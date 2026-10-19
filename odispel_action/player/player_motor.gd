class_name PlayerMotor
extends RefCounted

# Regole di movimento del personaggio: corsa, salto e schivata.
# Lavora solo su numeri (nessun nodo): si prova nei test e in futuro lo stesso
# calcolo potra' girare sull'host per controllare i movimenti in cooperativa.
# Il nodo Player gli passa l'intento e il contatto col pavimento, poi applica
# la velocita' con move_and_slide e gliela restituisce dopo gli urti.

signal jumped
signal landed
signal dodge_started

enum State { GROUND, AIR, DODGE }

# ---------- Regolazioni (metri e secondi) ----------

var run_speed: float = 7.5
var ground_accel: float = 70.0
var ground_decel: float = 80.0
var reverse_boost: float = 2.0       # cambiare verso a terra e' piu' rapido
var air_accel: float = 28.0
var air_decel: float = 4.0           # in aria si conserva lo slancio
var turn_speed: float = 20.0         # radianti al secondo
var gravity: float = 30.0
var fall_gravity: float = 44.0       # si scende piu' in fretta di come si sale
var max_fall_speed: float = 32.0
var jump_velocity: float = 11.0      # circa 2 m di altezza tenendo premuto
var jump_cut: float = 0.45           # rilasciando presto si salta meno in alto
var coyote_time: float = 0.1         # si puo' saltare poco dopo aver perso il bordo
var jump_buffer_time: float = 0.12   # un salto premuto poco prima di atterrare vale
var dodge_duration: float = 0.34
var dodge_start_speed: float = 15.0
var dodge_end_speed: float = 6.0
var dodge_cooldown: float = 0.2
var dodge_buffer_time: float = 0.12

# ---------- Stato ----------

var state: State = State.GROUND
var velocity: Vector3 = Vector3.ZERO
var facing: Vector3 = Vector3.FORWARD

var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _dodge_buffer_left: float = 0.0
var _dodge_left: float = 0.0
var _dodge_cooldown_left: float = 0.0
var _dodge_dir: Vector3 = Vector3.FORWARD
var _jump_rising: bool = false


func is_dodging() -> bool:
	return state == State.DODGE


# Da 0 a 1 durante la schivata (per l'animazione), 0 altrimenti.
func dodge_progress() -> float:
	if state != State.DODGE:
		return 0.0
	return clampf(1.0 - _dodge_left / dodge_duration, 0.0, 1.0)


func horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


# Calcola la velocita' per questo fotogramma.
func step(intent: PlayerIntent, on_floor: bool, delta: float) -> Vector3:
	if intent.jump_pressed:
		_jump_buffer_left = jump_buffer_time
	if intent.dodge_pressed:
		_dodge_buffer_left = dodge_buffer_time
	_dodge_cooldown_left = maxf(0.0, _dodge_cooldown_left - delta)

	if state == State.DODGE:
		_step_dodge(on_floor, delta)
	else:
		_update_ground(on_floor, delta)
		if _dodge_buffer_left > 0.0 and state == State.GROUND and _dodge_cooldown_left <= 0.0:
			_start_dodge(intent)
			_step_dodge(on_floor, delta)
		else:
			_step_run(intent, delta)
			_step_jump(intent)
			_step_gravity(delta)

	_jump_buffer_left = maxf(0.0, _jump_buffer_left - delta)
	_dodge_buffer_left = maxf(0.0, _dodge_buffer_left - delta)
	return velocity


func _update_ground(on_floor: bool, delta: float) -> void:
	if on_floor:
		if state == State.AIR and velocity.y <= 0.0:
			state = State.GROUND
			_jump_rising = false
			landed.emit()
		if state == State.GROUND:
			_coyote_left = coyote_time
	else:
		if state == State.GROUND:
			state = State.AIR
		_coyote_left = maxf(0.0, _coyote_left - delta)


func _step_run(intent: PlayerIntent, delta: float) -> void:
	var wish: Vector3 = Vector3(intent.move.x, 0.0, intent.move.z)
	if wish.length() > 1.0:
		wish = wish.normalized()
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var moving: bool = wish.length_squared() > 0.0001
	var accel: float
	if state == State.GROUND:
		accel = ground_accel if moving else ground_decel
		if moving and horizontal.dot(wish) < 0.0:
			accel *= reverse_boost
	else:
		accel = air_accel if moving else air_decel
	horizontal = horizontal.move_toward(wish * run_speed, accel * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if moving:
		_turn_toward(wish.normalized(), delta)


func _turn_toward(direction: Vector3, delta: float) -> void:
	var angle: float = facing.signed_angle_to(direction, Vector3.UP)
	var max_step: float = turn_speed * delta
	facing = facing.rotated(Vector3.UP, clampf(angle, -max_step, max_step)).normalized()


func _step_jump(intent: PlayerIntent) -> void:
	var can_jump: bool = state == State.GROUND or (_coyote_left > 0.0 and not _jump_rising)
	if _jump_buffer_left > 0.0 and can_jump:
		velocity.y = jump_velocity
		state = State.AIR
		_jump_rising = true
		_coyote_left = 0.0
		_jump_buffer_left = 0.0
		jumped.emit()
	elif _jump_rising and velocity.y > 0.0 and not intent.jump_held:
		velocity.y *= jump_cut
		_jump_rising = false
	if velocity.y <= 0.0:
		_jump_rising = false


func _step_gravity(delta: float) -> void:
	if state == State.AIR:
		var g: float = gravity if velocity.y > 0.0 else fall_gravity
		velocity.y = maxf(velocity.y - g * delta, -max_fall_speed)
	else:
		velocity.y = 0.0


func _start_dodge(intent: PlayerIntent) -> void:
	var direction: Vector3 = Vector3(intent.move.x, 0.0, intent.move.z)
	_dodge_dir = direction.normalized() if direction.length_squared() > 0.01 else facing
	facing = _dodge_dir
	state = State.DODGE
	_dodge_left = dodge_duration
	_dodge_buffer_left = 0.0
	_jump_rising = false
	dodge_started.emit()


func _step_dodge(on_floor: bool, delta: float) -> void:
	var t: float = 1.0 - _dodge_left / dodge_duration
	var speed: float = lerpf(dodge_start_speed, dodge_end_speed, t)
	velocity.x = _dodge_dir.x * speed
	velocity.z = _dodge_dir.z * speed
	if on_floor:
		velocity.y = 0.0
	else:
		velocity.y = maxf(velocity.y - fall_gravity * delta, -max_fall_speed)
	_dodge_left -= delta
	if _dodge_left <= 0.0:
		state = State.GROUND if on_floor else State.AIR
		_dodge_cooldown_left = dodge_cooldown
		_coyote_left = coyote_time if on_floor else 0.0
