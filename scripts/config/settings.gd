class_name Settings
extends RefCounted

# Impostazioni del giocatore (volumi, schermo intero, tutorial gia' visto).
# Stanno in un file a parte, user://settings.cfg, cosi' non toccano i progressi.

static var path: String = "user://settings.cfg"
static var music: float = 0.6        # 0..1
static var sfx: float = 0.8          # 0..1
static var muted: bool = false
static var fullscreen: bool = false
static var tutorial_done: bool = false
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
	tutorial_done = bool(cfg.get_value("game", "tutorial_done", tutorial_done))


static func ensure_loaded() -> void:
	if not _loaded:
		load_settings()


static func save() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("audio", "muted", muted)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("game", "tutorial_done", tutorial_done)
	return cfg.save(path) == OK


# Il tutorial parte da solo solo al primo combattimento in solitaria,
# e mai nei test senza schermo.
static func should_show_tutorial() -> bool:
	ensure_loaded()
	return not tutorial_done and DisplayServer.get_name() != "headless"


static func finish_tutorial() -> void:
	tutorial_done = true
	save()
