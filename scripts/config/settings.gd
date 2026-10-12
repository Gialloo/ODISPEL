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
	tutorial_done = bool(cfg.get_value("game", "tutorial_done", tutorial_done))
	gacha_guide_seen = bool(cfg.get_value("game", "gacha_guide_seen", gacha_guide_seen))
	seen_scenes = Array(cfg.get_value("game", "seen_scenes", []))


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
