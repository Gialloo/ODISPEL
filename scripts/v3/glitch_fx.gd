class_name GlitchFx
extends CanvasLayer

# GLITCH CROMATICO breve (riferimento: aberrazione rosso-ciano sui bordi luminosi nei momenti forti delle foto Ghost Stride).
# Un rettangolo a tutto schermo con shader che legge lo schermo, SOLO per ~0,25 s sui colpi critici, le rotture e le mosse pesanti
# dei boss; il resto del tempo e' invisibile (zero costo). Tre letture dello schermo + qualche fascia spostata, niente cicli.
# Spento con effetti ridotti (light_fx) e con i lampi a zero (Settings.flash, accessibilita'). Sta SOTTO l'interfaccia (layer 5).

const SHADER: String = """
shader_type canvas_item;
uniform sampler2D scr : hint_screen_texture, filter_linear, repeat_disable;
uniform float amt = 0.0;
uniform float seed = 0.0;
float h(float n) { return fract(sin(n * 91.3 + seed * 17.0) * 43758.5); }
void fragment() {
	vec2 uv = SCREEN_UV;
	float band = floor(uv.y * 14.0);
	float on = step(0.78, h(band)) * amt;
	uv.x += (h(band + 3.0) - 0.5) * 0.06 * on;
	float s = amt * 0.008;
	vec3 c;
	c.r = texture(scr, uv + vec2(s, 0.0)).r;
	c.g = texture(scr, uv).g;
	c.b = texture(scr, uv - vec2(s, 0.0)).b;
	COLOR = vec4(c, 1.0);
}
"""

static var _shader: Shader = null

var _rect: ColorRect
var _mat: ShaderMaterial
var _tw: Tween


static func shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	return _shader


func _init() -> void:
	layer = 5
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mat = ShaderMaterial.new()
	_mat.shader = shader()
	_rect.material = _mat
	_rect.visible = false
	add_child(_rect)


# Impulso: k = forza 0..1
func pulse(k: float = 1.0, secs: float = 0.26) -> void:
	if Settings.light_fx or Settings.flash <= 0.0:
		return
	if _tw != null and _tw.is_valid():
		_tw.kill()
	_mat.set_shader_parameter("seed", randf() * 10.0)
	_mat.set_shader_parameter("amt", k * Settings.flash)
	_rect.visible = true
	_tw = create_tween()
	_tw.tween_method(func(v: float) -> void: _mat.set_shader_parameter("amt", v * k * Settings.flash), 1.0, 0.0, secs)
	_tw.tween_callback(func() -> void: _rect.visible = false)
