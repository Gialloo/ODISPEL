class_name Onomato
extends Control

# ONOMATOPEE A FUMETTO (riferimento: il «TAP» con contorno glitch e le saette disegnate a mano delle foto Ghost Stride).
# Una parola breve, inclinata, vicino al bersaglio: scatta (pop), trema un attimo con il contorno ciano/magenta sfasato e svanisce in ~0,5 s.
# Parole INTERNAZIONALI da fumetto (TAP, BAM, ZAP, CLANG, KRAK, SWISH, PLING, THUD): sono quelle delle foto e si leggono a colpo d'occhio
# sul telefono anche senza leggere (regola L7: scelte perche' sono corte, universali e non spiegano nulla, regole 11 e U2).
# Massimo MAX a schermo; se ce ne sono gia' tante la nuova non parte (mai una selva di parole sopra l'interfaccia).
# Costo: un Control con _draw (testo x3, 1 poligono, 2 polilinee), vive mezzo secondo. Con light_fx: niente saette e niente tremolio.

const MAX: int = 3
const SIZES: Array = [60, 88]
const WORDS: String = "TAP BAM ZAP CLANG KRAK SWISH PLING THUD"
const CY: Color = Color("#2ef2ff")
const MG: Color = Color("#ff2bd6")
const INK: Color = Color(0.03, 0.02, 0.07)
const LIFE: float = 0.55

var word: String = "TAP"
var col: Color = Color.WHITE
var fsize: int = 56
var ang: float = -0.15
var jit: Vector2 = Vector2.ZERO
var bolts: Array = []
var burst: PackedVector2Array = PackedVector2Array()
var _t: float = 0.0
var _next_jit: float = 0.0
var _font: Font


# Fa comparire una parola in `at` (coordinate dello strato). big = colpo grosso (critico, rottura).
static func pop(layer: Control, at: Vector2, w: String, c: Color, big: bool = false, delay: float = 0.0) -> void:
	if layer == null or not layer.is_inside_tree():
		return
	var alive: int = 0
	for ch in layer.get_children():
		if ch is Onomato:
			alive += 1
	if alive >= MAX:
		return
	var o := Onomato.new()
	o.word = w
	o.col = c
	o.fsize = int(SIZES[1] if big else SIZES[0])
	o.visible = delay <= 0.0
	o._start(at, delay)
	layer.add_child(o)
	if delay > 0.0:
		var tw := o.create_tween()
		tw.tween_interval(delay)
		tw.tween_callback(func() -> void: o.visible = true)


# Prepara i glifi (i due gradini di grandezza col contorno) dentro una vista invisibile: niente scatto al primo colpo
static func warm(layer: Control) -> void:
	var box := Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.modulate.a = 0.01
	layer.add_child(box)
	for s in SIZES:
		var l := Ui.label(WORDS, int(s), Color.WHITE, Ui.display(), 12)
		box.add_child(l)
	var tw := box.create_tween()
	tw.tween_interval(0.1)
	tw.tween_callback(box.queue_free)


func _start(at: Vector2, _delay: float) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = Ui.display()
	var rs: float = float(randi() % 1000) / 1000.0
	ang = deg_to_rad(lerpf(7.0, 14.0, rs)) * (1.0 if randi() % 2 == 0 else -1.0)
	var sz: Vector2 = _font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	size = sz + Vector2(110, 90)
	pivot_offset = size * 0.5
	position = at - size * 0.5
	rotation = ang
	z_index = 20
	# sagoma d'impatto: stella a punte irregolari dietro la parola (scura: la parola si legge su qualsiasi sfondo)
	var n: int = 14
	var rx: float = size.x * 0.5 - 6.0
	var ry: float = size.y * 0.5 - 4.0
	for i in n * 2:
		var a: float = TAU * float(i) / float(n * 2)
		var k: float = (1.0 if i % 2 == 0 else 0.72) * (0.9 + 0.1 * float((i * 7) % 5) / 4.0)
		burst.append(size * 0.5 + Vector2(cos(a) * rx * k, sin(a) * ry * k))
	if not Settings.light_fx:
		# due saette disegnate a mano (zig-zag) che escono dai lati
		for sgn in [-1.0, 1.0]:
			var p: Vector2 = size * 0.5 + Vector2(sgn * (sz.x * 0.5 + 18.0), randf_range(-10.0, 18.0))
			var pts: Array = [p]
			for k in 4:
				p += Vector2(sgn * randf_range(14.0, 24.0), (1.0 if k % 2 == 0 else -1.0) * randf_range(10.0, 22.0))
				pts.append(p)
			bolts.append(pts)
	scale = Vector2(1.6, 1.6)
	modulate.a = 0.0


func _ready() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.03)
	tw.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(LIFE - 0.25)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.parallel().tween_property(self, "position:y", -22.0, 0.15).as_relative()
	tw.tween_callback(queue_free)
	set_process(not Settings.light_fx)


func _process(d: float) -> void:
	_t += d
	if _t >= _next_jit and _t < 0.3:
		_next_jit = _t + 0.05
		jit = Vector2(randf_range(-3.0, 3.0), randf_range(-2.0, 2.0))
		queue_redraw()


func _draw() -> void:
	if _font == null:
		return
	var fs: Vector2 = _font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var base: Vector2 = Vector2((size.x - fs.x) * 0.5, (size.y + fs.y) * 0.5 - _font.get_descent(fsize) * 0.9)
	# sagoma scura con bordo colorato
	draw_colored_polygon(burst, Color(INK.r, INK.g, INK.b, 0.78))
	var edge := PackedVector2Array(burst)
	edge.append(burst[0])
	draw_polyline(edge, Color(col.r, col.g, col.b, 0.9), 3.0, true)
	# saette: tratto bianco con bordo ciano e magenta sfasati
	for pts in bolts:
		var pa := PackedVector2Array()
		for q in pts:
			pa.append(q)
		draw_polyline(_shift(pa, Vector2(3, 2)), MG, 8.0, true)
		draw_polyline(_shift(pa, Vector2(-3, -2)), CY, 8.0, true)
		draw_polyline(pa, Color(0.96, 0.98, 1.0), 4.0, true)
	# contorno glitch: copie sfasate ciano e magenta, poi contorno scuro e parola piena
	draw_string(_font, base + Vector2(-5, -3) + jit, word, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, CY)
	draw_string(_font, base + Vector2(5, 3) - jit, word, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, MG)
	draw_string_outline(_font, base, word, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, 12, INK)
	draw_string(_font, base, word, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(0.97, 0.99, 1.0).lerp(col, 0.28))


func _shift(pa: PackedVector2Array, v: Vector2) -> PackedVector2Array:
	var r := PackedVector2Array()
	for q in pa:
		r.append(q + v)
	return r
