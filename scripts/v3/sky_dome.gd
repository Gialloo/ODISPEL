class_name SkyDome
extends MeshInstance3D

# LA CUPOLA nel cielo della citta', per tutto l'atto (non solo nell'apertura).
# «Una citta' sotto una cupola rosa»: la cupola rosa e' magenta rituale #E83DCE, il colore della magia (palette dell'IP),
# e tutti la vedono (il velo e' sottile). Qui e' lontana e tenue: un bagliore sull'orizzonte e una rete di meridiani
# e paralleli, come le cuciture di un sigillo, che pulsa piano. Sta dietro ai palazzi (luce additiva, niente profondita'
# scritta) e segue la telecamera in orizzontale, cosi' sembra all'infinito in qualsiasi area.
# Dentro le Anomalie e al chiuso non si mette (lo decide chi la crea: area.gd e battle3d.gd).

const MAGIC: Color = Color("#E83DCE")
const RADIUS: float = 95.0

var _t: float = 0.0
var strength: float = 1.0          # 1 = cielo della citta'; si puo' abbassare (es. all'alba)


static func outdoor(layout: String) -> bool:
	return layout in ["strada", "incrocio", "vicolo", "tangenziale", ""]


func _ready() -> void:
	mesh = _build()
	material_override = Toon.glow()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	top_level = true


func _process(delta: float) -> void:
	_t += delta
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam != null:
		global_position = Vector3(cam.global_position.x, -8.0, cam.global_position.z)
	# pulsazione lenta, come un respiro: la cupola e' viva
	transparency = clampf(1.0 - strength * (0.82 + 0.18 * sin(_t * 0.9)), 0.0, 1.0)


func _build() -> ArrayMesh:
	var v := PackedVector3Array()
	var c := PackedColorArray()
	var segs: int = 32 if Settings.light_fx else 48
	var p := func(el: float, az: float, r: float) -> Vector3:
		return Vector3(cos(el) * cos(az) * r, sin(el) * r * 0.8, cos(el) * sin(az) * r)
	# velo: tutta la cupola e' appena tinta, piu' forte verso l'orizzonte (dalle strade strette si vede solo in alto)
	var glow_rings: Array = [[0.0, 0.2], [0.18, 0.12], [0.5, 0.07], [0.9, 0.05], [1.4, 0.04]]
	for i in glow_rings.size() - 1:
		var e0: float = glow_rings[i][0]
		var e1: float = glow_rings[i + 1][0]
		var c0 := Color(MAGIC.r, MAGIC.g, MAGIC.b, glow_rings[i][1])
		var c1 := Color(MAGIC.r, MAGIC.g, MAGIC.b, glow_rings[i + 1][1])
		for j in segs:
			var a0: float = TAU * float(j) / float(segs)
			var a1: float = TAU * float(j + 1) / float(segs)
			v.append_array([p.call(e0, a0, RADIUS), p.call(e1, a0, RADIUS), p.call(e1, a1, RADIUS),
				p.call(e0, a0, RADIUS), p.call(e1, a1, RADIUS), p.call(e0, a1, RADIUS)])
			c.append_array([c0, c1, c1, c0, c1, c0])
	# meridiani: linee sottili che convergono verso la cima, come le cuciture di un sigillo
	var mer: int = 18 if Settings.light_fx else 28
	var steps: int = 12
	var top: float = 1.45
	for j in mer:
		var az: float = TAU * float(j) / float(mer)
		for i in steps:
			var e0: float = top * float(i) / float(steps)
			var e1: float = top * float(i + 1) / float(steps)
			var k0: float = 0.24 * (1.0 - 0.5 * float(i) / float(steps))
			var k1: float = 0.24 * (1.0 - 0.5 * float(i + 1) / float(steps))
			# piu' si sale, piu' i meridiani sono vicini: si allargano un poco per non sparire
			var w0: float = 0.004 / maxf(0.15, cos(e0))
			var w1: float = 0.004 / maxf(0.15, cos(e1))
			var c0 := Color(MAGIC.r, MAGIC.g, MAGIC.b, k0)
			var c1 := Color(MAGIC.r, MAGIC.g, MAGIC.b, k1)
			v.append_array([p.call(e0, az - w0, RADIUS), p.call(e1, az - w1, RADIUS), p.call(e1, az + w1, RADIUS),
				p.call(e0, az - w0, RADIUS), p.call(e1, az + w1, RADIUS), p.call(e0, az + w0, RADIUS)])
			c.append_array([c0, c1, c1, c0, c1, c0])
	# paralleli: cuciture orizzontali, fino in alto
	for pe in [[0.16, 0.26], [0.42, 0.2], [0.72, 0.17], [1.02, 0.15], [1.28, 0.13]]:
		var el: float = pe[0]
		var col := Color(MAGIC.r, MAGIC.g, MAGIC.b, pe[1])
		var hw: float = 0.006
		for j in segs:
			var a0: float = TAU * float(j) / float(segs)
			var a1: float = TAU * float(j + 1) / float(segs)
			v.append_array([p.call(el - hw, a0, RADIUS), p.call(el + hw, a0, RADIUS), p.call(el + hw, a1, RADIUS),
				p.call(el - hw, a0, RADIUS), p.call(el + hw, a1, RADIUS), p.call(el - hw, a1, RADIUS)])
			c.append_array([col, col, col, col, col, col])
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_COLOR] = c
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m
