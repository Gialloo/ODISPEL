class_name BossPlate
extends Control

# CARTELLINO DEL NEMICO come nella foto di riferimento dell'autore (7/11/2026, Settings.hud_foto): lastra nera storta col
# filo rosso, nome grande, LIVELLO, DEBOLE A in un bollino del colore; sotto HP (barra rossa coi numeri) e BREAK a tacche
# gialle e arancio. Legge solo i valori che battle3d gia' mette nelle barre di prima (che restano, nascoste).

const INK: Color = Color("#120a1c")
const CREAM: Color = Color("#fff4dc")
const RED: Color = Color("#ff2340")
const W: float = 500.0
const H: float = 106.0
const SEG: int = 10

var data: Dictionary = {}      # name, level, weak, weak_col, hp, max_hp, ghost, brk, brk_max, low
var _sig: String = ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(W, H)


func set_data(d: Dictionary) -> void:
	var s: String = str(d)
	if s == _sig:
		return
	_sig = s
	data = d
	queue_redraw()


func _slant(x: float, y: float, w: float, h: float, sk: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x + sk, y), Vector2(x + w + sk, y), Vector2(x + w, y + h), Vector2(x, y + h)])


func _txt(f: Font, p: Vector2, s: String, sz: int, col: Color, ow: int = 6) -> float:
	if ow > 0:
		draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, ow, INK)
	draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x


func _draw() -> void:
	if data.is_empty():
		return
	var fd: Font = Ui.display()
	# lastra: ombra, nero, filo rosso a sinistra e sotto (i tagli rossi del riferimento)
	var slab := _slant(6, 4, W - 24, H - 8, 14)
	var sh := PackedVector2Array()
	for q in slab:
		sh.append(q + Vector2(6, 6))
	draw_colored_polygon(sh, Color(INK, 0.9))
	draw_colored_polygon(slab, Color(0.03, 0.01, 0.04, 0.9))
	draw_colored_polygon(_slant(0, 2, 12, 46, 8), RED)
	draw_line(slab[3] + Vector2(10, 0), slab[2] + Vector2(-60, 0), RED, 3.0)
	# riga 1: nome, LIVELLO, debolezza
	var x: float = 26.0
	var nm: String = str(data.get("name", "?")).to_upper()
	var nsz: int = 30
	while nsz > 20 and fd.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, nsz).x > W * 0.42:
		nsz -= 2
	var nw: float = _txt(fd, Vector2(x, 38), nm, nsz, CREAM, 7)
	x += nw + 18.0
	if int(data.get("level", 0)) > 0:
		x += _txt(Ui.body(), Vector2(x, 36), "LIVELLO %d" % int(data["level"]), HudLayers.MIN_TEXT, CREAM, 0) + 14.0
	var wk: String = str(data.get("weak", ""))
	if wk != "":
		var wc: Color = data.get("weak_col", Color("#9a94a8"))
		var ww: float = Ui.body().get_string_size(wk, HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT).x + 22.0
		var wx: float = minf(x, W - ww - 20.0)
		draw_colored_polygon(_slant(wx, 14, ww, 28, 7), wc)
		_txt(Ui.body(), Vector2(wx + 11, 34), wk, HudLayers.MIN_TEXT, INK if wc.get_luminance() > 0.45 else CREAM, 0)
	# riga 2: HP
	var bx: float = 104.0
	var bw: float = W - bx - 40.0
	_txt(fd, Vector2(34, 70), "HP", 20, CREAM, 5)
	var mhp: float = maxf(1.0, float(data.get("max_hp", 1)))
	var k: float = clampf(float(data.get("hp", 0)) / mhp, 0.0, 1.0)
	var kg: float = clampf(float(data.get("ghost", 0)) / mhp, k, 1.0)
	draw_colored_polygon(_slant(bx, 54, bw, 18, 5), Color(0.12, 0.04, 0.07))
	if kg > k:
		draw_colored_polygon(_slant(bx, 54, bw * kg, 18, 5), Color(CREAM, 0.8))
	if k > 0.0:
		draw_colored_polygon(_slant(bx, 54, bw * k, 18, 5), RED)
	var hs: String = "%d / %d" % [int(data.get("hp", 0)), int(mhp)]
	var hw: float = fd.get_string_size(hs, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
	_txt(fd, Vector2(bx + bw - hw - 6, 70), hs, 19, CREAM, 5)
	# riga 3: BREAK a tacche (gialle all'inizio, arancio verso la fine); lampeggia quando sta per rompersi
	_txt(fd, Vector2(20, 96), "BREAK", 18, CREAM, 5)
	var bmax: float = maxf(1.0, float(data.get("brk_max", 1)))
	var full: float = clampf(float(data.get("brk", 0)) / bmax, 0.0, 1.0) * SEG
	var sw: float = (bw - 3.0 * (SEG - 1)) / SEG
	var low: bool = bool(data.get("low", false))
	for i in SEG:
		var sx: float = bx - 4.0 + i * (sw + 3.0)
		var lit: bool = float(i) < full
		var c: Color = Color("#ffd23f").lerp(Color("#ff7a1a"), float(i) / float(SEG - 1)) if lit else Color(0.16, 0.12, 0.18)
		if lit and low:
			c = c.lerp(CREAM, 0.35)
		draw_colored_polygon(_slant(sx, 82, sw, 14, 4), c)
