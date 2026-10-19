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
var _who: String = ""
var _who_col: Color = Ui.CREAM
var _t: float = 0.0
var _tag: Label
var _clock: Label
var _grain: ColorRect

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
	if anomaly:
		_tag.text = "NESSUN SEGNALE"
		_tag.add_theme_color_override("font_color", MAGIC.lightened(0.25))
		return
	var name_txt: String = ""
	if _who != "":
		name_txt = "  ·  " + _who.to_upper()
	_tag.text = "REC   CAM %02d%s" % [_cam_no, name_txt]
	_tag.add_theme_color_override("font_color", Ui.CREAM.lerp(_who_col, 0.35) if _who != "" else Ui.CREAM)


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
