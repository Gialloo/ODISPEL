class_name TouchControls
extends Control

# Comandi touch per smartphone, con piu' dita insieme:
#   - meta' sinistra: joystick "mobile" (nasce dove appoggi il pollice e lo segue);
#   - meta' destra: trascinare ruota la telecamera;
#   - pulsanti in basso a destra (SALTO, SCHIVA), con un'area di tocco un po'
#     piu' larga del disegno per non mancarli.
# Le dimensioni sono in unita' della risoluzione base (720 di altezza): su un
# telefono da 6" un pulsante di raggio 64 e' largo circa 11 mm, 13 mm con
# l'area di tocco. Lo spazio del futuro pulsante ATTACCO (angolo in basso a
# destra, ATTACK_SLOT) resta libero: i pulsanti non lo invadono.

const JOY_ZONE: float = 0.42          # parte sinistra dello schermo per il joystick
const JOY_RADIUS: float = 110.0
const JOY_DEADZONE: float = 0.12
const HIT_SCALE: float = 1.2

# Posizione rispetto all'angolo in basso a destra, raggio, etichetta.
const BUTTONS: Dictionary = {
	"jump": {"offset": Vector2(-160.0, -350.0), "radius": 64.0, "label": "SALTO"},
	"dodge": {"offset": Vector2(-350.0, -160.0), "radius": 64.0, "label": "SCHIVA"},
}
const ATTACK_SLOT: Dictionary = {"offset": Vector2(-160.0, -160.0), "radius": 84.0}

var _joy_finger: int = -1
var _joy_center: Vector2 = Vector2.ZERO
var _joy_finger_pos: Vector2 = Vector2.ZERO
var _joy_vector: Vector2 = Vector2.ZERO
var _cam_finger: int = -1
var _cam_last: Vector2 = Vector2.ZERO
var _cam_delta: Vector2 = Vector2.ZERO
var _button_fingers: Dictionary = {}   # dito -> pulsante
var _queued: Dictionary = {}           # pulsante -> premuto e non ancora letto


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var local: InputEventScreenTouch = make_input_local(event)
		handle_touch(local.index, local.position, local.pressed)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var local_drag: InputEventScreenDrag = make_input_local(event)
		handle_drag(local_drag.index, local_drag.position)
		get_viewport().set_input_as_handled()


# ---------- Logica (chiamata anche dai test) ----------

func handle_touch(finger: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		var button: String = button_at(pos)
		if button != "":
			_button_fingers[finger] = button
			_queued[button] = true
		elif pos.x < size.x * JOY_ZONE and _joy_finger == -1:
			_joy_finger = finger
			_joy_center = pos
			_joy_finger_pos = pos
			_joy_vector = Vector2.ZERO
		elif pos.x >= size.x * JOY_ZONE and _cam_finger == -1:
			_cam_finger = finger
			_cam_last = pos
	else:
		_release(finger)
	queue_redraw()


func handle_drag(finger: int, pos: Vector2) -> void:
	if finger == _joy_finger:
		_joy_finger_pos = pos
		var offset: Vector2 = pos - _joy_center
		if offset.length() > JOY_RADIUS:
			# il centro segue il dito: non si "perde" mai il joystick
			_joy_center = pos - offset.normalized() * JOY_RADIUS
			offset = pos - _joy_center
		var v: Vector2 = offset / JOY_RADIUS
		_joy_vector = Vector2.ZERO if v.length() < JOY_DEADZONE else v.limit_length(1.0)
		queue_redraw()
	elif finger == _cam_finger:
		_cam_delta += pos - _cam_last
		_cam_last = pos


func _release(finger: int) -> void:
	if finger == _joy_finger:
		_joy_finger = -1
		_joy_vector = Vector2.ZERO
	if finger == _cam_finger:
		_cam_finger = -1
	_button_fingers.erase(finger)


# Rilascia tutto (es. quando i comandi vengono nascosti).
func reset() -> void:
	_joy_finger = -1
	_joy_vector = Vector2.ZERO
	_cam_finger = -1
	_cam_delta = Vector2.ZERO
	_button_fingers.clear()
	_queued.clear()
	queue_redraw()


func button_center(id: String) -> Vector2:
	return size + Vector2(BUTTONS[id]["offset"])


func button_at(pos: Vector2) -> String:
	for id in BUTTONS:
		if pos.distance_to(button_center(id)) <= float(BUTTONS[id]["radius"]) * HIT_SCALE:
			return id
	return ""


# Direzione del joystick: x destra, y negativa = avanti (come Input.get_vector).
func move_vector() -> Vector2:
	return _joy_vector


func is_held(id: String) -> bool:
	return _button_fingers.values().has(id)


# Vero una volta sola per ogni pressione.
func consume_press(id: String) -> bool:
	if _queued.get(id, false):
		_queued.erase(id)
		return true
	return false


func take_camera_delta() -> Vector2:
	var d: Vector2 = _cam_delta
	_cam_delta = Vector2.ZERO
	return d


# ---------- Disegno ----------

func _draw() -> void:
	# joystick: anello e pomello; se non usato, un suggerimento tenue
	if _joy_finger != -1:
		draw_circle(_joy_center, JOY_RADIUS, Color(ActionTheme.PANEL, 0.35))
		draw_arc(_joy_center, JOY_RADIUS, 0.0, TAU, 48, Color(ActionTheme.CY, 0.6), 3.0)
		draw_circle(_joy_center + _joy_vector * JOY_RADIUS, 42.0, Color(ActionTheme.CY, 0.85))
	else:
		var hint: Vector2 = Vector2(210.0, size.y - 190.0)
		draw_arc(hint, JOY_RADIUS, 0.0, TAU, 48, Color(ActionTheme.CY, 0.18), 2.0)
		draw_circle(hint, 42.0, Color(ActionTheme.CY, 0.12))

	for id in BUTTONS:
		var c: Vector2 = button_center(id)
		var r: float = float(BUTTONS[id]["radius"])
		var held: bool = is_held(id)
		draw_circle(c, r, Color(ActionTheme.RD, 0.85) if held else Color(ActionTheme.PANEL, 0.55))
		draw_arc(c, r, 0.0, TAU, 48, ActionTheme.WH if held else ActionTheme.CY, 3.0)
		var label: String = str(BUTTONS[id]["label"])
		var font: Font = ActionTheme.display()
		var fs: int = 22
		var w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, c + Vector2(-w * 0.5, fs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ActionTheme.WH if held else ActionTheme.CY)
