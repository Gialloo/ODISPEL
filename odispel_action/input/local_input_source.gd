class_name LocalInputSource
extends Node

# Comandi del giocatore su questo dispositivo: tastiera, mouse, controller e
# touch. Li trasforma in un PlayerIntent per il personaggio e ruota la
# telecamera. In cooperativa il personaggio di un altro giocatore ricevera'
# l'intento dalla rete invece che da qui.
#
# PC: il primo clic cattura il mouse per la telecamera, Esc lo libera.
# F1 mostra/nasconde i comandi touch (sul PC si provano col mouse).

@export var mouse_sensitivity: float = 0.0025      # radianti per pixel
@export var stick_camera_speed: float = 3.0        # radianti al secondo
@export var touch_camera_sensitivity: float = 0.006

var camera: FollowCamera = null
var touch: TouchControls = null


func _ready() -> void:
	InputBindings.ensure()


func setup(follow_camera: FollowCamera, touch_controls: TouchControls) -> void:
	camera = follow_camera
	touch = touch_controls
	set_touch_visible(DisplayServer.is_touchscreen_available() or OS.has_feature("mobile"))


func set_touch_visible(on: bool) -> void:
	touch.visible = on
	touch.reset()
	# Sul PC, con i comandi touch visibili, il mouse simula le dita.
	if not OS.has_feature("mobile"):
		Input.emulate_touch_from_mouse = on
	if on:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func get_intent() -> PlayerIntent:
	var intent := PlayerIntent.new()
	var raw: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var touch_on: bool = touch != null and touch.visible
	if touch_on and touch.move_vector().length() > raw.length():
		raw = touch.move_vector()
	if camera != null:
		var basis: Basis = camera.yaw_basis()
		intent.move = (basis.x * raw.x + basis.z * raw.y).limit_length(1.0)
	else:
		intent.move = Vector3(raw.x, 0.0, raw.y).limit_length(1.0)
	intent.jump_pressed = Input.is_action_just_pressed("jump")
	intent.jump_held = Input.is_action_pressed("jump")
	intent.dodge_pressed = Input.is_action_just_pressed("dodge")
	if touch_on:
		intent.jump_pressed = touch.consume_press("jump") or intent.jump_pressed
		intent.jump_held = intent.jump_held or touch.is_held("jump")
		intent.dodge_pressed = touch.consume_press("dodge") or intent.dodge_pressed
	return intent


func _process(delta: float) -> void:
	if camera == null:
		return
	var stick: Vector2 = Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
	camera.rotate_view(-stick.x * stick_camera_speed * delta, -stick.y * stick_camera_speed * delta)
	if touch != null and touch.visible:
		var drag: Vector2 = touch.take_camera_delta()
		camera.rotate_view(-drag.x * touch_camera_sensitivity, -drag.y * touch_camera_sensitivity)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_touch") and touch != null:
		set_touch_visible(not touch.visible)
		return
	# Gli eventi mouse "finti" generati dal touch non devono catturare il mouse.
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var touch_on: bool = touch != null and touch.visible
	if event is InputEventMouseButton and event.pressed and not touch_on:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and camera != null:
		camera.rotate_view(-event.relative.x * mouse_sensitivity, -event.relative.y * mouse_sensitivity)
