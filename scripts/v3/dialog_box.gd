class_name DialogBox
extends Control

# Dialoghi in stile Persona 5: ritratti grandi che entrano di lato, chi parla in primo piano e chi ascolta scurito,
# fumetto obliquo con il nome in una targhetta del colore del personaggio, espressione che cambia a ogni battuta.
#
# Battuta: {"chi": "saul", "espr": "sfotto", "lato": "sx", "testo": "..."}
#   chi  = id del personaggio (ferri, nox, zecca, saul) oppure un nome libero ("DISTRIBUTORE", "???") senza ritratto
#   espr = neutro, felice, arrabbiato, triste, sorpreso, sfotto, serio (zecca anche: maschera)
#   lato = sx o dx (se manca: il primo che parla a sinistra, il secondo a destra)
# Ritratti: res://assets/portraits/<chi>_<espr>.png (girati verso destra; a destra si specchiano).
# SALTA chiude tutto e mostra per qualche secondo il riassunto della scena, cosi' chi salta non si perde.

signal finished

const CPS: float = 48.0
const PORTRAIT_DIR: String = "res://assets/portraits/"

var _lines: Array = []
var _i: int = -1
var _shown: float = 0.0
var _active: bool = false
var _recap: String = ""
var _t: float = 0.0

var _stage: Control
var _shade: ColorRect
var _box: Control
var _name: Label
var _text: Label
var _skip: Button
var _recap_lbl: Label
var _pt: Dictionary = {}          # "sx"/"dx" -> TextureRect
var _who: Dictionary = {}         # "sx"/"dx" -> id in scena
var _choices: VBoxContainer
var _waiting_choice: bool = false
var _speaker_col: Color = Ui.YELLOW
var _speaker_side: String = "sx"


func _ready() -> void:
	Ui.place(self, 0, 0, 1, 1)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage = Control.new()
	Ui.place(_stage, 0, 0, 1, 1)
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.gui_input.connect(_on_gui)
	_stage.visible = false
	add_child(_stage)
	_shade = ColorRect.new()
	_shade.color = Color(0.02, 0.0, 0.06, 0.45)
	Ui.place(_shade, 0, 0, 1, 1)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_shade)
	for side in ["sx", "dx"]:
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.flip_h = side == "dx"
		tr.visible = false
		_stage.add_child(tr)
		_pt[side] = tr
	_box = Control.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.draw.connect(_draw_box)
	Ui.place(_box, 0, 0, 1, 1)
	_stage.add_child(_box)
	_name = Ui.label("", 34, Ui.INK, Ui.names())
	_stage.add_child(_name)
	_text = Ui.label("", 29 if Ui.is_touch() else 26, Ui.CREAM, Ui.story())
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_stage.add_child(_text)
	_skip = Ui.button("SALTA", Ui.CREAM, 20)
	Ui.place(_skip, 1.0, 0, 1.0, 0, -170, 24, -24, 84)
	_skip.pressed.connect(skip)
	_stage.add_child(_skip)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 10)
	Ui.place(_choices, 0.5, 0.2, 0.5, 0.2, -330, 0, 330, 300)
	_choices.visible = false
	_stage.add_child(_choices)
	_recap_lbl = Ui.label("", 24, Ui.CREAM, null, 8)
	# fondo scuro: il riassunto si legge anche sopra una strada piena di neon
	_recap_lbl.add_theme_stylebox_override("normal", Ui.box(Color(0.06, 0.03, 0.1, 0.85), Ui.INK, 0, 6, 0))
	_recap_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_recap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ui.place(_recap_lbl, 0.15, 0, 0.85, 0, 0, 96, 0, 200)
	_recap_lbl.visible = false
	add_child(_recap_lbl)
	resized.connect(_layout)


func is_open() -> bool:
	return _active


# Avvia una scena: righe e (facoltativo) il riassunto da mostrare se si salta
func play(lines: Array, recap: String = "") -> void:
	# copia: le scelte inseriscono righe e non devono toccare i dati condivisi (prima, rigiocando, partivano due rami)
	_lines = lines.duplicate()
	_recap = recap
	_i = -1
	_who = {}
	for side in _pt:
		(_pt[side] as TextureRect).visible = false
	_active = true
	_stage.visible = true
	_stage.modulate.a = 0.0
	create_tween().tween_property(_stage, "modulate:a", 1.0, 0.15)
	Breadcrumb.mark("dialogo")
	_layout()
	_next()


func _layout() -> void:
	var s: Vector2 = size
	var ph: float = s.y * 0.98
	var pw: float = ph * 2.0 / 3.0
	for side in _pt:
		var tr: TextureRect = _pt[side]
		tr.size = Vector2(pw, ph)
		tr.position = Vector2(-pw * 0.12 if side == "sx" else s.x - pw * 0.88, s.y - ph + 10.0)
	var bx: Rect2 = _box_rect()
	_text.position = bx.position + Vector2(44, 34)
	_text.size = Vector2(bx.size.x - 100, bx.size.y - 50)
	_name.position = bx.position + Vector2(40, -40)
	_box.queue_redraw()


func _box_rect() -> Rect2:
	var s: Vector2 = size
	var h: float = 172.0
	var w: float = minf(s.x * 0.66, 900.0)
	var x: float = s.x * 0.5 - w * 0.5 + (60.0 if _speaker_side == "sx" else -60.0)
	return Rect2(x, s.y - h - 26.0, w, h)


func _draw_box() -> void:
	if not _active:
		return
	var r: Rect2 = _box_rect()
	var k: float = 26.0                   # inclinazione
	var pts := PackedVector2Array([r.position + Vector2(k, 0), r.position + Vector2(r.size.x, -8), r.end - Vector2(k, 0), r.position + Vector2(0, r.size.y + 6)])
	var shadow := PackedVector2Array()
	var border := PackedVector2Array()
	var c: Vector2 = r.get_center()
	for p in pts:
		shadow.append(p + Vector2(12, 12))
		border.append(c + (p - c) * 1.0 + (p - c).normalized() * 9.0)
	_box.draw_colored_polygon(shadow, Color(_speaker_col.r, _speaker_col.g, _speaker_col.b, 0.9))
	_box.draw_colored_polygon(border, Ui.CREAM)
	_box.draw_colored_polygon(pts, Color(0.04, 0.02, 0.08, 0.97))
	# targhetta del nome (parallelogramma inclinato)
	var nw: float = _name.get_combined_minimum_size().x + 46.0
	var np: Vector2 = r.position + Vector2(24, -48)
	var tag := PackedVector2Array([np + Vector2(14, 0), np + Vector2(nw + 14, -6), np + Vector2(nw, 46), np + Vector2(0, 50)])
	var tag_b := PackedVector2Array()
	for p in tag:
		tag_b.append(p + (p - (np + Vector2(nw * 0.5, 24))).normalized() * 5.0)
	_box.draw_colored_polygon(tag_b, Ui.INK)
	_box.draw_colored_polygon(tag, _speaker_col)
	# freccia "continua" che lampeggia
	if _done():
		var a: float = 0.5 + 0.5 * sin(_t * 7.0)
		var ap: Vector2 = r.end - Vector2(58, 34)
		_box.draw_colored_polygon(PackedVector2Array([ap, ap + Vector2(22, 0), ap + Vector2(11, 14)]), Color(1, 1, 1, a))


func _portrait(id: String, expr: String) -> Texture2D:
	for path in [PORTRAIT_DIR + "%s_%s.png" % [id, expr], PORTRAIT_DIR + "%s_neutro.png" % id]:
		if ResourceLoader.exists(path):
			return load(path)
	return null


func _color_of(id: String, ln: Dictionary) -> Color:
	if ln.has("col"):
		return Color(str(ln["col"]))
	var ch: Dictionary = BattleContent.CHARACTERS.get(id, {})
	return Ui.BATTLE_COLORS.get(str(ch.get("color", "")), Ui.YELLOW)


# Una riga vale se le sue condizioni sulle scelte sono vere ("se": flag fatto, "se_non": flag non fatto)
static func line_ok(ln: Dictionary) -> bool:
	if ln.has("se") and not Story.has_flag(str(ln["se"])):
		return false
	if ln.has("se_non") and Story.has_flag(str(ln["se_non"])):
		return false
	return true


func _next() -> void:
	_i += 1
	while _i < _lines.size() and not line_ok(_lines[_i]):
		_i += 1
	if _i >= _lines.size():
		_close(false)
		return
	var ln: Dictionary = _lines[_i]
	if ln.has("imposta"):
		Story.set_flag(str(ln["imposta"]))
	var id: String = str(ln.get("chi", ""))
	var expr: String = str(ln.get("espr", "neutro"))
	var tex: Texture2D = _portrait(id, expr)
	var side: String = str(ln.get("lato", ""))
	if side == "":
		side = "sx"
		for sd in _who:
			if _who[sd] == id:
				side = sd
		if not _who.values().has(id):
			side = "sx" if not _who.has("sx") else ("dx" if not _who.has("dx") else "sx")
	_speaker_side = side
	_speaker_col = _color_of(id, ln)
	var display: String = str(CastVisual.CAST.get(id, {}).get("name", id)).to_upper()
	_name.text = display
	_text.text = str(ln.get("testo", ""))
	_shown = 0.0
	_text.visible_characters = 0
	if tex != null:
		var tr: TextureRect = _pt[side]
		var entering: bool = not tr.visible or _who.get(side, "") != id
		_who[side] = id
		tr.texture = tex
		tr.visible = true
		tr.pivot_offset = tr.size * Vector2(0.5, 1.0)
		var home_x: float = -tr.size.x * 0.12 if side == "sx" else size.x - tr.size.x * 0.88
		if entering:
			tr.position.x = home_x + (-260.0 if side == "sx" else 260.0)
			tr.modulate.a = 0.0
			var tw := create_tween()
			tw.tween_property(tr, "position:x", home_x, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(tr, "modulate:a", 1.0, 0.15)
		else:
			tr.scale = Vector2(1.03, 1.03)
			create_tween().tween_property(tr, "scale", Vector2.ONE, 0.15)
	# chi parla davanti, chi ascolta scurito e piu' in basso
	for sd in _pt:
		var p: TextureRect = _pt[sd]
		if not p.visible:
			continue
		var talking: bool = sd == side and tex != null
		var col: Color = Color(1, 1, 1, p.modulate.a) if talking else Color(0.45, 0.42, 0.58, p.modulate.a)
		create_tween().tween_property(p, "self_modulate", Color(col.r, col.g, col.b, 1.0), 0.12)
		_stage.move_child(p, 2 if talking else 1)
	_layout()
	Settings.buzz(6)


func _done() -> bool:
	return _text.visible_characters < 0 or _text.visible_characters >= _text.text.length()


func advance() -> void:
	if not _active or _waiting_choice:
		return
	if not _done():
		_text.visible_characters = -1
		_maybe_choices()
	else:
		_next()


# Scelte (stile Persona): compaiono quando la riga e' scritta tutta; finche' non si sceglie non si va avanti
func _maybe_choices() -> void:
	if _i < 0 or _i >= _lines.size() or _waiting_choice:
		return
	var ln: Dictionary = _lines[_i]
	if not ln.has("scelte") or not _done():
		return
	_waiting_choice = true
	for c in _choices.get_children():
		c.queue_free()
	for opt in ln["scelte"]:
		var b := Ui.button(str(opt.get("testo", "")), Ui.CREAM, 22)
		b.custom_minimum_size.x = 640
		b.pressed.connect(_choose.bind(opt))
		_choices.add_child(b)
	_choices.visible = true


func _choose(opt: Dictionary) -> void:
	_waiting_choice = false
	_choices.visible = false
	Story.set_flag(str(opt.get("imposta", "")))
	var go: String = str(opt.get("vai", ""))
	if go != "":
		var extra: Array = DialogData.lines(go)
		var r: String = DialogData.recap(go)
		if r != "":
			_recap = r
		for k in extra.size():
			_lines.insert(_i + 1 + k, extra[k])
	Settings.buzz(15)
	_next()


# Saltando, le scelte non fatte prendono la prima opzione (e i flag delle sue righe)
func _auto_resolve_rest() -> void:
	var j: int = maxi(_i, 0)
	while j < _lines.size():
		var ln: Dictionary = _lines[j]
		if line_ok(ln):
			if ln.has("imposta"):
				Story.set_flag(str(ln["imposta"]))
			if ln.has("scelte") and (ln["scelte"] as Array).size() > 0:
				var opt: Dictionary = ln["scelte"][0]
				Story.set_flag(str(opt.get("imposta", "")))
				var go: String = str(opt.get("vai", ""))
				if go != "":
					for k2 in DialogData.lines(go):
						if (k2 as Dictionary).has("imposta"):
							Story.set_flag(str(k2["imposta"]))
					if DialogData.recap(go) != "":
						_recap = DialogData.recap(go)
		j += 1


func skip() -> void:
	if not _active:
		return
	_auto_resolve_rest()
	_waiting_choice = false
	_choices.visible = false
	_close(true)


func _close(skipped: bool) -> void:
	if not _active:
		return
	_active = false
	_stage.visible = false
	if skipped and _recap != "":
		_recap_lbl.text = "RIASSUNTO · " + _recap
		_recap_lbl.visible = true
		_recap_lbl.modulate.a = 1.0
		var tw := create_tween()
		tw.tween_interval(3.2)
		tw.tween_property(_recap_lbl, "modulate:a", 0.0, 0.4)
		tw.tween_callback(func() -> void: _recap_lbl.visible = false)
	# differito: chi chiama fa play() e poi "await finished". Una scena senza righe (testo mancante nei dati)
	# si chiude dentro play(), prima dell'await: col segnale immediato si restava bloccati per sempre.
	finished.emit.call_deferred()


func _process(delta: float) -> void:
	_t += delta
	if not _active:
		return
	_shown += delta * CPS
	if _text.visible_characters >= 0:
		_text.visible_characters = int(_shown)
	if not _waiting_choice and _done():
		_maybe_choices()
	_box.queue_redraw()


func _on_gui(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = (event as InputEventKey).physical_keycode
		if k in [KEY_E, KEY_ENTER, KEY_SPACE, KEY_KP_ENTER]:
			advance()
			get_viewport().set_input_as_handled()
		elif k == KEY_ESCAPE:
			skip()
			get_viewport().set_input_as_handled()
