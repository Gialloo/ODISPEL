extends CharacterBody3D
## Nemico base. Fase 1: SCOUT (rapido, aggressivo, poco resistente).
## Avvisa sempre prima di colpire (si carica e si illumina), così chi perde capisce perché.

signal died(enemy: Node)

enum S { IDLE, CHASE, WINDUP, ATTACK, RECOVER, HITSTUN, AIR, STAGGER, DEAD }

const COL_BODY := Color(0.85, 0.2, 0.25)
const COL_WARN := Color(1.0, 0.85, 0.2)

var player: Node3D
var radius := 0.45
var max_hp := 70.0
var hp := 70.0
var max_poise := 30.0
var poise := 30.0
var weight := 1.0                  # più pesante = meno spinta
var state := S.IDLE
var tune := {
	"speed": 6.5,
	"attack_range": 2.3,
	"windup": 0.55,
	"lunge_speed": 13.0,
	"active": 0.16,
	"recover": 0.65,
	"damage": 12.0,
	"cooldown_min": 1.2,
	"cooldown_max": 2.4,
}

var _t := 0.0
var _cooldown := 1.0
var _strafe := 1.0
var _attack_dir := Vector3.FORWARD
var _attack_resolved := false
var _hit_flash := 0.0
var _body: MeshInstance3D
var _mat: StandardMaterial3D
var _warn: MeshInstance3D
var _warn_mat: StandardMaterial3D
var _bar: MeshInstance3D
var _bar_bg: MeshInstance3D
var _visual: Node3D
var charged := false
var _charge_t := 0.0
var _power_fly := 0.0
var _hit_by: Dictionary = {}
var burn_t := 0.0                  # FUOCO: secondi di fiamma rimasti
var _burn_tick := 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 4 | 16
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = radius
	cap.height = 1.5
	col.shape = cap
	col.position.y = 0.75
	add_child(col)
	_visual = Node3D.new()
	add_child(_visual)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = COL_BODY
	_body = MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.9, 1.3, 0.7)
	_body.mesh = pm
	_body.position.y = 0.8
	_body.material_override = _mat
	_visual.add_child(_body)
	var eye := MeshInstance3D.new()
	var em := BoxMesh.new()
	em.size = Vector3(0.5, 0.1, 0.1)
	eye.mesh = em
	eye.position = Vector3(0, 0.95, -0.32)
	var emat := StandardMaterial3D.new()
	emat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	emat.albedo_color = Color(1, 0.95, 0.8)
	eye.material_override = emat
	_visual.add_child(eye)
	# avviso d'attacco: un anello che si stringe sotto il nemico
	_warn = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.8
	tm.outer_radius = 1.0
	tm.ring_segments = 4
	tm.rings = 20
	_warn.mesh = tm
	_warn_mat = StandardMaterial3D.new()
	_warn_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_warn_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_warn_mat.albedo_color = Color(COL_WARN, 0.0)
	_warn.material_override = _warn_mat
	_warn.position.y = 0.06
	add_child(_warn)
	_bar_bg = _make_bar(Color(0, 0, 0, 0.6), 1.0)
	_bar = _make_bar(Color(1, 0.3, 0.35), 0.98)
	hp = max_hp
	poise = max_poise
	_cooldown = randf_range(0.6, 1.4)
	_strafe = 1.0 if randf() < 0.5 else -1.0

func _make_bar(c: Color, w: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(w, 0.08)
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.no_depth_test = true
	mat.albedo_color = c
	m.material_override = mat
	m.position.y = 1.85
	m.visible = false
	add_child(m)
	return m

func is_dead() -> bool:
	return state == S.DEAD

## Vero se sta colpendo adesso e il giocatore è a portata (per la schivata all'ultimo).
func is_threatening(p: Node3D) -> bool:
	if state != S.ATTACK and not (state == S.WINDUP and _t >= tune.windup - 0.08):
		return false
	return global_position.distance_to(p.global_position) < tune.attack_range + 1.6

func _physics_process(delta: float) -> void:
	var d := delta * FX.enemy_time
	_t += d
	if _hit_flash > 0:
		_hit_flash -= delta
		if _hit_flash <= 0:
			_mat.emission_enabled = false
	match state:
		S.IDLE, S.CHASE:
			_chase(d)
		S.WINDUP:
			_face_player(d * 4.0)
			velocity.x = move_toward(velocity.x, 0, 30 * d)
			velocity.z = move_toward(velocity.z, 0, 30 * d)
			var k: float = clamp(_t / tune.windup, 0.0, 1.0)
			_warn_mat.albedo_color = Color(COL_WARN, 0.25 + 0.75 * k)
			_warn.scale = Vector3.ONE * lerp(2.2, 0.9, k)
			_visual.position.z = 0.25 * k
			_visual.rotation.x = 0.25 * k
			if _t >= tune.windup:
				_attack_dir = _flat(player.global_position - global_position).normalized()
				_attack_resolved = false
				_set_state(S.ATTACK)
		S.ATTACK:
			velocity.x = _attack_dir.x * tune.lunge_speed
			velocity.z = _attack_dir.z * tune.lunge_speed
			_visual.position.z = -0.3
			_visual.rotation.x = -0.3
			if not _attack_resolved:
				var to := _flat(player.global_position - global_position)
				if to.length() < 1.7 and to.normalized().dot(_attack_dir) > 0.2:
					_attack_resolved = true
					var r: String = player.take_hit(self, tune.damage, _attack_dir)
					if r == "perfect":
						_set_state(S.RECOVER)
						_t = -0.6
			if state == S.ATTACK and _t >= tune.active:
				_set_state(S.RECOVER)
		S.RECOVER:
			velocity.x = move_toward(velocity.x, 0, 40 * d)
			velocity.z = move_toward(velocity.z, 0, 40 * d)
			_visual.position.z = lerp(_visual.position.z, 0.0, 0.2)
			_visual.rotation.x = lerp(_visual.rotation.x, 0.0, 0.2)
			if _t >= tune.recover:
				_cooldown = randf_range(tune.cooldown_min, tune.cooldown_max)
				_set_state(S.CHASE)
		S.HITSTUN, S.STAGGER:
			velocity.x = move_toward(velocity.x, 0, 22 * d)
			velocity.z = move_toward(velocity.z, 0, 22 * d)
			if _t >= (0.32 if state == S.HITSTUN else 1.3) and is_on_floor():
				if state == S.STAGGER:
					poise = max_poise
				_set_state(S.CHASE)
		S.AIR:
			velocity.x = move_toward(velocity.x, 0, 4 * d)
			velocity.z = move_toward(velocity.z, 0, 4 * d)
			if is_on_floor() and _t > 0.15:
				FX.ring(global_position, Color(1, 1, 1, 0.4), 1.2, 0.2)
				_set_state(S.HITSTUN)
		S.DEAD:
			velocity.x = move_toward(velocity.x, 0, 10 * d)
			velocity.z = move_toward(velocity.z, 0, 10 * d)
	# gravità: in aria dopo un colpo si resta sospesi un po' di più (giocoleria)
	var g := 26.0
	if state == S.AIR and velocity.y < 2.0 and velocity.y > -4.0:
		g = 11.0
	velocity.y = max(velocity.y - g * d, -30.0)
	if burn_t > 0.0 and state != S.DEAD:
		_burning(delta)
	if charged:
		_charge_t += delta
		_mat.emission_enabled = true
		_mat.emission = Color(1, 0.85, 0.2)
		_mat.emission_energy_multiplier = 1.0 + 0.8 * sin(_charge_t * 18.0)
		if _charge_t > 7.0:
			charged = false
			_mat.emission_enabled = false
	var saved := velocity
	velocity *= FX.enemy_time if FX.enemy_time < 1.0 else 1.0
	move_and_slide()
	if FX.enemy_time < 1.0:
		velocity = saved
	if _power_fly > 0.0:
		_power_fly -= delta
		_power_collisions(saved)
	if state != S.WINDUP:
		_warn_mat.albedo_color.a = move_toward(_warn_mat.albedo_color.a, 0.0, 6 * delta)
	_update_bar()

func _chase(d: float) -> void:
	if player == null or player.get("state") == 4:
		velocity.x = move_toward(velocity.x, 0, 20 * d)
		velocity.z = move_toward(velocity.z, 0, 20 * d)
		return
	_cooldown -= d
	var to := _flat(player.global_position - global_position)
	var dist := to.length()
	var dir := to.normalized()
	var want: Vector3
	if dist > tune.attack_range + 1.5:
		want = dir * tune.speed
	else:
		# gira intorno al giocatore aspettando il momento
		var side := Vector3(-dir.z, 0, dir.x) * _strafe
		want = side * tune.speed * 0.45 + dir * (dist - tune.attack_range) * 1.5
		if _cooldown <= 0.0 and dist < tune.attack_range + 1.6:
			_set_state(S.WINDUP)
			FX.sound("scudo", 1.4, -8.0)
			return
	var hv := Vector3(velocity.x, 0, velocity.z).move_toward(want, 30 * d)
	velocity.x = hv.x
	velocity.z = hv.z
	_face_player(d * 10.0)
	if randf() < 0.004:
		_strafe = -_strafe

func _face_player(step: float) -> void:
	var to := _flat(player.global_position - global_position)
	if to.length() < 0.05:
		return
	var want := atan2(-to.x, -to.z)
	_visual.rotation.y = lerp_angle(_visual.rotation.y, want, clamp(step, 0, 1))

func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z)

func _set_state(s: int) -> void:
	state = s
	_t = 0.0

## SPINGI: scaraventato via. Contro un muro o un altro nemico si fa male.
func power_push(v: Vector3) -> void:
	if state == S.DEAD:
		return
	velocity = v / weight
	_set_state(S.AIR)
	_power_fly = 0.9
	_hit_by.clear()
	FX.stat("enemy_pushed")

## ATTIRA: trascinato a portata di lama e lasciato scoperto per un attimo.
func power_pull(point: Vector3) -> void:
	if state == S.DEAD:
		return
	var to := point - global_position
	to.y = 0
	velocity = to * 5.5 / weight + Vector3(0, 4.0, 0)
	_set_state(S.HITSTUN)
	_t = -0.3
	_warn_mat.albedo_color.a = 0.0
	FX.stat("enemy_pulled")

## SOVRACCARICA: al prossimo colpo esplode.
func charge() -> void:
	charged = true
	_charge_t = 0.0

func _power_collisions(pre: Vector3) -> void:
	var speed := Vector3(pre.x, 0, pre.z).length()
	if speed < 7.0:
		return
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var n := c.get_normal()
		var col := c.get_collider()
		var solid: bool = col is StaticBody3D or (col != null and col.has_method("is_fixed") and col.is_fixed())
		if absf(n.y) < 0.6 and solid:
			if col.has_method("structure_damage"):
				col.structure_damage(speed * 3.0)
			_power_fly = 0.0
			velocity = Vector3(n.x, 0.4, n.z) * 3.0
			FX.stat("wall_slams")
			FX.stat("env_hits")
			receive_hit({"dmg": 8.0 + speed * 0.8, "poise": 50.0, "dir": n, "knock": 1.0, "launch": 0.0, "form": -1, "move": "wall", "env": true})
			FX.ring(global_position + Vector3(0, 1, 0) - n * 0.4, Color(1, 1, 1, 0.8), 1.6, 0.2)
			return
	# contro un altro nemico: birilli
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or e.is_dead() or _hit_by.has(e):
			continue
		if e.global_position.distance_to(global_position) < radius + e.radius + 0.4:
			_hit_by[e] = true
			var dir: Vector3 = e.global_position - global_position
			dir.y = 0
			dir = dir.normalized()
			e.receive_hit({"dmg": 6.0 + speed * 0.6, "poise": 40.0, "dir": dir, "knock": speed * 0.5, "launch": 3.0, "form": -1, "move": "bowl", "env": true})
			FX.stat("enemy_collisions")
			FX.stat("env_hits")
			FX.hitstop(60)
			FX.sound("colpo_forte", 1.0)

## FUOCO: brucia per qualche secondo, il fuoco passa ai vicini; l'acqua lo spegne.
func ignite(sec: float) -> void:
	if state == S.DEAD:
		return
	if El.puddle_at(global_position) >= 0:
		FX.ring(global_position, Color(0.9, 0.95, 1.0, 0.6), 1.0, 0.2)
		return
	if burn_t <= 0.0:
		FX.stat("enemies_burned")
		_burn_tick = 0.0
	burn_t = max(burn_t, sec)

func _burning(delta: float) -> void:
	burn_t -= delta
	_burn_tick -= delta
	if El.puddle_at(global_position) >= 0:
		burn_t = 0.0
		FX.ring(global_position, Color(0.9, 0.95, 1.0, 0.7), 1.2, 0.25)
		FX.stat("fires_doused")
	if burn_t <= 0.0:
		if not charged:
			_mat.emission_enabled = false
		return
	if not charged and _hit_flash <= 0.0:
		_mat.emission_enabled = true
		_mat.emission = Color(1, 0.45, 0.1)
		_mat.emission_energy_multiplier = 1.2 + 0.6 * sin(_t * 30.0)
	if _burn_tick <= 0.0:
		_burn_tick = 0.5
		hp -= El.tune.fire_dps * 0.5
		FX.stat("fire_damage", int(El.tune.fire_dps * 0.5))
		FX.sparks(global_position + Vector3(0, 1.2, 0), Vector3.UP, Color(1, 0.55, 0.15), 3, 3.0)
		# si propaga a chi è attaccato e alle casse di legno vicine
		if burn_t > 1.0:
			for e in get_tree().get_nodes_in_group("enemies"):
				if e != self and e.burn_t <= 0.0 and e.global_position.distance_to(global_position) < 1.7:
					e.ignite(burn_t * 0.7)
					FX.stat("fire_spread")
			for p in get_tree().get_nodes_in_group("props"):
				if p.get("flammable") and p.center().distance_to(global_position) < 1.4:
					p.ignite()
		if hp <= 0.0:
			_die(Vector3.ZERO)

## ELETTRICITÀ: scossa che blocca sul posto e fa esplodere chi è sovraccaricato.
func shock(dmg: float) -> void:
	if state == S.DEAD:
		return
	receive_hit({"dmg": dmg, "poise": 35.0, "dir": Vector3.ZERO, "knock": 0.0, "launch": 0.0, "form": -1, "move": "shock", "env": true})
	if state != S.DEAD and is_on_floor():
		_set_state(S.STAGGER)
		_t = 0.35
	_mat.emission_enabled = true
	_mat.emission = Color(0.5, 0.95, 1.0)
	_mat.emission_energy_multiplier = 2.0
	_hit_flash = 0.18
	FX.stat("enemies_shocked")

## Riceve un colpo del giocatore (dati dalla tabella delle mosse).
func receive_hit(info: Dictionary) -> void:
	if state == S.DEAD:
		return
	hp -= info.dmg
	poise -= info.poise
	_mat.emission_enabled = true
	_mat.emission = Color(1, 1, 1)
	_mat.emission_energy_multiplier = 1.5
	_hit_flash = 0.07
	var dir: Vector3 = info.dir
	var kb: float = info.knock / weight
	if info.has("pull_to"):
		# VECTOR: trascinato verso il giocatore
		var to: Vector3 = info.pull_to - global_position
		to.y = 0
		velocity.x = to.x * 6.0
		velocity.z = to.z * 6.0
		velocity.y = 3.0
		_set_state(S.HITSTUN)
		_t = -0.15
	else:
		velocity.x = dir.x * kb
		velocity.z = dir.z * kb
	var interrupted := state == S.WINDUP or state == S.ATTACK
	if info.launch > 0.0 and (info.launch > 6.0 or not is_on_floor()):
		velocity.y = info.launch / sqrt(weight)
		_set_state(S.AIR)
	elif not info.has("pull_to"):
		if poise <= 0.0:
			_set_state(S.STAGGER)
			FX.sound("break", 1.0, -2.0)
			FX.stat("staggers")
		elif state != S.STAGGER:
			_set_state(S.HITSTUN)
	if interrupted:
		FX.stat("interrupts")
	_visual.scale = Vector3(1.25, 0.8, 1.25)
	create_tween().tween_property(_visual, "scale", Vector3.ONE, 0.15)
	_warn_mat.albedo_color.a = 0.0
	if charged and info.get("move", "") != "blast":
		charged = false
		_mat.emission_enabled = false
		FX.overcharge_blast(global_position + Vector3(0, 0.8, 0), self)
	if hp <= 0.0:
		_die(dir)

func _die(dir: Vector3) -> void:
	_set_state(S.DEAD)
	remove_from_group("enemies")
	collision_layer = 0
	velocity = dir * 9.0 + Vector3(0, 7.0, 0)
	FX.sound("ko", 1.2)
	FX.stat("kills")
	FX.sparks(global_position + Vector3(0, 1, 0), Vector3.UP, COL_BODY, 16, 9.0)
	_bar.visible = false
	_bar_bg.visible = false
	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_property(_visual, "scale", Vector3.ZERO, 0.25)
	t.tween_callback(func():
		died.emit(self)
		queue_free())

func _update_bar() -> void:
	var show := hp < max_hp and state != S.DEAD
	_bar.visible = show
	_bar_bg.visible = show
	if show:
		var k: float = clamp(hp / max_hp, 0.0, 1.0)
		_bar.scale.x = max(k, 0.001)
