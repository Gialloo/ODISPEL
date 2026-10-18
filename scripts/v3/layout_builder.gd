class_name LayoutBuilder
extends RefCounted

# Scenografie delle aree dell'atto 1, tutte da codice (PROVVISORIE): strada, incrocio, vicolo, galleria, caveau, interno Anomalia.
# Ritorna: colliders, bounds (x, z percorribili), limiti della camera, colori di sfondo e nebbia.

const THEMES: Dictionary = {
	"rosso": {"bg": "#2a0710", "fog": "#3a0a18", "line": Color(1.0, 0.2, 0.3, 0.0), "glow": Color(1.0, 0.25, 0.3, 0.3)},
	"blu": {"bg": "#060c2a", "fog": "#0a1440", "line": Color(0.25, 0.65, 1.0, 0.0), "glow": Color(0.3, 0.6, 1.0, 0.3)},
	"verde": {"bg": "#061f14", "fog": "#0a2e1e", "line": Color(0.3, 1.0, 0.55, 0.0), "glow": Color(0.3, 1.0, 0.5, 0.3)},
}


static func build(layout: String, seed_value: int, tema: String, parent: Node3D) -> Dictionary:
	var cb := CityBuilder.new(seed_value)
	var out: Dictionary = {"bounds": Rect2(-6.6, -42.5, 13.2, 54.0), "cam_x": 6.75, "cam_y": 99.0,
		"bg": Color("#120b22"), "fog": [Color("#1a1030"), 16.0, 60.0], "points": {}}
	match layout:
		"incrocio":
			_incrocio(cb, out)
		"vicolo":
			_vicolo(cb, out)
		"galleria":
			_galleria(cb, out, parent)
		"caveau":
			_caveau(cb, out)
		"anomalia":
			_anomalia(cb, out, tema)
		"tangenziale":
			_tangenziale(cb, out)
		_:
			_strada(cb, out)
	cb.build(parent)
	out["colliders"] = cb.colliders
	return out


static func _buildings(cb: CityBuilder, z0: float, z1: float, x_face: float = 7.0, skip: Vector2 = Vector2(99, 99), shops: int = -1, hmin: float = 7.0, hmax: float = 18.0) -> void:
	for side in [-1.0, 1.0]:
		var z: float = z0
		while z > z1:
			var l: float = cb.rng.randf_range(6.0, 10.0)
			var overlap: bool = z > skip.x and (z - l) < skip.y      # skip = (z basso, z alto) da lasciare libero
			if not overlap:
				cb.building(side, z, l - 0.3, cb.rng.randf_range(7.0, 10.0), cb.rng.randf_range(hmin, hmax), x_face, shops)
			z -= l


static func _strada(cb: CityBuilder, out: Dictionary) -> void:
	cb.street(12.0, -46.0)
	cb.crosswalk(-17.0)
	_buildings(cb, 11.0, -44.0)
	cb.backdrop(-46.0)
	for i in 6:
		cb.lamp(4.45 if i % 2 == 0 else -4.45, 6.0 - 9.0 * i)
	cb.bin(-6.2, -4.0)
	cb.bin(6.2, -14.5)
	cb.bin(-6.2, -36.0)
	cb.hydrant(4.6, -7.5)
	cb.bench(-6.1, -21.5)
	cb.car(-2.7, -11.0, Color("#2f8fb0"))
	cb.car(2.7, -25.0, Color("#c0392b"))
	cb.moon(Vector3(-30, 46, -140), 9.0)


static func _incrocio(cb: CityBuilder, out: Dictionary) -> void:
	cb.street(12.0, -44.0)
	# strada trasversale all'altezza dell'incrocio (z -20)
	cb.solid.box(Transform3D(Basis(), Vector3(0, -0.049, -20.0)), Vector3(80.0, 0.1, 8.0), Color("#1f1a2b"), false)
	cb.crosswalk(-15.0)
	cb.crosswalk(-25.0)
	_buildings(cb, 11.0, -42.0, 7.0, Vector2(-24.5, -15.5))
	for side in [-1.0, 1.0]:
		for k in 3:
			cb.solid.box(Transform3D(Basis(), Vector3(side * (14.0 + 9.0 * k), 7.0, -12.0)), Vector3(8.0, 14.0 + 3.0 * k, 6.0), Color("#33284a"))
			cb.solid.box(Transform3D(Basis(), Vector3(side * (14.0 + 9.0 * k), 6.0, -28.0)), Vector3(8.0, 12.0 + 2.0 * k, 6.0), Color("#2c3a55"))
	cb.backdrop(-44.0)
	for i in 5:
		cb.lamp(4.45 if i % 2 == 0 else -4.45, 6.0 - 11.0 * i)
	# auto ferme in coda al rosso (con la gente dentro)
	var cols: Array = [Color("#c0392b"), Color("#2f8fb0"), Color("#e0b030"), Color("#6b3fa0"), Color("#3d7a52")]
	for i in 4:
		cb.car(-2.7, -8.0 - 6.0 * i if i < 2 else -27.0 - 6.0 * (i - 2), cols[i % cols.size()])
	cb.car(2.7, -12.5, cols[4])
	cb.car(9.0, -20.0 + 1.8, cols[2])
	cb.car(-9.5, -20.0 - 1.8, cols[0])
	# barriera LibraCorp a strisce (con un varco al centro)
	for sx in [-1.0, 1.0]:
		for k in 3:
			var x: float = sx * (1.6 + 0.8 * k)
			var col: Color = Color("#e8343f") if k % 2 == 0 else Color("#f2f0ea")
			cb.solid.box(Transform3D(Basis(), Vector3(x, 0.55, -5.0)), Vector3(0.8, 0.25, 0.15), col)
		cb.solid.box(Transform3D(Basis(), Vector3(sx * 3.6, 0.35, -5.0)), Vector3(0.1, 0.7, 0.1), Color("#2b2638"))
		cb.colliders.append({"rect": Rect2(sx * 2.8 - 1.4, -5.2, 2.8, 0.4)})
	cb.moon(Vector3(30, 46, -140), 9.0)
	out["points"] = {"auto_ferme": Vector2(-2.2, -21.0), "barriera": Vector2(0.0, -5.0)}


static func _vicolo(cb: CityBuilder, out: Dictionary) -> void:
	cb.street(12.0, -46.0, 2.0, 1.4)
	_buildings(cb, 11.0, -44.0, 3.4, Vector2(99, 99), -1, 9.0, 20.0)
	cb.backdrop(-46.0)
	for i in 5:
		cb.lamp(2.6 if i % 2 == 0 else -2.6, 6.0 - 10.0 * i)
	# cabine telefoniche blu lungo il vicolo
	for z in [-6.0, -18.0, -30.0]:
		var x: float = 2.75 if int(z) % 12 == 0 else -2.75
		cb.solid.box(Transform3D(Basis(), Vector3(x, 1.1, z)), Vector3(0.9, 2.2, 0.9), Color("#2a4f9e"))
		cb.solid.box(Transform3D(Basis(), Vector3(x - signf(x) * 0.46, 1.25, z)), Vector3(0.02, 1.4, 0.7), Color(0.35, 0.8, 1.0, 0.0), false)
		cb.solid.box(Transform3D(Basis(), Vector3(x, 2.28, z)), Vector3(0.95, 0.16, 0.95), Color(0.9, 0.95, 1.0, 0.0), false)
		cb.colliders.append({"rect": Rect2(x - 0.5, z - 0.5, 1.0, 1.0)})
	# manifesti dei ricercati sui muri (le facce dei quattro)
	var faces: Array = [Color("#e8343f"), Color("#39b7ff"), Color("#8e3df0"), Color("#2f8f5a")]
	for i in 4:
		var z2: float = -4.0 - 1.1 * i
		cb.solid.quad(Vector3(-3.38, 1.4, z2 - 0.4), Vector3(-3.38, 1.4, z2 + 0.4), Vector3(-3.38, 2.5, z2 + 0.4), Vector3(-3.38, 2.5, z2 - 0.4), Vector3.RIGHT, Color("#e9e4d2"))
		cb.solid.quad(Vector3(-3.37, 1.8, z2 - 0.25), Vector3(-3.37, 1.8, z2 + 0.25), Vector3(-3.37, 2.35, z2 + 0.25), Vector3(-3.37, 2.35, z2 - 0.25), Vector3.RIGHT, faces[i])
	cb.bin(-2.9, -12.0)
	cb.bin(2.9, -24.0)
	cb.moon(Vector3(-20, 50, -140), 8.0)
	out["bounds"] = Rect2(-3.0, -42.5, 6.0, 54.0)
	out["cam_x"] = 3.1
	out["points"] = {"cabine": Vector2(3.0, -18.0), "manifesti": Vector2(-3.3, -6.0)}


static func _galleria(cb: CityBuilder, out: Dictionary, parent: Node3D) -> void:
	cb.road_col = Color("#3a3150")
	cb.street(12.0, -46.0, 4.0, 3.0)
	# pavimento a scacchi della galleria
	for i in 28:
		for j in 4:
			if (i + j) % 2 == 0:
				cb.solid.box(Transform3D(Basis(), Vector3(-3.0 + 2.0 * j, 0.004, 10.0 - 2.0 * i)), Vector3(2.0, 0.01, 2.0), Color("#4b4064"), false)
	_buildings(cb, 11.0, -44.0, 7.0, Vector2(99, 99), 1, 8.0, 12.0)
	# tetto a vetri della galleria: archi
	for k in 8:
		var z: float = 8.0 - 6.0 * k
		cb.solid.box(Transform3D(Basis(), Vector3(0, 11.0, z)), Vector3(14.5, 0.25, 0.25), Color("#2b2638"))
	cb.solid.box(Transform3D(Basis(), Vector3(0, 11.2, -17.0)), Vector3(14.5, 0.06, 56.0), Color(0.35, 0.3, 0.55, 0.0), false)
	cb.backdrop(-46.0)
	for i in 6:
		cb.lamp(4.45 if i % 2 == 0 else -4.45, 6.0 - 9.0 * i)
	cb.bench(-6.1, -10.0)
	cb.bench(6.1, -24.0)
	# manichini senza faccia davanti alle vetrine: due forme cotte in una mesh, disegnate con MultiMesh (4 chiamate in tutto)
	var look: Dictionary = {"faceless": true, "kit": "", "no_props": true, "skin": "#e8e4dc", "hair": "#d8d3ca", "top": "#f2efe8", "bottom": "#cfc9be", "accent": "#ffffff", "shoes": "#bdb7ac", "nomask": true}
	for v in 2:
		var mesh: ArrayMesh = CharacterVisual.baked_mesh(["nox", "saul"][v], look)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = 3
		for j in 3:
			var i: int = v + 2 * j
			var side: float = -1.0 if i % 2 == 0 else 1.0
			var pos := Vector3(side * 6.3, 0.14, -6.0 - 5.5 * i)
			mm.set_instance_transform(j, Transform3D(Basis(Vector3.UP, side * PI * 0.5), pos))
			cb.colliders.append({"c": Vector2(side * 6.3, pos.z), "r": 0.4})
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mmi)
		_dress_multi(mmi, mesh)
	out["points"] = {"vetrine": Vector2(-4.0, -16.0), "manichini": Vector2(4.0, -28.0)}


static func _caveau(cb: CityBuilder, out: Dictionary) -> void:
	var metal := Color("#5a6070")
	var dark := Color("#2d3240")
	cb.solid.box(Transform3D(Basis(), Vector3(0, -0.05, -15.0)), Vector3(9.0, 0.1, 58.0), Color("#3b4050"), false)
	for i in 14:
		cb.solid.box(Transform3D(Basis(), Vector3(0, 0.003, 10.0 - 4.0 * i)), Vector3(9.0, 0.006, 0.08), Color("#2a2e3a"), false)
	for sx in [-1.0, 1.0]:
		cb.solid.box(Transform3D(Basis(), Vector3(sx * 4.6, 2.3, -15.0)), Vector3(0.4, 4.6, 58.0), metal)
		for k in 9:
			var z: float = 9.0 - 6.0 * k
			cb.solid.box(Transform3D(Basis(), Vector3(sx * 4.25, 2.3, z)), Vector3(0.35, 4.6, 0.5), dark)
			cb.solid.box(Transform3D(Basis(), Vector3(sx * 4.38, 3.6, z - 3.0)), Vector3(0.05, 0.12, 2.4), Color(0.6, 1.0, 0.75, 0.0), false)
	cb.solid.box(Transform3D(Basis(), Vector3(0, 4.7, -15.0)), Vector3(9.6, 0.25, 58.0), dark)
	for k in 9:
		cb.solid.box(Transform3D(Basis(), Vector3(0, 4.55, 9.0 - 6.0 * k)), Vector3(3.0, 0.06, 0.3), Color(0.85, 0.95, 1.0, 0.0), false)
		cb._glow_disc(Vector3(0, 0.03, 9.0 - 6.0 * k), 2.6, Color(0.6, 0.9, 1.0, 0.18))
	# griglia laser (non blocca)
	for k in 4:
		cb.solid.box(Transform3D(Basis(), Vector3(0, 0.3 + 0.35 * k, -5.0)), Vector3(8.6, 0.025, 0.025), Color(1.0, 0.15, 0.2, 0.0), false)
	# lingotti e casse
	for k in 3:
		cb.solid.box(Transform3D(Basis(), Vector3(3.3, 0.25 + 0.3 * k, -16.0)), Vector3(0.9 - 0.2 * k, 0.28, 1.4 - 0.3 * k), Color("#f2c33a"))
	cb.colliders.append({"rect": Rect2(2.8, -16.8, 1.2, 1.6)})
	for z in [-9.0, -21.0, -27.0]:
		var x: float = -3.3 if z != -9.0 else 3.3
		cb.solid.box(Transform3D(Basis(), Vector3(x, 0.5, z)), Vector3(1.0, 1.0, 1.0), Color("#4a4f5e"))
		cb.colliders.append({"rect": Rect2(x - 0.6, z - 0.6, 1.2, 1.2)})
	# porta del caveau in fondo
	cb.solid.prism(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 2.2, -41.5)), 2.1, 2.1, 0.5, 20, Color("#7a8090"))
	cb.solid.prism(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 2.2, -41.0)), 0.5, 0.5, 0.3, 12, Color("#aab0c0"))
	out["bounds"] = Rect2(-3.8, -38.0, 7.6, 49.0)
	out["cam_x"] = 3.9
	out["cam_y"] = 4.2
	out["bg"] = Color("#0c0e14")
	out["fog"] = [Color("#151a24"), 14.0, 50.0]
	out["points"] = {"lingotti": Vector2(2.3, -16.0), "laser": Vector2(0.0, -5.0)}


# Capitolo 5: la tangenziale sopraelevata all'alba, subito dopo la caduta della cupola. La citta' e' sotto, il casello in fondo.
static func _tangenziale(cb: CityBuilder, out: Dictionary) -> void:
	var asph := Color("#2a2433")
	cb.solid.box(Transform3D(Basis(), Vector3(0, -0.05, -16.0)), Vector3(10.6, 0.1, 62.0), asph, false)
	cb.solid.box(Transform3D(Basis(), Vector3(0, -0.9, -16.0)), Vector3(11.4, 1.6, 62.0), Color("#4a4256"))
	# corsie e guardrail
	for lx in [-1.75, 1.75]:
		var z: float = 11.0
		while z > -44.0:
			cb.solid.box(Transform3D(Basis(), Vector3(lx, 0.005, z)), Vector3(0.14, 0.01, 1.8), Color("#e9e4f2"), false)
			z -= 4.0
	for sx in [-1.0, 1.0]:
		cb.solid.box(Transform3D(Basis(), Vector3(sx * 5.25, 0.55, -16.0)), Vector3(0.12, 0.28, 62.0), Color("#b8bccb"))
		cb.solid.box(Transform3D(Basis(), Vector3(sx * 5.4, 0.25, -16.0)), Vector3(0.35, 0.5, 62.0), Color("#5a5468"))
		var zp: float = 11.0
		while zp > -46.0:
			cb.solid.box(Transform3D(Basis(), Vector3(sx * 5.25, 0.3, zp)), Vector3(0.1, 0.6, 0.1), Color("#5a5468"))
			zp -= 2.5
		# piloni che scendono verso la citta'
		for k in 6:
			cb.solid.box(Transform3D(Basis(), Vector3(sx * 3.5, -10.0, 8.0 - 10.0 * k)), Vector3(1.2, 18.0, 1.2), Color("#3b3448"))
	# la citta' sotto, ancora con le luci accese
	var rng := cb.rng
	for side in [-1.0, 1.0]:
		for k in 16:
			var x: float = side * rng.randf_range(12.0, 45.0)
			var z2: float = rng.randf_range(-60.0, 20.0)
			var h: float = rng.randf_range(8.0, 30.0)
			var w: float = rng.randf_range(4.0, 8.0)
			var base: float = -22.0
			var wall: Color = Color(CityBuilder.WALLS[rng.randi() % CityBuilder.WALLS.size()]).darkened(0.15)
			cb.solid.box(Transform3D(Basis(), Vector3(x, base + h * 0.5, z2)), Vector3(w, h, w), wall)
			for f in int(h / 4.0):
				if rng.randf() < 0.5:
					var wc: Color = CityBuilder.LIT[rng.randi() % CityBuilder.LIT.size()]
					cb.solid.box(Transform3D(Basis(), Vector3(x - side * (w * 0.5 + 0.02), base + 2.0 + 4.0 * f, z2)), Vector3(0.02, 1.2, w * 0.6), wc, false)
	# il sole che sorge dietro il casello e i resti della cupola (frammenti rosa nel cielo)
	cb.solid.ball(Transform3D(Basis(), Vector3(8.0, 6.0, -150.0)), 16.0, Color(1.0, 0.62, 0.35, 0.0), false, 6, 14)
	for k in 14:
		var b := Basis(Vector3(rng.randf(), rng.randf(), rng.randf()).normalized(), rng.randf_range(0.0, PI))
		cb.solid.box(Transform3D(b, Vector3(rng.randf_range(-60.0, 60.0), rng.randf_range(25.0, 60.0), rng.randf_range(-120.0, -30.0))), Vector3(rng.randf_range(2.0, 7.0), 0.3, rng.randf_range(2.0, 6.0)), Color(1.0, 0.45, 0.7, 0.0), false)
	# lampioni dell'autostrada
	for i in 5:
		cb.lamp(4.9 if i % 2 == 0 else -4.9, 6.0 - 10.0 * i)
	# auto abbandonate (la gente e' scappata a piedi quando e' caduta la cupola)
	var cols: Array = [Color("#c0392b"), Color("#2f8fb0"), Color("#e0b030"), Color("#6b3fa0"), Color("#3d7a52"), Color("#d8d4cc")]
	var spots: Array = [Vector2(-1.8, -6.0), Vector2(2.0, -11.0), Vector2(-2.2, -19.0), Vector2(1.6, -25.5)]
	for i in spots.size():
		cb.car((spots[i] as Vector2).x, (spots[i] as Vector2).y, cols[i % cols.size()])
	# cartellone dei ricercati (le quattro facce)
	cb.solid.prism(Transform3D(Basis(), Vector3(6.6, 0.0, -17.0)), 0.18, 0.15, 5.0, 6, Color("#2b2638"))
	cb.solid.box(Transform3D(Basis(Vector3.UP, -0.5), Vector3(6.4, 5.8, -17.0)), Vector3(0.2, 2.6, 5.2), Color("#1b1527"))
	cb.solid.box(Transform3D(Basis(Vector3.UP, -0.5), Vector3(6.28, 5.8, -17.0)), Vector3(0.02, 2.3, 4.9), Color(1.0, 0.95, 0.85, 0.0), false)
	var face_cols: Array = [Color(0.91, 0.2, 0.25, 0.0), Color(0.22, 0.72, 1.0, 0.0), Color(0.56, 0.24, 0.94, 0.0), Color(0.18, 0.56, 0.35, 0.0)]
	for k in 4:
		cb.solid.box(Transform3D(Basis(Vector3.UP, -0.5), Vector3(6.25 - 0.55 * (k - 1.5) * sin(0.5), 6.0, -17.0 + 1.1 * (k - 1.5) * cos(0.5))), Vector3(0.02, 1.2, 0.9), face_cols[k], false)
	cb.solid.box(Transform3D(Basis(Vector3.UP, -0.5), Vector3(6.25, 4.9, -17.0)), Vector3(0.02, 0.3, 4.4), Color(0.9, 0.15, 0.2, 0.0), false)
	# casello in fondo: tettoia, cabine, sbarre abbassate
	cb.solid.box(Transform3D(Basis(), Vector3(0, 5.2, -38.0)), Vector3(12.0, 0.6, 5.0), Color("#d9d6e0"))
	cb.solid.box(Transform3D(Basis(), Vector3(0, 4.85, -35.45)), Vector3(12.0, 0.25, 0.1), Color(1.0, 0.82, 0.25, 0.0), false)
	for bx in [-4.0, 0.0, 4.0]:
		cb.solid.box(Transform3D(Basis(), Vector3(bx + 1.2, 1.3, -38.5)), Vector3(1.1, 2.6, 1.6), Color("#3b4a6a"))
		cb.solid.box(Transform3D(Basis(), Vector3(bx + 1.2, 1.8, -37.68)), Vector3(0.8, 0.8, 0.02), Color(0.55, 0.9, 1.0, 0.0), false)
		cb.solid.box(Transform3D(Basis(), Vector3(bx + 1.2, 2.75, -38.5)), Vector3(0.3, 0.3, 0.3), Color(1.0, 0.2, 0.25, 0.0), false)
		for st in 6:
			cb.solid.box(Transform3D(Basis(), Vector3(bx - 0.2 + 0.32 * st, 1.0, -37.4)), Vector3(0.32, 0.12, 0.1), Color("#e8343f") if st % 2 == 0 else Color("#f2f0ea"), false)
		cb.colliders.append({"rect": Rect2(bx + 0.5, -39.4, 1.4, 1.8)})
	for sx in [-1.0, 1.0]:
		cb.solid.box(Transform3D(Basis(), Vector3(sx * 5.6, 2.6, -38.0)), Vector3(0.6, 5.2, 0.6), Color("#d9d6e0"))
	out["bounds"] = Rect2(-4.6, -36.0, 9.2, 48.0)
	out["cam_x"] = 4.4
	out["bg"] = Color("#5a2a4a")
	out["fog"] = [Color("#7a3a55"), 20.0, 90.0]
	out["points"] = {"auto_ferme": Vector2(1.0, -10.0), "cartellone": Vector2(4.2, -17.0), "casello": Vector2(0.0, -31.0)}


static func _anomalia(cb: CityBuilder, out: Dictionary, tema: String) -> void:
	var th: Dictionary = THEMES.get(tema, THEMES["rosso"])
	var line: Color = th["line"]
	cb.solid.box(Transform3D(Basis(), Vector3(0, -0.05, -10.0)), Vector3(16.0, 0.1, 48.0), Color(th["bg"]).lightened(0.08), false)
	for i in 13:
		cb.solid.box(Transform3D(Basis(), Vector3(0, 0.004, 12.0 - 4.0 * i)), Vector3(16.0, 0.008, 0.06), line, false)
	for j in 5:
		cb.solid.box(Transform3D(Basis(), Vector3(-8.0 + 4.0 * j, 0.004, -10.0)), Vector3(0.06, 0.008, 48.0), line, false)
	# detriti della citta' che galleggiano: auto, palazzi a pezzi, cartelli
	for k in 22:
		var x: float = cb.rng.randf_range(9.0, 22.0) * (-1.0 if k % 2 == 0 else 1.0)
		var y: float = cb.rng.randf_range(1.0, 14.0)
		var z: float = cb.rng.randf_range(-36.0, 10.0)
		var b := Basis(Vector3(cb.rng.randf(), cb.rng.randf(), cb.rng.randf()).normalized(), cb.rng.randf_range(0.0, PI))
		var sz := Vector3(cb.rng.randf_range(1.0, 4.0), cb.rng.randf_range(1.0, 6.0), cb.rng.randf_range(1.0, 4.0))
		cb.solid.box(Transform3D(b, Vector3(x, y, z)), sz, Color("#2b2638").lerp(Color(line.r, line.g, line.b), 0.15))
	for k in 6:
		var z2: float = 8.0 - 7.0 * k
		for sx in [-1.0, 1.0]:
			cb.solid.prism(Transform3D(Basis(), Vector3(sx * 7.0, 0.0, z2)), 0.3, 0.2, 7.0, 6, Color("#1b1527"))
			cb.solid.box(Transform3D(Basis(), Vector3(sx * 7.0, 7.1, z2)), Vector3(0.5, 0.5, 0.5), line, false)
			cb._glow_disc(Vector3(sx * 7.0, 0.03, z2), 2.2, th["glow"])
	out["bounds"] = Rect2(-5.5, -30.0, 11.0, 41.0)
	out["cam_x"] = 6.5
	out["bg"] = Color(th["bg"])
	out["fog"] = [Color(th["fog"]), 10.0, 42.0]


# Materiali toon per un MultiMesh (corpo + contorno): MultiMeshInstance non ha override per superficie,
# quindi i materiali si mettono direttamente sulla mesh.
static func _dress_multi(mmi: MultiMeshInstance3D, mesh: ArrayMesh) -> void:
	for si in mesh.get_surface_count():
		mesh.surface_set_material(si, Toon.body() if si == 0 else Toon.ink())
