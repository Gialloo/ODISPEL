extends CharacterBody3D
## Oggetto manipolabile. Fisica controllata (niente RigidBody): traiettorie prevedibili.
## LEGGERO: si spinge, si attira, si tiene sospeso e si rilancia.
## PESANTE: serve uno stadio di potere più alto; quando vola fa molti più danni.
## Fase 3, famiglie dell'ambiente:
##   light  = cassa di legno, INFIAMMABILE: brucia, e lanciata accesa incendia chi colpisce.
##   heavy  = blocco di metallo, CONDUTTIVO: passa la scarica.
##   barrel = bidone di carburante, ESPLOSIVO: fuoco, scossa o un urto forte lo fanno saltare.
##   coil   = bobina fissa, CONDUTTIVA: colpita (o spinta col potere) scarica sui vicini.
##   cover  = muretto di casse, DISTRUTTIBILE: si sfonda con colpi pesanti, oggetti o nemici lanciati.

signal broke(prop: Node)

const KINDS := {
	"light": {"size": Vector3(0.9, 0.9, 0.9), "r": 0.45, "mass": 1.0, "col": Color(0.85, 0.75, 0.45), "band": Color(0.6, 0.95, 1.0), "flammable": true},
	"heavy": {"size": Vector3(1.8, 1.8, 1.8), "r": 0.9, "mass": 3.0, "col": Color(0.45, 0.5, 0.6), "band": Color(0.9, 0.5, 1.0), "conductive": true},
	"barrel": {"size": Vector3(0.9, 1.2, 0.9), "r": 0.5, "mass": 1.4, "col": Color(0.85, 0.2, 0.15), "band": Color(1.0, 0.8, 0.2), "flammable": true, "explosive": true},
	"coil": {"size": Vector3(1.2, 2.0, 1.2), "r": 0.7, "mass": 99.0, "col": Color(0.2, 0.25, 0.35), "band": Color(0.4, 0.9, 1.0), "conductive": true, "fixed": true},
	"cover": {"size": Vector3(3.2, 1.6, 0.8), "r": 1.1, "mass": 99.0, "col": Color(0.55, 0.42, 0.28), "band": Color(0.35, 0.28, 0.2), "fixed": true, "hp": 60.0},
	"debris": {"size": Vector3(0.6, 0.6, 0.6), "r": 0.3, "mass": 0.7, "col": Color(0.6, 0.47, 0.3), "band": Color(0.45, 0.35, 0.22), "flammable": true},
}

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
var size := Vector3.ONE
var flammable := false
var conductive := false
var explosive := false
var fixed := false
var hp := 0.0
var temp := 0.0                     # >0: sparisce dopo questi secondi (detriti)
var burning := 0.0                  # secondi di fiamma rimasti
var fuse := -1.0                    # bidone: miccia accesa
var _zap_cd := 0.0
var _gone := false
var _base_col := Color.WHITE

func setup(k: String) -> void:
	kind = k
	var d: Dictionary = KINDS[k]
	size = d.size
	radius = d.r
	mass = d.mass
	flammable = d.get("flammable", false)
	conductive = d.get("conductive", false)
	explosive = d.get("explosive", false)
	fixed = d.get("fixed", false)
	hp = d.get("hp", 0.0)

func _ready() -> void:
	add_to_group("props")
	# i fissi stanno su un livello a parte: bloccano tutti ma non la telecamera
	collision_layer = 16 if fixed else 8
	collision_mask = 1 | 8 | 16
	var d: Dictionary = KINDS[kind]
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position.y = size.y * 0.5
	add_child(cs)
	_mesh = MeshInstance3D.new()
	if kind == "barrel" or kind == "coil":
		var cm := CylinderMesh.new()
		cm.top_radius = size.x * 0.5
		cm.bottom_radius = size.x * 0.5
		cm.height = size.y
		cm.radial_segments = 12
		_mesh.mesh = cm
	else:
		var bm := BoxMesh.new()
		bm.size = size
		_mesh.mesh = bm
	_mesh.position.y = size.y * 0.5
	_mat = StandardMaterial3D.new()
	_base_col = d.col
	_mat.albedo_color = _base_col
	_mesh.material_override = _mat
	add_child(_mesh)
	# fascia che dice la famiglia: azzurra = legno leggero, viola = metallo,
	# gialla = carburante, ciano = bobina, scura = muretto da sfondare
	var band := MeshInstance3D.new()
	var b2 := BoxMesh.new()
	b2.size = Vector3(size.x * 1.03, size.y * 0.16, size.z * 1.03)
	band.mesh = b2
	band.position.y = size.y * (0.85 if kind == "coil" else 0.5)
	var bm2 := StandardMaterial3D.new()
	bm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm2.albedo_color = d.band
	band.material_override = bm2
	add_child(band)
	if kind == "coil":
		var top := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.45
		sm.height = 0.9
		top.mesh = sm
		top.position.y = size.y + 0.25
		var tm := StandardMaterial3D.new()
		tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		tm.albedo_color = Color(0.5, 0.95, 1.0)
		top.material_override = tm
		add_child(top)

func is_dead() -> bool:
	return _gone

func is_heavy() -> bool:
	return kind == "heavy"

func is_fixed() -> bool:
	return fixed

func center() -> Vector3:
	return global_position + Vector3(0, size.y * 0.5, 0)

## Spinta / lancio.
func launch(v: Vector3, by: Node3D) -> void:
	if fixed or _gone:
		return
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

## Il potere che "tocca" un oggetto fisso: la bobina scarica, il muretto incassa.
func power_poke() -> void:
	if kind == "coil":
		on_shock(true)
	elif kind == "cover":
		structure_damage(18.0)

func charge() -> void:
	charged = true
	_charge_t = 0.0
	_mat.emission_enabled = true
	_mat.emission = Color(1, 0.85, 0.2)

## Colpito da un attacco del giocatore: un leggero vola via nella direzione del colpo.
func receive_hit(info: Dictionary) -> void:
	if _gone:
		return
	if charged:
		detonate()
	if kind == "coil":
		on_shock(true)
		return
	if kind == "cover":
		structure_damage(info.dmg * (1.6 if info.form == 1 else 1.0) + info.knock)
		return
	if kind == "barrel" and info.dmg >= 10.0:
		ignite(0.35)
	var dir: Vector3 = info.dir
	var power: float = 10.0 + info.knock * 1.5
	if kind == "heavy":
		power *= 0.5
	launch(dir * power + Vector3(0, 2.5 + info.launch * 0.4, 0), get_tree().get_first_node_in_group("player"))

# ------------------------------------------------------------ fuoco, scossa, rottura

func ignite(fuse_time := 0.6) -> void:
	if _gone or not flammable:
		return
	if El.puddle_at(global_position) >= 0:
		return
	if explosive:
		if fuse < 0.0:
			fuse = fuse_time
			FX.sound("scudo", 1.6, -4.0)
		else:
			fuse = min(fuse, fuse_time)
		return
	if burning <= 0.0:
		FX.stat("props_burned")
	burning = 3.5

## Scossa ricevuta o data. La bobina scarica sui vicini (con una piccola ricarica).
func on_shock(origin := false) -> void:
	if kind == "coil":
		if _zap_cd > 0.0:
			return
		_zap_cd = 1.2
		_mat.emission_enabled = true
		_mat.emission = Color(0.5, 0.95, 1.0)
		_mat.emission_energy_multiplier = 2.5
		create_tween().tween_property(_mat, "emission_energy_multiplier", 0.0, 0.4)
		FX.stat("coil_discharges")
		FX.shake(0.35)
		var p := 1.6 if charged else 1.0
		if charged:
			charged = false
			FX.stat("coil_overloads")
		if origin:
			El.shock(center(), self, p)
	else:
		_mat.emission_enabled = true
		_mat.emission = Color(0.5, 0.95, 1.0)
		_mat.emission_energy_multiplier = 1.8
		get_tree().create_timer(0.25).timeout.connect(func():
			if is_instance_valid(self) and not charged and burning <= 0.0:
				_mat.emission_enabled = false)

## Danno alle strutture: il muretto si sfonda in detriti che volano via.
func structure_damage(amount: float) -> void:
	if _gone:
		return
	if kind == "barrel":
		ignite(0.15)
		return
	if kind != "cover":
		return
	hp -= amount
	FX.sparks(center(), Vector3.UP, _base_col, 6, 5.0)
	FX.sound("colpo_forte", 0.6, -4.0)
	_mesh.scale = Vector3(1.06, 0.94, 1.06)
	create_tween().tween_property(_mesh, "scale", Vector3.ONE, 0.12)
	_mat.albedo_color = _base_col.darkened(0.45 * (1.0 - clamp(hp / 60.0, 0.0, 1.0)))
	if hp <= 0.0:
		_break_cover()

func _break_cover() -> void:
	FX.stat("structures_broken")
	FX.sound("break", 0.7)
	FX.shake(0.6)
	FX.hitstop(80)
	FX.ring(center(), Color(1, 0.85, 0.6, 0.8), 2.6, 0.3)
	var pl: Node3D = get_tree().get_first_node_in_group("player")
	var away := Vector3.FORWARD
	if pl:
		away = global_position - pl.global_position
		away.y = 0
		away = away.normalized() if away.length() > 0.1 else Vector3.FORWARD
	var right := Vector3(-away.z, 0, away.x)
	for i in 5:
		var pr = get_script().new()
		pr.setup("debris")
		pr.temp = 6.0
		get_parent().add_child(pr)
		pr.global_position = global_position + right * (i - 2) * 0.6 + Vector3(0, 0.6 + (i % 2) * 0.6, 0)
		pr.launch((away * 15.0 + right * (i - 2) * 2.5 + Vector3(0, 4.0, 0)), pl)
		if burning > 0.0:
			pr.ignite()
	_vanish()

func _explode() -> void:
	fuse = -1.0
	var c := center()
	FX.stat("barrels_exploded")
	FX.sound("colpo_finale", 0.7)
	FX.shake(0.9)
	FX.hitstop(120)
	FX.ring(c, Color(1, 0.45, 0.1, 0.95), 3.8, 0.4)
	FX.sparks(c, Vector3.UP, Color(1, 0.6, 0.15), 22, 12.0)
	_gone = true
	for e in get_tree().get_nodes_in_group("enemies"):
		var to: Vector3 = e.global_position - c
		to.y = 0
		if to.length() < 3.8 and not e.is_dead():
			e.receive_hit({"dmg": 26.0, "poise": 80.0, "dir": to.normalized() if to.length() > 0.1 else Vector3.FORWARD,
				"knock": 10.0, "launch": 8.0, "form": -1, "move": "barrel", "env": true})
	for p in get_tree().get_nodes_in_group("props"):
		if p == self or p.is_dead():
			continue
		var to2: Vector3 = p.center() - c
		if to2.length() < 3.8:
			p.structure_damage(40.0)
			if p.has_method("launch") and not p.fixed:
				p.launch((to2.normalized() + Vector3(0, 0.7, 0)) * 13.0, null)
	El.ignite_area(c, 3.8, self)
	_vanish()

func _vanish() -> void:
	_gone = true
	broke.emit(self)
	queue_free()

func detonate() -> void:
	if not charged:
		return
	charged = false
	_mat.emission_enabled = false
	FX.overcharge_blast(center(), self)

func _physics_process(delta: float) -> void:
	if _gone:
		return
	_zap_cd = max(0.0, _zap_cd - delta)
	if temp > 0.0:
		temp -= delta
		if temp <= 0.0:
			_vanish()
			return
	if fuse >= 0.0:
		fuse -= delta
		_mat.emission_enabled = true
		_mat.emission = Color(1, 0.4, 0.1)
		_mat.emission_energy_multiplier = 1.0 + 1.5 * absf(sin(fuse * 30.0))
		if fuse <= 0.0:
			_explode()
			return
	if burning > 0.0:
		burning -= delta
		if El.puddle_at(global_position) >= 0:
			burning = 0.0
			FX.stat("fires_doused")
		if not charged:
			_mat.emission_enabled = burning > 0.0
			_mat.emission = Color(1, 0.45, 0.1)
			_mat.emission_energy_multiplier = 1.0 + 0.6 * sin(Time.get_ticks_msec() * 0.03)
		if Engine.get_physics_frames() % 15 == 0:
			FX.sparks(center() + Vector3(0, radius, 0), Vector3.UP, Color(1, 0.55, 0.15), 2, 3.0)
		if burning <= 0.0:
			# la cassa di legno si consuma
			FX.sparks(center(), Vector3.UP, Color(0.3, 0.3, 0.3), 8, 4.0)
			_vanish()
			return
	if fixed:
		return
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
			var col := get_slide_collision(0).get_collider()
			if col and col.has_method("structure_damage"):
				col.structure_damage(pre.length() * mass * 1.5)
				FX.stat("env_hits")
			if explosive:
				ignite(0.12)
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
			if burning > 0.0:
				e.ignite(El.tune.fire_time)
				FX.stat("fire_throws")
			if explosive:
				ignite(0.05)
			velocity *= 0.45
			if charged:
				detonate()
