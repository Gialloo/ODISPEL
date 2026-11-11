extends CanvasLayer
## Interfaccia «alla Persona» ma nostra: riquadro dei dialoghi storto con ritratti
## grandi che entrano di lato, cartellino del nome inclinato, scelte a lamelle,
## cartelli di data e luogo, barre da film, onomatopee e balloon sopra le teste.
## Colori: notte urbana e neon (STILE_VISIVO.md, 24/10/2026).

signal avanti
signal scelto(indice: int)

const COLORE := {
	"lance": Color("#ff2340"), "nox": Color("#2ef2ff"), "saul": Color("#d8ff3a"), "rio": Color("#a65bff"),
	"narra": Color("#3dff8a"),
}
## Lato del ritratto: chi parla entra dal suo lato e resta, scurito, finché la scena non finisce.
const LATO := {"lance": -1, "saul": -1, "nox": 1, "rio": 1}
const VELOCITA_TESTO := 55.0

var nomi := {"lance": "LANCE", "nox": "NOX", "saul": "SAUL", "rio": "???"}
var font_titolo: Font = preload("res://assets/fonts/ArchivoBlack-Regular.ttf")
var font_testo: Font = preload("res://assets/fonts/Roboto-Bold.ttf")
var attivo := false

var _radice: Control
var _ritratti := {}         # lato -> TextureRect
var _ritratto_chi := {}     # lato -> chi
var _box: Control
var _box_fondo: Polygon2D
var _box_ombra: Polygon2D
var _box_bordo: Line2D
var _cartellino: Node2D
var _cartellino_fondo: Polygon2D
var _cartellino_testo: Label
var _testo: RichTextLabel
var _freccia: Label
var _scelte: VBoxContainer
var _scrivendo := false
var _in_scelta := false
var _barre: Array[ColorRect] = []
var _livello_balloon: Control
var _cache_tex := {}

func _ready() -> void:
	layer = 10
	_radice = Control.new()
	_radice.set_anchors_preset(Control.PRESET_FULL_RECT)
	_radice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_radice)
	_livello_balloon = Control.new()
	_livello_balloon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_livello_balloon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radice.add_child(_livello_balloon)
	for i in 2:
		var b := ColorRect.new()
		b.color = Color.BLACK
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_radice.add_child(b)
		_barre.append(b)
	for lato in [-1, 1]:
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.flip_h = lato == 1
		tr.visible = false
		_radice.add_child(tr)
		_ritratti[lato] = tr
	_costruisci_box()
	_scelte = VBoxContainer.new()
	_scelte.add_theme_constant_override("separation", 14)
	_scelte.visible = false
	_radice.add_child(_scelte)
	get_viewport().size_changed.connect(_impagina)
	_impagina()
	_box.visible = false

func _costruisci_box() -> void:
	_box = Control.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radice.add_child(_box)
	_box_ombra = Polygon2D.new()
	_box.add_child(_box_ombra)
	_box_fondo = Polygon2D.new()
	_box_fondo.color = Color(0.02, 0.02, 0.04, 0.94)
	_box.add_child(_box_fondo)
	_box_bordo = Line2D.new()
	_box_bordo.width = 4.0
	_box_bordo.default_color = Color.WHITE
	_box_bordo.closed = true
	_box_bordo.joint_mode = Line2D.LINE_JOINT_SHARP
	_box.add_child(_box_bordo)
	_cartellino = Node2D.new()
	_box.add_child(_cartellino)
	_cartellino_fondo = Polygon2D.new()
	_cartellino.add_child(_cartellino_fondo)
	_cartellino_testo = Label.new()
	_cartellino_testo.add_theme_font_override("font", font_titolo)
	_cartellino_testo.add_theme_font_size_override("font_size", 34)
	_cartellino_testo.add_theme_color_override("font_color", Color.WHITE)
	_cartellino_testo.add_theme_color_override("font_outline_color", Color.BLACK)
	_cartellino_testo.add_theme_constant_override("outline_size", 10)
	_cartellino_testo.position = Vector2(26, -6)
	_cartellino.add_child(_cartellino_testo)
	_testo = RichTextLabel.new()
	_testo.bbcode_enabled = true
	_testo.scroll_active = false
	_testo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_testo.add_theme_font_override("normal_font", font_testo)
	_testo.add_theme_font_override("italics_font", font_testo)
	_testo.add_theme_font_size_override("normal_font_size", 31)
	_testo.add_theme_font_size_override("italics_font_size", 30)
	_testo.add_theme_color_override("default_color", Color.WHITE)
	_testo.add_theme_constant_override("line_separation", 6)
	_box.add_child(_testo)
	_freccia = Label.new()
	_freccia.text = "▼"
	_freccia.add_theme_font_size_override("font_size", 30)
	_box.add_child(_freccia)

func _dim() -> Vector2:
	return _radice.get_viewport_rect().size

func _impagina() -> void:
	var s := _dim()
	var w := s.x
	var h := s.y
	var poly := PackedVector2Array([Vector2(70, h - 236), Vector2(w - 56, h - 254), Vector2(w - 92, h - 26), Vector2(40, h - 18)])
	_box_fondo.polygon = poly
	_box_bordo.points = poly
	var ombra := PackedVector2Array()
	for p in poly:
		ombra.append(p + Vector2(12, 12))
	_box_ombra.polygon = ombra
	_cartellino.position = Vector2(84, h - 262)
	_cartellino.rotation_degrees = -4.0
	_cartellino_fondo.polygon = PackedVector2Array([Vector2(0, 0), Vector2(260, -12), Vector2(250, 46), Vector2(8, 52)])
	_testo.position = Vector2(118, h - 206)
	_testo.size = Vector2(w - 300, 172)
	_freccia.position = Vector2(w - 150, h - 78)
	var ph := h * 0.84
	var pw := ph * (512.0 / 768.0)
	_ritratti[-1].size = Vector2(pw, ph)
	_ritratti[-1].position = Vector2(-pw * 0.12, h - ph - 40)
	_ritratti[1].size = Vector2(pw, ph)
	_ritratti[1].position = Vector2(w - pw * 0.88, h - ph - 40)
	_scelte.position = Vector2(w - 640, h - 560)
	_scelte.size = Vector2(560, 280)
	var altezza_barra := 74.0
	_barre[0].size = Vector2(w, altezza_barra)
	_barre[1].size = Vector2(w, altezza_barra)
	_barre[1].position.y = h - altezza_barra if _barre[1].visible else h

func _process(delta: float) -> void:
	if _scrivendo:
		_testo.visible_ratio = minf(1.0, _testo.visible_ratio + delta * VELOCITA_TESTO / maxf(1.0, _testo.get_total_character_count()))
		if _testo.visible_ratio >= 1.0:
			_scrivendo = false
	_freccia.visible = not _scrivendo and not _in_scelta
	_freccia.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)

func _input(e: InputEvent) -> void:
	if not attivo or _in_scelta:
		return
	var premuto := false
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		premuto = true
	elif e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E]:
		premuto = true
	if premuto:
		get_viewport().set_input_as_handled()
		if _scrivendo:
			_testo.visible_ratio = 1.0
			_scrivendo = false
		else:
			avanti.emit()

# ---------------------------------------------------------------- dialoghi

func _tex(chi: String, faccia: String) -> Texture2D:
	var k := chi + "_" + faccia
	if not _cache_tex.has(k):
		var path := "res://assets/portraits/%s.png" % k
		if not ResourceLoader.exists(path):
			path = "res://assets/portraits/%s_neutro.png" % chi
		_cache_tex[k] = load(path)
	return _cache_tex[k]

## Una battuta. riga = {chi, faccia, testo} oppure {narra: testo}.
func di(riga: Dictionary) -> void:
	attivo = true
	_box.visible = true
	var chi: String = riga.get("chi", "narra")
	var testo: String = riga.get("testo", riga.get("narra", ""))
	var col: Color = COLORE.get(chi, COLORE["narra"])
	_box_ombra.color = col.darkened(0.15)
	if chi == "narra":
		_cartellino.visible = false
		_testo.text = "[i]" + testo + "[/i]"
		_testo.add_theme_color_override("default_color", Color("#cfe9ff"))
		for lato in _ritratti:
			_ritratti[lato].modulate = Color(0.35, 0.35, 0.45)
	else:
		_cartellino.visible = true
		_cartellino_fondo.color = col
		_cartellino_testo.text = nomi.get(chi, chi.to_upper())
		_testo.text = testo
		_testo.add_theme_color_override("default_color", Color.WHITE)
		_mostra_ritratto(chi, riga.get("faccia", "neutro"))
	_testo.visible_ratio = 0.0
	_scrivendo = true
	await avanti

func _mostra_ritratto(chi: String, faccia: String) -> void:
	var lato: int = LATO.get(chi, 1)
	var tr: TextureRect = _ritratti[lato]
	var nuovo: bool = _ritratto_chi.get(lato, "") != chi or not tr.visible
	tr.texture = _tex(chi, faccia)
	tr.visible = true
	tr.modulate = Color.WHITE
	_ritratti[-lato].modulate = Color(0.32, 0.32, 0.42)
	_ritratto_chi[lato] = chi
	var base_x: float = -tr.size.x * 0.12 if lato == -1 else _dim().x - tr.size.x * 0.88
	if nuovo:
		tr.position.x = base_x - 260.0 if lato == -1 else base_x + 260.0
		var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(tr, "position:x", base_x, 0.28)
	else:
		# piccolo sobbalzo quando cambia l'espressione
		var tw := create_tween()
		tw.tween_property(tr, "position:y", tr.position.y - 14.0, 0.07)
		tw.tween_property(tr, "position:y", tr.position.y, 0.1)

func scegli(opzioni: Array) -> int:
	attivo = true
	_in_scelta = true
	for c in _scelte.get_children():
		c.queue_free()
	var i := 0
	for o in opzioni:
		var b := Button.new()
		b.text = "  " + str(o)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(540, 78)
		b.add_theme_font_override("font", font_titolo)
		b.add_theme_font_size_override("font_size", 28)
		for stato in ["normal", "hover", "pressed", "focus"]:
			var sb := StyleBoxFlat.new()
			sb.skew = Vector2(0.28, 0)
			sb.border_width_left = 4
			sb.border_width_top = 4
			sb.border_width_right = 4
			sb.border_width_bottom = 4
			sb.border_color = Color.WHITE
			sb.bg_color = Color(0.02, 0.02, 0.04, 0.95) if stato == "normal" else Color("#ff2340")
			b.add_theme_stylebox_override(stato, sb)
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.BLACK)
		b.add_theme_color_override("font_focus_color", Color.BLACK)
		var indice := i
		b.pressed.connect(func(): scelto.emit(indice))
		_scelte.add_child(b)
		b.position.x = 0
		i += 1
	_scelte.visible = true
	_scelte.modulate.a = 0.0
	create_tween().tween_property(_scelte, "modulate:a", 1.0, 0.18)
	await get_tree().process_frame
	(_scelte.get_child(0) as Button).grab_focus()
	var r: int = await scelto
	_scelte.visible = false
	_in_scelta = false
	return r

## Nasconde solo il riquadro (durante i movimenti di camera), i ritratti restano.
func nascondi_box() -> void:
	_box.visible = false

func chiudi() -> void:
	attivo = false
	_box.visible = false
	for lato in _ritratti:
		var tr: TextureRect = _ritratti[lato]
		if tr.visible:
			var tw := create_tween()
			tw.tween_property(tr, "modulate:a", 0.0, 0.15)
			tw.tween_callback(func(): tr.visible = false)
	_ritratto_chi.clear()

# ---------------------------------------------------------------- regia a schermo

func barre(on: bool) -> void:
	var h := _dim().y
	_barre[0].visible = true
	_barre[1].visible = true
	var tw := create_tween().set_parallel()
	tw.tween_property(_barre[0], "position:y", 0.0 if on else -80.0, 0.35)
	tw.tween_property(_barre[1], "position:y", h - 74.0 if on else h + 6.0, 0.35)
	await tw.finished

## Cartello di data e luogo: banda storta che attraversa lo schermo.
func cartello(titolo: String, sotto: String) -> void:
	var s := _dim()
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radice.add_child(c)
	var fondo := ColorRect.new()
	fondo.color = Color(0.01, 0.01, 0.02, 0.88)
	fondo.size = s
	c.add_child(fondo)
	var banda := Polygon2D.new()
	banda.color = Color("#3dff8a")
	banda.polygon = PackedVector2Array([Vector2(-40, s.y * 0.38), Vector2(s.x + 40, s.y * 0.30), Vector2(s.x + 40, s.y * 0.56), Vector2(-40, s.y * 0.64)])
	c.add_child(banda)
	var banda2 := Polygon2D.new()
	banda2.color = Color.BLACK
	banda2.polygon = PackedVector2Array([Vector2(-40, s.y * 0.41), Vector2(s.x + 40, s.y * 0.33), Vector2(s.x + 40, s.y * 0.53), Vector2(-40, s.y * 0.61)])
	c.add_child(banda2)
	var t := Label.new()
	t.text = titolo
	t.add_theme_font_override("font", font_titolo)
	t.add_theme_font_size_override("font_size", 62)
	t.add_theme_color_override("font_color", Color.WHITE)
	t.rotation_degrees = -3.5
	t.position = Vector2(s.x * 0.12, s.y * 0.355)
	c.add_child(t)
	var st := Label.new()
	st.text = sotto
	st.add_theme_font_override("font", font_testo)
	st.add_theme_font_size_override("font_size", 32)
	st.add_theme_color_override("font_color", Color("#3dff8a"))
	st.rotation_degrees = -3.5
	st.position = Vector2(s.x * 0.13, s.y * 0.49)
	c.add_child(st)
	c.position.x = s.x
	var tw := create_tween()
	tw.tween_property(c, "position:x", 0.0, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.9)
	tw.tween_property(c, "position:x", -s.x, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tw.finished
	c.queue_free()

func onomato(parola: String) -> void:
	var s := _dim()
	var l := Label.new()
	l.text = parola
	l.add_theme_font_override("font", font_titolo)
	l.add_theme_font_size_override("font_size", 64)
	l.add_theme_color_override("font_color", Color("#e9f6ff"))
	l.add_theme_color_override("font_outline_color", Color("#ff2bd6"))
	l.add_theme_constant_override("outline_size", 10)
	l.add_theme_color_override("font_shadow_color", Color("#2ef2ff"))
	l.add_theme_constant_override("shadow_offset_x", 5)
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.rotation_degrees = -9.0
	l.position = Vector2(s.x * 0.58, s.y * 0.22)
	l.pivot_offset = Vector2(80, 40)
	l.scale = Vector2(0.3, 0.3)
	_radice.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2(1.1, 1.1), 0.1)
	tw.tween_property(l, "scale", Vector2.ONE, 0.08)
	tw.tween_interval(0.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_callback(l.queue_free)

func lampo() -> void:
	var r := ColorRect.new()
	r.color = Color(1, 1, 1, 0.8)
	r.size = _dim()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radice.add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "color:a", 0.0, 0.25)
	tw.tween_callback(r.queue_free)

# ---------------------------------------------------------------- balloon

## Balloon a fumetto sopra la testa di un personaggio, nel mondo.
## Segue la testa finché dura. Restituisce il nodo (per aspettarlo o toglierlo).
func balloon(chi: String, testo: String, punto_testa: Callable, camera: Camera3D, durata := 2.6) -> Control:
	var b := _Balloon.new()
	b.punto = punto_testa
	b.camera = camera
	_livello_balloon.add_child(b)
	b.imposta(chi, nomi.get(chi, chi.to_upper()), testo, COLORE.get(chi, Color.WHITE), font_titolo, font_testo)
	b.durata = durata
	return b

func togli_balloon() -> void:
	for c in _livello_balloon.get_children():
		c.queue_free()

class _Balloon extends Control:
	var punto: Callable
	var camera: Camera3D
	var durata := 2.6
	var _t := 0.0
	var _col := Color.WHITE
	var _nome: Label
	var _testo: Label
	var _forma := PackedVector2Array()

	func imposta(_chi: String, nome: String, testo: String, col: Color, ft: Font, fx: Font) -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_col = col
		_testo = Label.new()
		_testo.text = testo
		_testo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_testo.add_theme_font_override("font", fx)
		_testo.add_theme_font_size_override("font_size", 26)
		_testo.add_theme_color_override("font_color", Color.BLACK)
		_testo.custom_minimum_size = Vector2(0, 0)
		add_child(_testo)
		_nome = Label.new()
		_nome.text = nome
		_nome.add_theme_font_override("font", ft)
		_nome.add_theme_font_size_override("font_size", 20)
		_nome.add_theme_color_override("font_color", Color.BLACK)
		_nome.rotation_degrees = -6.0
		add_child(_nome)
		var larg := clampf(fx.get_string_size(testo, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 10.0, 120.0, 380.0)
		_testo.size = Vector2(larg, 0)
		_testo.position = Vector2(-larg * 0.5, -40)
		await get_tree().process_frame
		var alt := _testo.get_minimum_size().y
		_testo.size.y = alt
		_testo.position.y = -alt - 34
		_nome.position = Vector2(-larg * 0.5 - 18, _testo.position.y - 30)
		_forma = _crea_forma(Rect2(_testo.position - Vector2(22, 16), _testo.size + Vector2(44, 32)))
		pivot_offset = Vector2.ZERO
		scale = Vector2(0.2, 0.2)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		queue_redraw()

	func _crea_forma(r: Rect2) -> PackedVector2Array:
		# contorno a punte leggere, irregolare ma fisso
		var pts := PackedVector2Array()
		var rng := RandomNumberGenerator.new()
		rng.seed = int(r.size.x * 7 + r.size.y)
		var c := r.get_center()
		var n := 22
		for i in n:
			var a := TAU * i / n
			var d := Vector2(cos(a) * r.size.x * 0.56, sin(a) * r.size.y * 0.62)
			var k := 1.0 + (0.07 if i % 2 == 0 else -0.02) + rng.randf_range(-0.02, 0.03)
			pts.append(c + d * k)
		return pts

	func _process(delta: float) -> void:
		_t += delta
		if camera and punto.is_valid():
			var p3: Vector3 = punto.call()
			if camera.is_position_behind(p3):
				visible = false
			else:
				visible = true
				position = camera.unproject_position(p3)
		if _t > durata:
			modulate.a = maxf(0.0, 1.0 - (_t - durata) * 5.0)
			if modulate.a <= 0.0:
				queue_free()

	func _draw() -> void:
		if _forma.is_empty():
			return
		var ombra := PackedVector2Array()
		for p in _forma:
			ombra.append(p + Vector2(7, 7))
		draw_colored_polygon(ombra, _col)
		draw_colored_polygon(_forma, Color.WHITE)
		var chiuso := _forma.duplicate()
		chiuso.append(_forma[0])
		draw_polyline(chiuso, Color.BLACK, 4.0, true)
		# codina verso la testa
		var base_y := _testo.position.y + _testo.size.y + 12
		draw_colored_polygon(PackedVector2Array([Vector2(-14, base_y), Vector2(14, base_y), Vector2(2, -6)]), Color.WHITE)
		draw_polyline(PackedVector2Array([Vector2(-14, base_y + 1), Vector2(2, -6), Vector2(14, base_y + 1)]), Color.BLACK, 4.0, true)
		# cartellino del nome
		var np := _nome.position
		draw_set_transform(np, deg_to_rad(-6.0))
		draw_colored_polygon(PackedVector2Array([Vector2(-8, -2), Vector2(_nome.size.x + 10, -6), Vector2(_nome.size.x + 6, 26), Vector2(-4, 28)]), _col)
		draw_set_transform(Vector2.ZERO)
