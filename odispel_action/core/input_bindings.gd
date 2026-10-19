class_name InputBindings
extends RefCounted

# Comandi di tastiera e controller. Si registrano dal codice solo se non
# esistono gia': chi vuole cambiarli puo' definirli in Progetto > Impostazioni
# progetto > Mappa input e questi valori verranno ignorati.
#
# Tastiera: WASD / frecce, Spazio salto, Shift schivata, mouse telecamera.
# Controller: levetta sinistra, levetta destra, A salto, B schivata.

const MOVE_DEADZONE: float = 0.2
const CAMERA_DEADZONE: float = 0.15


static func ensure() -> void:
	_action("move_left", MOVE_DEADZONE, [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_action("move_right", MOVE_DEADZONE, [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_action("move_forward", MOVE_DEADZONE, [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action("move_back", MOVE_DEADZONE, [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_action("cam_left", CAMERA_DEADZONE, [_axis(JOY_AXIS_RIGHT_X, -1.0)])
	_action("cam_right", CAMERA_DEADZONE, [_axis(JOY_AXIS_RIGHT_X, 1.0)])
	_action("cam_up", CAMERA_DEADZONE, [_axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_action("cam_down", CAMERA_DEADZONE, [_axis(JOY_AXIS_RIGHT_Y, 1.0)])
	_action("jump", 0.5, [_key(KEY_SPACE), _button(JOY_BUTTON_A)])
	_action("dodge", 0.5, [_key(KEY_SHIFT), _button(JOY_BUTTON_B)])
	_action("toggle_touch", 0.5, [_key(KEY_F1)])
	_action("toggle_debug", 0.5, [_key(KEY_F3)])


static func _action(action: StringName, deadzone: float, events: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, deadzone)
	for e in events:
		InputMap.action_add_event(action, e)


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


static func _button(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e


static func _axis(axis: JoyAxis, direction: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = direction
	return e
