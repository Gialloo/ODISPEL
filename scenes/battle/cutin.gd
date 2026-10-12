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

	_portrait = PortraitView.new().setup(char_id, "cutin")
	_portrait.show_expression_text = false
	_portrait.size = Vector2(560, 700)
	_portrait.position = Vector2(-620, 20)
	add_child(_portrait)

	_name_label = BattleTheme.make_label(BattleContent.CHARACTERS.get(char_id, {}).get("name", char_id).to_upper() if BattleContent.CHARACTERS.has(char_id) else char_id.to_upper(), 30, BattleTheme.WH, true)
	_name_label.position = Vector2(560, 250)
	_name_label.modulate.a = 0.0
	add_child(_name_label)

	_label = BattleTheme.make_label(move_name.to_upper(), 76, BattleTheme.WH, true)
	_label.position = Vector2(1400, 300)
	_label.add_theme_constant_override("outline_size", 16)
	add_child(_label)

	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_portrait, "position:x", 50.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_label, "position:x", 520.0, 0.2).set_delay(0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_name_label, "modulate:a", 1.0, 0.1).set_delay(0.12)
	tw.chain().tween_interval(0.5)
	tw.chain().tween_property(self, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(queue_free)
	ComicFx.speed_lines(self, Vector2(640, 360), Color(1, 1, 1, 0.9), 0.3)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var view: Vector2 = size
	var k: float = clampf(_t / 0.14, 0.0, 1.0)
	# schermo oscurato
	draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, 0.62 * k))
	# banda inclinata: ombra rossa, nera, filo bianco
	var slant: float = 170.0
	var y0: float = 190.0
	var y1: float = 530.0
	var reach: float = maxf(view.x * k, 80.0)
	var back := PackedVector2Array([Vector2(-20, y0), Vector2(reach + slant, y0 - 24.0), Vector2(reach, y1 + 10.0), Vector2(-20, y1 + 30.0)])
	draw_colored_polygon(back, accent)
	var band := PackedVector2Array([Vector2(-20, y0 + 16.0), Vector2(reach + slant - 30.0, y0 - 10.0), Vector2(reach - 30.0, y1 - 14.0), Vector2(-20, y1 + 12.0)])
	draw_colored_polygon(band, Color(0.02, 0.03, 0.04, 0.96))
	var edge: PackedVector2Array = PackedVector2Array([band[1], band[2]])
	draw_polyline(edge, Color.WHITE, 4.0)
	# righe diagonali decorative
	for i in 7:
		var x: float = 520.0 + float(i) * 90.0
		draw_line(Vector2(x + 160.0, y0 + 30.0), Vector2(x, y1 - 20.0), Color(accent, 0.28), 6.0)
