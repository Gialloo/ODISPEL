extends Node3D
## Telecamera ravvicinata alle spalle: segue morbida, non entra nei muri,
## con aggancio del bersaglio che inquadra entrambi senza togliere il controllo.

var target: Node3D                # giocatore
var tune := {
	"sensitivity": 0.0045,        # radianti per pixel trascinato
	"distance": 4.7,
	"height": 2.0,
	"shoulder": 0.85,
	"follow": 14.0,
	"lock_turn": 6.0,
}

var yaw := 0.0
var pitch := -0.26
var _pivot: Node3D
var _arm: SpringArm3D
var camera: Camera3D
var _shake := 0.0
var _shake_t := 0.0
var _shake_dur := 0.0
var _fov_kick := 0.0
const BASE_FOV := 68.0

func _ready() -> void:
	top_level = true
	_pivot = Node3D.new()
	add_child(_pivot)
	_arm = SpringArm3D.new()
	_arm.spring_length = tune.distance
	_arm.margin = 0.25
	_arm.collision_mask = 1
	var sh := SphereShape3D.new()
	sh.radius = 0.25
	_arm.shape = sh
	_pivot.add_child(_arm)
	camera = Camera3D.new()
	camera.fov = BASE_FOV
	camera.near = 0.1
	camera.far = 120.0
	_arm.add_child(camera)
	camera.current = true
	FX.shake_requested.connect(_on_shake)
	if target:
		global_position = target.global_position + Vector3(0, tune.height, 0)
		_arm.add_excluded_object(target.get_rid())

func get_yaw() -> float:
	return yaw

func forward_flat() -> Vector3:
	return Vector3(-sin(yaw), 0, -cos(yaw))

func kick(deg: float) -> void:
	_fov_kick = max(_fov_kick, deg)

func _on_shake(strength: float, duration: float) -> void:
	_shake = max(_shake, strength)
	_shake_dur = duration
	_shake_t = duration

func _process(delta: float) -> void:
	# usa il tempo reale: la visuale resta reattiva anche durante hitstop e rallentamenti
	var rd: float = delta / max(Engine.time_scale, 0.01)
	rd = min(rd, 0.05)
	var look: Vector2 = Pad.take_look()
	yaw -= look.x * tune.sensitivity
	pitch = clamp(pitch - look.y * tune.sensitivity, -1.05, 0.45)
	if target:
		var lock = target.get("lock_target")
		if lock and is_instance_valid(lock) and look.length() < 2.0:
			var to: Vector3 = lock.global_position - target.global_position
			to.y = 0
			if to.length() > 0.5:
				var want := atan2(-to.x, -to.z)
				yaw = lerp_angle(yaw, want, clamp(tune.lock_turn * rd, 0, 1))
				pitch = lerp(pitch, -0.3, clamp(3.0 * rd, 0, 1))
		var goal: Vector3 = target.get_global_transform_interpolated().origin + Vector3(0, tune.height, 0)
		global_position = global_position.lerp(goal, clamp(tune.follow * rd, 0, 1))
	_pivot.rotation = Vector3(pitch, yaw, 0)
	_arm.spring_length = tune.distance
	_arm.position = Vector3(tune.shoulder, 0, 0)
	# scossa e calcio del campo visivo
	var off := Vector3.ZERO
	if _shake_t > 0:
		_shake_t -= rd
		var k: float = _shake * (_shake_t / max(_shake_dur, 0.001))
		off = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * k * 0.18
	camera.h_offset = off.x
	camera.v_offset = off.y
	_fov_kick = move_toward(_fov_kick, 0.0, 30.0 * rd)
	camera.fov = BASE_FOV + _fov_kick
