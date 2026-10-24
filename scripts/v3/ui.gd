class_name Ui
extends RefCounted

# Stile dell'interfaccia 2D della V3: pop, contorni netti, ombre piene (come la mappa V2), testo grande per il telefono.

const INK: Color = Color("#120a1c")
const CREAM: Color = Color("#fff4dc")
const PINK: Color = Color("#ff3d8b")
const YELLOW: Color = Color("#ffd23f")
const CYAN: Color = Color("#3fe0ff")
const VIOLET: Color = Color("#8e3df0")

const BATTLE_COLORS: Dictionary = {
	"rosso": Color("#ff4b4b"),
	"verde": Color("#46e07a"),
	"blu": Color("#3f9dff"),
	"giallo": Color("#ffd23f"),
	"viola": Color("#b45cff"),
}

static var _fonts: Dictionary = {}


static func _font(file: String) -> Font:
	if not _fonts.has(file):
		var f: Variant = load("res://assets/fonts/" + file)
		_fonts[file] = f if f is Font else ThemeDB.fallback_font
	return _fonts[file]


static func display() -> Font:
	return _font("ArchivoBlack-Regular.ttf")


static func body() -> Font:
	return _font("Roboto-Bold.ttf")


# Tipografia scelta dall'autore (13/10): Merriweather per dialoghi e descrizioni, Libre Caslon per il titolo e i nomi
static func story() -> Font:
	return _font("Merriweather-Bold.ttf")


static func names() -> Font:
	return _font("LibreCaslonText-Bold.ttf")


static func is_touch() -> bool:
	return TouchUi.active()


static func label(text: String, size: int, col: Color = CREAM, font: Font = null, outline: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font != null else body())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", INK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func box(bg: Color, border: Color = INK, bw: int = 4, radius: int = 6, shadow: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(INK.r, INK.g, INK.b, 0.9)
	s.shadow_size = 0
	s.shadow_offset = Vector2(shadow, shadow)
	if shadow > 0:
		s.shadow_size = 1
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


# Lastra storta alla Persona 5: fondo pieno, bordo spesso del colore a sinistra e sotto, ombra nera sfalsata. Per le scritte
# che devono leggersi su qualsiasi sfondo (minaccia del nemico, avvisi, ordine dei turni, indicazioni in esplorazione).
static func plate(bg: Color, edge: Color, skew: float = -0.18, edge_w: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.border_width_left = edge_w
	s.border_width_bottom = maxi(2, edge_w - 3)
	s.skew = Vector2(skew, 0.0)
	s.shadow_color = Color(INK.r, INK.g, INK.b, 0.85)
	s.shadow_size = 1
	s.shadow_offset = Vector2(5, 5)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 3
	s.content_margin_bottom = 5
	return s


# Scritta su lastra (vedi plate): la lastra si stringe attorno al testo
static func plate_label(text: String, size: int, col: Color, bg: Color, edge: Color, font: Font = null) -> Label:
	var l := label(text, size, col, font if font != null else display(), 0)
	l.add_theme_stylebox_override("normal", plate(bg, edge))
	return l


static func button(text: String, bg: Color = YELLOW, size: int = 26, min_w: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", display())
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_disabled_color", Color(CREAM.r, CREAM.g, CREAM.b, 0.85))   # leggibile anche spento
	b.add_theme_stylebox_override("normal", box(bg))
	b.add_theme_stylebox_override("hover", box(bg.lightened(0.15)))
	b.add_theme_stylebox_override("pressed", box(bg.darkened(0.12), INK, 4, 6, 2))
	b.add_theme_stylebox_override("disabled", box(bg.darkened(0.62), INK, 4, 6, 3))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.custom_minimum_size = Vector2(min_w, 64.0 if is_touch() else 52.0)
	return b


# Ancore e margini in un colpo solo. Con le proprieta' anchor_* Godot ricalcola i margini per tenere il rettangolo:
# qui si fissano prima le ancore (senza toccare i margini) e poi TUTTI e quattro i margini.
static func place(c: Control, al: float, at: float, ar: float, ab: float, ol: float = 0.0, ot: float = 0.0, orr: float = 0.0, ob: float = 0.0) -> void:
	# prima destra e basso (Godot non lascia la sinistra oltre la destra), poi sinistra e alto
	c.set_anchor(SIDE_RIGHT, ar, true, false)
	c.set_anchor(SIDE_BOTTOM, ab, true, false)
	c.set_anchor(SIDE_LEFT, al, true, false)
	c.set_anchor(SIDE_TOP, at, true, false)
	c.offset_left = ol
	c.offset_top = ot
	c.offset_right = orr
	c.offset_bottom = ob
