extends SceneTree

const SERVER_URL: String = "ws://127.0.0.1:9080"
const ROOM_ID: String = "odispel-link-test"
const TIMEOUT_SECONDS: float = 30.0

var role: String = ""
var socket := WebSocketPeer.new()
var link: WebRTCLink = null
var remote_peer_id: String = ""
var elapsed: float = 0.0
var sent_ping: bool = false


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()

	if args.is_empty() or not ["A", "B"].has(args[0]):
		print("USO: aggiungere -- A oppure -- B")
		quit(1)
		return

	role = args[0]
	print("=== ODISPEL WEBRTC LINK TEST ", role, " ===")

	if socket.connect_to_url(SERVER_URL) != OK:
		_fail("Connessione signaling fallita.")


func _process(delta: float) -> bool:
	elapsed += delta

	if elapsed > TIMEOUT_SECONDS:
		_fail("Timeout.")
		return true

	socket.poll()

	while socket.get_available_packet_count() > 0:
		var data: Variant = JSON.parse_string(
			socket.get_packet().get_string_from_utf8()
		)

		if data is Dictionary:
			_handle_signaling(data)

	if link != null:
		link.poll()

	return false


func _handle_signaling(data: Dictionary) -> void:
	match str(data.get("type", "")):
		"connected":
			socket.send_text(JSON.stringify({
				"type": "join",
				"room_id": ROOM_ID,
				"role": "host" if role == "A" else "client"
			}))

		"joined":
			var peers: Variant = data.get("peers", [])

			# B entra per secondo e prepara il collegamento come ricevente.
			if role == "B" and peers is Array and not peers.is_empty():
				remote_peer_id = str(peers[0])
				_create_link(false)

		"peer_joined":
			# A vede arrivare B e crea l'offerta.
			if role == "A" and link == null:
				remote_peer_id = str(data.get("peer_id", ""))
				_create_link(true)
				link.start()

		"offer", "answer", "ice_candidate":
			var payload: Variant = data.get("payload", {})

			if link != null and payload is Dictionary:
				link.handle_signal(str(data["type"]), payload)

		"error":
			_fail("Errore signaling: " + str(data.get("code", "?")))


func _create_link(initiator: bool) -> void:
	link = WebRTCLink.new()

	if not link.setup(initiator):
		_fail("setup del link fallito.")
		return

	link.outgoing_signal.connect(_on_outgoing_signal)
	link.channel_opened.connect(_on_channel_opened)
	link.message_received.connect(_on_message_received)


func _on_outgoing_signal(type: String, payload: Dictionary) -> void:
	socket.send_text(JSON.stringify({
		"type": type,
		"target_peer_id": remote_peer_id,
		"payload": payload
	}))


func _on_channel_opened() -> void:
	print(role, ": canale aperto.")

	if role == "A" and not sent_ping:
		sent_ping = true
		link.send_message({
			"type": "ping",
			"n": 7,
			"data": {"azione": "attack", "lista": [1, 2, 3]}
		})
		print("A: ping inviato.")


func _on_message_received(message: Dictionary) -> void:
	print(role, ": ricevuto ", JSON.stringify(message))

	if role == "B" and message.get("type") == "ping":
		var ok: bool = (
			int(message.get("n", 0)) == 7
			and message.get("data", {}).get("azione") == "attack"
		)

		if not ok:
			_fail("Contenuto del ping errato.")
			return

		link.send_message({"type": "pong", "n": 8})
		print("B: pong inviato.")

	elif role == "A" and message.get("type") == "pong":
		print("PASS: WebRTCLink, messaggi JSON bidirezionali riusciti.")
		_cleanup()
		quit(0)


func _fail(reason: String) -> void:
	print("FAIL: ", reason)
	_cleanup()
	quit(1)


func _cleanup() -> void:
	socket.close()

	if link != null:
		link.close()
