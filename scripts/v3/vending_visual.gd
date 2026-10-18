class_name VendingVisual
extends Node3D

# L'Anomalia "Distributore" in 3D (segnaposto PROVVISORIO): un distributore automatico posseduto.
# Stessa interfaccia di CharacterVisual per quello che serve al combattimento: attack() · hit() · ko() · head_point().

var awake: bool = false            # in strada dorme (ronza appena), in battaglia si muove
var stunned: bool = false
var _body: Node3D
var _meshes: Array = []
var _eyes: MeshInstance3D
var _t: float = 0.0
var hop: float = 0.0
var tilt: float = 0.0
var squash: float = 0.0
var fall: float = 0.0
var down: bool = false

const YEL: Color = Color("#ffc93c")


func _ready() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	var mb := MeshBatch.new()
	mb.ink_w = 0.035
	# mobile
	mb.box(Transform3D(Basis(), Vector3(0, 1.05, 0)), Vector3(1.15, 1.9, 0.85), YEL)
	mb.box(Transform3D(Basis(), Vector3(0, 0.08, 0)), Vector3(1.22, 0.16, 0.92), Color("#2a2233"))
	mb.box(Transform3D(Basis(), Vector3(0, 2.04, 0)), Vector3(1.22, 0.1, 0.92), Color("#2a2233"))
	# vetrina con i prodotti (luce propria)
	mb.box(Transform3D(Basis(), Vector3(-0.12, 1.25, -0.43)), Vector3(0.75, 1.1, 0.02), Color(0.08, 0.12, 0.28, 0.0), false)
	var prod: Array = [Color(1.0, 0.25, 0.45, 0.0), Color(0.25, 0.9, 1.0, 0.0), Color(0.6, 1.0, 0.3, 0.0), Color(1.0, 0.6, 0.15, 0.0)]
	for r in 4:
		for c in 3:
			var p: Color = prod[(r + c) % prod.size()]
			mb.box(Transform3D(Basis(), Vector3(-0.36 + 0.24 * c, 0.85 + 0.27 * r, -0.45)), Vector3(0.12, 0.17, 0.03), p, false)
		mb.box(Transform3D(Basis(), Vector3(-0.12, 0.76 + 0.27 * r, -0.45)), Vector3(0.72, 0.02, 0.04), Color(0.55, 0.6, 0.75, 0.0), false)
	# tastiera e fessura delle monete
	mb.box(Transform3D(Basis(), Vector3(0.4, 1.3, -0.44)), Vector3(0.22, 0.5, 0.03), Color("#3a3346"), false)
	for k in 6:
		mb.box(Transform3D(Basis(), Vector3(0.35 + 0.1 * (k % 2), 1.45 - 0.08 * float(k / 2), -0.46)), Vector3(0.06, 0.05, 0.02), Color("#e9e4f2"), false)
	# bocca (lo sportello) che morde
	mb.box(Transform3D(Basis(), Vector3(-0.1, 0.4, -0.43)), Vector3(0.8, 0.22, 0.05), Color("#0c0910"), false)
	for k in 5:
		mb.prism(Transform3D(Basis(Vector3.RIGHT, PI), Vector3(-0.42 + 0.16 * k, 0.51, -0.46)), 0.04, 0.0, 0.08, 4, Color("#f2f0ea"), false)
	# cavi che escono come zampe (l'Anomalia lo possiede)
	for sx in [-1.0, 1.0]:
		mb.prism(Transform3D(Basis(Vector3.BACK, 0.9 * sx), Vector3(0.58 * sx, 0.9, 0.1)), 0.05, 0.03, 0.9, 5, Color("#2a2233"))
		mb.ball(Transform3D(Basis(), Vector3(1.25 * sx, 1.4, 0.1)), 0.07, Color(1.0, 0.2, 0.55, 0.0), true, 4, 6)
	var mi: MeshInstance3D = mb.make_instance("Cabinet")
	_body.add_child(mi)
	_meshes.append(mi)
	# insegna in alto con gli occhi dell'Anomalia
	var eb := MeshBatch.new()
	eb.box(Transform3D(Basis(), Vector3(0, 1.88, -0.43)), Vector3(1.0, 0.24, 0.03), Color(0.06, 0.02, 0.08, 0.0), false)
	for sx in [-1.0, 1.0]:
		eb.box(Transform3D(Basis(Vector3.BACK, -0.35 * sx), Vector3(0.2 * sx, 1.89, -0.455)), Vector3(0.22, 0.07, 0.02), Color(1.0, 0.15, 0.3, 0.0), false)
	_eyes = eb.make_instance("Eyes")
	_body.add_child(_eyes)
	_meshes.append(_eyes)
	# bagliore sotto
	var g := MeshInstance3D.new()
	g.mesh = MeshBatch.disc(1.9, Color(1.0, 0.75, 0.2, 0.35), 18, 0.02)
	g.material_override = Toon.glow()
	add_child(g)
	var sh := MeshInstance3D.new()
	sh.mesh = MeshBatch.disc(0.95, Color(0.02, 0.0, 0.06, 0.6), 14, 0.025)
	sh.material_override = Toon.shadow()
	add_child(sh)


func _process(delta: float) -> void:
	_t += delta
	var hum: float = sin(_t * 31.0) * (0.004 if not awake else 0.0)
	var idle: float = sin(_t * 2.6) * 0.04 if awake and not stunned and not down else 0.0
	var wob: float = sin(_t * 9.0) * 0.12 if stunned else 0.0
	_body.position = Vector3(hum, hop + absf(idle) * 0.5, 0)
	_body.rotation = Vector3(-fall * 1.4 + tilt, 0, idle * 0.5 + wob)
	_body.scale = Vector3(1.0 + squash * 0.12, 1.0 - squash * 0.15, 1.0 + squash * 0.12)
	if _eyes != null:
		_eyes.visible = not down and (awake or fmod(_t, 2.4) < 2.2)


func head_point() -> Vector3:
	return global_transform * Vector3(0, 2.5, 0)


func chest_point() -> Vector3:
	return global_transform * Vector3(0, 1.3, 0)


func wake() -> Tween:
	awake = true
	var tw := create_tween()
	tw.tween_property(self, "squash", 0.6, 0.15)
	tw.tween_property(self, "squash", -0.4, 0.12)
	tw.parallel().tween_property(self, "hop", 0.6, 0.12)
	tw.tween_property(self, "hop", 0.0, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "squash", 0.0, 0.18)
	return tw


func attack() -> Tween:
	var tw := create_tween()
	tw.tween_property(self, "tilt", 0.25, 0.15)
	tw.parallel().tween_property(self, "squash", 0.5, 0.15)
	tw.tween_property(self, "tilt", -0.45, 0.08).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "squash", -0.3, 0.08)
	tw.tween_interval(0.12)
	tw.tween_property(self, "tilt", 0.0, 0.25)
	tw.parallel().tween_property(self, "squash", 0.0, 0.25)
	return tw


func slam() -> Tween:
	var tw := create_tween()
	tw.tween_property(self, "hop", 1.4, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "hop", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "squash", 0.8, 0.06)
	tw.tween_property(self, "squash", 0.0, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tw


func hit() -> Tween:
	_flash(true)
	var tw := create_tween()
	tw.tween_property(self, "tilt", -0.12, 0.06)
	tw.tween_callback(_flash.bind(false))
	tw.tween_property(self, "tilt", 0.0, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tw


func ko() -> Tween:
	down = true
	stunned = false
	var tw := create_tween()
	tw.tween_property(self, "fall", -0.6, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	return tw


func _flash(on: bool) -> void:
	for mi in _meshes:
		(mi as MeshInstance3D).material_override = Toon.hit_flash() if on else null
