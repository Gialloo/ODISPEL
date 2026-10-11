extends SceneTree

# Battaglia in rete con il nuovo motore, senza rete vera:
# i collegamenti sono WebRTCLink vuoti (send_message restituisce false).
#
#   godot --headless --path . -s res://tests/unit/test_battle_net.gd

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


func _init() -> void:
	_test_helpers()
	_test_hello_team()
	_test_start()
	_test_choices()
	_test_timer()
	_test_disconnect_and_rejoin()
	_test_client_side()
	_test_full_battle()
	for m in _managers:
		m.free()
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _lobby(player_count: int) -> NetworkManager:
	var game := GameState.new()
	game.setup("bn_test", 1, 1, player_count)
	for i in player_count:
		var p := PlayerState.new()
		p.setup("player_" + str(i + 1), "P" + str(i + 1), i + 1)
		game.party.add_player(p)
	var m := NetworkManager.new()
	m.is_host = true
	m.game = game
	m.local_player_id = "player_1"
	m._prepare_host_party()
	_managers.append(m)
	return m


func _hello(m: NetworkManager, peer: String, token: String, team: Variant = null) -> void:
	m._links[peer] = WebRTCLink.new()
	var msg: Dictionary = {"type": "hello", "name": peer, "token": token, "version": GameConfig.VERSION}
	if team != null:
		msg["team"] = team
	m._host_handle_message(msg, peer)


func _entries(ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		out.append(BattleContent.default_entry(str(id)))
	return out


func _started(count: int = 3) -> NetworkManager:
	var m: NetworkManager = _lobby(count)
	m.set_local_team(_entries(["kira", "dax", "elle"]))
	_hello(m, "peerA", "tok-a", _entries(["nova", "bruno", "mira"]))
	_check("setup: avvio battaglia", m.host_start_battle("distributore", 4242))
	return m


func _test_helpers() -> void:
	var s: Dictionary = BattleState.create([
		{"id": "a", "name": "A", "ai": false, "team": _entries(["kira"])},
		{"id": "b", "name": "B", "ai": false, "team": _entries(["nova"])}], "distributore", 9)
	BattleResolver.submit_choice(s, "a", {"move": "attack"})
	BattleResolver.submit_choice(s, "b", {"move": "guard"})
	var va: Dictionary = BattleNet.snapshot_for(s, "a")
	_check("snapshot: niente seed dell'RNG", va["rng_seed"] == "0" and va["rng_state"] == "0")
	_check("snapshot: vedo la mia scelta", va["players"][0]["choice"]["move"] == "attack")
	_check("snapshot: la scelta altrui e' solo bloccata", va["players"][1]["choice"] == {"locked": true})
	_check("snapshot: lo spettatore non vede scelte", BattleNet.snapshot_for(s, "")["players"][0]["choice"] == {"locked": true})
	_check("snapshot: l'originale non cambia", s["rng_seed"] == "9" and s["players"][1]["choice"]["move"] == "guard")
	_check("snapshot: chi non ha scelto resta senza scelta", BattleNet.snapshot_for(BattleState.create([{"id": "a", "name": "A", "ai": false, "team": _entries(["kira"])}], "distributore", 1), "x")["players"][0]["choice"] == null)

	_check("hello senza squadra: squadra di partenza", BattleNet.read_team({})["ok"] and BattleNet.read_team({})["team"].size() == 3)
	_check("squadra non-array rifiutata", not BattleNet.read_team({"team": "kira"})["ok"])
	_check("squadra con livello assurdo rifiutata", not BattleNet.read_team({"team": [{"char": "kira", "level": 9999, "rank": 0, "skills": [], "ult": "", "passives": [], "gear": []}]})["ok"])
	_check("squadra vuota rifiutata", not BattleNet.read_team({"team": []})["ok"])
	var via_json: Variant = JSON.parse_string(JSON.stringify({"team": _entries(["kira", "dax"])}))
	var r: Dictionary = BattleNet.read_team(via_json)
	_check("squadra via JSON: numeri interi", r["ok"] and r["team"][0]["level"] is int)
	var c: Dictionary = BattleNet.clean_choice({"swap": 5, "move": "attack", "extra": "x", "type": "choice"})
	_check("scelta ripulita", c == {"swap": "5", "move": "attack", "target": ""})


func _test_hello_team() -> void:
	var m: NetworkManager = _lobby(3)
	_hello(m, "peerA", "tok-a", _entries(["nova", "bruno"]))
	_check("hello con squadra valida: accettato", m._peer_players.has("peerA"))
	_check("squadra salvata sull'host", m._player_teams["player_2"].size() == 2 and m._player_teams["player_2"][0]["char"] == "nova")

	_hello(m, "peerB", "tok-b", [{"char": "drago", "level": 1, "rank": 0}])
	_check("hello con squadra non valida: rifiutato", not m._peer_players.has("peerB"))
	_check("slot non consumato dalla squadra non valida", m._find_free_player() != null and m._find_free_player().id == "player_3")

	_hello(m, "peerC", "tok-c")
	_check("hello senza squadra: accettato con quella di partenza", m._peer_players.has("peerC") and m._player_teams["player_3"].size() == 3)

	var h: NetworkManager = _lobby(2)
	_check("squadra locale non valida rifiutata", not h.set_local_team([]))
	_check("squadra locale valida", h.set_local_team(_entries(["kira"])) and h._player_teams["player_1"].size() == 1)


func _test_start() -> void:
	var solo: NetworkManager = _lobby(3)
	_check("non si avvia da soli", not solo.host_start_battle("distributore", 1))
	_hello(solo, "peerA", "tok-a")
	_check("boss sconosciuto rifiutato", not solo.host_start_battle("drago", 1))
	_check("seed zero rifiutato", not solo.host_start_battle("distributore", 0))

	var m: NetworkManager = _started(3)
	var b: Dictionary = m.battle
	_check("battaglia creata per i due presenti", b["players"].size() == 2 and b["round"] == 1)
	_check("le squadre scelte sono quelle in uso", BattleState.unit(b, "player_1:kira").size() > 0 and BattleState.unit(b, "player_2:nova").size() > 0)
	_check("vita boss per 2 giocatori", BattleState.boss(b)["max_hp"] == 2 * int(BattleContent.BOSSES["distributore"]["hp_per_player"]))
	_check("timer di pianificazione attivo", m.battle_timer_enabled and m.battle_time_left == m.battle_planning_seconds)
	_check("secondo avvio rifiutato a battaglia in corso", not m.host_start_battle("distributore", 2))
	_hello(m, "peerZ", "tok-z")
	_check("nuovi giocatori non entrano a battaglia iniziata", not m._peer_players.has("peerZ"))

	# riservato ma disconnesso -> IA
	var r: NetworkManager = _lobby(3)
	_hello(r, "peerA", "tok-a")
	_hello(r, "peerB", "tok-b")
	r._drop_peer("peerB")
	r.host_start_battle("distributore", 5)
	_check("chi era uscito entra in battaglia controllato dall'IA", r.battle["players"].size() == 3 and BattleState.player(r.battle, "player_3")["ai"])


func _test_choices() -> void:
	var m: NetworkManager = _started()
	_check("scelta non valida rifiutata", not m.submit_choice({"move": "fulmine"}))
	_check("energia insufficiente rifiutata", not m.submit_choice({"move": "cura"}))
	_check("scelta host valida", m.submit_choice({"move": "attack"}))
	_check("l'host aspetta l'altro giocatore", m.battle["round"] == 1 and BattleState.player(m.battle, "player_1")["choice"] != null)
	m._host_handle_message({"type": "choice", "move": "fulmine"}, "peerA")
	_check("scelta non valida dal client ignorata", m.battle["round"] == 1)
	m._host_handle_message({"type": "choice", "move": "attack"}, "peerSconosciuto")
	_check("scelta da peer sconosciuto ignorata", m.battle["round"] == 1)
	m._host_handle_message({"type": "choice", "move": "guard"}, "peerA")
	_check("round risolto quando scelgono tutti", m.battle["round"] == 2)
	_check("il boss ha subito danni", BattleState.boss(m.battle)["hp"] < BattleState.boss(m.battle)["max_hp"])
	_check("scelte azzerate nel round nuovo", BattleState.player(m.battle, "player_1")["choice"] == null)

	var ev_count: Array = [0]
	m.battle_events_received.connect(func(e: Array) -> void: ev_count[0] += e.size())
	m.submit_choice({"move": "attack"})
	m._host_handle_message({"type": "choice", "move": "attack"}, "peerA")
	_check("l'host emette gli eventi del round", ev_count[0] > 0)

	# un giocatore sconfitto non puo' scegliere
	var d: NetworkManager = _started()
	for uid in ["player_2:nova", "player_2:bruno", "player_2:mira"]:
		BattleState.unit(d.battle, uid)["hp"] = 0
	_check("giocatore sconfitto non puo' scegliere", not BattleResolver.submit_choice(d.battle, "player_2", {"move": "attack"}))


func _test_timer() -> void:
	var m: NetworkManager = _started()
	m.submit_choice({"move": "attack"})
	m._tick_battle_timer(1.0)
	_check("il tempo scorre", m.battle_time_left < m.battle_planning_seconds)
	_check("prima della scadenza non si risolve", m.battle["round"] == 1)
	m._tick_battle_timer(m.battle_planning_seconds)
	_check("a tempo scaduto il round si risolve col default", m.battle["round"] == 2)
	_check("il tempo riparte", m.battle_time_left == m.battle_planning_seconds)

	var off: NetworkManager = _started()
	off.battle_timer_enabled = false
	off._tick_battle_timer(1000.0)
	_check("timer disattivato: non scade", off.battle["round"] == 1)

	# un client non risolve mai da solo
	var c := NetworkManager.new()
	_managers.append(c)
	c.battle = BattleState.create([{"id": "a", "name": "A", "ai": false, "team": _entries(["kira"])}], "distributore", 1)
	c.battle_time_left = 1.0
	c._tick_battle_timer(5.0)
	_check("il client conta ma non risolve", c.battle["round"] == 1 and c.battle_time_left == 0.0)


func _test_disconnect_and_rejoin() -> void:
	var m: NetworkManager = _started()
	m.submit_choice({"move": "attack"})
	m._drop_peer("peerA")
	_check("uscita in battaglia: l'IA prende il posto e il round si risolve", m.battle["round"] == 2)
	_check("il giocatore uscito e' controllato dall'IA", BattleState.player(m.battle, "player_2")["ai"])

	_hello(m, "peerA2", "tok-a", _entries(["nova", "bruno", "mira"]))
	_check("rientro con lo stesso token: riprende il posto", m._peer_players.get("peerA2", "") == "player_2")
	_check("rientro: torna il controllo umano", not BattleState.player(m.battle, "player_2")["ai"])
	m.submit_choice({"move": "attack"})
	_check("dopo il rientro serve la sua scelta", m.battle["round"] == 2)
	m._host_handle_message({"type": "choice", "move": "attack"}, "peerA2")
	_check("il round si risolve di nuovo", m.battle["round"] == 3)

	_hello(m, "intruso", "tok-x")
	_check("un estraneo non prende il posto", not m._peer_players.has("intruso"))


func _test_client_side() -> void:
	var host: NetworkManager = _started()
	host.submit_choice({"move": "attack"})
	var wire: Variant = JSON.parse_string(JSON.stringify({"type": "battle_snapshot", "state": BattleNet.snapshot_for(host.battle, "player_2"), "time_left": 12.5}))
	var c := NetworkManager.new()
	_managers.append(c)
	var updates: Array = [0]
	c.battle_updated.connect(func() -> void: updates[0] += 1)
	c._client_handle_message(wire)
	_check("il client riceve la battaglia", c.battle.size() > 0 and updates[0] == 1)
	_check("i numeri sono interi", c.battle["round"] is int and BattleState.boss(c.battle)["hp"] is int)
	_check("il client vede il tempo", is_equal_approx(c.battle_time_left, 12.5))
	_check("il client non vede la scelta dell'host", BattleState.player(c.battle, "player_1")["choice"] == {"locked": true})
	_check("il client non ha l'RNG", c.battle["rng_seed"] == "0")

	var got: Array = []
	c.battle_events_received.connect(func(e: Array) -> void: got.append_array(e))
	c._client_handle_message({"type": "battle_events", "events": [{"t": "damage", "amount": 3.0}]})
	_check("eventi ricevuti con numeri interi", got.size() == 1 and got[0]["amount"] is int)

	var err: Array = []
	c.network_error.connect(func(r: String) -> void: err.append(r))
	c._client_handle_message({"type": "error", "code": "invalid_team", "detail": "livello non valido"})
	_check("errore di squadra mostrato", err.size() == 1 and "livello non valido" in err[0])
	c._client_handle_message({"type": "battle_snapshot", "state": {}})
	_check("snapshot vuoto ignorato", c.battle.size() > 0)

	# un client senza collegamento non invia
	_check("client senza host non invia scelte", not c.submit_choice({"move": "attack"}))


func _test_full_battle() -> void:
	var m: NetworkManager = _started()
	var guard: int = 0
	while str(m.battle["winner"]) == "" and guard < 100:
		m.submit_choice(BattleAI.choose(m.battle, "player_1"))
		var c: Dictionary = BattleAI.choose(m.battle, "player_2")
		c["type"] = "choice"
		m._host_handle_message(c, "peerA")
		guard += 1
	_check("battaglia in rete completa fino alla fine", str(m.battle["winner"]) != "" and guard < 100)
	_check("a fine battaglia si puo' avviarne un'altra", m.host_start_battle("distributore", 99) and m.battle["round"] == 1)
