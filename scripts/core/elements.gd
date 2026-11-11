extends Node
## Elementi dell'arena: FUOCO ed ELETTRICITÀ.
## Famiglie: INFIAMMABILI (casse di legno, bidoni di carburante) e CONDUTTIVI
## (blocchi di metallo, bobine, pozze d'acqua, nemici colpiti dalla scarica).
## Regole leggibili: il fuoco si spegne nell'acqua; l'elettricità nell'acqua prende tutta la pozza.

var puddles: Array = []            # [{pos: Vector3, r: float, mesh: MeshInstance3D}]
var tune := {
	"fire_dps": 8.0,
	"fire_time": 3.5,
	"shock_dmg": 14.0,
	"shock_range": 4.2,            # salto dell'arco tra conduttori
	"enemy_hop": 2.6,              # salto dell'arco tra nemici
	"chain": 4,
}

func add_puddle(pos: Vector3, r: float, mesh: MeshInstance3D) -> void:
	puddles.append({"pos": pos, "r": r, "mesh": mesh})

func puddle_at(p: Vector3, margin := 0.0) -> int:
	for i in puddles.size():
		var d: Dictionary = puddles[i]
		var to: Vector3 = p - d.pos
		to.y = 0
		if to.length() < d.r + margin and p.y < 1.2:
			return i
	return -1

func _enemies() -> Array:
	return get_tree().get_nodes_in_group("enemies")

func _props() -> Array:
	return get_tree().get_nodes_in_group("props")

# ------------------------------------------------------------ fuoco

## Accende tutto quello che è infiammabile nel raggio.
func ignite_area(pos: Vector3, r: float, source: Node = null) -> void:
	FX.ring(pos, Color(1, 0.5, 0.15, 0.9), r, 0.35)
	FX.sparks(pos, Vector3.UP, Color(1, 0.55, 0.15), 14, 8.0)
	for e in _enemies():
		if e != source and not e.is_dead() and e.global_position.distance_to(pos) < r + e.radius:
			e.ignite(tune.fire_time)
	for p in _props():
		if p != source and p.center().distance_to(pos) < r + p.radius and p.has_method("ignite"):
			p.ignite()

# ------------------------------------------------------------ elettricità

## Scarica che parte da un punto e salta tra i conduttori vicini.
## hostile: la scarica viene da un nemico e può colpire anche il giocatore.
func shock(pos: Vector3, source: Node = null, power := 1.0, hostile := false) -> void:
	FX.sound("critico", 1.5, -2.0)
	FX.ring(pos, Color(0.45, 0.9, 1.0, 0.9), 1.4, 0.18)
	FX.stat("shocks")
	var visited := {}
	if source:
		visited[source] = true
	var frontier := [{"pos": pos, "depth": 0}]
	var shocked_puddles := {}
	var pl: Node3D = get_tree().get_first_node_in_group("player")
	var player_hit := not hostile or pl == null
	if not player_hit and pl.global_position.distance_to(pos) < 1.8:
		player_hit = true
		pl.take_hit(source if source is Node3D else pl, tune.shock_dmg * 0.8, (pl.global_position - pos).normalized())
	while not frontier.is_empty():
		var cur: Dictionary = frontier.pop_front()
		var at: Vector3 = cur.pos
		var depth: int = cur.depth
		var reach: float = tune.shock_range * power
		# acqua: se la scarica tocca una pozza, la prende tutta
		var pi := puddle_at(at, 1.0)
		if pi >= 0 and not shocked_puddles.has(pi):
			shocked_puddles[pi] = true
			_flash_puddle(pi)
			FX.stat("puddle_shocks")
			if not player_hit and puddle_at(pl.global_position) == pi:
				player_hit = true
				_arc(puddles[pi].pos + Vector3(0, 0.1, 0), pl.global_position + Vector3(0, 0.9, 0))
				pl.take_hit(source if source is Node3D else pl, tune.shock_dmg * 0.9, Vector3.UP)
			for e in _enemies():
				if not visited.has(e) and not e.is_dead() and puddle_at(e.global_position) == pi:
					visited[e] = true
					_arc(puddles[pi].pos + Vector3(0, 0.1, 0), e.global_position + Vector3(0, 0.9, 0))
					e.shock(tune.shock_dmg * 1.3 * power)
					frontier.append({"pos": e.global_position, "depth": depth + 1})
		if depth >= tune.chain:
			continue
		for e in _enemies():
			if visited.has(e) or e.is_dead():
				continue
			var hop: float = reach if depth == 0 else tune.enemy_hop
			if e.global_position.distance_to(at) < hop:
				visited[e] = true
				_arc(at + Vector3(0, 0.9, 0), e.global_position + Vector3(0, 0.9, 0))
				e.shock(tune.shock_dmg * power)
				frontier.append({"pos": e.global_position, "depth": depth + 1})
		for p in _props():
			if visited.has(p) or p.center().distance_to(at) > reach:
				continue
			if p.get("conductive"):
				visited[p] = true
				_arc(at + Vector3(0, 0.9, 0), p.center())
				p.on_shock()
				frontier.append({"pos": p.global_position, "depth": depth + 1})
			elif p.get("explosive"):
				visited[p] = true
				_arc(at + Vector3(0, 0.9, 0), p.center())
				p.ignite()

func _flash_puddle(i: int) -> void:
	var m: MeshInstance3D = puddles[i].mesh
	if m == null:
		return
	var mat: StandardMaterial3D = m.material_override
	mat.albedo_color = Color(0.7, 1.0, 1.0, 0.85)
	var tw := create_tween()
	tw.tween_property(mat, "albedo_color", Color(0.25, 0.55, 0.9, 0.45), 0.45)

## Arco a zig-zag: pochi segmenti, svanisce in fretta.
func _arc(a: Vector3, b: Vector3) -> void:
	var world: Node = FX._world
	if world == null:
		return
	var pts := [a]
	for k in [0.33, 0.66]:
		pts.append(a.lerp(b, k) + Vector3(randf_range(-0.35, 0.35), randf_range(-0.3, 0.3), randf_range(-0.35, 0.35)))
	pts.append(b)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.75, 0.97, 1.0, 1.0)
	for i in pts.size() - 1:
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var d := p0.distance_to(p1)
		if d < 0.05:
			continue
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.07, 0.07, d)
		mi.mesh = bm
		mi.material_override = mat
		world.add_child(mi)
		mi.global_position = (p0 + p1) * 0.5
		mi.look_at(p1, Vector3.UP if absf((p1 - p0).normalized().y) < 0.95 else Vector3.RIGHT)
		get_tree().create_timer(0.16, true, false, true).timeout.connect(mi.queue_free)
