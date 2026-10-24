class_name Onomato
extends Control

# ONOMATOPEE A MANO (riferimenti 05 «TAP» e 13 «saette» di stile_ghost_stride/): piccole, senza balloon ne' stella piena.
# Lettere sottili, un po' storte (ognuna con la sua inclinazione, altezza e rotazione), bianco/azzurro chiaro, contorno glitch ciano/magenta
# sfasato; al massimo rosso per i colpi forti. Una saetta bianca a mano col bordo ciano/magenta, solo sui colpi grossi.
# Misure in frazione dell'altezza dello schermo (cosi' valgono su ogni telefono): lettere ~4-6% (cap-height), colpo grosso ~8-9%.
# Font: Roboto Bold (gia' nel progetto, tratto sottile e pulito) + inclinazione e lettere sfalsate per l'effetto a mano: un font
# pesante come Archivo Black dava il «fumetto pieno» che copriva lo schermo (regola L7; regole 11 e U2).
# Parole internazionali (TAP, BAM, ZAP, CLANG, KRAK, SWISH, PLING, THUD). Massimo MAX a schermo. Con light_fx: niente saetta e niente tremolio.

const MAX: int = 3
const WORDS: String = "TAP BAM ZAP CLANG KRAK SWISH PLING THUD"
const CY: Color = Color("#2ef2ff")
const MG: Color = Color("#ff2bd6")
const RED: Color = Color("#ff2340")
const INK: Color = Color(0.02, 0.03, 0.06)
const EM_NORMAL: float = 0.06     # corpo del font / altezza schermo (cap-height Roboto ~0,71 em -> ~4,3%)
const EM_BIG: float = 0.10        # critico, rottura: cap-height ~7,1% (max 10%)
const LIFE: float = 0.55

var word: String = "TAP"
var fill: Color = Color(0.9, 0.97, 1.0)
var fsize: int = 56
var big: bool = false
var jit: Vector2 = Vector2.ZERO
var bolt: PackedVector2Array = PackedVector2Array()
var _letters: Array = []           # per lettera: [x, y, rot, skew, scale]
var _t: float = 0.0
var _next_jit: float = 0.0
var _font: Font


static func em_px(layer: Control, is_big: bool) -> int:
	var h: float = layer.get_viewport_rect().size.y
	return int(roundf(h * (EM_BIG if is_big else EM_NORMAL)))


# Fa comparire una parola in `at` (coordinate dello strato). big = colpo grosso (critico, rottura).
static func pop(layer: Control, at: Vector2, w: String, c: Color, is_big: bool = false, delay: float = 0.0) -> void:
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
	o.big = is_big
	# solo bianco/azzurro dalle foto; rosso per i colpi forti (KRAK, colpi rossi)
	o.fill = Color(0.9, 0.97, 1.0).lerp(CY, 0.18)
	if c.r > 0.9 and c.g < 0.45:
		o.fill = Color(1.0, 0.82, 0.84).lerp(RED, 0.35)
	o.fsize = em_px(layer, is_big)
	o.visible = delay <= 0.0
	o._start(at)
	layer.add_child(o)
	if delay > 0.0:
		var tw := o.create_tween()
		tw.tween_interval(delay)
		tw.tween_callback(func() -> void: o.visible = true)


# Prepara i glifi dentro una vista invisibile: niente scatto al primo colpo
static func warm(layer: Control) -> void:
	var box := Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.modulate.a = 0.01
	layer.add_child(box)
	for b in [false, true]:
		box.add_child(Ui.label(WORDS, em_px(layer, b), Color.WHITE, Ui.body(), 2))
	var tw := box.create_tween()
	tw.tween_interval(0.1)
	tw.tween_callback(box.queue_free)


func _start(at: Vector2) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = Ui.body()
	var sz: Vector2 = _font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var pad: float = float(fsize) * 0.9
	size = sz + Vector2(pad * 2.0, pad * 1.4)
	pivot_offset = size * 0.5
	position = at - size * 0.5
	rotation = deg_to_rad(randf_range(-9.0, 9.0))
	z_index = 20
	# lettere «a mano»: ognuna un po' storta, piu' alta o piu' bassa, con inclinazione costante (corsivo a pennarello)
	var x: float = 0.0
	for i in word.length():
		var ch: String = word.substr(i, 1)
		var adv: float = _font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
		var sc: float = randf_range(0.9, 1.12)
		_letters.append([x, randf_range(-0.09, 0.09) * float(fsize), deg_to_rad(randf_range(-11.0, 11.0)), -0.28 + randf_range(-0.08, 0.08), sc])
		x += adv * 0.97
	# saetta a mano sul colpo grosso: 4 segmenti, zig-zag corto, esce da un lato della parola
	if big and not Settings.light_fx:
		var sgn: float = 1.0 if randi() % 2 == 0 else -1.0
		var u: float = float(fsize) * 0.28
		var p: Vector2 = size * 0.5 + Vector2(sgn * (sz.x * 0.5 + u * 0.4), -u * 0.2)
		bolt.append(p)
		for k in 4:
			p += Vector2(sgn * randf_range(0.7, 1.1) * u, (1.0 if k % 2 == 0 else -1.0) * randf_range(0.5, 0.9) * u)
			bolt.append(p)
	scale = Vector2(1.35, 1.35)
	modulate.a = 0.0


func _ready() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.03)
	tw.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(LIFE - 0.25)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.parallel().tween_property(self, "position:y", -float(fsize) * 0.4, 0.15).as_relative()
	tw.tween_callback(queue_free)
	set_process(not Settings.light_fx)


func _process(d: float) -> void:
	_t += d
	if _t >= _next_jit and _t < 0.3:
		_next_jit = _t + 0.05
		var j: float = float(fsize) * 0.03
		jit = Vector2(randf_range(-j, j), randf_range(-j, j) * 0.6)
		queue_redraw()


func _draw() -> void:
	if _font == null:
		return
	var sz: Vector2 = _font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var org: Vector2 = Vector2((size.x - sz.x) * 0.5, (size.y + float(fsize) * 0.71) * 0.5)
	var off: float = maxf(2.0, float(fsize) * 0.045)        # sfasamento del contorno glitch: sottile
	var th: float = maxf(1.5, float(fsize) * 0.03)
	# saetta: bianca, bordo ciano e magenta sfasati (foto 13)
	if bolt.size() > 1:
		draw_polyline(_shift(bolt, Vector2(off, off * 0.6)), Color(MG.r, MG.g, MG.b, 0.9), th * 2.4, true)
		draw_polyline(_shift(bolt, Vector2(-off, -off * 0.6)), Color(CY.r, CY.g, CY.b, 0.9), th * 2.4, true)
		draw_polyline(bolt, Color(0.97, 0.99, 1.0), th * 1.2, true)
	# lettere: copia ciano, copia magenta (sfasate), filo scuro sottile e riempimento chiaro
	for i in _letters.size():
		var L: Array = _letters[i]
		var ch: String = word.substr(i, 1)
		var base: Vector2 = org + Vector2(float(L[0]), float(L[1]))
		var sc: float = float(L[4])
		draw_set_transform_matrix(Transform2D(float(L[2]), Vector2(sc, sc), float(L[3]), base))
		draw_string(_font, Vector2(-off, -off * 0.6) + jit, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(CY.r, CY.g, CY.b, 0.95))
		draw_string(_font, Vector2(off, off * 0.6) - jit, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(MG.r, MG.g, MG.b, 0.95))
		draw_string_outline(_font, Vector2.ZERO, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, 3, INK)
		draw_string(_font, Vector2.ZERO, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, fill)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _shift(pa: PackedVector2Array, v: Vector2) -> PackedVector2Array:
	var r := PackedVector2Array()
	for q in pa:
		r.append(q + v)
	return r
