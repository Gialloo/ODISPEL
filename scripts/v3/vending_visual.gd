class_name VendingVisual
extends Node3D

# L'Anomalia "Distributore" in 3D (segnaposto PROVVISORIO): un distributore automatico posseduto.
# Stessa interfaccia di CharacterVisual per quello che serve al combattimento: attack() · hit() · ko() · head_point().

var kind: String = "distributore"  # distributore, semaforo, cabina, manichino, cassaforte, frammento_<colore>
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


const HEADS: Dictionary = {"distributore": 2.5, "semaforo": 4.2, "cabina": 2.9, "manichino": 3.0, "cassaforte": 2.6, "frammento": 1.9}
const FRAG_COLORS: Dictionary = {"giallo": Color(1.0, 0.82, 0.25, 0.0), "rosso": Color(1.0, 0.25, 0.3, 0.0), "blu": Color(0.3, 0.65, 1.0, 0.0), "verde": Color(0.3, 1.0, 0.5, 0.0), "viola": Color(0.75, 0.35, 1.0, 0.0)}
var _cubes: Array = []


func _ready() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	match kind.split("_")[0]:
		"semaforo":
			_build_semaforo()
		"cabina":
			_build_cabina()
		"manichino":
			_build_manichino()
		"cassaforte":
			_build_cassaforte()
		"frammento":
			_build_frammento()
		_:
			_build_distributore()


func _ground(col: Color, r: float) -> void:
	var g := MeshInstance3D.new()
	g.mesh = MeshBatch.disc(r, col, 18, 0.02)
	g.material_override = Toon.glow()
	add_child(g)
	var sh := MeshInstance3D.new()
	sh.mesh = MeshBatch.disc(r * 0.5, Color(0.02, 0.0, 0.06, 0.6), 14, 0.025)
	sh.material_override = Toon.shadow()
	add_child(sh)


func _add(mb: MeshBatch, n: String) -> MeshInstance3D:
	var mi: MeshInstance3D = mb.make_instance(n)
	_body.add_child(mi)
	_meshes.append(mi)
	return mi


func _eyes_panel(y: float, z: float, w: float, col: Color) -> void:
	var eb := MeshBatch.new()
	for sx in [-1.0, 1.0]:
		eb.box(Transform3D(Basis(Vector3.BACK, -0.35 * sx), Vector3(w * 0.25 * sx, y, z)), Vector3(w * 0.22, 0.07, 0.02), col, false)
	_eyes = _add(eb, "Eyes")


func _build_semaforo() -> void:
	var mb := MeshBatch.new()
	mb.ink_w = 0.035
	var dark := Color("#2b2638")
	mb.prism(Transform3D(Basis(), Vector3.ZERO), 0.12, 0.1, 3.0, 8, dark)
	mb.box(Transform3D(Basis(), Vector3(0, 3.25, 0)), Vector3(0.62, 1.55, 0.5), Color("#3a3446"))
	var lights: Array = [Color(1.0, 0.18, 0.22, 0.0), Color(0.35, 0.3, 0.12), Color(0.12, 0.3, 0.18)]
	for i in 3:
		var y: float = 3.75 - 0.48 * i
		mb.prism(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, y, -0.26)), 0.19, 0.19, 0.04, 14, lights[i], false)
		mb.box(Transform3D(Basis(Vector3.RIGHT, -0.4), Vector3(0, y + 0.2, -0.38)), Vector3(0.46, 0.04, 0.26), dark)
	# braccia di cavi (l'Anomalia lo possiede)
	for sx in [-1.0, 1.0]:
		mb.lock(Vector3(sx * 0.3, 3.0, 0), Vector3(sx * 1.1, 3.4, -0.2), Vector3(sx * 1.6, 2.2, -0.5), 0.07, 0.07, Vector3.FORWARD, dark, true, 6)
		mb.ball(Transform3D(Basis(), Vector3(sx * 1.6, 2.2, -0.5)), 0.1, Color(1.0, 0.2, 0.3, 0.0), true, 4, 6)
	_add(mb, "Semaforo")
	_eyes_panel(3.75, -0.3, 0.5, Color(1.0, 0.95, 0.9, 0.0))
	_ground(Color(1.0, 0.2, 0.3, 0.35), 2.2)


func _build_cabina() -> void:
	var mb := MeshBatch.new()
	mb.ink_w = 0.035
	var blue := Color("#2a4f9e")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			mb.box(Transform3D(Basis(), Vector3(sx * 0.55, 1.2, sz * 0.55)), Vector3(0.12, 2.4, 0.12), blue)
	mb.box(Transform3D(Basis(), Vector3(0, 2.45, 0)), Vector3(1.3, 0.2, 1.3), blue.darkened(0.2))
	mb.box(Transform3D(Basis(), Vector3(0, 2.3, -0.62)), Vector3(1.0, 0.14, 0.03), Color(0.9, 0.95, 1.0, 0.0), false)
	mb.box(Transform3D(Basis(), Vector3(0, 0.05, 0)), Vector3(1.25, 0.1, 1.25), blue.darkened(0.3))
	for sx in [-1.0, 1.0]:
		mb.box(Transform3D(Basis(), Vector3(sx * 0.6, 1.2, 0)), Vector3(0.02, 2.0, 1.0), Color(0.12, 0.3, 0.55, 0.0), false)
	mb.box(Transform3D(Basis(), Vector3(0, 1.2, 0.6)), Vector3(1.0, 2.0, 0.02), Color(0.12, 0.3, 0.55, 0.0), false)
	mb.box(Transform3D(Basis(), Vector3(0, 1.4, 0.45)), Vector3(0.35, 0.5, 0.15), Color("#1a1a22"))
	mb.lock(Vector3(0.12, 1.35, 0.35), Vector3(0.3, 0.9, 0.0), Vector3(0.1, 0.6, -0.3), 0.025, 0.025, Vector3.RIGHT, Color("#1a1a22"), false, 6)
	mb.box(Transform3D(Basis(Vector3.BACK, 0.6), Vector3(0.1, 0.62, -0.32)), Vector3(0.3, 0.08, 0.08), Color("#1a1a22"))
	_add(mb, "Cabina")
	_eyes_panel(1.9, -0.62, 0.7, Color(0.4, 0.85, 1.0, 0.0))
	_ground(Color(0.3, 0.6, 1.0, 0.35), 2.0)


func _build_manichino() -> void:
	# un manichino gigante senza faccia, su un piedistallo
	var mb := MeshBatch.new()
	mb.ink_w = 0.035
	mb.prism(Transform3D(Basis(), Vector3.ZERO), 0.8, 0.7, 0.35, 16, Color("#cfc9be"))
	_add(mb, "Base")
	var cv := CharacterVisual.new()
	cv.setup("zecca", {"faceless": true, "nomask": true, "skin": "#efece6", "hair": "#e2ddd4", "top": "#f5f2ec", "bottom": "#d8d2c6", "accent": "#46e07a", "shoes": "#c4beb2"})
	cv.position = Vector3(0, 0.35, 0)
	cv.scale = Vector3.ONE * 1.35
	cv.stance = true
	_body.add_child(cv)
	for c in cv.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(c)
	_ground(Color(0.3, 1.0, 0.5, 0.3), 2.0)


func _build_cassaforte() -> void:
	var mb := MeshBatch.new()
	mb.ink_w = 0.04
	var steel := Color("#6c7484")
	mb.box(Transform3D(Basis(), Vector3(0, 1.0, 0)), Vector3(1.8, 2.0, 1.3), steel)
	mb.box(Transform3D(Basis(), Vector3(0, 1.0, -0.66)), Vector3(1.5, 1.7, 0.05), steel.darkened(0.2))
	mb.prism(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 1.05, -0.7)), 0.34, 0.34, 0.08, 18, Color("#aab0c0"))
	mb.prism(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 1.05, -0.78)), 0.12, 0.12, 0.06, 12, Color("#30343e"))
	for k in 4:
		var a: float = TAU * float(k) / 4.0 + 0.4
		mb.box(Transform3D(Basis(Vector3.BACK, a), Vector3(cos(a) * 0.5, 1.05 + sin(a) * 0.5, -0.74)), Vector3(0.36, 0.06, 0.06), Color("#aab0c0"))
	for x in [-0.65, 0.65]:
		for y in [0.3, 1.7]:
			mb.ball(Transform3D(Basis(), Vector3(x, y, -0.7)), 0.05, Color("#8a90a0"), false, 4, 6)
	_add(mb, "Cassaforte")
	_eyes_panel(1.62, -0.72, 0.9, Color(0.35, 1.0, 0.55, 0.0))
	_ground(Color(0.3, 1.0, 0.5, 0.3), 2.2)


func _build_frammento() -> void:
	# anomalia minore: tre cubi luminosi che girano intorno a un nucleo
	var col: Color = FRAG_COLORS.get(kind.split("_")[1] if kind.contains("_") else "viola", FRAG_COLORS["viola"])
	var core := MeshBatch.new()
	core.ink_w = 0.03
	core.ball(Transform3D(Basis(), Vector3(0, 1.1, 0)), 0.28, Color(0.08, 0.05, 0.12))
	core.ball(Transform3D(Basis(), Vector3(0, 1.1, -0.22)), 0.1, col, false, 4, 8)
	_add(core, "Core")
	for i in 3:
		var cb := MeshBatch.new()
		cb.ink_w = 0.025
		cb.box(Transform3D(Basis(), Vector3.ZERO), Vector3(0.3, 0.3, 0.3), Color(col.r * 0.5, col.g * 0.5, col.b * 0.5))
		cb.box(Transform3D(Basis(), Vector3.ZERO), Vector3(0.18, 0.31, 0.18), col, false)
		var mi := _add(cb, "Cube")
		_cubes.append(mi)
	_ground(Color(col.r, col.g, col.b, 0.35), 1.2)


func _build_distributore() -> void:
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
	for i in _cubes.size():
		var a: float = _t * 1.6 + TAU * float(i) / 3.0
		(_cubes[i] as Node3D).position = Vector3(cos(a) * 0.6, 1.1 + sin(_t * 2.0 + i) * 0.25, sin(a) * 0.6)
		(_cubes[i] as Node3D).rotation = Vector3(_t * 1.3 + i, _t * 0.9, 0)
	var hum: float = sin(_t * 31.0) * (0.004 if not awake else 0.0)
	var idle: float = sin(_t * 2.6) * 0.04 if awake and not stunned and not down else 0.0
	var wob: float = sin(_t * 9.0) * 0.12 if stunned else 0.0
	_body.position = Vector3(hum, hop + absf(idle) * 0.5, 0)
	_body.rotation = Vector3(-fall * 1.4 + tilt, 0, idle * 0.5 + wob)
	_body.scale = Vector3(1.0 + squash * 0.12, 1.0 - squash * 0.15, 1.0 + squash * 0.12)
	if _eyes != null:
		_eyes.visible = not down and (awake or fmod(_t, 2.4) < 2.2)


func head_point() -> Vector3:
	return global_transform * Vector3(0, float(HEADS.get(kind.split("_")[0], 2.5)), 0)


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
