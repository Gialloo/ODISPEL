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
	check(controls.has_active_input(), "il controller rileva input touch attivo")

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
	check(not controls.has_active_input(), "release_all porta il controller in stato inattivo")

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

	# La pausa applicativa Android puo' arrivare prima o indipendentemente dal focus out.
	controls._stick_idx = 4
	controls._cam_idx = 5
	controls.stick = Vector2(-0.6, 0.7)
	controls.cam_drag = Vector2(-12, 28)
	controls._knob = Vector2(-25, 30)
	controls._notification(NOTIFICATION_APPLICATION_PAUSED)
	check(controls._stick_idx == -1 and controls._cam_idx == -1, "pausa applicativa libera entrambe le dita")
	check(controls.stick == Vector2.ZERO and controls.cam_drag == Vector2.ZERO, "pausa applicativa azzera movimento e camera")
	check(controls._knob == Vector2.ZERO, "pausa applicativa centra la manopola")

	# La perdita di focus della finestra desktop deve produrre lo stesso reset.
	controls._stick_idx = 6
	controls._cam_idx = 7
	controls.stick = Vector2(1.0, 1.0)
	controls.cam_drag = Vector2(9, 9)
	controls._knob = Vector2(40, 40)
	controls._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)      # costante di Node: lo script estende SceneTree
	check(controls._stick_idx == -1 and controls._cam_idx == -1, "window focus out libera entrambe le dita")
	check(controls.stick == Vector2.ZERO and controls.cam_drag == Vector2.ZERO, "window focus out azzera movimento e camera")
	check(controls._knob == Vector2.ZERO, "window focus out centra la manopola")

	TouchUi.force = false
	print("test_v3_touch_controls: " + ("OK" if fails == 0 else "%d errori" % fails))
	quit(1 if fails > 0 else 0)
