class_name RitrattoLampo
extends Control

# LAMPO DEL RITRATTO: per un attimo il disegno 2D di un personaggio appare sul lato dello schermo, come un fotogramma
# rubato dalla diretta di Echo (varianti di Rio dell'autore, 3/11/2026). Due modi:
#   "break"  il suo colpo rompe la guardia: fotogramma disturbato, strisce spostate e canali rosso/blu separati (VHS);
#   "ko"     SEGNALE PERSO: la sagoma blu sfarfalla e si spegne come un vecchio televisore (si stringe in una riga).
# PRESTAZIONI: un _draw solo con 3-7 draw_texture_rect_region, vive ~1 s e si libera da solo. Il tempo e' quello vero
# (Time), cosi' il fermo immagine del BREAK e la pausa non lo bloccano a meta'.
#   var l := RitrattoLampo.new(); parent.add_child(l); l.start(tex, "break", Color("#ff2340"))

const INK: Color = Color("#120a1c")
const DURATA: Dictionary = {"break": 0.95, "ko": 1.25, "ult": 1.4}
static var lento: float = 1.0        # solo per le prove (tools/v3_varianti_rio.gd): sotto xvfb i fotogrammi sono lenti
static var tempo_fisso: bool = false # solo per le clip (--fixed-fps): conta i fotogrammi invece dell'orologio vero
var _el: float = 0.0

var tex: Texture2D
var mode: String = "break"
var col: Color = Color.WHITE
var _t0: int = 0
var _seed: int = 0
var _dur: float = 0.0          # durata data da chi lo lancia (cut-in dell'ULTIMATE: quanto dura la scena); 0 = DURATA
var _seed_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func start(p_tex: Texture2D, p_mode: String, p_col: Color = Color.WHITE, p_dur: float = 0.0) -> void:
	_seed_rng.randomize()
	_dur = p_dur
	tex = p_tex
	mode = p_mode
	col = p_col
	_t0 = Time.get_ticks_msec()
	_seed = _seed_rng.randi()
	queue_redraw()


func _k() -> float:
	var sec: float = _el if tempo_fisso else float(Time.get_ticks_msec() - _t0) / 1000.0
	return sec / ((_dur if _dur > 0.0 else float(DURATA.get(mode, 1.0))) * lento)


func _process(_d: float) -> void:
	if tex == null:
		return
	_el += 1.0 / 30.0 if tempo_fisso else 0.0
	if _k() >= 1.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if tex == null:
		return
	var k: float = clampf(_k(), 0.0, 1.0)
	var W: float = size.x
	var H: float = size.y
	if mode == "ult":
		_draw_ult(k, W, H)
		return
	# il ritratto sta a destra, alto quasi come lo schermo, tagliato dal bordo in basso (lontano dal ritratto dell'HUD a sinistra)
	var h: float = H * 0.92
	var w: float = h * 0.75
	var ts: Vector2 = tex.get_size()
	var inn: float = clampf(k / 0.12, 0.0, 1.0)            # entra con uno scatto
	var out: float = clampf((k - 0.78) / 0.22, 0.0, 1.0)   # esce
	var x: float = W - w * 0.92 + (1.0 - inn) * w * 0.5
	var y: float = H - h + 10.0
	var a: float = (1.0 - out) * inn
	# lastra storta del colore del momento dietro al disegno (alla Persona): il disegno e' quasi tutto nero e sulla
	# notte della citta' non si staccherebbe
	var sl := PackedVector2Array([Vector2(x - 40.0, y + h * 0.18), Vector2(W + 10.0, y + h * 0.02), Vector2(W + 10.0, H), Vector2(x + 30.0, H)])
	var sd := PackedVector2Array()
	for q in sl:
		sd.append(q + Vector2(-12, 10))
	draw_colored_polygon(sd, Color(INK, 0.85 * a))
	draw_colored_polygon(sl, Color(col.darkened(0.15), 0.9 * a))
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed + int(k * 24.0)                        # il disturbo cambia ~24 volte al secondo, non a ogni frame
	if mode == "ko":
		# sfarfalla, poi si spegne: la figura si schiaccia in una riga chiara al centro e sparisce
		var squash: float = clampf((k - 0.55) / 0.3, 0.0, 1.0)
		var vis: float = 1.0 if rng.randf() > 0.22 or k > 0.5 else 0.35
		var hh: float = h * (1.0 - squash * 0.985)
		var r := Rect2(Vector2(x, y + (h - hh) * 0.5), Vector2(w, hh))
		draw_texture_rect(tex, Rect2(r.position + Vector2(-12, 9), r.size), false, Color(INK, 0.6 * a * vis))
		draw_texture_rect(tex, r, false, Color(1, 1, 1, a * vis))
		if squash > 0.0:
			var lw: float = w * (1.0 - clampf((k - 0.85) / 0.15, 0.0, 1.0))
			draw_rect(Rect2(Vector2(x + (w - lw) * 0.5, y + h * 0.5 - 2.0), Vector2(lw, 4.0)), Color(col.lightened(0.6), a))
		return
	# BREAK: copie rossa e blu spostate, poi il disegno tagliato in strisce che scivolano di lato
	var sp: float = 10.0 + 18.0 * (1.0 - inn) + 8.0 * out
	draw_texture_rect(tex, Rect2(Vector2(x - sp, y), Vector2(w, h)), false, Color(1.0, 0.1, 0.25, 0.55 * a))
	draw_texture_rect(tex, Rect2(Vector2(x + sp, y + 2.0), Vector2(w, h)), false, Color(0.15, 0.35, 1.0, 0.55 * a))
	var bands: int = 7
	for i in bands:
		var v0: float = float(i) / float(bands)
		var v1: float = float(i + 1) / float(bands)
		var shift: float = 0.0
		if rng.randf() < 0.45:
			shift = rng.randf_range(-36.0, 36.0) * (1.0 - k * 0.5)
		var dst := Rect2(Vector2(x + shift, y + h * v0), Vector2(w, h * (v1 - v0)))
		var src := Rect2(Vector2(0.0, ts.y * v0), Vector2(ts.x, ts.y * (v1 - v0)))
		draw_texture_rect_region(tex, dst, src, Color(1, 1, 1, a))
	# righe di scansione chiare, poche
	for j in 3:
		var ly: float = y + h * rng.randf()
		draw_rect(Rect2(Vector2(x - 20.0, ly), Vector2(w + 40.0, 2.0)), Color(col.lightened(0.5), 0.5 * a))


# CUT-IN DELL'ULTIMATE COL RITRATTO 2D (autore, 3/11/2026, idea 5): sopra la scena alla Edgerunners il disegno grande
# attraversa lo schermo come in Persona: entra di scatto da destra dentro una fascia storta del suo colore, scivola piano
# verso sinistra per tutta la scena (la "spinta" della telecamera) ed esce di scatto. Linee di velocita' dietro.
func _draw_ult(k: float, W: float, H: float) -> void:
	var h: float = H * 1.12
	var w: float = h * 0.75
	var inn: float = 1.0 - pow(1.0 - clampf(k / 0.14, 0.0, 1.0), 3.0)
	var out: float = pow(clampf((k - 0.86) / 0.14, 0.0, 1.0), 2.0)
	var drift: float = (k - 0.14) * 70.0
	var x: float = W * 0.50 + (1.0 - inn) * W * 0.6 - drift - out * W * 0.9
	var y: float = H - h * 0.92
	var a: float = 1.0 - out * 0.6
	# fascia storta: dal basso a sinistra all'alto a destra, con l'ombra d'inchiostro
	var by0: float = H * 0.34          # fascia stretta: la scena alla Edgerunners dietro resta leggibile sopra e sotto
	var by1: float = H * 0.80
	var bx: float = (1.0 - inn) * W * 0.5 + out * -W * 0.6
	var band := PackedVector2Array([Vector2(bx - 40.0, by0 + 70.0), Vector2(bx + W + 40.0, by0 - 40.0), Vector2(bx + W + 40.0, by1 - 90.0), Vector2(bx - 40.0, by1)])
	var bsh := PackedVector2Array()
	for q in band:
		bsh.append(q + Vector2(0, 14))
	draw_colored_polygon(bsh, Color(INK, 0.9 * a))
	draw_colored_polygon(band, Color(col.darkened(0.2), 0.8 * a))
	# linee di velocita' chiare che corrono a sinistra dentro la fascia
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	for i in 9:
		var ly: float = rng.randf_range(by0 + 30.0, by1 - 60.0)
		var ln: float = rng.randf_range(120.0, 320.0)
		var lx: float = fmod(rng.randf() * W - k * W * 2.2 * rng.randf_range(0.7, 1.3), W + ln)
		if lx < -ln:
			lx += W + ln
		draw_rect(Rect2(Vector2(lx, ly), Vector2(ln, 3.0)), Color(col.lightened(0.6), 0.55 * a))
	# il disegno: ombra piatta e poi lui
	draw_texture_rect(tex, Rect2(Vector2(x - 18.0, y + 12.0), Vector2(w, h)), false, Color(INK, 0.6 * a))
	draw_texture_rect(tex, Rect2(Vector2(x, y), Vector2(w, h)), false, Color(1, 1, 1, a))
