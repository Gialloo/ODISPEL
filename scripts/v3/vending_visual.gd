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


const HEADS: Dictionary = {"distributore": 2.5, "semaforo": 4.2, "cabina": 2.9, "manichino": 3.0, "cassaforte": 2.6, "frammento": 1.9, "telecamera": 3.4, "autovelox": 3.1}
const FRAG_COLORS: Dictionary = {"giallo": Color(1.0, 0.82, 0.25, 0.0), "rosso": Color(1.0, 0.25, 0.3, 0.0), "blu": Color(0.3, 0.65, 1.0, 0.0), "verde": Color(0.3, 1.0, 0.5, 0.0), "viola": Color(0.75, 0.35, 1.0, 0.0)}
var _cubes: Array = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
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
		"telecamera":
			_build_telecamera()
		"autovelox":
			_build_autovelox()
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
	cv.setup("rio", {"faceless": true, "nomask": true, "kit": "", "no_props": true, "skin": "#efece6", "hair": "#e2ddd4", "top": "#f5f2ec", "bottom": "#d8d2c6", "accent": "#46e07a", "shoes": "#c4beb2"})
	cv.position = Vector3(0, 0.35, 0)
	cv.scale = Vector3.ONE * 1.35
	cv.stance = true
	_body.add_child(cv)
	for c in cv.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(c)
	_ground(Color(0.3, 1.0, 0.5, 0.3), 2.0)


# Boss segreto di prova: una telecamera di sorveglianza gigante su un palo, con l'obiettivo rosso acceso
func _build_telecamera() -> void:
	var mb := MeshBatch.new()
	mb.ink_w = 0.04
	var grey := Color("#d9d6e0")
	var dark := Color("#2b2638")
	mb.prism(Transform3D(Basis(), Vector3.ZERO), 0.14, 0.12, 2.7, 8, dark)
	mb.box(Transform3D(Basis(), Vector3(0, 2.75, 0.1)), Vector3(0.3, 0.3, 0.5), dark)
	# corpo della telecamera, inclinato verso il basso
	var tilt := Basis(Vector3.RIGHT, 0.22)
	mb.box(Transform3D(tilt, Vector3(0, 3.2, -0.35)), Vector3(0.9, 0.75, 1.7), grey)
	mb.box(Transform3D(tilt, Vector3(0, 3.62, -0.45)), Vector3(1.05, 0.08, 1.95), grey.darkened(0.15))
	mb.prism(Transform3D(tilt * Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 3.0, -1.22)), 0.33, 0.33, 0.16, 18, dark)
	mb.prism(Transform3D(tilt * Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 2.98, -1.3)), 0.22, 0.22, 0.04, 16, Color(1.0, 0.15, 0.25, 0.0), false)
	mb.ball(Transform3D(Basis(), Vector3(0.36, 3.5, -1.0)), 0.05, Color(1.0, 0.2, 0.3, 0.0), false, 4, 6)
	# cavi come braccia (l'Anomalia la possiede)
	for sx in [-1.0, 1.0]:
		mb.lock(Vector3(sx * 0.2, 2.6, 0), Vector3(sx * 1.2, 2.4, -0.3), Vector3(sx * 1.7, 1.3, -0.6), 0.06, 0.06, Vector3.FORWARD, dark, true, 6)
		mb.ball(Transform3D(Basis(), Vector3(sx * 1.7, 1.3, -0.6)), 0.12, Color(0.75, 0.35, 1.0, 0.0), true, 4, 6)
	_add(mb, "Telecamera")
	_ground(Color(0.75, 0.35, 1.0, 0.35), 2.4)


# Capitolo 5: l'autovelox del casello. Cassetta grigia su un palo, obiettivo e flash, cavi come braccia.
func _build_autovelox() -> void:
	var mb := MeshBatch.new()
	mb.ink_w = 0.04
	var grey := Color("#c9cbd4")
	var dark := Color("#2b2638")
	mb.prism(Transform3D(Basis(), Vector3.ZERO), 0.13, 0.11, 2.2, 8, dark)
	mb.box(Transform3D(Basis(), Vector3(0, 2.85, 0)), Vector3(1.1, 1.3, 0.9), grey)
	mb.box(Transform3D(Basis(), Vector3(0, 3.55, -0.05)), Vector3(1.25, 0.12, 1.05), grey.darkened(0.2))
	mb.box(Transform3D(Basis(), Vector3(0, 2.3, -0.46)), Vector3(0.9, 0.12, 0.02), Color(1.0, 0.82, 0.25, 0.0), false)
	# obiettivo e flash
	mb.prism(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.2, 2.75, -0.45)), 0.24, 0.24, 0.1, 16, dark)
	mb.prism(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.2, 2.75, -0.5)), 0.16, 0.16, 0.02, 14, Color(1.0, 0.85, 0.3, 0.0), false)
	mb.box(Transform3D(Basis(), Vector3(0.3, 2.95, -0.46)), Vector3(0.3, 0.45, 0.02), Color(1.0, 1.0, 0.95, 0.0), false)
	# cavi come braccia
	for sx in [-1.0, 1.0]:
		mb.lock(Vector3(sx * 0.5, 2.6, 0), Vector3(sx * 1.4, 2.4, -0.3), Vector3(sx * 1.8, 1.2, -0.6), 0.06, 0.06, Vector3.FORWARD, dark, true, 6)
		mb.ball(Transform3D(Basis(), Vector3(sx * 1.8, 1.2, -0.6)), 0.12, Color(1.0, 0.82, 0.25, 0.0), true, 4, 6)
	_add(mb, "Autovelox")
	_eyes_panel(3.25, -0.47, 0.7, Color(1.0, 0.9, 0.4, 0.0))
	_ground(Color(1.0, 0.8, 0.25, 0.35), 2.3)


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
	_body.rotation = Vector3(-fall * 1.4 + tilt, spin, idle * 0.5 + wob + side)
	_body.scale = Vector3(1.0 + squash * 0.12, 1.0 - squash * 0.15, 1.0 + squash * 0.12) * maxf(0.001, 1.0 - shrink)
	if not _bits.is_empty():
		_bits_step(delta)
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
	var fin: Tween = _finale()
	if fin != null:
		return fin
	var tw := create_tween()
	tw.tween_property(self, "fall", -0.6, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	return tw


# ---------------------------------------------------------------- COLPO FINALE DIVERSO PER OGNI NEMICO
# 4/11/2026 (autore: «fai il 3»): ogni Anomalia muore a modo suo, come l'oggetto che e'. Gli oggetti raccontano i personaggi (U20):
# il semaforo impazzisce nei suoi tre colori e cade come un albero, la cassaforte si spalanca e sputa monete, la telecamera
# va in frantumi, l'autovelox scatta le sue ultime foto, la cabina squilla a vuoto e crolla, il distributore vomita lattine
# e finisce a faccia in giu', il manichino fa la sua ultima posa e si accascia, il frammento si sbriciola nel suo colore.
# Niente disegni nuovi: pezzi fatti con MeshBatch (le stesse forme del modello), scintille di LightFx, le stesse molle di ko().
# Telefono: al massimo 14 pezzi per 1,8 s, nessuna luce, nessuna particella della GPU; con «effetti ridotti» la meta'.
# Nel combattimento parte insieme al COLPO FINALE: il rallentatore e il fermo immagine colgono i pezzi a mezz'aria.

const FINALE_WORDS: Dictionary = {"semaforo": "BLINK", "cassaforte": "KA-CHING", "telecamera": "KRASH", "autovelox": "FLASH",
	"cabina": "DRIIN", "distributore": "CLUNK", "manichino": "CRAC", "frammento": "PUFF"}

var side: float = 0.0       # caduta di lato (semaforo)
var spin: float = 0.0       # giro su se stesso (cabina)
var shrink: float = 0.0     # si dissolve (frammento)
var _bits: Array = []       # [MeshInstance3D, velocita', rotazione, vita]


static func finale_word(k: String) -> String:
	return str(FINALE_WORDS.get(k.split("_")[0], "K.O."))


# Per il combattimento: si segna subito come abbattuto e la piccola morte parte quando parte il colpo finale (stesso ritardo, tempo reale).
func finale(delay: float) -> void:
	down = true
	stunned = false
	if delay > 0.01:
		await get_tree().create_timer(delay, true, false, true).timeout
	if is_inside_tree():
		ko()


func _finale() -> Tween:
	match kind.split("_")[0]:
		"semaforo":
			return _fin_semaforo()
		"cassaforte":
			return _fin_cassaforte()
		"telecamera":
			return _fin_telecamera()
		"autovelox":
			return _fin_autovelox()
		"cabina":
			return _fin_cabina()
		"distributore":
			return _fin_distributore()
		"manichino":
			return _fin_manichino()
		"frammento":
			return _fin_frammento()
	return null


func _at(local: Vector3) -> Vector3:
	return global_transform * local


func _n(n: int) -> int:
	return maxi(2, n / 2) if Settings.light_fx else n


# Pezzi che volano via e rimbalzano a terra: un solo modello, copiato (la mesh e' condivisa).
func _burst(mb: MeshBatch, from: Vector3, n: int, dir: Vector3, speed: float, up: float, spread: float) -> void:
	var proto: MeshInstance3D = mb.make_instance("Bit")
	proto.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in _n(n):
		var mi: MeshInstance3D = proto if i == 0 else proto.duplicate() as MeshInstance3D
		mi.position = from
		add_child(mi)
		var v: Vector3 = dir * speed * _rng.randf_range(0.6, 1.1) + Vector3.UP * up * _rng.randf_range(0.7, 1.2)
		v += Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.2, 0.4), _rng.randf_range(-1, 1)) * spread
		_bits.append([mi, v, Vector3(_rng.randf_range(-9, 9), _rng.randf_range(-9, 9), _rng.randf_range(-9, 9)), 0.0])


func _bits_step(delta: float) -> void:
	for i in range(_bits.size() - 1, -1, -1):
		var bt: Array = _bits[i]
		var mi: MeshInstance3D = bt[0]
		if not is_instance_valid(mi):
			_bits.remove_at(i)
			continue
		var v: Vector3 = bt[1]
		bt[3] = float(bt[3]) + delta
		v.y -= 9.8 * delta
		mi.position += v * delta
		if mi.position.y < 0.06:
			mi.position.y = 0.06
			v = Vector3(v.x * 0.55, absf(v.y) * 0.35, v.z * 0.55)
			bt[2] = (bt[2] as Vector3) * 0.6
		mi.rotation += (bt[2] as Vector3) * delta
		bt[1] = v
		var life: float = float(bt[3])
		if life > 1.4:
			mi.scale = Vector3.ONE * maxf(0.0, 1.0 - (life - 1.4) / 0.4)
		if life > 1.8:
			mi.queue_free()
			_bits.remove_at(i)


func _spark_at(local: Vector3, c: Color, n: int, d: float = 0.4) -> void:
	LightFx.sparks(self, _at(local), c, n, d)


# Il semaforo impazzisce: rosso, giallo, verde a raffica, poi cade di lato come un albero e sputa le ultime luci a terra.
func _fin_semaforo() -> Tween:
	var cols: Array = [Color(1.0, 0.18, 0.22), Color(1.0, 0.8, 0.2), Color(0.3, 1.0, 0.5)]
	var tw := create_tween()
	tw.tween_property(self, "squash", 0.5, 0.06)
	for r in 2:
		for i in 3:
			tw.tween_callback(_spark_at.bind(Vector3(0, 3.75 - 0.48 * i, -0.3), cols[i], 8 if r == 0 else 5, 0.35))
			tw.tween_interval(0.07)
	tw.tween_property(self, "squash", 0.0, 0.1)
	tw.tween_property(self, "side", 1.42, 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_callback(_fin_semaforo_terra).set_delay(0.3)
	return tw


# La cassaforte salta, si spalanca e sputa monete d'oro; poi si siede, pesante, svuotata.
func _fin_cassaforte() -> Tween:
	var tw := create_tween()
	tw.tween_property(self, "hop", 0.7, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "squash", -0.5, 0.14)
	tw.tween_callback(_fin_monete)
	tw.tween_property(self, "hop", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "squash", 0.9, 0.07)
	tw.tween_property(self, "fall", -0.22, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "squash", 0.15, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tw


# La telecamera va in frantumi: l'obiettivo esplode in schegge di vetro, poi la testa si piega e il palo crolla.
func _fin_telecamera() -> Tween:
	var tw := create_tween()
	tw.tween_callback(_fin_schegge)
	tw.tween_property(self, "tilt", 0.55, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.12)
	tw.tween_property(self, "fall", -0.62, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "tilt", 0.0, 0.3)
	return tw


# L'autovelox scatta le sue ultime tre foto (lampi a raffica, sempre piu' deboli), l'ultima esce stampata, poi crolla all'indietro.
func _fin_autovelox() -> Tween:
	var tw := create_tween()
	for i in 3:
		tw.tween_callback(_spark_at.bind(Vector3(0.3, 2.95, -0.5), LightFx.IVORY, 16 - 4 * i, 0.3))
		tw.tween_property(self, "squash", 0.45 - 0.12 * i, 0.05)
		tw.tween_property(self, "squash", 0.0, 0.1)
	tw.tween_callback(_fin_foto)
	tw.tween_property(self, "fall", -0.6, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	return tw


# La cabina squilla a vuoto (trema), la cornetta vola via, i vetri saltano, mezzo giro e crolla in avanti.
func _fin_cabina() -> Tween:
	var tw := create_tween()
	for i in 3:
		tw.tween_property(self, "tilt", 0.08, 0.035)
		tw.tween_property(self, "tilt", -0.08, 0.035)
	tw.tween_property(self, "tilt", 0.0, 0.03)
	tw.tween_callback(_fin_cornetta)
	tw.tween_property(self, "spin", PI * 0.5, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "fall", 0.62, 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	return tw


# Il distributore vomita la sua merce (lattine di tutti i colori della vetrina) e cade a faccia in giu'.
func _fin_distributore() -> Tween:
	var tw := create_tween()
	tw.tween_property(self, "squash", -0.45, 0.08)
	tw.tween_callback(_fin_lattine)
	tw.tween_property(self, "squash", 0.0, 0.1)
	tw.tween_interval(0.1)
	tw.tween_property(self, "fall", 0.6, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	return tw


# Il manichino fa la sua ultima posa da vetrina (un giro su se stesso), poi si accascia come una persona; il piedistallo resta.
func _fin_manichino() -> Tween:
	var cv: CharacterVisual = null
	for ch in _body.get_children():
		if ch is CharacterVisual:
			cv = ch
	var tw := create_tween()
	if cv == null:
		tw.tween_property(self, "fall", -0.6, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		return tw
	tw.tween_property(cv, "rotation:y", TAU, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_fin_posa.bind(cv))
	tw.tween_property(self, "squash", 0.35, 0.08)
	tw.tween_property(self, "squash", 0.0, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tw


# Il frammento si sbriciola: i tre cubi smettono di girare e schizzano via, il nucleo si spegne nel suo colore.
func _fin_frammento() -> Tween:
	var col: Color = FRAG_COLORS.get(kind.split("_")[1] if kind.contains("_") else "viola", FRAG_COLORS["viola"])
	var cubes: Array = _cubes.duplicate()
	_cubes.clear()
	for mi in cubes:
		var m: MeshInstance3D = mi
		var p: Vector3 = m.global_position
		m.reparent(self)
		m.global_position = p
		var out: Vector3 = Vector3(m.position.x, 0, m.position.z).normalized()
		_bits.append([m, out * 3.2 + Vector3.UP * 2.6, Vector3(_rng.randf_range(-8, 8), _rng.randf_range(-8, 8), 0), 0.0])
	_spark_at(Vector3(0, 1.1, 0), Color(col.r, col.g, col.b), 16, 0.5)
	var tw := create_tween()
	tw.tween_property(self, "squash", -0.6, 0.1)
	tw.tween_property(self, "shrink", 1.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "squash", 0.0, 0.45)
	return tw


func _fin_semaforo_terra() -> void:
	var mb := MeshBatch.new()
	mb.ball(Transform3D(), 0.09, Color(1.0, 0.8, 0.2, 0.0), false, 4, 6)
	_burst(mb, Vector3(-3.0, 0.3, -0.2), 6, Vector3.LEFT, 1.5, 2.5, 1.2)
	_spark_at(Vector3(-3.4, 0.3, -0.2), Color(1.0, 0.18, 0.22), 10, 0.4)


func _fin_monete() -> void:
	var mb := MeshBatch.new()
	mb.ink_w = 0.012
	mb.prism(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.13, 0.13, 0.035, 10, Color(1.0, 0.82, 0.25, 0.0))
	_burst(mb, Vector3(0, 1.75, -0.8), 14, Vector3.FORWARD, 2.6, 4.2, 1.4)
	_spark_at(Vector3(0, 1.05, -0.8), Color(1.0, 0.82, 0.25), 14, 0.5)


func _fin_schegge() -> void:
	var mb := MeshBatch.new()
	mb.ink_w = 0.01
	mb.box(Transform3D(), Vector3(0.16, 0.03, 0.11), Color(0.75, 0.92, 1.0, 0.0), false)
	_burst(mb, Vector3(0, 3.0, -1.35), 12, Vector3.FORWARD, 3.0, 2.2, 1.8)
	_spark_at(Vector3(0, 3.0, -1.35), Color(1.0, 0.15, 0.25), 14, 0.45)
	_spark_at(Vector3(0, 3.0, -1.35), LightFx.IVORY, 8, 0.3)


func _fin_foto() -> void:
	var mb := MeshBatch.new()
	mb.ink_w = 0.012
	mb.box(Transform3D(), Vector3(0.32, 0.02, 0.24), Color(0.96, 0.93, 0.85), true)
	mb.box(Transform3D(Basis(), Vector3(0, 0.012, 0)), Vector3(0.26, 0.004, 0.17), Color(1.0, 0.82, 0.25, 0.0), false)
	_burst(mb, Vector3(0, 2.3, -0.5), 1, Vector3.FORWARD, 1.2, 2.0, 0.2)


func _fin_cornetta() -> void:
	var cr := MeshBatch.new()
	cr.ink_w = 0.015
	cr.box(Transform3D(), Vector3(0.34, 0.09, 0.09), Color("#1a1a22"))
	_burst(cr, Vector3(0.1, 1.4, -0.5), 1, Vector3.FORWARD, 2.4, 3.2, 0.6)
	var gl := MeshBatch.new()
	gl.ink_w = 0.01
	gl.box(Transform3D(), Vector3(0.18, 0.18, 0.02), Color(0.3, 0.6, 1.0, 0.0), false)
	_burst(gl, Vector3(0, 1.4, 0), 8, Vector3.FORWARD, 1.2, 2.4, 2.4)
	_spark_at(Vector3(0, 1.6, -0.6), Color(0.4, 0.85, 1.0), 12, 0.4)


func _fin_lattine() -> void:
	for c in [Color(1.0, 0.25, 0.45, 0.0), Color(0.25, 0.9, 1.0, 0.0), Color(0.6, 1.0, 0.3, 0.0), Color(1.0, 0.6, 0.15, 0.0)]:
		var mb := MeshBatch.new()
		mb.ink_w = 0.012
		mb.prism(Transform3D(), 0.07, 0.07, 0.2, 8, c, true)
		_burst(mb, Vector3(-0.1, 0.45, -0.5), 3, Vector3.FORWARD, 3.0, 2.6, 1.3)
	_spark_at(Vector3(-0.1, 0.45, -0.5), Color(1.0, 0.75, 0.2), 12, 0.4)


func _fin_posa(cv: CharacterVisual) -> void:
	_spark_at(Vector3(0, 2.4, -0.3), Color(0.3, 1.0, 0.5), 12, 0.4)
	var mb := MeshBatch.new()
	mb.ink_w = 0.012
	mb.ball(Transform3D(), 0.06, Color("#efece6"), true, 4, 6)
	_burst(mb, Vector3(0, 2.6, -0.2), 4, Vector3.FORWARD, 0.8, 2.6, 1.5)
	cv.ko()


func _flash(on: bool) -> void:
	for mi in _meshes:
		(mi as MeshInstance3D).material_override = Toon.hit_flash() if on else null
