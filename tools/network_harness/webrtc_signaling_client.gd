
extends SceneTree

const SERVER_URL := "ws://127.0.0.1:9080"
const ROOM_ID := "odispel-webrtc-real"
const TIMEOUT_SECONDS := 30.0
const TEST_MESSAGE := "ODISPEL_WEBRTC_SIGNALING_OK"
const REPLY_MESSAGE := "ODISPEL_WEBRTC_REPLY_OK"

var role := ""
var socket := WebSocketPeer.new()
var peer: WebRTCPeerConnection
var channel: WebRTCDataChannel

var peer_id := ""
var remote_peer_id := ""
var joined := false
var remote_description_set := false
var offer_started := false
var message_sent := false
var message_received := false
var elapsed := 0.0

var pending_ice: Array[Dictionary] = []
var pending_signals: Array[Dictionary] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()

	if args.is_empty() or not ["A", "B"].has(args[0]):
		print("USO: aggiungere -- A oppure -- B")
		quit(1)
		return

	role = args[0]
	print("=== ODISPEL WEBRTC CLIENT ", role, " ===")
	call_deferred("run_test")


func run_test() -> void:
	peer = WebRTCPeerConnection.new()

	var err: int = peer.initialize({"iceServers": []})
	if err != OK:
		fail_test("Inizializzazione WebRTC fallita: " + str(err))
		return

	peer.session_description_created.connect(_on_description_created)
	peer.ice_candidate_created.connect(_on_ice_candidate)

	var connect_err := socket.connect_to_url(SERVER_URL)
	if connect_err != OK:
		fail_test("Connessione signaling fallita: " + str(connect_err))
		return

	while elapsed < TIMEOUT_SECONDS:
		socket.poll()
		peer.poll()

		while socket.get_available_packet_count() > 0:
			var raw := socket.get_packet().get_string_from_utf8()
			print("Signaling: ", raw)

			var data = JSON.parse_string(raw)
			if data is Dictionary:
				handle_signaling(data)

		if channel != null:
			channel.poll()

			if (
				role == "A"
				and not message_sent
				and channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN
			):
				var send_err := channel.put_packet(
					TEST_MESSAGE.to_utf8_buffer()
				)

				if send_err == OK:
					message_sent = true
					print("A: messaggio inviato.")
				else:
					fail_test(
						"Invio del messaggio iniziale fallito: "
						+ str(send_err)
					)
					return

			if (
				channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN
				and channel.get_available_packet_count() > 0
			):
				var received := channel.get_packet().get_string_from_utf8()
				print(role, ": messaggio ricevuto: ", received)

				if role == "B" and received == TEST_MESSAGE:
					var reply_err := channel.put_packet(
						REPLY_MESSAGE.to_utf8_buffer()
					)

					if reply_err == OK:
						print("B: risposta inviata.")
					else:
						fail_test(
							"Invio della risposta fallito: "
							+ str(reply_err)
						)
						return

				elif role == "A" and received == REPLY_MESSAGE:
					message_received = true
					print(
						"PASS: comunicazione WebRTC bidirezionale riuscita."
					)
					cleanup()
					quit(0)
					return

		await create_timer(0.1).timeout
		elapsed += 0.1

	fail_test("Timeout durante la connessione.")


func handle_signaling(data: Dictionary) -> void:
	match str(data.get("type", "")):
		"connected":
			peer_id = str(data.get("peer_id", ""))
			socket.send_text(JSON.stringify({
				"type": "join",
				"room_id": ROOM_ID
			}))

		"joined":
			joined = true
			var peers = data.get("peers", [])

			if role == "B" and peers is Array and not peers.is_empty():
				remote_peer_id = str(peers[0])
				flush_pending_signals()
				create_data_channel_if_needed()

		"peer_joined":
			remote_peer_id = str(data.get("peer_id", ""))
			flush_pending_signals()

			if role == "A" and not offer_started:
				offer_started = true
				create_data_channel_if_needed()

				if channel == null:
					fail_test("Creazione data channel A fallita.")
					return

				var err: int = peer.create_offer()
				if err != OK:
					fail_test("Creazione offer fallita: " + str(err))

		"offer":
			if role != "B":
				return

			remote_peer_id = str(data.get("from_peer_id", ""))
			flush_pending_signals()

			var payload = data.get("payload", {})
			if not payload is Dictionary:
				fail_test("Payload offer non valido.")
				return

			var sdp := str(payload.get("sdp", ""))
			if sdp.is_empty():
				fail_test("Offer ricevuta senza SDP.")
				return

			var err: int = peer.set_remote_description("offer", sdp)
			if err != OK:
				fail_test("Applicazione offer fallita: " + str(err))
				return

			remote_description_set = true
			flush_pending_ice()
			print("B: offer remota applicata.")

		"answer":
			if role != "A":
				return

			var payload = data.get("payload", {})
			if not payload is Dictionary:
				fail_test("Payload answer non valido.")
				return

			var sdp := str(payload.get("sdp", ""))
			if sdp.is_empty():
				fail_test("Answer ricevuta senza SDP.")
				return

			var err: int = peer.set_remote_description("answer", sdp)
			if err != OK:
				fail_test("Applicazione answer fallita: " + str(err))
				return

			remote_description_set = true
			flush_pending_ice()
			print("A: answer remota applicata.")

		"ice_candidate":
			var payload = data.get("payload", {})
			if not payload is Dictionary:
				return

			if not remote_description_set:
				pending_ice.append(payload)
			else:
				add_ice_candidate_from_payload(payload)

		"error":
			fail_test(
				"Errore signaling: "
				+ str(data.get("code", "sconosciuto"))
			)


func create_data_channel_if_needed() -> void:
	if channel != null:
		return

	channel = peer.create_data_channel("odispel-test", {
		"negotiated": true,
		"id": 1
	})

	if channel == null:
		fail_test("Creazione data channel fallita.")
		return

	print(role, ": data channel creato.")


func _on_description_created(type: String, sdp: String) -> void:
	var err: int = peer.set_local_description(type, sdp)
	if err != OK:
		fail_test("Applicazione descrizione locale fallita: " + str(err))
		return

	if type == "offer":
		send_signal("offer", {"sdp": sdp})
	elif type == "answer":
		send_signal("answer", {"sdp": sdp})


func _on_ice_candidate(media: String, index: int, candidate: String) -> void:
	send_signal("ice_candidate", {
		"media": media,
		"index": index,
		"candidate": candidate
	})


func send_signal(type: String, payload: Dictionary) -> void:
	if remote_peer_id.is_empty():
		pending_signals.append({
			"type": type,
			"payload": payload
		})
		return

	socket.send_text(JSON.stringify({
		"type": type,
		"target_peer_id": remote_peer_id,
		"payload": payload
	}))


func flush_pending_signals() -> void:
	if remote_peer_id.is_empty():
		return

	for pending in pending_signals:
		socket.send_text(JSON.stringify({
			"type": str(pending.get("type", "")),
			"target_peer_id": remote_peer_id,
			"payload": pending.get("payload", {})
		}))

	pending_signals.clear()


func flush_pending_ice() -> void:
	for candidate in pending_ice:
		add_ice_candidate_from_payload(candidate)

	pending_ice.clear()


func add_ice_candidate_from_payload(payload: Dictionary) -> void:
	var media := str(payload.get("media", ""))
	var index := int(payload.get("index", 0))
	var candidate := str(payload.get("candidate", ""))

	var err: int = peer.add_ice_candidate(media, index, candidate)
	if err != OK:
		print("ATTENZIONE: add_ice_candidate ha restituito ", err)


func fail_test(reason: String) -> void:
	print("FAIL: ", reason)
	cleanup()
	quit(1)


func cleanup() -> void:
	if socket != null:
		socket.close()

	if peer != null:
		peer.close()
