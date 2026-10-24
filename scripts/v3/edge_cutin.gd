class_name EdgeCutin
extends Control

# Cut-in "alla Edgerunners" (ricetta di un reel di Epoh, TouchDesigner + MediaPipe) con il personaggio 3D al posto della persona.
# Perche' cosi': tutto vive in viewport a ~640x360 accese SOLO durante il cut-in (telefono: pochi pixel da riempire),
# poi l'intero nodo viene liberato. Composizione dal fondo: retino -> raggi -> solidi -> fiamme -> persona.
# Per estenderlo agli altri personaggi basta un'altra palette (colori come parametri) e l'id del personaggio.
#   var e := EdgeCutin.new(); parent.add_child(e); e.start("nox", EdgeCutin.PAL_NOX)

const H: int = 360                       # altezza di lavoro delle viewport
const SOLIDS_FULL: int = 188             # come nel video: 8 tipi, 188 pezzi
const SOLIDS_LIGHT: int = 64             # effetti ridotti
const DURATA: float = 1.4

const PAL_NOX: Dictionary = {
	"sky": Color("#7fd0ff"), "mid": Color("#1f5cff"), "navy": Color("#0b1370"),      # persona: azzurro in alto, blu notte in basso
	"rim": Color("#ff9d1f"), "coral": Color("#ff5f80"), "line": Color("#060828"),    # bordo caldo, linea glitch, tratto scuro
	"top": Color("#2cc8ff"), "bottom": Color("#8a3fe0"), "dark": Color("#05050d"),   # retino: ciano in alto, viola in basso
	"ray": Color("#ffe21f"),
	"flames": [Color("#ffe21f"), Color("#ff8a1a"), Color("#ff3d9e")],               # giallo, arancione, magenta
	"solids": [Color("#ff2d4f"), Color("#ffd51f"), Color("#27b9ff"), Color("#8a3fe0"), Color("#ff5aa8"), Color("#2fdc8a")],
}

var _pal: Dictionary = PAL_NOX
var _char: String = ""
var _light: bool = false
var _w: int = 640
var _t: float = 0.0
var manual: bool = false                 # nei test il tempo lo decide la prova
var _tick: int = -1

var _vp_person: SubViewport
var _vp_solids: SubViewport
var _vp_comp: SubViewport
var _cv: CharacterVisual
var _cam_p: Camera3D
var _bg: ColorRect
var _solids_rect: TextureRect
var _flames: ColorRect
var _person: TextureRect
var _flash: ColorRect
var _mmis: Array = []
var _pieces: Array = []                  # un dizionario per pezzo: mesh, indice, direzione, raggio, rotazione, scala
var _origin: Vector3 = Vector3.ZERO
var _mat_p: ShaderMaterial
var _mat_bg: ShaderMaterial
var _mat_fl: ShaderMaterial


# ------------------------------------------------------------------ shader

const SH_PERSON: String = """
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D src : filter_linear;
uniform int mode = 2;                    // 0 maschera, 1 bianco e nero piatto, 2 colorata
uniform bool kuw = true;
uniform vec3 sky : source_color;
uniform vec3 mid : source_color;
uniform vec3 navy : source_color;
uniform vec3 rim_c : source_color;
uniform vec3 coral_c : source_color;
uniform vec3 line_c : source_color;
uniform float glitch = 0.0;
uniform float tq = 0.0;

float M(vec2 p) { return step(0.5, textureLod(src, p, 0.0).a); }
float Lr(vec2 p, float c) {
	vec4 s = textureLod(src, p, 0.0);
	return s.a > 0.5 ? dot(s.rgb, vec3(0.299, 0.587, 0.114)) : c;
}

// Kuwahara a 4 settori (3x3 campioni ciascuno, passo 2 px): sceglie il settore piu' uniforme e ne prende la media
float kuwahara(vec2 uv, float c, vec2 px) {
	float best = 1e9;
	float res = c;
	for (int s = 0; s < 4; s++) {
		vec2 o = vec2((s % 2 == 0) ? -1.0 : 1.0, (s < 2) ? -1.0 : 1.0);
		float sum = 0.0;
		float sq = 0.0;
		for (int i = 0; i < 3; i++) {
			for (int j = 0; j < 3; j++) {
				float v = Lr(uv + o * vec2(float(i), float(j)) * 2.0 * px, c);
				sum += v;
				sq += v * v;
			}
		}
		float mean = sum / 9.0;
		float var_ = sq / 9.0 - mean * mean;
		if (var_ < best) {
			best = var_;
			res = mean;
		}
	}
	return res;
}

void fragment() {
	vec2 px = 1.0 / vec2(textureSize(src, 0));
	float m = M(UV);
	vec4 outc = vec4(0.0);
	if (mode == 0) {
		outc = vec4(1.0, 1.0, 1.0, m);
	} else if (m < 0.5) {
		if (mode == 2) {
			// linea corallo: la sagoma sfasata (e a fasce, a scatti) che spunta dal contorno
			float band = step(0.9, fract(UV.y * 5.0 + tq * 0.37));
			vec2 cu = UV - vec2(-(3.5 + 12.0 * band * glitch), 2.0) * px;
			float ms = M(cu);
			float edge = ms * (1.0 - M(cu + vec2(2.5, 0.0) * px) * M(cu - vec2(2.5, 0.0) * px) * M(cu + vec2(0.0, 2.5) * px) * M(cu - vec2(0.0, 2.5) * px));
			outc = vec4(coral_c, edge);
		}
	} else {
		float c = Lr(UV, 0.5);
		float tone = kuw ? kuwahara(UV, c, px) : c;
		tone = clamp(pow(tone, 0.6) * 1.35, 0.0, 1.0);
		tone = floor(tone * 4.0 + 0.5) / 4.0;                                 // toni piatti da anime
		if (mode == 1) {
			outc = vec4(vec3(tone), 1.0);
		} else {
			float g = clamp((UV.y - 0.1) / 0.75, 0.0, 1.0);                    // 0 = in alto, 1 = in basso
			vec3 lightc = mix(sky, mid, g);
			vec3 darkc = mix(mid * 0.55, navy, g);
			vec3 col = mix(darkc, lightc, smoothstep(0.2, 0.85, tone));
			// linee scure dall'immagine originale: differenza di gaussiane (sfocatura stretta meno sfocatura larga)
			float b1 = (Lr(UV + vec2(px.x, 0.0), c) + Lr(UV - vec2(px.x, 0.0), c) + Lr(UV + vec2(0.0, px.y), c) + Lr(UV - vec2(0.0, px.y), c) + c) / 5.0;
			float b2 = 0.0;
			for (int k = 0; k < 8; k++) {
				float an = float(k) * 0.7853982;
				b2 += Lr(UV + vec2(cos(an), sin(an)) * 3.0 * px, c);
			}
			b2 = b2 / 8.0;
			col = mix(col, line_c, step(0.05, b2 - b1));
			// bordo caldo su un lato (alto a sinistra) e contorno scuro sottile
			vec2 d = normalize(vec2(-1.0, -0.6)) * px;
			float rim = 1.0 - M(UV + d * 4.0) * M(UV + d * 8.0);
			col = mix(col, rim_c, rim);
			float cont = 1.0 - M(UV + vec2(px.x, 0.0) * 1.5) * M(UV - vec2(px.x, 0.0) * 1.5) * M(UV + vec2(0.0, px.y) * 1.5) * M(UV - vec2(0.0, px.y) * 1.5);
			col = mix(col, line_c, cont);
			outc = vec4(col, 1.0);
		}
	}
	COLOR = outc;
}
"""

const SH_BG: String = """
shader_type canvas_item;
render_mode unshaded;
uniform vec3 c_top : source_color;
uniform vec3 c_bot : source_color;
uniform vec3 ray_c : source_color;
uniform vec3 dark_c : source_color;
uniform float halftone_on = 1.0;
uniform float rays_on = 1.0;
uniform float tq = 0.0;
uniform float grow = 1.0;
uniform vec2 res = vec2(640.0, 360.0);
uniform vec2 center = vec2(0.56, 0.46);

float h1(float n) { return fract(sin(n * 127.1) * 43758.5453); }

void fragment() {
	vec3 col = dark_c;
	if (halftone_on > 0.5) {
		float g = UV.y;
		vec3 base = mix(c_top, c_bot, smoothstep(0.2, 0.9, g));
		// retino a 45 gradi: puntini piu' grossi verso i bordi e in basso
		vec2 q = mat2(vec2(0.7071, -0.7071), vec2(0.7071, 0.7071)) * FRAGCOORD.xy / 6.0;
		float rad = mix(0.16, 0.46, clamp(abs(g - 0.5) * 1.5 + 0.12 * sin(UV.x * 7.0), 0.0, 1.0));
		float dm = step(length(fract(q) - 0.5), rad);
		col = mix(base, base * vec3(0.5, 0.55, 0.9), dm);
	}
	if (rays_on > 0.5) {
		vec2 p = (UV - center) * vec2(res.x / res.y, 1.0);
		float a = atan(p.y, p.x) / 6.2831853 + 0.5 + tq * 0.011;
		float n = 24.0;
		float id = floor(a * n);
		float fr = fract(a * n);
		float on = step(0.45, h1(id + 3.0));
		on *= step(abs(fr - 0.5), mix(0.18, 0.5, h1(id + 9.0)));
		float len = (0.3 + 1.1 * h1(id + 5.0)) * grow;
		float r = length(p);
		on *= step(0.2, r) * step(r, len);
		col = mix(col, ray_c, on);
	}
	COLOR = vec4(col, 1.0);
}
"""

const SH_FLAME: String = """
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D mask : filter_linear;
uniform vec3 c1 : source_color;
uniform vec3 c2 : source_color;
uniform vec3 c3 : source_color;
uniform float r1 = 0.04;
uniform float r2 = 0.08;
uniform float r3 = 0.12;
uniform float tq = 0.0;
uniform float aspect = 1.78;

float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1.0, 0.0)), f.x), mix(h2(i + vec2(0.0, 1.0)), h2(i + vec2(1.0, 1.0)), f.x), f.y);
}

// fiamma piatta: dove la sagoma sta entro il raggio (disturbato dal rumore e spinto verso l'alto) si dipinge
float fl(vec2 uv, float R, float seed) {
	if (R <= 0.0) { return 0.0; }
	float n = vn(vec2(uv.x * 14.0 + seed, uv.y * 10.0 + tq * 5.0));
	vec2 w = vec2((n - 0.5) * 0.05, 0.0);
	float a = 0.0;
	for (int k = 0; k < 8; k++) {
		float an = float(k) * 0.7853982 + seed;
		vec2 d = vec2(cos(an) / aspect, sin(an) + 0.8) * R * (0.65 + 0.7 * n);
		a = max(a, textureLod(mask, uv + d + w, 0.0).a);
	}
	return step(0.5, a);
}

void fragment() {
	float f3 = fl(UV, r3, 1.0);
	float f2 = f3 * fl(UV, r2, 4.0);
	float f1 = f2 * fl(UV, r1, 7.0);
	COLOR = vec4(f1 > 0.5 ? c1 : (f2 > 0.5 ? c2 : c3), f3);
}
"""

const SH_SOLID: String = """
shader_type spatial;
render_mode unshaded, cull_disabled;
varying vec3 vn;
varying vec4 vc;
void vertex() {
	vn = normalize(mat3(MODELVIEW_MATRIX) * NORMAL);
	vc = COLOR;
}
void fragment() {
	// cel shading a tre toni con retino sulle facce in ombra (il retino segue lo schermo, non il pezzo)
	float nl = dot(normalize(vn), normalize(vec3(-0.4, 0.7, 0.6)));
	float tone = nl > 0.35 ? 1.0 : (nl > -0.25 ? 0.78 : 0.56);
	vec2 q = mat2(vec2(0.7071, -0.7071), vec2(0.7071, 0.7071)) * FRAGCOORD.xy / 3.5;
	float dm = step(length(fract(q) - 0.5), 0.3) * step(tone, 0.8);
	ALBEDO = vc.rgb * tone * (1.0 - 0.38 * dm);
}
"""


# ------------------------------------------------------------------ avvio

func start(char_id: String, pal: Dictionary = PAL_NOX) -> void:
	_char = char_id
	_pal = pal
	_light = Settings.light_fx
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.place(self, 0, 0, 1, 1)
	var vs: Vector2 = get_viewport().get_visible_rect().size
	_w = clampi(roundi(float(H) * vs.x / maxf(vs.y, 1.0)), 640, 860)
	_build_person_vp()
	_build_solids_vp()
	_build_comp()
	apply_time(0.0)


func _vp(w: int, h: int, three_d: bool) -> SubViewport:
	var v := SubViewport.new()
	v.size = Vector2i(w, h)
	v.transparent_bg = three_d
	v.own_world_3d = three_d
	v.disable_3d = not three_d
	v.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	v.msaa_3d = Viewport.MSAA_DISABLED
	v.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	add_child(v)
	return v


# 1. LA PERSONA: il personaggio da solo, sfondo trasparente (l'alfa e' la maschera)
func _build_person_vp() -> void:
	_vp_person = _vp(_w, H, true)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = e
	_vp_person.add_child(env)
	_cv = CharacterVisual.new()
	_cv.setup(_char)
	_vp_person.add_child(_cv)
	_cv.stance = true
	_cv.lean = 0.12
	_cv.arm_r_x = -2.7           # posa d'azione: pugno in alto, altro braccio teso
	_cv.arm_l_x = -0.9
	_cam_p = Camera3D.new()
	_cam_p.fov = 42.0
	_cam_p.near = 0.1
	_cam_p.far = 30.0
	_cam_p.h_offset = -0.25
	_vp_person.add_child(_cam_p)
	_cam_p.position = Vector3(0.3, 1.45, -2.1)
	_cam_p.look_at_from_position(_cam_p.position, Vector3(0.0, 1.3, 0.0), Vector3.UP)
	_cam_p.current = true


# 2. I SOLIDI: 8 tipi low-poly in MultiMesh, esplodono dal centro; li aggiorniamo a scatti
func _build_solids_vp() -> void:
	_vp_solids = _vp(_w, H, true)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	env.environment = e
	_vp_solids.add_child(env)
	var cam := Camera3D.new()
	cam.fov = 55.0
	cam.near = 0.5
	cam.far = 60.0
	_vp_solids.add_child(cam)
	cam.position = Vector3(0, 0, 9)
	cam.current = true
	var half_h: float = tan(deg_to_rad(27.5)) * 9.0
	_origin = Vector3(0.06 * 2.0 * half_h * float(_w) / float(H), 0.0, 0.0)
	var sh := Shader.new()
	sh.code = SH_SOLID
	var mat := ShaderMaterial.new()
	mat.shader = sh
	var total: int = SOLIDS_LIGHT if _light else SOLIDS_FULL
	var meshes: Array = _solid_meshes()
	var cols: Array = _pal["solids"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 2077
	for k in meshes.size():
		var n: int = total / meshes.size() + (1 if k < total % meshes.size() else 0)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = meshes[k]
		mm.instance_count = n
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = mat
		mi.custom_aabb = AABB(Vector3(-60, -60, -60), Vector3(120, 120, 120))
		_vp_solids.add_child(mi)
		_mmis.append(mm)
		for i in n:
			var az: float = rng.randf() * TAU
			var el: float = rng.randf_range(-0.9, 0.9)
			var dir := Vector3(cos(az) * cos(el), sin(el) * 0.75, clampf(sin(az) * cos(el), -0.8, 0.45)).normalized()
			var big: bool = rng.randf() < 0.07
			mm.set_instance_color(i, cols[rng.randi() % cols.size()])
			_pieces.append({
				"mm": mm, "i": i, "dir": dir,
				"r": rng.randf_range(2.6, 14.0),
				"s": rng.randf_range(1.1, 1.9) if big else rng.randf_range(0.14, 0.62),
				"axis": Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(0.1, 1)).normalized(),
				"w": rng.randf_range(2.0, 7.0), "a0": rng.randf() * TAU,
				"d": rng.randf_range(0.0, 0.12),
			})


func _build_comp() -> void:
	_vp_comp = _vp(_w, H, false)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp_comp.add_child(root)
	# 4. retino + 5. raggi (un solo shader)
	_mat_bg = _mat(SH_BG)
	_mat_bg.set_shader_parameter("c_top", _pal["top"])
	_mat_bg.set_shader_parameter("c_bot", _pal["bottom"])
	_mat_bg.set_shader_parameter("ray_c", _pal["ray"])
	_mat_bg.set_shader_parameter("dark_c", _pal["dark"])
	_mat_bg.set_shader_parameter("res", Vector2(_w, H))
	_bg = ColorRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.material = _mat_bg
	root.add_child(_bg)
	# 6. solidi
	_solids_rect = TextureRect.new()
	_solids_rect.texture = _vp_solids.get_texture()
	_solids_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_solids_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_solids_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_solids_rect)
	# 7. fiamme in tre strati
	var fc: Array = _pal["flames"]
	_mat_fl = _mat(SH_FLAME)
	_mat_fl.set_shader_parameter("mask", _vp_person.get_texture())
	_mat_fl.set_shader_parameter("c1", fc[0])
	_mat_fl.set_shader_parameter("c2", fc[1])
	_mat_fl.set_shader_parameter("c3", fc[2])
	_mat_fl.set_shader_parameter("aspect", float(_w) / float(H))
	_flames = ColorRect.new()
	_flames.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flames.material = _mat_fl
	root.add_child(_flames)
	# 3. persona: bianco e nero piatto (Kuwahara), poi gradiente + linee + bordo
	_mat_p = _mat(SH_PERSON)
	for k in ["sky", "mid", "navy"]:
		_mat_p.set_shader_parameter(k, _pal[k])
	_mat_p.set_shader_parameter("rim_c", _pal["rim"])
	_mat_p.set_shader_parameter("coral_c", _pal["coral"])
	_mat_p.set_shader_parameter("line_c", _pal["line"])
	_mat_p.set_shader_parameter("kuw", not _light)
	_mat_p.set_shader_parameter("src", _vp_person.get_texture())
	_person = TextureRect.new()
	_person.texture = _vp_person.get_texture()
	_person.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_person.stretch_mode = TextureRect.STRETCH_SCALE
	_person.set_anchors_preset(Control.PRESET_FULL_RECT)
	_person.material = _mat_p
	root.add_child(_person)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_flash)
	var show := TextureRect.new()
	show.texture = _vp_comp.get_texture()
	show.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	show.stretch_mode = TextureRect.STRETCH_SCALE
	show.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	show.mouse_filter = Control.MOUSE_FILTER_IGNORE
	show.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(show)


func _mat(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


# Per le prove: accende un livello alla volta. person: -1 nascosta, 0 maschera, 1 bianco e nero, 2 colorata
func set_layers(halftone: bool, rays: bool, solids: bool, flames: bool, person: int) -> void:
	_mat_bg.set_shader_parameter("halftone_on", 1.0 if halftone else 0.0)
	_mat_bg.set_shader_parameter("rays_on", 1.0 if rays else 0.0)
	_solids_rect.visible = solids
	_flames.visible = flames
	_person.visible = person >= 0
	if person >= 0:
		_mat_p.set_shader_parameter("mode", person)


func _process(delta: float) -> void:
	if manual:
		return
	_t += delta
	apply_time(_t)


# Il tempo del cut-in: mani e fiamme crescono, i solidi esplodono, shader a 12 fotogrammi al secondo
func apply_time(t: float) -> void:
	_t = t
	var tick: int = int(t * 12.0)
	var tq: float = float(tick) / 12.0
	var pop: float = clampf(t / 0.22, 0.0, 1.0)
	var ease_o: float = 1.0 - pow(1.0 - pop, 3.0)
	_cv.arm_r_x = lerpf(-0.6, -2.7, ease_o)
	_cv.arm_l_x = lerpf(-0.2, -0.9, ease_o)
	_cv.scale = Vector3.ONE * (1.0 + 0.12 * (1.0 - ease_o))
	_flash.color.a = clampf(1.0 - t / 0.12, 0.0, 1.0) * 0.9
	if tick == _tick:
		return
	_tick = tick
	var gl: float = 1.0 if fposmod(sin(float(tick) * 12.9898) * 43758.5453, 1.0) > 0.55 else 0.0
	_mat_p.set_shader_parameter("tq", tq)
	_mat_p.set_shader_parameter("glitch", gl)
	_mat_bg.set_shader_parameter("tq", tq)
	_mat_bg.set_shader_parameter("grow", clampf(0.3 + tq / 0.3, 0.3, 1.0))
	var ramp: float = smoothstep(0.0, 0.4, tq) * (1.0 + 0.1 * sin(float(tick) * 2.3))
	_mat_fl.set_shader_parameter("tq", tq)
	_mat_fl.set_shader_parameter("r1", 0.035 * ramp)
	_mat_fl.set_shader_parameter("r2", 0.07 * ramp)
	_mat_fl.set_shader_parameter("r3", 0.115 * ramp)
	_update_solids(tq)


func _update_solids(tq: float) -> void:
	for p in _pieces:
		var tt: float = maxf(tq - float(p["d"]), 0.0)
		var k: float = clampf(tt / 0.55, 0.0, 1.0)
		var e: float = 1.0 - pow(1.0 - k, 3.0)
		var dist: float = float(p["r"]) * (e + 0.25 * tt)
		var b := Basis(p["axis"], float(p["a0"]) + float(p["w"]) * tt)
		var s: float = float(p["s"]) * (0.25 + 0.75 * e) if tq >= float(p["d"]) else 0.0001
		b = b.scaled(Vector3.ONE * s)
		(p["mm"] as MultiMesh).set_instance_transform(int(p["i"]), Transform3D(b, _origin + (p["dir"] as Vector3) * dist))


# ------------------------------------------------------------------ solidi low-poly

func _solid_meshes() -> Array:
	var out: Array = []
	var tet: Array = [Vector3(1, 1, 1), Vector3(1, -1, -1), Vector3(-1, 1, -1), Vector3(-1, -1, 1)]
	out.append(_hull(tet, [[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]], 0.5))                       # tetraedro
	out.append(_hull([Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(-1, 1, -1), Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)],
		[[0, 1, 2, 3], [4, 5, 6, 7], [0, 1, 5, 4], [2, 3, 7, 6], [1, 2, 6, 5], [0, 3, 7, 4]], 0.5))  # cubo
	out.append(_hull([Vector3(-1, -0.8, -0.6), Vector3(1, -0.8, -0.6), Vector3(0, 0.9, -0.6), Vector3(-1, -0.8, 0.6), Vector3(1, -0.8, 0.6), Vector3(0, 0.9, 0.6)],
		[[0, 1, 2], [3, 4, 5], [0, 1, 4, 3], [1, 2, 5, 4], [0, 2, 5, 3]], 0.6))                    # prisma triangolare
	out.append(_hull([Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, -1, 1), Vector3(-1, -1, 1), Vector3(0, 1.2, 0)],
		[[0, 1, 2, 3], [0, 1, 4], [1, 2, 4], [2, 3, 4], [3, 0, 4]], 0.55))                         # piramide
	var oct: Array = [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	var of: Array = []
	for sx in [0, 1]:
		for sy in [2, 3]:
			for sz in [4, 5]:
				of.append([sx, sy, sz])
	out.append(_hull(oct, of, 0.6))                                                                # ottaedro
	var cr: Array = []
	for v in oct:
		cr.append(Vector3(v.x * 0.45, v.y * 1.7, v.z * 0.45))
	out.append(_hull(cr, of, 0.6))                                                                 # cristallo allungato
	out.append(_hull([Vector3(-1.4, -0.12, -0.8), Vector3(1.4, -0.12, -0.8), Vector3(1.4, 0.12, -0.8), Vector3(-1.4, 0.12, -0.8), Vector3(-1.4, -0.12, 0.8), Vector3(1.4, -0.12, 0.8), Vector3(1.4, 0.12, 0.8), Vector3(-1.4, 0.12, 0.8)],
		[[0, 1, 2, 3], [4, 5, 6, 7], [0, 1, 5, 4], [2, 3, 7, 6], [1, 2, 6, 5], [0, 3, 7, 4]], 0.5))  # lastra
	var tall: Array = []
	for v in tet:
		tall.append(Vector3(v.x * 0.7, v.y * 1.5, v.z * 0.7))
	out.append(_hull(tall, [[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]], 0.5))                      # tetraedro alto
	return out


# Mesh convessa a facce piatte: ogni faccia e' orientata verso l'esterno e ha la sua normale
func _hull(pts: Array, faces: Array, sc: float) -> ArrayMesh:
	var c := Vector3.ZERO
	for p in pts:
		c += p
	c /= float(pts.size())
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		var fc := Vector3.ZERO
		for i in f:
			fc += pts[i]
		fc /= float(f.size())
		for k in range(1, f.size() - 1):
			var a: Vector3 = pts[f[0]] * sc
			var b: Vector3 = pts[f[k]] * sc
			var d: Vector3 = pts[f[k + 1]] * sc
			var n: Vector3 = (b - a).cross(d - a).normalized()
			if n.dot((fc - c) * sc) < 0.0:
				n = -n
			for v in [a, b, d]:
				st.set_normal(n)
				st.add_vertex(v)
	return st.commit()
