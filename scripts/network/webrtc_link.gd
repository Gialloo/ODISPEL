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
	"stun:stun1.l.google.com:19302",
	"stun:stun.cloudflare.com:3478",
	"stun:stun.relay.metered.ca:80"
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
var _invalid_count: int = 0

# Dopo questi avvisi i messaggi non validi si scartano in silenzio,
# così un peer ostile non riempie il log.
const MAX_INVALID_WARNINGS: int = 3
# Difese contro un peer che inonda il canale: pacchetti troppo grandi si scartano, troppi messaggi al secondo
# si scartano e, se l'eccesso continua, il collegamento si chiude. I valori normali sono molto sotto (qualche messaggio al secondo).
const MAX_PACKET_BYTES: int = 262144
const MAX_MESSAGES_PER_SEC: int = 120
const FLOOD_CLOSE_SECONDS: int = 5


# File con le credenziali del server di inoltro (TURN). Non e' nel repository (vedi .gitignore): si crea in
# config/turn.cfg partendo da config/turn.cfg.example e viene incluso nell'esportazione.
const TURN_CONFIG_PATH: String = "res://config/turn.cfg"


# Impostazioni TURN: prima le variabili d'ambiente, poi il file. {urls: Array, user, pass}; urls vuoto = niente TURN.
#   ODISPEL_TURN_URL   uno o piu' indirizzi separati da virgola, es. turn:turn.example.com:80,turns:turn.example.com:443?transport=tcp
#   ODISPEL_TURN_USER, ODISPEL_TURN_PASS
static func turn_settings(config_path: String = TURN_CONFIG_PATH) -> Dictionary:
	var url: String = OS.get_environment("ODISPEL_TURN_URL").strip_edges()
	var user: String = OS.get_environment("ODISPEL_TURN_USER")
	var pass_word: String = OS.get_environment("ODISPEL_TURN_PASS")
	if url.is_empty():
		var cfg := ConfigFile.new()
		if cfg.load(config_path) == OK:
			url = str(cfg.get_value("turn", "url", "")).strip_edges()
			user = str(cfg.get_value("turn", "user", ""))
			pass_word = str(cfg.get_value("turn", "pass", ""))
	var urls: Array = []
	for part in url.split(","):
		var clean: String = part.strip_edges()
		if clean.begins_with("turn:") or clean.begins_with("turns:"):
			urls.append(clean)
	return {"urls": urls, "user": user, "pass": pass_word}


# Costruisce la lista dei server ICE. STUN e' sempre presente; il TURN (inoltro del traffico, necessario con i dati
# mobili e le reti piu' restrittive) si aggiunge se configurato.
static func build_ice_servers(config_path: String = TURN_CONFIG_PATH) -> Array:
	var servers: Array = [{"urls": DEFAULT_STUN_URLS.duplicate()}]
	var turn: Dictionary = turn_settings(config_path)
	if not (turn["urls"] as Array).is_empty():
		servers.append({
			"urls": turn["urls"],
			"username": turn["user"],
			"credential": turn["pass"],
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
			var packet: PackedByteArray = channel.get_packet()
			if not _accept_packet(packet.size(), now):
				continue
			_handle_raw(unpack_text(packet), now)

		check_heartbeat(now)

	if state == WebRTCDataChannel.STATE_CLOSED and not _closed_emitted:
		_closed_emitted = true
		channel_closed.emit()


# Come JSON.parse_string, ma un testo non valido non scrive errori nel log:
# restituisce semplicemente null.
static func parse_json(raw: String) -> Variant:
	var json := JSON.new()

	if json.parse(raw) != OK:
		return null

	return json.data


# True se il canale si è aperto almeno una volta.
func has_been_open() -> bool:
	return _was_open


var _rate_window_start: int = 0
var _rate_count: int = 0
var _flood_seconds: int = 0


# False se il pacchetto va scartato (troppo grande o troppi messaggi al secondo).
func _accept_packet(size: int, now_msec: int) -> bool:
	if now_msec - _rate_window_start >= 1000:
		if _rate_count > MAX_MESSAGES_PER_SEC:
			_flood_seconds += 1
		else:
			_flood_seconds = 0
		_rate_window_start = now_msec
		_rate_count = 0
		if _flood_seconds >= FLOOD_CLOSE_SECONDS:
			push_warning("WebRTCLink: troppi messaggi, collegamento chiuso.")
			close()
			return false
	_rate_count += 1
	if size > MAX_PACKET_BYTES:
		_invalid_count += 1
		return false
	return _rate_count <= MAX_MESSAGES_PER_SEC


# Elabora un pacchetto ricevuto. I "ping" servono solo a dimostrare che
# l'altro lato è vivo e non vengono passati al resto del gioco.
func _handle_raw(raw: String, now_msec: int) -> void:
	_last_received_msec = now_msec

	var parsed: Variant = parse_json(raw)

	if not parsed is Dictionary:
		_invalid_count += 1

		if _invalid_count <= MAX_INVALID_WARNINGS:
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
	return channel.put_packet(pack_text(text)) == OK


# Compressione dei messaggi grossi (le fotografie della battaglia): meno dati su rete e sul TURN.
# Pacchetto compresso = byte 1 + dimensione originale (4 byte) + dati; un pacchetto normale e' JSON e inizia con "{".
const COMPRESS_MIN_BYTES: int = 600
const MAX_UNPACKED_BYTES: int = 1048576
const PACK_MARK: int = 1


static func pack_text(text: String) -> PackedByteArray:
	var raw: PackedByteArray = text.to_utf8_buffer()
	if raw.size() < COMPRESS_MIN_BYTES:
		return raw
	var packed: PackedByteArray = raw.compress(FileAccess.COMPRESSION_DEFLATE)
	if packed.size() + 5 >= raw.size():
		return raw
	var out := PackedByteArray([PACK_MARK])
	out.resize(5)
	out.encode_u32(1, raw.size())
	out.append_array(packed)
	return out


# Testo di un pacchetto ricevuto; stringa vuota se e' compresso male o dichiara una dimensione eccessiva.
static func unpack_text(packet: PackedByteArray) -> String:
	if packet.size() == 0 or packet[0] != PACK_MARK:
		return packet.get_string_from_utf8()
	if packet.size() < 6:
		return ""
	var original: int = int(packet.decode_u32(1))
	if original <= 0 or original > MAX_UNPACKED_BYTES:
		return ""
	var raw: PackedByteArray = packet.slice(5).decompress(original, FileAccess.COMPRESSION_DEFLATE)
	if raw.size() != original:
		return ""
	return raw.get_string_from_utf8()


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
