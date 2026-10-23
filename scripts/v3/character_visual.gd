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

# Oggetti mossi dal motore: carte che girano attorno a Saul
var kit: String = ""
var _mace: Node3D
var _mace_pos: Vector3
var _links: Array = []
var _mascot: Node3D
var _cards: Array = []
var _swing: float = 0.0              # 0..1 durante l'attacco: la mazza vola in avanti


func setup(char_id: String, override: Dictionary = {}) -> void:
	id = char_id
	var sp: Dictionary = CastVisual.spec(char_id).duplicate()
	if char_id == "zecca" and mask_cracked():
		sp["mask_crack"] = true          # la crepa resta per il resto dell'atto (un ritratto puo' toglierla con l'override)
	sp.merge(override, true)            # espressioni dei portrait: sopracciglia, palpebre, bocca...
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
	if override.is_empty() and _build_from_model(char_id):
		return

	# --- stile anime semplificato (AnimeBuilder) ---
	_hip_y = AnimeBuilder.HIP_Y
	_hips.position = Vector3(0, _hip_y, 0)
	var sw: float = (0.14 if bool(sp.get("fem", false)) else 0.168) * b
	_mesh(_hips, AnimeBuilder.torso(sp), "Torso")
	_head = _pivot(_hips, "Head", Vector3(0, AnimeBuilder.NECK_Y, 0))
	_head.scale = Vector3.ONE * 1.16         # testa grande da anime: si legge meglio sul telefono
	_mesh(_head, AnimeBuilder.head(sp), "HeadMesh")
	_arm_l = _pivot(_hips, "ArmL", Vector3(-sw - 0.035, AnimeBuilder.SHOULDER_Y, 0))
	_arm_r = _pivot(_hips, "ArmR", Vector3(sw + 0.035, AnimeBuilder.SHOULDER_Y, 0))
	_mesh(_arm_l, AnimeBuilder.arm(sp, -1.0), "Arm")
	_mesh(_arm_r, AnimeBuilder.arm(sp, 1.0), "Arm")
	_leg_l = _pivot(_body, "LegL", Vector3(-0.088, _hip_y, 0))
	_leg_r = _pivot(_body, "LegR", Vector3(0.088, _hip_y, 0))
	_mesh(_leg_l, AnimeBuilder.leg(sp, -1.0), "Leg")
	_mesh(_leg_r, AnimeBuilder.leg(sp, 1.0), "Leg")
	_shadow = MeshInstance3D.new()
	_shadow.mesh = MeshBatch.disc(0.42 * _scale, Color(0.02, 0.0, 0.06, 0.55), 14, 0.015)
	_shadow.material_override = Toon.shadow()
	add_child(_shadow)
	kit = str(sp.get("kit", ""))
	if not bool(sp.get("no_props", false)):
		_build_props(sp)


# La maschera di Rio si incrina nel capitolo 3 (Vetrina), dopo lo scontro col Manichino, e resta incrinata fino alla fine dell'atto
static func mask_cracked() -> bool:
	return Story.chapter > 3 or (Story.chapter == 3 and Story.step >= 4)


# Personaggio fermo "cotto" in una sola mesh (2 superfici: corpo + contorno). Serve per le comparse immobili
# (i manichini della galleria): con un MultiMesh si disegnano tutte insieme in 2 chiamate invece di ~12 a testa.
static func baked_mesh(char_id: String, override: Dictionary) -> ArrayMesh:
	var cv := CharacterVisual.new()
	cv.setup(char_id, override)
	var tools: Array = [SurfaceTool.new(), SurfaceTool.new()]
	for st in tools:
		(st as SurfaceTool).begin(Mesh.PRIMITIVE_TRIANGLES)
	var stack: Array = [[cv, Transform3D()]]
	while not stack.is_empty():
		var it: Array = stack.pop_back()
		var n: Node = it[0]
		var xf: Transform3D = it[1]
		for c in n.get_children():
			if c is Node3D:
				var cx: Transform3D = xf * (c as Node3D).transform
				if c is MeshInstance3D and c != cv._shadow and (c as MeshInstance3D).mesh is ArrayMesh:
					var m: ArrayMesh = (c as MeshInstance3D).mesh
					for si in mini(2, m.get_surface_count()):
						(tools[si] as SurfaceTool).append_from(m, si, cx)
				stack.append([c, cx])
	var out := ArrayMesh.new()
	for st in tools:
		var arr: Array = (st as SurfaceTool).commit_to_arrays()
		if arr.size() > 0 and arr[Mesh.ARRAY_VERTEX] != null and (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() > 0:
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	cv.free()
	return out


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
	# mai rigidi di fronte: da fermi un leggero contrapposto, in battaglia una posa diagonale (gambe larghe, busto girato e in avanti)
	var idle: float = (1.0 - w) * (1.0 - st)
	_leg_l.rotation = Vector3(s * 0.65 * w - 0.32 * st, 0, -0.2 * st - 0.04 * idle)
	_leg_r.rotation = Vector3(-s * 0.65 * w + 0.26 * st, 0, 0.2 * st + 0.02 * idle)
	_arm_l.rotation = Vector3(-s * 0.55 * w + arm_l_x + 0.35 * st, 0, -0.12 - 0.22 * st + arm_l_z)
	_arm_r.rotation = Vector3(s * 0.55 * w + arm_r_x + 0.45 * st, 0, 0.12 + 0.22 * st + arm_r_z)
	_hips.rotation = Vector3(-0.08 * w - lean - 0.2 * st - 0.04 * idle, sin(_phase) * 0.08 * w + 0.38 * st, 0.05 * idle)
	_head.rotation = Vector3(0.05 * w + lean * 0.4 + 0.08 * st, -0.3 * st, sin(_t * 1.3) * 0.03 * (1.0 - w) - 0.05 * idle)
	var bob: float = absf(cos(_phase)) * 0.05 * w + breath - 0.07 * st * _scale
	_body.position = Vector3(0, bob + hop, 0)
	_update_props(delta)
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
	if _mace != null:
		var sw := create_tween()
		sw.tween_property(self, "_swing", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		sw.tween_interval(0.15)
		sw.tween_property(self, "_swing", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
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


# Torna in piedi (Rispondo io di Nox)
func revive() -> Tween:
	down = false
	stance = true
	var tw := create_tween()
	tw.tween_property(self, "fall", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tw


func cheer() -> Tween:
	var tw := create_tween()
	tw.tween_property(self, "arm_r_x", -3.0, 0.2)
	tw.parallel().tween_property(self, "hop", 0.3, 0.2)
	tw.tween_property(self, "hop", 0.0, 0.2)
	return tw


# ---------- oggetti del kit ----------

func _build_props(sp: Dictionary) -> void:
	var metal: Color = AnimeBuilder._m(Color(str(sp.get("metal", "#c4cad6"))))
	var gold: Color = AnimeBuilder._m(Color(str(sp.get("gold", "#e0b54a"))))
	match kit:
		"corriere":
			# carte da gioco che girano attorno (il trucco del truffatore)
			var cb := MeshBatch.new()
			cb.ink_w = 0.004
			cb.box(Transform3D(), Vector3(0.08, 0.115, 0.004), Color("#f4efe6"))
			cb.box(Transform3D(Basis(Vector3.BACK, PI * 0.25), Vector3(0, 0, -0.003)), Vector3(0.03, 0.03, 0.002), Color(0.35, 0.95, 0.5, 0.0), false)
			cb.box(Transform3D(Basis(), Vector3(0, 0, 0.003)), Vector3(0.066, 0.1, 0.002), Color("#2f8f5a").darkened(0.3), false)
			var card_mesh: ArrayMesh = cb.build()
			for i in (0 if Settings.light_fx else 3):
				var ci := MeshInstance3D.new()
				ci.mesh = card_mesh
				Toon.dress(ci)
				add_child(ci)
				_cards.append(ci)


func _inst(mb: MeshBatch, n: String) -> MeshInstance3D:
	var mi: MeshInstance3D = mb.make_instance(n)
	_meshes.append(mi)
	return mi


func _update_props(delta: float) -> void:
	if _mace != null and _arm_r != null:
		var hand: Vector3 = transform.affine_inverse() * (_arm_r.global_transform * Vector3(0, -0.72, 0.02))
		var rest := Vector3(0.62, 0.27, 0.5) * _scale
		if stance:
			rest = Vector3(0.75, 0.27, 0.1) * _scale
		if down:
			rest = Vector3(0.6, 0.27, 0.3) * _scale
		var fly: Vector3 = hand + Vector3(0.1, 0.2, -1.2) * _scale
		var target: Vector3 = rest.lerp(fly, _swing)
		_mace_pos = _mace_pos.lerp(target, minf(1.0, delta * (14.0 if _swing > 0.01 else 5.0)))
		_mace_pos.y = maxf(_mace_pos.y, 0.27 * _scale)
		_mace.position = _mace_pos
		_mace.rotation.y += delta * (6.0 * _swing + 0.4 * _walk)
		# catena: curva che pende fra il manico e la sfera
		var mid: Vector3 = (hand + _mace_pos) * 0.5 + Vector3(0, -0.25 * (1.0 - _swing), 0)
		mid.y = maxf(mid.y, 0.03)
		for i in _links.size():
			var t: float = (float(i) + 0.5) / float(_links.size())
			var p: Vector3 = hand.lerp(mid, t).lerp(mid.lerp(_mace_pos, t), t)
			var tg: Vector3 = (2.0 * (1.0 - t) * (mid - hand) + 2.0 * t * (_mace_pos - mid)).normalized()
			var li: MeshInstance3D = _links[i]
			li.position = p
			if tg.length() > 0.01:
				var up: Vector3 = tg
				var side: Vector3 = up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
				li.basis = Basis(side, up, side.cross(up)).rotated(up, PI * 0.5 * float(i % 2)) * Basis().scaled(Vector3.ONE * _scale)
	if _mascot != null:
		var want := Vector3(-0.42, 1.85 + 0.06 * sin(_t * 2.4), 0.12) * _scale
		if down:
			want = Vector3(-0.3, 0.5, 0.0) * _scale
		_mascot.position = _mascot.position.lerp(want, minf(1.0, delta * 3.0))
		_mascot.rotation = Vector3(0.1 * sin(_t * 1.7), 0.25 * sin(_t * 0.9), 0.12 * sin(_t * 2.4))
	for i in _cards.size():
		var a: float = _t * 0.9 + TAU * float(i) / float(_cards.size())
		var ci: MeshInstance3D = _cards[i]
		ci.position = Vector3(cos(a) * 0.62, 1.05 + 0.25 * sin(a * 1.7 + float(i)), sin(a) * 0.5) * _scale
		ci.rotation = Vector3(0.3 * sin(_t + float(i)), -a + PI * 0.5, 0.4 * cos(_t * 1.3 + float(i)))
		ci.visible = not down


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
