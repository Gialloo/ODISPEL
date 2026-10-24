class_name CityBuilder
extends RefCounted

# Costruisce la scenografia urbana notturna in poche mesh (una per i solidi, una per i bagliori).
# Tutto da codice e deterministico (stesso seme = stessa strada). Niente luci vere: finestre e insegne hanno "luce propria".

const WALLS: Array = ["#27364f", "#2c3a55", "#2a4048", "#2f4a4d", "#2b3548", "#263a3c", "#3a3a3e"]   # blu notte e verde-nero (non piu' viola): palette delle foto
const LIT: Array = [Color(0.55, 0.95, 0.75, 0.0), Color(0.45, 0.85, 1.0, 0.0), Color(0.95, 0.85, 0.55, 0.0), Color(0.6, 0.75, 1.0, 0.0)]   # luci di casa fredde (verde-acqua, ciano) e qualche giallo: palette Ghost Stride
const DARK_WIN: Color = Color(0.09, 0.08, 0.16)
const NEON: Array = [Color(0.24, 1.0, 0.54, 0.0), Color(0.18, 0.95, 1.0, 0.0), Color(1.0, 0.14, 0.25, 0.0), Color(0.16, 0.36, 1.0, 0.0)]   # neon verde, ciano, rosso, blu (le foto dell'autore)

var solid := MeshBatch.new()
var glow_v := PackedVector3Array()
var glow_c := PackedColorArray()
var rng := RandomNumberGenerator.new()
var road_col: Color = Color("#141b24")
var colliders: Array = []          # [{"c": Vector2(x,z), "r": raggio}] oppure [{"rect": Rect2 su x,z}]


func _init(seed_value: int = 29) -> void:
	rng.seed = seed_value
	solid.ink_w = 0.04
	solid.world = true


func _c(hex: String) -> Color:
	return Color(hex)


# ---------- pezzi ----------

func street(z0: float, z1: float, half_road: float = 4.0, walk: float = 3.0) -> void:
	var len: float = z0 - z1
	var zc: float = (z0 + z1) * 0.5
	solid.box(Transform3D(Basis(), Vector3(0, -0.05, zc)), Vector3(half_road * 2.0, 0.1, len), road_col, false)
	for sx in [-1.0, 1.0]:
		solid.box(Transform3D(Basis(), Vector3(sx * (half_road + walk * 0.5), 0.07, zc)), Vector3(walk, 0.14, len), _c("#33404c"), false)
		solid.box(Transform3D(Basis(), Vector3(sx * (half_road + 0.06), 0.08, zc)), Vector3(0.14, 0.16, len), _c("#667684"), false)
		# fughe del marciapiede
		var z: float = z0
		while z > z1:
			solid.box(Transform3D(Basis(), Vector3(sx * (half_road + walk * 0.5), 0.142, z)), Vector3(walk, 0.005, 0.04), _c("#26313c"), false)
			z -= 1.5
	# mezzeria tratteggiata
	var zz: float = z0 - 1.0
	while zz > z1 + 1.0:
		solid.box(Transform3D(Basis(), Vector3(0, 0.005, zz)), Vector3(0.16, 0.01, 1.6), _c("#e8d27a"), false)
		zz -= 3.4


func crosswalk(z: float, half_road: float = 4.0) -> void:
	var x: float = -half_road + 0.5
	while x < half_road - 0.3:
		solid.box(Transform3D(Basis(), Vector3(x, 0.006, z)), Vector3(0.5, 0.012, 2.4), _c("#e9e4f2"), false)
		x += 0.9


# Palazzo con facciata verso la strada (side = -1 sinistra, +1 destra)
func building(side: float, z_front: float, length: float, depth: float, height: float, x_face: float = 7.0, force_shop: int = -1) -> void:
	var wall: Color = _c(WALLS[rng.randi() % WALLS.size()])
	var xc: float = side * (x_face + depth * 0.5)
	var zc: float = z_front - length * 0.5
	solid.box(Transform3D(Basis(), Vector3(xc, height * 0.5, zc)), Vector3(depth, height, length), wall)
	# cornicione
	solid.box(Transform3D(Basis(), Vector3(xc, height + 0.12, zc)), Vector3(depth + 0.3, 0.24, length + 0.3), wall.darkened(0.35))
	var fx: float = side * (x_face - 0.01)
	var n := Vector3(-side, 0, 0)
	# piano terra: vetrina o serranda
	var shop: bool = rng.randf() < 0.6
	if force_shop >= 0:
		shop = force_shop == 1
	if shop:
		var sc: Color = LIT[rng.randi() % LIT.size()]
		sc = Color(sc.r * 0.42, sc.g * 0.42, sc.b * 0.42, 0.0)      # vetrine piu' basse: pochi neon forti, non tutto acceso (Ghost Stride)
		_face_quad(fx, zc, length * 0.7, 0.6, 2.4, n, sc)
		solid.box(Transform3D(Basis(), Vector3(side * (x_face - 0.6), 2.75, zc)), Vector3(1.2, 0.12, length * 0.75), NEON[rng.randi() % NEON.size()].darkened(0.2) * Color(1, 1, 1, 0) + Color(0, 0, 0, 1))
		_glow_rect(Vector3(side * (x_face - 1.2), 0.03, zc), 2.2, length * 0.8, Color(sc.r, sc.g, sc.b, 0.22))
	else:
		_face_quad(fx, zc, length * 0.7, 0.3, 2.4, n, _c("#2c3a3e"))
		var y: float = 0.45
		while y < 2.4:
			_face_quad(fx - side * 0.01, zc, length * 0.7, y, y + 0.04, n, _c("#1a2428"))
			y += 0.25
	# finestre
	var cols: int = maxi(1, int(length / 2.2))
	var floors: int = maxi(1, int((height - 3.4) / 2.9))
	for f in floors:
		for c in cols:
			var wz: float = z_front - (float(c) + 0.5) * (length / float(cols))
			var wy: float = 3.6 + 2.9 * f
			var lit: bool = rng.randf() < 0.22                 # poche finestre accese: il buio fa risaltare i neon
			var wc: Color = LIT[rng.randi() % LIT.size()] * Color(0.45, 0.45, 0.45, 1.0) if lit else DARK_WIN
			_face_quad(fx, wz, 0.9, wy, wy + 1.35, n, wc)
	# insegna verticale al neon
	if rng.randf() < 0.55 and height > 8.0:
		var nc: Color = NEON[rng.randi() % NEON.size()]
		var nz: float = z_front - length * rng.randf_range(0.2, 0.8)
		solid.box(Transform3D(Basis(), Vector3(side * (x_face - 0.45), 5.4, nz)), Vector3(0.7, 3.4, 0.22), _c("#121a22"))
		solid.box(Transform3D(Basis(), Vector3(side * (x_face - 0.45), 5.4, nz - 0.12)), Vector3(0.5, 3.0, 0.02), nc, false)
		solid.box(Transform3D(Basis(), Vector3(side * (x_face - 0.45), 5.4, nz + 0.12)), Vector3(0.5, 3.0, 0.02), nc, false)
		_glow_rect(Vector3(side * (x_face - 1.4), 0.035, nz), 2.4, 2.6, Color(nc.r, nc.g, nc.b, 0.18))
	# tetto: serbatoio o antenna
	if rng.randf() < 0.5:
		solid.prism(Transform3D(Basis(), Vector3(xc, height + 0.24, zc)), 0.8, 0.8, 1.6, 8, wall.lightened(0.15))


func _face_quad(x: float, zc: float, w: float, y0: float, y1: float, n: Vector3, col: Color) -> void:
	var h: float = w * 0.5
	solid.quad(Vector3(x, y0, zc - h), Vector3(x, y0, zc + h), Vector3(x, y1, zc + h), Vector3(x, y1, zc - h), n, col)


func lamp(x: float, z: float) -> void:
	var side: float = signf(x)
	var pole: Color = _c("#1f2a33")
	solid.prism(Transform3D(Basis(), Vector3(x, 0.14, z)), 0.11, 0.07, 4.6, 6, pole)
	solid.box(Transform3D(Basis(), Vector3(x - side * 0.6, 4.72, z)), Vector3(1.3, 0.1, 0.12), pole)
	solid.box(Transform3D(Basis(), Vector3(x - side * 1.15, 4.62, z)), Vector3(0.55, 0.18, 0.3), pole)
	solid.box(Transform3D(Basis(), Vector3(x - side * 1.15, 4.51, z)), Vector3(0.45, 0.05, 0.22), Color(1.0, 0.86, 0.55, 0.0), false)
	_glow_disc(Vector3(x - side * 1.15, 0.03, z), 3.3, Color(1.0, 0.72, 0.38, 0.32))
	colliders.append({"c": Vector2(x, z), "r": 0.25})


func bin(x: float, z: float) -> void:
	solid.prism(Transform3D(Basis(), Vector3(x, 0.14, z)), 0.3, 0.33, 0.85, 8, _c("#3f6b5c"))
	solid.prism(Transform3D(Basis(), Vector3(x, 0.99, z)), 0.35, 0.3, 0.1, 8, _c("#2d4d42"))
	colliders.append({"c": Vector2(x, z), "r": 0.4})


func hydrant(x: float, z: float) -> void:
	solid.prism(Transform3D(Basis(), Vector3(x, 0.14, z)), 0.13, 0.12, 0.6, 8, _c("#e8343f"))
	solid.ball(Transform3D(Basis(), Vector3(x, 0.74, z)), 0.13, _c("#e8343f"), true, 4, 8)
	colliders.append({"c": Vector2(x, z), "r": 0.25})


func car(x: float, z: float, col: Color) -> void:
	solid.box(Transform3D(Basis(), Vector3(x, 0.55, z)), Vector3(1.8, 0.7, 4.2), col)
	solid.box(Transform3D(Basis(), Vector3(x, 1.12, z + 0.2)), Vector3(1.6, 0.5, 2.2), col.darkened(0.1))
	for sx in [-1.0, 1.0]:
		solid.quad(Vector3(x + sx * 0.81, 0.92, z - 0.7), Vector3(x + sx * 0.81, 0.92, z + 1.1), Vector3(x + sx * 0.81, 1.3, z + 1.0), Vector3(x + sx * 0.81, 1.3, z - 0.6), Vector3(sx, 0, 0), _c("#7fa6d6").darkened(0.5))
		for zz in [-1.35, 1.35]:
			solid.prism(Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(x + sx * 0.72, 0.36, z + zz)), 0.34, 0.34, 0.26, 8, _c("#141019"))
	# fari posteriori accesi
	for sx in [-1.0, 1.0]:
		solid.box(Transform3D(Basis(), Vector3(x + sx * 0.65, 0.7, z + 2.11)), Vector3(0.35, 0.14, 0.02), Color(1.0, 0.15, 0.25, 0.0), false)
	_glow_disc(Vector3(x, 0.03, z + 2.6), 1.3, Color(1.0, 0.15, 0.25, 0.2))
	colliders.append({"rect": Rect2(x - 1.0, z - 2.2, 2.0, 4.4)})


func bench(x: float, z: float) -> void:
	var w: Color = _c("#8a5a32")
	solid.box(Transform3D(Basis(), Vector3(x, 0.5, z)), Vector3(0.5, 0.08, 1.8), w)
	solid.box(Transform3D(Basis(), Vector3(x + signf(x) * 0.24, 0.85, z)), Vector3(0.08, 0.5, 1.8), w)
	for zz in [-0.75, 0.75]:
		solid.box(Transform3D(Basis(), Vector3(x, 0.3, z + zz)), Vector3(0.45, 0.4, 0.08), _c("#1f2a33"))
	colliders.append({"rect": Rect2(x - 0.35, z - 1.0, 0.7, 2.0)})


# Fondale: una fila di palazzi di traverso e un cartellone luminoso
func backdrop(z: float) -> void:
	for i in 6:
		var h: float = rng.randf_range(10.0, 22.0)
		var x: float = -17.5 + 7.0 * i
		var wall: Color = _c(WALLS[rng.randi() % WALLS.size()]).darkened(0.1)
		solid.box(Transform3D(Basis(), Vector3(x, h * 0.5, z - 4.0)), Vector3(7.0, h, 8.0), wall)
		for f in int((h - 3.0) / 3.0):
			for c in 3:
				var lit: bool = rng.randf() < 0.35
				var wc: Color = LIT[rng.randi() % LIT.size()] if lit else DARK_WIN
				var wx: float = x - 2.2 + 2.2 * c
				var wy: float = 3.4 + 3.0 * f
				solid.quad(Vector3(wx - 0.45, wy, z + 0.01), Vector3(wx + 0.45, wy, z + 0.01), Vector3(wx + 0.45, wy + 1.3, z + 0.01), Vector3(wx - 0.45, wy + 1.3, z + 0.01), Vector3(0, 0, 1), wc)
	solid.box(Transform3D(Basis(), Vector3(0, 9.0, z + 0.3)), Vector3(9.0, 3.4, 0.3), _c("#121a22"))
	solid.box(Transform3D(Basis(), Vector3(0, 9.0, z + 0.46)), Vector3(8.4, 2.8, 0.02), Color(1.0, 0.24, 0.55, 0.0), false)
	solid.box(Transform3D(Basis(), Vector3(-1.6, 9.0, z + 0.48)), Vector3(3.6, 0.5, 0.02), Color(1.0, 0.95, 0.85, 0.0), false)
	solid.box(Transform3D(Basis(), Vector3(2.4, 9.3, z + 0.48)), Vector3(1.6, 1.2, 0.02), Color(0.25, 0.9, 1.0, 0.0), false)
	solid.box(Transform3D(Basis(), Vector3(0, 0.0, z - 0.4)), Vector3(40.0, 0.12, 2.0), _c("#141b24"), false)


func moon(pos: Vector3, r: float) -> void:
	solid.ball(Transform3D(Basis(), pos), r, Color(1.0, 0.95, 0.8, 0.0), false, 6, 12)


# ---------- bagliori (trasparenti, additivi) ----------

func _glow_disc(c: Vector3, r: float, col: Color, segs: int = 14) -> void:
	if Settings.light_fx:
		col.a *= 0.6
	var edge := Color(col.r, col.g, col.b, 0.0)
	for i in segs:
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		glow_v.append_array([c, c + Vector3(cos(a1) * r, 0, sin(a1) * r), c + Vector3(cos(a0) * r, 0, sin(a0) * r)])
		glow_c.append_array([col, edge, edge])


func _glow_rect(c: Vector3, w: float, l: float, col: Color) -> void:
	# rettangolo che sfuma verso la strada (luce di vetrina sul marciapiede)
	_glow_disc(c, maxf(w, l) * 0.5, col, 12)


func build(parent: Node3D) -> void:
	var mi: MeshInstance3D = solid.make_instance("City")
	parent.add_child(mi)
	if not glow_v.is_empty():
		var arr: Array = []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = glow_v
		arr[Mesh.ARRAY_COLOR] = glow_c
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var g := MeshInstance3D.new()
		g.name = "Glows"
		g.mesh = m
		g.material_override = Toon.glow()
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(g)
