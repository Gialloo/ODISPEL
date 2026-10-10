extends SceneTree

# Test della logica host di NetworkManager senza rete:
# i collegamenti sono WebRTCLink vuoti (send_message restituisce false).
#
# Esecuzione:
#   godot --headless --path . -s res://tests/unit/test_network_host.gd

var passed: int = 0
var failed: int = 0
var _managers: Array[NetworkManager] = []


func _initialize() -> void:
	print("=== ODISPEL NETWORK HOST TESTS ===")

	_test_unassigned_slots_do_not_block()
	_test_join_assigns_and_syncs_slot()
	_test_room_full()
	_test_disconnect_syncs_slot()
	_test_rejoin_with_same_token()
	_test_stranger_cannot_take_reserved_slot()
	_test_duplicate_token_replaces_old_link()
	_test_no_new_players_after_round_one()
	_test_invalid_token_rejected()
	_test_planning_timeout()
	_test_timer_disabled_by_default()
	_test_client_counts_down_locally()
	_test_signaling_roles()
	_test_join_retry()
	_test_link_heartbeat()
	_test_link_open_timeout()
	_test_signaling_state()
	_test_filtered_snapshot()

	for manager in _managers:
		manager.free()

	print("")
	print("=== RISULTATI ===")
	print("PASS: ", passed)
	print("FAIL: ", failed)

	if failed == 0:
		print("TUTTI I TEST SUPERATI")

	quit(0 if failed == 0 else 1)


func _check(name: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _make_manager(player_count: int) -> NetworkManager:
	var game := GameState.new()
	game.setup("net_test", 1, 1, player_count)

	for index in range(player_count):
		var player := PlayerState.new()
		player.setup(
			"player_" + str(index + 1),
			"P" + str(index + 1),
			index + 1
		)
		game.party.add_player(player)

	game.setup_run("net_run", 12345, "start")
	game.begin_combat("boss_test", "Boss", 2000)

	var manager := NetworkManager.new()
	manager.is_host = true
	manager.game = game
	manager.local_player_id = "player_1"
	manager._prepare_host_party()
	_managers.append(manager)
	return manager


func _hello(
	manager: NetworkManager,
	peer_id: String,
	token: String,
	display_name: String = ""
) -> void:
	manager._links[peer_id] = WebRTCLink.new()
	manager._host_handle_message({
		"type": "hello",
		"name": display_name,
		"token": token
	}, peer_id)


func _player(manager: NetworkManager, player_id: String) -> PlayerState:
	return manager.game.party.get_player_by_id(player_id)


func _slot(manager: NetworkManager, player_id: String) -> PartySlot:
	return manager.game.party.get_slot_by_player_id(player_id)


func _test_unassigned_slots_do_not_block() -> void:
	var manager := _make_manager(3)

	_check(
		"Slot non occupati segnati disconnessi",
		not _player(manager, "player_2").connected
		and not _player(manager, "player_3").connected
	)
	_check(
		"L'host resta connesso",
		_player(manager, "player_1").connected
	)

	manager.host_submit_action("attack")

	var game: GameState = manager.game
	_check("Il round si risolve senza aspettare slot vuoti", game.combat.round_state.number == 2)
	_check("Attacchi automatici dei 3 giocatori", game.combat.boss.hp == 1700)


func _test_join_assigns_and_syncs_slot() -> void:
	var manager := _make_manager(3)
	_hello(manager, "peerA", "tok-a", "Alice")

	var player := _player(manager, "player_2")
	var slot := _slot(manager, "player_2")

	_check("Il peer riceve player_2", manager._peer_players.get("peerA") == "player_2")
	_check("Giocatore connesso e non IA", player.connected and not player.controlled_by_ai)
	_check("Peer di gioco assegnato", player.network_peer_id > 1)
	_check("Nome applicato", player.display_name == "Alice")
	_check(
		"Slot coerente con il giocatore",
		slot.connected and not slot.controlled_by_ai
		and slot.peer_id == player.network_peer_id
	)
	_check("Party valido", manager.game.party.is_valid())


func _test_room_full() -> void:
	var manager := _make_manager(2)
	_hello(manager, "peerA", "tok-a")
	_hello(manager, "peerB", "tok-b")

	_check("Primo client accettato", manager._peer_players.has("peerA"))
	_check("Secondo client rifiutato (stanza piena)", not manager._peer_players.has("peerB"))


func _test_disconnect_syncs_slot() -> void:
	var manager := _make_manager(2)
	_hello(manager, "peerA", "tok-a")
	manager._drop_peer("peerA")

	var player := _player(manager, "player_2")
	var slot := _slot(manager, "player_2")

	_check("Giocatore disconnesso e IA", not player.connected and player.controlled_by_ai)
	_check(
		"Anche lo slot risulta disconnesso",
		not slot.connected and slot.controlled_by_ai and slot.peer_id == 0
	)
	_check("Party ancora valido", manager.game.party.is_valid())


func _test_rejoin_with_same_token() -> void:
	var manager := _make_manager(3)
	_hello(manager, "peerA", "tok-a", "Alice")
	manager._drop_peer("peerA")
	_hello(manager, "peerA2", "tok-a")

	var player := _player(manager, "player_2")
	var slot := _slot(manager, "player_2")

	_check("Rientro: stesso giocatore", manager._peer_players.get("peerA2") == "player_2")
	_check("Rientro: di nuovo connesso", player.connected and not player.controlled_by_ai)
	_check("Rientro: slot coerente", slot.connected and not slot.controlled_by_ai)
	_check("Rientro: nome conservato", player.display_name == "Alice")

	manager.host_submit_action("attack")
	_check(
		"Rientro: il round aspetta di nuovo il giocatore",
		manager.game.combat.round_state.number == 1
	)


func _test_stranger_cannot_take_reserved_slot() -> void:
	var manager := _make_manager(3)
	_hello(manager, "peerA", "tok-a")
	manager._drop_peer("peerA")
	_hello(manager, "peerZ", "tok-z")

	_check(
		"Lo sconosciuto non prende lo slot riservato",
		manager._peer_players.get("peerZ") == "player_3"
	)
	_check(
		"Lo slot riservato resta disconnesso",
		not _player(manager, "player_2").connected
	)


func _test_duplicate_token_replaces_old_link() -> void:
	var manager := _make_manager(2)
	_hello(manager, "peerA", "tok-a")
	_hello(manager, "peerA2", "tok-a")

	_check("Il vecchio collegamento è rimosso", not manager._peer_players.has("peerA"))
	_check("Il nuovo collegamento ha il giocatore", manager._peer_players.get("peerA2") == "player_2")
	_check("Giocatore resta connesso", _player(manager, "player_2").connected)
	_check("Party valido dopo la sostituzione", manager.game.party.is_valid())


func _test_no_new_players_after_round_one() -> void:
	var manager := _make_manager(3)
	_hello(manager, "peerA", "tok-a")
	manager._host_handle_message({"type": "action", "action_id": "attack"}, "peerA")
	manager.host_submit_action("attack")

	_check("Il combattimento è al round 2", manager.game.combat.round_state.number == 2)

	_hello(manager, "peerZ", "tok-z")
	_check("Nuovo giocatore rifiutato dopo il round 1", not manager._peer_players.has("peerZ"))

	manager._drop_peer("peerA")
	_hello(manager, "peerA2", "tok-a")
	_check("Chi era già dentro può rientrare", manager._peer_players.get("peerA2") == "player_2")


func _test_invalid_token_rejected() -> void:
	var manager := _make_manager(2)
	_hello(manager, "peerA", "")
	_check("Token vuoto rifiutato", not manager._peer_players.has("peerA"))

	_hello(manager, "peerB", "x".repeat(65))
	_check("Token troppo lungo rifiutato", not manager._peer_players.has("peerB"))


func _test_planning_timeout() -> void:
	var manager := _make_manager(3)
	_hello(manager, "peerA", "tok-a", "Alice")

	var captured: Array = []
	manager.round_result_received.connect(
		func(events: Array) -> void: captured.append_array(events)
	)

	manager.set_planning_timer_enabled(true)
	manager.host_submit_action("attack")

	var game: GameState = manager.game
	_check("Timer: il round aspetta Alice", game.combat.round_state.number == 1)

	manager._tick_planning_timer(29.0)
	_check("Timer: a 29 s il round non è scaduto", game.combat.round_state.number == 1)

	manager._tick_planning_timer(2.0)
	_check("Timer: scaduto il tempo il round si risolve", game.combat.round_state.number == 2)
	_check("Timer: attacchi di host, Alice (auto) e slot vuoto (auto)", game.combat.boss.hp == 1700)

	var alice_timeout: bool = false

	for event: Dictionary in captured:
		if (
			event["type"] == "auto_action"
			and event["player_id"] == "player_2"
			and "in tempo" in str(event["text"])
		):
			alice_timeout = true

	_check("Timer: evento di tempo scaduto per Alice", alice_timeout)
	_check(
		"Timer: nel nuovo round il tempo riparte da capo",
		is_equal_approx(
			game.combat.round_state.time_remaining,
			game.combat.round_state.planning_time
		)
	)


func _test_timer_disabled_by_default() -> void:
	var manager := _make_manager(2)
	_hello(manager, "peerA", "tok-a")

	manager._tick_planning_timer(500.0)

	_check("Timer disattivo: nessuna risoluzione", manager.game.combat.round_state.number == 1)
	_check("Timer disattivo: nessun conteggio", is_equal_approx(
		manager.game.combat.round_state.time_remaining,
		manager.game.combat.round_state.planning_time
	))


func _test_client_counts_down_locally() -> void:
	var manager := _make_manager(2)
	manager.is_host = false
	manager._tick_planning_timer(5.0)

	_check(
		"Client: il conto alla rovescia scende solo per la UI",
		is_equal_approx(manager.game.combat.round_state.time_remaining, 25.0)
	)
	_check("Client: non risolve mai il round", manager.game.combat.round_state.number == 1)

	manager._tick_planning_timer(100.0)
	_check("Client: a zero non risolve", manager.game.combat.round_state.number == 1)


func _test_signaling_roles() -> void:
	var errors: Array[String] = []

	# Client: "joined" senza host_peer_id significa nessun host.
	var client := NetworkManager.new()
	_managers.append(client)
	client.is_host = false
	client.join_retry_limit = 0
	client.network_error.connect(func(reason: String) -> void: errors.append(reason))

	client._handle_signaling({"type": "joined", "peer_id": "me", "peers": []})
	_check(
		"Signaling: client senza host nella risposta riceve un errore",
		errors.size() == 1 and errors[0] == "nessun host nella stanza"
	)

	client._handle_signaling({"type": "room_closed", "reason": "host_left"})
	_check(
		"Signaling: room_closed avvisa il client che l'host è uscito",
		errors.size() == 2 and errors[1] == "host disconnesso"
	)

	client._handle_signaling({"type": "error", "code": "no_host"})
	client._handle_signaling({"type": "error", "code": "room_taken"})
	client._handle_signaling({"type": "error", "code": "altro"})
	_check("Signaling: no_host tradotto", errors[2] == "nessun host nella stanza")
	_check("Signaling: room_taken tradotto", errors[3] == "stanza già occupata: l'host deve crearla")
	_check("Signaling: altri codici passano così come sono", errors[4] == "signaling: altro")

	# Host: ignora room_closed e peer_left di peer sconosciuti.
	var host_errors: Array[String] = []
	var host := _make_manager(2)
	host.network_error.connect(func(reason: String) -> void: host_errors.append(reason))
	host._handle_signaling({"type": "room_closed"})
	host._handle_signaling({"type": "peer_left", "peer_id": "sconosciuto"})
	_check("Signaling: l'host non riceve errori da room_closed", host_errors.is_empty())

	# Host: peer_left di un client lo rimuove.
	_hello(host, "peerA", "tok-a")
	host._handle_signaling({"type": "peer_left", "peer_id": "peerA"})
	_check(
		"Signaling: peer_left rimuove il client dall'host",
		not host._peer_players.has("peerA")
		and not _player(host, "player_2").connected
	)


func _test_join_retry() -> void:
	var errors: Array[String] = []
	var waits: Array[int] = []
	var client := NetworkManager.new()
	_managers.append(client)
	client.is_host = false
	client.join_retry_limit = 2
	client.join_retry_interval = 2.0
	client.network_error.connect(func(reason: String) -> void: errors.append(reason))
	client.waiting_for_host.connect(func(attempt: int) -> void: waits.append(attempt))

	client._handle_signaling({"type": "error", "code": "no_host"})
	_check("Retry: il primo no_host non è un errore", errors.is_empty() and waits.size() == 1 and waits[0] == 1)
	_check("Retry: nuovo tentativo programmato", is_equal_approx(client._join_retry_in, 2.0))

	client._tick_join_retry(1.0)
	_check("Retry: il conto alla rovescia scende", is_equal_approx(client._join_retry_in, 1.0))

	client._tick_join_retry(1.5)
	_check("Retry: scaduto l'intervallo il tentativo è partito", client._join_retry_in < 0.0)

	client._handle_signaling({"type": "error", "code": "no_host"})
	_check("Retry: secondo tentativo segnalato", errors.is_empty() and waits.size() == 2 and waits[1] == 2)

	client._handle_signaling({"type": "error", "code": "no_host"})
	_check(
		"Retry: esauriti i tentativi arriva l'errore",
		errors.size() == 1 and errors[0] == "nessun host nella stanza"
	)

	# Un host non ritenta mai.
	var host_errors: Array[String] = []
	var host := _make_manager(2)
	host.network_error.connect(func(reason: String) -> void: host_errors.append(reason))
	host._handle_signaling({"type": "error", "code": "no_host"})
	_check("Retry: l'host non ritenta", host_errors.size() == 1)


func _test_link_heartbeat() -> void:
	var link := WebRTCLink.new()
	var messages: Array[Dictionary] = []
	var closed: Array[bool] = []
	link.message_received.connect(func(message: Dictionary) -> void: messages.append(message))
	link.channel_closed.connect(func() -> void: closed.append(true))

	# Prima dell'apertura il heartbeat non fa nulla.
	link.check_heartbeat(999999)
	_check("Heartbeat: inattivo finché il canale non è aperto", closed.is_empty())

	link._was_open = true
	link._last_received_msec = 0
	link._last_ping_msec = 0

	link.check_heartbeat(WebRTCLink.HEARTBEAT_TIMEOUT_MSEC - 1)
	_check("Heartbeat: prima del timeout il link resta aperto", closed.is_empty())

	link._handle_raw('{"type":"ping"}', 5000)
	_check("Heartbeat: il ping non arriva al gioco", messages.is_empty())

	link.check_heartbeat(5000 + WebRTCLink.HEARTBEAT_TIMEOUT_MSEC - 1)
	_check("Heartbeat: un ping ricevuto allunga la vita del link", closed.is_empty())

	link._handle_raw('{"type":"action","action_id":"attack"}', 6000)
	_check(
		"Heartbeat: i messaggi normali passano",
		messages.size() == 1 and messages[0]["type"] == "action"
	)

	link._handle_raw("non è json", 7000)
	_check("Heartbeat: i messaggi non validi sono scartati", messages.size() == 1)

	link.check_heartbeat(7000 + WebRTCLink.HEARTBEAT_TIMEOUT_MSEC)
	_check("Heartbeat: dopo il silenzio il link si chiude", closed.size() == 1)

	link.check_heartbeat(7000 + WebRTCLink.HEARTBEAT_TIMEOUT_MSEC + 5000)
	_check("Heartbeat: la chiusura è segnalata una sola volta", closed.size() == 1)


func _test_link_open_timeout() -> void:
	var host := _make_manager(2)
	host._links["peerX"] = WebRTCLink.new()
	host._link_created["peerX"] = 0

	host._check_link_timeouts(NetworkManager.LINK_OPEN_TIMEOUT_MSEC - 1)
	_check("Timeout link: prima del limite resta", host._links.has("peerX"))

	host._check_link_timeouts(NetworkManager.LINK_OPEN_TIMEOUT_MSEC)
	_check(
		"Timeout link: l'host abbandona il collegamento che non si apre",
		not host._links.has("peerX") and not host._link_created.has("peerX")
	)

	var errors: Array[String] = []
	var client := NetworkManager.new()
	_managers.append(client)
	client.is_host = false
	client.network_error.connect(func(reason: String) -> void: errors.append(reason))
	client._links["hostpeer"] = WebRTCLink.new()
	client._link_created["hostpeer"] = 0

	client._check_link_timeouts(NetworkManager.LINK_OPEN_TIMEOUT_MSEC)
	_check(
		"Timeout link: il client riceve un errore",
		errors.size() == 1 and errors[0] == "connessione con l'host non riuscita"
	)

	client._check_link_timeouts(NetworkManager.LINK_OPEN_TIMEOUT_MSEC + 1000)
	_check("Timeout link: l'errore non si ripete", errors.size() == 1)

	var opened := WebRTCLink.new()
	opened._was_open = true
	client._links["ok"] = opened
	client._link_created["ok"] = 0
	client._check_link_timeouts(NetworkManager.LINK_OPEN_TIMEOUT_MSEC * 2)
	_check("Timeout link: un link aperto non va in timeout", errors.size() == 1)


func _test_signaling_state() -> void:
	# Senza connessione avviata non si segnala nulla.
	var errors: Array[String] = []
	var manager := NetworkManager.new()
	_managers.append(manager)
	manager.network_error.connect(func(reason: String) -> void: errors.append(reason))
	manager._check_signaling_state(1000)
	_check("Signaling: nessun errore se non è stato avviato nulla", errors.is_empty())

	# Connessione rifiutata: il socket è chiuso e non si è mai aperto.
	manager._connect_started_msec = 500
	manager._check_signaling_state(1000)
	_check("Signaling: server non raggiungibile", errors.size() == 1 and errors[0] == "signaling non raggiungibile")

	manager._check_signaling_state(2000)
	_check("Signaling: l'errore si segnala una volta sola", errors.size() == 1)

	# Chiuso dopo essere stato aperto, senza collegamenti di gioco.
	var errors2: Array[String] = []
	var second := NetworkManager.new()
	_managers.append(second)
	second.network_error.connect(func(reason: String) -> void: errors2.append(reason))
	second._connect_started_msec = 500
	second._socket_was_open = true
	second._check_signaling_state(1000)
	_check("Signaling: caduto senza link di gioco è un errore", errors2.size() == 1 and errors2[0] == "signaling disconnesso")

	# Chiuso ma con un collegamento di gioco già aperto: si continua.
	var errors3: Array[String] = []
	var lost3: Array[bool] = []
	var third := NetworkManager.new()
	_managers.append(third)
	third.network_error.connect(func(reason: String) -> void: errors3.append(reason))
	third.signaling_lost.connect(func() -> void: lost3.append(true))
	var open_link := WebRTCLink.new()
	open_link._was_open = true
	third._links["p"] = open_link
	third._connect_started_msec = 500
	third._socket_was_open = true
	third._check_signaling_state(1000)
	_check(
		"Signaling: con un link aperto la partita continua (solo signaling_lost)",
		errors3.is_empty() and lost3.size() == 1
	)

	# Chiusura volontaria: nessun errore.
	var errors4: Array[String] = []
	var fourth := NetworkManager.new()
	_managers.append(fourth)
	fourth.network_error.connect(func(reason: String) -> void: errors4.append(reason))
	fourth.shutdown()
	fourth._process(0.1)
	_check("Shutdown: nessun errore dopo la chiusura volontaria", errors4.is_empty())


func _test_filtered_snapshot() -> void:
	var manager := _make_manager(3)
	_hello(manager, "peerA", "tok-a", "Alice")
	_hello(manager, "peerB", "tok-b", "Bob")

	# Alice sceglie guard; l'host e Bob non hanno ancora scelto.
	manager._host_handle_message({"type": "action", "action_id": "guard"}, "peerA")

	var game: GameState = manager.game
	var alice: PlayerState = _player(manager, "player_2")
	_check("Snapshot: Alice ha scelto guard", alice.selected_action_id == "guard" and alice.is_locked)

	var for_bob: Dictionary = NetworkManager.build_snapshot_for(game, "player_3")
	var for_alice: Dictionary = NetworkManager.build_snapshot_for(game, "player_2")

	_check(
		"Snapshot: Bob non vede la scelta di Alice",
		_snapshot_action(for_bob, "player_2") == ""
	)
	_check(
		"Snapshot: Bob vede però che Alice ha bloccato la scelta",
		_snapshot_locked(for_bob, "player_2")
	)
	_check(
		"Snapshot: Alice vede la propria scelta",
		_snapshot_action(for_alice, "player_2") == "guard"
	)
	_check(
		"Snapshot: chi non ha un giocatore non vede nessuna scelta",
		_snapshot_action(NetworkManager.build_snapshot_for(game, ""), "player_2") == ""
	)

	_check(
		"Snapshot: stato dell'RNG rimosso",
		for_bob["combat"]["rng"].is_empty()
	)
	_check(
		"Snapshot: seed della run nascosto",
		str(for_bob["run"]["seed"]) == "0"
	)

	_check(
		"Snapshot: lo stato dell'host non viene modificato",
		alice.selected_action_id == "guard"
		and game.combat.rng != null
		and game.run.seed == 12345
	)

	# Dopo il passaggio per JSON il client ricostruisce uno stato valido.
	var parsed: Variant = JSON.parse_string(JSON.stringify(for_bob))
	var client_game := GameState.new()

	if parsed is Dictionary:
		client_game.apply_dictionary(parsed)

	_check("Snapshot: il client lo accetta come stato valido", client_game.is_valid())
	_check(
		"Snapshot: il client non riceve l'RNG",
		client_game.combat != null and client_game.combat.rng == null
	)
	_check(
		"Snapshot: il client ha il boss e il round corretti",
		client_game.combat.boss.hp == 2000 and client_game.combat.round_state.number == 1
	)

	# Fuori dalla pianificazione le scelte non vengono più nascoste dal filtro,
	# ma l'RNG resta sempre rimosso.
	game.combat.phase = CombatState.Phase.ENDED
	var ended: Dictionary = NetworkManager.build_snapshot_for(game, "player_3")
	_check(
		"Snapshot: a combattimento chiuso l'RNG resta nascosto",
		ended["combat"]["rng"].is_empty()
	)

	# Senza combattimento il filtro non si rompe.
	var empty_game := GameState.new()
	empty_game.setup("vuoto", 1, 1, 2)
	var no_combat: Dictionary = NetworkManager.build_snapshot_for(empty_game, "x")
	_check("Snapshot: funziona anche senza combattimento", no_combat.has("session"))


func _snapshot_player(snapshot: Dictionary, player_id: String) -> Dictionary:
	for slot_data in snapshot["party"]["slots"]:
		var player_data: Dictionary = slot_data.get("player_data", {})

		if str(player_data.get("id", "")) == player_id:
			return player_data

	return {}


func _snapshot_action(snapshot: Dictionary, player_id: String) -> String:
	return str(_snapshot_player(snapshot, player_id).get("selected_action_id", "?"))


func _snapshot_locked(snapshot: Dictionary, player_id: String) -> bool:
	return bool(_snapshot_player(snapshot, player_id).get("is_locked", false))

