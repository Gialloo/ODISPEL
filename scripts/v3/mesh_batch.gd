class_name MeshBatch
extends RefCounted

# Costruisce UNA mesh da tante forme semplici (scatole, prismi, sfere low-poly) con colore nei vertici.
# Superficie 0: il corpo (materiale toon). Superficie 1: il contorno (guscio gonfiato, materiale inchiostro).
# Cosi' una strada intera o un personaggio intero sono 1-2 draw call invece di centinaia.

var _v: PackedVector3Array = PackedVector3Array()
var _n: PackedVector3Array = PackedVector3Array()
var _c: PackedColorArray = PackedColorArray()
var _ov: PackedVector3Array = PackedVector3Array()
var _on: PackedVector3Array = PackedVector3Array()
var _oc: PackedColorArray = PackedColorArray()
var ink_w: float = 0.025           # spessore del contorno (metri)

# Godot considera "davanti" il triangolo in senso orario visto da fuori: _tri mette in ordine i vertici da solo.
const FRONT_SIGN: float = -1.0


func is_empty() -> bool:
	return _v.is_empty()


func tri_count() -> int:
	return (_v.size() + _ov.size()) / 3


func _tri(a: Vector3, b: Vector3, c: Vector3, n: Vector3, col: Color, outline: bool) -> void:
	var cr: Vector3 = (b - a).cross(c - a)
	if cr.dot(n) * FRONT_SIGN < 0.0:
		var t: Vector3 = b
		b = c
		c = t
	if outline:
		_ov.append_array([a, b, c])
		_on.append_array([n, n, n])
		_oc.append_array([col, col, col])
	else:
		_v.append_array([a, b, c])
		_n.append_array([n, n, n])
		_c.append_array([col, col, col])


# Triangolo con normali per vertice (sfere lisce)
func _tri_smooth(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, col: Color, outline: bool) -> void:
	var n: Vector3 = (na + nb + nc).normalized()
	var cr: Vector3 = (b - a).cross(c - a)
	if cr.dot(n) * FRONT_SIGN < 0.0:
		var t: Vector3 = b
		b = c
		c = t
		var tn: Vector3 = nb
		nb = nc
		nc = tn
	if outline:
		_ov.append_array([a, b, c])
		_on.append_array([na, nb, nc])
		_oc.append_array([col, col, col])
	else:
		_v.append_array([a, b, c])
		_n.append_array([na, nb, nc])
		_c.append_array([col, col, col])


static func _nx(xf: Transform3D, n: Vector3) -> Vector3:
	return (xf.basis.inverse().transposed() * n).normalized()


# Scatola centrata nell'origine della trasformazione
func box(xf: Transform3D, size: Vector3, col: Color, outline: bool = true) -> void:
	_box(xf, size, col, false)
	if outline:
		_box(xf, size + Vector3.ONE * ink_w * 2.0, Toon.INK, true)


func _box(xf: Transform3D, size: Vector3, col: Color, ol: bool) -> void:
	var h: Vector3 = size * 0.5
	var faces: Array = [
		[Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)],
		[Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)],
		[Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
		[Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
		[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
		[Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
	]
	for f in faces:
		var n: Vector3 = f[0]
		var u: Vector3 = f[1]
		var w: Vector3 = f[2]
		var c: Vector3 = n * h
		var du: Vector3 = u * h
		var dw: Vector3 = w * h
		var p0: Vector3 = xf * (c - du - dw)
		var p1: Vector3 = xf * (c + du - dw)
		var p2: Vector3 = xf * (c + du + dw)
		var p3: Vector3 = xf * (c - du + dw)
		var wn: Vector3 = _nx(xf, n)
		_tri(p0, p1, p2, wn, col, ol)
		_tri(p0, p2, p3, wn, col, ol)


# Prisma (cilindro low-poly o cono) lungo +Y da 0 ad h, raggi r0 in basso e r1 in alto
func prism(xf: Transform3D, r0: float, r1: float, h: float, sides: int, col: Color, outline: bool = true, caps: bool = true) -> void:
	_prism(xf, r0, r1, h, sides, col, false, caps, 0.0)
	if outline:
		_prism(xf, r0 + ink_w, r1 + ink_w, h, sides, Toon.INK, true, caps, ink_w)


func _prism(xf: Transform3D, r0: float, r1: float, h: float, sides: int, col: Color, ol: bool, caps: bool, grow: float) -> void:
	var y0: float = -grow
	var y1: float = h + grow
	for i in sides:
		var a0: float = TAU * float(i) / float(sides)
		var a1: float = TAU * float(i + 1) / float(sides)
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var b0: Vector3 = xf * (d0 * r0 + Vector3(0, y0, 0))
		var b1: Vector3 = xf * (d1 * r0 + Vector3(0, y0, 0))
		var t0: Vector3 = xf * (d0 * r1 + Vector3(0, y1, 0))
		var t1: Vector3 = xf * (d1 * r1 + Vector3(0, y1, 0))
		var mid: Vector3 = (d0 + d1).normalized()
		var slope: float = (r0 - r1) / maxf(0.001, h)
		var n: Vector3 = _nx(xf, Vector3(mid.x, slope, mid.z).normalized())
		_tri(b0, b1, t1, n, col, ol)
		if r1 > 0.0005:
			_tri(b0, t1, t0, n, col, ol)
		if caps:
			if r0 > 0.0005:
				_tri(xf * Vector3(0, y0, 0), b0, b1, _nx(xf, Vector3.DOWN), col, ol)
			if r1 > 0.0005:
				_tri(xf * Vector3(0, y1, 0), t0, t1, _nx(xf, Vector3.UP), col, ol)


# Sfera low-poly liscia (testa, mani, lampioni)
func ball(xf: Transform3D, r: float, col: Color, outline: bool = true, lat: int = 6, lon: int = 10) -> void:
	_ball(xf, r, col, false, lat, lon)
	if outline:
		_ball(xf, r + ink_w, Toon.INK, true, lat, lon)


func _ball(xf: Transform3D, r: float, col: Color, ol: bool, lat: int, lon: int) -> void:
	var nb: Basis = xf.basis.inverse().transposed()
	for i in lat:
		var t0: float = PI * float(i) / float(lat)
		var t1: float = PI * float(i + 1) / float(lat)
		for j in lon:
			var p0: float = TAU * float(j) / float(lon)
			var p1: float = TAU * float(j + 1) / float(lon)
			var d00 := Vector3(sin(t0) * cos(p0), cos(t0), sin(t0) * sin(p0))
			var d01 := Vector3(sin(t0) * cos(p1), cos(t0), sin(t0) * sin(p1))
			var d10 := Vector3(sin(t1) * cos(p0), cos(t1), sin(t1) * sin(p0))
			var d11 := Vector3(sin(t1) * cos(p1), cos(t1), sin(t1) * sin(p1))
			var n00: Vector3 = (nb * d00).normalized()
			var n01: Vector3 = (nb * d01).normalized()
			var n10: Vector3 = (nb * d10).normalized()
			var n11: Vector3 = (nb * d11).normalized()
			if i > 0:
				_tri_smooth(xf * (d00 * r), xf * (d10 * r), xf * (d01 * r), n00, n10, n01, col, ol)
			if i < lat - 1:
				_tri_smooth(xf * (d01 * r), xf * (d10 * r), xf * (d11 * r), n01, n10, n11, col, ol)


# Quadrilatero piatto (pannelli, insegne, finestre): niente contorno
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color) -> void:
	_tri(a, b, c, n, col, false)
	_tri(a, c, d, n, col, false)


func build() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if _v.is_empty():
		return mesh
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = _v
	arr[Mesh.ARRAY_NORMAL] = _n
	arr[Mesh.ARRAY_COLOR] = _c
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	if not _ov.is_empty():
		var oa: Array = []
		oa.resize(Mesh.ARRAY_MAX)
		oa[Mesh.ARRAY_VERTEX] = _ov
		oa[Mesh.ARRAY_NORMAL] = _on
		oa[Mesh.ARRAY_COLOR] = _oc
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, oa)
	return mesh


# Crea direttamente il nodo con i materiali giusti
func make_instance(node_name: String = "Batch") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Toon.dress(mi)
	return mi


# ---------- forme trasparenti (bagliori e ombre a macchia): mesh a parte, materiale glow o shadow ----------

# Disco orizzontale con sfumatura radiale: centro col, bordo trasparente
static func disc(radius: float, col: Color, segs: int = 16, y: float = 0.02) -> ArrayMesh:
	var v := PackedVector3Array()
	var c := PackedColorArray()
	var edge := Color(col.r, col.g, col.b, 0.0)
	for i in segs:
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		v.append_array([Vector3(0, y, 0), Vector3(cos(a1) * radius, y, sin(a1) * radius), Vector3(cos(a0) * radius, y, sin(a0) * radius)])
		c.append_array([col, edge, edge])
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_COLOR] = c
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m
