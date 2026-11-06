extends SceneTree

# Test automatici dello stick, del trascinamento camera e del reset multitouch.
var fails: int = 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	TouchUi.force = true
	var controls := TouchControls.new()
	root.add_child(controls)
	controls.size = Vector2(1280, 720)

	var left := InputEventScreenTouch.new()
	left.index = 0
	left.position = Vector2(200, 400)
	left.pressed = true
	check(controls.handle(left), "il dito sinistro attiva lo stick")
	check(controls._stick_idx == 0, "indice del dito stick registrato")

	var right := InputEventScreenTouch.new()
	right.index = 1
	right.position = Vector2(900, 400)
	right.pressed = true
	check(controls.handle(right), "il dito destro attiva la camera")
	check(controls._cam_idx == 1, "indice del dito camera registrato")

	var move_stick := InputEventScreenDrag.new()
	move_stick.index = 0
	move_stick.position = Vector2(240, 400)
	check(controls.handle(move_stick), "il trascinamento sinistro aggiorna lo stick")
	check(controls.stick.x > 0.0, "lo stick segnala movimento verso destra")

	var move_camera := InputEventScreenDrag.new()
	move_camera.index = 1
	move_camera.position = Vector2(930, 420)
	check(controls.handle(move_camera), "il trascinamento destro aggiorna la camera")
	check(controls.take_cam_drag() == Vector2(30, 20), "delta camera corretto")

	controls.release_all()
	check(controls._stick_idx == -1 and controls._cam_idx == -1, "release_all libera entrambe le dita")
	check(controls.stick == Vector2.ZERO and controls.cam_drag == Vector2.ZERO, "release_all azzera movimento e camera")
	check(controls._knob == Vector2.ZERO, "release_all centra la manopola")

	# Anche una perdita di focus deve liberare i tocchi se il sistema operativo
	# non invia i normali eventi di rilascio.
	controls._stick_idx = 2
	controls._cam_idx = 3
	controls.stick = Vector2(0.8, -0.4)
	controls.cam_drag = Vector2(45, -20)
	controls._knob = Vector2(30, -15)
	controls._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(controls._stick_idx == -1 and controls._cam_idx == -1, "focus out libera entrambe le dita")
	check(controls.stick == Vector2.ZERO and controls.cam_drag == Vector2.ZERO, "focus out azzera movimento e camera")
	check(controls._knob == Vector2.ZERO, "focus out centra la manopola")

	TouchUi.force = false
	print("test_v3_touch_controls: " + ("OK" if fails == 0 else "%d errori" % fails))
	quit(1 if fails > 0 else 0)
