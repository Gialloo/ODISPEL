class_name VentaglioHud
extends PortraitHud

# MENU A VENTAGLIO DISEGNATO A MANO (Procreate, autore 7/11/2026). In basso a sinistra il busto di chi e' di turno, rosso
# pieno e nero; dietro di lui si apre un ventaglio di lame: SKILL (nera, in alto), ATTACK (la lastra grande, con sopra la
# lama nera della descrizione breve), ULTIMATE (del colore del personaggio), GUARD (marrone). Le lame sono il disegno
# dell'autore; le scritte e la descrizione le mette il gioco. Stessa interfaccia del ritratto (setup, pick, item, tapped,
# hovered, set_who, bande nere dell'ULTIMATE): Settings.hud_ventaglio = false riporta l'HUD col ritratto (aggiungi, non togliere).
#
# Immagini: res://assets/hud_ventaglio/ (tools/prepara_ventaglio.py le ricava dai fogli 1536x2048 dell'autore).
#   ventaglio_<colore>.png  tela comune del foglio (52,560)-(1509,1711) ridotta a 0,6
#   busto_<id>.png          riquadro del busto (52,612)-(670,1375) ridotto a 0,6
# Busti di Rio, Nox e Saul: SEGNAPOSTO a tre toni dai ritratti ufficiali, finche' l'autore non li disegna a mano.
# PRESTAZIONI: due texture e una manciata di poligoni in un solo _draw; si ridisegna solo durante le animazioni e quando
# un comando e' acceso (un respiro di luce sulla lama scelta).

const DIR: String = "res://assets/hud_ventaglio/"
const COLORE: Dictionary = {"lance": "rosso", "nox": "blu", "rio": "viola", "saul": "verde"}   # colori di battaglia
const ORIGIN: Vector2 = Vector2(52, 560)        # angolo della tela sul foglio 1536x2048
const CANVAS: Vector2 = Vector2(1457, 1151)     # grandezza della tela sul foglio
const BUST_AT: Vector2 = Vector2(52, 612)       # angolo del busto sul foglio
const BUST_SZ: Vector2 = Vector2(618, 763)
const HUD_H: float = 430.0                      # altezza della tela a schermo (unita' 1280x720)
const D: float = 1.024                          # i punti qui sotto sono presi sul disegno visto a 1500x2000: x1,024 = foglio
const HINGE: Vector2 = Vector2(230, 1110)       # perno del ventaglio (nascosto dietro al busto)
# lame (poligoni sul disegno): zona del tocco e luce della scelta
const BLADE: Dictionary = {
	"skill": [Vector2(455, 897), Vector2(952, 557), Vector2(992, 552), Vector2(1040, 580), Vector2(1045, 780), Vector2(560, 1005)],
	"attack": [Vector2(565, 1010), Vector2(1460, 940), Vector2(1472, 1010), Vector2(1228, 1238), Vector2(645, 1195), Vector2(600, 1150)],
	"ult": [Vector2(645, 1198), Vector2(1290, 1365), Vector2(1308, 1382), Vector2(1172, 1576), Vector2(1140, 1572), Vector2(612, 1300)],
	"guard": [Vector2(352, 1325), Vector2(612, 1300), Vector2(905, 1490), Vector2(732, 1665), Vector2(672, 1652)],
}
const DESC_POLY: Array = [Vector2(590, 1000), Vector2(1455, 748), Vector2(1460, 940), Vector2(600, 1005)]
# scritte: [centro sul disegno, rotazione, grandezza (unita'), larghezza massima sul disegno]
const WORD: Dictionary = {
	"skill": [Vector2(752, 812), -0.55, 66, 470.0],
	"attack": [Vector2(925, 1112), -0.02, 80, 620.0],
	"ult": [Vector2(900, 1382), 0.36, 40, 560.0],
	"guard": [Vector2(640, 1455), 0.58, 48, 330.0],
}
const DESC_AT: Vector2 = Vector2(1076, 900)     # centro della descrizione breve
const DESC_ROT: float = -0.2
const DESC_W: float = 560.0
const ULT_AXIS: Array = [Vector2(625, 1250), Vector2(1245, 1470)]     # dalla base alla punta: la carica scurisce il resto
# Le scritte sono quelle del disegno dell'autore (in inglese)
const WORDS: Dictionary = {"skill": "SKILL", "attack": "ATTACK", "ult": "ULTIMATE", "guard": "GUARD"}

var _fan: Texture2D
var _bust: Texture2D
var _polys: Dictionary = {}                    # kind -> poligono a schermo (tocco e mouse)
var _o: Vector2 = Vector2.ZERO                 # angolo della tela a schermo
var _k: float = HUD_H / CANVAS.y               # da pixel del foglio a unita' dello schermo


func set_who(id: String) -> void:
	if id == who_id and _fan != null:
		return
	who_id = id
	var c: String = str(COLORE.get(id, "rosso"))
	_fan = load(DIR + "ventaglio_%s.png" % c) if ResourceLoader.exists(DIR + "ventaglio_%s.png" % c) else null
	var bp: String = DIR + "busto_%s.png" % id
	_bust = load(bp) if ResourceLoader.exists(bp) else null
	_tex_real = false              # niente respiro del ritratto: si ridisegna solo quando qualcosa si muove
	queue_redraw()


func _process(delta: float) -> void:
	super(delta)
	if visible and picked != "":
		queue_redraw()             # respiro di luce sulla lama scelta


# punto del disegno (1500x2000) -> schermo
func _p(v: Vector2) -> Vector2:
	return _o + (v * D - ORIGIN) * _k


func _poly(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in arr:
		out.append(_p(v))
	return out


func _draw() -> void:
	_draw_bands()
	var H: float = size.y
	var e: float = _ease(appear)
	_o = Vector2(18.0, H - HUD_H - 6.0)      # un margine: il cappello di Lance non tocca il bordo
	_polys.clear()
	# 1) ventaglio: si apre dal perno dietro al busto (ruota e cresce), poi resta fermo
	var hinge: Vector2 = _p(HINGE)
	var fr: float = (1.0 - e) * 0.55
	var fs: float = 0.35 + 0.65 * e
	var m := Transform2D(fr, Vector2(fs, fs), 0.0, hinge) * Transform2D(0.0, -hinge)
	draw_set_transform_matrix(m)
	if _fan != null:
		draw_texture_rect(_fan, Rect2(_o, CANVAS * _k), false, Color(1, 1, 1, e))
	var f: Font = Ui._font("BarlowCondensed-Light.ttf")
	for kind in ["guard", "ult", "attack", "skill"]:
		var it: Dictionary = item(kind)
		if it.is_empty():
			continue
		var poly: PackedVector2Array = _poly(BLADE[kind])
		_polys[kind] = poly
		_draw_blade(kind, it, poly, f, e)
	_draw_desc(e)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# 2) busto: entra da sinistra insieme al ventaglio, scatta appena quando scegli
	if _bust != null:
		var e2: float = _ease(clampf((appear - 0.15) / 0.85, 0.0, 1.0))
		var r := Rect2(_o + (BUST_AT - ORIGIN) * _k + Vector2(-(1.0 - e2) * 260.0, 0.0), BUST_SZ * _k)
		var sc: float = 1.0 + 0.03 * _punch * _punch + (0.02 * sel if picked == "ult" else 0.0)
		var piv: Vector2 = r.position + Vector2(r.size.x * 0.5, r.size.y)
		draw_set_transform_matrix(Transform2D(0.0, Vector2(sc, sc), 0.0, piv) * Transform2D(0.0, -piv))
		draw_texture_rect(_bust, r, false, Color(1, 1, 1, e2))
		draw_set_transform_matrix(Transform2D.IDENTITY)
	if who.contains("RAPIDO"):
		CmdWheel.skew_text(self, _o + Vector2(14, 6), "RAPIDO", 20, HOT, INK, Ui.display(), 7, -0.25)


# bande nere dell'ULTIMATE e lampo della scelta (le stesse della ruota, CmdWheel._draw)
func _draw_bands() -> void:
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


func _draw_blade(kind: String, it: Dictionary, poly: PackedVector2Array, f: Font, e: float) -> void:
	var ok: bool = bool(it.get("ok", false))
	var on: bool = picked == kind
	# ULTIMATE in carica: la parte della lama non ancora carica resta scura
	if kind == "ult" and not ok:
		var a: Vector2 = _p(ULT_AXIS[0])
		var b: Vector2 = _p(ULT_AXIS[1])
		var dir: Vector2 = (b - a).normalized()
		var n: Vector2 = dir.orthogonal() * 400.0
		var q: Vector2 = a.lerp(b, clampf(float(it.get("charge", 0.0)), 0.0, 1.0))
		var rest := PackedVector2Array([q + n, q - n, q - n + dir * 600.0, q + n + dir * 600.0])
		for pp in Geometry2D.intersect_polygons(poly, rest):
			draw_colored_polygon(pp, Color(0.02, 0.0, 0.02, 0.62 * e))
	elif not ok:
		draw_colored_polygon(poly, Color(0.02, 0.0, 0.02, 0.55 * e))
	if picked != "" and not on:
		draw_colored_polygon(poly, Color(0.0, 0.0, 0.0, 0.3 * e * smoothstep(0.0, 1.0, sel)))      # le altre si spengono un po'
	if on:
		var pulse: float = 0.5 + 0.5 * sin(t * 6.0)
		draw_colored_polygon(poly, Color(1, 1, 1, (0.08 + 0.07 * pulse) * e))
		var ring := PackedVector2Array(poly)
		ring.append(poly[0])
		draw_polyline(ring, Color(col.lightened(0.55), e), 3.0, true)
	# scritta: bianca e sottile come nel disegno; spenta = grigia; scelta = gialla
	var w: Array = WORD[kind]
	var name: String = str(WORDS.get(kind, it.get("name", kind)))
	var sz: int = int(w[2])
	var maxw: float = float(w[3]) * D * _k
	while sz > 24 and f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > maxw:
		sz -= 2
	var tw: float = f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var fill: Color = (HOT if on else CREAM.lerp(Color.WHITE, 0.6)) if ok else GREY
	if kind == "ult" and not ok:
		fill = Color(CREAM, 0.75)
	var c: Vector2 = _p(w[0])
	var asc: float = f.get_ascent(sz)
	var cur: Transform2D = _cur_m() * Transform2D(float(w[1]), c)
	draw_set_transform_matrix(cur)
	draw_string_outline(f, Vector2(-tw * 0.5, asc * 0.36), name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 4, Color(INK, 0.55 * e))
	draw_string(f, Vector2(-tw * 0.5, asc * 0.36), name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(fill, e))
	var bf: Font = Ui._font("BarlowCondensed-MediumItalic.ttf")
	if kind == "ult" and not ok:
		draw_string(bf, Vector2(tw * 0.5 + 8.0, asc * 0.36), str(it.get("cost", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(HOT, e))
	# PC: il tasto della tastiera accanto alla scritta, piccolo
	if not Ui.is_touch():
		var kc := Vector2(tw * 0.5 + (60.0 if kind == "ult" and not ok else 18.0), -asc * 0.05)
		draw_circle(kc, 11.0, Color(INK, 0.85 * e))
		draw_arc(kc, 11.0, 0.0, TAU, 20, Color(fill, 0.8 * e), 1.5, true)
		var k: String = str(KEYS.get(kind, ""))
		var ks: Vector2 = bf.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
		draw_string(bf, kc + Vector2(-ks.x * 0.5, 6.0), k, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(fill, e))
	draw_set_transform_matrix(_cur_m())


# trasformazione del ventaglio (apertura) in uso: le scritte ci si appoggiano sopra
func _cur_m() -> Transform2D:
	var e: float = _ease(appear)
	var hinge: Vector2 = _p(HINGE)
	return Transform2D((1.0 - e) * 0.55, Vector2(0.35 + 0.65 * e, 0.35 + 0.65 * e), 0.0, hinge) * Transform2D(0.0, -hinge)


# descrizione breve della mossa sulla lama nera sopra ATTACK: quella scelta, se no quella di ATTACK (come nel disegno)
func _draw_desc(e: float) -> void:
	var kind: String = picked if picked != "" else "attack"
	var it: Dictionary = item(kind)
	if it.is_empty():
		return
	var txt: String = str(it.get("desc", "")).split("\n")[0].strip_edges()
	if kind == "ult":
		var nm: String = str(it.get("title", "")).replace("ULTIMATE · ", "").strip_edges()
		if nm != "":
			txt = nm + ": " + txt
	if txt == "":
		return
	var bf: Font = Ui._font("BarlowCondensed-MediumItalic.ttf")
	var fsz: int = HudLayers.MIN_TEXT + 1
	var lines: Array = CmdWheel.wrap(bf, txt, fsz, DESC_W * D * _k)
	if lines.size() > 3:
		lines = lines.slice(0, 3)
		lines[2] = str(lines[2]).trim_suffix(".") + "…"
	var lh: float = float(fsz) * 0.98
	var c: Vector2 = _p(DESC_AT)
	draw_set_transform_matrix(_cur_m() * Transform2D(DESC_ROT, c))
	var y0: float = -lh * (lines.size() - 1) * 0.5 + fsz * 0.34
	for i in lines.size():
		var s: String = str(lines[i])
		var lw: float = bf.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
		draw_string(bf, Vector2(-lw * 0.5, y0 + lh * i), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(1, 1, 1, e))
	draw_set_transform_matrix(_cur_m())
	_polys["desc"] = _poly(DESC_POLY)


# tocco e mouse: le lame sono poligoni storti, non rettangoli. La lama della descrizione vale come il comando descritto.
func _kind_at(p: Vector2) -> String:
	for k in ["skill", "attack", "ult", "guard"]:
		if _polys.has(k) and Geometry2D.is_point_in_polygon(p, _polys[k]):
			return k
	if _polys.has("desc") and Geometry2D.is_point_in_polygon(p, _polys["desc"]):
		return picked if picked != "" else "attack"
	return ""


func _has_point(p: Vector2) -> bool:
	return _kind_at(p) != ""


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var hk: String = _kind_at((ev as InputEventMouseMotion).position)
		if _polys.has("desc") and Geometry2D.is_point_in_polygon((ev as InputEventMouseMotion).position, _polys["desc"]):
			hk = _hov                 # sopra la descrizione resta acceso quello che c'era
		if hk != _hov:
			_hov = hk
			hovered.emit(hk)
			queue_redraw()
		return
	var pressed: bool = (ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed) \
		or (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	if not pressed:
		return
	var p: Vector2 = (ev as InputEventScreenTouch).position if ev is InputEventScreenTouch else (ev as InputEventMouseButton).position
	var k: String = _kind_at(p)
	if k != "":
		accept_event()
		tapped.emit(k)
