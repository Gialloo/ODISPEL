
extends SceneTree

const SERVER_URL := "ws://127.0.0.1:9080"
const ROOM_ID := "test-godot-odispel"
const TIMEOUT_SECONDS := 5.0

func _initialize() -> void:
	print("=== ODISPEL ROOM JOIN TEST ===")
	call_deferred("run_test")

func run_test() -> void:
	var socket := WebSocketPeer.new()
	var error := socket.connect_to_url(SERVER_URL)

	if error != OK:
		print("ERRORE: connessione non avviata. Codice: ", error)
		quit(1)
		return

	var elapsed := 0.0
	var peer_id := ""
	var join_sent := false

	while elapsed < TIMEOUT_SECONDS:
		socket.poll()

		if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
			while socket.get_available_packet_count() > 0:
				var message_text := socket.get_packet().get_string_from_utf8()
				print("Ricevuto: ", message_text)

				var parsed = JSON.parse_string(message_text)
				if not parsed is Dictionary:
					continue

				if parsed.get("type") == "connected":
					peer_id = str(parsed.get("peer_id", ""))
					if peer_id.is_empty():
						print("ERRORE: peer_id assente.")
						socket.close()
						quit(1)
						return

					var join_message := {
						"type": "join",
						"room_id": ROOM_ID,
						"role": "host"
					}
					socket.send_text(JSON.stringify(join_message))
					join_sent = true
					print("Richiesta ingresso inviata: ", ROOM_ID)

				elif parsed.get("type") == "joined":
					print("PASS: ingresso nella stanza confermato.")
					print("Stanza: ", ROOM_ID)
					print("Peer ID: ", peer_id)
					socket.close()
					quit(0)
					return

				elif parsed.get("type") == "error":
					print("ERRORE server: ", message_text)
					socket.close()
					quit(1)
					return

		elif socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
			print("ERRORE: connessione chiusa.")
			print("Codice: ", socket.get_close_code())
			print("Motivo: ", socket.get_close_reason())
			quit(1)
			return

		await process_frame
		elapsed += 0.1

	print("ERRORE: timeout durante il test della stanza.")
	print("Richiesta inviata: ", join_sent)
	socket.close()
	quit(1)
