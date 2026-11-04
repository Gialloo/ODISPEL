class_name Sfx
extends Node

# IL SUONO DEL COMBATTIMENTO (4/11/2026, idea 1 approvata dall'autore: «oggi il combattimento è muto»).
# Effetti e musica sono generati da tools/gen_suoni.py (nostri, CC0): si ritoccano li' e si rigenerano.
# Tutto passa da qui con funzioni statiche (come Settings e Breadcrumb): il nodo si crea da solo la prima volta,
# resta vivo tra le schermate e non serve un autoload (i test con -s non lo caricherebbero).
#
# MUSICA A STRATI: quattro strati lunghi uguale suonano sempre insieme e a tempo; il COMBO ne alza il volume.
#   base (tappeto e basso) sempre · ritmo piano, pieno da 2 COMBO · arpeggio da 3 · melodia da 5 e col BREAK.
#   Quando il nemico agisce il COMBO torna a zero ma la musica scende piano (non si spegne di colpo a ogni turno).

const DIR: String = "res://assets/audio/"
const STEMS: Array = ["base", "ritmo", "arpeggio", "melodia"]
const POOL: int = 12
# parola a fumetto (Onomato) -> effetto: cosi' ogni colpo che si vede si sente, senza toccare ogni punto del combattimento
const WORDS: Dictionary = {
	"TAP": "colpo", "ZAP": "colpo_forte", "BAM": "critico", "CLANG": "scudo", "THUD": "ferita",
	"PLING": "cura", "SWISH": "schivata", "KRAK": "break",
}
# volume di partenza di ogni effetto (dB): i colpi frequenti piu' bassi, i momenti grossi pieni
const GAIN: Dictionary = {
	"colpo": -4.0, "colpo_forte": -3.0, "critico": -1.0, "scudo": -4.0, "ferita": -3.0, "cura": -4.0,
	"schivata": -5.0, "break": 0.0, "camera": -9.0, "combo": -6.0, "ko": -3.0, "colpo_finale": 0.0,
	"cutin": -3.0, "turno": -8.0, "ui_sposta": -12.0, "ui_ok": -8.0, "ui_indietro": -8.0,
	"vittoria": -2.0, "sconfitta": -3.0,
}
const QUIET_DB: float = -60.0

static var _me: Sfx = null

var _players: Array = []
var _next: int = 0
var _cache: Dictionary = {}
var _last: Dictionary = {}          # effetto -> ms dell'ultima volta (due colpi uguali nello stesso istante = uno)
var _music: AudioStreamPlayer = null
var _sync: AudioStreamSynchronized = null
var _track: String = ""
var _level: int = 0
var _hold_until: int = 0            # ms: dopo un BREAK la musica resta al massimo per un po'
var _vol: Array = [1.0, 0.0, 0.0, 0.0]     # volume attuale di ogni strato (0..1), insegue _want
var _want: Array = [1.0, 0.0, 0.0, 0.0]
var _duck: float = 1.0              # la musica si abbassa sotto il cut-in e il colpo finale
var _duck_until: int = 0
var _fade_out: float = -1.0         # >= 0: secondi che mancano al silenzio (la musica sta sfumando)
var _fade_len: float = 1.0


# ---------------------------------------------------------------- funzioni da chiamare
static func play(sfx_name: String, delay: float = 0.0, pitch: float = 1.0, db: float = 0.0) -> void:
	var s: Sfx = _inst()
	if s != null:
		s._play(sfx_name, delay, pitch, db)


# la parola a fumetto che compare sul colpo decide il suono (TAP, ZAP, BAM, CLANG, ...)
static func word(w: String, big: bool = false) -> void:
	if WORDS.has(w):
		play(str(WORDS[w]), 0.0, randf_range(0.95, 1.05), 1.5 if big else 0.0)


# +1 COMBO: blip che sale di tono e musica che cresce
static func combo(n: int) -> void:
	var s: Sfx = _inst()
	if s == null:
		return
	if n >= 2:
		s._play("combo", 0.0, minf(1.0 + 0.06 * float(n - 2), 1.6), 0.0)
	s._set_level(0 if n < 2 else (1 if n == 2 else (2 if n < 5 else 3)))


# BREAK: tutta la musica per qualche secondo, anche se poi il COMBO si azzera
static func surge(sec: float = 6.0) -> void:
	var s: Sfx = _inst()
	if s == null:
		return
	s._hold_until = Time.get_ticks_msec() + int(sec * 1000.0)
	s._set_level(3)


static func duck(sec: float) -> void:
	var s: Sfx = _inst()
	if s != null:
		s._duck_until = Time.get_ticks_msec() + int(sec * 1000.0)


static func music_start(track: String) -> void:
	var s: Sfx = _inst()
	if s != null:
		s._start_music(track)


static func music_stop(fade: float = 0.5) -> void:
	if _me != null and is_instance_valid(_me):
		_me._fade_len = maxf(0.01, fade)
		_me._fade_out = _me._fade_len


# ---------------------------------------------------------------- dentro
static func _inst() -> Sfx:
	if _me != null and is_instance_valid(_me):
		return _me
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	_me = Sfx.new()
	_me.name = "Sfx"
	_me.process_mode = Node.PROCESS_MODE_ALWAYS       # suona anche a gioco in pausa (menu, cut-in)
	tree.root.add_child.call_deferred(_me)           # durante il _ready di una schermata la radice e' occupata
	return _me


func _init() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	# limitatore sull'uscita: BREAK + colpo finale + musica piena insieme non devono gracchiare (costa pochissimo)
	var has_lim: bool = false
	for i in AudioServer.get_bus_effect_count(0):
		if AudioServer.get_bus_effect(0, i) is AudioEffectHardLimiter:
			has_lim = true
	if not has_lim:
		var lim := AudioEffectHardLimiter.new()
		lim.ceiling_db = -0.5
		AudioServer.add_bus_effect(0, lim)


func _stream(sfx_name: String) -> AudioStream:
	if _cache.has(sfx_name):
		return _cache[sfx_name]
	var path: String = DIR + sfx_name + ".ogg"
	var st: AudioStream = load(path) as AudioStream if ResourceLoader.exists(path) else null
	_cache[sfx_name] = st
	return st


func _play(sfx_name: String, delay: float, pitch: float, db: float) -> void:
	Settings.ensure_loaded()
	if Settings.sfx_volume <= 0.01:
		return
	if not is_inside_tree():
		await ready
	if delay > 0.01:
		await get_tree().create_timer(delay, true, false, true).timeout
	if not is_inside_tree():
		return
	var now: int = Time.get_ticks_msec()
	if now - int(_last.get(sfx_name, -1000)) < 40:
		return
	_last[sfx_name] = now
	var st: AudioStream = _stream(sfx_name)
	if st == null:
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = st
	p.pitch_scale = pitch
	p.volume_db = float(GAIN.get(sfx_name, -4.0)) + db + linear_to_db(Settings.sfx_volume)
	p.play()


func _start_music(track: String) -> void:
	if not is_inside_tree():
		await ready
	_fade_out = -1.0
	_level = 0
	_hold_until = 0
	_want = [1.0, 0.35, 0.0, 0.0]
	_vol = _want.duplicate()
	if _track == track and _music.playing:
		return
	_track = track
	_sync = AudioStreamSynchronized.new()
	_sync.stream_count = STEMS.size()
	for i in STEMS.size():
		var st: AudioStream = _stream("musica/%s_%s" % [track, STEMS[i]])
		if st == null:
			_music.stop()
			_track = ""
			return
		if "loop" in st:
			st.set("loop", true)
		_sync.set_sync_stream(i, st)
		_sync.set_sync_stream_volume(i, linear_to_db(maxf(float(_vol[i]), 0.001)))
	_music.stream = _sync
	_music.volume_db = linear_to_db(maxf(Settings.music_volume, 0.001)) - 4.0
	_music.play()


func _set_level(lv: int) -> void:
	if Time.get_ticks_msec() < _hold_until:
		lv = 3
	_level = lv
	_want = [1.0, 1.0 if lv >= 1 else 0.35, 1.0 if lv >= 2 else 0.0, 1.0 if lv >= 3 else 0.0]


func _process(delta: float) -> void:
	if _sync == null or not _music.playing:
		return
	var now: int = Time.get_ticks_msec()
	if _hold_until > 0 and now >= _hold_until:
		_hold_until = 0
		_set_level(mini(_level, 2))
	for i in STEMS.size():
		var w: float = float(_want[i])
		var v: float = float(_vol[i])
		# sale svelto (si sente subito che il COMBO conta), scende piano
		v = move_toward(v, w, delta * (2.5 if w > v else 0.6))
		_vol[i] = v
		_sync.set_sync_stream_volume(i, QUIET_DB if v < 0.002 else linear_to_db(v))
	_duck = move_toward(_duck, 0.35 if now < _duck_until else 1.0, delta * 3.0)
	var master: float = Settings.music_volume * _duck
	if _fade_out >= 0.0:
		_fade_out = maxf(0.0, _fade_out - delta)
		master *= _fade_out / _fade_len
		if _fade_out <= 0.0:
			_music.stop()
			_track = ""
			_fade_out = -1.0
			return
	_music.volume_db = QUIET_DB if master < 0.002 else linear_to_db(master) - 4.0
