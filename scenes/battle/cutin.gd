class_name CutIn
extends Control

# Sequenza dell'ultimate, alla Persona: il ritratto entra di scatto su una banda
# inclinata, con linee di velocita' e il nome della mossa gigante.
# Usa la grafica `characters/<id>/cutin.png` se c'e', altrimenti il segnaposto.

const DURATION: float = 1.0

var char_id: String = ""
var move_name: String = ""
var accent: Color = BattleTheme.RD
var _t: float = 0.0
var _portrait: PortraitView
var _label: Label
var _name_label: Label
var _tex: Texture2D = null          # grafica 16:9 a tutta banda (se c'e')


static func play(parent: Node, new_char: String, new_move: String, new_accent: Color) -> float:
	var c := CutIn.new()
	c.char_id = new_char
	c.move_name = new_move
	c.accent = new_accent
	parent.add_child(c)
	return DURATION


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Snd.play("cutin")

	_tex = ArtLibrary.cutin(char_id)
	if _tex != null and float(_tex.get_width()) / maxf(1.0, float(_tex.get_height())) < 1.3:
		_tex = null              # grafica non panoramica: va nel ritratto classico
	if _tex == null:
		_portrait = PortraitView.new().setup(char_id, "cutin")
		_portrait.show_expression_text = false
		_portrait.size = Vector2(640, 720)
		_portrait.position = Vector2(-700, 10)
		add_child(_portrait)

	_name_label = BattleTheme.make_label(BattleContent.CHARACTERS.get(char_id, {}).get("name", char_id).to_upper() if BattleContent.CHARACTERS.has(char_id) else char_id.to_upper(), 30, BattleTheme.WH, true)
	_name_label.position = Vector2(560, 250) if _tex == null else Vector2(90, 410)
	_name_label.modulate.a = 0.0
	add_child(_name_label)

	_label = BattleTheme.make_label(move_name.to_upper(), 76, BattleTheme.WH, true)
	_label.position = Vector2(1400, 300) if _tex == null else Vector2(1400, 440)
	_label.add_theme_constant_override("outline_size", 16)
	add_child(_label)

	var tw: Tween = create_tween()
	tw.set_parallel(true)
	if _portrait != null:
		tw.tween_property(_portrait, "position:x", 40.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_label, "position:x", 520.0 if _tex == null else 90.0, 0.2).set_delay(0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_name_label, "modulate:a", 1.0, 0.1).set_delay(0.12)
	tw.chain().tween_interval(0.5)
	tw.chain().tween_property(self, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(queue_free)
	ComicFx.speed_lines(self, Vector2(640, 360), Color(1, 1, 1, 0.9), 0.3)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


# Rettangolo dello schermo intero nelle coordinate di questo controllo (la banda esce dal riquadro).
func _screen_rect() -> Rect2:
	var vp: Vector2 = get_viewport_rect().size
	var gp: Vector2 = global_position
	return Rect2(-gp, vp)


func _draw() -> void:
	var view: Rect2 = _screen_rect()
	var k: float = clampf(_t / 0.14, 0.0, 1.0)
	# schermo oscurato (tutto lo schermo, anche fuori dal riquadro)
	draw_rect(view, Color(0, 0, 0, 0.62 * k))
	# banda inclinata: ombra rossa, nera, filo bianco
	var slant: float = 170.0
	var wide_art: bool = _tex != null
	var y0: float = 110.0 if wide_art else 190.0
	var y1: float = 600.0 if wide_art else 530.0
	var left: float = view.position.x - 20.0
	var reach: float = left + maxf(view.size.x * k, 80.0)
	var back := PackedVector2Array([Vector2(left, y0), Vector2(reach + slant, y0 - 24.0), Vector2(reach, y1 + 10.0), Vector2(left, y1 + 30.0)])
	draw_colored_polygon(back, accent)
	var band := PackedVector2Array([Vector2(left, y0 + 16.0), Vector2(reach + slant - 30.0, y0 - 10.0), Vector2(reach - 30.0, y1 - 14.0), Vector2(left, y1 + 12.0)])
	draw_colored_polygon(band, Color(0.02, 0.03, 0.04, 0.96))
	if wide_art:
		_draw_art(band, left, reach, y0, y1)
	var edge: PackedVector2Array = PackedVector2Array([band[1], band[2]])
	draw_polyline(edge, Color.WHITE, 4.0)
	if wide_art:
		# fascia scura in basso per leggere il nome della mossa sopra la grafica
		var fade := PackedVector2Array([Vector2(left, y1 - 120.0), Vector2(reach - 30.0 + 22.0, y1 - 150.0), Vector2(reach - 30.0, y1 - 14.0), Vector2(left, y1 + 12.0)])
		draw_colored_polygon(fade, Color(0, 0, 0, 0.5))
		return
	# righe diagonali decorative
	for i in 7:
		var x: float = 520.0 + float(i) * 90.0
		draw_line(Vector2(x + 160.0, y0 + 30.0), Vector2(x, y1 - 20.0), Color(accent, 0.28), 6.0)


# La grafica riempie la banda (taglia sopra e sotto, tenendo il viso), con un lento zoom.
func _draw_art(band: PackedVector2Array, left: float, reach: float, y0: float, y1: float) -> void:
	var vw: float = _screen_rect().size.x
	var bw: float = vw + 40.0
	var bh: float = y1 - y0 + 60.0
	var tw: float = float(_tex.get_width())
	var th: float = float(_tex.get_height())
	var zoom: float = 1.0 + 0.06 * clampf(_t / DURATION, 0.0, 1.0)
	var s: float = maxf(bw / tw, bh / th) * zoom
	var iw: float = tw * s
	var ih: float = th * s
	# il viso sta a circa il 44% dell'altezza: la banda si centra li'
	var ix: float = left + (bw - iw) * 0.5
	var iy: float = (y0 - 30.0) + bh * 0.5 - ih * 0.44
	iy = clampf(iy, (y0 - 30.0) + bh - ih, y0 - 30.0)
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	for p in band:
		uvs.append(Vector2((p.x - ix) / iw, (p.y - iy) / ih).clamp(Vector2.ZERO, Vector2.ONE))
		cols.append(Color.WHITE)
	draw_polygon(band, cols, uvs, _tex)
