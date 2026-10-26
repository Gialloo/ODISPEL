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


# Scritta da videoregistratore (OSD tipo DECK/PLAY/SP) per i tasti VHS: VT323, licenza OFL
static func vhs() -> Font:
	return _font("VT323-Regular.ttf")


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


# Tasto VHS (richiesta dell'autore, 26/10/2026): schermo arancio-rosso di videocassetta con scanline, scritta OSD
# chiara e un po' sgranata, tutto al 65% di opacita' per sembrare un ologramma. Per i tasti dei menu, MAI per i comandi
# d'azione dei personaggi in combattimento.
const VHS_RED: Color = Color("#c8401e")
const VHS_TEXT: Color = Color("#fff8f0")
const VHS_ALPHA: float = 0.65


static func vhs_button(text: String, size: int = 26, min_w: float = 0.0, tint: Color = VHS_RED) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", vhs())
	b.add_theme_font_size_override("font_size", int(size * 1.45))   # VT323 e' stretto: piu' grande per leggerlo sul telefono
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, VHS_TEXT)
	b.add_theme_color_override("font_disabled_color", Color(VHS_TEXT.r, VHS_TEXT.g, VHS_TEXT.b, 0.5))
	b.add_theme_stylebox_override("normal", _vhs_box(tint))
	b.add_theme_stylebox_override("hover", _vhs_box(tint.lightened(0.12)))
	b.add_theme_stylebox_override("pressed", _vhs_box(tint.lightened(0.25)))
	b.add_theme_stylebox_override("disabled", _vhs_box(tint.darkened(0.5)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.custom_minimum_size = Vector2(min_w, 64.0 if is_touch() else 52.0)
	b.modulate.a = VHS_ALPHA
	b.mouse_entered.connect(func() -> void: b.modulate.a = 0.85)
	b.mouse_exited.connect(func() -> void: b.modulate.a = VHS_ALPHA)
	b.button_down.connect(func() -> void: b.modulate.a = 0.95)
	b.button_up.connect(func() -> void: b.modulate.a = VHS_ALPHA)
	# sopra il tasto: scanline, sbavatura rosso/ciano della scritta e il triangolo PLAY quando e' scelto
	var fx := Control.new()
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx.draw.connect(func() -> void: _vhs_fx(b, fx))
	b.add_child(fx)
	b.mouse_entered.connect(fx.queue_redraw)
	b.mouse_exited.connect(fx.queue_redraw)
	b.resized.connect(fx.queue_redraw)
	return b


static func _vhs_box(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = Color(VHS_TEXT.r, VHS_TEXT.g, VHS_TEXT.b, 0.35)
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.content_margin_left = 44
	s.content_margin_right = 22
	s.content_margin_top = 2
	s.content_margin_bottom = 4
	return s


static func _vhs_fx(b: Button, fx: Control) -> void:
	var s: Vector2 = fx.size
	var f: Font = vhs()
	var fs: int = b.get_theme_font_size("font_size")
	var base: float = (s.y + f.get_ascent(fs) - f.get_descent(fs)) * 0.5
	# sbavatura del nastro: la scritta ripetuta spostata in rosso e ciano
	fx.draw_string(f, Vector2(44 + 2, base), b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.15, 0.1, 0.35))
	fx.draw_string(f, Vector2(44 - 2, base), b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.2, 0.9, 1, 0.22))
	# bagliore del tubo catodico: la scritta ripetuta di un pixel attorno, bianca e leggera
	for o in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		fx.draw_string(f, Vector2(44, base) + o, b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.22))
	# bordi del vecchio televisore: piu' scuri ai lati
	var edge: float = minf(60.0, s.x * 0.18)
	var dark := Color(0, 0, 0, 0.35)
	var clear := Color(0, 0, 0, 0)
	fx.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(edge, 0), Vector2(edge, s.y), Vector2(0, s.y)]),
		PackedColorArray([dark, clear, clear, dark]))
	fx.draw_polygon(PackedVector2Array([Vector2(s.x - edge, 0), Vector2(s.x, 0), Vector2(s.x, s.y), Vector2(s.x - edge, s.y)]),
		PackedColorArray([clear, dark, dark, clear]))
	# grana del nastro: puntini fissi (sempre gli stessi per lo stesso tasto, niente sfarfallio)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(b.text)
	for i in int(s.x * s.y / 220.0):
		var c: float = rng.randf()
		fx.draw_rect(Rect2(rng.randf() * s.x, rng.randf() * s.y, 2, 1), Color(c, c, c, 0.12))
	# scanline: una riga scura ogni 3 px, una chiara ogni 6
	var y: float = 0.0
	while y < s.y:
		fx.draw_line(Vector2(0, y), Vector2(s.x, y), Color(0, 0, 0, 0.22), 1.0)
		if int(y) % 6 == 0:
			fx.draw_line(Vector2(0, y + 1), Vector2(s.x, y + 1), Color(1, 1, 1, 0.05), 1.0)
		y += 3.0
	# PLAY: triangolo pieno sul tasto scelto, vuoto sugli altri
	var cy: float = s.y * 0.5
	var tri := PackedVector2Array([Vector2(16, cy - 9), Vector2(16, cy + 9), Vector2(31, cy)])
	if b.is_hovered() or b.has_meta("vhs_scelto"):   # vhs_scelto: tasto scelto senza mouse (pad, tastiera, prove)
		fx.draw_colored_polygon(tri, VHS_TEXT)
	else:
		tri.append(tri[0])
		fx.draw_polyline(tri, Color(VHS_TEXT.r, VHS_TEXT.g, VHS_TEXT.b, 0.6), 2.0)


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


# Lista scorrevole fatta per il telefono (decisione dell'autore, 25/10/2026): si trascina col dito anche partendo
# da un tasto (i tasti passano il trascinamento al contenitore), la barra e' piu' spessa di 3 px per prenderla col dito
# e sta 4 px piu' a destra: chi chiama allarga il contenitore di 4 px per lasciarlo simmetrico.
const SCROLL_EXTRA_W: float = 3.0
const SCROLL_SHIFT: float = 4.0


static func phone_scroll(sc: ScrollContainer, col: Color = CREAM) -> void:
	sc.scroll_deadzone = 12
	var bar: VScrollBar = sc.get_v_scroll_bar()
	var w: float = maxf(bar.get_combined_minimum_size().x, 8.0) + SCROLL_EXTRA_W
	bar.custom_minimum_size.x = w
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.35)
	track.set_corner_radius_all(int(w * 0.5))
	track.content_margin_left = w * 0.5
	track.content_margin_right = w * 0.5
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(col, 0.85)
	grab.set_corner_radius_all(int(w * 0.5))
	grab.content_margin_left = w * 0.5
	grab.content_margin_right = w * 0.5
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("grabber", grab)
	bar.add_theme_stylebox_override("grabber_highlight", grab)
	bar.add_theme_stylebox_override("grabber_pressed", grab)
	sc.add_theme_constant_override("scrollbar_h_separation", int(SCROLL_SHIFT))


# I tasti dentro una lista scorrevole lasciano passare il trascinamento al contenitore (sul telefono prima si bloccava)
static func pass_drag(b: Control) -> void:
	b.mouse_filter = Control.MOUSE_FILTER_PASS

