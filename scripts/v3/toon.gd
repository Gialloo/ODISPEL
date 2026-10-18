class_name Toon
extends RefCounted

# Materiali toon condivisi della V3. Tutto e' UNSHADED: niente luci in tempo reale, niente ombre, niente cielo.
# L'ombreggiatura a due toni si calcola nello shader con una direzione di luce fissa: costa poco ed e' uguale su ogni telefono.
# Colore dei vertici: rgb = colore, alpha = 1 normale, alpha = 0 "luce propria" (insegne, finestre: niente ombra).
# Contorni: guscio rovesciato (mesh gonfiata, cull_front) in una seconda superficie della stessa mesh, NON next_pass.

const INK: Color = Color(0.07, 0.04, 0.11)

const _BODY: String = """
shader_type spatial;
render_mode unshaded, cull_back;
uniform vec3 light_dir = vec3(-0.45, 0.85, 0.35);
uniform vec3 shade_tint : source_color = vec3(0.50, 0.46, 0.80);
uniform vec3 rim_col : source_color = vec3(1.0, 0.82, 0.95);
uniform float rim_k = 0.32;
uniform vec3 fog_col : source_color = vec3(0.10, 0.07, 0.17);
uniform float fog_near = 18.0;
uniform float fog_far = 70.0;
varying vec3 wn;
void vertex() {
	wn = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}
void fragment() {
	vec3 base = COLOR.rgb;
	vec3 c = base;
	// alpha: 1 normale (ombra fredda) · 0.8 pelle (ombra calda) · 0.6 piatto (viso) · 0 luce propria
	if (COLOR.a > 0.7) {
		float nl = dot(normalize(wn), normalize(light_dir));
		float lit = smoothstep(-0.03, 0.05, nl);
		vec3 tint = COLOR.a > 0.9 ? shade_tint : vec3(0.88, 0.64, 0.70);
		c = mix(base * tint, base, lit);
		float r = 1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
		c = mix(c, rim_col, step(0.80, r) * rim_k * lit);
	}
	float d = length(VERTEX);
	float f = smoothstep(fog_near, fog_far, d) * (COLOR.a > 0.5 ? 1.0 : 0.55);
	ALBEDO = mix(c, fog_col, f);
}
"""

const _INK: String = """
shader_type spatial;
render_mode unshaded, cull_front;
uniform vec3 ink : source_color = vec3(0.07, 0.04, 0.11);
uniform vec3 fog_col : source_color = vec3(0.10, 0.07, 0.17);
uniform float fog_near = 18.0;
uniform float fog_far = 70.0;
void fragment() {
	float f = smoothstep(fog_near, fog_far, length(VERTEX));
	ALBEDO = mix(ink, fog_col, f);
}
"""

# Contorno per i modelli importati (glTF): la mesh si gonfia lungo le normali lisce nello shader.
const _INK_GROW: String = """
shader_type spatial;
render_mode unshaded, cull_front;
uniform float grow = 0.022;
uniform vec3 ink : source_color = vec3(0.07, 0.04, 0.11);
uniform vec3 fog_col : source_color = vec3(0.10, 0.07, 0.17);
uniform float fog_near = 18.0;
uniform float fog_far = 70.0;
void vertex() {
	VERTEX += NORMAL * grow;
}
void fragment() {
	float f = smoothstep(fog_near, fog_far, length(VERTEX));
	ALBEDO = mix(ink, fog_col, f);
}
"""

const _GLOW: String = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
void fragment() {
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a;
}
"""

const _SHADOW: String = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
void fragment() {
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a;
}
"""

static var _cache: Dictionary = {}


static func _shader_mat(key: String, code: String) -> ShaderMaterial:
	if _cache.has(key):
		return _cache[key]
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	if key == "glow" or key == "shadow":
		m.render_priority = 1
	_cache[key] = m
	return m


static func body() -> ShaderMaterial:
	return _shader_mat("body", _BODY)


static func ink() -> ShaderMaterial:
	return _shader_mat("ink", _INK)


static func ink_grow() -> ShaderMaterial:
	return _shader_mat("ink_grow", _INK_GROW)


static func glow() -> ShaderMaterial:
	return _shader_mat("glow", _GLOW)


static func shadow() -> ShaderMaterial:
	return _shader_mat("shadow", _SHADOW)


# Bianco pieno per il lampo di "colpito" (si mette come override sulle parti per un attimo).
static func hit_flash() -> StandardMaterial3D:
	if _cache.has("flash"):
		return _cache["flash"]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.97, 0.92)
	_cache["flash"] = m
	return m


# Nebbia: ogni scena sceglie colore e distanze (la strada e' lunga, l'arena e' corta).
static func set_fog(col: Color, near: float, far: float) -> void:
	for m in [body(), ink(), ink_grow()]:
		m.set_shader_parameter("fog_col", Vector3(col.r, col.g, col.b))
		m.set_shader_parameter("fog_near", near)
		m.set_shader_parameter("fog_far", far)


# Applica i materiali a una mesh costruita da MeshBatch (superficie 0 corpo, 1 contorno).
static func dress(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	for i in mi.mesh.get_surface_count():
		mi.set_surface_override_material(i, body() if i == 0 else ink())
