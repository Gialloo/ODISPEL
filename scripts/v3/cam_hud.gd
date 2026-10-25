class_name CamHud
extends Control

# LO SGUARDO E' UNA TELECAMERA (SINTESI §5): l'interfaccia e' l'occhio di Echo, che vive nelle telecamere.
# Angoli del mirino, REC che lampeggia, numero della telecamera e ora della notte (l'atto va dalle tre all'alba).
# Dentro le Anomalie le telecamere non arrivano: niente REC, «NESSUN SEGNALE» in magenta che sfarfalla.
# Grana e righe di scansione leggerissime (spente con «effetti ridotti»), sotto ai comandi: i testi restano leggibili.
#
# Uso: var h := CamHud.new(); h.anomaly = ...; h.tag_right = ...; parent.add_child(h); h.watch("nox", Color, 2)

const MAGIC: Color = Color("#E83DCE")
const REC_RED: Color = Color("#ff4630")

var anomaly: bool = false            # dentro un'Anomalia: nessun segnale
var tag_right: bool = false          # etichetta a destra (esplorazione, sotto la pausa) o a sinistra (battaglia)
var tag_y: float = -204.0            # posizione verticale dell'etichetta (dal basso se negativa)
var _cam_no: int = 1
var live: int = -1                   # Hype di Rio (battaglia): da 25 in su la telecamera va «in diretta» e lo scrive
var _who: String = ""
var _who_col: Color = Ui.CREAM
var _t: float = 0.0
var _tag: Label
var _clock: Label
var _grain: ColorRect
# LA CITTA' CHE REAGISCE (Fase 4): la telecamera di Echo subisce la battaglia.
var fractured: bool = false          # nemico in BREAK: la lente resta incrinata in un angolo finche' non si rialza
var _dist_t: float = 0.0             # disturbo in corso (Ultimate o BREAK): secondi rimasti
var _dist_len: float = 1.0
var _dist_txt: String = ""
var _dist_col: Color = Ui.CREAM

const GRAIN_SHADER: String = """
shader_type canvas_item;
render_mode unshaded;
uniform float k = 1.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float scan = step(0.5, fract(FRAGCOORD.y * 0.5)) * 0.035;
	float n = h(floor(FRAGCOORD.xy * 0.5) + floor(TIME * 18.0)) * 0.05;
	COLOR = vec4(vec3(n), (scan + n * 0.6) * k);
}
"""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.place(self, 0, 0, 1, 1)
	if not Settings.light_fx:
		_grain = ColorRect.new()
		_grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Ui.place(_grain, 0, 0, 1, 1)
		var mat := ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = GRAIN_SHADER
		mat.shader = sh
		mat.set_shader_parameter("k", 1.6 if anomaly else 1.0)
		_grain.material = mat
		add_child(_grain)
	_tag = Ui.label("", 18, Ui.CREAM, Ui.body(), 6)
	_clock = Ui.label("", 15, Color(1, 1, 1, 0.7), Ui.body(), 5)
	for l in [_tag, _clock]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if tag_right else HORIZONTAL_ALIGNMENT_LEFT
		add_child(l)
	var top: float = tag_y
	var anchor_y: float = 1.0 if tag_y < 0.0 else 0.0
	if tag_right:
		Ui.place(_tag, 1, anchor_y, 1, anchor_y, -460, top, -24, top + 24)
		Ui.place(_clock, 1, anchor_y, 1, anchor_y, -460, top + 23, -24, top + 44)
	else:
		Ui.place(_tag, 0, anchor_y, 0, anchor_y, 44, top, 520, top + 24)
		Ui.place(_clock, 0, anchor_y, 0, anchor_y, 44, top + 23, 520, top + 44)
	_refresh()


# Chi stiamo guardando: id del personaggio (vuoto = inquadratura generale), colore, numero della telecamera.
func watch(who: String, c: Color, cam_no: int) -> void:
	_who = who
	_who_col = c
	_cam_no = cam_no
	_refresh()


func _refresh() -> void:
	if _tag == null:
		return
	if _dist_t > 0.0:
		_tag.text = _dist_txt
		_tag.add_theme_color_override("font_color", _dist_col)
		return
	if anomaly:
		_tag.text = "NESSUN SEGNALE"
		_tag.add_theme_color_override("font_color", MAGIC.lightened(0.25))
		return
	var name_txt: String = ""
	if _who != "":
		name_txt = "  ·  " + _who.to_upper()
	_tag.text = "REC   CAM %02d%s%s" % [_cam_no, name_txt, ("  ·  IN DIRETTA %d" % live) if live >= 25 else ""]
	_tag.add_theme_color_override("font_color", Ui.CREAM.lerp(_who_col, 0.35) if _who != "" else Ui.CREAM)


# Disturbo del segnale: l'etichetta del REC lo dice, mirino e scritta tremano, poi tutto torna come prima.
func disturb(txt: String, c: Color, secs: float = 1.4) -> void:
	if anomaly:
		return
	_dist_txt = txt
	_dist_col = c
	_dist_t = secs
	_dist_len = maxf(0.1, secs)
	_refresh()


func set_fractured(on: bool) -> void:
	if on != fractured:
		fractured = on
		queue_redraw()


# Hype di Rio: la diretta si vede nella telecamera di Echo
func set_live(hype: int) -> void:
	if hype != live:
		live = hype
		_refresh()


# Ora della notte: il prologo comincia alle tre, ogni capitolo porta la citta' piu' vicina all'alba.
func _time_text() -> String:
	if anomaly:
		return "--:--:--"
	var ch: int = int(Story.chapter) if Story.chapter >= 0 else 0
	var secs: int = 3 * 3600 + 12 * 60 + ch * 23 * 60 + int(_t)
	return "%02d:%02d:%02d" % [(secs / 3600) % 24, (secs / 60) % 60, secs % 60]


func _process(delta: float) -> void:
	_t += delta
	if _clock != null:
		_clock.text = _time_text()
	if anomaly and _tag != null:
		_tag.modulate.a = 0.55 + 0.45 * float(sin(_t * 23.0) > -0.6)
	if _dist_t > 0.0:
		_dist_t -= delta
		if _tag != null:
			_tag.modulate.a = 0.45 + 0.55 * float(sin(_t * 41.0) > -0.3)
		if _dist_t <= 0.0:
			if _tag != null:
				_tag.modulate.a = 1.0
			_refresh()
	queue_redraw()


func _draw() -> void:
	var sz: Vector2 = size
	var c: Color = Color(MAGIC.r, MAGIC.g, MAGIC.b, 0.5) if anomaly else Color(1, 0.96, 0.86, 0.4)
	var m: float = 12.0
	var l: float = 36.0
	var w: float = 3.0
	var j := Vector2.ZERO
	if anomaly:
		j = Vector2(sin(_t * 31.0), cos(_t * 27.0)) * 1.5
	if _dist_t > 0.0:
		var k: float = _dist_t / _dist_len
		j = Vector2(sin(_t * 47.0), cos(_t * 39.0)) * 5.0 * k
		c = c.lerp(Color(_dist_col.r, _dist_col.g, _dist_col.b, 0.75), k)
	for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		var p := Vector2(m if corner.x == 0 else sz.x - m, m if corner.y == 0 else sz.y - m) + j
		var dx: float = l if corner.x == 0 else -l
		var dy: float = l if corner.y == 0 else -l
		draw_line(p, p + Vector2(dx, 0), c, w)
		draw_line(p, p + Vector2(0, dy), c, w)
	# pallino del REC accanto all'etichetta: lampeggia come una telecamera vera
	if not anomaly and _tag != null and fmod(_t, 1.2) < 0.75:
		var tp: Vector2 = _tag.position
		var x: float = tp.x + _tag.size.x - _tag.get_combined_minimum_size().x - 14.0 if tag_right else tp.x - 14.0
		draw_circle(Vector2(x, tp.y + _tag.size.y * 0.5), 7.0, REC_RED)
		draw_arc(Vector2(x, tp.y + _tag.size.y * 0.5), 7.5, 0, TAU, 16, Ui.INK, 2.0)
	if fractured:
		_draw_crack(sz)


# Lente incrinata (nemico in BREAK): poche linee spezzate dal bordo sinistro, nel buio tra REC e comandi, lontano dai testi.
# Disegno fisso (niente casuale a ogni frame): costa una decina di linee.
const _CRACK: Array = [
	[Vector2(0.0, 0.0), Vector2(-60, -22), Vector2(-118, -30), Vector2(-190, -70)],
	[Vector2(0.0, 0.0), Vector2(-24, -64), Vector2(-30, -120), Vector2(-72, -176)],
	[Vector2(-60, -22), Vector2(-84, -78), Vector2(-30, -120)],
	[Vector2(-118, -30), Vector2(-150, -10)],
	[Vector2(0.0, 0.0), Vector2(-96, -110), Vector2(-150, -150)],
]


func _draw_crack(sz: Vector2) -> void:
	var o := Vector2(10.0, sz.y * 0.36)
	for i in _CRACK.size():
		var pts := PackedVector2Array()
		var fy: float = 1.0 if i % 2 == 0 else -0.8      # meta' delle crepe sale, meta' scende
		for q in _CRACK[i]:
			pts.append(o + Vector2(-(q as Vector2).x * 1.2, (q as Vector2).y * fy * 0.9))
		draw_polyline(pts, Color(0, 0, 0, 0.5), 4.5)
		draw_polyline(pts, Color(1, 1, 1, 0.75), 2.2)
