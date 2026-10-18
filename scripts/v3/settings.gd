class_name Settings
extends RefCounted

# Impostazioni della V3 (file proprio, user://settings.cfg): le stesse voci di accessibilita' della V2.

static var path: String = "user://settings.cfg"
static var shake: float = 1.0            # scosse della camera, 0..1
static var flash: float = 1.0            # lampi a tutto schermo, 0..1 (0 = niente luci improvvise)
static var skip_cutin: bool = false      # salta la sequenza dell'ultimate
static var light_fx: bool = false        # effetti ridotti (meno particelle e bagliori)
static var vibration: bool = true
static var show_fps: bool = false
static var _loaded: bool = false

const LEVELS: Array = [1.0, 0.5, 0.0]


static func ensure_loaded() -> void:
	if not _loaded:
		load_settings()


static func load_settings() -> void:
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	shake = clampf(float(cfg.get_value("a11y", "shake", shake)), 0.0, 1.0)
	flash = clampf(float(cfg.get_value("a11y", "flash", flash)), 0.0, 1.0)
	skip_cutin = bool(cfg.get_value("a11y", "skip_cutin", skip_cutin))
	light_fx = bool(cfg.get_value("video", "light_fx", light_fx))
	vibration = bool(cfg.get_value("game", "vibration", vibration))
	show_fps = bool(cfg.get_value("video", "show_fps", show_fps))


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("a11y", "shake", shake)
	cfg.set_value("a11y", "flash", flash)
	cfg.set_value("a11y", "skip_cutin", skip_cutin)
	cfg.set_value("video", "light_fx", light_fx)
	cfg.set_value("game", "vibration", vibration)
	cfg.set_value("video", "show_fps", show_fps)
	cfg.save(path)


static func next_level(value: float) -> float:
	var i: int = LEVELS.find(value)
	return float(LEVELS[(i + 1) % LEVELS.size()]) if i >= 0 else 1.0


static func level_text(value: float) -> String:
	if value >= 0.99:
		return "PIENE"
	if value <= 0.01:
		return "SPENTE"
	return "RIDOTTE"


static func buzz(ms: int) -> void:
	if vibration and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)
