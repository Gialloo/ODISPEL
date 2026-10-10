class_name NetworkManager
extends Node

signal room_joined
signal player_assigned(player_id: String)
signal snapshot_received
signal round_result_received(events: Array)
signal player_left(player_id: String)
signal network_error(reason: String)

# Il signaling si è chiuso ma i collegamenti di gioco già aperti continuano.
signal signaling_lost

# Il client riprova a entrare perché l'host non c'è ancora.
signal waiting_for_host(attempt: int)

const SIGNALING_CONNECT_TIMEOUT_MSEC: int = 10000
const LINK_OPEN_TIMEOUT_MSEC: int = 20000

var is_host: bool = false
var game: GameState = null
var player_level: int = 1

# Timer di pianificazione: lo fa scorrere solo l'host, e solo se attivato
# (altrimenti scadrebbe mentre si aspetta che entrino i giocatori).
var planning_timer_enabled: bool = false
var local_player_id: String = ""
var my_peer_id: String = ""

# Token segreto del client: permette di riprendere lo stesso giocatore
# dopo una disconnessione. Si può salvare e reimpostare prima di start_client().
var session_token: String = ""

# Tentativi di ingresso del client se l'host non ha ancora creato la stanza.
var join_retry_limit: int = 15
var join_retry_interval: float = 2.0

var _socket := WebSocketPeer.new()
var _room_id: String = ""
var _display_name: String = ""
var _host_peer_id: String = ""
var _links: Dictionary = {}         # peer_id -> WebRTCLink
var _peer_players: Dictionary = {}  # peer_id -> player_id
var _peer_numbers: Dictionary = {}  # peer_id -> numero di peer di gioco
var _player_tokens: Dictionary = {} # token -> player_id (slot riservati)
var _peer_counter: int = 1
var _link_created: Dictionary = {}  # peer_id -> ms di creazione del link

var _shutting_down: bool = false
var _socket_was_open: bool = false
var _signaling_reported: bool = false
var _connect_started_msec: int = 0
var _join_attempts: int = 0
var _join_retry_in: float = -1.0


func start_host(
	host_game: GameState,
	url: String,
	room_id: String,
	display_name: String
) -> bool:
	if host_game == null or host_game.party == null:
		return false

	var players: Array = host_game.party.get_players()

	if players.is_empty():
		return false

	is_host = true
	game = host_game
	local_player_id = (players[0] as PlayerState).id
	_prepare_host_party()
	return _connect(url, room_id, display_name)


func start_client(url: String, room_id: String, display_name: String) -> bool:
	is_host = false

	if session_token.is_empty():
		session_token = Crypto.new().generate_random_bytes(16).hex_encode()

	return _connect(url, room_id, display_name)


func host_submit_action(action_id: String) -> bool:
	if not is_host:
		return false

	return _host_apply_action(local_player_id, action_id)


func submit_action(action_id: String) -> bool:
	if is_host:
		return host_submit_action(action_id)

	var link: WebRTCLink = _links.get(_host_peer_id)

	if link == null:
		return false

	return link.send_message({"type": "action", "action_id": action_id})


# Giocatori umani attualmente collegati (host compreso).
func get_connected_human_count() -> int:
	if game == null or game.party == null:
		return 0

	var count: int = 0

	for player: PlayerState in game.party.get_players():
		if player.connected and not player.controlled_by_ai:
			count += 1

	return count


# Toglie dal party i posti che nessuno ha mai occupato.
# Chi è entrato e poi è uscito resta (può rientrare, nel frattempo gioca l'IA).
func host_remove_unfilled_players() -> int:
	if not is_host or game == null:
		return 0

	var reserved: Array = _player_tokens.values()
	var removed: int = 0

	for player: PlayerState in game.party.get_players():
		if player.id == local_player_id:
			continue

		if player.connected or reserved.has(player.id):
			continue

		if game.party.remove_player(player.id):
			removed += 1

	return removed


# Avvia il combattimento per tutti. Servono l'host e almeno un client.
func host_start_combat(
	boss_id: String,
	boss_name: String,
	boss_hp: int,
	run_seed: int
) -> bool:
	if not is_host or game == null:
		return false

	if boss_id.is_empty() or boss_hp <= 0 or run_seed == 0:
		return false

	if game.combat != null and not game.combat.is_finished():
		return false

	if get_connected_human_count() < 2:
		return false

	host_remove_unfilled_players()

	if not game.setup_run("net_" + str(run_seed), run_seed, "start"):
		return false

	if not game.begin_combat(boss_id, boss_name, boss_hp):
		return false

	set_planning_timer_enabled(true)
	_broadcast_snapshot()
	return true


# Attiva o disattiva il timer dei round. Attivandolo riparte da capo.
func set_planning_timer_enabled(enabled: bool) -> void:
	planning_timer_enabled = enabled

	if (
		enabled
		and game != null
		and game.combat != null
		and game.combat.round_state != null
	):
		game.combat.round_state.begin()


func shutdown() -> void:
	# Prima il flag: la chiusura volontaria non è un errore.
	_shutting_down = true

	for link: WebRTCLink in _links.values():
		link.close()

	_links.clear()
	_link_created.clear()
	_socket.close()


func _connect(url: String, room_id: String, display_name: String) -> bool:
	_room_id = room_id
	_display_name = display_name
	_shutting_down = false
	_socket_was_open = false
	_signaling_reported = false
	_join_attempts = 0
	_join_retry_in = -1.0
	_connect_started_msec = Time.get_ticks_msec()
	return _socket.connect_to_url(url) == OK


func _process(delta: float) -> void:
	if _shutting_down:
		return

	_socket.poll()
	_check_signaling_state(Time.get_ticks_msec())
	_tick_join_retry(delta)

	while _socket.get_available_packet_count() > 0:
		var data: Variant = WebRTCLink.parse_json(
			_socket.get_packet().get_string_from_utf8()
		)

		if data is Dictionary:
			_handle_signaling(data)

	for link: WebRTCLink in _links.values():
		link.poll()

	_check_link_timeouts(Time.get_ticks_msec())
	_tick_planning_timer(delta)


func _send_join() -> void:
	if _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return

	_socket.send_text(JSON.stringify({
		"type": "join",
		"room_id": _room_id,
		"role": "host" if is_host else "client"
	}))


func _tick_join_retry(delta: float) -> void:
	if _join_retry_in < 0.0:
		return

	_join_retry_in -= delta

	if _join_retry_in <= 0.0:
		_join_retry_in = -1.0
		_send_join()


# Controlla la connessione al server di signaling.
func _check_signaling_state(now_msec: int) -> void:
	if _signaling_reported:
		return

	var state: int = _socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		_socket_was_open = true
		return

	if state == WebSocketPeer.STATE_CONNECTING:
		if now_msec - _connect_started_msec >= SIGNALING_CONNECT_TIMEOUT_MSEC:
			_signaling_reported = true
			_socket.close()
			network_error.emit("signaling non raggiungibile")

		return

	if state != WebSocketPeer.STATE_CLOSED:
		return

	if _connect_started_msec == 0:
		return

	_signaling_reported = true

	if not _socket_was_open:
		network_error.emit("signaling non raggiungibile")
		return

	# I collegamenti già aperti continuano a funzionare senza signaling.
	if _has_open_game_link():
		signaling_lost.emit()
	else:
		network_error.emit("signaling disconnesso")


func _has_open_game_link() -> bool:
	for link: WebRTCLink in _links.values():
		if link.has_been_open():
			return true

	return false


# Un collegamento che non si apre entro il tempo limite viene abbandonato.
func _check_link_timeouts(now_msec: int) -> void:
	for peer_id: String in _link_created.keys():
		var link: WebRTCLink = _links.get(peer_id)

		if link == null:
			_link_created.erase(peer_id)
			continue

		if link.has_been_open():
			_link_created.erase(peer_id)
			continue

		if now_msec - int(_link_created[peer_id]) < LINK_OPEN_TIMEOUT_MSEC:
			continue

		_link_created.erase(peer_id)

		if is_host:
			_drop_peer(peer_id)
		else:
			network_error.emit("connessione con l'host non riuscita")


func _handle_signaling(data: Dictionary) -> void:
	match str(data.get("type", "")):
		"connected":
			_send_join()

		"joined":
			my_peer_id = str(data.get("peer_id", ""))
			_join_attempts = 0
			_join_retry_in = -1.0

			if not is_host:
				# È il server a dire chi è l'host della stanza.
				_host_peer_id = str(data.get("host_peer_id", ""))

				if _host_peer_id.is_empty():
					network_error.emit("nessun host nella stanza")
					return

				_create_link(_host_peer_id, false)

			room_joined.emit()

		"peer_joined":
			if is_host:
				var new_peer: String = str(data.get("peer_id", ""))
				_create_link(new_peer, true)
				(_links[new_peer] as WebRTCLink).start()

		"peer_left":
			# Il server lo manda solo all'host, quando esce un client.
			if is_host:
				_drop_peer(str(data.get("peer_id", "")))

		"room_closed":
			# L'host è uscito: il server ha chiuso la stanza.
			if not is_host:
				network_error.emit("host disconnesso")

		"offer", "answer", "ice_candidate":
			var from_peer: String = str(data.get("from_peer_id", ""))
			var payload: Variant = data.get("payload", {})
			var link: WebRTCLink = _links.get(from_peer)

			if link != null and payload is Dictionary:
				link.handle_signal(str(data["type"]), payload)

		"error":
			match str(data.get("code", "?")):
				"no_host":
					_on_no_host()
				"room_taken":
					network_error.emit("stanza già occupata: l'host deve crearla")
				var code:
					network_error.emit("signaling: " + code)


# L'host potrebbe non aver ancora creato la stanza: il client riprova.
func _on_no_host() -> void:
	if not is_host and _join_attempts < join_retry_limit:
		_join_attempts += 1
		_join_retry_in = join_retry_interval
		waiting_for_host.emit(_join_attempts)
		return

	network_error.emit("nessun host nella stanza")


func _create_link(peer_id: String, initiator: bool) -> void:
	var link := WebRTCLink.new()

	if not link.setup(initiator):
		network_error.emit("setup WebRTC fallito")
		return

	link.outgoing_signal.connect(_on_link_signal.bind(peer_id))
	link.channel_opened.connect(_on_link_opened.bind(peer_id))
	link.channel_closed.connect(_on_link_closed.bind(peer_id))
	link.message_received.connect(_on_link_message.bind(peer_id))
	_links[peer_id] = link
	_link_created[peer_id] = Time.get_ticks_msec()


func _on_link_signal(type: String, payload: Dictionary, peer_id: String) -> void:
	if _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return

	_socket.send_text(JSON.stringify({
		"type": type,
		"target_peer_id": peer_id,
		"payload": payload
	}))


func _on_link_opened(peer_id: String) -> void:
	if not is_host:
		var link: WebRTCLink = _links.get(peer_id)

		if link != null:
			link.send_message({
				"type": "hello",
				"name": _display_name,
				"token": session_token
			})


func _on_link_closed(peer_id: String) -> void:
	if _shutting_down:
		return

	if is_host:
		_drop_peer(peer_id)
	else:
		network_error.emit("collegamento con l'host chiuso")


func _on_link_message(message: Dictionary, peer_id: String) -> void:
	if is_host:
		_host_handle_message(message, peer_id)
	else:
		_client_handle_message(message)


# ---------- HOST ----------

func _host_handle_message(message: Dictionary, peer_id: String) -> void:
	match str(message.get("type", "")):
		"hello":
			_host_handle_hello(peer_id, message)

		"action":
			var player_id: String = str(_peer_players.get(peer_id, ""))

			if player_id.is_empty():
				return

			_host_apply_action(player_id, str(message.get("action_id", "")))


func _host_apply_action(player_id: String, action_id: String) -> bool:
	if not CombatResolver.submit_action(game, player_id, action_id):
		return false

	_host_try_resolve()
	_broadcast_snapshot()
	return true


func _host_try_resolve() -> void:
	if not CombatResolver.can_resolve(game):
		return

	_host_publish_round(CombatResolver.resolve_round(game, player_level))


func _host_publish_round(result: Dictionary) -> void:
	if result["ok"]:
		_broadcast({"type": "round_result", "events": result["events"]})
		round_result_received.emit(result["events"])


# Scaduto il tempo: chi non ha scelto attacca in automatico.
func _host_force_resolve() -> void:
	if not CombatResolver.can_force_resolve(game):
		return

	_host_publish_round(CombatResolver.resolve_round(game, player_level, true))
	_broadcast_snapshot()


func _tick_planning_timer(delta: float) -> void:
	if game == null or game.combat == null:
		return

	var combat: CombatState = game.combat

	if combat.phase != CombatState.Phase.PLANNING or combat.round_state == null:
		return

	if not is_host:
		# Solo per mostrare il conto alla rovescia: l'host resta l'autorità
		# e lo snapshot successivo corregge il valore.
		combat.update_planning_timer(delta)
		return

	if not planning_timer_enabled:
		return

	combat.update_planning_timer(delta)

	if combat.round_state.is_planning_finished():
		_host_force_resolve()


func _host_handle_hello(peer_id: String, message: Dictionary) -> void:
	if _peer_players.has(peer_id):
		return

	var link: WebRTCLink = _links.get(peer_id)

	if link == null:
		return

	var token: String = str(message.get("token", "")).strip_edges()

	if token.is_empty() or token.length() > 64:
		link.send_message({"type": "error", "code": "invalid_token"})
		return

	var player: PlayerState = null

	if _player_tokens.has(token):
		# Rientro: lo stesso token riprende lo stesso giocatore.
		player = game.party.get_player_by_id(str(_player_tokens[token]))

		if player == null:
			link.send_message({"type": "error", "code": "join_failed"})
			return

		# Se un vecchio collegamento è ancora aperto, il nuovo lo sostituisce.
		var old_peer: String = _peer_for_player(player.id)

		if not old_peer.is_empty() and old_peer != peer_id:
			_drop_peer(old_peer, false)
	else:
		if not _is_joining_open():
			link.send_message({"type": "error", "code": "game_in_progress"})
			return

		player = _find_free_player()

		if player == null:
			link.send_message({"type": "error", "code": "room_full"})
			return

	var peer_number: int = _allocate_peer_number()

	if not game.party.reconnect_player(player.id, peer_number):
		link.send_message({"type": "error", "code": "join_failed"})
		return

	var wanted_name: String = str(message.get("name", "")).strip_edges()

	if not wanted_name.is_empty():
		player.display_name = wanted_name.substr(0, 24)

	_peer_players[peer_id] = player.id
	_peer_numbers[peer_id] = peer_number
	_player_tokens[token] = player.id

	link.send_message({"type": "welcome", "player_id": player.id})
	player_assigned.emit(player.id)
	_broadcast_snapshot()


# Gli slot non ancora occupati da un giocatore reale non devono
# bloccare il round: si segnano come disconnessi finché non entra qualcuno.
func _prepare_host_party() -> void:
	var reserved: Array = _player_tokens.values()

	for player: PlayerState in game.party.get_players():
		if player.id != local_player_id and not reserved.has(player.id):
			game.party.disconnect_player(player.id)


# I nuovi giocatori possono entrare solo prima che il combattimento
# superi il primo round. Chi ha già un token può sempre rientrare.
func _is_joining_open() -> bool:
	if game.combat == null:
		return true

	if game.combat.is_finished():
		return false

	var round_state: RoundState = game.combat.round_state

	return round_state != null and round_state.number <= 1


func _allocate_peer_number() -> int:
	var highest: int = _peer_counter

	for player: PlayerState in game.party.get_players():
		highest = maxi(highest, player.network_peer_id)

	_peer_counter = highest + 1
	return _peer_counter


func _peer_for_player(player_id: String) -> String:
	for peer_id: String in _peer_players:
		if _peer_players[peer_id] == player_id:
			return peer_id

	return ""


func _find_free_player() -> PlayerState:
	var taken: Array = _peer_players.values()
	var reserved: Array = _player_tokens.values()

	for player: PlayerState in game.party.get_players():
		if player.id == local_player_id:
			continue

		if taken.has(player.id) or reserved.has(player.id):
			continue

		return player

	return null


# notify = false: sostituzione silenziosa (il giocatore rientra subito),
# senza segnarlo disconnesso né risolvere il round.
func _drop_peer(peer_id: String, notify: bool = true) -> void:
	if not _links.has(peer_id):
		return

	var link: WebRTCLink = _links[peer_id]
	_links.erase(peer_id)
	_link_created.erase(peer_id)
	_peer_numbers.erase(peer_id)
	link.close()

	if not _peer_players.has(peer_id):
		return

	var player_id: String = _peer_players[peer_id]
	_peer_players.erase(peer_id)

	if not notify:
		return

	# Passa dal party, così anche lo slot resta coerente con il giocatore.
	game.party.disconnect_player(player_id)

	player_left.emit(player_id)
	_host_try_resolve()
	_broadcast_snapshot()


func _broadcast(message: Dictionary) -> void:
	for link: WebRTCLink in _links.values():
		link.send_message(message)


func _broadcast_snapshot() -> void:
	# Ogni client riceve la sua versione dello stato, senza i segreti.
	for peer_id: String in _links.keys():
		var link: WebRTCLink = _links[peer_id]
		var viewer_id: String = str(_peer_players.get(peer_id, ""))

		link.send_message({
			"type": "snapshot",
			"state": build_snapshot_for(game, viewer_id)
		})

	snapshot_received.emit()


# Stato di gioco come lo può vedere un singolo giocatore.
# Tolti (l'host ha lo stato completo):
#   - seed dell'RNG e stato del generatore: con quelli un client modificato
#     potrebbe prevedere i bersagli del boss;
#   - le azioni scelte dagli altri giocatori durante la pianificazione
#     (resta visibile solo che hanno "bloccato" la scelta).
# L'identificativo vuoto vale per chi non ha ancora un giocatore assegnato.
static func build_snapshot_for(
	game_state: GameState,
	viewer_player_id: String
) -> Dictionary:
	var data: Dictionary = game_state.to_dictionary()

	var run_data: Variant = data.get("run", {})

	if run_data is Dictionary and not run_data.is_empty():
		run_data["seed"] = "0"

	var combat_data: Variant = data.get("combat", {})

	if not (combat_data is Dictionary) or combat_data.is_empty():
		return data

	combat_data["rng"] = {}

	if int(combat_data.get("phase", -1)) != int(CombatState.Phase.PLANNING):
		return data

	var party_data: Variant = data.get("party", {})

	if not (party_data is Dictionary):
		return data

	for slot_data in party_data.get("slots", []):
		var player_data: Variant = slot_data.get("player_data", {})

		if not (player_data is Dictionary) or player_data.is_empty():
			continue

		if str(player_data.get("id", "")) != viewer_player_id:
			player_data["selected_action_id"] = ""

	return data


# ---------- CLIENT ----------

func _client_handle_message(message: Dictionary) -> void:
	match str(message.get("type", "")):
		"welcome":
			local_player_id = str(message.get("player_id", ""))
			player_assigned.emit(local_player_id)

		"snapshot":
			var state: Variant = message.get("state", {})

			if state is Dictionary:
				if game == null:
					game = GameState.new()

				game.apply_dictionary(state)
				snapshot_received.emit()

		"round_result":
			var events: Variant = message.get("events", [])

			if events is Array:
				round_result_received.emit(events)

		"error":
			network_error.emit("host: " + str(message.get("code", "?")))
