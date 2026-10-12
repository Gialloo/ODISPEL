class_name BattleTheme
extends RefCounted

# Stile grafico del combattimento: telecamera di sorveglianza + HUD "arcade".
# Dominante celeste/ciano, accenti rossi aggressivi, bianco e nero.

const CY: Color = Color("#7cf0ff")        # ciano principale
const CY_DIM: Color = Color("#2a8a9a")
const CY_DARK: Color = Color("#0f3a44")
const RD: Color = Color("#ff2d55")        # rosso aggressivo
const RD_DARK: Color = Color("#5a1022")
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


static func unit_color(color_name: String) -> Color:
	return UNIT_COLORS.get(color_name, WH)


# Font a spaziatura fissa (testi tecnici, numeri).
static func mono() -> Font:
	if _mono == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Consolas", "Courier New", "DejaVu Sans Mono", "monospace"])
		f.font_weight = 700
		_mono = f
	return _mono


# Font "da insegna": pesante e inclinato (titoli, danni, pulsanti).
static func display() -> Font:
	if _display == null:
		var base := SystemFont.new()
		base.font_names = PackedStringArray(["Impact", "Arial Black", "DejaVu Sans Bold", "sans-serif"])
		base.font_weight = 900
		var fv := FontVariation.new()
		fv.base_font = base
		fv.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-0.22, 1.0), Vector2.ZERO)
		_display = fv
	return _display


static func make_label(text: String, size: int = 16, color: Color = CY, use_display: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", display() if use_display else mono())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
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
			colors = {"text": CY, "hover": BK}
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
	b.add_theme_color_override("font_disabled_color", CY_DARK)
	b.add_theme_color_override("font_outline_color", BK if kind != "normal" else Color(0, 0, 0, 0))
	b.add_theme_constant_override("outline_size", 0 if kind == "normal" else 4)
	b.add_theme_font_override("font", display())
	b.add_theme_font_size_override("font_size", size)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
