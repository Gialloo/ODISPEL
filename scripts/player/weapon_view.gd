extends Node3D
## Aspetto dell'arma trasformabile: tre forme con sagome e colori diversi,
## trasformazione con un "pop" rapido e scia del fendente.

const M = preload("res://scripts/player/moves.gd")

var form := M.Form.BLADE
var _forms: Array[Node3D] = []
var _trail_mats: Array[StandardMaterial3D] = []
var _arm: Node3D
var _swing_tw: Tween
var _vector_line: MeshInstance3D
## 0.13: posa del corpo letta dal giocatore ogni frame (gradi e frazioni), animata insieme all'arma.
var body_twist := 0.0          # rotazione del busto attorno alla verticale
var body_pitch := 0.0          # + = piegato in avanti
var body_drop := 0.0           # 0..0.35 = accovacciato (schiaccia la sagoma)
var _pose_tw: Tween
var _links: Array[Node3D] = []
var _chain_len := 1.6
var _chain_wiggle := 0.0
var _chain_phase := 0.0
const CHAIN_LINKS := 18
const REST := {"rot": Vector3(-35, -20, 0), "pos": Vector3(0.35, 1.15, 0.0), "twist": 0.0, "pitch": 0.0, "drop": 0.0}

func _ready() -> void:
	_arm = Node3D.new()
	_arm.position = Vector3(0.35, 1.15, 0.0)
	add_child(_arm)
	_forms = [_build_blade(), _build_impact(), _build_vector()]
	for f in _forms:
		_arm.add_child(f)
	for c in M.FORM_COLOR:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.albedo_color = Color(c, 0.75)
		_trail_mats.append(m)
	_vector_line = MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.07, 0.07, 1.0)
	_vector_line.mesh = b
	_vector_line.material_override = _mat(M.FORM_COLOR[M.Form.VECTOR], true)
	_vector_line.visible = false
	_vector_line.top_level = true
	add_child(_vector_line)
	_show(form, false)
	rest()

func _mat(c: Color, glow := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if glow:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _box(size: Vector3, pos: Vector3, c: Color, glow := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = _mat(c, glow)
	return mi

func _build_blade() -> Node3D:
	var n := Node3D.new()
	n.add_child(_box(Vector3(0.08, 0.08, 0.3), Vector3(0, 0, 0.0), Color(0.15, 0.15, 0.18)))
	n.add_child(_box(Vector3(0.05, 0.14, 1.25), Vector3(0, 0, -0.75), M.FORM_COLOR[0], true))
	return n

func _build_impact() -> Node3D:
	var n := Node3D.new()
	n.add_child(_box(Vector3(0.1, 0.1, 1.0), Vector3(0, 0, -0.4), Color(0.15, 0.15, 0.18)))
	n.add_child(_box(Vector3(0.55, 0.45, 0.45), Vector3(0, 0, -1.05), M.FORM_COLOR[1], true))
	return n

func _build_vector() -> Node3D:
	# catena a maglie: a riposo è corta e raccolta, nei colpi si allunga davvero fino alla portata
	var n := Node3D.new()
	n.add_child(_box(Vector3(0.12, 0.12, 0.3), Vector3(0, 0, 0.05), Color(0.15, 0.15, 0.18)))
	for i in CHAIN_LINKS:
		var l := _box(Vector3(0.1, 0.1, 0.24), Vector3.ZERO, M.FORM_COLOR[2].lerp(Color.WHITE, float(i) / CHAIN_LINKS * 0.5), true)
		n.add_child(l)
		_links.append(l)
	var tip := _box(Vector3(0.24, 0.24, 0.24), Vector3.ZERO, Color(1, 0.9, 1), true)
	n.add_child(tip)
	_links.append(tip)
	return n

func _process(delta: float) -> void:
	if form != M.Form.VECTOR or _links.is_empty():
		return
	_chain_phase += delta * 26.0
	var n := _links.size()
	for i in n:
		var k := float(i + 1) / n
		var z := -(0.15 + k * _chain_len)
		# l'onda corre lungo la catena e cresce verso la punta: si vede la frustata
		var w := sin(k * 7.0 - _chain_phase) * _chain_wiggle * k
		_links[i].position = Vector3(w, w * 0.5, z)

func _show(f: int, pop := true) -> void:
	for i in _forms.size():
		_forms[i].visible = i == f
	if pop:
		var n := _forms[f]
		n.scale = Vector3(1.6, 1.6, 0.3)
		var t := n.create_tween()
		t.tween_property(n, "scale", Vector3.ONE, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Cambia forma solo se serve (non a ogni colpo).
func set_form(f: int) -> bool:
	if f == form:
		return false
	form = f
	_show(f, true)
	FX.sparks(_arm.global_position + global_transform.basis.z * -0.6, Vector3.UP, M.FORM_COLOR[f], 6, 3.0)
	return true

func rest() -> void:
	if _swing_tw:
		_swing_tw.kill()
	if _pose_tw:
		_pose_tw.kill()
	# ritorno morbido alla guardia, non uno scatto
	_pose_tw = create_tween()
	var from := _current()
	_pose_tw.tween_method(func(k: float): _apply(_blend(from, REST, k)), 0.0, 1.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pose_tw.parallel().tween_property(self, "_chain_len", 1.6, 0.14)
	_pose_tw.parallel().tween_property(self, "_chain_wiggle", 0.0, 0.14)

# ------------------------------------------------------------ pose (0.13)

func _pose(rot: Vector3, pos := Vector3(0.35, 1.15, 0.0), twist := 0.0, pitch := 0.0, drop := 0.0) -> Dictionary:
	return {"rot": rot, "pos": pos, "twist": twist, "pitch": pitch, "drop": drop}

func _current() -> Dictionary:
	return _pose(Vector3(rad_to_deg(_arm.rotation.x), rad_to_deg(_arm.rotation.y), rad_to_deg(_arm.rotation.z)), _arm.position, body_twist, body_pitch, body_drop)

func _blend(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	return _pose(a.rot.lerp(b.rot, k), a.pos.lerp(b.pos, k), lerpf(a.twist, b.twist, k), lerpf(a.pitch, b.pitch, k), lerpf(a.drop, b.drop, k))

func _apply(p: Dictionary) -> void:
	_arm.rotation = Vector3(deg_to_rad(p.rot.x), deg_to_rad(p.rot.y), deg_to_rad(p.rot.z))
	_arm.position = p.pos
	body_twist = p.twist
	body_pitch = p.pitch
	body_drop = p.drop

## Sequenza di pose: [[posa, secondi, trans, ease], ...]. La prima posa si applica subito.
func _seq(steps: Array) -> void:
	if _swing_tw:
		_swing_tw.kill()
	if _pose_tw:
		_pose_tw.kill()
	_pose_tw = create_tween()
	var prev: Dictionary = steps[0][0]
	_apply(prev)
	for i in range(1, steps.size()):
		var st: Array = steps[i]
		var a: Dictionary = prev
		var b: Dictionary = st[0]
		_pose_tw.tween_method(func(k: float): _apply(_blend(a, b, k)), 0.0, 1.0, max(0.01, st[1])).set_trans(st[2]).set_ease(st[3])
		prev = b

## Animazione completa di un colpo. wind = fino al colpo, strike = durata del colpo, rec = coda.
func play(id: String, m: Dictionary) -> void:
	var wind: float = max(0.03, m.hit_from)
	var strike: float = max(0.06, m.hit_to - m.hit_from + 0.04)
	var rec: float = max(0.06, m.cancel - m.hit_to)
	var side: float = m.get("swing", 1.0)
	var E := Tween.EASE_OUT
	var I := Tween.EASE_IN
	var EXPO := Tween.TRANS_EXPO
	var QUAD := Tween.TRANS_QUAD
	var BACK := Tween.TRANS_BACK
	var sh := Vector3(0.35, 1.15, 0.0)
	match m.form:
		M.Form.BLADE:
			if side == 2.0:
				# piroetta: lama tesa in fuori, il corpo gira (lo fa il giocatore), braccio che apre
				_seq([[_pose(Vector3(-5, 60, 0), sh, 20, 0, 0.12), 0],
					[_pose(Vector3(-5, -300, 0), sh + Vector3(0.1, 0, -0.2), -20, 8, 0.05), wind + strike, QUAD, E],
					[_pose(Vector3(-20, -340, 0), sh, 0, 4, 0), rec, QUAD, E]])
			elif side == 0.0:
				# fendente dall'alto: si alza, si tende indietro, poi taglia giù fino a terra
				_seq([[_pose(Vector3(60, 0, 0), sh, 0, -4, 0), 0],
					[_pose(Vector3(115, 5, 0), sh + Vector3(0, 0.15, 0.1), 0, -10, 0.0), wind, QUAD, E],
					[_pose(Vector3(-75, -5, 0), sh + Vector3(0, -0.1, -0.35), 0, 18, 0.12), strike, EXPO, E],
					[_pose(Vector3(-60, -10, 0), sh + Vector3(0, -0.05, -0.2), 0, 10, 0.06), rec, QUAD, E]])
			else:
				# fendente orizzontale in diagonale: carica di lato, taglio netto oltre il centro, assestamento
				var roll: float = 25.0 if id in ["blade_1", "blade_air_1", "blade_dash"] else -25.0
				_seq([[_pose(Vector3(-5, 95 * -side, roll * side), sh, 22 * side, 0, 0.06), 0],
					[_pose(Vector3(-2, 115 * -side, roll * side), sh + Vector3(0, 0.05, 0.1), 30 * side, -3, 0.1), wind, QUAD, E],
					[_pose(Vector3(-15, -110 * -side, -roll * side), sh + Vector3(0, -0.05, -0.3), -32 * side, 12, 0.04), strike, EXPO, E],
					[_pose(Vector3(-20, -90 * -side, -roll * side * 0.5), sh + Vector3(0, 0, -0.15), -14 * side, 6, 0.0), rec, QUAD, E]])
		M.Form.IMPACT:
			if id == "impact_launcher":
				# montante: giù basso e accovacciato, poi su con tutto il corpo
				_seq([[_pose(Vector3(-60, -10, 0), sh, 0, 6, 0.1), 0],
					[_pose(Vector3(-100, -15, 0), sh + Vector3(0, -0.3, -0.1), 15, 14, 0.32), wind, QUAD, I],
					[_pose(Vector3(120, 0, 0), sh + Vector3(0, 0.35, -0.2), -10, -14, 0.0), strike, EXPO, E],
					[_pose(Vector3(100, 0, 0), sh + Vector3(0, 0.25, -0.1), 0, -8, 0.0), rec, QUAD, E]])
			elif side == 0.0 or id in ["impact_slam", "impact_hammer", "impact_breaker", "impact_counter"]:
				# martellata: il martello va dietro la testa, il corpo si tende all'indietro e pesa,
				# poi cade giù di colpo con il corpo che si piega e si schiaccia a terra; piccolo rimbalzo
				_seq([[_pose(Vector3(80, 0, 0), sh, 0, -5, 0.05), 0],
					[_pose(Vector3(150, 0, 0), sh + Vector3(0, 0.3, 0.2), 0, -16, 0.0), wind, QUAD, E],
					[_pose(Vector3(-75, 0, 0), sh + Vector3(0, -0.2, -0.45), 0, 26, 0.3), strike, EXPO, I],
					[_pose(Vector3(-58, 0, 0), sh + Vector3(0, -0.1, -0.35), 0, 16, 0.15), rec * 0.4, BACK, E],
					[_pose(Vector3(-65, 0, 0), sh + Vector3(0, -0.15, -0.35), 0, 18, 0.18), rec * 0.6, QUAD, E]])
			else:
				# colpo largo di lato (chiusura della combo): rotazione ampia di busto, peso che passa da un piede all'altro
				_seq([[_pose(Vector3(-10, 90 * -side, 10 * side), sh, 30 * side, 0, 0.1), 0],
					[_pose(Vector3(-5, 140 * -side, 15 * side), sh + Vector3(0, 0.05, 0.25), 48 * side, -6, 0.18), wind, QUAD, E],
					[_pose(Vector3(-25, -120 * -side, -10 * side), sh + Vector3(0, -0.1, -0.35), -45 * side, 16, 0.12), strike, EXPO, I],
					[_pose(Vector3(-30, -100 * -side, -5 * side), sh + Vector3(0, -0.05, -0.2), -30 * side, 10, 0.08), rec, BACK, E]])
		M.Form.VECTOR:
			var reach: float = m.reach
			if side == 2.0 or m.arc >= 360.0:
				# spazzata e vortice: la catena si apre fino in fondo e gira tutta intorno
				_chain_wiggle = 0.25
				_tween_chain(reach * 0.95, wind * 0.6, wind + strike + rec * 0.3)
				_seq([[_pose(Vector3(5, 90, 0), sh, 25, 0, 0.1), 0],
					[_pose(Vector3(0, 60, 0), sh, 30, 0, 0.12), wind * 0.6, QUAD, E],
					[_pose(Vector3(0, -300, 0), sh + Vector3(0.05, 0, -0.1), -30, 6, 0.08), wind * 0.4 + strike, Tween.TRANS_LINEAR, E],
					[_pose(Vector3(-10, -340, 0), sh, 0, 0, 0.0), rec, QUAD, E]])
			else:
				# frustata: braccio indietro, poi lancio in avanti; la catena parte con l'onda e torna indietro
				_chain_wiggle = 0.6
				_tween_chain(reach * 0.92, strike, rec * 0.8)
				_seq([[_pose(Vector3(30, 30 * side, 0), sh, 12 * side, -4, 0.04), 0],
					[_pose(Vector3(45, 55 * side, 0), sh + Vector3(0, 0.1, 0.25), 22 * side, -8, 0.06), wind, QUAD, E],
					[_pose(Vector3(4, -6 * side, 0), sh + Vector3(-0.1, 0.0, -0.4), -14 * side, 14, 0.04), strike, EXPO, E],
					[_pose(Vector3(-10, -10 * side, 0), sh + Vector3(0, 0, -0.2), -6 * side, 6, 0.0), rec, QUAD, E]])

## La catena si allunga fino a length in out secondi, resta tesa per hold, poi torna corta.
func _tween_chain(length: float, out: float, hold: float) -> void:
	var t := create_tween()
	t.tween_property(self, "_chain_len", length, max(0.04, out)).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(self, "_chain_wiggle", 0.05, max(0.04, out + hold * 0.5))
	t.tween_interval(max(0.0, hold * 0.4))
	t.tween_property(self, "_chain_len", 1.6, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

## Movimento del braccio per la durata del colpo. side: -1 da destra, 1 da sinistra, 0 dall'alto, 2 giro completo.
func swing(side: float, windup: float, strike: float) -> void:
	if _swing_tw:
		_swing_tw.kill()
	_swing_tw = create_tween()
	if side == 0.0:
		_arm.rotation = Vector3(deg_to_rad(70), 0, 0)
		_swing_tw.tween_property(_arm, "rotation", Vector3(deg_to_rad(95), 0, 0), windup)
		_swing_tw.tween_property(_arm, "rotation", Vector3(deg_to_rad(-60), 0, 0), strike).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	elif side == 2.0:
		_arm.rotation = Vector3(deg_to_rad(-80), 0, 0)
		_swing_tw.tween_property(_arm, "rotation", Vector3(deg_to_rad(-85), deg_to_rad(-360), 0), windup + strike).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_arm.rotation = Vector3(deg_to_rad(-80), deg_to_rad(80) * -side, 0)
		_swing_tw.tween_property(_arm, "rotation", Vector3(deg_to_rad(-85), deg_to_rad(95) * -side, 0), windup)
		_swing_tw.tween_property(_arm, "rotation", Vector3(deg_to_rad(-75), deg_to_rad(-85) * -side, 0), strike).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

## Scia a ventaglio davanti al personaggio, colore della forma.
## Carica di IMPACT: la testa del martello si gonfia durante la preparazione.
func charge(seconds: float) -> void:
	var n := _forms[M.Form.IMPACT]
	var t := n.create_tween()
	t.tween_property(n, "scale", Vector3(1.35, 1.35, 1.1), seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(n, "scale", Vector3.ONE, 0.12)

## Ogni forma ha la sua scia: BLADE sottile e nitida, IMPACT larga e piena, VECTOR lunga e filiforme.
func trail(f: int, reach: float, arc_deg: float, height := 1.1, tilt := 0.0) -> void:
	var mi := MeshInstance3D.new()
	var inner: float = [0.78, 0.2, 0.88][f]
	mi.mesh = _fan(reach, min(arc_deg, 359.0), inner)
	var mat: StandardMaterial3D = _trail_mats[f].duplicate()
	mi.material_override = mat
	get_parent().get_parent().add_child(mi)
	mi.global_transform = global_transform
	mi.global_position += Vector3(0, height, 0)
	if tilt != 0.0:
		mi.rotate_object_local(Vector3.FORWARD, deg_to_rad(tilt))
	var t := mi.create_tween()
	t.tween_property(mat, "albedo_color:a", 0.0, [0.12, 0.22, 0.16][f])
	t.tween_callback(mi.queue_free)

func _fan(r: float, arc_deg: float, inner_k := 0.55) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 14
	var a0 := deg_to_rad(-arc_deg * 0.5)
	var step := deg_to_rad(arc_deg) / seg
	var inner := r * inner_k
	for i in seg:
		var a := a0 + step * i
		var b := a + step
		var p1 := Vector3(sin(a) * inner, 0, -cos(a) * inner)
		var p2 := Vector3(sin(a) * r, 0, -cos(a) * r)
		var p3 := Vector3(sin(b) * r, 0, -cos(b) * r)
		var p4 := Vector3(sin(b) * inner, 0, -cos(b) * inner)
		for p in [p1, p2, p3, p1, p3, p4]:
			st.add_vertex(p)
	return st.commit()

## Catena di VECTOR tesa fino al bersaglio.
func show_line(from: Vector3, to: Vector3, seconds: float) -> void:
	var d := from.distance_to(to)
	if d < 0.1:
		return
	_vector_line.visible = true
	_vector_line.global_position = (from + to) * 0.5
	_vector_line.look_at(to, Vector3.UP)
	_vector_line.scale = Vector3(1, 1, d)
	get_tree().create_timer(seconds, true, false, true).timeout.connect(func(): _vector_line.visible = false)
