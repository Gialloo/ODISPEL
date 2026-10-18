class_name Toon
extends RefCounted

# Materiali toon condivisi della V3. Tutto e' UNSHADED: niente luci in tempo reale, niente ombre, niente cielo.
# L'ombreggiatura a due toni si calcola nello shader con una direzione di luce fissa: costa poco ed e' uguale su ogni telefono.
# Colore dei vertici: rgb = colore, alpha = 1 normale, 0.8 pelle, 0.6 piatto, 0.4 METALLO (bande chiare fisse), 0 "luce propria".
# Il metallo a bande e' l'eccezione approvata in docs/STILE_VISIVO.md (resa dei primi Final Fantasy).
# Contorni: guscio rovesciato (mesh gonfiata, cull_front) in una seconda superficie della stessa mesh, NON next_pass.

const INK: Color = Color(0.07, 0.04, 0.11)
const METAL_A: float = 0.4          # alpha del colore dei vertici per il metallo a bande

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
	// alpha: 1 normale (ombra fredda) · 0.8 pelle (ombra calda) · 0.6 piatto (viso) · 0.4 metallo · 0 luce propria
	if (COLOR.a > 0.3 && COLOR.a < 0.5) {
		// METALLO lucido alla primi Final Fantasy: base scura e 2-3 bande chiare fisse che seguono la forma (vista dalla camera)
		vec3 vn = normalize(NORMAL);
		float m = vn.y * 0.75 + vn.x * 0.35;
		vec3 dk = base * 0.3 + vec3(0.02, 0.025, 0.07);
		c = dk;
		c = mix(c, base * 1.05, smoothstep(-0.05, 0.0, m) * (1.0 - smoothstep(0.32, 0.37, m)));
		c = mix(c, mix(base, vec3(1.0), 0.75), smoothstep(0.42, 0.46, m) * (1.0 - smoothstep(0.62, 0.66, m)));
		c = mix(c, base * 0.75, smoothstep(0.66, 0.7, m));
		c = mix(c, mix(base, vec3(0.85, 0.8, 1.0), 0.5), smoothstep(-0.62, -0.58, m) * (1.0 - smoothstep(-0.45, -0.41, m)));
		float r2 = 1.0 - clamp(dot(vn, normalize(VIEW)), 0.0, 1.0);
		c = mix(c, vec3(1.0, 0.95, 1.0), step(0.86, r2) * 0.55);
	} else if (COLOR.a > 0.7) {
		float nl = dot(normalize(wn), normalize(light_dir));
		float lit = smoothstep(-0.03, 0.05, nl);
		vec3 tint = COLOR.a > 0.9 ? shade_tint : vec3(0.88, 0.64, 0.70);
		c = mix(base * tint, base, lit);
		float r = 1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
		c = mix(c, rim_col, step(0.80, r) * rim_k * lit);
	}
	float d = length(VERTEX);
	float f = smoothstep(fog_near, fog_far, d) * (COLOR.a > 0.3 ? 1.0 : 0.55);
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

# Modelli con texture (TRELLIS.2 + Mixamo): stesso toon a due toni, il colore viene dalla texture del modello.
# Le parti molto chiare e poco sature della texture (l'argento) prendono le bande del metallo (eccezione approvata).
const _BODY_TEX: String = """
shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec4 albedo_col : source_color = vec4(1.0);
uniform vec3 light_dir = vec3(-0.45, 0.85, 0.35);
uniform vec3 shade_tint : source_color = vec3(0.50, 0.46, 0.80);
uniform vec3 rim_col : source_color = vec3(1.0, 0.82, 0.95);
uniform float rim_k = 0.32;
uniform float metal_k = 1.0;
uniform vec3 fog_col : source_color = vec3(0.10, 0.07, 0.17);
uniform float fog_near = 18.0;
uniform float fog_far = 70.0;
varying vec3 wn;
void vertex() {
	wn = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}
void fragment() {
	vec3 base = texture(albedo_tex, UV).rgb * albedo_col.rgb;
	float nl = dot(normalize(wn), normalize(light_dir));
	float lit = smoothstep(-0.03, 0.05, nl);
	vec3 c = mix(base * shade_tint, base, lit);
	float mx = max(base.r, max(base.g, base.b));
	float mn = min(base.r, min(base.g, base.b));
	float metal = step(0.55, mx) * (1.0 - step(0.12, mx - mn)) * metal_k;
	vec3 vn = normalize(NORMAL);
	float m = vn.y * 0.75 + vn.x * 0.35;
	vec3 band = base * 0.3 + vec3(0.02, 0.025, 0.07);
	band = mix(band, base * 1.05, smoothstep(-0.05, 0.0, m) * (1.0 - smoothstep(0.32, 0.37, m)));
	band = mix(band, mix(base, vec3(1.0), 0.75), smoothstep(0.42, 0.46, m) * (1.0 - smoothstep(0.62, 0.66, m)));
	c = mix(c, band, metal);
	float r = 1.0 - clamp(dot(vn, normalize(VIEW)), 0.0, 1.0);
	c = mix(c, rim_col, step(0.80, r) * rim_k * lit);
	float f = smoothstep(fog_near, fog_far, length(VERTEX));
	ALBEDO = mix(c, fog_col, f);
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


# Materiale toon per una superficie con texture (un materiale nuovo per texture: la texture e' un parametro)
static func body_tex(tex: Texture2D, tint: Color = Color.WHITE) -> ShaderMaterial:
	var key: String = "body_tex_shader"
	if not _cache.has(key):
		var sh := Shader.new()
		sh.code = _BODY_TEX
		_cache[key] = sh
	var m := ShaderMaterial.new()
	m.shader = _cache[key]
	if tex != null:
		m.set_shader_parameter("albedo_tex", tex)
	m.set_shader_parameter("albedo_col", tint)
	track(m)
	return m


# Un materiale fuori dalla cache (texture, contorno con spessore proprio): riceve anche lui la nebbia della scena
static func track(m: ShaderMaterial) -> void:
	var arr: Array = _cache.get("tex_mats", [])
	arr.append(weakref(m))
	_cache["tex_mats"] = arr
	_fog_one(m)


static func _fog_one(m: ShaderMaterial) -> void:
	if _cache.has("fog"):
		var f: Array = _cache["fog"]
		m.set_shader_parameter("fog_col", f[0])
		m.set_shader_parameter("fog_near", f[1])
		m.set_shader_parameter("fog_far", f[2])


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
	_cache["fog"] = [Vector3(col.r, col.g, col.b), near, far]
	for m in [body(), ink(), ink_grow()]:
		_fog_one(m)
	var alive: Array = []
	for w in _cache.get("tex_mats", []):
		var m2: Variant = (w as WeakRef).get_ref()
		if m2 != null:
			_fog_one(m2)
			alive.append(w)
	_cache["tex_mats"] = alive


# Applica i materiali a una mesh costruita da MeshBatch (superficie 0 corpo, 1 contorno).
static func dress(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	for i in mi.mesh.get_surface_count():
		mi.set_surface_override_material(i, body() if i == 0 else ink())
