extends SceneTree

# Test del PlayerMotor senza fisica: un pavimento piatto simulato a y = 0.
# Uso: godot --headless --path odispel_action -s res://tests/test_motor.gd

const DT: float = 1.0 / 60.0

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


# Mondo minimo: posizione + pavimento a y = 0.
class Sim:
	var motor: PlayerMotor = PlayerMotor.new()
	var pos: Vector3 = Vector3.ZERO
	var on_floor: bool = true
	var ledge_x: float = INF      # oltre questa x il pavimento finisce
	var max_y: float = 0.0

	func step(intent: PlayerIntent) -> void:
		var v: Vector3 = motor.step(intent, on_floor, 1.0 / 60.0)
		pos += v / 60.0
		var floor_here: bool = pos.x < ledge_x
		if floor_here and pos.y <= 0.0 and v.y <= 0.0:
			pos.y = 0.0
			motor.velocity.y = 0.0
			on_floor = true
		else:
			on_floor = false
		max_y = maxf(max_y, pos.y)

	func run(intent: PlayerIntent, frames: int) -> void:
		for i in frames:
			step(intent)


func _intent(move: Vector3 = Vector3.ZERO, jump: bool = false, held: bool = false, dodge: bool = false) -> PlayerIntent:
	var i := PlayerIntent.new()
	i.move = move
	i.jump_pressed = jump
	i.jump_held = held
	i.dodge_pressed = dodge
	return i


func _init() -> void:
	_test_run()
	_test_turn()
	_test_jump()
	_test_jump_buffer_and_coyote()
	_test_dodge()
	print("=== RISULTATI ===")
	print("PASS: ", passed)
	print("FAIL: ", failed)
	print("TUTTI I TEST SUPERATI" if failed == 0 else "CI SONO TEST FALLITI")
	quit(1 if failed > 0 else 0)


func _test_run() -> void:
	var s := Sim.new()
	s.run(_intent(Vector3.FORWARD), 9)
	_check("corsa: velocita' piena in 0,15 s", is_equal_approx(s.motor.horizontal_speed(), s.motor.run_speed))
	s.run(_intent(), 7)
	_check("corsa: si ferma in 0,12 s", s.motor.horizontal_speed() < 0.01)

	var half := Sim.new()
	half.run(_intent(Vector3.FORWARD * 0.5), 30)
	_check("corsa: joystick a meta' = meta' velocita'", is_equal_approx(half.motor.horizontal_speed(), half.motor.run_speed * 0.5))

	var rev := Sim.new()
	rev.run(_intent(Vector3.FORWARD), 30)
	rev.run(_intent(Vector3.BACK), 10)
	_check("corsa: inversione completa in 0,17 s", rev.motor.velocity.z > rev.motor.run_speed * 0.99)

	var over := Sim.new()
	over.run(_intent(Vector3(1.0, 0.0, -1.0)), 30)
	_check("corsa: in diagonale non si va piu' veloci", over.motor.horizontal_speed() <= over.motor.run_speed + 0.001)


func _test_turn() -> void:
	var s := Sim.new()
	s.step(_intent(Vector3.RIGHT))
	var angle: float = Vector3.FORWARD.angle_to(s.motor.facing)
	_check("rotazione: limitata a turn_speed per fotogramma", angle > 0.0 and angle <= s.motor.turn_speed * DT + 0.001)
	s.run(_intent(Vector3.RIGHT), 8)
	_check("rotazione: in meno di 0,15 s guarda dove va", s.motor.facing.distance_to(Vector3.RIGHT) < 0.01)


func _test_jump() -> void:
	var s := Sim.new()
	s.step(_intent(Vector3.ZERO, true, true))
	_check("salto: parte da terra", s.motor.state == PlayerMotor.State.AIR and s.motor.velocity.y > 0.0)
	s.run(_intent(Vector3.ZERO, false, true), 5)
	var vy: float = s.motor.velocity.y
	s.step(_intent(Vector3.ZERO, true, true))
	_check("salto: niente doppio salto", s.motor.velocity.y < vy)
	s.run(_intent(Vector3.ZERO, false, true), 120)
	_check("salto pieno: tra 1,8 e 2,2 m", s.max_y > 1.8 and s.max_y < 2.2)
	_check("salto: atterra", s.on_floor and s.motor.state == PlayerMotor.State.GROUND)

	var tap := Sim.new()
	tap.step(_intent(Vector3.ZERO, true, true))
	tap.run(_intent(), 120)
	_check("salto breve: rilasciando subito si sale meno di 1 m", tap.max_y < 1.0 and tap.max_y > 0.2)

	var air := Sim.new()
	air.step(_intent(Vector3.ZERO, true, true))
	air.run(_intent(Vector3.FORWARD, false, true), 20)
	_check("salto: in aria ci si puo' ancora muovere", air.pos.z < -1.0)


func _test_jump_buffer_and_coyote() -> void:
	# salto premuto poco prima di toccare terra
	var s := Sim.new()
	s.pos.y = 0.3
	s.on_floor = false
	s.motor.state = PlayerMotor.State.AIR
	var frames := 0
	while s.pos.y > 0.05 and frames < 60:
		s.step(_intent())
		frames += 1
	s.step(_intent(Vector3.ZERO, true, true))
	var jumped: bool = false
	for i in 10:
		s.step(_intent(Vector3.ZERO, false, true))
		if s.motor.velocity.y > 5.0:
			jumped = true
	_check("buffer: il salto premuto prima dell'atterraggio parte", jumped)

	# appena caduti da un bordo si puo' ancora saltare
	var c := Sim.new()
	c.ledge_x = 0.5
	c.run(_intent(Vector3.RIGHT), 12)
	_check("coyote: e' in aria oltre il bordo", not c.on_floor)
	c.step(_intent(Vector3.RIGHT, true, true))
	_check("coyote: salto valido subito dopo il bordo", c.motor.velocity.y > 5.0)

	var late := Sim.new()
	late.ledge_x = 0.5
	late.run(_intent(Vector3.RIGHT), 12)
	late.run(_intent(Vector3.RIGHT), 12)
	late.step(_intent(Vector3.RIGHT, true, true))
	_check("coyote: troppo tardi non si salta", late.motor.velocity.y < 0.0)


func _test_dodge() -> void:
	var s := Sim.new()
	s.step(_intent(Vector3.RIGHT, false, false, true))
	_check("schivata: parte subito", s.motor.is_dodging())
	var frames := 1
	while s.motor.is_dodging() and frames < 60:
		s.step(_intent())
		frames += 1
	_check("schivata: dura circa 0,34 s", absf(float(frames) * DT - s.motor.dodge_duration) < 2.0 * DT)
	_check("schivata: percorre da 3 a 4,5 m", s.pos.x > 3.0 and s.pos.x < 4.5)
	_check("schivata: si gira nella direzione della schivata", s.motor.facing.distance_to(Vector3.RIGHT) < 0.01)

	s.step(_intent(Vector3.RIGHT, false, false, true))
	_check("schivata: ricarica, non si ripete subito", not s.motor.is_dodging())
	var started: bool = false
	for i in 20:
		s.step(_intent(Vector3.RIGHT, false, false, i % 4 == 0))
		if s.motor.is_dodging():
			started = true
	_check("schivata: dopo la ricarica funziona di nuovo", started)

	var still := Sim.new()
	still.step(_intent(Vector3.ZERO, false, false, true))
	still.run(_intent(), 30)
	_check("schivata da fermi: va dove guarda", still.pos.z < -3.0)

	var air := Sim.new()
	air.step(_intent(Vector3.ZERO, true, true))
	air.run(_intent(Vector3.ZERO, false, true), 5)
	air.step(_intent(Vector3.RIGHT, false, true, true))
	air.run(_intent(Vector3.ZERO, false, true), 3)
	_check("schivata: non in aria", not air.motor.is_dodging())

	# salto premuto alla fine della schivata: parte appena finisce
	var chain := Sim.new()
	chain.step(_intent(Vector3.FORWARD, false, false, true))
	chain.run(_intent(Vector3.FORWARD), 15)
	chain.step(_intent(Vector3.FORWARD, true, true))
	var jumped: bool = false
	for i in 10:
		chain.step(_intent(Vector3.FORWARD, false, true))
		if chain.motor.velocity.y > 5.0:
			jumped = true
	_check("schivata -> salto: il salto prenotato parte", jumped)
