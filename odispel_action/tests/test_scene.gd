extends SceneTree

# Prova completa con la fisica vera: carica la scena principale e comanda il
# personaggio con una sequenza di intenti, come farebbe un giocatore.
# Uso: godot --headless --path odispel_action -s res://tests/test_scene.gd

var passed: int = 0
var failed: int = 0
var main: Node3D
var player: Player
var camera: FollowCamera


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


# Comandi registrati: il test cambia "current" e il personaggio lo legge.
class ScriptedInput:
	extends Node
	var current: PlayerIntent = PlayerIntent.new()

	func get_intent() -> PlayerIntent:
		var i: PlayerIntent = current
		var next := PlayerIntent.new()
		next.move = i.move
		next.jump_held = i.jump_held
		current = next   # le pressioni valgono un fotogramma solo
		return i


var input: ScriptedInput


func _initialize() -> void:
	_run()


func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	player = main.get_node("Player")
	camera = main.get_node("FollowCamera")
	input = ScriptedInput.new()
	main.add_child(input)
	player.intent_source = input

	await _frames(30)
	_check("scena: il personaggio e' a terra all'avvio", player.is_on_floor())
	_check("scena: la telecamera e' dietro e sopra", camera.camera.global_position.z > player.global_position.z + 2.0 and camera.camera.global_position.y > player.global_position.y + 1.0)

	await _test_run_and_jump()
	await _test_dodge()
	await _test_car_roof()
	await _test_ramp()
	await _test_walls()
	await _test_camera_wall()
	await _test_real_touch_events()

	print("=== RISULTATI ===")
	print("PASS: ", passed)
	print("FAIL: ", failed)
	print("TUTTI I TEST SUPERATI" if failed == 0 else "CI SONO TEST FALLITI")
	quit(1 if failed > 0 else 0)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _teleport(pos: Vector3, facing: Vector3 = Vector3.FORWARD) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player.motor.velocity = Vector3.ZERO
	player.motor.facing = facing
	player.motor.state = PlayerMotor.State.AIR
	player.reset_physics_interpolation()
	input.current = PlayerIntent.new()
	await _frames(20)


func _move(dir: Vector3, held: bool = false) -> void:
	var i := PlayerIntent.new()
	i.move = dir
	i.jump_held = held
	input.current = i


func _press_jump(dir: Vector3 = Vector3.ZERO) -> void:
	var i := PlayerIntent.new()
	i.move = dir
	i.jump_pressed = true
	i.jump_held = true
	input.current = i


func _press_dodge(dir: Vector3) -> void:
	var i := PlayerIntent.new()
	i.move = dir
	i.dodge_pressed = true
	input.current = i


func _test_run_and_jump() -> void:
	await _teleport(Vector3(0, 0.1, 6))
	var start: Vector3 = player.global_position
	_move(Vector3.LEFT)
	await _frames(60)
	var moved: float = start.distance_to(player.global_position)
	_check("corsa: in 1 s percorre 6,5-7,5 m (%.2f)" % moved, moved > 6.5 and moved < 7.5)
	_move(Vector3.ZERO)
	await _frames(15)
	_check("corsa: si ferma subito", player.motor.horizontal_speed() < 0.05)

	_press_jump()
	var top: float = 0.0
	for i in 70:
		await physics_frame
		if i > 0:
			_move(Vector3.ZERO, true)
		top = maxf(top, player.global_position.y)
	_check("salto: sale oltre 1,7 m (%.2f)" % top, top > 1.7)
	_check("salto: e' riatterrato", player.is_on_floor())


func _test_dodge() -> void:
	await _teleport(Vector3(0, 0.1, 6))
	var start: Vector3 = player.global_position
	_press_dodge(Vector3.RIGHT)
	await physics_frame
	_move(Vector3.ZERO)
	await _frames(30)
	var dx: float = player.global_position.x - start.x
	_check("schivata: sposta di 3-4,5 m (%.2f)" % dx, dx > 3.0 and dx < 4.5)
	_check("schivata: finita e di nuovo a terra", not player.motor.is_dodging() and player.is_on_floor())


func _test_car_roof() -> void:
	# auto in (-1,6; -9): tetto a 1,6 m. Si parte davanti e si salta correndo.
	await _teleport(Vector3(-1.6, 0.1, -4.0))
	_move(Vector3.FORWARD)
	await _frames(8)
	_press_jump(Vector3.FORWARD)
	await physics_frame
	_move(Vector3.FORWARD, true)
	await _frames(24)
	_move(Vector3.ZERO, true)
	await _frames(40)
	var y: float = player.global_position.y
	_check("auto: saltando si sale sul tetto (y %.2f)" % y, player.is_on_floor() and y > 1.5)


func _test_ramp() -> void:
	# la rampa sale verso est fino alla terrazza a 2,5 m
	await _teleport(Vector3(4.0, 0.1, -2.0), Vector3.RIGHT)
	_move(Vector3.RIGHT)
	await _frames(150)
	var y: float = player.global_position.y
	_check("rampa: correndo si arriva in cima (y %.2f)" % y, y > 2.4 and player.is_on_floor())


func _test_walls() -> void:
	await _teleport(Vector3(0, 0.1, 6))
	_move(Vector3.BACK)
	await _frames(180)
	_check("confini: non si esce dall'arena (z %.2f)" % player.global_position.z, player.global_position.z < TestArena.HALF)
	_press_jump(Vector3.BACK)
	await physics_frame
	_move(Vector3.BACK, true)
	await _frames(60)
	_check("confini: neanche saltando la barriera", player.global_position.z < TestArena.HALF)


func _test_camera_wall() -> void:
	# spalle al pilone in (-6, 2): la telecamera non deve finirci dentro
	await _teleport(Vector3(-6.0, 0.1, 0.4), Vector3.FORWARD)
	camera.yaw = 0.0
	camera.pitch = 0.0
	camera.snap_to_target()
	await _frames(10)
	var cam_z: float = camera.camera.global_position.z
	_check("telecamera: si avvicina davanti al pilone (z %.2f)" % cam_z, cam_z < 2.0 - 0.45)


# Tocchi veri attraverso Input: il dito spinge "su" -> avanti rispetto alla telecamera.
# Serve una finestra vera: in --headless lo schermo finto e' 64x64 e le
# coordinate dei tocchi non hanno senso. Su Linux: xvfb-run (vedi README).
func _test_real_touch_events() -> void:
	if DisplayServer.get_name() == "headless":
		print("SALTATO: tocchi veri (serve un display, non --headless)")
		return
	var source: LocalInputSource = main.get_node("LocalInputSource")
	var touch: TouchControls = main.get_node("HUD/TouchControls")
	source.set_touch_visible(true)
	camera.yaw = deg_to_rad(90.0)   # telecamera girata: avanti = -X nel mondo
	var start := Vector2(200, touch.size.y - 200)
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = start
	down.pressed = true
	Input.parse_input_event(down)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = start + Vector2(0, -TouchControls.JOY_RADIUS)
	Input.parse_input_event(drag)
	await process_frame
	await process_frame
	var move: Vector3 = source.get_intent().move
	_check("touch vero: il joystick spinge avanti rispetto alla telecamera (%s)" % move, move.distance_to(Vector3(-1, 0, 0)) < 0.05)
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = drag.position
	up.pressed = false
	Input.parse_input_event(up)
	var tap := InputEventScreenTouch.new()
	tap.index = 1
	tap.position = touch.button_center("jump")
	tap.pressed = true
	Input.parse_input_event(tap)
	await process_frame
	await process_frame
	var intent: PlayerIntent = source.get_intent()
	_check("touch vero: rilasciato il joystick si ferma", intent.move == Vector3.ZERO)
	_check("touch vero: il pulsante SALTO arriva come salto", intent.jump_pressed and intent.jump_held)
	source.set_touch_visible(false)
