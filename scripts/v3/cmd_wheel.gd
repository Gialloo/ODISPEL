class_name CmdWheel
extends Control

# Ruota dei comandi della V3, ripresa dall'HUD della V2 (battaglia in chiaro): i quattro comandi stanno ATTORNO a chi e' di
# turno senza coprirlo, ognuno con la sua lettera grande dietro e una pennellata del colore del personaggio che parte dal
# corpo e passa sotto il tasto. Toccare un comando lo SCEGLIE: la sua pennellata si accende in luce (light painting), la scena
# si scurisce attorno al personaggio (riflettore) e compare il riquadro con nome e cosa fa. Toccarlo di nuovo, o CONFERMA,
# lo lancia. L'ULTIMATE spinge tutto di piu': buio quasi pieno, bande nere oblique, aura del personaggio.
# Riferimenti (Persona 5 / P3 Reload / Metaphor): comandi vicino al personaggio, centro libero, ogni scelta ha uno scatto.
# PRESTAZIONI: pennellate e lettere si ridisegnano solo quando cambia il personaggio o la scelta; a ogni fotogramma si
# muovono solo trasformazioni (respiro, ondeggio) e i pochi archi degli anelli.

signal tapped(kind: String)      # un comando toccato ("attack" | "skill" | "ult" | "guard" | "confirm" | "cancel")

const KINDS: Array = ["attack", "skill", "ult", "guard"]
# angolo (gradi, schermo) di ogni comando attorno al personaggio: ATTACCO verso il nemico, ABILITA' sopra la testa,
# ULTIMATE in basso a destra (la piu' grande), GUARDIA dietro le spalle
const ANG: Array = [-14.0, -64.0, 38.0, 196.0]
const INK: Color = Color("#120a1c")
const CREAM: Color = Color("#fff4dc")
const HOT: Color = Color("#ffd23f")

var center: Vector2 = Vector2(420, 400)    # petto del personaggio sullo schermo
var rx: float = 150.0                      # semiassi dell'ellisse dei comandi (il corpo e' alto: ellisse verticale)
var ry: float = 175.0
var col: Color = Color("#8b3dff")
var who: String = ""
var items: Array = []                      # {kind, name, sub, cost, ok, letter, title, desc}
var picked: String = ""
var t: float = 0.0
var appear: float = 0.0                    # ingresso a catena dei comandi
var sel: float = 0.0                       # 0..1 intensita' della scelta
var flash: float = 0.0
var hits: Dictionary = {}                  # kind -> Rect2 di tocco
var _paint: Array = []                     # pennellate piatte (una per direzione)
var _light: Array = []                     # stesse pennellate in luce (additive), accese sulla scelta
var _letters: _Layer
var _front: _Layer
var _rings: _Layer
var _streaks: Array = []
var _look: String = ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	# PRESTAZIONI: un solo nodo per le quattro pennellate, uno per la luce (solo il comando scelto) e uno per le scie:
	# ogni nodo in piu' (e ogni cambio di materiale) e' una chiamata di disegno in piu' sul telefono
	var p := _Layer.new(self, "paint", -1)
	add_child(p)
	_paint.append(p)
	var l := _Layer.new(self, "light", -1)
	l.material = add
	l.visible = false
	add_child(l)
	_light.append(l)
	var st := _streak_texture()
	for i in 1:
		var ps := CPUParticles2D.new()
		ps.texture = st
		ps.amount = 9
		ps.lifetime = 1.0
		ps.preprocess = 1.0
		ps.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
		ps.spread = 7.0
		ps.gravity = Vector2.ZERO
		ps.initial_velocity_min = 170.0
		ps.initial_velocity_max = 330.0
		ps.damping_min = 40.0
		ps.damping_max = 110.0
		ps.scale_amount_min = 0.9
		ps.scale_amount_max = 2.0
		ps.particle_flag_align_y = true
		var gr := Gradient.new()
		gr.offsets = PackedFloat32Array([0.0, 0.18, 0.7, 1.0])
		gr.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
		ps.color_ramp = gr
		ps.material = add
		ps.emitting = false
		add_child(ps)
		_streaks.append(ps)
	# pennellate, lettere e tasti sopra il mirino del nemico (z 1); le bande nere dell'ultimate (disegno della ruota, z 0)
	# restano sotto i pannelli di nemico e squadra
	for n in _paint + _light + _streaks:
		(n as CanvasItem).z_index = 2
	_letters = _Layer.new(self, "letters", 0)
	add_child(_letters)
	_rings = _Layer.new(self, "rings", 0)
	add_child(_rings)
	_front = _Layer.new(self, "front", 0)
	add_child(_front)
	for n in [_letters, _rings, _front]:
		(n as CanvasItem).z_index = 2


# Nuovo turno o dati cambiati: ricostruisce i disegni solo se qualcosa e' davvero diverso
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
	for ps in _streaks:
		(ps as CPUParticles2D).color = col.lightened(0.45)
	_redraw_all()


func pick(kind: String) -> void:
	if kind == picked:
		return
	picked = kind
	if kind != "":
		flash = Settings.flash
	_redraw_all()


func dir_of(i: int) -> Vector2:
	var a: float = deg_to_rad(float(ANG[i]))
	return Vector2(cos(a), sin(a))


# Punto dell'ellisse nella direzione i, a k volte il raggio (1 = posto del tasto)
func at(i: int, k: float) -> Vector2:
	var d: Vector2 = dir_of(i)
	return Vector2(d.x * rx, d.y * ry) * k


func item(kind: String) -> Dictionary:
	for it in items:
		if str(it["kind"]) == kind:
			return it
	return {}


func _redraw_all() -> void:
	for n in _paint + _light:
		(n as CanvasItem).queue_redraw()
	_letters.queue_redraw()
	_front.queue_redraw()
	_rings.queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	appear = move_toward(appear, 1.0, delta / 0.55)
	var tgt: float = 1.0 if picked != "" else 0.0
	sel = move_toward(sel, tgt, delta / (0.45 if picked == "ult" else 0.25))
	flash = maxf(0.0, flash - delta * 3.2)
	var e: float = smoothstep(0.0, 1.0, sel)
	var ult: bool = picked == "ult"
	var pr: float = _ease3(appear * 1.5)
	var sc: float = (0.3 + 0.7 * pr) * (1.0 + 0.012 * sin(t * 1.8))
	var rot: float = sin(t * 1.5) * 0.015
	var p: CanvasItem = _paint[0]
	p.position = center
	p.scale = Vector2(sc, sc)
	p.rotation = rot
	var dimk: float = 0.4 * e
	p.modulate = Color(1.0 - dimk, 1.0 - dimk, 1.0 - dimk, pr * (0.55 if ult else 1.0))
	var l: CanvasItem = _light[0]
	var kk: float = e * (1.6 if ult else 1.0) * pr
	l.visible = kk > 0.01 and picked != ""
	l.position = center
	l.scale = Vector2(sc, sc) * (1.0 + 0.04 * e)
	l.rotation = rot
	l.modulate = Color(kk, kk, kk, 1.0)
	var ps: CPUParticles2D = _streaks[0]
	var pi: int = KINDS.find(picked)
	ps.position = center
	ps.emitting = not Settings.light_fx and pi >= 0 and pr > 0.5
	ps.modulate.a = pr
	ps.speed_scale = 1.0 + 1.4 * e
	if pi >= 0 and (not ps.has_meta("rk") or ps.get_meta("rk") != Vector3(rx, ry, pi)):
		ps.set_meta("rk", Vector3(rx, ry, pi))
		var pts := PackedVector2Array()
		for k in 14:
			pts.append(at(pi, lerpf(0.45, 1.5, float(k) / 13.0)))
		ps.emission_points = pts
		ps.direction = Vector2(dir_of(pi).x * rx, dir_of(pi).y * ry).normalized()
	_letters.position = center
	_letters.modulate.a = _ease3(appear * 1.4 - 0.1)
	_front.position = center
	_front.modulate.a = 1.0
	_rings.position = center
	_rings.queue_redraw()
	if appear < 1.0 or sel > 0.0 and sel < 1.0 or flash > 0.0:
		_front.queue_redraw()
	queue_redraw()


func _ease3(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)


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
		draw_rect(Rect2(Vector2.ZERO, size), Color(col.lightened(0.7), flash * (0.4 if picked == "ult" else 0.18)))


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
	# prima CONFERMA/ANNULLA (stanno sopra), poi i comandi
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


# Raccoglie triangoli colorati e li disegna in UNA chiamata (draw_mesh): le pennellate sono centinaia di poligoni e
# disegnate una per una costavano ~220 chiamate di disegno a fotogramma. Stessi nomi dei metodi di CanvasItem,
# cosi' brush() e ribbon() funzionano uguali.
class _Mesh:
	var v := PackedVector2Array()
	var c := PackedColorArray()

	func draw_colored_polygon(pts: PackedVector2Array, col: Color) -> void:
		for k in range(1, pts.size() - 1):
			v.append(pts[0])
			v.append(pts[k])
			v.append(pts[k + 1])
			c.append(col)
			c.append(col)
			c.append(col)

	func draw_line(a: Vector2, b: Vector2, col: Color, w: float = 1.0, _aa: bool = false) -> void:
		var n: Vector2 = (b - a).orthogonal().normalized() * w * 0.5
		draw_colored_polygon(PackedVector2Array([a + n, b + n, b - n, a - n]), col)

	func draw_circle(p: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for k in 10:
			var a: float = TAU * float(k) / 10.0
			pts.append(p + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, col)

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
	var i: int
	var _keep: ArrayMesh

	func _init(p_w: CmdWheel, p_part: String, p_i: int) -> void:
		w = p_w
		part = p_part
		i = p_i
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if w.items.size() < 4:
			return
		match part:
			"paint":
				var m := CmdWheel._Mesh.new()
				for k in 4:
					i = k
					_paint(m)
				_keep = m.commit(self)
			"light":
				i = CmdWheel.KINDS.find(w.picked)
				if i >= 0:
					var m2 := CmdWheel._Mesh.new()
					_light(m2)
					_keep = m2.commit(self)
			"letters":
				_letters()
			"front":
				_front()
			"rings":
				_rings()

	# pennellata della direzione i: parte dal bordo del corpo, passa sotto il tasto e va oltre
	func _paint(m) -> void:
		var d: Vector2 = w.at(i, 1.0).normalized()
		var perp: Vector2 = d.orthogonal()
		var a: Vector2 = w.at(i, 0.42)
		var tip: Vector2 = w.at(i, 1.0) + d * 150.0
		var bend: float = 30.0 * (1.0 if i % 2 == 0 else -1.0)
		var ok: bool = bool(w.items[i]["ok"])
		var c0: Color = w.col if ok else w.col.darkened(0.55)
		CmdWheel.brush(m, a, tip, 92.0, 18.0, Color(c0, 0.92), 40 + i, bend)
		CmdWheel.brush(m, a + d * 30.0 + perp * 14.0, w.at(i, 1.0) + d * 90.0 + perp * 24.0, 32.0, 7.0, Color(c0.lightened(0.55), 0.9), 60 + i, -18.0)
		CmdWheel.brush(m, w.at(i, 0.9) - perp * 22.0, w.at(i, 1.0) + d * 80.0 - perp * 38.0, 11.0, 3.0, Color("#d8f4ff", 0.9), 80 + i, 8.0, 0.2, 8)
		var rng := RandomNumberGenerator.new()
		rng.seed = 21 + i * 7
		for k in 12:
			var q: Vector2 = a + d * rng.randf_range(20.0, (tip - a).length() + 30.0) + perp * rng.randf_range(-60.0, 60.0)
			m.draw_circle(q, rng.randf_range(1.6, 5.5), c0 if k % 4 else c0.lightened(0.6))

	# light painting: la stessa forma resa come scie di luce (alone morbido, fasci sottili, nucleo quasi bianco)
	func _light(m) -> void:
		var d: Vector2 = w.at(i, 1.0).normalized()
		var perp: Vector2 = d.orthogonal()
		var a0: Vector2 = w.at(i, 0.38)
		var bend: float = 30.0 * (1.0 if i % 2 == 0 else -1.0)
		var len: float = (w.at(i, 1.0) - a0).length() + 170.0
		for g in 4:
			CmdWheel.brush(m, a0, a0 + d * len, 92.0 + float(4 - g) * 30.0, 26.0 + float(3 - g) * 10.0, Color(w.col, 0.05 + float(g) * 0.035), 40 + i, bend, 0.1)
		for sp in [[-26.0, 1.0], [0.0, 1.08], [24.0, 0.88], [-11.0, 0.7], [12.0, 0.6]]:
			var pts := PackedVector2Array()
			var b0: Vector2 = a0 + d * len * float(sp[1])
			var dd: Vector2 = b0 - a0
			var nrm: Vector2 = dd.orthogonal().normalized()
			for k in 20:
				var u: float = float(k) / 19.0
				pts.append(a0 + dd * u + nrm * sin(u * PI) * bend + perp * float(sp[0]) * (1.0 - 0.6 * u))
			CmdWheel.ribbon(m, pts, 36.0, 4.0, Color(w.col, 0.12))
			CmdWheel.ribbon(m, pts, 20.0, 3.0, Color(w.col.lightened(0.15), 0.26))
			CmdWheel.ribbon(m, pts, 9.0, 2.0, Color(w.col.lightened(0.5), 0.6))
			CmdWheel.ribbon(m, pts, 3.4, 1.2, Color(w.col.lightened(0.88), 0.95))

	# lettere grandi dietro i tasti (A, la prima lettera dell'abilita', U, G): bianche, accese sulla scelta
	func _letters() -> void:
		var f: Font = Ui.display()
		for k in 4:
			var it: Dictionary = w.items[k]
			var on: bool = w.picked == str(it["kind"])
			var s: String = str(it["letter"])
			var sz: int = 150 if on else 128
			var tw: float = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
			var lp: Vector2 = w.at(k, 1.0) + w.at(k, 1.0).normalized() * 70.0 + Vector2(-tw * 0.5, sz * 0.36)
			var dimk: float = 0.5 if (w.picked != "" and not on) or not bool(it["ok"]) else 1.0
			CmdWheel.skew_text(self, lp + Vector2(5, 5), s, sz, Color(w.col.darkened(0.4), 0.85 * dimk), Color(0, 0, 0, 0), f, 0)
			if on:
				CmdWheel.skew_text(self, lp, s, sz, Color(w.col, 0.35), Color(w.col, 0.35), f, 34)
				CmdWheel.skew_text(self, lp, s, sz, Color(1, 1, 1, 0.9), Color(w.col.lightened(0.2), 0.8), f, 18)
			CmdWheel.skew_text(self, lp, s, sz, Color(CmdWheel.CREAM, dimk) if not on else Color.WHITE, Color(0.05, 0.02, 0.06, 0.95 * dimk), f, 10)

	# anelli di energia: pulsano sul comando scelto e sull'ULTIMATE carica (pochi archi, ridisegnati ogni fotogramma)
	func _rings() -> void:
		for k in 4:
			var it: Dictionary = w.items[k]
			var p: Vector2 = w.at(k, 1.0)
			if w.picked == str(it["kind"]):
				var pulse: float = 0.5 + 0.5 * sin(w.t * 7.0)
				draw_arc(p, 48.0 + 5.0 * pulse, 0.0, TAU, 40, Color(w.col.lightened(0.5), 0.35 + 0.4 * pulse), 3.0, true)
				for j in 3:
					var u: float = fposmod(w.t * 0.8 + float(j) / 3.0, 1.0)
					draw_arc(p, 40.0 + u * 70.0, 0.0, TAU, 36, Color(CmdWheel.HOT, (1.0 - u) * 0.65), 3.0 * (1.0 - u) + 1.0, true)
			elif str(it["kind"]) == "ult" and bool(it["ok"]) and w.picked == "":
				var up: float = 0.5 + 0.5 * sin(w.t * 4.0)
				draw_arc(p, 40.0 + 3.0 * up, 0.0, TAU, 56, Color(w.col.lightened(0.45), 0.25 + 0.45 * up), 3.0, true)
				var s0: float = w.t * 3.0
				draw_arc(p, 32.0, s0, s0 + 0.9, 14, Color(1, 1, 1, 0.95), 5.0, true)

	func _front() -> void:
		var fd: Font = Ui.display()
		var fb: Font = Ui.body()
		var origin: Vector2 = w.center
		w.hits.clear()      # rettangoli di tocco relativi al centro della ruota (il centro segue il personaggio)
		for k in 4:
			var it: Dictionary = w.items[k]
			var kind: String = str(it["kind"])
			var on: bool = w.picked == kind
			var ult: bool = kind == "ult"
			var ok: bool = bool(it["ok"])
			var pe: float = w._ease3(w.appear * 1.6 - float(k) * 0.12)
			var back: float = 1.0 + 2.2 * pow(pe - 1.0, 3.0) + 1.2 * pow(pe - 1.0, 2.0)    # entra con un piccolo rimbalzo
			var p_rest: Vector2 = w.at(k, 1.0)
			var p: Vector2 = Vector2.ZERO.lerp(p_rest, clampf(back, 0.0, 1.2))
			var rad: float = (36.0 if on else (32.0 if ult else 28.0)) * clampf(0.4 + 0.6 * back, 0.0, 1.2)
			var dimmed: bool = (w.picked != "" and not on) or not ok
			var ring: Color = CmdWheel.HOT if on else (w.col.lightened(0.35) if ult else CmdWheel.CREAM)
			if on:
				draw_circle(p, rad + 20.0, Color(w.col, 0.22))
				draw_circle(p, rad + 10.0, Color(w.col, 0.36))
			elif ult and ok:
				draw_circle(p, rad + 9.0, Color(w.col, 0.4))
			draw_circle(p + Vector2(3, 4), rad, Color(0, 0, 0, 0.55))
			draw_circle(p, rad, CmdWheel.CREAM if on else Color("#0a0b14"))
			draw_arc(p, rad, 0.0, TAU, 44, Color(ring, 0.5) if dimmed else ring, 4.0, true)
			CmdWheel.glyph(self, kind, p, rad * 0.62, Color("#0a0b14") if on else Color(ring, 0.55 if dimmed else 1.0))
			# numero del tasto (tastiera 1-4)
			var kp: Vector2 = p + Vector2(rad * 0.72, -rad * 0.72)
			draw_circle(kp, 10.0, w.col)
			draw_arc(kp, 10.0, 0.0, TAU, 20, Color("#0a0b14"), 2.0, true)
			draw_string(fb, kp + Vector2(-4.5, 5.5), str(k + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, CmdWheel.CREAM)
			# etichetta: nome inclinato + striscia crema col sottotitolo (a sinistra per GUARDIA, che sta dietro le spalle)
			var fa: float = clampf(pe * 1.6, 0.0, 1.0)
			var nm: String = str(it["name"])
			var sz: int = 34 if on else 28
			var tw: float = fd.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
			var left: bool = p_rest.x < -10.0
			var rr: float = 36.0 if on else 30.0
			var x0: float = p_rest.x - rr - 12.0 - tw if left else p_rest.x + rr + 12.0
			var y0: float = p_rest.y + 6.0
			var sub: String = str(it["sub"])
			var sw: float = fb.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 22.0
			var sx: float = x0 + (tw - sw if left else 0.0)
			draw_colored_polygon(CmdWheel.slant(Rect2(sx, y0 + 6.0, sw, 25.0), 6.0), Color(CmdWheel.CREAM, 0.95 * fa * (0.7 if dimmed else 1.0)))
			draw_string(fb, Vector2(sx + 11.0, y0 + 25.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(CmdWheel.INK, fa))
			CmdWheel.skew_text(self, Vector2(x0, y0), nm, sz, Color(CmdWheel.HOT, fa) if on else Color(CmdWheel.CREAM, (0.55 if dimmed else 1.0) * fa), Color(0.03, 0.02, 0.06, 0.95 * fa), fd, 9)
			var cost: String = str(it["cost"])
			var cw: float = 0.0
			if cost != "":
				cw = fb.get_string_size(cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 18.0
				var cx: float = sx + sw + 6.0 if not left else sx - cw - 6.0
				var cr := Rect2(cx, y0 + 6.0, cw, 25.0)
				draw_colored_polygon(CmdWheel.slant(cr, 5.0), Color(0.04, 0.05, 0.1, 0.92 * fa))
				draw_string(fb, Vector2(cx + 9.0, y0 + 25.0), cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(w.col.lightened(0.55) if ult else Color("#7fdcec"), fa))
			var lab := Rect2(minf(x0, sx) - (cw + 6.0 if left else 0.0), y0 - 34.0, maxf(tw, sw) + cw + 12.0, 70.0)
			w.hits[kind] = Rect2(p_rest - Vector2(46, 46), Vector2(92, 92)).merge(lab)
		# chi e' di turno: nome nel suo colore sotto i piedi del cerchio (si legge anche senza distinguere i colori)
		var nw: float = fd.get_string_size(w.who, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		CmdWheel.skew_text(self, Vector2(-nw * 0.5, w.ry + 70.0), w.who, 30, w.col.lightened(0.35), Color(0.03, 0.02, 0.06, 0.95), fd, 9)
		if w.picked == "":
			return
		# riquadro della scelta: nome della mossa e cosa fa, sopra la ruota (scivola dentro con la scelta)
		var e: float = smoothstep(0.0, 1.0, w.sel)
		var it2: Dictionary = w.item(w.picked)
		var title: String = str(it2.get("title", ""))
		var desc: String = str(it2.get("desc", ""))
		# in alto a destra, sotto i tasti di sistema: il centro e il nemico restano liberi
		var right: float = w.size.x - origin.x - 24.0
		var ttw: float = fd.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 36).x
		var bx: float = right - ttw - 70.0 + (1.0 - e) * 120.0
		var by: float = 196.0 - origin.y
		draw_colored_polygon(CmdWheel.slant(Rect2(bx - 20.0, by - 40.0, ttw + 90.0, 52.0), 14.0), Color(0.03, 0.02, 0.06, 0.92 * e))
		draw_colored_polygon(CmdWheel.slant(Rect2(bx - 26.0, by + 14.0, ttw + 96.0, 5.0), 3.0), Color(w.col.lightened(0.2), e))
		CmdWheel.glyph(self, w.picked, Vector2(bx + 6.0, by - 14.0), 16.0, Color(w.col.lightened(0.4), e))
		CmdWheel.skew_text(self, Vector2(bx + 34.0, by), title, 36, Color(CmdWheel.CREAM, e), Color(0, 0, 0, 0), fd, 0)
		var ly: float = by + 48.0
		for line in desc.split("\n"):
			var lw: float = fb.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x
			CmdWheel.skew_text(self, Vector2(right - lw - 10.0 + (1.0 - e) * 120.0, ly), line, 21, Color(CmdWheel.CREAM, e), Color(0.03, 0.02, 0.06, 0.95 * e), fb, 7, -0.12)
			ly += 28.0
		# CONFERMA (giallo) e ANNULLA: sotto il comando scelto, verso il nemico
		# a destra sotto il riquadro della scelta, sopra la squadra: sempre allo stesso posto, facile da trovare col pollice
		var cp: Vector2 = Vector2(w.size.x - origin.x - 250.0, 340.0 - origin.y)
		var crr := Rect2(cp + Vector2((1.0 - e) * 90.0, 0.0), Vector2(200.0, 52.0))
		draw_colored_polygon(CmdWheel.slant(crr.grow(4.0), 12.0), Color(0.03, 0.02, 0.06, 0.9 * e))
		draw_colored_polygon(CmdWheel.slant(crr, 10.0), Color(CmdWheel.HOT, e))
		var cwid: float = fd.get_string_size("CONFERMA", HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		CmdWheel.skew_text(self, crr.position + Vector2((crr.size.x - cwid) * 0.5, 38.0), "CONFERMA", 28, Color(CmdWheel.INK, e), Color(0, 0, 0, 0), fd, 0)
		var arr := Rect2(crr.position + Vector2(10.0, 58.0), Vector2(180.0, 36.0))
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
