class_name BattleTheme
extends RefCounted

# Stile grafico del combattimento: telecamera di sorveglianza + HUD "arcade".
# Dominante celeste/ciano, accenti rossi aggressivi, bianco e nero.

# PALETTE A COLORI COMPLEMENTARI: ciano (tinta ~188) contro rosso-arancio (tinta ~8), opposti sul cerchio cromatico.
# Ciano = azione/amico/interfaccia, rosso-arancio = pericolo/nemico/attacco. Giallo = solo evidenza (punti focali), verde = esito positivo.
const CY: Color = Color("#7cf0ff")        # ciano principale
const CY_DIM: Color = Color("#8fd6e4")      # testi secondari: chiari, si leggono bene
const CY_DARK: Color = Color("#0f3a44")
const RD: Color = Color("#ff4630")        # rosso-arancio, complementare del ciano
const RD_DARK: Color = Color("#5a1a12")
const WH: Color = Color("#f2fdff")
const BK: Color = Color("#04080a")
const PANEL: Color = Color("#061418")
const OK: Color = Color("#6bffb0")        # esito positivo (verde)
const GOLD: Color = Color("#ffd25f")      # evidenza / rarita' alta
const POP: Color = Color("#fff36b")       # giallo dei fumetti

# Colori di gioco dei personaggi (vantaggi di colore).
const UNIT_COLORS: Dictionary = {
	"rosso": Color("#ff4d6d"),
	"verde": Color("#6bffb0"),
	"blu": Color("#5aa8ff"),
	"giallo": Color("#ffd25f"),
	"viola": Color("#b07bff"),
}

static var _mono: Font = null
static var _display: Font = null
static var _hud: Font = null


static func unit_color(color_name: String) -> Color:
	return UNIT_COLORS.get(color_name, WH)


# FONT UNICO DEL GIOCO: Libre Caslon Condensed (Google Fonts, licenza OFL, vedi assets/fonts/OFL-LibreCaslonCondensed.txt).
# Pesi: Regular / Medium / SemiBold / Bold, ciascuno anche in corsivo.
# Il Caslon condensato e' stretto e basso: i testi normali (non i titoli) si ingrandiscono un po' per restare leggibili.
const TEXT_SCALE: float = 1.12
const FONT_DIR: String = "res://assets/fonts/LibreCaslonCondensed-"
static var _cache: Dictionary = {}


static func font(weight: String = "Medium", italic: bool = false) -> Font:
	var key: String = weight + ("Italic" if italic else "")
	if key == "RegularItalic":
		key = "Italic"
	if not _cache.has(key):
		_cache[key] = load(FONT_DIR + key + ".ttf")
	return _cache[key]


# Testo normale (descrizioni, elenchi, numeri): un peso medio, leggibile anche piccolo.
static func mono() -> Font:
	if _mono == null:
		_mono = font("SemiBold")
	return _mono


# Titoli, pulsanti, danni: il grassetto.
static func display() -> Font:
	if _display == null:
		_display = font("Bold")
	return _display


# Titoli dei pannelli e numeri dell'HUD.
static func hud() -> Font:
	if _hud == null:
		_hud = font("Bold")
	return _hud


# Colpi critici e parole d'effetto: grassetto corsivo (da usare con testo MAIUSCOLO).
static func crit() -> Font:
	return font("Bold", true)


# Pensieri, sottotitoli, citazioni: corsivo.
static func quote() -> Font:
	return font("Medium", true)


static func make_label(text: String, size: int = 16, color: Color = CY, use_display: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", display() if use_display else mono())
	l.add_theme_font_size_override("font_size", int(round(float(size) * (1.0 if use_display else TEXT_SCALE))))
	l.add_theme_color_override("font_color", color)
	if not use_display:
		# ombra netta: il testo piccolo resta leggibile su qualsiasi sfondo
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		l.add_theme_constant_override("shadow_offset_x", 1)
		l.add_theme_constant_override("shadow_offset_y", 1)
	if use_display:
		# contorno nero spesso: il testo "da fumetto" si legge su qualsiasi sfondo
		l.add_theme_color_override("font_outline_color", BK)
		l.add_theme_constant_override("outline_size", maxi(4, size / 7))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func _box(bg: Color, border: Color, width: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(0)
	s.content_margin_left = 14.0
	s.content_margin_right = 14.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0
	return s


# Gli stili dei pulsanti sono uguali per tutti: si creano una volta per tipo e si condividono.
static var _button_styles: Dictionary = {}


static func _styles_for(kind: String) -> Dictionary:
	if _button_styles.has(kind):
		return _button_styles[kind]
	var normal: SlantBox
	var hover: SlantBox
	var colors: Dictionary
	match kind:
		"primary":
			normal = SlantBox.make(RD, WH, 16.0, BK, 3.0)
			hover = SlantBox.make(WH, RD, 16.0, RD, 3.0)
			colors = {"text": WH, "hover": RD}
		"ultimate":
			normal = SlantBox.make(BK, WH, 16.0, RD, 3.0)
			hover = SlantBox.make(WH, RD, 16.0, BK, 3.0)
			colors = {"text": WH, "hover": RD}
		_:
			normal = SlantBox.make(BK, CY, 14.0, CY_DARK, 2.0)
			hover = SlantBox.make(CY, BK, 14.0, CY_DIM, 2.0)
			colors = {"text": WH, "hover": BK}
	# grana leggera e lucentezza: chiare, cosi' si vedono anche sui colori scuri
	match kind:
		"primary":
			normal.hatch = Color(1, 1, 1, 0.22)
			hover.hatch = Color(0.8, 0.1, 0.2, 0.14)
		"ultimate":
			normal.hatch = Color(1, 1, 1, 0.18)
			hover.hatch = Color(0.8, 0.1, 0.2, 0.14)
		_:
			normal.hatch = Color(CY, 0.17)
			hover.hatch = Color(0, 0.1, 0.15, 0.12)
	normal.gloss = 0.13
	hover.gloss = 0.22
	var styles: Dictionary = {
		"normal": normal,
		"hover": hover,
		"disabled": SlantBox.make(Color(0.02, 0.06, 0.07), CY_DARK, 14.0, Color(0, 0, 0, 0), 2.0),
		"focus": StyleBoxEmpty.new(),
		"text": colors["text"],
		"hover_text": colors["hover"],
	}
	_button_styles[kind] = styles
	return styles


# kind: "primary" (rosso), "normal" (ciano), "ultimate" (bianco su rosso)
# I pulsanti sono parallelogrammi con ombra netta (stile Persona); sotto il mouse
# diventano pieni e si spostano un poco.
static func style_button(b: Button, kind: String = "normal", size: int = 22) -> void:
	var st: Dictionary = _styles_for(kind)
	b.add_theme_stylebox_override("normal", st["normal"])
	b.add_theme_stylebox_override("hover", st["hover"])
	b.add_theme_stylebox_override("pressed", st["hover"])
	b.add_theme_stylebox_override("disabled", st["disabled"])
	b.add_theme_stylebox_override("focus", st["focus"])
	b.add_theme_color_override("font_color", st["text"])
	b.add_theme_color_override("font_hover_color", st["hover_text"])
	b.add_theme_color_override("font_pressed_color", st["hover_text"])
	b.add_theme_color_override("font_disabled_color", Color("#6aa3af"))
	b.add_theme_color_override("font_outline_color", BK if kind != "normal" else Color(0, 0, 0, 0.9))
	b.add_theme_constant_override("outline_size", 4 if kind != "normal" else 3)
	b.add_theme_font_override("font", display())
	b.add_theme_font_size_override("font_size", TouchUi.fit(b, size))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


# Colore di una rarita' (comune, rara, epica, leggendaria).
static func rarity_color(rarity: int) -> Color:
	var colors: Array = [Color("#c9dde2"), CY, UNIT_COLORS["viola"], GOLD]
	return colors[clampi(rarity, 0, colors.size() - 1)]
