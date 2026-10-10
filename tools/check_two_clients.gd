
extends SceneTree

const SERVER_URL := "ws://127.0.0.1:9080"
const ROOM_ID := "test-relay-odispel"
const TIMEOUT_SECONDS := 8.0

var client_a := WebSocketPeer.new()
var client_b := WebSocketPeer.new()
var id_a := ""
var id_b := ""
var joined_a := false
var joined_b := false
var offer_sent := false
var offer_received := false

func _initialize() -> void:
	print("=== ODISPEL SIGNALING RELAY TEST ===")
	call_deferred("run_test")

func run_test() -> void:
	var error_a := client_a.connect_to_url(SERVER_URL)
	var error_b := client_b.connect_to_url(SERVER_URL)

	if error_a != OK or error_b != OK:
		print("ERRORE: connessione non avviata.")
		print("Client A: ", error_a, " | Client B: ", error_b)
		quit(1)
		return

	var elapsed := 0.0

	while elapsed < TIMEOUT_SECONDS:
		client_a.poll()
		client_b.poll()

		process_client(client_a, "A")
		process_client(client_b, "B")

		if joined_a and joined_b and offer_received:
			print("PASS: A ha inviato un'offer fittizia e B l'ha ricevuta.")
			client_a.close()
			client_b.close()
			quit(0)
			return

		await process_frame
		elapsed += 0.1

	print("ERRORE: timeout durante il relay.")
	print("joined_a=", joined_a, " joined_b=", joined_b)
	print("offer_sent=", offer_sent, " offer_received=", offer_received)
	client_a.close()
	client_b.close()
	quit(1)


func process_client(socket: WebSocketPeer, label: String) -> void:
	while socket.get_ready_state() == WebSocketPeer.STATE_OPEN and socket.get_available_packet_count() > 0:
		var raw := socket.get_packet().get_string_from_utf8()
		print("Client ", label, " riceve: ", raw)

		var data = JSON.parse_string(raw)
		if not data is Dictionary:
			continue

		if data.get("type") == "connected":
			var peer_id := str(data.get("peer_id", ""))

			if label == "A":
				id_a = peer_id
			else:
				id_b = peer_id

			socket.send_text(JSON.stringify({
				"type": "join",
				"room_id": ROOM_ID,
				"role": "host" if label == "A" else "client"
			}))

		elif data.get("type") == "joined" and data.get("room_id") == ROOM_ID:
			if label == "A":
				joined_a = true
			else:
				joined_b = true

		elif data.get("type") == "offer" and label == "B":
			if str(data.get("from_peer_id", "")) == id_a:
				var payload = data.get("payload", {})
				if payload is Dictionary and payload.get("sdp") == "ODISPEL_TEST_OFFER_NOT_REAL_WEBRTC":
					offer_received = true

	if joined_a and joined_b and not offer_sent and not id_b.is_empty() and label == "A":
		var offer_message := {
			"type": "offer",
			"target_peer_id": id_b,
			"payload": {
				"sdp": "ODISPEL_TEST_OFFER_NOT_REAL_WEBRTC"
			}
		}
		socket.send_text(JSON.stringify(offer_message))
		offer_sent = true
		print("Client A ha inviato un'offer fittizia a B.")
