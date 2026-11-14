extends Node3D
## Potere di manipolazione: SPINGI, ATTIRA, ALTERA (versione limitata: SOVRACCARICA).
## Precisione prima di tutto: un solo bersaglio alla volta, sempre segnato da un mirino.
## Stadi: 1 = leggeri e nemici leggeri, 2 = anche pesanti, 3 = più bersagli insieme.

signal used(kind: String)

var player: CharacterBody3D
var cam: Node3D
var stage := 1                      # stadio effettivo (base o sbloccato da OVERLOAD)
var base_stage := 1
var tune := {
	"range": 15.0,
	"push_speed": 22.0,
	"pull_speed": 16.0,
	"push_cd": 0.45,
	"pull_cd": 0.5,
	"alter_cd": 2.5,
}

var target: Node3D
var held: Node3D                    # oggetto tenuto sospeso dopo un'attrazione
var _cd := {"push": 0.0, "pull": 0.0, "alter": 0.0}
var _reticle: MeshInstance3D
var _reticle_mat: StandardMaterial3D
var _beam: MeshInstance3D
var _beam_mat: StandardMaterial3D

func _ready() -> void:
	_reticle = MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.8
	t.outer_radius = 1.0
	t.rings = 20
	t.ring_segments = 4
	_reticle.mesh = t
	_reticle_mat = StandardMaterial3D.new()
	_reticle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_reticle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_reticle_mat.no_depth_test = true
	_reticle_mat.albedo_color = Color(0.7, 0.95, 1.0, 0.7)
	_reticle.material_override = _reticle_mat
	_reticle.top_level = true
	_reticle.visible = false
	add_child(_reticle)
	_beam = MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.09, 0.09, 1.0)
	_beam.mesh = b
	_beam_mat = StandardMaterial3D.new()
	_beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam.material_override = _beam_mat
	_beam.top_level = true
	_beam.visible = false
	add_child(_beam)

func cooldown_ratio(kind: String) -> float:
	return clamp(_cd[kind] / tune[kind + "_cd"], 0.0, 1.0)

func _physics_process(delta: float) -> void:
	stage = max(base_stage, OV.stage_bonus())
	for k in _cd:
		_cd[k] = max(0.0, _cd[k] - delta)
	target = _pick_target()
	_update_reticle()
	if held and is_instance_valid(held):
		if Run.has("orbita"):
			_orbit(delta)
		else:
			held.set_hold_point(player.global_position + Vector3(0, 2.6, 0) + player.facing * 1.4)
	if player.state == player.S.DEAD or player.state == player.S.HURT:
		return
	if Pad.just("push"):
		push()
	if Pad.just("pull"):
		pull()
	if Pad.just("alter"):
		alter()

## 0.19, potenziamento Orbita: l'oggetto tenuto ti gira attorno e colpisce chi tocca (danno ridotto).
var _orbit_a := 0.0
var _orbit_hit := {}
func _orbit(delta: float) -> void:
	_orbit_a += delta * 4.5
	var off := Vector3(cos(_orbit_a), 0, sin(_orbit_a)) * 1.9
	held.set_hold_point(player.global_position + Vector3(0, 1.1, 0) + off)
	var now := Time.get_ticks_msec()
	var c: Vector3 = held.center()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_dead() or now < int(_orbit_hit.get(e, 0)):
			continue
		if e.global_position.distance_to(c - Vector3(0, 0.6, 0)) < e.radius + 1.0:
			_orbit_hit[e] = now + 600
			var dir: Vector3 = e.global_position - player.global_position
			dir.y = 0
			e.receive_hit({"dmg": 6.0, "poise": 14.0, "dir": dir.normalized(), "knock": 4.0, "launch": 0.0, "form": -1, "move": "orbit", "env": true})
			FX.sparks(c, dir.normalized(), Color(0.7, 0.95, 1.0), 6, 6.0)
			FX.stat("up_orbit_hits")

func _can_move(t: Node3D) -> bool:
	if t == null:
		return false
	if t.has_method("is_fixed") and t.is_fixed():
		return false
	if t.has_method("is_heavy") and t.is_heavy():
		return stage >= 2
	return true

## Oggetti fissi che il potere può comunque "toccare" (bobina, muretto).
func _can_poke(t: Node3D) -> bool:
	return t != null and t.has_method("power_poke") and t.has_method("is_fixed") and t.is_fixed()

## Bersaglio: quello agganciato, altrimenti il più vicino al centro dello schermo.
func _pick_target() -> Node3D:
	if player.lock_target and is_instance_valid(player.lock_target) and not player.lock_target.is_dead():
		return player.lock_target
	var fwd: Vector3 = cam.forward_flat()
	var best: Node3D = null
	var best_score := INF
	for group in ["enemies", "props"]:
		for n in get_tree().get_nodes_in_group(group):
			if n == held or n.is_dead():
				continue
			var to: Vector3 = n.global_position - player.global_position
			to.y = 0
			var d := to.length()
			if d > tune.range or d < 0.6:
				continue
			var ang := rad_to_deg(fwd.angle_to(to.normalized()))
			if ang > 40.0:
				continue
			var score := ang * 0.12 + d * 0.25 + (0.0 if group == "enemies" else 1.0) + (1.5 if n.has_method("is_fixed") and n.is_fixed() else 0.0)
			if score < best_score:
				best_score = score
				best = n
	return best

func _update_reticle() -> void:
	if target == null:
		_reticle.visible = false
		return
	_reticle.visible = true
	var r: float = target.get("radius") if target.get("radius") != null else 0.5
	_reticle.global_position = target.global_position + Vector3(0, 0.08, 0)
	_reticle.scale = Vector3.ONE * (r + 0.55) * (1.0 + 0.06 * sin(Time.get_ticks_msec() * 0.012))
	_reticle_mat.albedo_color = Color(0.7, 0.95, 1.0, 0.75) if _can_move(target) or _can_poke(target) else Color(1, 0.4, 0.4, 0.6)
	if OV.bursting > 0.0 and _can_move(target):
		_reticle_mat.albedo_color = Color(1, 0.82, 0.25, 0.85)

func _beam_to(to: Vector3, c: Color) -> void:
	var from: Vector3 = player.global_position + Vector3(0, 1.3, 0) + player.facing * 0.4
	var d: float = from.distance_to(to)
	if d < 0.2:
		return
	_beam.visible = true
	_beam.global_position = (from + to) * 0.5
	_beam.look_at(to, Vector3.UP)
	_beam.scale = Vector3(1, 1, d)
	_beam_mat.albedo_color = c
	var tw := create_tween()
	tw.tween_property(_beam_mat, "albedo_color:a", 0.0, 0.18)
	tw.tween_callback(func(): _beam.visible = false)

func _too_heavy() -> void:
	FX.sound("scudo", 0.7, -4.0)
	FX.stat("power_too_heavy")

func _targets_for_stage(main: Node3D, kind := "push") -> Array:
	var list := [main]
	if stage >= 3 or (kind == "pull" and Run.has("attrazione_doppia")):
		# stadio 3: il potere prende anche il bersaglio più vicino al primo
		var best: Node3D = null
		var bd := 4.0
		for group in ["enemies", "props"]:
			for n in get_tree().get_nodes_in_group(group):
				if n == main or n == held or n.is_dead():
					continue
				var d: float = n.global_position.distance_to(main.global_position)
				if d < bd:
					bd = d
					best = n
		if best:
			list.append(best)
	return list

## SPINGI: se tieni qualcosa lo lanci verso il bersaglio; altrimenti scaraventi il bersaglio lontano.
func push() -> void:
	if _cd.push > 0.0:
		return
	# sfere del Conduit davanti a te: SPINGI le rimanda indietro
	var reflected := false
	for o in get_tree().get_nodes_in_group("orbs"):
		var to: Vector3 = o.global_position - player.global_position
		to.y = 0
		if not o.reflected and to.length() < 6.0 and (to.length() < 1.5 or player.facing.angle_to(to.normalized()) < deg_to_rad(80)):
			o.reflect(player)
			reflected = true
	if reflected:
		_beam_to(player.global_position + player.facing * 2.0 + Vector3(0, 1.2, 0), Color(1, 0.95, 0.5, 0.9))
		_done("push", "reflect")
		return
	if held and is_instance_valid(held):
		var aim: Vector3 = player.facing
		if target:
			aim = (target.global_position + Vector3(0, 0.8, 0) - held.center()).normalized()
		elif cam:
			aim = cam.forward_flat()
		if Run.has("lanci_carichi"):
			held.charge()
		held.launch(aim * tune.push_speed * 1.25 + Vector3(0, 1.5, 0), player)
		_beam_to(held.center(), Color(0.7, 0.95, 1.0, 0.9))
		held = null
		_done("push", "throw")
		return
	if target == null:
		# nessun bersaglio: onda corta davanti, utile per respingere
		FX.ring(player.global_position + player.facing * 1.5, Color(0.7, 0.95, 1.0, 0.7), 2.0, 0.2)
		_done("push", "wave")
		return
	if _can_poke(target):
		target.power_poke()
		_beam_to(target.global_position + Vector3(0, 1.0, 0), Color(0.7, 0.95, 1.0, 0.9))
		_done("push", "poke")
		return
	if not _can_move(target):
		_too_heavy()
		_cd.push = 0.25
		return
	var moved := 0
	for t in _targets_for_stage(target):
		if not _can_move(t):
			continue
		moved += 1
		var dir: Vector3 = t.global_position - player.global_position
		dir.y = 0
		dir = dir.normalized()
		var v: Vector3 = dir * tune.push_speed + Vector3(0, 3.5, 0)
		if t.has_method("launch"):
			t.launch(v, player)
		else:
			t.power_push(v)
		_beam_to(t.global_position + Vector3(0, 0.9, 0), Color(0.7, 0.95, 1.0, 0.9))
		FX.sparks(t.global_position + Vector3(0, 0.9, 0), dir, Color(0.7, 0.95, 1.0), 8, 7.0)
	if moved >= 2:
		FX.stat("multi_target")
	_done("push", "push")

## ATTIRA: un oggetto viene tenuto sospeso davanti a te; un nemico viene trascinato a portata di lama.
func pull() -> void:
	if _cd.pull > 0.0:
		return
	if held and is_instance_valid(held):
		held.release_hold()
		held = null
		_cd.pull = 0.2
		return
	if target == null:
		return
	if _can_poke(target):
		target.power_poke()
		_beam_to(target.global_position + Vector3(0, 1.0, 0), Color(0.7, 0.95, 1.0, 0.9))
		_done("pull", "poke")
		return
	if not _can_move(target):
		_too_heavy()
		_cd.pull = 0.25
		return
	var moved := 0
	for t in _targets_for_stage(target, "pull"):
		if not _can_move(t):
			continue
		moved += 1
		if t.has_method("hold"):
			if held == null:
				held = t
				t.hold(player.global_position + Vector3(0, 2.6, 0))
			else:
				var to2: Vector3 = player.global_position - t.global_position
				t.launch(to2.normalized() * tune.pull_speed * 0.6 + Vector3(0, 4, 0), player)
		else:
			t.power_pull(player.global_position + player.facing * 1.8)
			# 0.19: schivata e poi ATTIRA = Contro-presa (il nemico arriva scoperto a lungo)
			if t.is_in_group("enemies") and player.has_method("on_power_pull") and player.on_power_pull():
				t.grab_stun()
		_beam_to(t.global_position + Vector3(0, 0.9, 0), Color(0.85, 0.5, 1.0, 0.9))
	if moved >= 2:
		FX.stat("multi_target")
	_done("pull", "pull")

## ALTERA (limitata): SOVRACCARICA il bersaglio. Al prossimo impatto esplode.
func alter() -> void:
	if _cd.alter > 0.0:
		return
	var t: Node3D = held if held and is_instance_valid(held) else target
	if t == null:
		return
	if t.has_method("charge"):
		t.charge()
	_beam_to(t.global_position + Vector3(0, 0.9, 0), Color(1, 0.85, 0.2, 0.9))
	FX.ring(t.global_position, Color(1, 0.85, 0.2, 0.8), 1.6, 0.25)
	_done("alter", "alter")

func _done(kind: String, stat: String) -> void:
	_cd[kind] = tune[kind + "_cd"] * OV.cooldown_mult()
	FX.sound("cutin" if kind == "alter" else "schivata", 0.8 if kind == "pull" else 1.3, -3.0)
	FX.stat("power_" + stat)
	if cam and cam.has_method("kick"):
		cam.kick(2.5)
	used.emit(kind)
