extends CharacterBody3D
## Nemico a tre archetipi. Avvisa sempre prima di colpire (si carica e si illumina),
## così chi perde capisce perché.
##   SCOUT   rapido, aggressivo, poco resistente: affondo.
##   BRUTE   pesante e resistente: non si ferma ai colpi finché non perde l'equilibrio,
##           schianto ad area lento e potente; si sposta col potere solo dallo stadio 2.
##   CONDUIT tiene le distanze e lancia sfere elettriche, spesso sull'ambiente (pozze, bidoni,
##           bobine vicino al giocatore). La sfera si rimanda indietro con SPINGI; scosso, si scarica.

signal died(enemy: Node)

enum S { IDLE, CHASE, WINDUP, ATTACK, RECOVER, HITSTUN, AIR, STAGGER, DEAD }

const COL_BODY := Color(0.85, 0.2, 0.25)
const Orb = preload("res://scripts/enemies/orb.gd")
## Archetipi: valori base e moltiplicatori della tabella condivisa (tune, regolabile nel LAB).
const ARCH := {
	"scout": {"hp": 70.0, "poise": 30.0, "weight": 1.0, "radius": 0.45, "col": Color(0.85, 0.2, 0.25), "m": {}},
	"brute": {"hp": 220.0, "poise": 95.0, "weight": 2.6, "radius": 0.8, "col": Color(0.9, 0.48, 0.15),
		"m": {"speed": 0.48, "attack_range": 1.25, "windup": 1.7, "lunge_speed": 0.25, "damage": 1.9, "active": 1.4, "recover": 1.5}},
	"conduit": {"hp": 55.0, "poise": 25.0, "weight": 0.9, "radius": 0.45, "col": Color(0.3, 0.55, 1.0),
		"m": {"speed": 0.8, "attack_range": 3.4, "windup": 1.5, "damage": 0.9, "cooldown_min": 1.5, "cooldown_max": 1.3}},
}
const COL_WARN := Color(1.0, 0.85, 0.2)

var player: Node3D
var radius := 0.45
var max_hp := 70.0
var hp := 70.0
var max_poise := 30.0
var poise := 30.0
var weight := 1.0                  # più pesante = meno spinta
var state := S.IDLE
var arch := "scout"
var boss := false                  # 0.15: COLOSSO, un Bruto gigante che chiude ogni quinta ondata
var boss_name := ""                # 0.17: COLOSSO (Bruto gigante) o TRALICCIO (Conduit gigante, ogni decima ondata)
var _shots := 0                    # TRALICCIO: attacchi fatti (ogni terzo è la scarica a terra)
var _close_t := 0.0                # TRALICCIO: da quanto il giocatore gli sta addosso
var _pulse_t := 0.0                # TRALICCIO: carica dell'impulso prima di sparire
var wave := 1                      # ondata: rende i nemici più svelti e frequenti, non solo più resistenti
var _zap_cd := 0.0
var _prev_vy := 0.0
var _tumble := 0.0                 # 0.8: rotazione in aria quando viene lanciato
var _bounced := false
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
## 0.16: barra di vita come la vuole l'autore: rosso = vita, bianco = vita appena tolta.
## Il bianco resta fermo finché i colpi continuano e scende solo dopo una pausa.
var hp_white := 70.0
var _white_hold := 0.0
var _hp_seen := 70.0
const WHITE_HOLD := 0.6
var hit_chain := 0
var _burn_tick := 0.0

func setup(a: String, w: int, is_boss := false) -> void:
	arch = a
	wave = w
	var d: Dictionary = ARCH[a]
	radius = d.radius
	weight = d.weight
	max_hp = d.hp * (1.0 + 0.04 * min(w - 1, 15))
	max_poise = d.poise * (1.0 + 0.03 * min(w - 1, 15))
	if is_boss:
		# tanta vita ma postura solo il doppio: le combo pesanti lo devono ancora far barcollare
		boss = true
		if a == "conduit":
			# TRALICCIO: si tiene lontano e spara a ventaglio. Le sue sfere rimandate indietro lo fanno crollare.
			boss_name = "TRALICCIO"
			max_hp *= 8.0
			max_poise *= 3.0
			radius *= 1.6
			weight *= 3.0
		else:
			boss_name = "COLOSSO"
			max_hp *= 5.5
			max_poise *= 2.2
			radius *= 1.5
			weight *= 2.0

## Valore della tabella per questo archetipo e questa ondata.
func _tv(k: String) -> float:
	var v: float = tune[k] * ARCH[arch].m.get(k, 1.0)
	var lw: float = min(wave - 1, 14)
	match k:
		"speed":
			v *= 1.0 + 0.02 * lw
		"cooldown_min", "cooldown_max":
			v *= 1.0 - 0.03 * lw
		"windup":
			v *= max(0.75, 1.0 - 0.015 * lw)
	if boss and arch == "conduit":
		match k:
			"speed": v *= 1.1
			"attack_range": v *= 1.25
			"windup": v *= 0.85
	elif boss:
		match k:
			"speed": v *= 1.3
			"attack_range": v *= 1.5
			"damage": v *= 1.25
	return v

func is_heavy() -> bool:
	return arch == "brute"

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 4 | 16
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = radius
	cap.height = (3.2 if boss else 2.0) if arch == "brute" else (2.7 if boss else 1.5)
	col.shape = cap
	col.position.y = cap.height * 0.5
	add_child(col)
	_visual = Node3D.new()
	add_child(_visual)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = ARCH[arch].col
	_body = MeshInstance3D.new()
	if arch == "brute":
		var bx := BoxMesh.new()
		bx.size = Vector3(1.6, 1.9, 1.2)
		_body.mesh = bx
		_body.position.y = 1.0
	elif arch == "conduit":
		var cy := CylinderMesh.new()
		cy.top_radius = 0.2
		cy.bottom_radius = 0.45
		cy.height = 1.5
		_body.mesh = cy
		_body.position.y = 0.8
		var ant := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.25
		sm.height = 0.5
		ant.mesh = sm
		ant.position.y = 1.75
		var am := StandardMaterial3D.new()
		am.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		am.albedo_color = Color(0.5, 0.95, 1.0)
		ant.material_override = am
		_visual.add_child(ant)
	else:
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
	eye.position = Vector3(0, 1.45, -0.62) if arch == "brute" else Vector3(0, 0.95, -0.32)
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
	if boss:
		_make_boss_look()
	hp = max_hp
	hp_white = max_hp
	_hp_seen = max_hp
	poise = max_poise
	_cooldown = randf_range(0.6, 1.4)
	_strafe = 1.0 if randf() < 0.5 else -1.0

## COLOSSO: stesso corpo del Bruto ma 1,6 volte più grande, viola scuro, con tre corna e il petto acceso.
func _make_boss_look() -> void:
	add_to_group("boss")
	if arch == "conduit":
		_make_pylon_look()
		return
	_visual.scale = Vector3.ONE * 1.6
	_mat.albedo_color = Color(0.42, 0.14, 0.32)
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.95, 0.6, 0.2)
	for i in 3:
		var horn := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.28, 0.6 if i == 1 else 0.45, 0.28)
		horn.mesh = pm
		horn.material_override = hm
		horn.position = Vector3((i - 1) * 0.5, 2.15, -0.1)
		horn.rotation.z = (1 - i) * 0.35
		_visual.add_child(horn)
	var core := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.5, 0.5, 0.08)
	core.mesh = cm
	var km := StandardMaterial3D.new()
	km.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	km.albedo_color = Color(1.0, 0.55, 0.15)
	core.material_override = km
	core.position = Vector3(0, 1.05, -0.62)
	_visual.add_child(core)

## TRALICCIO: un Conduit alto quasi il doppio, blu notte, con traverse da palo della luce e tre isolatori accesi.
func _make_pylon_look() -> void:
	_visual.scale = Vector3.ONE * 1.8
	_mat.albedo_color = Color(0.12, 0.16, 0.38)
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.2, 0.22, 0.3)
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.albedo_color = Color(0.5, 0.95, 1.0)
	for i in 2:
		var bar := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = Vector3(1.5 - i * 0.5, 0.08, 0.1)
		bar.mesh = bx
		bar.material_override = bm
		bar.position = Vector3(0, 1.25 + i * 0.3, 0)
		_visual.add_child(bar)
	for i in 3:
		var iso := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.11
		sm.height = 0.22
		iso.mesh = sm
		iso.material_override = gm
		iso.position = Vector3((i - 1) * 0.68, 1.36, 0)
		_visual.add_child(iso)

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
	if state != S.ATTACK and not (state == S.WINDUP and _t >= _tv("windup") - 0.08):
		return false
	return global_position.distance_to(p.global_position) < _tv("attack_range") + 1.6

## Riporta il nemico in campo (caduto fuori dall'arena o incastrato): rientra con l'annuncio rosso.
func recall(p: Vector3) -> void:
	if is_dead():
		return
	velocity = Vector3.ZERO
	global_position = p
	_set_state(S.CHASE)
	FX.ring(p, Color(1, 0.3, 0.3, 0.8), 2.0, 0.4)

func _physics_process(delta: float) -> void:
	# 0.9: lanciato oltre il muro o sotto il pavimento non resta perso per sempre (bloccava l'ondata)
	if not is_dead() and (global_position.y < -4.0 or global_position.y > 40.0 or Vector2(global_position.x, global_position.z).length() > 27.5):
		FX.stat("enemy_recalls")
		var a := randf() * TAU
		recall(Vector3(sin(a) * 16.0, 0.3, cos(a) * 16.0))
		return
	var d := delta * FX.enemy_time
	_zap_cd = max(0.0, _zap_cd - delta)
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
			var k: float = clamp(_t / _tv("windup"), 0.0, 1.0)
			_warn_mat.albedo_color = Color(COL_WARN, 0.25 + 0.75 * k)
			_warn.scale = Vector3.ONE * (lerp(1.2, 3.0, k) if arch == "brute" else lerp(2.2, 0.9, k))
			if arch == "conduit":
				_mat.emission_enabled = true
				_mat.emission = Color(0.5, 0.95, 1.0)
				_mat.emission_energy_multiplier = 2.0 * k
			_visual.position.z = 0.25 * k
			_visual.rotation.x = 0.25 * k
			if _t >= _tv("windup"):
				_attack_dir = _flat(player.global_position - global_position).normalized()
				_attack_resolved = false
				if arch == "conduit" and boss:
					_shots += 1
					if _shots % 3 == 0:
						_pylon_strike()
					else:
						_volley()
					_set_state(S.RECOVER)
				elif arch == "conduit":
					_fire_orb()
					_set_state(S.RECOVER)
				elif arch == "brute":
					_slam()
					_set_state(S.ATTACK)
				else:
					_set_state(S.ATTACK)
		S.ATTACK:
			velocity.x = _attack_dir.x * _tv("lunge_speed")
			velocity.z = _attack_dir.z * _tv("lunge_speed")
			_visual.position.z = -0.3
			_visual.rotation.x = -0.3
			if not _attack_resolved and arch == "scout":
				var to := _flat(player.global_position - global_position)
				if to.length() < 1.7 and to.normalized().dot(_attack_dir) > 0.2:
					_attack_resolved = true
					var r: String = player.take_hit(self, _tv("damage"), _attack_dir)
					if r == "perfect":
						_set_state(S.RECOVER)
						_t = -0.6
			if state == S.ATTACK and _t >= _tv("active"):
				_set_state(S.RECOVER)
		S.RECOVER:
			velocity.x = move_toward(velocity.x, 0, 40 * d)
			velocity.z = move_toward(velocity.z, 0, 40 * d)
			_visual.position.z = lerp(_visual.position.z, 0.0, 0.2)
			_visual.rotation.x = lerp(_visual.rotation.x, 0.0, 0.2)
			if _t >= _tv("recover"):
				_cooldown = randf_range(_tv("cooldown_min"), _tv("cooldown_max"))
				_set_state(S.CHASE)
		S.HITSTUN, S.STAGGER:
			# scivola sul pavimento: più pesante = si ferma prima
			var fr: float = (22.0 if is_on_floor() else 5.0) * sqrt(weight)
			velocity.x = move_toward(velocity.x, 0, fr * d)
			velocity.z = move_toward(velocity.z, 0, fr * d)
			if _t >= (0.32 if state == S.HITSTUN else (2.4 if boss else (2.0 if arch == "brute" else 1.3))) and is_on_floor():
				if state == S.STAGGER:
					poise = max_poise
				_set_state(S.CHASE)
		S.AIR:
			velocity.x = move_toward(velocity.x, 0, 4 * d)
			velocity.z = move_toward(velocity.z, 0, 4 * d)
			_visual.rotation.x += _tumble * d
			if is_on_floor() and _t > 0.15:
				if _prev_vy < -8.0 and not _bounced:
					# cade forte: un rimbalzo basso, dà peso al corpo
					_bounced = true
					velocity.y = min(-_prev_vy * 0.3, 5.5) / sqrt(weight)
					_tumble *= 0.5
					FX.ring(global_position, Color(1, 1, 1, 0.5), 1.5, 0.2)
					FX.sound("colpo_forte", 0.6, -10.0)
					FX.stat("enemy_bounces")
				else:
					FX.ring(global_position, Color(1, 1, 1, 0.4), 1.2, 0.2)
					_set_state(S.HITSTUN)
					_tumble = 0.0
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
	if state != S.AIR and state != S.WINDUP and state != S.ATTACK and state != S.DEAD:
		_visual.rotation.x = lerp_angle(_visual.rotation.x, 0.0, clamp(12.0 * delta, 0.0, 1.0))
	# non si infila dentro il giocatore: spinta morbida verso fuori
	if state != S.DEAD and player and is_instance_valid(player):
		var away := _flat(global_position - player.global_position)
		var gap: float = radius + 0.5 - away.length()
		if gap > 0.0 and state != S.ATTACK:
			var n: Vector3 = away.normalized() if away.length() > 0.05 else Vector3.RIGHT
			velocity.x += n.x * gap * 30.0 * d
			velocity.z += n.z * gap * 30.0 * d
	_prev_vy = velocity.y
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
	_tick_white(delta)

## Ogni danno (colpi, fuoco, scosse) ferma il bianco; dopo la pausa scivola giù fino al rosso.
func _tick_white(delta: float) -> void:
	if hp < _hp_seen:
		hit_chain = hit_chain + 1 if _white_hold > 0.0 else 1   # 0.18: colpi di fila ("N HITS")
		_white_hold = WHITE_HOLD
	_hp_seen = hp
	if _white_hold > 0.0:
		_white_hold -= delta
	else:
		hp_white = move_toward(hp_white, max(hp, 0.0), max_hp * 0.9 * delta)

func _chase(d: float) -> void:
	if player == null or player.get("state") == 4:
		velocity.x = move_toward(velocity.x, 0, 20 * d)
		velocity.z = move_toward(velocity.z, 0, 20 * d)
		return
	_cooldown -= d
	var to := _flat(player.global_position - global_position)
	var dist := to.length()
	if boss and arch == "conduit" and _tick_pulse(d, dist):
		return
	var dir := to.normalized()
	var want: Vector3
	if dist > _tv("attack_range") + 1.5:
		want = dir * _tv("speed")
	else:
		# gira intorno al giocatore aspettando il momento
		var side := Vector3(-dir.z, 0, dir.x) * _strafe
		want = side * _tv("speed") * 0.45 + dir * (dist - _tv("attack_range")) * 1.5
		if _cooldown <= 0.0 and dist < _tv("attack_range") + 1.6:
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

## BRUTE: schianto ad area davanti a sé.
func _slam() -> void:
	var c := global_position + _attack_dir * (1.6 if boss else 1.0)
	var r := 4.5 if boss else 3.0
	FX.ring(c, Color(1, 0.6, 0.2, 0.9), r, 0.3)
	FX.shake(0.9 if boss else 0.6)
	if boss:
		_shockwave(c)
	FX.sound("colpo_finale", 0.6)
	FX.sparks(c, Vector3.UP, Color(1, 0.6, 0.2), 12, 8.0)
	var to := _flat(player.global_position - c)
	if to.length() < r and absf(player.global_position.y - global_position.y) < 1.6:
		player.take_hit(self, _tv("damage"), to.normalized() if to.length() > 0.1 else _attack_dir)
	for p in get_tree().get_nodes_in_group("props"):
		if p.center().distance_to(c) < r:
			p.structure_damage(25.0)
	_attack_resolved = true

## COLOSSO: dopo la botta parte un'onda a terra che si allarga. Si evita saltando (o con una schivata perfetta).
func _shockwave(c: Vector3) -> void:
	var hit := [false]
	for k in 3:
		var rr := 6.0 + k * 3.0
		get_tree().create_timer(0.12 + k * 0.12, false).timeout.connect(func():
			if state == S.DEAD or not is_instance_valid(player):
				return
			FX.ring(c, Color(1, 0.45, 0.2, 0.7), rr, 0.25)
			var d := _flat(player.global_position - c).length()
			var grounded: bool = player.is_on_floor() and player.global_position.y - c.y < 0.6
			# solo fuori dalla botta: chi l'ha già presa non viene colpito due volte
			if not hit[0] and grounded and d > maxf(rr - 3.2, 4.6) and d < rr + 0.4:
				hit[0] = true
				player.take_hit(self, _tv("damage") * 0.45, _flat(player.global_position - c).normalized()))

## CONDUIT: sfera elettrica. Mira al giocatore o all'ambiente vicino a lui.
func _fire_orb() -> void:
	_mat.emission_enabled = false
	var aim: Vector3 = player.global_position + Vector3(0, 0.9, 0)
	var pi := El.puddle_at(player.global_position, 0.6)
	if pi >= 0 and randf() < 0.75:
		aim = El.puddles[pi].pos + Vector3(0, 0.2, 0)
		FX.stat("conduit_env_shots")
	else:
		for pr in get_tree().get_nodes_in_group("props"):
			if (pr.get("explosive") or pr.get("kind") == "coil") and pr.center().distance_to(player.global_position) < 3.2 and not pr.is_dead():
				aim = pr.center()
				FX.stat("conduit_env_shots")
				break
	var o := Orb.new()
	FX._world.add_child(o)
	var from := global_position + Vector3(0, 1.6, 0)
	o.fire(from, aim, self, _tv("damage"))
	FX.sound("critico", 1.8, -4.0)
	FX.stat("orbs_fired")

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
	_bounced = false
	_tumble = 9.0 * (-1.0 if randf() < 0.5 else 1.0)
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
	if state != S.DEAD and is_on_floor() and not boss:
		_set_state(S.STAGGER)
		_t = 0.35
	_mat.emission_enabled = true
	_mat.emission = Color(0.5, 0.95, 1.0)
	_mat.emission_energy_multiplier = 2.0
	_hit_flash = 0.18
	FX.stat("enemies_shocked")
	if arch == "conduit" and not boss and _zap_cd <= 0.0 and state != S.DEAD:
		# il Conduit scosso si scarica su chi gli sta intorno
		_zap_cd = 1.5
		FX.stat("conduit_overloads")
		var at := global_position
		get_tree().create_timer(0.12).timeout.connect(func(): El.shock(at, self, 1.3))

## TRALICCIO: tre sfere a ventaglio. Si rimandano con SPINGI o con la parata della BLADE.
func _volley() -> void:
	_mat.emission_enabled = false
	var from := global_position + Vector3(0, 2.6, 0)
	var aim: Vector3 = player.global_position + Vector3(0, 0.9, 0)
	var base := aim - from
	for i in 3:
		var o := Orb.new()
		FX._world.add_child(o)
		var dir := base.rotated(Vector3.UP, deg_to_rad((i - 1) * 16.0))
		o.fire(from, from + dir, self, _tv("damage"))
	FX.sound("critico", 1.4, -2.0)
	FX.stat("boss_volleys")

## TRALICCIO: quattro scariche a terra intorno al giocatore, annunciate da anelli. Basta spostarsi.
func _pylon_strike() -> void:
	_mat.emission_enabled = false
	var c := player.global_position
	var spots := [c]
	var a0 := randf() * TAU
	for i in 3:
		var a := a0 + i * TAU / 3.0
		spots.append(c + Vector3(sin(a), 0, cos(a)) * 3.2)
	for p in spots:
		FX.ring(p, Color(0.5, 0.95, 1.0, 0.9), 1.8, 0.9)
	FX.sound("scudo", 0.8, -4.0)
	FX.stat("boss_strikes")
	get_tree().create_timer(0.9, false).timeout.connect(func():
		if state == S.DEAD:
			return
		for p in spots:
			El.shock(p + Vector3(0, 0.1, 0), self, 0.8, true)
		FX.shake(0.5))

## TRALICCIO: se gli stai addosso troppo a lungo si carica (anello largo) e scarica tutto intorno, poi sparisce
## lontano. Si evita allontanandosi o con la schivata perfetta. Vero se in questo frame sta facendo l'impulso.
func _tick_pulse(d: float, dist: float) -> bool:
	if _pulse_t > 0.0:
		_pulse_t -= d
		velocity.x = move_toward(velocity.x, 0, 30 * d)
		velocity.z = move_toward(velocity.z, 0, 30 * d)
		var k: float = 1.0 - _pulse_t / 0.8
		_warn_mat.albedo_color = Color(0.5, 0.95, 1.0, 0.3 + 0.7 * k)
		_warn.scale = Vector3.ONE * 4.2
		_mat.emission_enabled = true
		_mat.emission = Color(0.5, 0.95, 1.0)
		_mat.emission_energy_multiplier = 3.0 * k
		if _pulse_t <= 0.0:
			_mat.emission_enabled = false
			FX.ring(global_position, Color(0.5, 0.95, 1.0, 0.9), 4.2, 0.3)
			FX.sound("critico", 0.9)
			if _flat(player.global_position - global_position).length() < 4.4:
				player.take_hit(self, _tv("damage") * 1.2, _flat(player.global_position - global_position).normalized())
			var a := randf() * TAU
			var to := Vector3(sin(a) * 15.0, 0.3, cos(a) * 15.0)
			if to.distance_to(player.global_position) < 9.0:
				to = Vector3(-to.x, to.y, -to.z)
			global_position = to
			FX.ring(to, Color(0.5, 0.95, 1.0, 0.8), 3.0, 0.4)
			FX.stat("boss_blinks")
			_close_t = 0.0
			_cooldown = 0.8
		return true
	_close_t = _close_t + d if dist < 3.6 else maxf(0.0, _close_t - d * 0.5)
	if _close_t > 2.4:
		_pulse_t = 0.8
		FX.sound("scudo", 0.6, -2.0)
		return true
	return false

## TRALICCIO: una sua sfera rimandata indietro lo colpisce in pieno e gli toglie tanto equilibrio.
func orb_backfire() -> void:
	if state == S.DEAD:
		return
	FX.stat("boss_backfires")
	FX.shake(0.5)
	receive_hit({"dmg": max_hp * 0.06, "poise": max_poise * 0.4, "dir": Vector3.ZERO, "knock": 0.0, "launch": 0.0, "form": -1, "move": "backfire"})

## Riceve un colpo del giocatore (dati dalla tabella delle mosse).
func receive_hit(info: Dictionary) -> void:
	if state == S.DEAD:
		return
	hp -= info.dmg
	# 0.18: numeri dei danni (li disegna la HUD, scripts/ui/enemy_bars.gd)
	if info.dmg >= 1.0:
		get_tree().call_group("dmg_pops", "pop", global_position + Vector3(0, 2.0 if arch == "brute" else 1.6, 0) * (1.6 if boss else 1.0), info.dmg, info.dmg >= 18.0)
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
		velocity.x = to.x * 6.0 / weight
		velocity.z = to.z * 6.0 / weight
		velocity.y = 3.0
		_set_state(S.HITSTUN)
		_t = -0.15
	else:
		velocity.x = dir.x * kb
		velocity.z = dir.z * kb
		# colpo forte: vola e può sbattere contro muri e altri nemici
		if kb > 8.0:
			_power_fly = max(_power_fly, 0.45)
			_hit_by.clear()
	var interrupted := state == S.WINDUP or state == S.ATTACK
	if (arch == "brute" or boss) and poise > 0.0 and state != S.STAGGER and state != S.AIR and not info.has("pull_to"):
		# corazza: incassa senza fermarsi finché non perde l'equilibrio
		velocity.x *= 0.25
		velocity.z *= 0.25
		interrupted = false
		_visual.scale = Vector3(1.1, 0.92, 1.1)
		create_tween().tween_property(_visual, "scale", Vector3.ONE, 0.12)
		if charged and info.get("move", "") != "blast":
			charged = false
			_mat.emission_enabled = false
			FX.overcharge_blast(global_position + Vector3(0, 0.8, 0), self)
		if hp <= 0.0:
			_die(dir)
		return
	if info.launch > 0.0 and (info.launch > 6.0 or not is_on_floor()):
		velocity.y = info.launch / sqrt(weight)
		if state != S.AIR:
			_bounced = false
		_set_state(S.AIR)
		_tumble = clamp(info.launch * 0.9 + kb * 0.4, 0.0, 12.0) * (-1.0 if randf() < 0.5 else 1.0)
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
	if burn_t > 0.0 and Run.has("fuoco_vivo"):
		var at := global_position + Vector3(0, 0.8, 0)
		FX.stat("up_fire_bursts")
		get_tree().create_timer(0.05).timeout.connect(func(): El.ignite_area(at, 2.8, self))
	burn_t = 0.0
	_set_state(S.DEAD)
	remove_from_group("enemies")
	collision_layer = 0
	velocity = dir * 9.0 + Vector3(0, 7.0, 0)
	FX.sound("ko", 1.2)
	FX.stat("kills")
	FX.sparks(global_position + Vector3(0, 1, 0), Vector3.UP, ARCH[arch].col, 16, 9.0)
	if boss:
		remove_from_group("boss")
		FX.shake(1.2)
		FX.speed_lines(700)
		FX.ring(global_position, Color(1, 0.6, 0.2, 0.9), 7.0, 0.5)
		FX.sparks(global_position + Vector3(0, 2, 0), Vector3.UP, Color(1, 0.6, 0.2), 30, 14.0)
		FX.stat("boss_kills")
	_bar.visible = false
	_bar_bg.visible = false
	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_property(_visual, "scale", Vector3.ZERO, 0.25)
	t.tween_callback(func():
		died.emit(self)
		queue_free())

func _update_bar() -> void:
	# 0.16: la barra sopra la testa ora la disegna la HUD (scripts/ui/enemy_bars.gd): questa resta spenta
	var show := false
	_bar.visible = show
	_bar_bg.visible = show
	if show:
		var k: float = clamp(hp / max_hp, 0.0, 1.0)
		_bar.scale.x = max(k, 0.001)
