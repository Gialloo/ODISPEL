extends SceneTree

# SPEDIZIONE cooperativa: l'host possiede la run, i client votano, i risultati coincidono.
#   godot --headless --path . -s res://tests/unit/test_expedition_net.gd

var passed: int = 0
var failed: int = 0
var _managers: Array[NetworkManager] = []


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _entries(ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		out.append(BattleContent.default_entry(str(id)))
	return out


func _host() -> NetworkManager:
	var game := GameState.new()
	game.setup("xn_test", 1, 1, 2)
	for i in 2:
		var p := PlayerState.new()
		p.setup("player_" + str(i + 1), "P" + str(i + 1), i + 1)
		game.party.add_player(p)
	var m := NetworkManager.new()
	m.is_host = true
	m.game = game
	m.local_player_id = "player_1"
	m._prepare_host_party()
	m.set_local_team(_entries(["kira", "dax", "elle"]))
	m._links["peerA"] = WebRTCLink.new()
	m._host_handle_message({"type": "hello", "name": "peerA", "token": "tok", "version": GameConfig.VERSION, "team": _entries(["nova", "bruno", "mira"])}, "peerA")
	_managers.append(m)
	return m


func _init() -> void:
	var m: NetworkManager = _host()
	_check("nessuna spedizione", m.exp_run().is_empty())
	_check("combattimento senza run rifiutato", not m.host_exp_fight())
	_check("host avvia", m.host_exp_new("distributore", 0))
	_check("la run e' nella lobby", not (m.lobby.get("exp", {}) as Dictionary).is_empty())
	_check("seconda run rifiutata mentre e' viva", not m.host_exp_new("distributore", 0))
	_check("voto host", m.exp_vote("archivio"))
	var peer_player: String = str(m._peer_players.get("peerA", ""))
	m._host_handle_message({"type": "exp_vote", "option": "rifugio"}, "peerA")
	_check("voto client registrato", str(m.expedition["votes"].get(peer_player, "")) == "rifugio")
	m._host_handle_message({"type": "exp_vote", "option": "boh"}, "peerA")
	_check("voto falso ignorato", str(m.expedition["votes"].get(peer_player, "")) == "rifugio")
	_check("conferma: pareggio vince l'host", m.host_exp_confirm() and Expedition.kind(m.expedition) == "fight")
	_check("la scelta e' applicata", int(m.expedition["clue"]) == 1)
	# combattimento
	_check("avvio combattimento", m.host_exp_fight() and m.battle.has("expedition"))
	_check("nemico della tappa", str(BattleState.boss(m.battle)["char"]) == str(Expedition.battle_params(m.expedition)["boss"]))
	BattleState.boss(m.battle)["hp"] = 0
	m._battle_resolve(true)
	_check("vittoria registrata una volta", Expedition.kind(m.expedition) == "boon" and int(m.expedition["fights"]) == 1)
	m._battle_resolve(true)
	_check("niente doppio conteggio", int(m.expedition["fights"]) == 1)
	_check("nessun premio normale a meta' spedizione", m.battle_rewards.is_empty() and not Expedition.pays_rewards(m.battle))
	# un client riceve la lobby
	var c := NetworkManager.new()
	_managers.append(c)
	c._client_handle_message({"type": "lobby", "state": m.lobby})
	var cr: Dictionary = c.exp_run()
	_check("client vede la run", Expedition.kind(cr) == "boon" and str(cr["boss"]) == "distributore")
	_check("client vede opzioni uguali", Expedition.option_ids(cr) == Expedition.option_ids(m.expedition))
	_check("client non puo' avviare", not c.host_exp_fight() and not c.host_exp_new("distributore", 0))
	# prosegue fino alla fine
	var guard: int = 0
	while Expedition.kind(m.expedition) != "done" and guard < 20:
		guard += 1
		var k: String = Expedition.kind(m.expedition)
		if k == "fight":
			_check("combatte %s" % Expedition.role(m.expedition), m.host_exp_fight())
			BattleState.boss(m.battle)["hp"] = 0
			m._battle_resolve(true)
		else:
			m.exp_vote(str(Expedition.option_ids(m.expedition)[0]))
			m.host_exp_confirm()
	_check("spedizione finita", str(m.expedition["result"]) == "win")
	var pay: bool = Expedition.pays_rewards(m.battle)
	_check("il boss finale paga", pay)
	var roster: Dictionary = RosterState.new_roster()
	var c0: int = int(roster["coins"])
	var lines: Array = Expedition.finish(roster, c.exp_run() if Expedition.kind(c.exp_run()) == "done" else m.expedition)
	_check("premi di fine spedizione", int(roster["coins"]) > c0 and not lines.is_empty())
	m.host_exp_close()
	_check("chiusura", m.exp_run().is_empty())
	_check("nuova spedizione dopo la chiusura", m.host_exp_new("distributore", 1))
	for x in _managers:
		x.free()
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
