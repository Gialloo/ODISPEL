class_name WebRTCLink
extends RefCounted

signal outgoing_signal(type: String, payload: Dictionary)
signal channel_opened
signal channel_closed
signal message_received(message: Dictionary)

const CHANNEL_NAME: String = "odispel-game"
const CHANNEL_ID: int = 1

# Server STUN pubblici: permettono di scoprire l'indirizzo pubblico
# e connettersi attraverso la maggior parte delle NAT domestiche.
const DEFAULT_STUN_URLS: Array = [
	"stun:stun.l.google.com:19302",
	"stun:stun1.l.google.com:19302"
]

# Heartbeat: ogni lato manda un "ping" a intervalli regolari. Se per troppo
# tempo non arriva nulla dall'altro lato, il collegamento è considerato
# caduto (il data channel da solo può impiegare molto a accorgersene).
const HEARTBEAT_INTERVAL_MSEC: int = 2000
const HEARTBEAT_TIMEOUT_MSEC: int = 8000

var peer: WebRTCPeerConnection = null
var channel: WebRTCDataChannel = null
var is_initiator: bool = false

var _remote_description_set: bool = false
var _pending_ice: Array[Dictionary] = []
var _was_open: bool = false
var _closed_emitted: bool = false
var _last_received_msec: int = 0
var _last_ping_msec: int = 0


# Costruisce la lista dei server ICE.
# STUN è sempre presente. Un TURN (relay, necessario con NAT restrittive)
# si configura con variabili d'ambiente, così le credenziali
# non finiscono nel repository:
#   ODISPEL_TURN_URL   es. turn:turn.example.com:3478
#   ODISPEL_TURN_USER
#   ODISPEL_TURN_PASS
static func build_ice_servers() -> Array:
	var servers: Array = [{"urls": DEFAULT_STUN_URLS.duplicate()}]

	var turn_url: String = OS.get_environment("ODISPEL_TURN_URL").strip_edges()

	if not turn_url.is_empty():
		servers.append({
			"urls": [turn_url],
			"username": OS.get_environment("ODISPEL_TURN_USER"),
			"credential": OS.get_environment("ODISPEL_TURN_PASS")
		})

	return servers


func setup(initiator: bool, ice_servers: Array = []) -> bool:
	is_initiator = initiator
	peer = WebRTCPeerConnection.new()

	var servers: Array = ice_servers

	if servers.is_empty():
		servers = build_ice_servers()

	var err: int = peer.initialize({"iceServers": servers})
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

	var now: int = Time.get_ticks_msec()

	if state == WebRTCDataChannel.STATE_OPEN and not _was_open:
		_was_open = true
		_last_received_msec = now
		_last_ping_msec = now
		channel_opened.emit()

	if state == WebRTCDataChannel.STATE_OPEN:
		while channel.get_available_packet_count() > 0:
			_handle_raw(channel.get_packet().get_string_from_utf8(), now)

		check_heartbeat(now)

	if state == WebRTCDataChannel.STATE_CLOSED and not _closed_emitted:
		_closed_emitted = true
		channel_closed.emit()


# True se il canale si è aperto almeno una volta.
func has_been_open() -> bool:
	return _was_open


# Elabora un pacchetto ricevuto. I "ping" servono solo a dimostrare che
# l'altro lato è vivo e non vengono passati al resto del gioco.
func _handle_raw(raw: String, now_msec: int) -> void:
	_last_received_msec = now_msec

	var parsed: Variant = JSON.parse_string(raw)

	if not parsed is Dictionary:
		push_warning("WebRTCLink: messaggio non valido scartato.")
		return

	if str(parsed.get("type", "")) == "ping":
		return

	message_received.emit(parsed)


# Manda i ping e chiude il collegamento se l'altro lato tace da troppo.
func check_heartbeat(now_msec: int) -> void:
	if not _was_open or _closed_emitted:
		return

	if now_msec - _last_received_msec >= HEARTBEAT_TIMEOUT_MSEC:
		push_warning("WebRTCLink: heartbeat scaduto, collegamento chiuso.")
		close()
		return

	if now_msec - _last_ping_msec >= HEARTBEAT_INTERVAL_MSEC:
		_last_ping_msec = now_msec
		send_message({"type": "ping"})


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
