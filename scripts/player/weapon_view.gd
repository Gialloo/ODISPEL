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
	var n := Node3D.new()
	for i in 5:
		n.add_child(_box(Vector3(0.09, 0.09, 0.28), Vector3(0, 0, -0.1 - i * 0.33), M.FORM_COLOR[2].lerp(Color.WHITE, i * 0.08), true))
	return n

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
	_arm.rotation = Vector3(deg_to_rad(-35), deg_to_rad(-20), 0)

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
func trail(f: int, reach: float, arc_deg: float, height := 1.1) -> void:
	var mi := MeshInstance3D.new()
	var inner: float = [0.78, 0.2, 0.88][f]
	mi.mesh = _fan(reach, min(arc_deg, 359.0), inner)
	var mat: StandardMaterial3D = _trail_mats[f].duplicate()
	mi.material_override = mat
	get_parent().get_parent().add_child(mi)
	mi.global_transform = global_transform
	mi.global_position += Vector3(0, height, 0)
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
