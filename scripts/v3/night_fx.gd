class_name NightFx
extends Node3D

# NOTTE URBANA «Ghost Stride» (riferimenti in stile_ghost_stride/): buio quasi nero, pochi neon fortissimi (verde, ciano, blu + un
# accento rosso), pavimento bagnato con riflessi lunghi e pioggia fine. Tutto economico (PRESTAZIONI):
#  - neon = scatole "luce propria" (alpha 0 nello shader toon) + aloni additivi; ZERO luci dinamiche;
#  - riflessi a terra = strisce additive sfumate (una mesh), non riflessi veri;
#  - pioggia = una mesh sola animata nel vertex shader (nessuna CPU per goccia); con light_fx meno gocce e niente riflessi lunghi.
# Perche' cosi': l'autore (24/10) vuole lo stile delle foto dentro il gioco; neon e riflessi dicono "notte bagnata" in 2 mesh.

const GREEN: Color = Color("#3dff8a")
const CYAN: Color = Color("#2ef2ff")
const BLUE: Color = Color("#2a5cff")
const RED: Color = Color("#ff2340")
const LIME: Color = Color("#d8ff3a")
const BG: Color = Color("#04080b")
const FOG: Color = Color("#071a1e")

const _RAIN: String = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform float height = 11.0;
uniform float speed = 0.9;
varying float a;
void vertex() {
	float ph = fract(COLOR.r - TIME * speed * (0.8 + COLOR.g * 0.5));
	VERTEX.y += height * ph;
	VERTEX.x += (1.0 - ph) * 0.0 + (UV.y - 0.5) * 0.0;
	a = smoothstep(0.0, 0.08, ph) * (0.55 + 0.45 * COLOR.g);
}
void fragment() {
	ALBEDO = vec3(0.62, 0.92, 1.0);
	ALPHA = a * 0.34 * (1.0 - abs(UV.x - 0.5) * 2.0) * (0.35 + 0.65 * UV.y);
}
"""

var solid := MeshBatch.new()
var glow_v := PackedVector3Array()
var glow_c := PackedColorArray()
var rng := RandomNumberGenerator.new()
var _ground_y: float = 0.16
var _road_half: float = 4.0
var _rain: MeshInstance3D = null
var neon_count: int = 0


# o: wall_x (x della facciata, 0 = niente muri), z0 (inizio, vicino), z1 (fine, lontano), seed, road_half, side_y, count (neon sui muri),
#    back (true = insegna rossa in fondo), rain (true = pioggia), colors (palette scelta)
static func apply(parent: Node3D, o: Dictionary) -> NightFx:
	var fx := NightFx.new()
	fx.name = "NightFx"
	parent.add_child(fx)
	fx._build(o)
	return fx


# Cielo e nebbia da notte: lo stesso per battaglia ed esplorazione. Ritorna true se ha trovato l'ambiente da scurire.
static func darken_env(env: Environment, near: float, far: float) -> void:
	if env != null:
		env.background_color = BG
	Toon.set_fog(FOG, near, far)


func _build(o: Dictionary) -> void:
	rng.seed = int(o.get("seed", 7)) * 31 + 5
	solid.ink_w = 0.0
	var wall_x: float = float(o.get("wall_x", 7.0))
	var z0: float = float(o.get("z0", 10.0))
	var z1: float = float(o.get("z1", -40.0))
	_road_half = float(o.get("road_half", 4.0))
	_ground_y = float(o.get("side_y", 0.16))
	var n: int = int(o.get("count", 4))
	var pal: Array = o.get("colors", [CYAN, GREEN, RED, BLUE, CYAN, GREEN, LIME])
	# i neon si distribuiscono lungo la strada alternando i lati; il primo e' sempre ciano o verde (colore guida)
	var span: float = z0 - z1
	for i in n:
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var z: float = z0 - 2.0 - span * (float(i) + rng.randf_range(0.15, 0.85)) / float(n)
		var c: Color = pal[i % pal.size()]
		if i == 1 and not o.get("no_red", false):
			c = RED                                  # un accento rosso per scena (insegna, come nelle foto)
		var kind: int = rng.randi() % 3
		_neon(kind, side, wall_x, z, c)
	if o.get("back", true):
		_back_sign(z1 + 1.2, RED if rng.randf() < 0.5 else CYAN)
	_flush()
	if o.get("rain", true):
		_rain = _make_rain(int(o.get("drops", 110 if Settings.light_fx else 240)))
		_rain.top_level = true
		add_child(_rain)
		set_process(true)


func _process(_d: float) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam != null and _rain != null:
		_rain.global_position = Vector3(cam.global_position.x, 0.0, cam.global_position.z - 6.0)


# ---------------- pezzi ----------------

func _lit(c: Color) -> Color:
	return Color(c.r, c.g, c.b, 0.0)


func _neon(kind: int, side: float, wall_x: float, z: float, c: Color) -> void:
	neon_count += 1
	var x: float = side * (wall_x - 0.08)
	var inward: Vector3 = Vector3(-side, 0, 0)
	match kind:
		0:
			# tubo orizzontale lungo, ad altezza di insegna
			var len: float = rng.randf_range(4.5, 7.0)
			var y: float = rng.randf_range(2.6, 3.6)
			solid.box(Transform3D(Basis(), Vector3(x + side * 0.03, y, z)), Vector3(0.1, 0.22, len + 0.3), Color("#0a0d12"), false)
			solid.box(Transform3D(Basis(), Vector3(x, y, z)), Vector3(0.09, 0.1, len), _lit(c), false)
			_halo_wall(x, y, z, len, 0.26, side, c)
			_floor_light(side, wall_x, z, len, c, 0.30)
		1:
			# tubo verticale alto (come i due cartelli verticali delle foto)
			var h: float = rng.randf_range(3.2, 5.0)
			solid.box(Transform3D(Basis(), Vector3(x + side * 0.03, 1.4 + h * 0.5, z)), Vector3(0.1, h + 0.2, 0.3), Color("#0a0d12"), false)
			solid.box(Transform3D(Basis(), Vector3(x, 1.4 + h * 0.5, z)), Vector3(0.09, h, 0.12), _lit(c), false)
			_halo_wall(x, 1.4 + h * 0.5, z, 0.12, h, side, c)
			_floor_light(side, wall_x, z, 1.6, c, 0.34)
			# riflesso lungo e stretto: la colonna di luce sul bagnato
			_streak(side * (wall_x - 1.3 - rng.randf() * 0.8), z, rng.randf_range(4.5, 7.0), 0.22, c, 0.40)
		_:
			# insegna a riquadro: cornice scura, bordo neon e due righe interne
			var w: float = rng.randf_range(1.8, 2.8)
			var h2: float = rng.randf_range(1.0, 1.6)
			var y2: float = rng.randf_range(3.2, 4.4)
			solid.box(Transform3D(Basis(), Vector3(x + side * 0.05, y2, z)), Vector3(0.14, h2 + 0.3, w + 0.3), Color("#0a0d12"), false)
			solid.box(Transform3D(Basis(), Vector3(x, y2 + h2 * 0.5, z)), Vector3(0.1, 0.07, w), _lit(c), false)
			solid.box(Transform3D(Basis(), Vector3(x, y2 - h2 * 0.5, z)), Vector3(0.1, 0.07, w), _lit(c), false)
			solid.box(Transform3D(Basis(), Vector3(x, y2, z - w * 0.5)), Vector3(0.1, h2, 0.07), _lit(c), false)
			solid.box(Transform3D(Basis(), Vector3(x, y2, z + w * 0.5)), Vector3(0.1, h2, 0.07), _lit(c), false)
			solid.box(Transform3D(Basis(), Vector3(x - side * 0.01, y2 + 0.15, z)), Vector3(0.09, 0.07, w * 0.55), _lit(c.lerp(Color.WHITE, 0.6)), false)
			_halo_wall(x, y2, z, w + 0.2, h2 + 0.2, side, c)
			_floor_light(side, wall_x, z, w, c, 0.26)
	if inward.x == 0.0:
		pass


# Insegna in fondo alla strada: fa da bersaglio visivo dietro al nemico e getta una lunga colonna di luce sul bagnato verso la camera
func _back_sign(z: float, c: Color) -> void:
	neon_count += 1
	var w: float = 5.0
	solid.box(Transform3D(Basis(), Vector3(0, 2.3, z)), Vector3(w + 0.4, 0.34, 0.14), Color("#0a0d12"), false)
	solid.box(Transform3D(Basis(), Vector3(0, 2.3, z + 0.08)), Vector3(w, 0.1, 0.08), _lit(c), false)
	solid.box(Transform3D(Basis(), Vector3(-1.2, 3.1, z + 0.08)), Vector3(0.08, 1.5, 0.08), _lit(c), false)
	solid.box(Transform3D(Basis(), Vector3(1.6, 3.1, z + 0.08)), Vector3(0.08, 1.5, 0.08), _lit(Color.WHITE.lerp(c, 0.4)), false)
	for k in 3:
		var hw: float = w * 0.5 + 0.6 + k * 0.7
		var hh: float = 0.35 + k * 0.6
		_rect_z(Vector3(0, 2.3, z + 0.12), hw, hh, Color(c.r, c.g, c.b, [0.30, 0.14, 0.06][k]))
	# colonna di riflesso verso la camera (la parte che da' il "pavimento bagnato")
	_streak_wide(0.0, z + 0.4, 12.0 if not Settings.light_fx else 7.0, 1.6, c, 0.34)
	_streak_wide(-0.9, z + 0.4, 7.0, 0.14, c, 0.45)
	_streak_wide(0.8, z + 0.4, 9.0, 0.10, c, 0.4)


func _rect_z(c: Vector3, hw: float, hh: float, col: Color) -> void:
	var a: Vector3 = c + Vector3(-hw, -hh, 0)
	var b: Vector3 = c + Vector3(hw, -hh, 0)
	var d: Vector3 = c + Vector3(hw, hh, 0)
	var e: Vector3 = c + Vector3(-hw, hh, 0)
	glow_v.append_array([a, b, d, a, d, e])
	for i in 6:
		glow_c.append(col)


# Alone sul muro: tre rettangoli additivi sempre piu' larghi e piu' deboli (luce che si sfuma nell'aria bagnata)
func _halo_wall(x: float, y: float, z: float, len: float, hgt: float, side: float, c: Color) -> void:
	var xx: float = x - side * 0.02
	var ks: Array = [[0.22, 0.30], [0.8, 0.14], [1.7, 0.06]]
	if Settings.light_fx:
		ks = [[0.3, 0.26], [1.2, 0.09]]
	for k in ks:
		var pad: float = float(k[0])
		var col := Color(c.r, c.g, c.b, float(k[1]))
		var a := Vector3(xx, y - hgt * 0.5 - pad, z - len * 0.5 - pad)
		var b := Vector3(xx, y - hgt * 0.5 - pad, z + len * 0.5 + pad)
		var d := Vector3(xx, y + hgt * 0.5 + pad, z + len * 0.5 + pad)
		var e := Vector3(xx, y + hgt * 0.5 + pad, z - len * 0.5 - pad)
		glow_v.append_array([a, b, d, a, d, e])
		for i in 6:
			glow_c.append(col)


func _gy(x: float) -> float:
	return _ground_y if absf(x) > _road_half else 0.03


# Luce a terra davanti al neon: chiazza che si sfuma verso il centro della strada
func _floor_light(side: float, wall_x: float, z: float, len: float, c: Color, a: float) -> void:
	var x0: float = side * (wall_x - 0.1)
	var depth: float = 3.2
	var x1: float = x0 - side * depth
	var y: float = _ground_y
	var hl: float = len * 0.5 + 0.8
	var bright := Color(c.r, c.g, c.b, a * (0.6 if Settings.light_fx else 1.0))
	var dark := Color(c.r, c.g, c.b, 0.0)
	var p0 := Vector3(x0, y, z - hl)
	var p1 := Vector3(x0, y, z + hl)
	var p2 := Vector3(x1, y, z + hl)
	var p3 := Vector3(x1, y, z - hl)
	glow_v.append_array([p0, p1, p2, p0, p2, p3])
	glow_c.append_array([bright, bright, dark, bright, dark, dark])


# Striscia di riflesso: lunga lungo z, sfumata ai due capi (il neon "scende" nel bagnato)
func _streak(x: float, z: float, len: float, w: float, c: Color, a: float) -> void:
	if Settings.light_fx:
		return
	_streak_wide(x, z, len, w, c, a)


func _streak_wide(x: float, z: float, len: float, w: float, c: Color, a: float) -> void:
	var y: float = _gy(x) + 0.005
	var hw: float = w * 0.5
	var bright := Color(c.r, c.g, c.b, a)
	var dark := Color(c.r, c.g, c.b, 0.0)
	# una striscia che parte forte vicino alla fonte (z) e muore verso la camera (+z)
	var p0 := Vector3(x - hw, y, z)
	var p1 := Vector3(x + hw, y, z)
	var p2 := Vector3(x + hw * 0.6, y, z + len)
	var p3 := Vector3(x - hw * 0.6, y, z + len)
	glow_v.append_array([p0, p1, p2, p0, p2, p3])
	glow_c.append_array([bright, bright, dark, bright, dark, dark])


func _flush() -> void:
	if not solid.is_empty():
		var mi: MeshInstance3D = solid.make_instance("Neon")
		Toon.dress(mi, true)
		add_child(mi)
	if not glow_v.is_empty():
		var arr: Array = []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = glow_v
		arr[Mesh.ARRAY_COLOR] = glow_c
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var g := MeshInstance3D.new()
		g.name = "NeonGlow"
		g.mesh = m
		g.material_override = Toon.glow()
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(g)


# ---------------- pioggia ----------------

static var _rain_mat: ShaderMaterial = null


static func rain_material() -> ShaderMaterial:
	if _rain_mat == null:
		var sh := Shader.new()
		sh.code = _RAIN
		_rain_mat = ShaderMaterial.new()
		_rain_mat.shader = sh
		_rain_mat.render_priority = 2
	return _rain_mat


func _make_rain(count: int) -> MeshInstance3D:
	var v := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	for i in count:
		var x: float = rng.randf_range(-11.0, 11.0)
		var z: float = rng.randf_range(-9.0, 12.0)
		var ph: float = rng.randf()
		var sp: float = rng.randf()
		var len: float = rng.randf_range(0.45, 0.8)
		var ang: float = rng.randf_range(0.0, PI)
		var w: float = 0.03
		var dx: float = cos(ang) * w
		var dz: float = sin(ang) * w
		var lean: float = -0.07
		var col := Color(ph, sp, 0.0, 1.0)
		# due quadrati incrociati: la goccia si vede da ogni lato
		for k in 2:
			var ox: float = dx if k == 0 else -dz
			var oz: float = dz if k == 0 else dx
			var a := Vector3(x - ox, 0.0, z - oz)
			var b := Vector3(x + ox, 0.0, z + oz)
			var d := Vector3(x + ox + lean, len, z + oz)
			var e := Vector3(x - ox + lean, len, z - oz)
			v.append_array([a, b, d, a, d, e])
			uv.append_array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)])
			for j in 6:
				c.append(col)
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_COLOR] = c
	arr[Mesh.ARRAY_TEX_UV] = uv
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.name = "Rain"
	mi.mesh = m
	mi.material_override = rain_material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 20.0
	return mi
