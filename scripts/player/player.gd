extends CharacterBody3D
## Protagonista di OVERLOAD (Fase 1: movimento, salto, schivata, combo, arma a tre forme).
## Tutto ciò che si regola sta in `tune`: il pannello del laboratorio lo modifica dal vivo.

const M = preload("res://scripts/player/moves.gd")
const WeaponView = preload("res://scripts/player/weapon_view.gd")

signal hp_changed(hp: float, max_hp: float)
signal form_changed(form: int)
signal perfect_dodge
signal died

enum S { MOVE, ATTACK, DODGE, HURT, DEAD }

var tune := {
	"run_speed": 7.8,
	"accel": 60.0,
	"decel": 45.0,
	"air_control": 0.6,
	"turn_speed": 16.0,
	"jump": 10.0,
	"gravity": 28.0,
	"fall_mult": 1.55,
	"dodge_speed": 17.0,
	"dodge_time": 0.22,
	"iframe": 0.26,
	"perfect_window": 0.18,
	"assist_range": 7.5,
	"assist_angle": 80.0,
}

var cam: Node3D                   # rig della telecamera (yaw)
var enemies_root: Node
var max_hp := 100.0
var hp := 100.0
var state := S.MOVE
var facing := Vector3.FORWARD
var lock_target: Node3D

var move_id := ""
var move: Dictionary = {}
var move_t := 0.0
var _hit_list: Array = []
var _hit_any := false
var _trail_done := false
var _slam_landed := false
var _move_press_ms := 0           # pressione che ha avviato la mossa
var _heavy_fired_press := -1
var _last_move_id := ""
var _last_move_end := 0
var _buffer := ""
var _buffer_until := 0
var _jump_buffer_until := 0
var _coyote_until := 0
var _air_attacks := 0
var _air_dodge_used := false
var _jump_cut := false
var _was_on_floor := true
var _fall_speed := 0.0

var _dodge_dir := Vector3.ZERO
var _dodge_t := 0.0
var _dodge_start := -100000
var _last_dodge_end := -100000
var _hurt_t := 0.0
var _counter_ready := false
var _multi_done := false
# potenziamenti della run
var _combo_hits := 0
var _air_hits := 0
var _heavy_ready := false
var _vshock_at := 0

var visual: Node3D
var weapon: Node3D
var _body_mat: StandardMaterial3D
var _band_mat: StandardMaterial3D
var _body_parts: Array[MeshInstance3D] = []

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 16
	floor_snap_length = 0.3
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.75
	col.shape = cap
	col.position.y = 0.875
	add_child(col)
	_build_visual()
	hp = max_hp

func _build_visual() -> void:
	visual = Node3D.new()
	add_child(visual)
	_body_mat = StandardMaterial3D.new()
	_body_mat.albedo_color = Color(0.12, 0.13, 0.2)
	_band_mat = StandardMaterial3D.new()
	_band_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_band_mat.albedo_color = M.FORM_COLOR[0]
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.36
	cm.height = 1.45
	body.mesh = cm
	body.position.y = 0.78
	body.material_override = _body_mat
	visual.add_child(body)
	_body_parts.append(body)
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.24
	sm.height = 0.48
	head.mesh = sm
	head.position.y = 1.68
	head.material_override = _body_mat
	visual.add_child(head)
	_body_parts.append(head)
	var visor := MeshInstance3D.new()
	var vb := BoxMesh.new()
	vb.size = Vector3(0.34, 0.08, 0.12)
	visor.mesh = vb
	visor.position = Vector3(0, 1.7, -0.2)
	visor.material_override = _band_mat
	visual.add_child(visor)
	var band := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(0.76, 0.1, 0.76)
	band.mesh = bb
	band.position.y = 1.12
	band.material_override = _band_mat
	visual.add_child(band)
	weapon = WeaponView.new()
	visual.add_child(weapon)

# ---------------------------------------------------------------- ciclo

func _physics_process(delta: float) -> void:
	if state == S.DEAD:
		velocity.y -= tune.gravity * delta
		velocity.x = move_toward(velocity.x, 0, 20 * delta)
		velocity.z = move_toward(velocity.z, 0, 20 * delta)
		move_and_slide()
		return
	var on_floor := is_on_floor()
	var now := Time.get_ticks_msec()
	if on_floor:
		_coyote_until = now + 120
		_air_attacks = 0
		_air_dodge_used = false
	_read_actions(now)
	match state:
		S.MOVE:
			_update_move(delta, on_floor, now)
		S.ATTACK:
			_update_attack(delta, on_floor, now)
		S.DODGE:
			_update_dodge(delta)
		S.HURT:
			_hurt_t -= delta
			velocity.x = move_toward(velocity.x, 0, 30 * delta)
			velocity.z = move_toward(velocity.z, 0, 30 * delta)
			_apply_gravity(delta, 1.0)
			if _hurt_t <= 0:
				state = S.MOVE
	move_and_slide()
	_landing_feel(on_floor)
	_update_visual(delta)
	if lock_target and (not is_instance_valid(lock_target) or lock_target.is_dead()):
		lock_target = null

func _read_actions(now: int) -> void:
	if Pad.just("jump"):
		_jump_buffer_until = now + 150
	if Pad.just("lock"):
		toggle_lock()
	if Pad.just("dodge"):
		_request("dodge", now)
	if Pad.just("attack"):
		_request("light", now)
	# pesante: si tiene premuto; se la leggera appena partita è ancora in caricamento, si trasforma
	if Pad.held("attack") and Pad.held_time("attack") >= 0.2 and _heavy_fired_press != Pad._pressed_at["attack"]:
		_heavy_fired_press = Pad._pressed_at["attack"]
		if state == S.ATTACK and _move_press_ms == Pad._pressed_at["attack"] and move_t < move.hit_from + 0.12 and move_id.begins_with("blade"):
			_start_move(_pick_move("heavy"), now)
		else:
			_request("heavy", now)

## Prova a eseguire subito; se non si può, tiene l'azione in coda per poco.
func _request(kind: String, now: int) -> void:
	if state == S.HURT or state == S.DEAD:
		_buffer = kind
		_buffer_until = now + 200
		return
	if _can_act_now(kind):
		_do(kind, now)
	else:
		_buffer = kind
		_buffer_until = now + 260

func _can_act_now(kind: String) -> bool:
	match state:
		S.MOVE:
			return true
		S.ATTACK:
			if kind == "dodge":
				return move_t >= move.cancel or move_t < 0.04 or _hit_any and move_t >= move.hit_to
			return move_t >= move.cancel
		S.DODGE:
			# attacco dalla schivata: si può uscire quasi subito (diventa VECTOR sweep)
			return kind != "dodge" and _dodge_t >= tune.dodge_time * 0.55
	return false

func _do(kind: String, now: int) -> void:
	_buffer = ""
	if kind == "dodge":
		_start_dodge(now)
	else:
		if state == S.DODGE:
			_last_dodge_end = now
		_start_move(_pick_move(kind), now)

func _try_buffer(now: int) -> void:
	if _buffer != "" and now <= _buffer_until and _can_act_now(_buffer):
		_do(_buffer, now)
	elif now > _buffer_until:
		_buffer = ""

# ---------------------------------------------------------------- movimento

func input_dir() -> Vector3:
	var m: Vector2 = Pad.move
	if m.length() < 0.12:
		return Vector3.ZERO
	var yaw: float = cam.get_yaw() if cam else 0.0
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var d := right * m.x + fwd * m.y
	return d.normalized() * min(1.0, m.length())

func _update_move(delta: float, on_floor: bool, now: int) -> void:
	var dir := input_dir()
	var target: Vector3 = dir * tune.run_speed
	var hv := Vector3(velocity.x, 0, velocity.z)
	var acc: float = tune.accel if dir != Vector3.ZERO else tune.decel
	if not on_floor:
		acc *= tune.air_control
	hv = hv.move_toward(target, acc * delta)
	velocity.x = hv.x
	velocity.z = hv.z
	if dir != Vector3.ZERO:
		_turn_towards(dir, tune.turn_speed * delta)
	# salto con tolleranza (coyote) e memoria del tasto
	if now <= _jump_buffer_until and now <= _coyote_until:
		velocity.y = tune.jump
		_jump_buffer_until = 0
		_coyote_until = 0
		_jump_cut = false
		_squash(Vector3(0.8, 1.25, 0.8))
		FX.stat("jumps")
	if not Pad.held("jump") and velocity.y > 0 and not _jump_cut:
		velocity.y *= 0.55
		_jump_cut = true
	_apply_gravity(delta, 1.0)
	_try_buffer(now)

func _apply_gravity(delta: float, mult: float) -> void:
	var g: float = tune.gravity * mult
	if velocity.y < 0:
		g *= tune.fall_mult
	velocity.y = max(velocity.y - g * delta, -40.0)

func _turn_towards(dir: Vector3, step: float) -> void:
	var a := atan2(facing.x, facing.z)
	var b := atan2(dir.x, dir.z)
	var na := lerp_angle(a, b, clamp(step, 0.0, 1.0))
	facing = Vector3(sin(na), 0, cos(na))

func _landing_feel(on_floor: bool) -> void:
	if not on_floor:
		_fall_speed = min(_fall_speed, velocity.y)
	if on_floor and not _was_on_floor:
		if _fall_speed < -9.0:
			_squash(Vector3(1.25, 0.75, 1.25))
			FX.ring(global_position, Color(1, 1, 1, 0.5), 1.4, 0.25)
		_fall_speed = 0.0
	_was_on_floor = on_floor

# ---------------------------------------------------------------- attacchi

func _pick_move(kind: String) -> String:
	var now := Time.get_ticks_msec()
	var airborne := not is_on_floor()
	if _counter_ready and FX.is_slowed():
		_counter_ready = false
		return "impact_counter"
	if kind == "heavy":
		return "impact_slam" if airborne and global_position.y > 1.2 else "impact_launcher"
	if airborne:
		if state == S.ATTACK and move.get("air", false) and move.next != "":
			return move.next
		if _air_attacks < 3:
			return "blade_air_1"
		return "blade_air_3"
	if now - _last_dodge_end < 260:
		return "vector_sweep"
	var t := _best_target(true)
	if t:
		var to_t := _flat(t.global_position - global_position)
		var d := to_t.length()
		var back := input_dir()
		# stick tirato all'indietro rispetto al nemico: VECTOR lo frusta verso di te
		if back != Vector3.ZERO and d > 2.2 and d < 6.8 and back.normalized().dot(to_t.normalized()) < -0.5:
			return "vector_reel"
		if d > 4.2 and d < 11.5:
			return "vector_lash"
	if state == S.ATTACK and move.next != "":
		return move.next
	if _last_move_id != "" and now - _last_move_end < 450:
		var last: Dictionary = M.DATA[_last_move_id]
		if last.next != "" and not last.get("air", false):
			return last.next
	return "blade_1"

func _start_move(id: String, now: int) -> void:
	move_id = id
	move = M.DATA[id]
	move_t = 0.0
	_hit_list.clear()
	_hit_any = false
	_trail_done = false
	_multi_done = false
	_slam_landed = false
	_move_press_ms = Pad._pressed_at["attack"]
	state = S.ATTACK
	_buffer = ""
	if weapon.set_form(move.form):
		form_changed.emit(move.form)
		_band_mat.albedo_color = M.FORM_COLOR[move.form]
		FX.stat("form_" + M.FORM_NAME[move.form].to_lower())
		# la trasformazione si vede e si sente: lampo del colore della forma
		_flash(M.FORM_COLOR[move.form])
		FX.ring(global_position, Color(M.FORM_COLOR[move.form], 0.7), 1.3, 0.18)
		FX.sound("cutin", 1.6 + 0.2 * move.form, -12.0)
	FX.stat("move_" + id)
	if id == "blade_3" and Run.has("lama_eco"):
		get_tree().create_timer(0.1, false).timeout.connect(_echo_slash)
	# aiuto alla mira: ci si gira subito verso il bersaglio
	var t := _best_target(false)
	if t:
		var to := _flat(t.global_position - global_position)
		if to.length() > 0.1:
			facing = to.normalized()
	else:
		var d := input_dir()
		if d != Vector3.ZERO:
			facing = d.normalized()
	weapon.swing(move.swing, move.hit_from, max(0.06, move.hit_to - move.hit_from + 0.04))
	if move.form == M.Form.IMPACT and move.hit_from > 0.1:
		weapon.charge(move.hit_from)
	if move.get("air", false):
		_air_attacks += 1
		velocity.y = max(velocity.y, 2.2)
	if move.get("slam", false):
		velocity = Vector3(facing.x * 3.0, -24.0, facing.z * 3.0)
		_squash(Vector3(0.8, 1.3, 0.8))
	if id == "impact_launcher":
		_squash(Vector3(1.2, 0.85, 1.2))

func _update_attack(delta: float, on_floor: bool, now: int) -> void:
	move_t += delta
	var target: Node3D = _best_target(false)
	# avanzamento verso il bersaglio fino al colpo, senza sorpassarlo
	if move.get("slam", false):
		if not _slam_landed:
			move_t = min(move_t, 0.05)
			if on_floor:
				_slam_landed = true
				move_t = 0.3
				_do_hits(true)
			velocity.y = -24.0
		else:
			velocity.x = move_toward(velocity.x, 0, 40 * delta)
			velocity.z = move_toward(velocity.z, 0, 40 * delta)
	else:
		var lunge: float = move.lunge
		if target:
			var d := _flat(target.global_position - global_position).length()
			if d < move.reach * 0.55:
				lunge = 0.0
		var hv := Vector3(velocity.x, 0, velocity.z)
		if move_t < move.hit_to and lunge > 0:
			hv = hv.move_toward(facing * lunge, 120 * delta)
		else:
			hv = hv.move_toward(Vector3.ZERO, 50 * delta)
		velocity.x = hv.x
		velocity.z = hv.z
		if move.get("air", false):
			_apply_gravity(delta, 0.22)
		else:
			_apply_gravity(delta, 1.0)
		if move_t >= move.hit_from and move_t <= move.hit_to:
			if not _trail_done:
				_trail_done = true
				if move_id == "vector_lash":
					var end: Vector3 = global_position + Vector3(0, 1.1, 0) + facing * move.reach
					if target:
						end = target.global_position + Vector3(0, 1.0, 0)
					weapon.show_line(global_position + Vector3(0, 1.15, 0), end, 0.14)
				else:
					weapon.trail(move.form, move.reach, move.arc)
			_do_hits(false)
	# IMPACT launcher: se tieni premuto, salti dietro al nemico lanciato
	if move.get("follow", false) and _hit_any and on_floor and move_t >= move.cancel and Pad.held("attack"):
		_end_move(now)
		velocity.y = tune.jump * 1.2
		_jump_cut = true
		_squash(Vector3(0.75, 1.3, 0.75))
		_afterimage()
		FX.stat("launch_follow")
		return
	if move_t >= move.cancel:
		_try_buffer(now)
	if state == S.ATTACK and move_t >= move.dur:
		_end_move(now)

func _end_move(now: int) -> void:
	_last_move_id = move_id
	_last_move_end = now
	state = S.MOVE
	weapon.rest()

func _do_hits(slam: bool) -> void:
	if enemies_root == null:
		return
	var first_hit := not _hit_any
	for e in enemies_root.get_children() + get_tree().get_nodes_in_group("props"):
		if not e.has_method("receive_hit") or e.is_dead() or _hit_list.has(e):
			continue
		if e.has_method("hold") and e.state == 2:
			continue
		var to: Vector3 = e.global_position - global_position
		var flat := _flat(to)
		var dist := flat.length()
		var dy: float = absf(to.y)
		if dy > 2.4:
			continue
		var r: float = move.reach + e.radius
		if move_id == "vector_lash":
			var along := flat.dot(facing)
			var side := (flat - facing * along).length()
			if along < 0 or along > r or side > 1.2 + e.radius:
				continue
		else:
			if dist > r:
				continue
			if move.arc < 360.0 and dist > 1.0:
				var ang := rad_to_deg(facing.angle_to(flat.normalized()))
				if ang > move.arc * 0.5:
					continue
		_hit_list.append(e)
		_hit_any = true
		var kdir := flat.normalized() if dist > 0.05 else facing
		var info := {
			"dmg": move.dmg, "poise": move.poise, "dir": kdir, "knock": move.knock,
			"launch": move.launch, "form": move.form, "move": move_id,
		}
		if move.get("pull", false):
			info["pull_to"] = global_position + facing * 1.8
		var is_enemy: bool = e.is_in_group("enemies")
		if is_enemy and _heavy_ready and move.form == M.Form.IMPACT:
			info.dmg *= 2.0
			info.poise *= 2.0
			FX.ring(e.global_position, Color(1, 0.6, 0.2, 0.95), 3.5, 0.35)
			_wave_at(e.global_position, 3.5, e)
			FX.stat("up_heavy_drops")
		e.receive_hit(info)
		if is_enemy:
			_upgrade_hit(e)
		FX.sparks(e.global_position + Vector3(0, 1.0, 0), -kdir, M.FORM_COLOR[move.form], 9, 8.0)
		FX.stat("hits")
		if not is_on_floor():
			velocity.y = max(velocity.y, 3.2)
	if _hit_any and move.form == M.Form.IMPACT:
		_heavy_ready = false
		_air_hits = 0
	if _hit_any and first_hit:
		OV.feed("move:" + move_id, "weapon_%d" % move.form, 5.0)
		FX.hitstop(move.stop)
		FX.shake(move.shake)
		FX.sound(move.sound, M.FORM_PITCH[move.form])
		if move.form == M.Form.IMPACT:
			FX.ring(global_position + facing * 1.4, Color(1, 0.75, 0.4, 0.7), 1.6, 0.22)
		if move.has("ring"):
			FX.ring(global_position, Color(M.FORM_COLOR[move.form], 0.8), move.ring, 0.3)
	elif slam:
		FX.shake(move.shake * 0.6)
		FX.sound("colpo_forte", 0.8)
		FX.ring(global_position, Color(M.FORM_COLOR[move.form], 0.8), move.ring, 0.3)

# ---------------------------------------------------------------- potenziamenti

func _upgrade_hit(e: Node3D) -> void:
	_combo_hits += 1
	if Run.has("catena_combo") and _combo_hits % 10 == 0:
		_resonance()
	if move.form == M.Form.IMPACT and Run.has("onda_urto"):
		_wave_at(e.global_position, 2.4, e)
	if move_id.begins_with("blade_air"):
		_air_hits += 1
		if _air_hits >= 2 and Run.has("impatto_aereo") and not _heavy_ready:
			_heavy_ready = true
			_flash(Color(1, 0.6, 0.2))
	if move.form == M.Form.VECTOR:
		if Run.has("catena_doppia") and (move_id == "vector_lash" or move_id == "vector_reel"):
			var best: Node3D = null
			var bd := 4.5
			for o in get_tree().get_nodes_in_group("enemies"):
				if o == e or o.is_dead() or _hit_list.has(o):
					continue
				var d: float = o.global_position.distance_to(e.global_position)
				if d < bd:
					bd = d
					best = o
			if best:
				_hit_list.append(best)
				best.power_pull(global_position + facing * 2.2)
				FX.stat("up_double_chain")
		if Run.has("vector_scossa") and Time.get_ticks_msec() > _vshock_at:
			_vshock_at = Time.get_ticks_msec() + 600
			El.shock(e.global_position, null, 0.6)
			FX.stat("up_vector_shocks")

## Onda attorno a un punto che colpisce gli altri nemici.
func _wave_at(c: Vector3, r: float, skip: Node) -> void:
	FX.ring(c, Color(1, 0.75, 0.4, 0.8), r, 0.25)
	for o in get_tree().get_nodes_in_group("enemies"):
		if o == skip or o.is_dead() or _hit_list.has(o):
			continue
		var to: Vector3 = _flat(o.global_position - c)
		if to.length() < r:
			o.receive_hit({"dmg": 8.0, "poise": 25.0, "dir": to.normalized() if to.length() > 0.1 else facing, "knock": 6.0, "launch": 0.0, "form": M.Form.IMPACT, "move": "wave"})
			FX.stat("up_wave_hits")

## Fendente d'eco: taglia in linea retta davanti.
func _echo_slash() -> void:
	if state == S.DEAD:
		return
	var from := global_position + Vector3(0, 1.0, 0)
	for k in 5:
		FX.sparks(from + facing * (1.5 + k * 1.3), facing, M.FORM_COLOR[0], 3, 6.0)
	for o in get_tree().get_nodes_in_group("enemies"):
		if o.is_dead():
			continue
		var to: Vector3 = _flat(o.global_position - global_position)
		var along := to.dot(facing)
		var side := (to - facing * along).length()
		if along > 0.5 and along < 7.0 and side < 1.0 + o.radius:
			o.receive_hit({"dmg": 12.0, "poise": 20.0, "dir": facing, "knock": 4.0, "launch": 0.0, "form": M.Form.BLADE, "move": "eco"})
			FX.stat("up_echo_hits")
	FX.sound("colpo", 1.6, -4.0)

## Risonanza: onda che parte dal giocatore ogni 10 colpi puliti.
func _resonance() -> void:
	FX.ring(global_position, Color(0.6, 1.0, 1.0, 0.9), 3.5, 0.3)
	FX.sound("break", 1.3, -3.0)
	FX.shake(0.4)
	for o in get_tree().get_nodes_in_group("enemies"):
		var to: Vector3 = _flat(o.global_position - global_position)
		if not o.is_dead() and to.length() < 3.5:
			o.receive_hit({"dmg": 12.0, "poise": 40.0, "dir": to.normalized() if to.length() > 0.1 else facing, "knock": 9.0, "launch": 4.0, "form": -1, "move": "resonance"})
	FX.stat("up_resonance")

# ---------------------------------------------------------------- schivata

func _start_dodge(now: int) -> void:
	if not is_on_floor():
		if _air_dodge_used:
			return
		_air_dodge_used = true
	if state == S.ATTACK:
		_end_move(now)
	var d := input_dir()
	_dodge_dir = d.normalized() if d != Vector3.ZERO else -facing
	if d != Vector3.ZERO:
		facing = _dodge_dir
	_dodge_t = 0.0
	_dodge_start = now
	state = S.DODGE
	velocity = _dodge_dir * tune.dodge_speed
	velocity.y = 0.0
	_afterimage()
	FX.sound("schivata", 1.1, -4.0)
	FX.stat("dodges")
	if cam and cam.has_method("kick"):
		cam.kick(4.0)
	# schivata all'ultimo: un nemico sta già colpendo qui vicino
	if enemies_root:
		for e in enemies_root.get_children():
			if e.has_method("is_threatening") and e.is_threatening(self):
				_perfect(e)
				break

func _update_dodge(delta: float) -> void:
	_dodge_t += delta
	var k: float = clamp(_dodge_t / tune.dodge_time, 0.0, 1.0)
	var spd: float = lerp(tune.dodge_speed, tune.run_speed * 0.6, k * k)
	velocity.x = _dodge_dir.x * spd
	velocity.z = _dodge_dir.z * spd
	velocity.y = max(velocity.y - tune.gravity * 0.3 * delta, -6.0)
	if _dodge_t > tune.dodge_time * 0.5 and _dodge_t < tune.dodge_time * 0.6:
		_afterimage()
	if _dodge_t >= tune.dodge_time:
		state = S.MOVE
		_last_dodge_end = Time.get_ticks_msec()
		_try_buffer(_last_dodge_end)

func is_invulnerable() -> bool:
	return state == S.DODGE and Time.get_ticks_msec() - _dodge_start <= int(tune.iframe * 1000.0)

func _recent_dodge() -> bool:
	return Time.get_ticks_msec() - _dodge_start <= int(tune.perfect_window * 1000.0)

func _perfect(_e: Node) -> void:
	if FX.is_slowed():
		return
	FX.slow_enemies(0.22, 1.5)
	_counter_ready = true
	FX.sound("cutin", 1.2)
	FX.ring(global_position, Color(0.6, 1.0, 1.0, 0.9), 3.5, 0.35)
	FX.hitstop(60)
	FX.stat("perfect_dodges")
	perfect_dodge.emit()
	if cam and cam.has_method("kick"):
		cam.kick(9.0)

## Chiamata dai nemici quando il loro colpo arriva. Ritorna "hit", "dodged" o "perfect".
func take_hit(from: Node3D, dmg: float, dir: Vector3) -> String:
	if state == S.DEAD:
		return "dodged"
	if is_invulnerable():
		if _recent_dodge():
			_perfect(from)
			return "perfect"
		return "dodged"
	hp = max(0.0, hp - dmg)
	hp_changed.emit(hp, max_hp)
	FX.hitstop(70)
	FX.shake(0.45)
	FX.sound("ferita")
	FX.sparks(global_position + Vector3(0, 1.1, 0), dir, Color(1, 0.25, 0.3), 10, 7.0)
	FX.stat("player_hits_taken")
	OV.hurt()
	_combo_hits = 0
	_air_hits = 0
	if state == S.ATTACK:
		weapon.rest()
	velocity = _flat(dir).normalized() * 7.0 + Vector3(0, 2.0, 0)
	_hurt_t = 0.3
	state = S.HURT
	_flash(Color(1, 0.3, 0.3))
	if hp <= 0.0:
		state = S.DEAD
		FX.sound("ko")
		died.emit()
	return "hit"

func revive() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	state = S.MOVE
	velocity = Vector3.ZERO

# ---------------------------------------------------------------- bersagli

func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z)

## Bersaglio per l'aiuto alla mira: quello agganciato, altrimenti il migliore davanti.
func _best_target(far: bool) -> Node3D:
	if lock_target and is_instance_valid(lock_target) and not lock_target.is_dead():
		return lock_target
	if enemies_root == null:
		return null
	var ref := input_dir()
	if ref == Vector3.ZERO:
		ref = facing
	var best: Node3D = null
	var best_score := INF
	var max_r: float = 11.5 if far else tune.assist_range
	for e in enemies_root.get_children():
		if not e.has_method("is_dead") or e.is_dead():
			continue
		var to := _flat(e.global_position - global_position)
		var d := to.length()
		if d > max_r:
			continue
		var ang := rad_to_deg(ref.angle_to(to.normalized())) if d > 0.1 else 0.0
		if ang > tune.assist_angle and d > 2.0:
			continue
		var score := d + ang * 0.05
		if score < best_score:
			best_score = score
			best = e
	return best

func toggle_lock() -> void:
	if lock_target:
		lock_target = null
		return
	if enemies_root == null or cam == null:
		return
	var fwd: Vector3 = cam.forward_flat()
	var best: Node3D = null
	var best_score := INF
	for e in enemies_root.get_children():
		if not e.has_method("is_dead") or e.is_dead():
			continue
		var to := _flat(e.global_position - global_position)
		var d := to.length()
		if d > 20.0:
			continue
		var score := d * 0.5 + rad_to_deg(fwd.angle_to(to.normalized())) * 0.1
		if score < best_score:
			best_score = score
			best = e
	lock_target = best

# ---------------------------------------------------------------- aspetto

func _update_visual(delta: float) -> void:
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-facing.x, -facing.z), clamp(30.0 * delta, 0, 1))
	var hv := Vector3(velocity.x, 0, velocity.z)
	var lean: float = clamp(hv.length() / 10.0, 0.0, 1.0) * 0.12
	visual.rotation.x = lerp(visual.rotation.x, -lean, clamp(10.0 * delta, 0, 1))
	visual.scale = visual.scale.lerp(Vector3.ONE, clamp(14.0 * delta, 0, 1))

func _squash(s: Vector3) -> void:
	visual.scale = s

func _flash(c: Color) -> void:
	_body_mat.emission_enabled = true
	_body_mat.emission = c
	var t := create_tween()
	t.tween_property(_body_mat, "emission", Color.BLACK, 0.18)

func _afterimage() -> void:
	for p in _body_parts:
		var g := MeshInstance3D.new()
		g.mesh = p.mesh
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(M.FORM_COLOR[weapon.form], 0.45)
		g.material_override = m
		get_parent().add_child(g)
		g.global_transform = p.global_transform
		var t := g.create_tween()
		t.tween_property(m, "albedo_color:a", 0.0, 0.22)
		t.tween_callback(g.queue_free)
