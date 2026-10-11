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


# kind: "primary" (rosso), "normal" (ciano), "ultimate" (bianco su rosso)
static func style_button(b: Button, kind: String = "normal", size: int = 22) -> void:
	var normal: StyleBoxFlat
	var hover: StyleBoxFlat
	var text_color: Color
	var hover_text: Color
	match kind:
		"primary":
			normal = _box(RD, WH, 2)
			hover = _box(WH, RD, 2)
			text_color = WH
			hover_text = RD
		"ultimate":
			normal = _box(BK, WH, 3)
			hover = _box(WH, RD, 3)
			text_color = WH
			hover_text = RD
		_:
			normal = _box(BK, CY, 2)
			hover = _box(CY, CY, 2)
			text_color = CY
			hover_text = BK
	var disabled: StyleBoxFlat = _box(Color(0.02, 0.06, 0.07), CY_DARK, 2)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", text_color)
	b.add_theme_color_override("font_hover_color", hover_text)
	b.add_theme_color_override("font_pressed_color", hover_text)
	b.add_theme_color_override("font_disabled_color", CY_DARK)
	b.add_theme_font_override("font", display())
	b.add_theme_font_size_override("font_size", size)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
