class_name Settings
extends RefCounted

# Impostazioni del giocatore (volumi, schermo intero, tutorial gia' visto).
# Stanno in un file a parte, user://settings.cfg, cosi' non toccano i progressi.

static var path: String = "user://settings.cfg"
static var music: float = 0.6        # 0..1
static var sfx: float = 0.8          # 0..1
static var muted: bool = false
static var fullscreen: bool = false
static var fps_limit: int = 60         # 0 = senza limite (60 di base: meno CPU/GPU e batteria; si puo' alzare nelle impostazioni)
static var vsync: bool = true
static var light_fx: bool = OS.has_feature("mobile")   # effetti ridotti: niente velo telecamera ne' pulviscolo (telefoni e PC lenti)
const FPS_CHOICES: Array = [60, 90, 120, 144, 240, 0]
static var fast_battle: bool = false     # animazioni di battaglia piu' veloci
static var turbo_battle: bool = false    # velocita' massima (con fast_battle: 0 normale, 1 veloce, 2 turbo)
static var shake: float = 1.0            # intensita' delle scosse della camera, 0..1
static var flash: float = 1.0            # intensita' dei lampi a tutto schermo, 0..1 (0 = niente luci improvvise)
static var skip_cutin: bool = false      # salta la sequenza dell'ultimate
static var skip_story: bool = false      # salta da sola le scene di storia
static var show_fps: bool = false        # contatore dei fotogrammi in un angolo
static var vibration: bool = true       # vibrazione del telefono nei momenti forti
static var banter: bool = true          # battute dei personaggi in battaglia
static var tutorial_done: bool = false
static var gacha_guide_seen: bool = false
static var seen_scenes: Array = []      # scene di storia gia' viste
static var _loaded: bool = false


static func load_settings() -> void:
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	music = clampf(float(cfg.get_value("audio", "music", music)), 0.0, 1.0)
	sfx = clampf(float(cfg.get_value("audio", "sfx", sfx)), 0.0, 1.0)
	muted = bool(cfg.get_value("audio", "muted", muted))
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))
	fps_limit = int(cfg.get_value("video", "fps_limit", fps_limit))
	if not FPS_CHOICES.has(fps_limit):
		fps_limit = 60
	vsync = bool(cfg.get_value("video", "vsync", vsync))
	light_fx = bool(cfg.get_value("video", "light_fx", light_fx))
	banter = bool(cfg.get_value("game", "banter", banter))
	vibration = bool(cfg.get_value("game", "vibration", vibration))
	fast_battle = bool(cfg.get_value("game", "fast_battle", fast_battle))
	turbo_battle = bool(cfg.get_value("game", "turbo_battle", turbo_battle)) and fast_battle
	shake = clampf(float(cfg.get_value("game", "shake", shake)), 0.0, 1.0)
	flash = clampf(float(cfg.get_value("game", "flash", flash)), 0.0, 1.0)
	skip_cutin = bool(cfg.get_value("game", "skip_cutin", skip_cutin))
	skip_story = bool(cfg.get_value("game", "skip_story", skip_story))
	show_fps = bool(cfg.get_value("video", "show_fps", show_fps))
	tutorial_done = bool(cfg.get_value("game", "tutorial_done", tutorial_done))
	gacha_guide_seen = bool(cfg.get_value("game", "gacha_guide_seen", gacha_guide_seen))
	seen_scenes = Array(cfg.get_value("game", "seen_scenes", []))


# Limite di fotogrammi e V-Sync. Con il V-Sync attivo il gioco segue il monitor (60, 144...) senza strappi.
static func apply_video() -> void:
	Engine.max_fps = fps_limit
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)


static func next_fps_limit() -> int:
	var i: int = FPS_CHOICES.find(fps_limit)
	return int(FPS_CHOICES[(i + 1) % FPS_CHOICES.size()])


static func fps_text() -> String:
	return "FPS MASSIMI: %s" % ("SENZA LIMITE" if fps_limit == 0 else str(fps_limit))


static func ensure_loaded() -> void:
	if not _loaded:
		load_settings()


static func save() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("audio", "muted", muted)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "fps_limit", fps_limit)
	cfg.set_value("video", "vsync", vsync)
	cfg.set_value("video", "light_fx", light_fx)
	cfg.set_value("game", "banter", banter)
	cfg.set_value("game", "vibration", vibration)
	cfg.set_value("game", "fast_battle", fast_battle)
	cfg.set_value("game", "turbo_battle", turbo_battle)
	cfg.set_value("game", "shake", shake)
	cfg.set_value("game", "flash", flash)
	cfg.set_value("game", "skip_cutin", skip_cutin)
	cfg.set_value("game", "skip_story", skip_story)
	cfg.set_value("video", "show_fps", show_fps)
	cfg.set_value("game", "tutorial_done", tutorial_done)
	cfg.set_value("game", "gacha_guide_seen", gacha_guide_seen)
	cfg.set_value("game", "seen_scenes", seen_scenes)
	return cfg.save(path) == OK


# Il tutorial parte da solo solo al primo combattimento in solitaria,
# e mai nei test senza schermo.
static func should_show_tutorial() -> bool:
	ensure_loaded()
	return not tutorial_done and DisplayServer.get_name() != "headless"


static func finish_tutorial() -> void:
	tutorial_done = true
	save()


static func mark_scene_seen(id: String) -> void:
	ensure_loaded()
	if not seen_scenes.has(id):
		seen_scenes.append(id)
		save()


# La guida al reclutamento si apre da sola la prima volta che si entra nella pagina.
static func should_show_gacha_guide() -> bool:
	ensure_loaded()
	return not gacha_guide_seen and DisplayServer.get_name() != "headless"


static func finish_gacha_guide() -> void:
	gacha_guide_seen = true
	save()


# Vibrazione breve (solo telefono, e solo se non e' spenta nelle impostazioni).
static func buzz(ms: int) -> void:
	if vibration and TouchUi.active():
		Input.vibrate_handheld(ms)


# Pausa tra un evento e l'altro in battaglia.
static func event_delay() -> float:
	if fast_battle and turbo_battle:
		return 0.10
	return 0.22 if fast_battle else 0.42


# Velocita' della battaglia a tre livelli: normale -> veloce -> turbo -> normale.
static func speed_level() -> int:
	return 0 if not fast_battle else (2 if turbo_battle else 1)


static func next_speed() -> void:
	var lv: int = (speed_level() + 1) % 3
	fast_battle = lv >= 1
	turbo_battle = lv == 2


static func speed_text() -> String:
	return ["NORMALE", "VELOCE", "TURBO"][speed_level()]


# Qualita' grafica in un colpo solo: BASSA (effetti ridotti, 60 fps), MEDIA, ALTA (effetti pieni, 120 fps).
static func quality_name() -> String:
	if light_fx:
		return "BASSA"
	return "ALTA" if fps_limit == 0 or fps_limit >= 90 else "MEDIA"


static func next_quality() -> void:
	match quality_name():
		"BASSA":
			light_fx = false
			fps_limit = 60
		"MEDIA":
			light_fx = false
			fps_limit = 120
		_:
			light_fx = true
			fps_limit = 60


# 0, 0.5 o 1 in "0 / 50 / 100%": per le intensita' (scosse, lampi).
static func next_level(value: float) -> float:
	return 0.0 if value > 0.75 else (1.0 if value < 0.25 else 0.5)


static func level_text(value: float) -> String:
	return "NIENTE" if value < 0.25 else ("RIDOTTE" if value < 0.75 else "PIENE")
