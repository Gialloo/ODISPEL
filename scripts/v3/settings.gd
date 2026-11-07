class_name Settings
extends RefCounted

# Impostazioni della V3 (file proprio, user://settings.cfg): le stesse voci di accessibilita' della V2.

static var path: String = "user://settings.cfg"
static var shake: float = 1.0            # scosse della camera, 0..1
static var flash: float = 1.0            # lampi a tutto schermo, 0..1 (0 = niente luci improvvise)
static var skip_cutin: bool = false      # salta la sequenza dell'ultimate
static var cutin_once: bool = false      # la sequenza si vede solo la prima volta per personaggio, poi resta il nome (Fase 4)
static var light_fx: bool = false        # effetti ridotti (meno particelle e bagliori)
static var vibration: bool = true
static var show_fps: bool = false
static var surprise: bool = true        # prova A/B: si puo' attaccare il nemico in strada (vantaggio) e farsi sorprendere (agguato)
static var broken_cam: bool = true      # telecamera rotta quando tocca a chi ha pochi PV
static var parry_wide: bool = false     # finestra di parata ampia (accessibilita'): la guardia normale vale sempre
static var hud_ritratto: bool = true    # HUD di battaglia col ritratto 2D (remake di Persona 1, 2/11/2026); false = la ruota attorno al personaggio
static var hud_ritmo: bool = true       # barra del RITMO di squadra sopra la fila (HUD 0.61, P0-A, approvata 7/11/2026); false = come prima
static var hud_minaccia: bool = true    # prossima mossa su una lastra con icona + bersagli sui ritratti (HUD 0.61, P0-B); false = la riga di testo
static var hud_avvisi: bool = true      # avvisi in tre categorie (pericolo/tattica/ambiente), uniti e compatti col comando acceso (HUD 0.61, P0-C)
static var hud_echo: bool = true        # Echo in tre modi: consigli corti che non si ripetono e se ne vanno, avviso rosso sul pericolo (HUD 0.61, P1-A)
static var fps_cap: int = 0             # limite degli fps scelto dal giocatore (0 = predefinito: 60 sul telefono, 120 su PC)
static var text_speed: int = 0          # velocita' del testo nei dialoghi: 0 NORMALE, 1 VELOCE, 2 ISTANTANEO
static var auto_text: bool = false      # dialoghi automatici (AUTO alla Persona): la battuta va avanti da sola dopo una pausa
static var music_volume: float = 1.0    # volume della musica, 0..1 (4/11/2026: il combattimento ha il suono)
static var sfx_volume: float = 1.0      # volume degli effetti sonori, 0..1
static var cam_calm: bool = true        # regia MORBIDA in battaglia (6/11/2026, tester: «cambi di camera drastici, mal di testa»); false = DINAMICA, le inquadrature di prima
static var _loaded: bool = false

const LEVELS: Array = [1.0, 0.5, 0.0]
const FPS_CAPS: Array = [30, 60, 120, 240]
const TEXT_SPEEDS: Array = ["NORMALE", "VELOCE", "ISTANTANEO"]
const VOLUMES: Array = [1.0, 0.7, 0.4, 0.0]
const TEXT_CPS: Array = [48.0, 110.0, 0.0]   # caratteri al secondo; 0 = tutta la battuta subito


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
	cutin_once = bool(cfg.get_value("a11y", "cutin_once", cutin_once))
	light_fx = bool(cfg.get_value("video", "light_fx", light_fx))
	vibration = bool(cfg.get_value("game", "vibration", vibration))
	show_fps = bool(cfg.get_value("video", "show_fps", show_fps))
	surprise = bool(cfg.get_value("game", "surprise", surprise))
	broken_cam = bool(cfg.get_value("video", "broken_cam", broken_cam))
	fps_cap = int(cfg.get_value("video", "fps_cap", fps_cap))
	parry_wide = bool(cfg.get_value("game", "parry_wide", parry_wide))
	text_speed = clampi(int(cfg.get_value("game", "text_speed", text_speed)), 0, TEXT_SPEEDS.size() - 1)
	auto_text = bool(cfg.get_value("game", "auto_text", auto_text))
	hud_ritratto = bool(cfg.get_value("video", "hud_ritratto", hud_ritratto))
	music_volume = clampf(float(cfg.get_value("audio", "music", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx", sfx_volume)), 0.0, 1.0)
	cam_calm = bool(cfg.get_value("video", "cam_calm", cam_calm))


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("a11y", "shake", shake)
	cfg.set_value("a11y", "flash", flash)
	cfg.set_value("a11y", "skip_cutin", skip_cutin)
	cfg.set_value("a11y", "cutin_once", cutin_once)
	cfg.set_value("video", "light_fx", light_fx)
	cfg.set_value("game", "vibration", vibration)
	cfg.set_value("video", "show_fps", show_fps)
	cfg.set_value("game", "surprise", surprise)
	cfg.set_value("video", "broken_cam", broken_cam)
	cfg.set_value("video", "fps_cap", fps_cap)
	cfg.set_value("game", "parry_wide", parry_wide)
	cfg.set_value("game", "text_speed", text_speed)
	cfg.set_value("game", "auto_text", auto_text)
	cfg.set_value("video", "hud_ritratto", hud_ritratto)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "cam_calm", cam_calm)
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


static func next_volume(value: float) -> float:
	var i: int = VOLUMES.find(value)
	return float(VOLUMES[(i + 1) % VOLUMES.size()]) if i >= 0 else 1.0


static func volume_text(value: float) -> String:
	return "SPENTO" if value <= 0.01 else "%d%%" % int(round(value * 100.0))


static func fps_value() -> int:
	if FPS_CAPS.has(fps_cap):
		return fps_cap
	return 60 if OS.has_feature("mobile") else 120


static func next_fps() -> void:
	fps_cap = int(FPS_CAPS[(FPS_CAPS.find(fps_value()) + 1) % FPS_CAPS.size()])


# Limite degli fps e vsync: il vsync resta acceso finche' il limite non supera lo schermo,
# cosi' a 120/240 su un monitor veloce non si strappa l'immagine e su uno lento si va oltre i 60 se richiesto.
static func apply_fps() -> void:
	var cap: int = fps_value()
	Engine.max_fps = cap
	if DisplayServer.get_name() == "headless":
		return
	var hz: float = DisplayServer.screen_get_refresh_rate()
	var over: bool = hz > 1.0 and float(cap) > hz + 1.0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED if over else DisplayServer.VSYNC_ENABLED)


static func buzz(ms: int) -> void:
	if vibration and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)
