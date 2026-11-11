extends CanvasLayer
## 0.12: effetti a schermo da animazione di inizio anni 2000.
## - impact frame: per un istante lo schermo diventa bianco e nero invertito (colpi forti, parry, OVERLOAD)
## - linee di velocità: raggi dal centro su scatti e schivate
## - pellicola: grana leggera e bordi scuri, sempre accesi
## Lo shader che legge lo schermo è acceso solo durante l'impact frame: il resto del tempo non costa la copia.

const IMPACT_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float threshold = 0.42;
uniform vec4 ink : source_color = vec4(0.04, 0.02, 0.05, 1.0);
uniform vec4 paper : source_color = vec4(1.0, 0.96, 0.9, 1.0);
void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.3, 0.59, 0.11));
	// invertito: quello che era chiaro diventa inchiostro, lo scuro diventa carta
	COLOR = l > threshold ? ink : paper;
}
"""

## 0.14: pellicola a basso costo. Grana e vignetta sono due piccole texture preparate una volta;
## lo shader fa solo due letture (niente seni o hash per pixel come prima).
const FILM_SHADER := """
shader_type canvas_item;
uniform sampler2D noise_tex : filter_nearest, repeat_enable;
uniform sampler2D vig_tex : filter_linear;
uniform vec2 offset = vec2(0.0);
uniform vec2 tiles = vec2(10.0, 5.6);
void fragment() {
	float n = texture(noise_tex, UV * tiles + offset).r;
	float v = texture(vig_tex, UV).r;
	float ga = abs(n - 0.5) * 0.1;
	float a = v + ga * (1.0 - v);
	COLOR = vec4(vec3(step(0.5, n)) * ga * (1.0 - v) / max(a, 0.0001), a);
}
"""

const LINES_SHADER := """
shader_type canvas_item;
uniform float amount = 0.0;
float hash(float p) { return fract(sin(p * 91.345) * 47453.5453); }
void fragment() {
	vec2 uv = (UV - 0.5) * vec2(1.78, 1.0);
	float a = atan(uv.y, uv.x);
	float r = length(uv);
	float f = (a + 3.14159) / 6.28318 * 220.0;
	float slot = floor(f);
	float t = floor(TIME * 20.0);
	float on = step(0.78, hash(slot + t * 3.1));
	// linea sottile al centro della sua fetta, più sottile verso l'interno
	float w = 1.0 - smoothstep(0.0, 0.18 + r * 0.25, abs(fract(f) - 0.5));
	float inner = 0.42 + hash(slot * 1.7 + t) * 0.2;
	float m = on * w * smoothstep(inner, inner + 0.15, r);
	COLOR = vec4(1.0, 0.97, 0.92, m * 0.5 * amount);
}
"""

var _impact: ColorRect
var _film: ColorRect
var _lines: ColorRect
var _lines_mat: ShaderMaterial
var _impact_until := 0
var _impact_cd_until := 0
var _lines_until := 0
var _lines_len := 1
var _film_mat: ShaderMaterial
var _film_step := -1

func _noise_tex() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_L8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for y in 64:
		for x in 64:
			img.set_pixel(x, y, Color(rng.randf(), 0, 0))
	return ImageTexture.create_from_image(img)

func _vig_tex() -> ImageTexture:
	var img := Image.create(64, 36, false, Image.FORMAT_L8)
	for y in 36:
		for x in 64:
			var u := Vector2(x / 63.0 - 0.5, y / 35.0 - 0.5) * Vector2(1.25, 1.0)
			img.set_pixel(x, y, Color(smoothstep(0.35, 0.85, u.length()) * 0.38, 0, 0))
	return ImageTexture.create_from_image(img)

func _ready() -> void:
	layer = -1                        # sopra il 3D, sotto la HUD (layer 1)
	process_mode = Node.PROCESS_MODE_ALWAYS
	# ordine: l'impact frame legge lo schermo per primo (senza grana), poi linee e pellicola sopra
	_impact = _rect(IMPACT_SHADER)
	_impact.visible = false
	_lines = _rect(LINES_SHADER)
	_lines_mat = _lines.material
	_lines.visible = false
	_film = _rect(FILM_SHADER)
	_film_mat = _film.material
	_film_mat.set_shader_parameter("noise_tex", _noise_tex())
	_film_mat.set_shader_parameter("vig_tex", _vig_tex())
	FX.impact_requested.connect(_on_impact)
	FX.speedlines_requested.connect(_on_lines)

func _rect(code: String) -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	r.material = m
	add_child(r)
	return r

func _on_impact(ms: int) -> void:
	if not bool(Run.opt.get("flash", true)):
		return
	var now := Time.get_ticks_msec()
	if now < _impact_cd_until:
		return
	_impact_until = now + ms
	_impact_cd_until = now + ms + 350     # mai lampi a raffica
	_impact.visible = true

func _on_lines(ms: int) -> void:
	var now := Time.get_ticks_msec()
	_lines_until = max(_lines_until, now + ms)
	_lines_len = ms
	_lines.visible = true

func _process(_d: float) -> void:
	var now := Time.get_ticks_msec()
	_film.visible = bool(Run.opt.get("film", true))
	# la grana salta 12 volte al secondo: si sposta la texture, non si ricalcola niente
	var st := int(now / 83)
	if _film.visible and st != _film_step:
		_film_step = st
		_film_mat.set_shader_parameter("offset", Vector2(randf(), randf()))
	if _impact.visible and now >= _impact_until:
		_impact.visible = false
	if _lines.visible:
		var left := _lines_until - now
		if left <= 0:
			_lines.visible = false
		else:
			_lines_mat.set_shader_parameter("amount", clampf(float(left) / max(_lines_len, 1) * 1.6, 0.0, 1.0))
