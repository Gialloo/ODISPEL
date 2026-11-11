extends CharacterBody3D
## Oggetto manipolabile. Fisica controllata (niente RigidBody): traiettorie prevedibili.
## LEGGERO: si spinge, si attira, si tiene sospeso e si rilancia.
## PESANTE: serve uno stadio di potere più alto; quando vola fa molti più danni.

signal broke(prop: Node)

enum S { IDLE, FLYING, HELD }

var kind := "light"                # "light" | "heavy"
var radius := 0.5
var mass := 1.0
var state := S.IDLE
var charged := false               # SOVRACCARICA: al prossimo impatto esplode
var thrower: Node3D
var _hold_point := Vector3.ZERO
var _hit_cool := {}
var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _charge_t := 0.0
var _fly_t := 0.0

func setup(k: String) -> void:
	kind = k
	if kind == "heavy":
		radius = 0.9
		mass = 3.0
	else:
		radius = 0.45
		mass = 1.0

func _ready() -> void:
	add_to_group("props")
	collision_layer = 8
	collision_mask = 1 | 8
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3.ONE * radius * 2.0
	cs.shape = sh
	cs.position.y = radius
	add_child(cs)
	_mesh = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sh.size
	_mesh.mesh = bm
	_mesh.position.y = radius
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.85, 0.75, 0.45) if kind == "light" else Color(0.45, 0.5, 0.6)
	_mesh.material_override = _mat
	add_child(_mesh)
	# fascia che dice "si può prendere": chiara sui leggeri, scura sui pesanti
	var band := MeshInstance3D.new()
	var b2 := BoxMesh.new()
	b2.size = Vector3(radius * 2.05, radius * 0.3, radius * 2.05)
	band.mesh = b2
	band.position.y = radius
	var bm2 := StandardMaterial3D.new()
	bm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm2.albedo_color = Color(0.6, 0.95, 1.0) if kind == "light" else Color(0.9, 0.5, 1.0)
	band.material_override = bm2
	add_child(band)

func is_dead() -> bool:
	return false

func is_heavy() -> bool:
	return kind == "heavy"

func center() -> Vector3:
	return global_position + Vector3(0, radius, 0)

## Spinta / lancio.
func launch(v: Vector3, by: Node3D) -> void:
	state = S.FLYING
	thrower = by
	velocity = v / sqrt(mass)
	_fly_t = 0.0
	_hit_cool.clear()

func hold(point: Vector3) -> void:
	state = S.HELD
	_hold_point = point

func release_hold() -> void:
	if state == S.HELD:
		state = S.IDLE

func set_hold_point(p: Vector3) -> void:
	_hold_point = p

func charge() -> void:
	charged = true
	_charge_t = 0.0
	_mat.emission_enabled = true
	_mat.emission = Color(1, 0.85, 0.2)

## Colpito da un attacco del giocatore: un leggero vola via nella direzione del colpo.
func receive_hit(info: Dictionary) -> void:
	if charged:
		detonate()
	var dir: Vector3 = info.dir
	var power: float = 10.0 + info.knock * 1.5
	if kind == "heavy":
		power *= 0.5
	launch(dir * power + Vector3(0, 2.5 + info.launch * 0.4, 0), get_tree().get_first_node_in_group("player"))

func detonate() -> void:
	if not charged:
		return
	charged = false
	_mat.emission_enabled = false
	FX.overcharge_blast(center(), self)

func _physics_process(delta: float) -> void:
	if charged:
		_charge_t += delta
		_mat.emission_energy_multiplier = 1.0 + 0.8 * sin(_charge_t * 18.0)
		if _charge_t > 7.0:
			charged = false
			_mat.emission_enabled = false
	match state:
		S.HELD:
			var to := _hold_point - center()
			velocity = to * 14.0
			if velocity.length() > 22.0:
				velocity = velocity.normalized() * 22.0
			_mesh.rotation.y += delta * 3.0
		S.FLYING:
			_fly_t += delta
			velocity.y -= 18.0 * delta
			_check_hits()
			if is_on_floor() and _fly_t > 0.1 and Vector3(velocity.x, 0, velocity.z).length() < 3.0:
				state = S.IDLE
		S.IDLE:
			velocity.y -= 28.0 * delta
			velocity.x = move_toward(velocity.x, 0, 18.0 * delta)
			velocity.z = move_toward(velocity.z, 0, 18.0 * delta)
	var pre := velocity
	move_and_slide()
	if state == S.FLYING and get_slide_collision_count() > 0:
		var n := get_slide_collision(0).get_normal()
		if pre.length() > 9.0 and absf(n.y) < 0.6:
			# rimbalza sul muro e perde forza
			velocity = pre.bounce(n) * 0.35
			FX.sound("colpo_forte", 0.7, -6.0)
			FX.sparks(center(), n, Color(1, 1, 1), 5, 4.0)
			if charged:
				detonate()
		elif is_on_floor():
			velocity.x *= 0.85
			velocity.z *= 0.85
	if global_position.y < -10.0:
		global_position = Vector3(randf_range(-8, 8), 3, randf_range(-8, 8))
		velocity = Vector3.ZERO
		state = S.IDLE

## In volo colpisce i nemici che incontra.
func _check_hits() -> void:
	var speed := velocity.length()
	if speed < 6.0:
		return
	var now := Time.get_ticks_msec()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_dead() or (_hit_cool.has(e) and now < _hit_cool[e]):
			continue
		if center().distance_to(e.global_position + Vector3(0, 0.8, 0)) < radius + e.radius + 0.35:
			_hit_cool[e] = now + 400
			var dir := Vector3(velocity.x, 0, velocity.z).normalized()
			var dmg := speed * 0.9 * mass
			e.receive_hit({"dmg": dmg, "poise": dmg * 1.4, "dir": dir, "knock": 5.0 * mass, "launch": 2.0 if mass < 2 else 5.0,
				"form": -1, "move": "prop", "env": true})
			FX.hitstop(55 + 25 * mass)
			FX.shake(0.25 * mass)
			FX.sound("colpo_forte", 1.1 - mass * 0.1)
			FX.sparks(center(), -dir, Color(1, 0.9, 0.6), 10, 7.0)
			FX.stat("prop_hits")
			FX.stat("env_hits")
			velocity *= 0.45
			if charged:
				detonate()
