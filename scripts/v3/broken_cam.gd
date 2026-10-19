class_name BrokenCam
extends CanvasLayer

# TELECAMERA ROTTA: la battaglia e' vista dalle telecamere (lo sguardo di Echo, il Kairos).
#
# 1. ROTTURA (animazione): nel momento esatto del colpo lo schermo si spezza, le schegge saltano e ricadono.
#    - quando il nemico colpisce un personaggio e lo fa scendere sotto il 50% o sotto il 25% dei PV;
#    - quando la squadra manda il nemico in ROTTURA (barra bianca a 0): solo l'animazione, poi lo schermo torna pulito.
# 2. CREPE CHE RESTANO: quando tocca a un personaggio ferito, la sua telecamera resta incrinata.
#    Leggera e leggibile: crepe sottili e schegge appena spostate, il centro dello schermo resta quasi pulito.
#
# Ogni personaggio ha la sua telecamera, quindi il suo disegno di crepe. Comandi e testi stanno sopra e restano integri.
# Livelli (PROVVISORI): PV > 50% pulita · 50%..25% incrinata · < 25% rotta.

const SEEDS: int = 14
const BURST_TIME: float = 0.7

const SHADER: String = """
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform float crack = 0.0;       // crepe che restano (0..1)
uniform float burst = 0.0;       // rottura in corso (1 = appena colpito, poi scende a 0)
uniform float glow = 0.0;        // lampo bianco della rottura (0 se i lampi sono spenti)
uniform vec2 impact = vec2(0.6, 0.45);
uniform float aspect = 1.7778;
uniform vec2 pts[14];

float h1(float n) { return fract(sin(n * 91.345) * 47453.5453); }

void fragment() {
	vec2 uv = SCREEN_UV;
	float d1 = 1e5; float d2 = 1e5; int id = 0;
	for (int i = 0; i < 14; i++) {
		vec2 d = uv - pts[i];
		d.x *= aspect;
		float q = dot(d, d);
		if (q < d1) { d2 = d1; d1 = q; id = i; }
		else if (q < d2) { d2 = q; }
	}
	d1 = sqrt(d1); d2 = sqrt(d2);
	float fi = float(id);
	// le schegge vicine al centro dello schermo si muovono poco: l'azione resta leggibile
	vec2 cc = pts[id] - vec2(0.5, 0.55);
	cc.x *= aspect;
	float edge_w = smoothstep(0.12, 0.55, length(cc));
	float move = crack * 0.22 * edge_w + burst;
	vec2 dir = normalize(pts[id] - impact + vec2(0.0001));
	vec2 off = (vec2(h1(fi + 3.0), h1(fi + 5.0)) - 0.5) * vec2(0.05, 0.04) * move + dir * 0.05 * burst;
	float ang = (h1(fi + 7.0) - 0.5) * 0.12 * move;
	vec2 p = uv - pts[id];
	p.x *= aspect;
	p = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang))) * p;
	p.x /= aspect;
	vec2 suv = clamp(pts[id] + p + off, vec2(0.001), vec2(0.999));
	vec3 col = texture(screen_tex, suv).rgb;
	col *= 1.0 + (h1(fi + 17.0) - 0.5) * 0.12 * move;
	// crepe: linea chiara sottile con un filo d'ombra
	float vis = max(crack, burst);
	float edge = d2 - d1;
	float w = 0.0018 + 0.0012 * vis;
	float line = (1.0 - smoothstep(0.0, w, edge)) * smoothstep(0.0, 0.15, vis);
	float shade = (1.0 - smoothstep(w, w * 2.5, edge)) * 0.25 * smoothstep(0.0, 0.15, vis);
	col = mix(col, col * 0.55, shade);
	col = mix(col, vec3(0.96, 0.95, 1.0), line * (0.55 + 0.35 * burst));
	// punto d'impatto e lampo della rottura
	vec2 q2 = uv - impact; q2.x *= aspect;
	float star = (1.0 - smoothstep(0.0, 0.04 + 0.05 * burst, length(q2))) * vis;
	col = mix(col, vec3(0.95), star * 0.35);
	col = mix(col, vec3(1.0), glow * 0.35);
	COLOR = vec4(col, 1.0);
}
"""

var _rect: ColorRect
var _mat: ShaderMaterial
var _crack: float = 0.0
var _target: float = 0.0
var _burst: float = 0.0
var _burst_t: float = 99.0
var _who: String = ""
var _pattern: String = ""


func _ready() -> void:
	layer = 5          # sopra il 3D, sotto l'interfaccia della battaglia (10)
	_mat = ShaderMaterial.new()
	_mat.shader = shader()
	_rect = ColorRect.new()
	_rect.material = _mat
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.place(_rect, 0, 0, 1, 1)
	_rect.visible = false
	add_child(_rect)


# Lo shader si compila una volta sola per tutta la partita (prima se ne creava uno nuovo a ogni battaglia,
# e il telefono lo ricompilava proprio quando la telecamera si incrinava: un piccolo scatto nel momento piu' forte)
static var _shader: Shader = null


static func shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	return _shader


# 0 = sopra il 50% · 1 = incrinata (50%..25%) · 2 = rotta (sotto il 25%)
static func tier(ratio: float) -> int:
	if ratio > 0.5:
		return 0
	return 1 if ratio > 0.25 else 2


# Intensita' delle crepe che restano, per un rapporto PV/PV massimi (0 = pulita)
static func level_for(ratio: float) -> float:
	match tier(ratio):
		1:
			return 0.45
		2:
			return 1.0
	return 0.0


# Telecamera del personaggio di turno; "" = nessuno (turno del nemico, fine)
func show_for(char_id: String, ratio: float) -> void:
	if not Settings.broken_cam:
		char_id = ""
	var lvl: float = level_for(ratio) if char_id != "" else 0.0
	if Settings.light_fx:
		lvl *= 0.6
	if lvl > 0.0 and char_id != _pattern:
		_use_pattern(char_id)
		_crack = 0.0
	_who = char_id if lvl > 0.0 else ""
	_target = lvl


# Animazione di rottura nel momento del colpo. key = di chi e' la telecamera (personaggio) o "boss".
func shatter(key: String, strength: float = 1.0) -> void:
	if not Settings.broken_cam:
		return
	if key != _pattern:
		_use_pattern(key)
		_crack = 0.0
	_burst = clampf(strength, 0.3, 1.0) * (0.6 if Settings.light_fx else 1.0)
	_burst_t = 0.0
	Settings.buzz(60)


func _use_pattern(key: String) -> void:
	_pattern = key
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key) & 0x7fffffff
	var imp := Vector2(rng.randf_range(0.3, 0.7), rng.randf_range(0.3, 0.6))
	var pts := PackedVector2Array()
	for i in SEEDS:
		var a: float = TAU * float(i) / float(SEEDS) + rng.randf_range(-0.25, 0.25)
		var r: float = (0.08 + 0.85 * pow(rng.randf(), 0.8)) * (0.6 if i % 3 == 0 else 1.0)
		pts.append(imp + Vector2(cos(a) * r / 1.7778, sin(a) * r))
	_mat.set_shader_parameter("pts", pts)
	_mat.set_shader_parameter("impact", imp)


func _process(delta: float) -> void:
	_crack = move_toward(_crack, _target, delta * 3.0)
	var b: float = 0.0
	if _burst_t < BURST_TIME:
		_burst_t += delta
		var k: float = clampf(_burst_t / BURST_TIME, 0.0, 1.0)
		b = _burst * (1.0 - k) * (1.0 - k)          # salta subito, poi ricade
	_rect.visible = _crack > 0.005 or b > 0.005
	if not _rect.visible:
		return
	var sz: Vector2 = get_viewport().get_visible_rect().size
	_mat.set_shader_parameter("aspect", sz.x / maxf(1.0, sz.y))
	_mat.set_shader_parameter("crack", _crack)
	_mat.set_shader_parameter("burst", b)
	_mat.set_shader_parameter("glow", Settings.flash * maxf(0.0, 1.0 - _burst_t / 0.15) * _burst if _burst_t < 0.15 else 0.0)
