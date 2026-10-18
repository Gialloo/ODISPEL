class_name CharacterVisual
extends Node3D

# Segnaposto 3D di un personaggio (PROVVISORIO, in attesa dei modelli glTF).
# Interfaccia stabile, da tenere anche quando arriveranno i modelli veri:
#   setup(id) · move_speed (0..1) · stance (bool) · attack() · cast() · hit() · ko() · cheer() · head_point()
# Le animazioni sono procedurali (seno e tween): nessuno scheletro, nessun AnimationPlayer.
# Guarda verso -Z (come look_at di Godot).

var id: String = ""
var move_speed: float = 0.0        # 0 = fermo, 1 = cammina veloce
var stance: bool = false           # posa da combattimento

var _body: Node3D
var _hips: Node3D
var _head: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _meshes: Array = []
var _shadow: MeshInstance3D
var _t: float = 0.0
var _phase: float = 0.0
var _walk: float = 0.0
var _hip_y: float = 0.88
var _scale: float = 1.0

# Pose aggiuntive animate dai tween
var arm_r_x: float = 0.0
var arm_l_x: float = 0.0
var arm_r_z: float = 0.0
var arm_l_z: float = 0.0
var lean: float = 0.0
var hop: float = 0.0
var fall: float = 0.0
var down: bool = false


func setup(char_id: String) -> void:
	id = char_id
	var sp: Dictionary = CastVisual.spec(char_id)
	_scale = float(sp["height"]) / 1.75
	var b: float = float(sp["build"])
	var skin: Color = Color(str(sp["skin"]))
	var hair: Color = Color(str(sp["hair"]))
	var top: Color = Color(str(sp["top"]))
	var bottom: Color = Color(str(sp["bottom"]))
	var accent: Color = Color(str(sp["accent"]))
	var shoes: Color = Color(str(sp["shoes"]))
	var style: String = str(sp["hair_style"])
	var extra: String = str(sp["extra"])

	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	_body.scale = Vector3.ONE * _scale
	_hips = _pivot(_body, "Hips", Vector3(0, _hip_y, 0))
	if _build_from_model(char_id):
		return

	# --- busto ---
	var mb := MeshBatch.new()
	mb.box(Transform3D(Basis(), Vector3(0, 0.08, 0)), Vector3(0.27 * b, 0.18, 0.18), bottom)
	mb.box(Transform3D(Basis(), Vector3(0, 0.31, 0)), Vector3(0.34 * b, 0.30, 0.2), top)
	mb.box(Transform3D(Basis(), Vector3(0, 0.47, 0)), Vector3(0.38 * b, 0.07, 0.21), top.lightened(0.08))
	mb.prism(Transform3D(Basis(), Vector3(0, 0.46, 0)), 0.05, 0.045, 0.1, 6, skin, false)
	if extra == "coat":
		# cappotto lungo delle Civette: si apre dalla vita fino alle ginocchia
		mb.prism(Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, 0.12, 0)), 0.17 * b, 0.27 * b, 0.55, 8, top.darkened(0.15))
		mb.box(Transform3D(Basis(), Vector3(0, 0.30, -0.105)), Vector3(0.05, 0.3, 0.02), accent, false)
	elif extra == "bag":
		# tracolla e borsa (il pacco)
		mb.box(Transform3D(Basis(Vector3.FORWARD, 0.75), Vector3(0, 0.3, -0.105)), Vector3(0.045, 0.5, 0.02), accent.darkened(0.3), false)
		mb.box(Transform3D(Basis(), Vector3(0.2 * b, 0.02, -0.04)), Vector3(0.1, 0.16, 0.2), Color("#8a5a32"))
	elif extra == "mask":
		# felpa con cappuccio e scritta luminosa "LIVE"
		mb.ball(Transform3D(Basis().scaled(Vector3(1.0, 0.7, 0.8)), Vector3(0, 0.5, 0.11)), 0.16, top.darkened(0.2))
		mb.box(Transform3D(Basis(), Vector3(0, 0.3, -0.105)), Vector3(0.14, 0.05, 0.02), Color(accent.r, accent.g, accent.b, 0.0), false)
	elif extra == "cap":
		# giubba LibraCorp: placca sul petto e fascia rossa
		mb.box(Transform3D(Basis(), Vector3(0.08, 0.37, -0.105)), Vector3(0.08, 0.06, 0.02), Color("#c9d3e8"), false)
		mb.box(Transform3D(Basis(), Vector3(0, 0.2, 0)), Vector3(0.35 * b, 0.04, 0.215), accent, false)
	_mesh(_hips, mb, "Torso")

	# --- testa ---
	_head = _pivot(_hips, "Head", Vector3(0, 0.55, 0))
	var hb := MeshBatch.new()
	hb.ball(Transform3D(Basis().scaled(Vector3(1.0, 1.08, 1.0)), Vector3(0, 0.15, 0)), 0.155, skin)
	if extra != "mask":
		for sx in [-1.0, 1.0]:
			hb.box(Transform3D(Basis(), Vector3(0.055 * sx, 0.15, -0.148)), Vector3(0.034, 0.06, 0.012), Toon.INK, false)
			hb.box(Transform3D(Basis(), Vector3(0.05 * sx, 0.167, -0.154)), Vector3(0.012, 0.016, 0.006), Color(1, 1, 1, 0.0), false)
		hb.box(Transform3D(Basis(), Vector3(0, 0.075, -0.15)), Vector3(0.04, 0.008, 0.01), Toon.INK.lightened(0.15), false)
	_hair(hb, style, hair, accent, extra)
	_mesh(_head, hb, "HeadMesh")

	# --- braccia ---
	var sw: float = 0.2 * b
	_arm_l = _pivot(_hips, "ArmL", Vector3(-sw, 0.46, 0))
	_arm_r = _pivot(_hips, "ArmR", Vector3(sw, 0.46, 0))
	for side in [-1.0, 1.0]:
		var ab := MeshBatch.new()
		var down_b := Basis(Vector3.RIGHT, PI)
		ab.prism(Transform3D(down_b, Vector3.ZERO), 0.055, 0.047, 0.3, 6, top)
		ab.prism(Transform3D(down_b, Vector3(0, -0.3, 0)), 0.045, 0.04, 0.24, 6, skin if extra == "mask" else top.darkened(0.08))
		ab.ball(Transform3D(Basis(), Vector3(0, -0.57, 0)), 0.048, skin, true, 4, 6)
		if extra == "cap" and side > 0.0:
			ab.prism(Transform3D(down_b, Vector3(0, -0.08, 0)), 0.06, 0.06, 0.05, 6, accent, false)
		if extra == "coat" and side > 0.0:
			ab.prism(Transform3D(Basis(), Vector3(0, -0.66, -0.03)), 0.038, 0.045, 0.1, 6, Color("#f4efe6"))
		if extra == "mask" and side > 0.0:
			ab.box(Transform3D(Basis(), Vector3(0, -0.6, -0.06)), Vector3(0.05, 0.09, 0.012), Color("#1a1a22"))
		_mesh(_arm_r if side > 0.0 else _arm_l, ab, "Arm")

	# --- gambe ---
	_leg_l = _pivot(_body, "LegL", Vector3(-0.085, _hip_y, 0))
	_leg_r = _pivot(_body, "LegR", Vector3(0.085, _hip_y, 0))
	for leg in [_leg_l, _leg_r]:
		var lb := MeshBatch.new()
		lb.prism(Transform3D(Basis(Vector3.RIGHT, PI), Vector3.ZERO), 0.075, 0.052, 0.8, 6, bottom)
		lb.box(Transform3D(Basis(), Vector3(0, -0.83, -0.035)), Vector3(0.095, 0.08, 0.2), shoes)
		_mesh(leg, lb, "Leg")

	# ombra a macchia sotto i piedi
	_shadow = MeshInstance3D.new()
	_shadow.mesh = MeshBatch.disc(0.42 * _scale, Color(0.02, 0.0, 0.06, 0.55), 14, 0.015)
	_shadow.material_override = Toon.shadow()
	add_child(_shadow)


func _hair(hb: MeshBatch, style: String, hair: Color, accent: Color, extra: String) -> void:
	match style:
		"crew":
			hb.ball(Transform3D(Basis().scaled(Vector3(1.06, 0.62, 1.06)), Vector3(0, 0.2, 0.01)), 0.16, hair)
			# berretto con visiera
			hb.ball(Transform3D(Basis().scaled(Vector3(1.1, 0.55, 1.1)), Vector3(0, 0.25, 0.0)), 0.16, Color("#25324f"))
			hb.box(Transform3D(Basis(Vector3.RIGHT, 0.15), Vector3(0, 0.24, -0.17)), Vector3(0.22, 0.02, 0.12), Color("#141a2b"))
			hb.box(Transform3D(Basis(), Vector3(0, 0.29, -0.155)), Vector3(0.05, 0.035, 0.012), accent, false)
		"owl":
			hb.ball(Transform3D(Basis().scaled(Vector3(1.12, 1.0, 1.12)), Vector3(0, 0.19, 0.03)), 0.16, hair)
			hb.box(Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, 0.25, -0.12)), Vector3(0.3, 0.07, 0.08), hair)
			# ciuffi a orecchie di civetta
			for sx in [-1.0, 1.0]:
				hb.prism(Transform3D(Basis(Vector3.FORWARD, -0.45 * sx), Vector3(0.09 * sx, 0.3, 0.0)), 0.05, 0.0, 0.14, 5, hair)
			# capelli lunghi dietro
			hb.box(Transform3D(Basis(), Vector3(0, 0.05, 0.1)), Vector3(0.3, 0.3, 0.08), hair)
			hb.box(Transform3D(Basis(), Vector3(0.1, 0.23, -0.15)), Vector3(0.05, 0.02, 0.01), accent, false)
		"spiky":
			hb.ball(Transform3D(Basis().scaled(Vector3(1.05, 0.7, 1.05)), Vector3(0, 0.22, 0.02)), 0.16, hair)
			var dirs: Array = [Vector3(0, 1, 0.2), Vector3(0.6, 0.8, 0.2), Vector3(-0.6, 0.8, 0.2), Vector3(0.3, 0.7, 0.7), Vector3(-0.3, 0.7, 0.7), Vector3(0, 0.6, -0.8)]
			for d in dirs:
				var dn: Vector3 = (d as Vector3).normalized()
				var bas := Basis(Quaternion(Vector3.UP, dn))
				hb.prism(Transform3D(bas, Vector3(0, 0.22, 0.02) + dn * 0.1), 0.06, 0.0, 0.17, 5, hair)
			# la maschera: bianca, occhi viola, fascia gialla
			hb.ball(Transform3D(Basis().scaled(Vector3(0.95, 1.05, 0.5)), Vector3(0, 0.14, -0.09)), 0.15, Color("#f6f3ee"))
			for sx in [-1.0, 1.0]:
				hb.box(Transform3D(Basis(Vector3.BACK, 0.35 * sx), Vector3(0.055 * sx, 0.16, -0.165)), Vector3(0.06, 0.022, 0.01), Color(0.75, 0.3, 1.0, 0.0), false)
			hb.box(Transform3D(Basis(), Vector3(0, 0.07, -0.165)), Vector3(0.1, 0.012, 0.01), accent, false)
		_:
			# lunghi raccolti (Saul) con coda e berretto
			hb.ball(Transform3D(Basis().scaled(Vector3(1.08, 0.8, 1.1)), Vector3(0, 0.2, 0.02)), 0.16, hair)
			hb.box(Transform3D(Basis(Vector3.RIGHT, -0.3), Vector3(0, -0.02, 0.17)), Vector3(0.07, 0.26, 0.06), hair)
			hb.ball(Transform3D(Basis().scaled(Vector3(1.12, 0.5, 1.12)), Vector3(0, 0.27, 0.01)), 0.16, accent.darkened(0.45))
			hb.box(Transform3D(Basis(), Vector3(0.12, 0.2, -0.13)), Vector3(0.05, 0.12, 0.03), hair)


func _pivot(parent: Node3D, n: String, pos: Vector3) -> Node3D:
	var p := Node3D.new()
	p.name = n
	p.position = pos
	parent.add_child(p)
	return p


func _mesh(parent: Node3D, mb: MeshBatch, n: String) -> void:
	var mi: MeshInstance3D = mb.make_instance(n)
	parent.add_child(mi)
	_meshes.append(mi)


func _process(delta: float) -> void:
	if _body == null:
		return
	_t += delta
	var target_w: float = clampf(move_speed, 0.0, 1.0)
	_walk = lerpf(_walk, target_w, minf(1.0, delta * 10.0))
	_phase += delta * (5.0 + 5.5 * _walk) * (1.0 if _walk > 0.02 else 0.0)
	var w: float = _walk
	var s: float = sin(_phase)
	var breath: float = sin(_t * 2.2) * 0.008
	var st: float = 1.0 if stance else 0.0
	_leg_l.rotation = Vector3(s * 0.65 * w, 0, 0)
	_leg_r.rotation = Vector3(-s * 0.65 * w, 0, 0)
	_arm_l.rotation = Vector3(-s * 0.55 * w + arm_l_x + 0.35 * st, 0, -0.12 - 0.15 * st + arm_l_z)
	_arm_r.rotation = Vector3(s * 0.55 * w + arm_r_x + 0.45 * st, 0, 0.12 + 0.15 * st + arm_r_z)
	_hips.rotation = Vector3(-0.08 * w - lean - 0.06 * st, sin(_phase) * 0.08 * w, 0)
	_head.rotation = Vector3(0.05 * w + lean * 0.4, 0, sin(_t * 1.3) * 0.03 * (1.0 - w))
	var bob: float = absf(cos(_phase)) * 0.05 * w + breath
	_body.position = Vector3(0, bob + hop, 0)
	_body.rotation = Vector3(-fall * 1.45, 0, fall * 0.2)
	if _shadow != null:
		var k: float = clampf(1.0 - hop * 0.8, 0.4, 1.0)
		_shadow.scale = Vector3(k, 1, k)


# Punto sopra la testa, in coordinate globali (per numeri del danno e nomi)
func head_point() -> Vector3:
	return global_transform * Vector3(0, 1.95 * _scale, 0)


func chest_point() -> Vector3:
	return global_transform * Vector3(0, 1.25 * _scale, 0)


# ---------- azioni (ritornano il Tween: si puo' attendere con await tw.finished) ----------

func attack() -> Tween:
	var tw := create_tween()
	tw.tween_property(self, "arm_r_x", -2.6, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "lean", -0.15, 0.12)
	tw.tween_property(self, "arm_r_x", 0.6, 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "lean", 0.3, 0.1)
	tw.tween_interval(0.12)
	tw.tween_property(self, "arm_r_x", 0.0, 0.2)
	tw.parallel().tween_property(self, "lean", 0.0, 0.2)
	return tw


func cast() -> Tween:
	var tw := create_tween()
	tw.tween_property(self, "arm_r_x", -2.9, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "arm_l_x", -2.9, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "hop", 0.35, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "hop", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "arm_r_x", -0.4, 0.1)
	tw.parallel().tween_property(self, "arm_l_x", -0.4, 0.1)
	tw.tween_interval(0.12)
	tw.tween_property(self, "arm_r_x", 0.0, 0.2)
	tw.parallel().tween_property(self, "arm_l_x", 0.0, 0.2)
	return tw


func hit() -> Tween:
	_flash(true)
	var tw := create_tween()
	tw.tween_property(self, "lean", -0.45, 0.07)
	tw.tween_callback(_flash.bind(false))
	tw.tween_property(self, "lean", 0.0, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tw


func ko() -> Tween:
	down = true
	stance = false
	var tw := create_tween()
	tw.tween_property(self, "fall", 1.0, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	return tw


func cheer() -> Tween:
	var tw := create_tween()
	tw.tween_property(self, "arm_r_x", -3.0, 0.2)
	tw.parallel().tween_property(self, "hop", 0.3, 0.2)
	tw.tween_property(self, "hop", 0.0, 0.2)
	return tw


func _flash(on: bool) -> void:
	for mi in _meshes:
		(mi as MeshInstance3D).material_override = Toon.hit_flash() if on else null


# ---------- modello vero (glTF) al posto del segnaposto ----------
# Se esiste res://assets/characters/<id>/<id>.glb lo si usa. Per ora i modelli arrivano SENZA scheletro:
# i pezzi si dividono per nome in testa, busto, braccia e gambe e si appendono ai perni del segnaposto,
# cosi' le animazioni procedurali funzionano lo stesso. Quando arrivera' lo scheletro si passera' all'AnimationPlayer.
# Convenzione del file: Y in alto, metri, guarda verso +Z, origine fra i piedi.

const MODEL_PATH: String = "res://assets/characters/%s/%s.glb"
const _LEG: Array = ["trouser", "knee", "boot", "cargo_pocket", "pocket_flap", "leg", "shin", "thigh", "shoe"]
const _ARM: Array = ["upper_arm", "elbow", "forearm", "hand", "armband", "glove", "arma", "arm_", "sleeve"]
const _HEAD: Array = ["head", "hair", "ear", "eye", "brow", "nose", "mouth", "cap", "mask", "maschera", "face"]


static func has_model(char_id: String) -> bool:
	return ResourceLoader.exists(MODEL_PATH % [char_id, char_id])


func _group_of(n: String, x: float) -> String:
	var low: String = n.to_lower()
	for k in _HEAD:
		if low.begins_with(k):
			return "head"
	for k in _LEG:
		if low.begins_with(k):
			return "leg_l" if x < 0.0 else "leg_r"
	for k in _ARM:
		if low.begins_with(k) or low.contains(k):
			return "arm_l" if x < 0.0 else "arm_r"
	return "torso"


func _collect(n: Node, xf: Transform3D, out: Array) -> void:
	var here: Transform3D = xf
	if n is Node3D:
		here = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		out.append([n, here])
	for c in n.get_children():
		_collect(c, here, out)


func _build_from_model(char_id: String) -> bool:
	var path: String = MODEL_PATH % [char_id, char_id]
	if not ResourceLoader.exists(path):
		return false
	var ps: Variant = load(path)
	if not (ps is PackedScene):
		return false
	var inst: Node = (ps as PackedScene).instantiate()
	var parts: Array = []
	_collect(inst, Transform3D(), parts)
	if parts.is_empty():
		inst.free()
		return false
	# misure nel sistema del file
	var head_top: float = 0.0
	var leg_top: float = 0.0
	var sh_y: float = 0.0
	var sh_x: float = 0.0
	var neck_y: float = 99.0
	var leg_x: float = 0.0
	var all_top: float = 0.0
	for pr in parts:
		var mi: MeshInstance3D = pr[0]
		var box: AABB = (pr[1] as Transform3D) * mi.mesh.get_aabb()
		var low: String = mi.name.to_lower()
		all_top = maxf(all_top, box.end.y)
		if low.begins_with("head"):
			head_top = maxf(head_top, box.end.y)
			neck_y = minf(neck_y, box.position.y)
		if low.begins_with("trouser") or low.begins_with("leg") or low.begins_with("thigh"):
			leg_top = maxf(leg_top, box.end.y)
			leg_x = maxf(leg_x, absf(box.get_center().x))
		if low.begins_with("upper_arm"):
			sh_y = maxf(sh_y, box.end.y)
			sh_x = maxf(sh_x, absf(box.get_center().x))
	if head_top <= 0.0:
		head_top = all_top
	if leg_top <= 0.0:
		leg_top = head_top * 0.52
	if sh_y <= 0.0:
		sh_y = head_top * 0.8
	if neck_y > 90.0:
		neck_y = head_top * 0.86
	var k: float = 1.75 / head_top                     # altezza normalizzata; _body.scale porta poi all'altezza del personaggio
	var to_body := Transform3D(Basis(Vector3.UP, PI).scaled(Vector3(k, k, k)), Vector3.ZERO)   # +Z del file -> -Z del gioco
	_hip_y = leg_top * k
	_hips.position = Vector3(0, _hip_y, 0)
	_head = _pivot(_hips, "Head", Vector3(0, neck_y * k - _hip_y, 0))
	_arm_l = _pivot(_hips, "ArmL", Vector3(-sh_x * k, sh_y * k - 0.06 - _hip_y, 0))
	_arm_r = _pivot(_hips, "ArmR", Vector3(sh_x * k, sh_y * k - 0.06 - _hip_y, 0))
	_leg_l = _pivot(_body, "LegL", Vector3(-leg_x * k, _hip_y, 0))
	_leg_r = _pivot(_body, "LegR", Vector3(leg_x * k, _hip_y, 0))
	var pivots: Dictionary = {"torso": _hips, "head": _head, "arm_l": _arm_l, "arm_r": _arm_r, "leg_l": _leg_l, "leg_r": _leg_r}
	var flat: Dictionary = {}
	var smooth: Dictionary = {}
	for pr in parts:
		var mi: MeshInstance3D = pr[0]
		var xf_body: Transform3D = to_body * (pr[1] as Transform3D)
		var c: Vector3 = xf_body * mi.mesh.get_aabb().get_center()
		var g: String = _group_of(str(mi.name), c.x)
		var pv: Node3D = pivots[g]
		var pv_body: Transform3D = Transform3D(Basis(), pv.position)
		if pv.get_parent() == _hips:
			pv_body = Transform3D(Basis(), _hips.position + pv.position)
		elif pv == _hips:
			pv_body = Transform3D(Basis(), _hips.position)
		var local: Transform3D = pv_body.affine_inverse() * xf_body
		if not flat.has(g):
			flat[g] = SurfaceTool.new()
			smooth[g] = SurfaceTool.new()
		for si in mi.mesh.get_surface_count():
			(flat[g] as SurfaceTool).append_from(mi.mesh, si, local)
			(smooth[g] as SurfaceTool).append_from(mi.mesh, si, local)
	inst.free()
	for g in flat:
		var stf: SurfaceTool = flat[g]
		stf.deindex()
		stf.generate_normals()
		var body_mi := MeshInstance3D.new()
		body_mi.name = "Model_" + str(g)
		body_mi.mesh = stf.commit()
		body_mi.material_override = Toon.body()
		body_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		(pivots[g] as Node3D).add_child(body_mi)
		_meshes.append(body_mi)
		var sts: SurfaceTool = smooth[g]
		sts.generate_normals()
		var ink_mi := MeshInstance3D.new()
		ink_mi.name = "Ink_" + str(g)
		ink_mi.mesh = sts.commit()
		ink_mi.material_override = Toon.ink_grow()
		ink_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		(pivots[g] as Node3D).add_child(ink_mi)
	_shadow = MeshInstance3D.new()
	_shadow.mesh = MeshBatch.disc(0.42 * _scale, Color(0.02, 0.0, 0.06, 0.55), 14, 0.015)
	_shadow.material_override = Toon.shadow()
	add_child(_shadow)
	return true
