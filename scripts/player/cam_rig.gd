extends Node3D
## Telecamera ravvicinata alle spalle: segue morbida, non entra nei muri,
## con aggancio del bersaglio che inquadra entrambi senza togliere il controllo.

var target: Node3D                # giocatore
var tune := {
	"sensitivity": 0.0045,        # radianti per pixel trascinato
	"distance": 4.7,
	"height": 2.0,
	"shoulder": 0.85,
	"follow": 20.0,               # 0.9: più stretto, e il ritardo massimo è limitato (max_lag)
	"follow_y": 9.0,              # in verticale più morbido: i salti non fanno ballare la visuale
	"max_lag": 0.8,
	"lock_turn": 7.0,
	"look_smooth": 28.0,          # il trascinamento si spalma su pochi frame: scorre liscio anche a scatti
	"auto_turn": 1.3,             # visuale libera: si gira piano dietro al personaggio quando corri di lato
	"flick": 70.0,                # pixel trascinati in aggancio per passare al bersaglio accanto
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
var _look_buf := Vector2.ZERO
var _idle_look := 0.0
var _flick := 0.0
var _flick_cd := 0.0
var _was_locked := false

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
	strength *= float(Run.opt.get("shake", 1.0))
	_shake = max(_shake, strength)
	_shake_dur = duration
	_shake_t = duration

func _process(delta: float) -> void:
	# usa il tempo reale: la visuale resta reattiva anche durante hitstop e rallentamenti
	var rd: float = delta / max(Engine.time_scale, 0.01)
	rd = min(rd, 0.05)
	var opt: Dictionary = Run.opt
	_look_buf += Pad.take_look()
	var take: Vector2 = _look_buf * clamp(1.0 - exp(-tune.look_smooth * rd), 0.0, 1.0)
	if _look_buf.length() < 0.5:
		take = _look_buf
	_look_buf -= take
	var sens: float = tune.sensitivity * float(opt.get("look", 1.0))
	_flick_cd = max(0.0, _flick_cd - rd)
	var lock = target.get("lock_target") if target else null
	var locked: bool = lock != null and is_instance_valid(lock)
	if locked:
		# in aggancio il trascinamento orizzontale non combatte la visuale: un colpo di dito
		# passa al nemico accanto; il verticale resta libero
		pitch = clamp(pitch - take.y * sens * 0.6, -1.05, 0.45)
		_flick += take.x
		if absf(_flick) > tune.flick and _flick_cd <= 0.0 and target.has_method("switch_lock"):
			target.switch_lock(signf(_flick))
			_flick = 0.0
			_flick_cd = 0.3
		_flick = move_toward(_flick, 0.0, 120.0 * rd)
	else:
		_flick = 0.0
		yaw -= take.x * sens
		pitch = clamp(pitch - take.y * sens, -1.05, 0.45)
	_idle_look = 0.0 if take.length() > 0.3 else _idle_look + rd
	if target:
		if locked:
			var to: Vector3 = lock.global_position - target.global_position
			to.y = 0
			if to.length() > 0.5:
				var want := atan2(-to.x, -to.z)
				# appena agganciato gira più deciso, poi segue morbido
				var k: float = tune.lock_turn * (1.6 if not _was_locked else 1.0)
				yaw = lerp_angle(yaw, want, clamp(1.0 - exp(-k * rd), 0, 1))
				if _idle_look > 0.4:
					pitch = lerp(pitch, -0.3, clamp(3.0 * rd, 0, 1))
		elif opt.get("auto_cam", true) and _idle_look > 0.7:
			# visuale libera: quando corri di lato la camera si rimette piano alle tue spalle
			var v: Vector3 = target.velocity
			v.y = 0
			var sp := v.length()
			if sp > 3.0:
				var want := atan2(-v.x, -v.z)
				var diff := angle_difference(yaw, want)
				if absf(diff) < 2.5:
					var rate: float = tune.auto_turn * absf(sin(diff)) * clamp(sp / 8.0, 0.0, 1.2)
					yaw += clamp(diff, -rate * rd, rate * rd)
		_was_locked = locked
		var goal: Vector3 = target.get_global_transform_interpolated().origin + Vector3(0, tune.height, 0)
		var cur := global_position
		var kh: float = clamp(1.0 - exp(-tune.follow * rd), 0, 1)
		var kv: float = clamp(1.0 - exp(-tune.follow_y * rd), 0, 1)
		var h := Vector2(cur.x, cur.z).lerp(Vector2(goal.x, goal.z), kh)
		var gh := Vector2(goal.x, goal.z)
		if h.distance_to(gh) > tune.max_lag:
			h = gh + (h - gh).normalized() * tune.max_lag
		var y: float = lerp(cur.y, goal.y, kv)
		y = clamp(y, goal.y - 1.4, goal.y + 1.4)
		global_position = Vector3(h.x, y, h.y)
	tune.distance = float(opt.get("cam_dist", tune.distance))
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
