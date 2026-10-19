class_name FollowCamera
extends Node3D

# Telecamera in terza persona. Segue il bersaglio con un leggero ritardo
# (piu' morbido in verticale, cosi' i salti non fanno sobbalzare la visuale)
# e un braccio a molla la avvicina quando c'e' un muro dietro.
# Se il giocatore non la muove per un po', si riallinea piano alle spalle
# del personaggio che corre, ma non lo fa mai quando corre verso lo schermo.
#
# Struttura: FollowCamera (punto seguito) > SpringArm3D (yaw e pitch) > Camera3D

@export var height: float = 1.5
@export var distance: float = 5.5
@export var min_pitch_deg: float = -60.0
@export var max_pitch_deg: float = 25.0
@export var follow_sharpness: float = 18.0
@export var vertical_sharpness: float = 7.0
@export var auto_align_delay: float = 1.2
@export var auto_align_speed: float = 1.6       # radianti al secondo
@export var auto_align_max_deg: float = 100.0

var target: Node3D = null
var yaw: float = 0.0
var pitch: float = deg_to_rad(-18.0)

var _since_manual: float = 0.0

@onready var arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	# Si muove in _process: la visuale non va interpolata come la fisica.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	arm.spring_length = distance
	arm.collision_mask = GameLayers.WORLD
	var probe := SphereShape3D.new()
	probe.radius = 0.25
	arm.shape = probe
	arm.margin = 0.1
	_apply_rotation()


# Rotazione chiesta dal giocatore (mouse, levetta, trascinamento touch).
func rotate_view(yaw_delta: float, pitch_delta: float) -> void:
	if is_zero_approx(yaw_delta) and is_zero_approx(pitch_delta):
		return
	yaw = wrapf(yaw + yaw_delta, -PI, PI)
	pitch = clampf(pitch + pitch_delta, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	_since_manual = 0.0


# Orientamento orizzontale della visuale: serve a trasformare
# "avanti/indietro/destra/sinistra" in una direzione nel mondo.
func yaw_basis() -> Basis:
	return Basis(Vector3.UP, yaw)


func snap_to_target() -> void:
	if target == null:
		return
	global_position = _follow_point()
	if "motor" in target:
		var f: Vector3 = target.motor.facing
		yaw = atan2(-f.x, -f.z)
	_apply_rotation()


func _process(delta: float) -> void:
	if target == null:
		return
	var goal: Vector3 = _follow_point()
	var p: Vector3 = global_position
	var kh: float = 1.0 - exp(-follow_sharpness * delta)
	var kv: float = 1.0 - exp(-vertical_sharpness * delta)
	p.x = lerpf(p.x, goal.x, kh)
	p.z = lerpf(p.z, goal.z, kh)
	p.y = lerpf(p.y, goal.y, kv)
	global_position = p
	_auto_align(delta)
	_apply_rotation()


func _follow_point() -> Vector3:
	return target.get_global_transform_interpolated().origin + Vector3(0.0, height, 0.0)


func _auto_align(delta: float) -> void:
	_since_manual += delta
	if _since_manual < auto_align_delay or not ("velocity" in target):
		return
	var v: Vector3 = target.velocity
	v.y = 0.0
	if v.length() < 2.0:
		return
	var desired: float = atan2(-v.x, -v.z)
	var diff: float = angle_difference(yaw, desired)
	if absf(diff) > deg_to_rad(auto_align_max_deg):
		return
	yaw = rotate_toward(yaw, desired, auto_align_speed * delta)


func _apply_rotation() -> void:
	arm.rotation = Vector3(pitch, yaw, 0.0)
