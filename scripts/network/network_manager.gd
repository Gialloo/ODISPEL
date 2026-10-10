class_name NetworkManager
extends Node

signal room_joined
signal player_assigned(player_id: String)
signal snapshot_received
signal round_result_received(events: Array)
signal player_left(player_id: String)
signal network_error(reason: String)

var is_host: bool = false
var game: GameState = null
var player_level: int = 1
var local_player_id: String = ""
var my_peer_id: String = ""

var _socket := WebSocketPeer.new()
var _room_id: String = ""
var _display_name: String = ""
var _host_peer_id: String = ""
var _links: Dictionary = {}         # peer_id -> WebRTCLink
var _peer_players: Dictionary = {}  # peer_id -> player_id


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
	return _connect(url, room_id, display_name)


func start_client(url: String, room_id: String, display_name: String) -> bool:
	is_host = false
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


func shutdown() -> void:
	for link: WebRTCLink in _links.values():
		link.close()

	_links.clear()
	_socket.close()


func _connect(url: String, room_id: String, display_name: String) -> bool:
	_room_id = room_id
	_display_name = display_name
	return _socket.connect_to_url(url) == OK


func _process(_delta: float) -> void:
	_socket.poll()

	while _socket.get_available_packet_count() > 0:
		var data: Variant = JSON.parse_string(
			_socket.get_packet().get_string_from_utf8()
		)

		if data is Dictionary:
			_handle_signaling(data)

	for link: WebRTCLink in _links.values():
		link.poll()


func _handle_signaling(data: Dictionary) -> void:
	match str(data.get("type", "")):
		"connected":
			_socket.send_text(JSON.stringify({
				"type": "join",
				"room_id": _room_id
			}))

		"joined":
			my_peer_id = str(data.get("peer_id", ""))
			var peers: Variant = data.get("peers", [])

			if is_host and peers is Array and not peers.is_empty():
				network_error.emit("stanza già occupata: l'host deve crearla")
				return

			if not is_host:
				if not (peers is Array) or peers.is_empty():
					network_error.emit("nessun host nella stanza")
					return

				# Il primo peer della stanza è l'host.
				_host_peer_id = str(peers[0])
				_create_link(_host_peer_id, false)

			room_joined.emit()

		"peer_joined":
			if is_host:
				var new_peer: String = str(data.get("peer_id", ""))
				_create_link(new_peer, true)
				(_links[new_peer] as WebRTCLink).start()

		"peer_left":
			var left_peer: String = str(data.get("peer_id", ""))

			if is_host:
				_drop_peer(left_peer)
			elif left_peer == _host_peer_id:
				network_error.emit("host disconnesso")

		"offer", "answer", "ice_candidate":
			var from_peer: String = str(data.get("from_peer_id", ""))
			var payload: Variant = data.get("payload", {})
			var link: WebRTCLink = _links.get(from_peer)

			if link != null and payload is Dictionary:
				link.handle_signal(str(data["type"]), payload)

		"error":
			network_error.emit("signaling: " + str(data.get("code", "?")))


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


func _on_link_signal(type: String, payload: Dictionary, peer_id: String) -> void:
	_socket.send_text(JSON.stringify({
		"type": type,
		"target_peer_id": peer_id,
		"payload": payload
	}))


func _on_link_opened(peer_id: String) -> void:
	if not is_host:
		var link: WebRTCLink = _links.get(peer_id)

		if link != null:
			link.send_message({"type": "hello", "name": _display_name})


func _on_link_closed(peer_id: String) -> void:
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
			if _peer_players.has(peer_id):
				return

			var player: PlayerState = _find_free_player()
			var link: WebRTCLink = _links.get(peer_id)

			if link == null:
				return

			if player == null:
				link.send_message({"type": "error", "code": "room_full"})
				return

			var wanted_name: String = str(message.get("name", "")).strip_edges()

			if not wanted_name.is_empty():
				player.display_name = wanted_name.substr(0, 24)

			_peer_players[peer_id] = player.id
			link.send_message({"type": "welcome", "player_id": player.id})
			player_assigned.emit(player.id)
			_broadcast_snapshot()

		"action":
			var player_id: String = str(_peer_players.get(peer_id, ""))

			if player_id.is_empty():
				return

			_host_apply_action(player_id, str(message.get("action_id", "")))


func _host_apply_action(player_id: String, action_id: String) -> bool:
	if not CombatResolver.submit_action(game, player_id, action_id):
		return false

	if CombatResolver.can_resolve(game):
		var result: Dictionary = CombatResolver.resolve_round(game, player_level)

		if result["ok"]:
			_broadcast({"type": "round_result", "events": result["events"]})
			round_result_received.emit(result["events"])

	_broadcast_snapshot()
	return true


func _find_free_player() -> PlayerState:
	var taken: Array = _peer_players.values()

	for player: PlayerState in game.party.get_players():
		if player.id != local_player_id and not taken.has(player.id):
			return player

	return null


func _drop_peer(peer_id: String) -> void:
	if not _links.has(peer_id):
		return

	var link: WebRTCLink = _links[peer_id]
	_links.erase(peer_id)
	link.close()

	if _peer_players.has(peer_id):
		var player_id: String = _peer_players[peer_id]
		_peer_players.erase(peer_id)

		for player: PlayerState in game.party.get_players():
			if player.id == player_id:
				player.disconnect_player()

		player_left.emit(player_id)
		_broadcast_snapshot()


func _broadcast(message: Dictionary) -> void:
	for link: WebRTCLink in _links.values():
		link.send_message(message)


func _broadcast_snapshot() -> void:
	_broadcast({"type": "snapshot", "state": game.to_dictionary()})
	snapshot_received.emit()


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
