extends Control
## Comandi touch: stick mobile a sinistra, trascinamento a destra per la telecamera,
## tasti grandi per il pollice destro. Multitouch con indice per ogni dito.

signal gear_pressed

var look_scale := 1.7
var _stick_id := -1
var _stick_center := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _look_id := -1
var _look_last := Vector2.ZERO
var _btn_touch := {}               # indice dito -> nome tasto
var _font: Font

const STICK_R := 95.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = load("res://assets/fonts/ArchivoBlack-Regular.ttf")

func _buttons() -> Dictionary:
	var s := size
	return {
		"attack": {"pos": Vector2(s.x - 165, s.y - 150), "r": 82.0, "label": "ATTACCO", "col": Color(0.35, 0.95, 1.0)},
		"dodge": {"pos": Vector2(s.x - 330, s.y - 92), "r": 58.0, "label": "SCHIVA", "col": Color(1, 1, 1)},
		"jump": {"pos": Vector2(s.x - 92, s.y - 305), "r": 56.0, "label": "SALTO", "col": Color(1, 1, 1)},
		"lock": {"pos": Vector2(s.x - 290, s.y - 255), "r": 42.0, "label": "LOCK", "col": Color(1, 0.85, 0.3)},
	}

func _gear_rect() -> Rect2:
	return Rect2(Vector2(size.x - 86, 14), Vector2(70, 60))

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		if event.pressed:
			if _gear_rect().has_point(p):
				gear_pressed.emit()
				return
			for n in _buttons():
				var b: Dictionary = _buttons()[n]
				if p.distance_to(b.pos) <= b.r * 1.15:
					_btn_touch[event.index] = n
					Pad.press(n)
					queue_redraw()
					return
			if p.x < size.x * 0.42 and _stick_id == -1:
				_stick_id = event.index
				_stick_center = p
				_stick_pos = p
			elif _look_id == -1:
				_look_id = event.index
				_look_last = p
			queue_redraw()
		else:
			if _btn_touch.has(event.index):
				Pad.release(_btn_touch[event.index])
				_btn_touch.erase(event.index)
			if event.index == _stick_id:
				_stick_id = -1
				Pad.move = Vector2.ZERO
			if event.index == _look_id:
				_look_id = -1
			queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == _stick_id:
			_stick_pos = event.position
			var v: Vector2 = (_stick_pos - _stick_center)
			if v.length() > STICK_R:
				# lo stick segue il dito: niente pollice "fuori corsa"
				_stick_center = _stick_pos - v.normalized() * STICK_R
				v = v.normalized() * STICK_R
			var m := v / STICK_R
			Pad.move = Vector2(m.x, -m.y)
			queue_redraw()
		elif event.index == _look_id:
			Pad.look += (event.position - _look_last) * look_scale
			_look_last = event.position

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		for i in _btn_touch:
			Pad.release(_btn_touch[i])
		_btn_touch.clear()
		_stick_id = -1
		_look_id = -1
		Pad.move = Vector2.ZERO

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	# stick
	if _stick_id != -1:
		draw_circle(_stick_center, STICK_R, Color(1, 1, 1, 0.08))
		draw_arc(_stick_center, STICK_R, 0, TAU, 40, Color(1, 1, 1, 0.3), 3.0)
		var knob := _stick_center + (_stick_pos - _stick_center).limit_length(STICK_R)
		draw_circle(knob, 42, Color(1, 1, 1, 0.35))
	else:
		var c := Vector2(170, size.y - 160)
		draw_arc(c, STICK_R, 0, TAU, 40, Color(1, 1, 1, 0.12), 3.0)
	# tasti
	var held := {}
	for i in _btn_touch:
		held[_btn_touch[i]] = true
	for n in _buttons():
		var b: Dictionary = _buttons()[n]
		var on: bool = held.has(n) or Pad.held(n)
		var col: Color = b.col
		draw_circle(b.pos, b.r, Color(col, 0.32 if on else 0.14))
		draw_arc(b.pos, b.r, 0, TAU, 40, Color(col, 0.9 if on else 0.55), 4.0 if on else 3.0)
		var fs := 22 if b.r > 70 else 17
		var w := _font.get_string_size(b.label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		draw_string(_font, b.pos + Vector2(-w * 0.5, fs * 0.35), b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.9))
	# ingranaggio del laboratorio
	var g := _gear_rect()
	draw_rect(g, Color(0, 0, 0, 0.35))
	var gw := _font.get_string_size("LAB", HORIZONTAL_ALIGNMENT_CENTER, -1, 20).x
	draw_string(_font, g.get_center() + Vector2(-gw * 0.5, 8), "LAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.8))
