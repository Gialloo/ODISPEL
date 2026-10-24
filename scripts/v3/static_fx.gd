class_name StaticFx
extends Node

# Disturbo del segnale sul corpo di chi e' rotto (nemico in BREAK, compagno KO): un rumore statico a quadretti che appare e
# sparisce a scatti, come la telecamera di Echo che perde il segnale. Richiesta dell'autore (24/10), riferimento: la sagoma fatta
# di rumore del suo esempio. PRESTAZIONI: un materiale sovrapposto (material_overlay) acceso solo nei lampi, niente se spento.

const SHADER: String = """
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;
uniform float cover = 1.0;
uniform vec4 tint : source_color = vec4(0.66, 0.6, 1.0, 1.0);
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void vertex() {
	// strappi orizzontali: fasce del corpo spostate di lato, cambiano 20 volte al secondo
	float t = floor(TIME * 20.0);
	float band = h(vec2(floor(VERTEX.y * 7.0), t));
	VERTEX.x += (band - 0.5) * 0.09 * step(0.55, band);
}
void fragment() {
	float cell = max(4.0, VIEWPORT_SIZE.y / 140.0);
	vec2 c = floor(FRAGCOORD.xy / cell);
	float t = floor(TIME * 24.0);
	if (h(c + t * 2.31 + 7.0) > cover) { discard; }
	float n = h(c + t * 1.37);
	vec3 col = mix(vec3(0.07, 0.04, 0.13), tint.rgb, n);
	col = mix(col, vec3(1.0), step(0.92, h(c.yx + t * 0.71 + 3.1)));
	float row = h(vec2(floor(FRAGCOORD.y / (cell * 3.0)), t));
	col = mix(col, tint.rgb * 1.25, step(0.93, row) * 0.7);
	ALBEDO = col;
}
"""

static var _shader: Shader = null

var active: bool = false
var _show: bool = false
var _t: float = 0.0
var _mat: ShaderMaterial
var _meshes: Array = []


func _init(tint: Color = Color(0.66, 0.6, 1.0)) -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	_mat.set_shader_parameter("tint", tint)


func set_on(on: bool) -> void:
	if on == active:
		return
	active = on
	if on:
		_collect()
		_show = true
		_t = 0.35          # il primo lampo e' piu' lungo: si vede subito che si e' rotto
		_apply()
	else:
		_show = false
		_apply()


func _collect() -> void:
	_meshes.clear()
	var stack: Array = [get_parent()]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			# niente cerchi a terra e ombre: il disturbo e' sul corpo
			if mi.material_override == Toon.glow() or mi.material_override == Toon.shadow():
				continue
			_meshes.append(mi)


func _apply() -> void:
	_mat.set_shader_parameter("cover", randf_range(0.65, 1.0))
	for mi in _meshes:
		if is_instance_valid(mi):
			(mi as MeshInstance3D).material_overlay = _mat if _show else null


func _process(delta: float) -> void:
	if not active:
		return
	_t -= delta
	if _t > 0.0:
		return
	_show = not _show
	# lampi brevi e pause irregolari: un disturbo, non un effetto fisso
	_t = randf_range(0.06, 0.24) if _show else randf_range(0.15, 0.75)
	_apply()
