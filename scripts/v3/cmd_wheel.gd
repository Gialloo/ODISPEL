class_name CmdWheel
extends Control

# Comandi della battaglia V3, alla Persona 5 / Persona 3 Reload / Metaphor: un grappolo di comandi accanto a chi e' di turno,
# parole grandi inclinate con l'iniziale enorme, una macchia di vernice spray (graffito, identita' ODISPEL) del colore del
# personaggio dietro, e un filo d'energia che dal personaggio arriva al comando scelto.
# Toccare un comando lo SCEGLIE: la parola cresce su una lastra nera, dal tasto escono raggi di luce interi (non tagliati),
# la scena si scurisce attorno al personaggio. Toccarlo di nuovo, o CONFERMA, lo lancia. L'ULTIMATE spinge tutto di piu'.
# PRESTAZIONI: vernice, raggi ed energia sono maglie di triangoli (una chiamata di disegno ciascuna) rifatte solo quando cambia
# il personaggio o la scelta; a ogni fotogramma si muovono solo trasformazioni.

signal tapped(kind: String)      # "attack" | "skill" | "ult" | "guard" | "confirm" | "cancel"

const KINDS: Array = ["attack", "skill", "ult", "guard"]
# posto di ogni comando rispetto al petto del personaggio (a zig-zag verso il nemico, come in Persona 5), in unita' "s"
const POS: Array = [Vector2(118, 118), Vector2(92, -38), Vector2(132, -116), Vector2(150, 40)]
const SIZE: Array = [1.25, 1.0, 1.08, 0.92]      # ATTACCO e' il piu' grande, come in tutti i riferimenti
const INK: Color = Color("#120a1c")
const CREAM: Color = Color("#fff4dc")
const HOT: Color = Color("#ffd23f")
const ECHO: Color = Color("#3fe0ff")

var center: Vector2 = Vector2(420, 400)    # petto del personaggio sullo schermo
var rx: float = 150.0                      # meta' larghezza / altezza del personaggio a schermo (la ruota si adatta)
var ry: float = 175.0
var col: Color = Color("#8b3dff")
var who: String = ""
var items: Array = []                      # {kind, name, sub, cost, ok, letter, title, desc}
var picked: String = ""
var t: float = 0.0
var appear: float = 0.0
var sel: float = 0.0
var flash: float = 0.0
var hits: Dictionary = {}                  # kind -> Rect2 relativo al centro
var _paint: _Layer                         # macchia di vernice spray dietro i comandi
var _beam: _Layer                          # filo d'energia dal personaggio al comando scelto (additivo)
var _rays: _Layer                          # raggi di luce dal tasto scelto (additivo, ruotano piano)
var _front: _Layer                         # tasti e parole
var _flow: CPUParticles2D                  # scintille che corrono lungo il filo d'energia
var _look: String = ""
var _front_at: Vector2 = Vector2.ZERO
var _under_was: bool = false              # serve un ultimo ridisegno per pulire bande e lampo


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_paint = _Layer.new(self, "paint")
	add_child(_paint)
	_beam = _Layer.new(self, "beam")
	_beam.material = add
	add_child(_beam)
	_rays = _Layer.new(self, "rays")
	_rays.material = add
	add_child(_rays)
	_flow = CPUParticles2D.new()
	_flow.texture = _streak_texture()
	_flow.amount = 16
	_flow.lifetime = 0.7
	_flow.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	_flow.spread = 6.0
	_flow.gravity = Vector2.ZERO
	_flow.initial_velocity_min = 260.0
	_flow.initial_velocity_max = 480.0
	_flow.scale_amount_min = 0.8
	_flow.scale_amount_max = 1.8
	_flow.particle_flag_align_y = true
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 0.2, 0.75, 1.0])
	gr.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
	_flow.color_ramp = gr
	_flow.material = add
	_flow.emitting = false
	add_child(_flow)
	_front = _Layer.new(self, "front")
	add_child(_front)
	# tutto sopra il mirino del nemico (z 1); le bande nere dell'ultimate (disegno della ruota, z 0) restano sotto i pannelli
	for n in [_paint, _beam, _rays, _flow, _front]:
		(n as CanvasItem).z_index = 2


func setup(p_who: String, p_col: Color, p_items: Array) -> void:
	var look: String = "%s|%s|%s" % [p_who, p_col.to_html(), str(p_items)]
	if p_who != who:
		appear = 0.0
		picked = ""
	who = p_who
	col = p_col
	items = p_items
	if look == _look:
		return
	_look = look
	_flow.color = col.lightened(0.55)
	_redraw_all()


func pick(kind: String) -> void:
	if kind == picked:
		return
	picked = kind
	if kind != "":
		flash = Settings.flash
		t = 0.0
	_redraw_all()


func item(kind: String) -> Dictionary:
	for it in items:
		if str(it["kind"]) == kind:
			return it
	return {}


# Scala del grappolo: segue la grandezza del personaggio a schermo, entro limiti leggibili sul telefono
func s() -> float:
	return clampf(ry / 200.0, 0.8, 1.0)


# Posto del tasto i rispetto al petto
func at(i: int) -> Vector2:
	return (POS[i] as Vector2) * s()


func _redraw_all() -> void:
	for n in [_paint, _beam, _rays, _front]:
		(n as CanvasItem).queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	appear = move_toward(appear, 1.0, delta / 0.45)
	var tgt: float = 1.0 if picked != "" else 0.0
	sel = move_toward(sel, tgt, delta / (0.4 if picked == "ult" else 0.22))
	flash = maxf(0.0, flash - delta * 3.2)
	var e: float = smoothstep(0.0, 1.0, sel)
	var ult: bool = picked == "ult"
	var pr: float = _ease3(appear * 1.3)
	# la vernice entra "spruzzata": cresce dal centro del grappolo con un piccolo rimbalzo, poi respira appena
	var pc: Vector2 = Vector2(150, 0) * s()
	var sc: float = (0.2 + 0.8 * _back(pr)) * (1.0 + 0.01 * sin(t * 1.6))
	_paint.position = center + pc - pc * sc
	_paint.scale = Vector2(sc, sc)
	_paint.modulate = Color(1, 1, 1, pr * (0.75 if ult else 1.0))
	var k: int = KINDS.find(picked)
	_beam.visible = k >= 0 and e > 0.01
	_rays.visible = _beam.visible
	if k >= 0:
		var ip: Vector2 = center + at(k)
		_beam.position = center
		_beam.modulate = Color(e, e, e, 1.0) * (1.4 if ult else 1.0)
		_rays.position = ip
		_rays.rotation = t * (0.5 if ult else 0.3)
		var rs: float = (0.55 + 0.45 * e) * (1.0 + 0.05 * sin(t * 6.0))
		_rays.scale = Vector2(rs, rs) * (1.35 if ult else 1.0)
		_rays.modulate = Color(e, e, e, 1.0)
		_flow.position = center
		_flow.emitting = not Settings.light_fx and e > 0.5
		_flow.speed_scale = 1.6 if ult else 1.0
		if not _flow.has_meta("k") or _flow.get_meta("k") != Vector3(k, s(), 0):
			_flow.set_meta("k", Vector3(k, s(), 0))
			var pts := PackedVector2Array()
			var dst: Vector2 = at(k)
			for j in 10:
				pts.append(_curve(dst, float(j) / 12.0))
			_flow.emission_points = pts
			_flow.direction = dst.normalized()
	else:
		_flow.emitting = false
	_front.position = center
	# i tasti non dipendono dal tempo: si ridisegnano solo durante l'entrata o il passaggio di scelta (telefono: meno lavoro)
	# (il riquadro e CONFERMA sono fissi sullo schermo: se il petto si sposta con la camera vanno ridisegnati)
	var moved: bool = picked != "" and center.distance_squared_to(_front_at) > 0.25
	if appear < 1.0 or (sel > 0.0 and sel < 1.0) or moved:
		_front.queue_redraw()
		_front_at = center
	var under: bool = flash > 0.0 or (ult and sel > 0.0)
	if under or _under_was:
		queue_redraw()
	_under_was = under


# Filo d'energia: curva dal petto al tasto, che si gonfia verso l'alto (sembra uscire dal personaggio)
func _curve(dst: Vector2, u: float) -> Vector2:
	var mid: Vector2 = dst * 0.5 + Vector2(-20, -60) * s()
	return (1.0 - u) * (1.0 - u) * Vector2(30, -10) * s() + 2.0 * (1.0 - u) * u * mid + u * u * dst


func _ease3(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)


func _back(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 1.0 + 2.2 * pow(x - 1.0, 3.0) + 1.2 * pow(x - 1.0, 2.0)


# Sotto a tutto: le bande nere oblique dell'ultimate e il lampo della scelta
func _draw() -> void:
	var e: float = smoothstep(0.0, 1.0, sel)
	if picked == "ult" and e > 0.01:
		var hi: Color = col.lightened(0.7)
		var bt: float = size.y * 0.13 * e
		draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, bt * 0.6), Vector2(0, bt * 1.4)]), Color(0, 0, 0.03, 0.9))
		draw_colored_polygon(PackedVector2Array([Vector2(0, size.y), Vector2(size.x, size.y), Vector2(size.x, size.y - bt * 1.4), Vector2(0, size.y - bt * 0.6)]), Color(0, 0, 0.03, 0.9))
		draw_line(Vector2(0, bt * 1.4), Vector2(size.x, bt * 0.6), Color(hi, 0.9 * e), 3.0, true)
		draw_line(Vector2(0, size.y - bt * 0.6), Vector2(size.x, size.y - bt * 1.4), Color(hi, 0.9 * e), 3.0, true)
	if flash > 0.01:
		draw_rect(Rect2(Vector2.ZERO, size), Color(col.lightened(0.7), flash * (0.4 if picked == "ult" else 0.16)))


func _has_point(p: Vector2) -> bool:
	for k in hits:
		if (hits[k] as Rect2).has_point(p - center):
			return true
	return false


func _gui_input(ev: InputEvent) -> void:
	var pressed: bool = (ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed) \
		or (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	if not pressed:
		return
	var p: Vector2 = (ev as InputEventScreenTouch).position if ev is InputEventScreenTouch else (ev as InputEventMouseButton).position
	for k in ["confirm", "cancel", "attack", "skill", "ult", "guard"]:
		if hits.has(k) and (hits[k] as Rect2).has_point(p - center):
			accept_event()
			tapped.emit(k)
			return


static func _streak_texture() -> Texture2D:
	# striscia di luce affusolata: testa luminosa, coda che sfuma
	var img := Image.create(8, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		var a: float = pow(float(y) / 63.0, 1.8)
		for x in 8:
			var cx: float = 1.0 - absf((float(x) - 3.5) / 3.5)
			img.set_pixel(x, y, Color(1, 1, 1, a * pow(cx, 0.7)))
	return ImageTexture.create_from_image(img)


# ---------- disegno ----------

static func skew_text(c: CanvasItem, p: Vector2, s: String, sz: int, fill: Color, outline: Color, f: Font, ow: int = 8, sk: float = -0.22) -> void:
	c.draw_set_transform_matrix(Transform2D(Vector2(1, 0), Vector2(sk, 1), p))
	if ow > 0:
		c.draw_string_outline(f, Vector2.ZERO, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, ow, outline)
	c.draw_string(f, Vector2.ZERO, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, fill)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)


static func slant(r: Rect2, sl: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(r.position.x + sl, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x - sl, r.end.y), Vector2(r.position.x, r.end.y)])


# Pennellata: striscia a larghezza variabile con bordi irregolari e setole a secco in fondo (come nella V2)
static func brush(c, a: Vector2, b: Vector2, w0: float, w1: float, fill: Color, sd: int, bend: float = 0.0, jag: float = 0.22, n: int = 16) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	var d: Vector2 = b - a
	var nrm: Vector2 = Vector2(-d.y, d.x).normalized()
	var L := PackedVector2Array()
	var R := PackedVector2Array()
	for i in n + 1:
		var u: float = float(i) / float(n)
		var p: Vector2 = a + d * u + nrm * sin(u * PI) * bend
		var w: float = maxf(1.5, lerpf(w0, w1, u) * 0.5)
		L.append(p + nrm * w * (1.0 + rng.randf_range(-jag, jag)))
		R.append(p - nrm * w * (1.0 + rng.randf_range(-jag, jag)))
	for i in n:
		c.draw_colored_polygon(PackedVector2Array([L[i], L[i + 1], R[i + 1], R[i]]), fill)
	for k in 4:
		var o: Vector2 = nrm * (float(k) - 1.5) * w1 * 0.3
		c.draw_line(b + o, b + o + d.normalized() * rng.randf_range(14.0, 44.0), fill, 2.0)


static func ribbon(c, pts: PackedVector2Array, w0: float, w1: float, fill: Color) -> void:
	var n: int = pts.size()
	var L := PackedVector2Array()
	var R := PackedVector2Array()
	for k in n:
		var a: Vector2 = pts[maxi(k - 1, 0)]
		var b: Vector2 = pts[mini(k + 1, n - 1)]
		var nr: Vector2 = (b - a).orthogonal().normalized()
		var w: float = lerpf(w0, w1, float(k) / float(n - 1)) * 0.5
		L.append(pts[k] + nr * w)
		R.append(pts[k] - nr * w)
	for k in n - 1:
		c.draw_colored_polygon(PackedVector2Array([L[k], L[k + 1], R[k + 1], R[k]]), fill)


# Icona del comando disegnata a mano (nessuna texture): spade incrociate, fulmine, esplosione, scudo
static func glyph(c: CanvasItem, kind: String, p: Vector2, r: float, fill: Color) -> void:
	match kind:
		"attack":
			for s in [-1.0, 1.0]:
				var a: Vector2 = p + Vector2(-r * 0.62 * s, -r * 0.62)
				var b: Vector2 = p + Vector2(r * 0.5 * s, r * 0.5)
				c.draw_line(a, b, fill, r * 0.2, true)
				var m: Vector2 = a.lerp(b, 0.72)
				var nrm: Vector2 = (b - a).orthogonal().normalized()
				c.draw_line(m - nrm * r * 0.28, m + nrm * r * 0.28, fill, r * 0.16, true)
		"skill":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(r * 0.15, -r * 0.8), p + Vector2(-r * 0.5, r * 0.1), p + Vector2(-r * 0.02, r * 0.1),
				p + Vector2(-r * 0.2, r * 0.8), p + Vector2(r * 0.5, -r * 0.12), p + Vector2(r * 0.02, -r * 0.12)]), fill)
		"ult":
			var pts := PackedVector2Array()
			for k in 16:
				var a: float = -PI / 2.0 + TAU * float(k) / 16.0
				pts.append(p + Vector2(cos(a), sin(a)) * (r * 0.82 if k % 2 == 0 else r * 0.36))
			c.draw_colored_polygon(pts, fill)
		"guard":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.6, -r * 0.62), p + Vector2(r * 0.6, -r * 0.62), p + Vector2(r * 0.56, r * 0.05),
				p + Vector2(0, r * 0.75), p + Vector2(-r * 0.56, r * 0.05)]), fill)


# Raccoglie triangoli colorati e li disegna in UNA chiamata (draw_mesh). Stessi nomi dei metodi di CanvasItem,
# cosi' brush() e ribbon() funzionano uguali; tri() ha un colore per vertice (sfumature senza tagli netti).
class _Mesh:
	var v := PackedVector2Array()
	var c := PackedColorArray()

	func tri(a: Vector2, b: Vector2, d: Vector2, ca: Color, cb: Color, cd: Color) -> void:
		v.append(a)
		v.append(b)
		v.append(d)
		c.append(ca)
		c.append(cb)
		c.append(cd)

	func draw_colored_polygon(pts: PackedVector2Array, col: Color) -> void:
		for k in range(1, pts.size() - 1):
			tri(pts[0], pts[k], pts[k + 1], col, col, col)

	func draw_line(a: Vector2, b: Vector2, col: Color, w: float = 1.0, _aa: bool = false) -> void:
		var n: Vector2 = (b - a).orthogonal().normalized() * w * 0.5
		draw_colored_polygon(PackedVector2Array([a + n, b + n, b - n, a - n]), col)

	func draw_circle(p: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for k in 12:
			var a: float = TAU * float(k) / 12.0
			pts.append(p + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, col)

	# disco sfumato: pieno al centro, trasparente al bordo (alone morbido senza texture)
	func glow(p: Vector2, r: float, col: Color) -> void:
		var n: int = 20
		for k in n:
			var a0: float = TAU * float(k) / float(n)
			var a1: float = TAU * float(k + 1) / float(n)
			tri(p, p + Vector2(cos(a0), sin(a0)) * r, p + Vector2(cos(a1), sin(a1)) * r, col, Color(col, 0.0), Color(col, 0.0))

	# nastro lungo una curva, largo w0 -> w1, trasparente ai due capi (niente estremita' tagliate)
	func band(pts: PackedVector2Array, w0: float, w1: float, col: Color) -> void:
		var n: int = pts.size()
		for k in n - 1:
			var u0: float = float(k) / float(n - 1)
			var u1: float = float(k + 1) / float(n - 1)
			var d0: Vector2 = (pts[mini(k + 1, n - 1)] - pts[maxi(k - 1, 0)]).orthogonal().normalized()
			var d1: Vector2 = (pts[mini(k + 2, n - 1)] - pts[k]).orthogonal().normalized()
			var h0: float = lerpf(w0, w1, u0) * 0.5
			var h1: float = lerpf(w0, w1, u1) * 0.5
			var a0: float = col.a * smoothstep(0.0, 0.18, u0) * (1.0 - smoothstep(0.8, 1.0, u0))
			var a1: float = col.a * smoothstep(0.0, 0.18, u1) * (1.0 - smoothstep(0.8, 1.0, u1))
			var c0 := Color(col, a0)
			var c1 := Color(col, a1)
			tri(pts[k] + d0 * h0, pts[k + 1] + d1 * h1, pts[k + 1] - d1 * h1, c0, c1, c1)
			tri(pts[k] + d0 * h0, pts[k + 1] - d1 * h1, pts[k] - d0 * h0, c0, c1, c0)

	func commit(ci: CanvasItem) -> ArrayMesh:
		if v.is_empty():
			return null
		var arr: Array = []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_COLOR] = c
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		ci.draw_mesh(m, null)
		return m     # va tenuta viva finche' il disegno resta a schermo


class _Layer extends Control:
	var w: CmdWheel
	var part: String
	var _keep: ArrayMesh

	func _init(p_w: CmdWheel, p_part: String) -> void:
		w = p_w
		part = p_part
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if w.items.size() < 4:
			return
		var m := CmdWheel._Mesh.new()
		match part:
			"paint":
				_paint(m)
			"beam":
				_beam(m)
			"rays":
				_rays(m)
			"front":
				_front()
				return
		_keep = m.commit(self)

	# Macchia di vernice spray (graffito): forma irregolare del colore del personaggio, un'ombra piu' scura dentro,
	# una seconda macchia ciano (Echo) in alto, colature verso il basso, schizzi e alone di spruzzo attorno.
	func _blob(m, c: Vector2, r: Vector2, fill: Color, seed: int, wob: float) -> void:
		var pts := PackedVector2Array()
		var n: int = 44
		var ph: float = float(seed) * 1.7
		for k in n:
			var a: float = TAU * float(k) / float(n)
			var q: float = 1.0 + wob * (0.55 * sin(a * 3.0 + ph) + 0.3 * sin(a * 7.0 + ph * 2.1) + 0.15 * sin(a * 13.0 + ph * 0.7))
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y) * q)
		for k in n:
			m.tri(c, pts[k], pts[(k + 1) % n], fill, fill, fill)

	func _paint(m) -> void:
		var s: float = w.s()
		var c0: Color = w.col
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var cc: Vector2 = Vector2(150, 0) * s
		# alone di spruzzo: puntini chiari attorno alla macchia
		for k in 60:
			var a: float = rng.randf() * TAU
			var q: Vector2 = cc + Vector2(cos(a) * 110.0, sin(a) * 175.0).rotated(-0.45) * s * rng.randf_range(1.0, 1.35)
			m.draw_circle(q, rng.randf_range(1.0, 2.8) * s, Color(c0.lightened(0.2), rng.randf_range(0.25, 0.6)))
		# pennellate spray diagonali (non un ovale pieno): tre colpi sovrapposti che lasciano passare la scena
		CmdWheel.brush(m, cc + Vector2(-60, 175) * s, cc + Vector2(70, -185) * s, 120.0 * s, 70.0 * s, Color(c0, 0.85), 11, 30.0 * s, 0.3, 18)
		CmdWheel.brush(m, cc + Vector2(-10, 150) * s, cc + Vector2(150, -60) * s, 70.0 * s, 26.0 * s, Color(c0.darkened(0.3), 0.75), 13, -20.0 * s, 0.35, 14)
		CmdWheel.brush(m, cc + Vector2(30, -120) * s, cc + Vector2(150, -175) * s, 48.0 * s, 18.0 * s, Color(CmdWheel.ECHO, 0.85), 17, 12.0 * s, 0.35, 10)
		# colature verso il basso
		for k in 5:
			var x: float = cc.x + rng.randf_range(-70.0, 40.0) * s
			var y0: float = cc.y + rng.randf_range(110.0, 160.0) * s
			var len: float = rng.randf_range(35.0, 110.0) * s
			var wd: float = rng.randf_range(4.0, 8.0) * s
			m.draw_colored_polygon(PackedVector2Array([Vector2(x - wd * 0.5, y0 - 16.0 * s), Vector2(x + wd * 0.5, y0 - 16.0 * s), Vector2(x + wd * 0.35, y0 + len), Vector2(x - wd * 0.35, y0 + len)]), Color(c0, 0.85))
			m.draw_circle(Vector2(x, y0 + len), wd * 0.55, Color(c0, 0.85))
		# schizzi
		for k in 16:
			var a: float = rng.randf() * TAU
			var q: Vector2 = cc + Vector2(cos(a) * 130.0, sin(a) * 200.0).rotated(-0.45) * s * rng.randf_range(1.0, 1.3)
			m.draw_circle(q, rng.randf_range(2.5, 7.0) * s, Color(c0 if k % 3 else CmdWheel.ECHO, 0.85))
		# arco sottile attorno al personaggio (il cerchio di Metaphor)
		var pts := PackedVector2Array()
		for k in 40:
			var a: float = deg_to_rad(lerpf(110.0, 250.0, float(k) / 39.0))
			pts.append(Vector2(cos(a) * w.rx * 1.6, sin(a) * w.ry * 1.2))
		for k in 39:
			m.draw_line(pts[k], pts[k + 1], Color(CmdWheel.CREAM, 0.4), 2.0 * s)

	# filo d'energia: dal petto al tasto scelto, alone largo + nucleo quasi bianco, trasparente ai due capi
	func _beam(m) -> void:
		var k: int = CmdWheel.KINDS.find(w.picked)
		if k < 0:
			return
		var s: float = w.s()
		var dst: Vector2 = w.at(k)
		var pts := PackedVector2Array()
		for j in 26:
			pts.append(w._curve(dst, float(j) / 25.0))
		var ult: bool = w.picked == "ult"
		var g: float = 1.5 if ult else 1.0
		m.band(pts, 70.0 * s * g, 34.0 * s * g, Color(w.col, 0.16))
		m.band(pts, 34.0 * s * g, 18.0 * s * g, Color(w.col.lightened(0.25), 0.4))
		m.band(pts, 12.0 * s * g, 7.0 * s * g, Color(w.col.lightened(0.7), 0.85))
		m.band(pts, 4.0 * s, 3.0 * s, Color(1, 1, 1, 0.95))
		m.glow(Vector2(30, -10) * s, 60.0 * s * g, Color(w.col.lightened(0.3), 0.5))

	# raggi di luce dal tasto scelto: interi, sfumati verso la punta, con alone morbido e nucleo bianco
	func _rays(m) -> void:
		var ult: bool = w.picked == "ult"
		var s: float = w.s()
		var rng := RandomNumberGenerator.new()
		rng.seed = 31
		var n: int = 22 if ult else 14
		var hi: Color = w.col.lightened(0.55)
		for k in n:
			var a: float = TAU * (float(k) + rng.randf_range(-0.25, 0.25)) / float(n)
			var d: Vector2 = Vector2(cos(a), sin(a))
			var perp: Vector2 = d.orthogonal()
			var r0: float = 22.0 * s
			var len: float = rng.randf_range(70.0, 170.0) * s * (1.3 if ult else 1.0)
			var hw: float = rng.randf_range(5.0, 11.0) * s
			m.tri(d * r0 + perp * hw, d * r0 - perp * hw, d * (r0 + len), Color(hi, 0.85), Color(hi, 0.85), Color(hi, 0.0))
			if k % 2 == 0:
				m.tri(d * r0 + perp * hw * 0.35, d * r0 - perp * hw * 0.35, d * (r0 + len * 0.75), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.0))
		m.glow(Vector2.ZERO, 120.0 * s * (1.3 if ult else 1.0), Color(w.col, 0.55))
		m.glow(Vector2.ZERO, 55.0 * s, Color(hi, 0.7))

	# una parola alla Persona 5: iniziale enorme, resto grande, inclinata e ruotata, contorno nero spesso e ombra colorata
	func _word(p: Vector2, s: String, big: int, small: int, fill: Color, shade: Color, rot: float) -> float:
		var f: Font = Ui.display()
		var ini: String = s.substr(0, 1)
		var rest: String = s.substr(1)
		var wi: float = f.get_string_size(ini, HORIZONTAL_ALIGNMENT_LEFT, -1, big).x
		var wr: float = f.get_string_size(rest, HORIZONTAL_ALIGNMENT_LEFT, -1, small).x
		draw_set_transform_matrix(Transform2D(rot, Vector2.ONE, -0.25, p))
		for pass_i in 2:
			var off: Vector2 = Vector2(5, 5) if pass_i == 0 else Vector2.ZERO
			var c: Color = shade if pass_i == 0 else fill
			if pass_i == 1:
				draw_string_outline(f, Vector2.ZERO, ini, HORIZONTAL_ALIGNMENT_LEFT, -1, big, 12, CmdWheel.INK)
				draw_string_outline(f, Vector2(wi - 2.0, 0), rest, HORIZONTAL_ALIGNMENT_LEFT, -1, small, 10, CmdWheel.INK)
			draw_string(f, off, ini, HORIZONTAL_ALIGNMENT_LEFT, -1, big, c)
			draw_string(f, off + Vector2(wi - 2.0, 0), rest, HORIZONTAL_ALIGNMENT_LEFT, -1, small, c)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return wi + wr

	func _front() -> void:
		var fd: Font = Ui.display()
		var fb: Font = Ui.body()
		var s: float = w.s()
		var origin: Vector2 = w.center
		w.hits.clear()      # rettangoli di tocco relativi al petto (il centro segue il personaggio)
		var e: float = smoothstep(0.0, 1.0, w.sel)
		for k in 4:
			var it: Dictionary = w.items[k]
			var kind: String = str(it["kind"])
			var on: bool = w.picked == kind
			var ult: bool = kind == "ult"
			var ok: bool = bool(it["ok"])
			var dimmed: bool = (w.picked != "" and not on) or not ok
			var pe: float = w._ease3(w.appear * 1.6 - float(k) * 0.1)
			var p_rest: Vector2 = w.at(k)
			var p: Vector2 = p_rest.lerp(p_rest + Vector2(-60, 0) * s, 1.0 - pe)
			var fa: float = clampf(pe * 1.5, 0.0, 1.0)
			var sz: float = float(CmdWheel.SIZE[k]) * s * (1.0 + 0.16 * e * (1.0 if on else 0.0))
			var rad: float = 25.0 * sz
			# lastra nera dietro la parola scelta (Persona 5), col bordo del colore del personaggio
			var big: int = int(50.0 * sz)
			var small: int = int(29.0 * sz)
			var nm: String = str(it["name"])
			var tw: float = fd.get_string_size(nm.substr(0, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, big).x + fd.get_string_size(nm.substr(1), HORIZONTAL_ALIGNMENT_LEFT, -1, small).x
			var x0: float = p.x + rad + 10.0
			var by: float = p.y + small * 0.42
			if on:
				# inversione alla Persona 5: lastra piena del colore del personaggio (ombra nera sfalsata) e parola nera
				var pl := PackedVector2Array([Vector2(x0 - 24.0, by - big * 0.8), Vector2(x0 + tw + 40.0, by - big * 0.95), Vector2(x0 + tw + 22.0, by + 14.0), Vector2(x0 - 40.0, by + 22.0)])
				var psh := PackedVector2Array()
				for q in pl:
					psh.append(q + Vector2(7, 7))
				draw_colored_polygon(psh, Color(0.02, 0.01, 0.04, 0.95 * e))
				draw_colored_polygon(pl, Color(w.col.lightened(0.12), e))
			# tasto rotondo con l'icona e il numero (tastiera 1-4)
			var ring: Color = CmdWheel.HOT if on else (w.col.lightened(0.45) if ult and ok else CmdWheel.CREAM)
			if ult and ok and not on:
				draw_circle(p, rad + 8.0, Color(w.col, 0.55 * fa))
			draw_circle(p + Vector2(3, 4), rad, Color(0, 0, 0, 0.55 * fa))
			draw_circle(p, rad, Color(CmdWheel.CREAM, fa) if on else Color(0.04, 0.03, 0.08, fa))
			draw_arc(p, rad, 0.0, TAU, 40, Color(ring, (0.5 if dimmed else 1.0) * fa), 4.0, true)
			CmdWheel.glyph(self, kind, p, rad * 0.62, Color(CmdWheel.INK, fa) if on else Color(ring, (0.5 if dimmed else 1.0) * fa))
			var kp: Vector2 = p + Vector2(-rad * 0.75, -rad * 0.75)
			draw_circle(kp, 10.0, Color(w.col, fa))
			draw_arc(kp, 10.0, 0.0, TAU, 20, Color(CmdWheel.INK, fa), 2.0, true)
			draw_string(fb, kp + Vector2(-4.5, 5.5), str(k + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(CmdWheel.CREAM, fa))
			# la parola: crema col contorno nero, gialla se scelta, spenta se non si puo' usare
			var fill: Color = CmdWheel.INK if on else Color(CmdWheel.CREAM, 0.5 if dimmed else 1.0)
			var shade: Color = Color(w.col.lightened(0.3), 1.0) if on else Color(w.col.darkened(0.25), (0.45 if dimmed else 1.0))
			_word(Vector2(x0, by), nm, big, small, Color(fill, fill.a * fa), Color(shade, shade.a * fa), -0.1)
			# sottotitolo e costo, piccoli e corsivi sotto la parola (come "Use a Skill" in Persona 5)
			var sub: String = str(it["sub"])
			var cost: String = str(it["cost"])
			var line: String = sub + ("  ·  " + cost if cost != "" else "")
			var sx: float = x0 + tw * 0.32
			var sy: float = by + 24.0 * sz
			draw_set_transform_matrix(Transform2D(-0.1, Vector2.ONE, -0.2, Vector2(sx, sy)))
			draw_string_outline(fb, Vector2.ZERO, line, HORIZONTAL_ALIGNMENT_LEFT, -1, int(19.0 * maxf(s, 0.95)), 7, Color(CmdWheel.INK, fa))
			draw_string(fb, Vector2.ZERO, line, HORIZONTAL_ALIGNMENT_LEFT, -1, int(19.0 * maxf(s, 0.95)), Color((w.col.lightened(0.6) if ult else CmdWheel.CREAM), (0.6 if dimmed else 1.0) * fa))
			draw_set_transform_matrix(Transform2D.IDENTITY)
			var hit := Rect2(p - Vector2(rad + 12.0, rad + 12.0), Vector2(rad * 2.0 + 24.0, rad * 2.0 + 24.0))
			hit = hit.merge(Rect2(x0 - 10.0, by - big * 0.85, tw + 40.0, big * 0.85 + 34.0 * sz))
			w.hits[kind] = hit
		if w.picked == "":
			return
		# riquadro della scelta in alto a destra: nome della mossa e cosa fa
		var it2: Dictionary = w.item(w.picked)
		var title: String = str(it2.get("title", ""))
		var desc: String = str(it2.get("desc", ""))
		var right: float = w.size.x - origin.x - 24.0
		var ttw: float = fd.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		var bx: float = right - ttw - 70.0 + (1.0 - e) * 120.0
		var by2: float = 196.0 - origin.y
		draw_colored_polygon(CmdWheel.slant(Rect2(bx - 20.0, by2 - 32.0, ttw + 90.0, 42.0), 14.0), Color(0.03, 0.02, 0.06, 0.92 * e))
		draw_colored_polygon(CmdWheel.slant(Rect2(bx - 26.0, by2 + 10.0, ttw + 96.0, 4.0), 3.0), Color(w.col.lightened(0.2), e))
		CmdWheel.glyph(self, w.picked, Vector2(bx + 6.0, by2 - 11.0), 13.0, Color(w.col.lightened(0.4), e))
		CmdWheel.skew_text(self, Vector2(bx + 34.0, by2), title, 28, Color(CmdWheel.CREAM, e), Color(0, 0, 0, 0), fd, 0)
		var ly: float = by2 + 36.0
		for line2 in desc.split("\n"):
			var lw: float = fb.get_string_size(line2, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
			CmdWheel.skew_text(self, Vector2(right - lw - 10.0 + (1.0 - e) * 120.0, ly), line2, 18, Color(CmdWheel.CREAM, e), Color(0.03, 0.02, 0.06, 0.95 * e), fb, 7, -0.12)
			ly += 24.0
		# CONFERMA e ANNULLA: a destra sotto il riquadro, sulla stessa riga, sopra la squadra
		var cp: Vector2 = Vector2(w.size.x - origin.x - 230.0, 290.0 - origin.y)
		var crr := Rect2(cp + Vector2((1.0 - e) * 90.0, 0.0), Vector2(200.0, 52.0))
		draw_colored_polygon(CmdWheel.slant(crr.grow(4.0), 12.0), Color(0.03, 0.02, 0.06, 0.9 * e))
		draw_colored_polygon(CmdWheel.slant(crr, 10.0), Color(CmdWheel.HOT, e))
		var cwid: float = fd.get_string_size("CONFERMA", HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		CmdWheel.skew_text(self, crr.position + Vector2((crr.size.x - cwid) * 0.5, 38.0), "CONFERMA", 28, Color(CmdWheel.INK, e), Color(0, 0, 0, 0), fd, 0)
		var arr := Rect2(crr.position + Vector2(-176.0, 8.0), Vector2(160.0, 36.0))
		draw_colored_polygon(CmdWheel.slant(arr, 8.0), Color(0.03, 0.02, 0.06, 0.85 * e))
		var awid: float = fb.get_string_size("ANNULLA", HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
		draw_string(fb, arr.position + Vector2((arr.size.x - awid) * 0.5, 25.0), "ANNULLA", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(CmdWheel.CREAM, e))
		w.hits["confirm"] = crr.grow(6.0)
		w.hits["cancel"] = arr.grow(4.0)


# Riflettore: la scena si scurisce attorno a chi sceglie e lui resta in luce, con un'aura del suo colore (piu' forte per l'ULTIMATE).
# Un solo rettangolo con uno shader: costa un passaggio a tutto schermo, solo mentre una scelta e' aperta.
static func make_spot() -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.visible = false
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform vec2 c = vec2(0.3, 0.55);
uniform vec2 r = vec2(0.12, 0.3);
uniform float k = 0.0;
uniform float aura = 0.0;
uniform vec3 tint : source_color = vec3(0.55, 0.25, 1.0);
void fragment() {
	float q = length((UV - c) / r);
	float dark = k * mix(0.12, 1.0, smoothstep(0.7, 1.45, q));
	float glow = aura * exp(-pow((q - 0.95) * 2.6, 2.0));
	vec3 col = mix(vec3(0.015, 0.0, 0.05), tint, clamp(glow * 1.4, 0.0, 1.0));
	COLOR = vec4(col, clamp(max(dark, glow * 0.55), 0.0, 1.0));
}"""
	var m := ShaderMaterial.new()
	m.shader = sh
	r.material = m
	return r
