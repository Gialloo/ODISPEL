extends SceneTree

# PvP in rete (host autorevole), senza rete vera.
#   godot --headless --path . -s res://tests/unit/test_pvp_net.gd

var passed: int = 0
var failed: int = 0
var _managers: Array[NetworkManager] = []


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _lobby(n: int) -> NetworkManager:
	var game := GameState.new()
	game.setup("pvp_test", 1, 1, n)
	for i in n:
		var p := PlayerState.new()
		p.setup("player_" + str(i + 1), "P" + str(i + 1), i + 1)
		game.party.add_player(p)
	var m := NetworkManager.new()
	m.is_host = true
	m.game = game
	m.local_player_id = "player_1"
	m.local_team = [BattleContent.default_entry("kira"), BattleContent.default_entry("dax")]
	m._prepare_host_party()
	for i in range(1, n):
		var peer: String = "peer_%d" % i
		m._links[peer] = WebRTCLink.new()
		m._host_handle_message({"type": "hello", "name": peer, "token": "tok%d" % i, "version": GameConfig.VERSION,
			"team": [BattleContent.default_entry("rex"), BattleContent.default_entry("elle")]}, peer)
	_managers.append(m)
	return m


func _init() -> void:
	var m: NetworkManager = _lobby(2)
	_check("lobby ha modalita' e bilanciamento", m._build_lobby().has("mode") and m._build_lobby().has("balanced"))
	_check("modalita' sconosciuta rifiutata", not m.host_set_mode("battle_royale", true))
	_check("imposta 1v1", m.host_set_mode("duel", true) and m.lobby_mode == "duel")
	_check("pvp: non si parte senza pronti", not m.all_ready())
	for id in ["player_1", "player_2"]:
		m._ready_players[id] = true
	_check("pvp: tutti pronti", m.all_ready())
	_check("host_launch avvia il PvP", m.host_launch() and bool(m.battle.get("pvp", false)))
	_check("pronti azzerati", not bool(m._ready_players.get("player_1", false)))
	_check("2 giocatori, nessuna IA", m.battle["players"].size() == 2 and not bool(m.battle["players"][1]["ai"]))
	# scelte
	_check("scelta non valida rifiutata", not m._host_apply_choice("player_1", {"move": "ult", "target": "player_2"}))
	_check("host sceglie", m._host_apply_choice("player_1", {"move": "attack", "target": "player_2", "swap": ""}))
	_check("non risolve finche' manca uno", int(m.battle["round"]) == 1)
	var events: Array = []
	m.battle_events_received.connect(func(e: Array) -> void: events.append_array(e))
	_check("il client sceglie, round risolto", m._host_apply_choice("player_2", {"move": "guard", "target": "", "swap": ""}) and int(m.battle["round"]) == 2)
	_check("eventi emessi", events.size() > 0)
	# snapshot nasconde
	m._host_apply_choice("player_1", {"move": "guard", "target": "", "swap": ""})
	var snap: Dictionary = BattleNet.snapshot_for(m.battle, "player_2")
	_check("l'avversario vede la scelta solo come 'bloccata'", snap["players"][0]["choice"].has("locked") and snap["rng_seed"] == "0")
	# timer: scaduto il tempo chi non ha scelto viene sostituito dall'IA
	m._battle_resolve(true)
	_check("timeout: il round avanza", int(m.battle["round"]) >= 3)
	# disconnessione: gioca l'IA
	m._drop_peer("peer_1")
	_check("chi esce passa all'IA", bool(PvpEngine.player(m.battle, "player_2")["ai"]))
	var guard: int = 0
	while str(m.battle["winner"]) == "" and guard < 60:
		m._host_apply_choice("player_1", {"move": "attack", "target": "player_2", "swap": ""})
		if str(m.battle["winner"]) == "" and m.battle["players"][0]["choice"] == null:
			m._battle_resolve(true)
		guard += 1
	_check("la partita finisce", str(m.battle["winner"]) != "")
	m.reward_save_path = "user://test_pvp_net_roster.json"
	m.battle_rewards = PvpRewards.for_battle(m.battle, m._battle_seed).get("player_1", {})
	var bag: Dictionary = m.finish()
	_check("finish: borsa fight applicata e contatori aggiornati", int(bag.get("coins", 0)) > 0 and int(Feats.stats(RosterStore.load_or_new(m.reward_save_path)).get("pvp_plays", 0)) == 1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(m.reward_save_path))
	# 2v2: 2 umani + 2 IA
	var d: NetworkManager = _lobby(2)
	d.host_set_mode("duo", false)
	for id in ["player_1", "player_2"]:
		d._ready_players[id] = true
	_check("2v2 con 2 umani parte", d.host_launch())
	_check("2v2: 4 posti, 2 IA", d.battle["players"].size() == 4 and int(d.battle["players"].filter(func(p: Dictionary) -> bool: return bool(p["ai"])).size()) == 2)
	_check("2v2: gli umani sono avversari", PvpEngine.player(d.battle, "player_1")["team"] != PvpEngine.player(d.battle, "player_2")["team"])
	_check("non bilanciato: livelli originali", int(PvpEngine.unit(d.battle, "player_1:kira")["level"]) == int(BattleContent.default_entry("kira").get("level", 1)))
	# FFA con 3 umani
	var f: NetworkManager = _lobby(3)
	f.host_set_mode("ffa", true)
	for id in ["player_1", "player_2", "player_3"]:
		f._ready_players[id] = true
	_check("ffa a 3 parte", f.host_launch() and f.battle["players"].size() == 3)
	# troppi giocatori per il 1v1
	var t: NetworkManager = _lobby(3)
	t.host_set_mode("duel", true)
	for id in ["player_1", "player_2", "player_3"]:
		t._ready_players[id] = true
	_check("1v1 con 3 umani non parte", not t.all_ready() and not t.host_launch())
	_check("messaggio di errore chiaro", t.start_problem().contains("massimo"))
	# abbandono a meta': non si resta incastrati nella sfida lasciata
	var a: NetworkManager = _lobby(2)
	a.host_set_mode("duel", true)
	for id in ["player_1", "player_2"]:
		a._ready_players[id] = true
	_check("abbandono: la sfida parte", a.host_launch() and not a.battle.is_empty())
	a._host_handle_message({"type": "abandon"}, "peer_1")
	_check("abbandono client: al suo posto l'IA", bool(PvpEngine.player(a.battle, "player_2")["ai"]) and a._abandoned_peers.has("peer_1"))
	_check("abbandono client: la sfida continua per l'host", not a.battle.is_empty())
	a.abandon_battle()
	_check("abbandono host: la sfida e' chiusa", a.battle.is_empty())
	for id in ["player_1", "player_2"]:
		a._ready_players[id] = true
	_check("dopo l'abbandono se ne puo' avviare un'altra", a.host_launch() and not a.battle.is_empty() and str(a.battle.get("winner", "")) == "")
	_check("nuova sfida: nessuno e' piu' escluso", a._abandoned_peers.is_empty())
	# tutti fuori (nessun umano rimasto): la sfida residua non blocca la successiva
	var z: NetworkManager = _lobby(2)
	z.host_set_mode("duel", true)
	for id in ["player_1", "player_2"]:
		z._ready_players[id] = true
	z.host_launch()
	z._host_handle_message({"type": "abandon"}, "peer_1")
	BattleNet.set_player_ai(z.battle, "player_1", true)
	for id in ["player_1", "player_2"]:
		z._ready_players[id] = true
	_check("nessun umano rimasto: si puo' avviare una sfida nuova", z.host_launch() and not bool(PvpEngine.player(z.battle, "player_1")["ai"]))
	var c := NetworkManager.new()
	c._client_bid = 77
	c.battle = {"pvp": true, "winner": "", "players": []}
	c._links["h"] = WebRTCLink.new()
	c._host_peer_id = "h"
	c.abandon_battle()
	_check("abbandono client: stato locale pulito e sfida ignorata", c.battle.is_empty() and c._ignored_bid == 77)
	c._client_handle_message({"type": "battle_snapshot", "state": {"pvp": true, "winner": "", "players": []}, "bid": 77, "time_left": 5.0})
	_check("stati in ritardo della sfida lasciata ignorati", c.battle.is_empty())
	_managers.append(c)
	for mm in _managers:
		mm.free()
	print("RESULT: %d passed, %d failed" % [passed, failed])
	print("FAIL: %d" % failed)
	quit(1 if failed > 0 else 0)
