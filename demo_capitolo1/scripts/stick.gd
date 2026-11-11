extends Control
## Stick virtuale: tocca e trascina nella metà sinistra dello schermo.
## Su PC si usa la tastiera (WASD o frecce) e questo resta invisibile.

const RAGGIO := 110.0
var mondo: Node3D
var _dito := -1
var _centro := Vector2.ZERO
var _punta := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if e is InputEventScreenTouch:
		if e.pressed and _dito == -1 and e.position.x < get_viewport_rect().size.x * 0.45:
			_dito = e.index
			_centro = e.position
			_punta = e.position
		elif not e.pressed and e.index == _dito:
			_dito = -1
			mondo.input_stick = Vector2.ZERO
		queue_redraw()
	elif e is InputEventScreenDrag and e.index == _dito:
		var d: Vector2 = e.position - _centro
		if d.length() > RAGGIO:
			d = d.normalized() * RAGGIO
		_punta = _centro + d
		mondo.input_stick = d / RAGGIO
		queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_VISIBILITY_CHANGED:
		_dito = -1
		if mondo:
			mondo.input_stick = Vector2.ZERO
		queue_redraw()

func _draw() -> void:
	if _dito == -1:
		return
	draw_circle(_centro, RAGGIO, Color(1, 1, 1, 0.08))
	draw_arc(_centro, RAGGIO, 0, TAU, 48, Color(1, 1, 1, 0.5), 3.0)
	draw_circle(_punta, 46, Color(0.24, 1.0, 0.54, 0.75))
