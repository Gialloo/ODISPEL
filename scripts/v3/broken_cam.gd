class_name BrokenCam
extends CanvasLayer

# TELECAMERA ROTTA: la battaglia e' vista dalle telecamere (lo sguardo del Kairos). Quando tocca a un personaggio
# con pochi PV, la sua telecamera e' incrinata o in frantumi: l'immagine si spezza in schegge spostate, con le crepe.
# Ogni personaggio ha la sua telecamera, quindi il suo disegno di crepe (sempre lo stesso per lui).
# Sta fra la scena 3D e l'interfaccia: comandi, barre e testi restano integri e leggibili.
#
# Livelli (PROVVISORI): PV > 50% pulita · 50%..25% incrinata (crepe, poche schegge) · < 25% rotta (tutto in frantumi).

const SEEDS: int = 18

const SHADER: String = """
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform float amount : hint_range(0.0, 1.0) = 0.0;   // 0 pulita, 1 in frantumi
uniform float kick = 0.0;                           // colpo all'ingresso (schegge che saltano)
uniform vec2 impact = vec2(0.6, 0.45);              // punto d'impatto (uv)
uniform float aspect = 1.7778;
uniform vec2 pts[18];                               // centri delle schegge (uv)
uniform float flicker = 0.0;                        // tremolio (0 se i lampi sono spenti)
uniform float t = 0.0;

float h1(float n) { return fract(sin(n * 91.345) * 47453.5453); }

// distanza con l'aspetto dello schermo: bordi dritti, come schegge di vetro vere
float sdist(vec2 a, vec2 b) {
	vec2 d = a - b;
	d.x *= aspect;
	return dot(d, d);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float d1 = 1e5; float d2 = 1e5; int id = 0;
	for (int i = 0; i < 18; i++) {
		float d = sdist(uv, pts[i]);
		if (d < d1) { d2 = d1; d1 = d; id = i; }
		else if (d < d2) { d2 = d; }
	}
	float fi = float(id);
	float r = h1(fi + 1.0);
	// quante schegge si staccano: con poco danno solo alcune, poi tutte
	float loose = step(r, amount * 1.3 - 0.2);
	float k = (amount + kick) * loose;
	vec2 c = pts[id];
	// ogni scheggia mostra un pezzo d'immagine spostato, ruotato e ingrandito: il nemico si vede doppio
	float ang = (h1(fi + 7.0) - 0.5) * 0.32 * k;
	float zoom = 1.0 + (h1(fi + 13.0) - 0.3) * 0.5 * k;
	vec2 off = (vec2(h1(fi + 3.0), h1(fi + 5.0)) - 0.5) * vec2(0.22, 0.16) * k;
	off += vec2(sin(t * 37.0 + fi), cos(t * 29.0 + fi)) * 0.002 * flicker * loose;
	vec2 p = uv - c;
	p.x *= aspect;
	p = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang))) * p / zoom;
	p.x /= aspect;
	vec2 suv = clamp(c + p + off, vec2(0.001), vec2(0.999));
	vec3 col = texture(screen_tex, suv).rgb;
	// ogni scheggia prende la luce in modo diverso
	col *= 1.0 + (h1(fi + 17.0) - 0.5) * 0.28 * k;
	col = mix(col, vec3(0.92, 0.9, 1.0), 0.10 * loose * amount * step(0.72, h1(fi + 21.0)));
	// crepe: bordo chiaro sottile con un filo d'ombra accanto
	d1 = sqrt(d1); d2 = sqrt(d2);
	float edge = d2 - d1;
	float w = 0.0022 + 0.0016 * amount;
	float crack = (1.0 - smoothstep(0.0, w, edge)) * smoothstep(0.02, 0.2, amount);
	float shade = (1.0 - smoothstep(w, w * 3.0, edge)) * 0.35 * smoothstep(0.02, 0.2, amount);
	col = mix(col, col * 0.45, shade);
	col = mix(col, vec3(0.97, 0.96, 1.0), crack * 0.85);
	// punto d'impatto: vetro sbriciolato
	vec2 q = uv - impact; q.x *= aspect;
	float star = (1.0 - smoothstep(0.0, 0.05 + 0.04 * amount, length(q))) * amount;
	col = mix(col, vec3(0.95), star * 0.55);
	COLOR = vec4(col, 1.0);
}
"""

var _rect: ColorRect
var _mat: ShaderMaterial
var _amount: float = 0.0
var _target: float = 0.0
var _kick: float = 0.0
var _t: float = 0.0
var _who: String = ""


func _ready() -> void:
	layer = 5          # sopra il 3D, sotto l'interfaccia della battaglia (10)
	_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHADER
	_mat.shader = sh
	_rect = ColorRect.new()
	_rect.material = _mat
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.place(_rect, 0, 0, 1, 1)
	_rect.visible = false
	add_child(_rect)


# Quanto e' rotta la telecamera per un rapporto PV/PV massimi (0 = pulita)
static func level_for(ratio: float) -> float:
	if ratio > 0.5:
		return 0.0
	return 0.3 + 0.7 * clampf((0.5 - ratio) / 0.25, 0.0, 1.0)


# Telecamera di un personaggio (char_id) con questo rapporto di PV; "" = nessuno (turno del nemico, fine)
func show_for(char_id: String, ratio: float) -> void:
	if not Settings.broken_cam:
		char_id = ""
	var lvl: float = level_for(ratio) if char_id != "" else 0.0
	if Settings.light_fx:
		lvl *= 0.6
	if char_id != _who and lvl > 0.0:
		_build_pattern(char_id)
		_amount = 0.0
		_kick = 0.35 * maxf(0.3, Settings.shake)   # le schegge saltano quando si passa a questa telecamera
		Settings.buzz(30)
	elif lvl > _target + 0.15:
		_kick = 0.25 * maxf(0.3, Settings.shake)    # si e' rotta di piu' durante il turno
	_who = char_id if lvl > 0.0 else ""
	_target = lvl


func _build_pattern(char_id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(char_id) & 0x7fffffff
	var imp := Vector2(rng.randf_range(0.3, 0.7), rng.randf_range(0.3, 0.6))
	var pts := PackedVector2Array()
	for i in SEEDS:
		# piu' fitte vicino all'impatto, piu' larghe verso i bordi
		var a: float = TAU * float(i) / float(SEEDS) + rng.randf_range(-0.25, 0.25)
		var r: float = (0.08 + 0.85 * pow(rng.randf(), 0.8)) * (0.6 if i % 3 == 0 else 1.0)
		pts.append(imp + Vector2(cos(a) * r / 1.7778, sin(a) * r))
	_mat.set_shader_parameter("pts", pts)
	_mat.set_shader_parameter("impact", imp)


func _process(delta: float) -> void:
	_t += delta
	_amount = move_toward(_amount, _target, delta * (4.0 if _target > _amount else 2.5))
	_kick = move_toward(_kick, 0.0, delta * 1.6)
	_rect.visible = _amount > 0.005
	if not _rect.visible:
		return
	var sz: Vector2 = get_viewport().get_visible_rect().size
	_mat.set_shader_parameter("aspect", sz.x / maxf(1.0, sz.y))
	_mat.set_shader_parameter("amount", _amount)
	_mat.set_shader_parameter("kick", _kick)
	_mat.set_shader_parameter("flicker", Settings.flash * (0.0 if Settings.light_fx else 1.0))
	_mat.set_shader_parameter("t", _t)
