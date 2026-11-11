extends Node3D
## Sfera elettrica del Conduit: lenta e ben visibile. Dove arriva scarica (anche sui nemici).
## SPINGI la rimanda indietro: rimandata, cerca un nemico e la scarica è più forte.

var vel := Vector3.ZERO
var owner_enemy: Node3D
var dmg := 10.0
var reflected := false
var _target := Vector3.ZERO
var _life := 3.2
var _mat: StandardMaterial3D

func _ready() -> void:
	add_to_group("orbs")
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.32
	sm.height = 0.64
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.albedo_color = Color(0.55, 0.95, 1.0)
	mi.material_override = _mat
	add_child(mi)

func fire(from: Vector3, to: Vector3, by: Node3D, damage: float) -> void:
	global_position = from
	_target = to
	owner_enemy = by
	dmg = damage
	vel = (to - from).normalized() * 9.0

## SPINGI: la sfera torna indietro verso il nemico più vicino a chi l'ha lanciata.
func reflect(by: Node3D) -> void:
	if reflected:
		return
	reflected = true
	_life = 2.5
	var best: Node3D = owner_enemy if is_instance_valid(owner_enemy) and not owner_enemy.is_dead() else null
	if best == null:
		var bd := INF
		for e in get_tree().get_nodes_in_group("enemies"):
			var d: float = e.global_position.distance_to(global_position)
			if d < bd and not e.is_dead():
				bd = d
				best = e
	var aim: Vector3 = best.global_position + Vector3(0, 0.9, 0) if best else global_position + (global_position - by.global_position).normalized() * 8.0
	_target = aim
	vel = (aim - global_position).normalized() * 16.0
	_mat.albedo_color = Color(1.0, 0.95, 0.5)
	FX.sound("schivata", 1.6)
	FX.stat("orbs_reflected")

func _physics_process(delta: float) -> void:
	_life -= delta
	var d := delta * (1.0 if reflected else FX.enemy_time)
	global_position += vel * d
	scale = Vector3.ONE * (1.0 + 0.15 * sin(Time.get_ticks_msec() * 0.03))
	if reflected:
		for e in get_tree().get_nodes_in_group("enemies"):
			if not e.is_dead() and e.global_position.distance_to(global_position - Vector3(0, 0.9, 0)) < e.radius + 0.6:
				_burst(1.4)
				return
	else:
		var pl: Node3D = get_tree().get_first_node_in_group("player")
		if pl and (pl.global_position + Vector3(0, 0.9, 0)).distance_to(global_position) < 0.85:
			var r: String = pl.take_hit(owner_enemy if is_instance_valid(owner_enemy) else self, dmg, vel.normalized())
			_burst(0.8, r == "hit")
			return
		for p in get_tree().get_nodes_in_group("props"):
			if p.get("explosive") and not p.is_dead() and p.center().distance_to(global_position) < p.radius + 0.5:
				p.ignite(0.1)
				_burst(1.0)
				return
	if global_position.distance_to(_target) < 0.4 or global_position.y < 0.05 or _life <= 0.0:
		_burst(1.0)

func _burst(power: float, hit_player := false) -> void:
	set_physics_process(false)
	# la scarica del Conduit fa male anche ai nemici: è lì che il giocatore la sfrutta
	El.shock(global_position, owner_enemy if not reflected and is_instance_valid(owner_enemy) else null, power, not reflected and not hit_player)
	queue_free()
