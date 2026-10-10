class_name WebRTCLink
extends RefCounted

signal outgoing_signal(type: String, payload: Dictionary)
signal channel_opened
signal channel_closed
signal message_received(message: Dictionary)

const CHANNEL_NAME: String = "odispel-game"
const CHANNEL_ID: int = 1

var peer: WebRTCPeerConnection = null
var channel: WebRTCDataChannel = null
var is_initiator: bool = false

var _remote_description_set: bool = false
var _pending_ice: Array[Dictionary] = []
var _was_open: bool = false
var _closed_emitted: bool = false


func setup(initiator: bool) -> bool:
	is_initiator = initiator
	peer = WebRTCPeerConnection.new()

	var err: int = peer.initialize({"iceServers": []})
	if err != OK:
		push_error("WebRTCLink: initialize fallita: " + str(err))
		return false

	peer.session_description_created.connect(_on_description_created)
	peer.ice_candidate_created.connect(_on_ice_candidate_created)

	# Canale negoziato: entrambi i lati lo creano con lo stesso id.
	channel = peer.create_data_channel(CHANNEL_NAME, {
		"negotiated": true,
		"id": CHANNEL_ID
	})

	if channel == null:
		push_error("WebRTCLink: creazione canale fallita.")
		return false

	return true


func start() -> bool:
	if peer == null or not is_initiator:
		return false

	return peer.create_offer() == OK


func handle_signal(type: String, payload: Dictionary) -> void:
	if peer == null:
		return

	match type:
		"offer", "answer":
			var sdp: String = str(payload.get("sdp", ""))

			if sdp.is_empty():
				push_error("WebRTCLink: " + type + " senza SDP.")
				return

			if peer.set_remote_description(type, sdp) != OK:
				push_error("WebRTCLink: applicazione " + type + " fallita.")
				return

			_remote_description_set = true
			_flush_pending_ice()

		"ice_candidate":
			if _remote_description_set:
				_add_ice(payload)
			else:
				_pending_ice.append(payload)


func poll() -> void:
	if peer == null:
		return

	peer.poll()

	if channel == null:
		return

	channel.poll()

	var state: int = channel.get_ready_state()

	if state == WebRTCDataChannel.STATE_OPEN and not _was_open:
		_was_open = true
		channel_opened.emit()

	if state == WebRTCDataChannel.STATE_OPEN:
		while channel.get_available_packet_count() > 0:
			var raw: String = channel.get_packet().get_string_from_utf8()
			var parsed: Variant = JSON.parse_string(raw)

			if parsed is Dictionary:
				message_received.emit(parsed)
			else:
				push_warning("WebRTCLink: messaggio non valido scartato.")

	if state == WebRTCDataChannel.STATE_CLOSED and not _closed_emitted:
		_closed_emitted = true
		channel_closed.emit()


func send_message(message: Dictionary) -> bool:
	if not is_open():
		return false

	var text: String = JSON.stringify(message)
	return channel.put_packet(text.to_utf8_buffer()) == OK


func is_open() -> bool:
	return (
		channel != null
		and channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN
	)


func close() -> void:
	if peer != null:
		peer.close()

	if not _closed_emitted:
		_closed_emitted = true
		channel_closed.emit()


func _on_description_created(type: String, sdp: String) -> void:
	if peer.set_local_description(type, sdp) != OK:
		push_error("WebRTCLink: descrizione locale fallita.")
		return

	outgoing_signal.emit(type, {"sdp": sdp})


func _on_ice_candidate_created(media: String, index: int, candidate: String) -> void:
	outgoing_signal.emit("ice_candidate", {
		"media": media,
		"index": index,
		"candidate": candidate
	})


func _flush_pending_ice() -> void:
	for candidate in _pending_ice:
		_add_ice(candidate)

	_pending_ice.clear()


func _add_ice(payload: Dictionary) -> void:
	var err: int = peer.add_ice_candidate(
		str(payload.get("media", "")),
		int(payload.get("index", 0)),
		str(payload.get("candidate", ""))
	)

	if err != OK:
		push_warning("WebRTCLink: add_ice_candidate ha restituito " + str(err))
