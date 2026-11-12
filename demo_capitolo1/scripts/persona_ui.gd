extends CanvasLayer
## Interfaccia nello stile delle tavole dell'autore, «stile Persona 5» (12/11/2026):
## banda storta nera col filo bianco e la striscia del colore di chi parla, nome a lettere
## ritagliate, ritratti con contorno da adesivo sopra un retino, vignette a tutto schermo
## con cornice bianca a fulmine, scelte a lamelle, cartelli rossi, balloon sopra le teste.
## Colori: rosso, nero e bianco più il colore di ogni personaggio (STILE_VISIVO.md).

signal avanti
signal scelto(indice: int)

const COLORE := {
	"lance": Color("#ff2340"), "nox": Color("#2ef2ff"), "saul": Color("#d8ff3a"), "rio": Color("#a65bff"),
	"narra": Color("#3dff8a"),
}
## Lato del ritratto: chi parla entra dal suo lato e resta, scurito, finché la scena non finisce.
const LATO := {"lance": -1, "saul": -1, "nox": 1, "rio": 1}
const VELOCITA_TESTO := 55.0
## Altezza del volto nel ritratto (frazione dall'alto), per centrare i primi piani.
const VOLTO := {"lance": 0.37, "nox": 0.31, "saul": 0.36, "rio": 0.4}

## Nessuno conosce il nome degli altri all'inizio: si scopre parlando (regia "nome").
var nomi := {"lance": "LANCE", "nox": "???", "saul": "???", "rio": "???"}
var font_titolo: Font = preload("res://assets/fonts/ArchivoBlack-Regular.ttf")
var font_testo: Font = preload("res://assets/fonts/Roboto-Bold.ttf")
## Testo dei dialoghi: condensato e pieno come nelle tavole, grande per il telefono.
var font_dialogo: Font = preload("res://assets/fonts/Anton-Regular.ttf")
var attivo := false

var _radice: Control
var _ritratti := {}         # lato -> TextureRect
var _ritratto_chi := {}     # lato -> chi
var _box: Control
var _box_fondo: Polygon2D
var _box_ombra: Polygon2D
var _box_bordo: Line2D
var _box_striscia: Polygon2D
var _cartellino: Control
var _cartellino_di := ""
var _retini := {}           # lato -> Polygon2D col retino dietro al ritratto
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
		var rt := Polygon2D.new()
		rt.visible = false
		_radice.add_child(rt)
		_retini[lato] = rt
	for lato in [-1, 1]:
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.flip_h = lato == 1
		tr.visible = false
		tr.material = Fumetto.ritratto(Color.WHITE)
		_radice.add_child(tr)
		_ritratti[lato] = tr
	_costruisci_box()
	_scelte = VBoxContainer.new()
	_scelte.add_theme_constant_override("separation", 16)
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
	_box_fondo.color = Fumetto.NERO
	_box.add_child(_box_fondo)
	_box_striscia = Polygon2D.new()
	_box.add_child(_box_striscia)
	_box_bordo = Line2D.new()
	_box_bordo.width = 5.0
	_box_bordo.default_color = Fumetto.BIANCO
	_box_bordo.closed = true
	_box_bordo.joint_mode = Line2D.LINE_JOINT_SHARP
	_box.add_child(_box_bordo)
	_testo = RichTextLabel.new()
	_testo.bbcode_enabled = true
	_testo.scroll_active = false
	_testo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_testo.add_theme_font_override("normal_font", font_dialogo)
	_testo.add_theme_font_override("italics_font", font_dialogo)
	_testo.add_theme_font_size_override("normal_font_size", 36)
	_testo.add_theme_font_size_override("italics_font_size", 34)
	_testo.add_theme_color_override("default_color", Fumetto.BIANCO)
	_testo.add_theme_color_override("font_outline_color", Color.BLACK)
	_testo.add_theme_constant_override("outline_size", 6)
	_testo.add_theme_constant_override("line_separation", 4)
	_box.add_child(_testo)
	_cartellino = Control.new()
	_cartellino.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_cartellino)
	_freccia = Label.new()
	_freccia.text = "▶"
	_freccia.add_theme_font_size_override("font_size", 30)
	_freccia.add_theme_color_override("font_color", Fumetto.ROSSO)
	_box.add_child(_freccia)

func _dim() -> Vector2:
	return _radice.get_viewport_rect().size

## Banda dei dialoghi: storta, nera, filo bianco, ombra piena del colore di chi parla.
func _impagina() -> void:
	var s := _dim()
	var w := s.x
	var h := s.y
	var x0 := w * 0.13
	var x1 := w * 0.93
	var poly := PackedVector2Array([Vector2(x0 + 46, h - 238), Vector2(x1, h - 258), Vector2(x1 - 34, h - 30), Vector2(x0, h - 22)])
	_box_fondo.polygon = poly
	_box_bordo.points = poly
	_box_ombra.polygon = Fumetto.sposta(poly, Vector2(14, 12))
	# striscia del colore di chi parla lungo il lato alto, come nelle tavole
	_box_striscia.polygon = PackedVector2Array([poly[0] + Vector2(0, 2), poly[1] + Vector2(0, 2), poly[1] + Vector2(-2, 14), poly[0] + Vector2(-1, 14)])
	_cartellino.position = Vector2(x0 + 30, h - 310)
	_cartellino.rotation_degrees = -4.0
	_testo.position = Vector2(x0 + 70, h - 214)
	_testo.size = Vector2(x1 - x0 - 150, 176)
	_freccia.position = Vector2(x1 - 96, h - 84)
	var ph := h * 0.86
	var pw := ph * (512.0 / 768.0)
	_ritratti[-1].size = Vector2(pw, ph)
	_ritratti[-1].position = Vector2(-pw * 0.14, h - ph - 30)
	_ritratti[1].size = Vector2(pw, ph)
	_ritratti[1].position = Vector2(w - pw * 0.86, h - ph - 30)
	# retino dietro al ritratto di chi parla: angolo pieno di punti che sfumano verso il centro
	_retini[-1].polygon = PackedVector2Array([Vector2(0, h * 0.12), Vector2(w * 0.44, h), Vector2(0, h)])
	_retini[1].polygon = PackedVector2Array([Vector2(w, h * 0.12), Vector2(w, h), Vector2(w * 0.56, h)])
	_scelte.position = Vector2(w - 660, h - 590)
	_scelte.size = Vector2(580, 300)
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
	_freccia.position.x += sin(Time.get_ticks_msec() * 0.012) * 0.6

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
	if chi == "rio":
		faccia = "maschera"   # Rio ha sempre la maschera (decisione dell'autore, 11/11)
	var k := chi + "_" + faccia
	if not _cache_tex.has(k):
		var path := "res://assets/portraits/%s.png" % k
		if not ResourceLoader.exists(path):
			path = "res://assets/portraits/%s_neutro.png" % chi
		_cache_tex[k] = load(path)
	return _cache_tex[k]

func _metti_cartellino(chi: String) -> void:
	var nome: String = nomi.get(chi, chi.to_upper())
	if _cartellino_di == chi + nome:
		return
	_cartellino_di = chi + nome
	for c in _cartellino.get_children():
		c.queue_free()
	_cartellino.add_child(Fumetto.ritagli(nome, COLORE.get(chi, Color.WHITE), 54.0))

## Una battuta. riga = {chi, faccia, testo} oppure {narra: testo}.
func di(riga: Dictionary) -> void:
	attivo = true
	var appena_aperto := not _box.visible
	_box.visible = true
	var chi: String = riga.get("chi", "narra")
	var testo: String = riga.get("testo", riga.get("narra", ""))
	var col: Color = COLORE.get(chi, COLORE["narra"])
	if chi == "narra":
		_box_ombra.color = Fumetto.ROSSO
		_box_striscia.color = Fumetto.BIANCO
		_cartellino.visible = false
		_cartellino_di = ""
		_testo.text = "[i]" + testo + "[/i]"
		_testo.add_theme_color_override("default_color", Color("#d6dcea"))
		for lato in _ritratti:
			_ritratti[lato].modulate = Color(0.32, 0.32, 0.4)
			_retini[lato].visible = false
	else:
		_box_ombra.color = col
		_box_striscia.color = col
		_cartellino.visible = true
		_metti_cartellino(chi)
		_testo.text = testo
		_testo.add_theme_color_override("default_color", Fumetto.BIANCO)
		_mostra_ritratto(chi, riga.get("faccia", "neutro"))
	if appena_aperto:
		# la banda entra con uno scatto, come un colpo di forbici
		_box.scale = Vector2(1.0, 0.2)
		_box.pivot_offset = Vector2(_dim().x * 0.5, _dim().y - 130)
		create_tween().tween_property(_box, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_testo.visible_ratio = 0.0
	_scrivendo = true
	await avanti

func _mostra_ritratto(chi: String, faccia: String) -> void:
	var lato: int = LATO.get(chi, 1)
	var tr: TextureRect = _ritratti[lato]
	var nuovo: bool = _ritratto_chi.get(lato, "") != chi or not tr.visible
	var col: Color = COLORE.get(chi, Color.WHITE)
	tr.texture = _tex(chi, faccia)
	(tr.material as ShaderMaterial).set_shader_parameter("contorno", col)
	tr.visible = true
	tr.modulate = Color.WHITE
	_ritratti[-lato].modulate = Color(0.3, 0.3, 0.38)
	_retini[-lato].visible = false
	var rt: Polygon2D = _retini[lato]
	var s := _dim()
	var angolo := Vector2(0, s.y) if lato == -1 else Vector2(s.x, s.y)
	rt.material = Fumetto.retino(col, Color(0, 0, 0, 0), 15.0, angolo, angolo + Vector2(-lato * s.x * 0.36, -s.y * 0.5), 0.46, 0.0)
	rt.visible = true
	_ritratto_chi[lato] = chi
	var base_x: float = -tr.size.x * 0.14 if lato == -1 else s.x - tr.size.x * 0.86
	if nuovo:
		tr.position.x = base_x - 300.0 if lato == -1 else base_x + 300.0
		var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(tr, "position:x", base_x, 0.24)
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
		b.text = "   " + str(o)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(560, 84)
		b.add_theme_font_override("font", font_dialogo)
		b.add_theme_font_size_override("font_size", 34)
		for stato in ["normal", "hover", "pressed", "focus"]:
			var sb := StyleBoxFlat.new()
			sb.skew = Vector2(0.32, 0)
			sb.border_width_left = 14
			sb.border_width_top = 4
			sb.border_width_right = 4
			sb.border_width_bottom = 4
			var acceso: bool = stato != "normal"
			sb.border_color = Fumetto.ROSSO if not acceso else Fumetto.NERO
			sb.bg_color = Fumetto.NERO if not acceso else Fumetto.ROSSO
			sb.shadow_color = Fumetto.BIANCO if acceso else Fumetto.ROSSO
			sb.shadow_size = 0
			sb.shadow_offset = Vector2(8, 8)
			b.add_theme_stylebox_override(stato, sb)
		b.add_theme_color_override("font_color", Fumetto.BIANCO)
		b.add_theme_color_override("font_hover_color", Fumetto.NERO)
		b.add_theme_color_override("font_focus_color", Fumetto.NERO)
		b.add_theme_color_override("font_pressed_color", Fumetto.NERO)
		b.rotation_degrees = -3.0 + 2.0 * (i % 2)
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
	_cartellino_di = ""
	for lato in _retini:
		_retini[lato].visible = false

# ---------------------------------------------------------------- regia a schermo

func barre(on: bool) -> void:
	var h := _dim().y
	_barre[0].visible = true
	_barre[1].visible = true
	var tw := create_tween().set_parallel()
	tw.tween_property(_barre[0], "position:y", 0.0 if on else -80.0, 0.35)
	tw.tween_property(_barre[1], "position:y", h - 74.0 if on else h + 6.0, 0.35)
	await tw.finished

## Cartello di data e luogo: banda rossa col retino e la cornice bianca a fulmine.
func cartello(titolo: String, sotto: String) -> void:
	var s := _dim()
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radice.add_child(c)
	var fondo := ColorRect.new()
	fondo.color = Color(0.01, 0.0, 0.01, 0.9)
	fondo.size = s
	c.add_child(fondo)
	var r := Rect2(-60, s.y * 0.30, s.x + 120, s.y * 0.34)
	var forma := Fumetto.fulmine(r, 46.0, 26.0, hash(titolo))
	var bianco := Polygon2D.new()
	bianco.polygon = Fumetto.fulmine(r.grow(14), 46.0, 30.0, hash(titolo) + 1)
	bianco.color = Fumetto.BIANCO
	c.add_child(bianco)
	var banda := Polygon2D.new()
	banda.polygon = forma
	banda.color = Fumetto.ROSSO
	c.add_child(banda)
	var punti := Polygon2D.new()
	punti.polygon = forma
	punti.material = Fumetto.retino(Color(0.35, 0.0, 0.06, 0.9), Color(0, 0, 0, 0), 13.0, Vector2(s.x, r.position.y), Vector2(s.x * 0.35, r.end.y), 0.5, 0.0)
	c.add_child(punti)
	c.rotation_degrees = -3.0
	c.pivot_offset = s * 0.5
	var t := Label.new()
	t.text = titolo
	t.add_theme_font_override("font", font_dialogo)
	t.add_theme_font_size_override("font_size", 92)
	t.add_theme_color_override("font_color", Fumetto.BIANCO)
	t.add_theme_color_override("font_outline_color", Fumetto.NERO)
	t.add_theme_constant_override("outline_size", 18)
	t.position = Vector2(s.x * 0.08, s.y * 0.315)
	c.add_child(t)
	var st := Label.new()
	st.text = "  " + sotto + "  "
	st.add_theme_font_override("font", font_dialogo)
	st.add_theme_font_size_override("font_size", 34)
	st.add_theme_color_override("font_color", Fumetto.BIANCO)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Fumetto.NERO
	sb.skew = Vector2(0.3, 0)
	st.add_theme_stylebox_override("normal", sb)
	st.position = Vector2(s.x * 0.1, s.y * 0.5)
	c.add_child(st)
	c.position.x = s.x
	var tw := create_tween()
	tw.tween_property(c, "position:x", 0.0, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.9)
	tw.tween_property(c, "position:x", -s.x * 1.2, 0.28).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tw.finished
	c.queue_free()

## Vignetta a tutto schermo per i momenti forti (stile delle tavole): primo piano del
## personaggio a due colori col retino, dentro una cornice bianca a fulmine, nome ritagliato.
func vignetta(chi: String, faccia := "serio", nome := "", durata := 1.5) -> void:
	var s := _dim()
	var col: Color = COLORE.get(chi, Fumetto.ROSSO)
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radice.add_child(c)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.55)
	velo.size = s
	c.add_child(velo)
	var r := Rect2(-30, s.y * 0.2, s.x + 60, s.y * 0.5)
	var seme := hash(chi + faccia)
	var bianco := Polygon2D.new()
	bianco.polygon = Fumetto.fulmine(r.grow(18), 52.0, 40.0, seme)
	bianco.color = Fumetto.BIANCO
	c.add_child(bianco)
	var forma := Fumetto.fulmine(r, 52.0, 30.0, seme + 7)
	var fondo := Polygon2D.new()
	fondo.polygon = forma
	fondo.color = col.darkened(0.25)
	c.add_child(fondo)
	var punti := Polygon2D.new()
	punti.polygon = forma
	punti.material = Fumetto.retino(Color(0, 0, 0, 0.55), Color(0, 0, 0, 0), 12.0, Vector2(0, r.end.y), Vector2(s.x * 0.5, r.position.y), 0.5, 0.05)
	c.add_child(punti)
	# il primo piano: il volto sta nel terzo alto del ritratto, lo porto al centro della vignetta
	var tex := _tex(chi, faccia)
	var largo := s.x * 0.62
	var dove := Rect2(Vector2(s.x * 0.42 - largo * 0.5, r.get_center().y - largo * 1.5 * float(VOLTO.get(chi, 0.35))), Vector2(largo, largo * 1.5))
	var volto := Fumetto.ritaglio(forma, tex, dove, LATO.get(chi, 1) == 1)
	volto.material = Fumetto.ritratto(Fumetto.BIANCO, 6.0, true, Fumetto.NERO, col)
	c.add_child(volto)
	if nome != "":
		var n := Fumetto.ritagli(nome, col, 74.0)
		n.position = Vector2(s.x * 0.66, r.end.y - 70)
		n.rotation_degrees = -6.0
		c.add_child(n)
	c.pivot_offset = Vector2(s.x * 0.5, r.get_center().y)
	c.scale = Vector2(1.25, 0.05)
	c.rotation_degrees = -4.0
	var tw := create_tween()
	tw.tween_property(c, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "rotation_degrees", -2.0, durata)
	tw.tween_property(c, "position:x", -s.x * 1.3, 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tw.finished
	c.queue_free()

## Il gruppo in fette storte, una per personaggio, ognuna del suo colore (tavola a tre volti).
func trittico(chi: Array, durata := 2.0) -> void:
	var s := _dim()
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radice.add_child(c)
	var n := chi.size()
	var r := Rect2(0, s.y * 0.14, s.x, s.y * 0.66)
	var bianco := Polygon2D.new()
	bianco.polygon = Fumetto.fulmine(r.grow(16), 60.0, 34.0, 3)
	bianco.color = Fumetto.BIANCO
	c.add_child(bianco)
	var nero := Polygon2D.new()
	nero.polygon = Fumetto.fulmine(r.grow(4), 60.0, 20.0, 4)
	nero.color = Fumetto.NERO
	c.add_child(nero)
	var inclina := s.x * 0.06
	var fette: Array[Control] = []
	for i in n:
		var who: String = chi[i]
		var col: Color = COLORE.get(who, Fumetto.ROSSO)
		var xa := r.position.x + r.size.x * i / n
		var xb := r.position.x + r.size.x * (i + 1) / n
		var gap := 9.0
		var forma := PackedVector2Array([
			Vector2(xa + inclina + gap, r.position.y + 10), Vector2(xb + inclina - gap, r.position.y + 10),
			Vector2(xb - inclina - gap, r.end.y - 10), Vector2(xa - inclina + gap, r.end.y - 10)])
		var f := Control.new()
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(f)
		var fondo := Polygon2D.new()
		fondo.polygon = forma
		fondo.color = col.darkened(0.55)
		f.add_child(fondo)
		var punti := Polygon2D.new()
		punti.polygon = forma
		punti.material = Fumetto.retino(Color(col.r, col.g, col.b, 0.5), Color(0, 0, 0, 0), 11.0, Vector2(xa, r.end.y), Vector2(xb, r.position.y), 0.45, 0.05)
		f.add_child(punti)
		var largo := (xb - xa) * 1.9
		var dove := Rect2(Vector2((xa + xb) * 0.5 - largo * 0.5, r.get_center().y - largo * 1.5 * (float(VOLTO.get(who, 0.35)) - 0.03)), Vector2(largo, largo * 1.5))
		var volto := Fumetto.ritaglio(forma, _tex(who, "serio"), dove, i % 2 == 1)
		volto.material = Fumetto.ritratto(Fumetto.BIANCO, 5.0, true, Fumetto.NERO, col)
		f.add_child(volto)
		var nm := Fumetto.ritagli(nomi.get(who, who.to_upper()), col, 40.0, i)
		nm.position = Vector2(xa + 10, r.end.y - 64)
		f.add_child(nm)
		f.modulate.a = 0.0
		f.position.y = 40.0 if i % 2 == 0 else -40.0
		fette.append(f)
	c.rotation_degrees = -2.0
	c.pivot_offset = s * 0.5
	var tw := create_tween()
	for i in fette.size():
		tw.parallel().tween_property(fette[i], "modulate:a", 1.0, 0.12).set_delay(i * 0.09)
		tw.parallel().tween_property(fette[i], "position:y", 0.0, 0.16).set_delay(i * 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(durata)
	tw.tween_property(c, "modulate:a", 0.0, 0.2)
	await tw.finished
	c.queue_free()

func onomato(parola: String) -> void:
	var s := _dim()
	var l := Label.new()
	l.text = parola
	l.add_theme_font_override("font", font_dialogo)
	l.add_theme_font_size_override("font_size", 96)
	l.add_theme_color_override("font_color", Fumetto.BIANCO)
	l.add_theme_color_override("font_outline_color", Fumetto.NERO)
	l.add_theme_constant_override("outline_size", 16)
	l.add_theme_color_override("font_shadow_color", Fumetto.ROSSO)
	l.add_theme_constant_override("shadow_offset_x", 9)
	l.add_theme_constant_override("shadow_offset_y", 7)
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

func lampo(col := Color.WHITE) -> void:
	var r := ColorRect.new()
	r.color = Color(col.r, col.g, col.b, 0.8)
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
	# un personaggio ha un solo balloon alla volta: il nuovo sostituisce il vecchio
	for vecchio in _livello_balloon.get_children():
		if vecchio.get_meta("chi", "") == chi:
			vecchio.queue_free()
	var b := _Balloon.new()
	b.set_meta("chi", chi)
	b.punto = punto_testa
	b.camera = camera
	_livello_balloon.add_child(b)
	b.imposta(Fumetto.ritagli(nomi.get(chi, chi.to_upper()), COLORE.get(chi, Color.WHITE), 24.0), testo, COLORE.get(chi, Color.WHITE), font_dialogo)
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
	var _nome: Control
	var _testo: Label
	var _forma := PackedVector2Array()

	func imposta(nome: Control, testo: String, col: Color, fx: Font) -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_col = col
		_testo = Label.new()
		_testo.text = testo
		_testo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_testo.add_theme_font_override("font", fx)
		_testo.add_theme_font_size_override("font_size", 28)
		_testo.add_theme_color_override("font_color", Fumetto.NERO)
		add_child(_testo)
		_nome = nome
		add_child(_nome)
		var larg := clampf(fx.get_string_size(testo, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x + 10.0, 120.0, 380.0)
		_testo.size = Vector2(larg, 0)
		_testo.position = Vector2(-larg * 0.5, -40)
		await get_tree().process_frame
		var alt := _testo.get_minimum_size().y
		_testo.size.y = alt
		_testo.position.y = -alt - 34
		_nome.position = Vector2(-larg * 0.5 - 22, _testo.position.y - 44)
		_nome.rotation_degrees = -6.0
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
		draw_colored_polygon(Fumetto.sposta(_forma, Vector2(9, 8)), Fumetto.NERO)
		draw_colored_polygon(Fumetto.sposta(_forma, Vector2(5, 4)), _col)
		draw_colored_polygon(_forma, Fumetto.BIANCO)
		var chiuso := _forma.duplicate()
		chiuso.append(_forma[0])
		draw_polyline(chiuso, Fumetto.NERO, 5.0, true)
		# codina verso la testa
		var base_y := _testo.position.y + _testo.size.y + 12
		draw_colored_polygon(PackedVector2Array([Vector2(-14, base_y), Vector2(14, base_y), Vector2(2, -6)]), Fumetto.BIANCO)
		draw_polyline(PackedVector2Array([Vector2(-14, base_y + 1), Vector2(2, -6), Vector2(14, base_y + 1)]), Fumetto.NERO, 5.0, true)
