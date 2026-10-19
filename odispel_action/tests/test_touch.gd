extends SceneTree

# Test dei comandi touch: zone, joystick, pulsanti, piu' dita, dimensioni.
# Uso: godot --headless --path odispel_action -s res://tests/test_touch.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _controls(screen: Vector2) -> TouchControls:
	var t := TouchControls.new()
	t.size = screen
	return t


func _init() -> void:
	_test_joystick()
	_test_camera_and_buttons()
	_test_multitouch()
	for screen in [Vector2(1280, 720), Vector2(1600, 720), Vector2(960, 720), Vector2(1280, 1024)]:
		_test_layout(screen)
	print("=== RISULTATI ===")
	print("PASS: ", passed)
	print("FAIL: ", failed)
	print("TUTTI I TEST SUPERATI" if failed == 0 else "CI SONO TEST FALLITI")
	quit(1 if failed > 0 else 0)


func _test_joystick() -> void:
	var t := _controls(Vector2(1280, 720))
	t.handle_touch(0, Vector2(200, 500), true)
	_check("joystick: appena toccato e' fermo", t.move_vector() == Vector2.ZERO)
	t.handle_drag(0, Vector2(200, 500 - TouchControls.JOY_RADIUS))
	_check("joystick: su = avanti (y negativa)", t.move_vector().is_equal_approx(Vector2(0, -1)))
	t.handle_drag(0, Vector2(200 + TouchControls.JOY_RADIUS * 0.5, 500))
	_check("joystick: a meta' corsa vale 0,5", t.move_vector().is_equal_approx(Vector2(0.5, 0)))
	t.handle_drag(0, Vector2(200 + 5, 500))
	_check("joystick: zona morta al centro", t.move_vector() == Vector2.ZERO)
	t.handle_drag(0, Vector2(200 + 400, 500))
	_check("joystick: oltre il bordo resta a 1", is_equal_approx(t.move_vector().length(), 1.0))
	t.handle_drag(0, Vector2(600 - TouchControls.JOY_RADIUS, 500))
	_check("joystick: il centro ha seguito il dito", t.move_vector() == Vector2.ZERO)
	t.handle_touch(0, Vector2(600, 500), false)
	_check("joystick: rilasciato torna a zero", t.move_vector() == Vector2.ZERO)
	t.free()


func _test_camera_and_buttons() -> void:
	var t := _controls(Vector2(1280, 720))
	t.handle_touch(1, Vector2(800, 200), true)
	t.handle_drag(1, Vector2(830, 190))
	t.handle_drag(1, Vector2(850, 190))
	_check("telecamera: somma i trascinamenti", t.take_camera_delta().is_equal_approx(Vector2(50, -10)))
	_check("telecamera: il valore si legge una volta", t.take_camera_delta() == Vector2.ZERO)
	_check("telecamera: non muove il personaggio", t.move_vector() == Vector2.ZERO)
	t.handle_touch(1, Vector2(850, 190), false)

	var jump: Vector2 = t.button_center("jump")
	t.handle_touch(2, jump + Vector2(10, 10), true)
	_check("pulsante: tenuto premuto", t.is_held("jump"))
	_check("pulsante: pressione letta una volta", t.consume_press("jump") and not t.consume_press("jump"))
	t.handle_drag(2, jump + Vector2(30, 0))
	_check("pulsante: trascinare sopra non muove la telecamera", t.take_camera_delta() == Vector2.ZERO)
	t.handle_touch(2, jump, false)
	_check("pulsante: rilasciato", not t.is_held("jump"))

	var r: float = float(TouchControls.BUTTONS["dodge"]["radius"])
	t.handle_touch(3, t.button_center("dodge") + Vector2(r * 1.1, 0), true)
	_check("pulsante: area di tocco piu' larga del disegno", t.consume_press("dodge"))
	t.handle_touch(3, Vector2.ZERO, false)
	t.free()


func _test_multitouch() -> void:
	var t := _controls(Vector2(1280, 720))
	t.handle_touch(0, Vector2(200, 500), true)
	t.handle_touch(1, t.button_center("jump"), true)
	t.handle_drag(0, Vector2(200, 500 - TouchControls.JOY_RADIUS))
	_check("piu' dita: si corre e si salta insieme", t.move_vector().y < -0.9 and t.is_held("jump"))
	t.handle_touch(2, Vector2(900, 150), true)
	t.handle_drag(2, Vector2(920, 150))
	_check("piu' dita: telecamera insieme a joystick e salto", t.take_camera_delta().x > 0.0 and t.move_vector().y < -0.9)
	t.handle_touch(3, Vector2(150, 300), true)
	t.handle_drag(3, Vector2(400, 300))
	_check("piu' dita: un secondo dito a sinistra non ruba il joystick", t.move_vector().y < -0.9)
	t.handle_touch(1, t.button_center("jump"), false)
	_check("piu' dita: rilasciare il salto non ferma il joystick", t.move_vector().y < -0.9 and not t.is_held("jump"))
	t.reset()
	_check("reset: tutto rilasciato", t.move_vector() == Vector2.ZERO and not t.is_held("jump"))
	t.free()


func _test_layout(screen: Vector2) -> void:
	var t := _controls(screen)
	var tag: String = "%dx%d" % [int(screen.x), int(screen.y)]
	var attack_center: Vector2 = screen + Vector2(TouchControls.ATTACK_SLOT["offset"])
	var attack_r: float = float(TouchControls.ATTACK_SLOT["radius"]) * TouchControls.HIT_SCALE
	var ids: Array = TouchControls.BUTTONS.keys()
	var ok_inside: bool = true
	var ok_attack: bool = true
	var ok_joystick: bool = true
	for id in ids:
		var c: Vector2 = t.button_center(id)
		var r: float = float(TouchControls.BUTTONS[id]["radius"]) * TouchControls.HIT_SCALE
		if c.x - r < 0 or c.y - r < 0 or c.x + r > screen.x or c.y + r > screen.y:
			ok_inside = false
		if c.distance_to(attack_center) < r + attack_r:
			ok_attack = false
		if c.x - r < screen.x * TouchControls.JOY_ZONE:
			ok_joystick = false
	_check(tag + ": pulsanti interi sullo schermo", ok_inside)
	_check(tag + ": spazio libero per il futuro ATTACCO", ok_attack)
	_check(tag + ": pulsanti lontani dalla zona del joystick", ok_joystick)
	var a: Vector2 = t.button_center(ids[0])
	var b: Vector2 = t.button_center(ids[1])
	var gap: float = a.distance_to(b) - (float(TouchControls.BUTTONS[ids[0]]["radius"]) + float(TouchControls.BUTTONS[ids[1]]["radius"])) * TouchControls.HIT_SCALE
	_check(tag + ": aree dei pulsanti separate (>= 40)", gap >= 40.0)
	_check(tag + ": pulsanti nella meta' bassa (in alto restano le informazioni)", a.y > screen.y * 0.4 and b.y > screen.y * 0.4)
	t.free()
