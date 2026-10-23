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
const BREAK_TIME: float = 1.15

const SHADER: String = """
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform float crack = 0.0;       // crepe che restano (0..1)
uniform float burst = 0.0;       // rottura in corso (1 = appena colpito, poi scende a 0)
uniform float glow = 0.0;        // lampo bianco della rottura (0 se i lampi sono spenti)
uniform float prog = 1.0;        // tempo della rottura 0..1 (onda d'urto, raggi, schegge che volano verso di noi)
uniform float big = 0.0;         // 1 = rottura del nemico (BREAK): piu' schegge in volo, bordi luminosi, aberrazione
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
	// BREAK: le schegge volano verso la camera (si ingrandiscono e si allontanano dal punto d'impatto), ognuna con la sua spinta (profondita')
	float depth = 0.4 + 0.6 * h1(fi + 11.0);
	float zoom = 1.0 + big * burst * 0.22 * depth;
	off += dir * big * burst * 0.07 * depth;
	float ang = (h1(fi + 7.0) - 0.5) * (0.12 + 0.2 * big) * move;
	vec2 p = uv - pts[id];
	p.x *= aspect;
	p = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang))) * p;
	p.x /= aspect;
	p /= zoom;
	vec2 suv = clamp(pts[id] + p + off, vec2(0.001), vec2(0.999));
	vec3 col = texture(screen_tex, suv).rgb;
	// aberrazione cromatica solo nei primi istanti del BREAK (rosso e blu leggermente separati)
	if (big > 0.5) {
		vec2 ab = dir * 0.012 * burst;
		col.r = texture(screen_tex, clamp(suv + ab, vec2(0.001), vec2(0.999))).r;
		col.b = texture(screen_tex, clamp(suv - ab, vec2(0.001), vec2(0.999))).b;
	}
	col *= 1.0 + (h1(fi + 17.0) - 0.5) * (0.12 + 0.3 * big) * move;
	// crepe: linea chiara sottile con un filo d'ombra
	float vis = max(crack, burst);
	float edge = d2 - d1;
	float w = 0.0018 + 0.0012 * vis + 0.0016 * big * burst;
	float line = (1.0 - smoothstep(0.0, w, edge)) * smoothstep(0.0, 0.15, vis);
	float shade = (1.0 - smoothstep(w, w * 2.5, edge)) * 0.25 * smoothstep(0.0, 0.15, vis);
	col = mix(col, col * 0.55, shade);
	col = mix(col, vec3(0.96, 0.95, 1.0), line * (0.55 + 0.35 * burst));
	// BREAK: fessura scura tra le schegge con bordo luminoso ghiaccio (le schegge sembrano vetro vero, con spessore)
	float gap = (1.0 - smoothstep(w * 1.5, w * 4.5, edge)) * big * burst;
	col = mix(col, col * 0.3, gap * 0.8);
	float rim = (1.0 - smoothstep(0.0, w * 1.6, edge)) * big * smoothstep(0.0, 0.2, burst);
	col += vec3(0.55, 0.9, 1.0) * rim * 0.9;
	// riflesso sulla faccia della scheggia: ogni scheggia prende la luce da un lato diverso
	float facet = dot(normalize(p + vec2(0.0001)), vec2(cos(fi * 2.4), sin(fi * 2.4)));
	col += vec3(0.8, 0.95, 1.0) * max(0.0, facet) * 0.22 * big * burst * depth;
	// punto d'impatto e lampo della rottura
	vec2 q2 = uv - impact; q2.x *= aspect;
	float rq = length(q2);
	float star = (1.0 - smoothstep(0.0, 0.04 + 0.05 * burst, rq)) * vis;
	col = mix(col, vec3(0.95), star * 0.35);
	// BREAK: raggi netti dal punto d'impatto (crepe che partono dal colpo) e onda d'urto che si allarga
	if (big > 0.5) {
		float a = atan(q2.y, q2.x);
		float k = a * 9.0 / 6.2831853;
		float sid = floor(k + 0.5);
		float sp = abs(k - sid) / 9.0 * 6.2831853 * rq;   // distanza dal raggio in unita' dello schermo
		float reach = (0.18 + 0.75 * h1(sid * 3.7 + 1.0)) * smoothstep(0.0, 0.25, prog);
		float spoke = (1.0 - smoothstep(0.0012, 0.0034, sp)) * (1.0 - smoothstep(reach * 0.8, reach, rq)) * burst * 3.0;
		col = mix(col, vec3(1.0), clamp(spoke, 0.0, 1.0) * 0.9);
		float shock = abs(rq - prog * 0.9);
		float wave = (1.0 - smoothstep(0.0, 0.02 + 0.03 * prog, shock)) * (1.0 - prog) * burst;
		col += vec3(0.6, 0.9, 1.0) * wave * 0.8;
	}
	col = mix(col, vec3(1.0), glow * (0.35 + 0.35 * big));
	COLOR = vec4(col, 1.0);
}
"""

var _rect: ColorRect
var _mat: ShaderMaterial
var _crack: float = 0.0
var _target: float = 0.0
var _burst: float = 0.0
var _burst_t: float = 99.0
var _burst_dur: float = 0.7           # durata della rottura in corso (il BREAK dura di piu': e' il momento da godersi)
var _big: float = 0.0                 # 1 se la rottura in corso e' il BREAK del nemico
var _rel: PackedVector2Array = PackedVector2Array()   # schegge relative al punto d'impatto (si puo' spostare sul nemico)
var _imp: Vector2 = Vector2(0.6, 0.45)
var _stop_gen: int = 0
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
# impact = punto dello schermo (0..1) da cui partono le crepe; (-1,-1) = quello suo. big = BREAK del nemico: dura di piu',
# fermo immagine brevissimo, schegge che volano verso di noi (Star Rail: il vetro rotto e' il premio del Break).
func shatter(key: String, strength: float = 1.0, impact: Vector2 = Vector2(-1, -1), big: bool = false) -> void:
	if not Settings.broken_cam:
		return
	if key != _pattern:
		_use_pattern(key)
		_crack = 0.0
	if impact.x >= 0.0:
		_place_pattern(impact)
	var k: float = 0.6 if Settings.light_fx else 1.0
	_burst = clampf(strength, 0.3, 1.0) * k
	_burst_t = 0.0
	_big = 1.0 if big else 0.0
	_burst_dur = BREAK_TIME if big else BURST_TIME
	Settings.buzz(120 if big else 60)
	if big:
		_hit_stop()


# Fermo immagine di ~0.09 s (tempo reale) sul colpo che rompe: Persona/Star Rail, il colpo "pesa". Solo se il gioco corre normale
# (non in pausa, non quando il tempo e' gia' rallentato) e si rimette a posto da solo.
func _hit_stop() -> void:
	if Engine.time_scale < 0.5 or Engine.time_scale > 2.0:
		return
	var prev: float = Engine.time_scale
	_stop_gen += 1
	var gen: int = _stop_gen
	Engine.time_scale = 0.06
	await get_tree().create_timer(0.09, true, false, true).timeout
	if gen == _stop_gen and is_equal_approx(Engine.time_scale, 0.06):
		Engine.time_scale = prev


func _exit_tree() -> void:
	# se la battaglia chiude durante il fermo immagine il tempo non deve restare lento
	if is_equal_approx(Engine.time_scale, 0.06):
		Engine.time_scale = 1.0


func _use_pattern(key: String) -> void:
	_pattern = key
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key) & 0x7fffffff
	var imp := Vector2(rng.randf_range(0.3, 0.7), rng.randf_range(0.3, 0.6))
	_rel = PackedVector2Array()
	for i in SEEDS:
		var a: float = TAU * float(i) / float(SEEDS) + rng.randf_range(-0.25, 0.25)
		var r: float = (0.08 + 0.85 * pow(rng.randf(), 0.8)) * (0.6 if i % 3 == 0 else 1.0)
		_rel.append(Vector2(cos(a) * r / 1.7778, sin(a) * r))
	_place_pattern(imp)


func _place_pattern(imp: Vector2) -> void:
	_imp = imp
	var pts := PackedVector2Array()
	for r2 in _rel:
		pts.append(imp + r2)
	_mat.set_shader_parameter("pts", pts)
	_mat.set_shader_parameter("impact", imp)


func _process(delta: float) -> void:
	_crack = move_toward(_crack, _target, delta * 3.0)
	var b: float = 0.0
	var k: float = 1.0
	if _burst_t < _burst_dur:
		_burst_t += delta
		k = clampf(_burst_t / _burst_dur, 0.0, 1.0)
		# il BREAK resta teso un attimo (le schegge sospese) e poi ricade; il colpo normale salta subito e ricade
		b = _burst * (1.0 - k) * (1.0 - k) if _big < 0.5 else _burst * (1.0 - smoothstep(0.35, 1.0, k))
	_rect.visible = _crack > 0.005 or b > 0.005
	if not _rect.visible:
		return
	var sz: Vector2 = get_viewport().get_visible_rect().size
	_mat.set_shader_parameter("aspect", sz.x / maxf(1.0, sz.y))
	_mat.set_shader_parameter("crack", _crack)
	_mat.set_shader_parameter("burst", b)
	_mat.set_shader_parameter("prog", k)
	_mat.set_shader_parameter("big", _big)
	# lampo bianco nei primi 0.15 s, solo se i lampi sono accesi nelle impostazioni
	_mat.set_shader_parameter("glow", Settings.flash * maxf(0.0, 1.0 - _burst_t / 0.15) * _burst if _burst_t < 0.15 else 0.0)
