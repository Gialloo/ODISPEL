extends SceneTree

# Lobby condivisa (pronto, personaggio guida, missione) senza rete vera.
#   godot --headless --path . -s res://tests/unit/test_lobby.gd

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
	_run()
	for m in _managers:
		m.free()
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _host(count: int) -> NetworkManager:
	var game := GameState.new()
	game.setup("lb_test", 1, 1, count)
	for i in count:
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


func _entries(ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		out.append(BattleContent.default_entry(str(id)))
	return out


func _hello(m: NetworkManager, peer: String, token: String, team: Array) -> void:
	m._links[peer] = WebRTCLink.new()
	m._host_handle_message({"type": "hello", "name": peer, "token": token, "version": GameConfig.VERSION, "team": team}, peer)


func _row(m: NetworkManager, id: String) -> Dictionary:
	for p in m.lobby["players"]:
		if str(p["id"]) == id:
			return p
	return {}


func _run() -> void:
	var m: NetworkManager = _host(3)
	m.set_local_team(_entries(["kira", "dax", "elle"]))
	m.refresh_lobby()
	_check("lobby: c'e' solo l'host", m.lobby["players"].size() == 1)
	_check("lobby: l'host e' segnato", _row(m, "player_1")["host"] == true)
	_check("lobby: personaggio guida dell'host", _row(m, "player_1")["lead"]["char"] == "kira")
	_check("lobby: missione di partenza", m.lobby["boss"] == "distributore" and m.lobby["tier"] == 0)

	var updates: Array = []
	m.lobby_updated.connect(func() -> void: updates.append(1))
	_hello(m, "peerA", "tok-a", _entries(["nova", "bruno"]))
	_check("ingresso: la lobby si aggiorna", updates.size() >= 1)
	_check("ingresso: due giocatori", m.lobby["players"].size() == 2)
	_check("ingresso: guida del client", _row(m, "player_2")["lead"]["char"] == "nova")
	_check("ingresso: squadra del client contata", _row(m, "player_2")["team_size"] == 2)
	_check("ingresso: non e' pronto", _row(m, "player_2")["ready"] == false)
	_check("ingresso: il posto libero non compare", _row(m, "player_3").is_empty())

	_check("non si parte se nessuno e' pronto", not m.all_ready() and not m.host_launch())
	m.set_ready(true)
	_check("host pronto", _row(m, "player_1")["ready"] == true and m.is_local_ready())
	_check("non si parte se manca il client", not m.all_ready())
	m._host_handle_message({"type": "ready", "ready": true}, "peerA")
	_check("client pronto", _row(m, "player_2")["ready"] == true)
	_check("tutti pronti", m.all_ready())

	# la squadra cambia: chi e' pronto deve riconfermare
	m._host_handle_message({"type": "team", "team": _entries(["mira"])}, "peerA")
	_check("squadra del client aggiornata", _row(m, "player_2")["lead"]["char"] == "mira")
	_check("cambio squadra toglie il pronto", _row(m, "player_2")["ready"] == false)
	_check("l'altro resta pronto", _row(m, "player_1")["ready"] == true)
	m._host_handle_message({"type": "team", "team": [{"char": "drago"}]}, "peerA")
	_check("squadra non valida ignorata", _row(m, "player_2")["lead"]["char"] == "mira")
	m.set_local_team(_entries(["dax", "kira"]))
	_check("cambio squadra dell'host toglie il suo pronto", _row(m, "player_1")["ready"] == false)
	_check("guida dell'host cambiata", _row(m, "player_1")["lead"]["char"] == "dax")

	# missione
	m.set_ready(true)
	m._host_handle_message({"type": "ready", "ready": true}, "peerA")
	_check("pronti di nuovo", m.all_ready())
	_check("missione valida", m.host_set_mission("semaforo", 1))
	_check("missione nella lobby", m.lobby["boss"] == "semaforo" and m.lobby["tier"] == 1)
	_check("cambiare missione toglie i pronto", not m.all_ready())
	_check("boss sconosciuto rifiutato", not m.host_set_mission("drago", 0))
	_check("difficolta' limitata", m.host_set_mission("tombino", 9) and m.lobby["tier"] == 3)

	# partenza
	m.set_ready(true)
	m._host_handle_message({"type": "ready", "ready": true}, "peerA")
	_check("partenza con tutti pronti", m.host_launch())
	_check("la battaglia usa la missione della lobby", str(BattleState.boss(m.battle)["char"]) == "tombino" and int(m.battle["tier"]) == 3)
	_check("dopo la partenza nessuno e' pronto", not _row(m, "player_1")["ready"] and not _row(m, "player_2")["ready"])

	# uscita
	var m2: NetworkManager = _host(2)
	m2.set_local_team(_entries(["kira"]))
	_hello(m2, "peerA", "tok-a", _entries(["nova"]))
	m2.set_ready(true)
	m2._host_handle_message({"type": "ready", "ready": true}, "peerA")
	_check("due pronti", m2.all_ready())
	m2._drop_peer("peerA")
	_check("chi esce non e' piu' pronto/connesso", not _row(m2, "player_2")["connected"] and not _row(m2, "player_2")["ready"])
	_check("da soli non si parte", not m2.all_ready())

	# livelli non sbloccati: l'host sa chi non li ha
	var m3: NetworkManager = _host(3)
	m3.set_local_team(_entries(["kira"]))
	m3.local_cleared = {"distributore": 3, "semaforo": 1}
	m3._links["pA"] = WebRTCLink.new()
	m3._host_handle_message({"type": "hello", "name": "Luca", "token": "tok-l", "version": GameConfig.VERSION, "team": _entries(["nova"]), "cleared": {"distributore": 1}}, "pA")
	_check("sblocco: Luca ha battuto solo Normale", m3.players_lacking_unlock("distributore", 1).is_empty())
	_check("sblocco: Luca non ha Incubo", m3.players_lacking_unlock("distributore", 2) == ["Luca"])
	_check("sblocco: Normale del primo boss e' aperto a tutti", m3.players_lacking_unlock("distributore", 0).is_empty())
	_check("sblocco: Luca ha battuto Normale del primo boss, il secondo boss e' aperto", m3.players_lacking_unlock("semaforo", 0).is_empty())
	_check("sblocco: il terzo boss no", m3.players_lacking_unlock("tombino", 0) == ["Luca"])
	var m4: NetworkManager = _host(2)
	m4.set_local_team(_entries(["kira"]))
	m4.local_cleared = {}
	_hello(m4, "pB", "tok-b", _entries(["nova"]))
	_check("sblocco: senza progressi comunicati non si segnala nessuno (il primo boss e' aperto)", m4.players_lacking_unlock("distributore", 0).is_empty())
	_check("sblocco: l'host stesso si controlla", m4.players_lacking_unlock("tombino", 0) == ["P1"])
	_check("sblocco: dati strani vengono ripuliti", NetworkManager._clean_cleared({"distributore": 99, "x": 5, "semaforo": -3}) == {"distributore": 4, "semaforo": 0, "tombino": 0, "cabina": 0, "ascensore": 0, "manichino": 0, "orologio": 0, "specchio": 0, "sirena": 0, "lampione": 0, "bancomat": 0, "scala": 0, "radio": 0, "metro": 0, "cassaforte": 0, "faro": 0, "registro": 0, "eclissi": 0})

	# finestra di conferma
	var yes_count: Array = [0]
	var host_node := Control.new()
	root.add_child(host_node)
	var cb: ConfirmBox = ConfirmBox.ask(host_node, "Luca non ha ancora sbloccato questo livello.\nProcedere lo stesso?", func() -> void: yes_count[0] += 1)
	if cb.yes_button == null:
		cb._ready()          # in questo test l'albero non e' ancora partito
	_check("conferma: si apre", host_node.get_child_count() == 1 and cb.yes_button != null)
	cb.no_button.pressed.emit()
	_check("conferma: NO non fa nulla", yes_count[0] == 0)
	var cb2: ConfirmBox = ConfirmBox.ask(host_node, "x", func() -> void: yes_count[0] += 1)
	if cb2.yes_button == null:
		cb2._ready()
	cb2.yes_button.pressed.emit()
	_check("conferma: SI' esegue una volta", yes_count[0] == 1)
	host_node.free()

	# lato client
	var c := NetworkManager.new()
	_managers.append(c)
	c.local_player_id = "player_2"
	var got: Array = []
	c.lobby_updated.connect(func() -> void: got.append(1))
	c._client_handle_message({"type": "lobby", "state": JSON.parse_string(JSON.stringify(m.lobby))})
	_check("client: riceve la lobby", c.lobby["players"].size() == 2 and got.size() == 1)
	_check("client: numeri interi", c.lobby["tier"] is int)
	_check("client: sa se e' pronto", c.is_local_ready() == false)
