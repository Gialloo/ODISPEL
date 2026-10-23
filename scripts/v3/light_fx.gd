class_name LightFx
extends MeshInstance3D

# LA MAGIA SI DISEGNA CON LA LUCE (SINTESI §5, regola madre dello stile).
# «I personaggi sono disegnati con precisione. I loro poteri sono disegnati con istinto.»
# Pennellate di luce che escono dal personaggio nel suo colore, col nucleo avorio; scintille d'impatto arancio;
# il cerchio di luce sotto chi e' di turno; il sigillo magenta sotto le Anomalie (la magia che le possiede).
# La luce e' l'evento eccezionale: compare quando succede qualcosa e poi sparisce, mai tutto al neon.
#
# Tecnica (vincoli del motore, vedi README): una ImmediateMesh additiva (Toon.glow) ricostruita a ogni frame,
# poche decine di triangoli, nessuna particella della GPU, nessuna luce. Con «effetti ridotti» si dimezza tutto.
#
# Uso: LightFx.stroke(parent, da, a, colore) · LightFx.sparks(parent, punto) · LightFx.rise(parent, piedi, colore)
#      var g := LightFx.glyph(parent, piedi, colore) ... g.stop() · LightFx.seal(parent, piedi) ... stop()
#      await LightFx.blackout(control, colore)   (2D: i due fotogrammi neri dell'ultimate)

const IVORY: Color = Color("#F5E9C9")       # nucleo della luce (palette dell'IP)
const IMPACT: Color = Color("#FF7438")      # impatto
const MAGIC: Color = Color("#E83DCE")       # magenta rituale: magia e Anomalie

var kind: String = ""
var col: Color = Color.WHITE
var t: float = 0.0
var dur: float = 0.5
var a: Vector3 = Vector3.ZERO
var b: Vector3 = Vector3.ZERO
var bow: Vector3 = Vector3.ZERO
var width: float = 0.3
var radius: float = 1.0
var seed_v: float = 0.0
var _sparks: Array = []                     # [direzione, velocita', lunghezza]
var _fade: float = 1.0
var _stopping: bool = false
var _im: ImmediateMesh
var _vv: PackedVector3Array = PackedVector3Array()
var _vc: PackedColorArray = PackedColorArray()


static func _make(parent: Node, k: String, c: Color, d: float) -> LightFx:
	var fx := LightFx.new()
	fx.kind = k
	fx.col = c
	fx.dur = d
	fx.seed_v = randf() * 100.0
	fx.top_level = true
	fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx._im = ImmediateMesh.new()
	fx.mesh = fx._im
	fx.material_override = Toon.glow()
	parent.add_child(fx)
	return fx


# Pennellata di luce da un punto a un altro, ad arco, tracciata a mano (leggero tremolio) e poi cancellata dalla coda.
static func stroke(parent: Node, from: Vector3, to: Vector3, c: Color, w: float = 0.32, d: float = 0.5) -> LightFx:
	var fx := _make(parent, "stroke", c, d)
	fx.a = from
	fx.b = to
	var dir: Vector3 = (to - from)
	var side: Vector3 = dir.cross(Vector3.UP).normalized()
	fx.bow = Vector3.UP * (0.6 + 0.25 * dir.length() * 0.25) + side * randf_range(-1.0, 1.0) * 0.9
	fx.width = w
	return fx


# Scintille d'impatto: tratti brevi che schizzano via dal punto colpito.
static func sparks(parent: Node, at: Vector3, c: Color = IMPACT, n: int = 10, d: float = 0.32) -> LightFx:
	var fx := _make(parent, "sparks", c, d)
	fx.a = at
	if Settings.light_fx:
		n = n / 2
	for i in n:
		var dir := Vector3(randf_range(-1, 1), randf_range(-0.4, 1.0), randf_range(-1, 1)).normalized()
		fx._sparks.append([dir, randf_range(2.5, 5.0), randf_range(0.25, 0.5)])
	return fx


# Spirale di luce che sale attorno al personaggio (abilita' su se' o sugli alleati: cure, scudi, potenziamenti).
static func rise(parent: Node, feet: Vector3, c: Color, d: float = 0.7, r: float = 0.6) -> LightFx:
	var fx := _make(parent, "rise", c, d)
	fx.a = feet
	fx.radius = r
	return fx


# Cerchio di luce sotto chi e' di turno: un arco disegnato a mano che gira, finche' non si chiama stop().
static func glyph(parent: Node, feet: Vector3, c: Color, r: float = 0.75) -> LightFx:
	var fx := _make(parent, "glyph", c, 9999.0)
	fx.a = feet
	fx.radius = r
	return fx


# Segnalino del bersaglio annunciato dal boss: anello pulsante con quattro punte che puntano al centro, finche' non si chiama stop().
static func mark(parent: Node, feet: Vector3, c: Color, r: float = 1.05) -> LightFx:
	var fx := _make(parent, "mark", c, 9999.0)
	fx.a = feet
	fx.radius = r
	return fx


# Sigillo della possessione sotto un'Anomalia: anello magenta con tacche e scintille che salgono, finche' non si chiama stop().
static func seal(parent: Node, feet: Vector3, r: float = 1.9) -> LightFx:
	var fx := _make(parent, "seal", MAGIC, 9999.0)
	fx.a = feet
	fx.radius = r
	return fx


func stop() -> void:
	_stopping = true


func move_to(feet: Vector3, c: Color) -> void:
	a = feet
	col = c
	_stopping = false
	_fade = minf(_fade, 0.2)


func _process(delta: float) -> void:
	t += delta
	if _stopping:
		_fade -= delta * 4.0
		if _fade <= 0.0:
			queue_free()
			return
	elif _fade < 1.0:
		_fade = minf(1.0, _fade + delta * 5.0)
	if t >= dur:
		queue_free()
		return
	_vv.clear()
	_vc.clear()
	match kind:
		"stroke":
			_draw_stroke()
		"sparks":
			_draw_sparks()
		"rise":
			_draw_rise()
		"glyph":
			_draw_glyph()
		"mark":
			_draw_mark()
		"seal":
			_draw_seal()
	_im.clear_surfaces()
	if _vv.is_empty():
		return
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in _vv.size():
		_im.surface_set_color(_vc[i])
		_im.surface_add_vertex(_vv[i])
	_im.surface_end()


# ---------------------------------------------------------------- disegno

func _quad(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, c0: Color, c1: Color) -> void:
	_vv.append_array([p0, p1, p2, p0, p2, p3])
	_vc.append_array([c0, c1, c1, c0, c1, c0])


func _to_cam(p: Vector3) -> Vector3:
	var cam: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return Vector3.BACK
	return (cam.global_position - p).normalized()


func _a(c: Color, k: float) -> Color:
	return Color(c.r, c.g, c.b, clampf(k, 0.0, 1.0))


func _bez(u: float) -> Vector3:
	var m: Vector3 = (a + b) * 0.5 + bow
	return a.lerp(m, u).lerp(m.lerp(b, u), u)


# Nastro rivolto verso la telecamera lungo una curva: largo in mezzo e sottile alle punte (pennello).
func _ribbon(pts: Array, w: float, c: Color, k: float) -> void:
	if pts.size() < 2:
		return
	var n: int = pts.size()
	for i in n - 1:
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var tg: Vector3 = (p1 - p0).normalized()
		var s0: Vector3 = tg.cross(_to_cam(p0)).normalized()
		var u0: float = float(i) / float(n - 1)
		var u1: float = float(i + 1) / float(n - 1)
		var w0: float = w * sin(PI * u0) + 0.01
		var w1: float = w * sin(PI * u1) + 0.01
		_quad(p0 - s0 * w0, p1 - s0 * w1, p1 + s0 * w1, p0 + s0 * w0, _a(c, k), _a(c, k))


func _draw_stroke() -> void:
	var u: float = t / dur
	var head: float = ease(minf(1.0, u / 0.45), 0.4)
	var tail: float = clampf((u - 0.3) / 0.7, 0.0, 1.0)
	tail = tail * tail
	if head - tail < 0.02:
		return
	var segs: int = 10 if Settings.light_fx else 18
	var pts: Array = []
	for i in segs + 1:
		var s: float = lerpf(tail, head, float(i) / float(segs))
		# istinto: il tratto trema appena, come una mano che dipinge al buio
		var wob := Vector3(0, sin(s * 17.0 + seed_v) * 0.05, cos(s * 13.0 + seed_v) * 0.04)
		pts.append(_bez(s) + wob)
	var k: float = 1.0 - maxf(0.0, (u - 0.75) / 0.25)
	_ribbon(pts, width, col, 0.8 * k)
	_ribbon(pts, width * 0.32, IVORY, 0.9 * k)


func _draw_sparks() -> void:
	var k: float = t / dur
	var cam_dir: Vector3 = _to_cam(a)
	for s in _sparks:
		var dir: Vector3 = s[0]
		var p0: Vector3 = a + dir * float(s[1]) * t * (1.0 - 0.5 * k)
		var p1: Vector3 = p0 - dir * float(s[2]) * (1.0 - k)
		var side: Vector3 = dir.cross(cam_dir).normalized() * 0.035
		_quad(p0 - side, p1, p1, p0 + side, _a(IVORY, 1.0 - k), _a(col, 0.9 * (1.0 - k)))
	# lampo al centro, solo nei primi istanti
	if k < 0.35:
		var r: float = 0.25 + 0.6 * k
		var up: Vector3 = Vector3.UP.cross(cam_dir).normalized()
		var vu: Vector3 = cam_dir.cross(up).normalized()
		var c: Color = _a(col, 0.8 * (1.0 - k / 0.35))
		_quad(a - up * r, a - vu * r * 0.25, a + up * r, a + vu * r * 0.25, c, c)
		_quad(a - vu * r, a - up * r * 0.25, a + vu * r, a + up * r * 0.25, c, c)


func _draw_rise() -> void:
	var u: float = t / dur
	var head: float = ease(minf(1.0, u / 0.6), 0.5)
	var tail: float = clampf((u - 0.35) / 0.65, 0.0, 1.0)
	var segs: int = 12 if Settings.light_fx else 22
	for strand in 2:
		var pts: Array = []
		for i in segs + 1:
			var s: float = lerpf(tail, head, float(i) / float(segs))
			var ang: float = s * TAU * 1.4 + PI * float(strand)
			var r: float = radius * (1.0 - 0.35 * s)
			pts.append(a + Vector3(cos(ang) * r, 0.1 + s * 2.0, sin(ang) * r))
		_ribbon(pts, 0.12, col, 0.75)
		_ribbon(pts, 0.04, IVORY, 0.8)


# Arco piatto a terra fra due angoli, con spessore che si assottiglia alle punte.
func _arc(r: float, th: float, a0: float, a1: float, c: Color, k: float, segs: int) -> void:
	var y: float = a.y + 0.03
	for i in segs:
		var u0: float = float(i) / float(segs)
		var u1: float = float(i + 1) / float(segs)
		var b0: float = lerpf(a0, a1, u0)
		var b1: float = lerpf(a0, a1, u1)
		var w0: float = th * (0.35 + 0.65 * sin(PI * u0))
		var w1: float = th * (0.35 + 0.65 * sin(PI * u1))
		var d0 := Vector3(cos(b0), 0, sin(b0))
		var d1 := Vector3(cos(b1), 0, sin(b1))
		var o := Vector3(a.x, y, a.z)
		_quad(o + d0 * (r - w0), o + d1 * (r - w1), o + d1 * (r + w1), o + d0 * (r + w0), _a(c, k), _a(c, k))


func _draw_glyph() -> void:
	var pulse: float = 0.75 + 0.25 * sin(t * 4.0)
	var segs: int = 16 if Settings.light_fx else 28
	var rot: float = t * 1.6
	# l'arco grande e' un cerchio quasi chiuso, tracciato con un gesto solo (resta un varco)
	_arc(radius, 0.06, rot, rot + TAU * 0.86, col, 0.55 * pulse * _fade, segs)
	_arc(radius, 0.022, rot, rot + TAU * 0.86, IVORY, 0.55 * pulse * _fade, segs)
	_arc(radius * 0.72, 0.025, -rot * 1.3, -rot * 1.3 + TAU * 0.4, col, 0.4 * _fade, segs / 2)


func _draw_mark() -> void:
	var pulse: float = 0.7 + 0.3 * sin(t * 7.0)
	var segs: int = 14 if Settings.light_fx else 24
	_arc(radius, 0.07, 0.0, TAU, col, 0.6 * pulse * _fade, segs)
	_arc(radius, 0.025, 0.0, TAU, IVORY, 0.6 * pulse * _fade, segs)
	# quattro punte che puntano al centro e respirano avanti e indietro
	var inset: float = 0.12 * sin(t * 7.0)
	for i in 4:
		var ang: float = TAU * float(i) / 4.0 + PI * 0.25
		_arc(radius * 0.7 + inset, 0.09, ang - 0.12, ang + 0.12, col, 0.75 * _fade, 2)


func _draw_seal() -> void:
	var segs: int = 20 if Settings.light_fx else 36
	var pulse: float = 0.7 + 0.3 * sin(t * 2.2)
	_arc(radius, 0.05, 0.0, TAU, col, 0.35 * pulse * _fade, segs)
	_arc(radius * 0.82, 0.02, t * 0.5, t * 0.5 + TAU, col, 0.3 * _fade, segs)
	# tacche come un timbro d'ufficio: le Anomalie parlano in burocratese
	var ticks: int = 12
	for i in ticks:
		var ang: float = TAU * float(i) / float(ticks) - t * 0.35
		_arc(radius * 0.91, 0.07, ang, ang + 0.09, col, 0.45 * _fade, 1)
	# scintille che salgono: la magia che tiene in piedi l'oggetto
	var cam_dir: Vector3 = _to_cam(a)
	var side: Vector3 = Vector3.UP.cross(cam_dir).normalized()
	var motes: int = 4 if Settings.light_fx else 8
	for i in motes:
		var ph: float = fmod(t * 0.45 + float(i) * 0.618, 1.0)
		var ang2: float = float(i) * 2.4 + seed_v
		var p: Vector3 = a + Vector3(cos(ang2) * radius * 0.8, 0.2 + ph * 3.2, sin(ang2) * radius * 0.8)
		var s: float = 0.07 * (1.0 - ph * 0.6)
		var k: float = sin(PI * ph) * 0.8 * _fade
		_quad(p - side * s, p + Vector3.UP * s * 2.2, p + side * s, p - Vector3.UP * s * 2.2, _a(IVORY, k), _a(col, k))


# ---------------------------------------------------------------- 2D: i due fotogrammi neri dell'ultimate

# «Ultimate lanciata = due frame neri con sola luce del colore del personaggio» (battaglia V2, 17/10).
# Due lampi brevissimi di nero con una pennellata di luce, il secondo incrociato al primo. Spenti se i lampi sono a zero.
static func blackout(layer: Control, c: Color) -> void:
	if layer == null or Settings.flash <= 0.01 or not layer.is_inside_tree():
		return
	var sz: Vector2 = layer.get_viewport_rect().size
	var frames: Array = [[Vector2(-0.05, 0.22), Vector2(0.5, 0.42), Vector2(1.05, 0.8)],
		[Vector2(-0.05, 0.85), Vector2(0.45, 0.5), Vector2(1.05, 0.18)]]
	for f in frames:
		var black := ColorRect.new()
		black.color = Color(0.0, 0.0, 0.0, minf(1.0, 0.6 + 0.4 * Settings.flash))
		black.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Ui.place(black, 0, 0, 1, 1)
		layer.add_child(black)
		var pts := PackedVector2Array()
		for i in 13:
			var u: float = float(i) / 12.0
			var p0: Vector2 = f[0]
			var p1: Vector2 = f[1]
			var p2: Vector2 = f[2]
			var p: Vector2 = p0.lerp(p1, u).lerp(p1.lerp(p2, u), u)
			pts.append(p * sz + Vector2(0, sin(u * 11.0) * 6.0))
		var taper := Curve.new()
		taper.add_point(Vector2(0, 0.1))
		taper.add_point(Vector2(0.4, 1.0))
		taper.add_point(Vector2(1, 0.15))
		# alone largo e tenue, tratto del colore, nucleo avorio: lightpainting
		var widths: Array = [0.34, 0.16, 0.05]
		var cols: Array = [Color(c.r, c.g, c.b, 0.3), c, IVORY]
		for pass_i in 3:
			var ln := Line2D.new()
			ln.points = pts
			ln.width = sz.y * float(widths[pass_i])
			ln.width_curve = taper
			ln.default_color = cols[pass_i]
			ln.joint_mode = Line2D.LINE_JOINT_ROUND
			ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
			ln.end_cap_mode = Line2D.LINE_CAP_ROUND
			ln.antialiased = true
			black.add_child(ln)
		await layer.get_tree().create_timer(0.075).timeout
		if is_instance_valid(black):
			black.queue_free()
		if not is_instance_valid(layer) or not layer.is_inside_tree():
			return
		await layer.get_tree().create_timer(0.05).timeout
