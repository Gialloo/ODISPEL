
extends SceneTree

const TIMEOUT_SECONDS := 15.0

var peer_a: WebRTCPeerConnection
var peer_b: WebRTCPeerConnection
var channel_a: WebRTCDataChannel
var channel_b: WebRTCDataChannel

var offer_ready := false
var answer_ready := false
var answer_requested := false
var message_sent := false
var message_received := false
var elapsed := 0.0

func _initialize() -> void:
	print("=== ODISPEL WEBRTC CONNECTION TEST ===")
	call_deferred("run_test")

func run_test() -> void:
	peer_a = WebRTCPeerConnection.new()
	peer_b = WebRTCPeerConnection.new()

	if peer_a.initialize({"iceServers": []}) != OK:
		fail_test("Inizializzazione peer A fallita.")
		return

	if peer_b.initialize({"iceServers": []}) != OK:
		fail_test("Inizializzazione peer B fallita.")
		return

	peer_a.session_description_created.connect(_on_description_a)
	peer_b.session_description_created.connect(_on_description_b)
	peer_a.ice_candidate_created.connect(_on_ice_a)
	peer_b.ice_candidate_created.connect(_on_ice_b)

	channel_a = peer_a.create_data_channel("odispel-test", {
		"negotiated": true,
		"id": 1
	})
	channel_b = peer_b.create_data_channel("odispel-test", {
		"negotiated": true,
		"id": 1
	})

	if channel_a == null or channel_b == null:
		fail_test("Creazione dei data channel fallita.")
		return

	var err: int = peer_a.create_offer()
	if err != OK:
		fail_test("create_offer fallito: " + str(err))
		return

	while elapsed < TIMEOUT_SECONDS:
		peer_a.poll()
		peer_b.poll()


		if (
			channel_a.get_ready_state() == WebRTCDataChannel.STATE_OPEN
			and channel_b.get_ready_state() == WebRTCDataChannel.STATE_OPEN
		):
			if not message_sent:
				channel_a.put_packet("ODISPEL_WEBRTC_OK".to_utf8_buffer())
				message_sent = true
				print("Canale aperto: messaggio inviato.")

			if channel_b.get_available_packet_count() > 0:
				var received := channel_b.get_packet().get_string_from_utf8()
				print("Messaggio ricevuto da B: ", received)

				if received == "ODISPEL_WEBRTC_OK":
					message_received = true
					print("PASS: connessione WebRTC e scambio dati riusciti.")
					cleanup()
					quit(0)
					return

		await create_timer(0.1).timeout
		elapsed += 0.1

	fail_test("Timeout durante la negoziazione WebRTC.")

func _on_description_a(type: String, sdp: String) -> void:
	print("Peer A ha creato descrizione: ", type)
	peer_a.set_local_description(type, sdp)

	if type == "offer":
		peer_b.set_remote_description(type, sdp)
		offer_ready = true

func _on_description_b(type: String, sdp: String) -> void:
	print("Peer B ha creato descrizione: ", type)
	peer_b.set_local_description(type, sdp)

	if type == "answer":
		peer_a.set_remote_description(type, sdp)
		answer_ready = true

func _on_ice_a(media: String, index: int, name: String) -> void:
	peer_b.add_ice_candidate(media, index, name)

func _on_ice_b(media: String, index: int, name: String) -> void:
	peer_a.add_ice_candidate(media, index, name)

func fail_test(reason: String) -> void:
	print("FAIL: ", reason)
	cleanup()
	quit(1)

func cleanup() -> void:
	if peer_a != null:
		peer_a.close()
	if peer_b != null:
		peer_b.close()
