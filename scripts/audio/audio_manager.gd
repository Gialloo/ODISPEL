extends Node

# Autoload "Sfx": effetti sonori e musica.
#  - suoni dei pulsanti automatici (qualunque Button nato dopo)
#  - musica del menu e della battaglia, scelta in base alla schermata
#  - volumi e muto dalle impostazioni; tasto M = muto
# Si usa tramite la classe Snd.

const SFX_DIR: String = "res://assets/audio/sfx/"
const MUSIC_DIR: String = "res://assets/audio/music/"
const POOL_SIZE: int = 10
const MUSIC_FADE: float = 0.8

var current_music: String = ""

var _streams: Dictionary = {}
var _loops: Dictionary = {}
var _pool: Array = []
var _next: int = 0
var _music_players: Array = []
var _music_index: int = 0
var _duck_db: float = 0.0
var _last_scene: Node = null
var _hover_gate: float = 0.0


func _ready() -> void:
	Settings.ensure_loaded()
	_make_bus("Music")
	_make_bus("SFX")
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.bus = "Music"
		m.volume_db = -80.0
		add_child(m)
		_music_players.append(m)
	apply_settings()
	get_tree().node_added.connect(_on_node_added)
	_preload_in_background()


# Musica ed effetti si leggono su un altro thread: al primo suono non c'e' nessuna attesa.
func _preload_in_background() -> void:
	var paths: Array = [MUSIC_DIR + "menu.wav", MUSIC_DIR + "battle.wav", MUSIC_DIR + "battle_hard.wav"]
	for file in ResourceLoader.list_directory(SFX_DIR):
		if str(file).ends_with(".wav"):
			paths.append(SFX_DIR + str(file))
	Warmup.audio(paths)


func _make_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var idx: int = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func apply_settings() -> void:
	Settings.ensure_loaded()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(Settings.music, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(Settings.sfx, 0.0001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), Settings.muted)
	Settings.apply_video()
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if Settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


# ---------- Effetti ----------

func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		_streams[path] = load(path) if ResourceLoader.exists(path) else null
	return _streams[path]


func play(sound: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _stream(SFX_DIR + sound + ".wav")
	if stream == null or _pool.is_empty():
		return
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var b: BaseButton = node
		b.pressed.connect(_on_button_pressed.bind(b))
		b.mouse_entered.connect(_on_button_hover.bind(b))
		ButtonFx.hook(b)
		b.gui_input.connect(_on_button_input.bind(b))


func _on_button_pressed(b: BaseButton) -> void:
	if not b.disabled:
		var snd: String = ButtonFx.sound_for(b)
		play(snd, randf_range(0.97, 1.04) if snd == "click" else 1.0)


# Premere un pulsante spento: suono d'errore e una piccola scossa, cosi' si capisce che non si puo'.
func _on_button_input(event: InputEvent, b: BaseButton) -> void:
	if not b.disabled or not (event is InputEventMouseButton or event is InputEventScreenTouch):
		return
	if event is InputEventMouseButton and not (event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if event is InputEventScreenTouch and not event.pressed:
		return
	play("error", 1.0, -8.0)
	ButtonFx.shake(b)


func _on_button_hover(b: BaseButton) -> void:
	# un solo "tic" ogni tanto: passando sopra a tanti pulsanti non deve mitragliare
	var now: float = Time.get_ticks_msec() / 1000.0
	if b.disabled or now < _hover_gate:
		return
	_hover_gate = now + 0.06
	play("hover")


# ---------- Musica ----------

# Che brano suona in questa schermata: in battaglia quello teso per Ciclo Infinito, Sfida del giorno e ultimi bersagli.
func _track_for(scene: Node) -> String:
	if not str(scene.scene_file_path).contains("battle_screen"):
		return "menu"
	var hard: bool = MissionConfig.endless_floor > 0 or MissionConfig.daily_mod != "" or ["orologio", "specchio"].has(MissionConfig.boss_id)
	return "battle_hard" if hard else "battle"

func play_music(track: String) -> void:
	if track == current_music:
		return
	current_music = track
	_duck_db = 0.0
	var stream: AudioStream = _stream(MUSIC_DIR + track + ".wav")
	var old: AudioStreamPlayer = _music_players[_music_index]
	_music_index = 1 - _music_index
	var fresh: AudioStreamPlayer = _music_players[_music_index]
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	if old.playing:
		tw.tween_property(old, "volume_db", -60.0, MUSIC_FADE)
		tw.chain().tween_callback(old.stop)
	if stream == null:
		return
	fresh.stream = _looped(track, stream)
	fresh.volume_db = -60.0
	fresh.play()
	tw.tween_property(fresh, "volume_db", _duck_db, MUSIC_FADE)


# Versione "a ciclo" di un brano: si crea una volta e si riusa a ogni cambio di schermata.
func _looped(track: String, stream: AudioStream) -> AudioStream:
	if _loops.has(track):
		return _loops[track]
	var looped: AudioStream = stream.duplicate()
	if looped is AudioStreamWAV:
		var wav: AudioStreamWAV = looped
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() / 2        # 16 bit mono
	_loops[track] = looped
	return looped


func duck(db: float) -> void:
	_duck_db = db
	var p: AudioStreamPlayer = _music_players[_music_index]
	create_tween().tween_property(p, "volume_db", db, 0.5)


func _process(_delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene == _last_scene:
		return
	_last_scene = scene
	if scene != null:
		play_music(_track_for(scene))


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		Settings.muted = not Settings.muted
		Settings.save()
		apply_settings()
		Notify.toast("AUDIO DISATTIVATO" if Settings.muted else "AUDIO ATTIVO")
