class_name ThreatPlate
extends Control

# PROSSIMA MOSSA DEL NEMICO su una lastra (HUD 0.61, P0-B, mockup approvato dall'autore il 7/11/2026).
# Prende il posto della riga di testo sotto l'EQUILIBRIO (la riga resta, nascosta, per chi la legge da codice).
# - un'icona per il tipo di colpo: singolo (mirino), su tutti (tre teste), catena (due anelli);
# - il nome della mossa grande, sopra "PROSSIMA MOSSA · SU <chi>" (e "· POI <mossa>" se c'e' una catena);
# - colpo FORTE: lastra rossa piena, bordo giallo, strisce di pericolo a sinistra e il bollino FORTE;
# - effetto di stato della mossa (MARCHIO, SANGUINA): un bollino chiaro con l'occhio;
# - nemico stordito: lastra scura col bordo giallo, "STORDITO · salterà il prossimo turno".
# Tutto dai dati veri del motore (telegraph, BOSS_MOVES, threat_preview): niente previsioni inventate.
# Le icone sono disegnate qui in attesa di quelle dell'autore (P1-C). Un solo _draw, rifatto solo quando cambiano i dati.

const INK: Color = Color("#120a1c")
const CREAM: Color = Color("#fff4dc")
const HOT: Color = Color("#ffd23f")
const RED: Color = Color("#ff3b4e")
const DEEP: Color = Color("#d0122f")
const PH: float = 54.0

var data: Dictionary = {}          # {state: normale|forte|stordito, name, who, kind: singolo|tutti|catena, status, chain}
var _sig: String = ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, PH + 6)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func set_threat(d: Dictionary) -> void:
	var sig: String = str(d)
	if sig == _sig:
		return
	_sig = sig
	data = d
	visible = not d.is_empty()
	queue_redraw()


static func slant(x: float, y: float, w: float, h: float, sk: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x + sk, y), Vector2(x + w, y), Vector2(x + w - sk, y + h), Vector2(x, y + h)])


# Icone del tipo di colpo (segnaposto finche' l'autore non disegna le sue, P1-C). ci = chi disegna, dentro il suo _draw.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, col: Color, r: float = 15.0) -> void:
	match kind:
		"singolo":
			ci.draw_arc(c, r, 0, TAU, 28, col, 3.0, true)
			ci.draw_circle(c, 3.2, col)
			for a in 4:
				var v := Vector2.from_angle(a * PI / 2.0)
				ci.draw_line(c + v * (r - 6), c + v * (r + 4), col, 3.0)
		"tutti":
			for i in [-1, 0, 1]:
				ci.draw_arc(c + Vector2(i * 10, 4), 4.5, 0, TAU, 14, col, 2.5, true)
			ci.draw_arc(c + Vector2(0, 8), r + 2, deg_to_rad(200), deg_to_rad(340), 18, col, 3.0, true)
		"catena":
			ci.draw_arc(c + Vector2(-5, 0), 8, 0, TAU, 18, col, 3.0, true)
			ci.draw_arc(c + Vector2(6, 0), 8, 0, TAU, 18, col, 3.0, true)
			ci.draw_line(c + Vector2(13, -11), c + Vector2(19, -15), col, 3.0)
		"stato":
			var pts := PackedVector2Array()
			for i in 25:
				pts.append(c + Vector2(-r + 2.0 * r * i / 24.0, -sin(i / 24.0 * PI) * r * 0.55))
			for i in 25:
				pts.append(c + Vector2(r - 2.0 * r * i / 24.0, sin(i / 24.0 * PI) * r * 0.55))
			pts.append(pts[0])
			ci.draw_polyline(pts, col, 2.0, true)
			ci.draw_circle(c, r * 0.3, col)
		"stordito":
			for i in 3:
				var p := c + Vector2.from_angle(-PI / 2.0 + i * TAU / 3.0) * r * 0.55
				ci.draw_line(p + Vector2(-4, 0), p + Vector2(4, 0), col, 2.5)
				ci.draw_line(p + Vector2(0, -4), p + Vector2(0, 4), col, 2.5)


func _txt(f: Font, p: Vector2, s: String, fs: int, col: Color, outline: int) -> float:
	if outline > 0:
		draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, INK)
	draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


func _draw() -> void:
	if data.is_empty():
		return
	var fd: Font = Ui.display()
	var fb: Font = Ui.body()
	var st: String = str(data.get("state", "normale"))
	var strong: bool = st == "forte"
	var stun: bool = st == "stordito"
	var x: float = 10.0
	var y: float = 3.0
	var w: float = size.x - 14.0
	var plate: PackedVector2Array = slant(x, y, w, PH, 10.0)
	if strong:
		for r in [8.0, 4.0]:
			draw_colored_polygon(slant(x - r, y - r * 0.6, w + r * 2, PH + r * 1.2, 10.0), Color(1.0, 0.12, 0.2, 0.28))
	var sh := PackedVector2Array()
	for q in plate:
		sh.append(q + Vector2(5, 5))
	draw_colored_polygon(sh, Color(INK, 0.94))
	draw_colored_polygon(plate, Color(DEEP, 0.96) if strong else Color(0.05, 0.03, 0.08, 0.93))
	var edge: Color = HOT if (strong or stun) else RED
	draw_polyline(plate + PackedVector2Array([plate[0]]), edge, 2.5, true)
	# riquadro dell'icona
	draw_colored_polygon(slant(x + 6, y + 6, 42, 42, 6), edge)
	draw_icon(self, "stordito" if stun else str(data.get("kind", "singolo")), Vector2(x + 30, y + 27), INK)
	var tx: float = x + 60.0
	if stun:
		_txt(fb, Vector2(tx, y + 20), "IL NEMICO SALTA IL TURNO", HudLayers.MIN_TEXT, Color(CREAM, 0.88), 4)
		_txt(fd, Vector2(tx, y + 46), "STORDITO", 24, HOT, 5)
		return
	var lab: String = "PROSSIMA MOSSA · SU " + str(data.get("who", "TUTTI"))
	if str(data.get("chain", "")) != "":
		lab += " · POI " + str(data["chain"])
	_txt(fb, Vector2(tx, y + 20), lab, HudLayers.MIN_TEXT, Color(CREAM, 0.88), 4)
	var nx: float = tx + _txt(fd, Vector2(tx, y + 46), str(data.get("name", "?")).to_upper(), 24, CREAM, 6) + 10.0
	if strong:
		var fw: float = fd.get_string_size("FORTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		draw_colored_polygon(slant(nx, y + 27, fw + 14, 22, 5), HOT)
		_txt(fd, Vector2(nx + 8, y + 44), "FORTE", 17, INK, 0)
		nx += fw + 22.0
	var stat: String = str(data.get("status", ""))
	if stat != "":
		var sw: float = fb.get_string_size(stat, HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT).x + 34.0
		draw_colored_polygon(slant(nx, y + 27, sw, 22, 5), Color(CREAM, 0.94))
		draw_icon(self, "stato", Vector2(nx + 14, y + 38), INK, 8.0)
		_txt(fb, Vector2(nx + 26, y + 44), stat, HudLayers.MIN_TEXT, INK, 0)
	if strong:
		# strisce di pericolo sul bordo sinistro
		for j in 5:
			var yy: float = y + 4 + j * 10
			draw_line(Vector2(x - 10 + (PH - (yy - y)) * 10.0 / PH, yy), Vector2(x - 4 + (PH - (yy - y - 6)) * 10.0 / PH, yy + 6), HOT, 3.0)
