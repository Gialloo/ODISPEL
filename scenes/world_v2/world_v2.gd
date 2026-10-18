extends Node3D

# MAPPA ESPLORABILE DEL TEST V2 (2.5D: ambiente 3D, personaggi 2D).
# Si arriva da SQUADRA V2. Il primo personaggio della front row cammina, gli altri due della front row lo seguono
# (la panchina non si vede). Si puo' solo: camminare, interagire con gli oggetti, subire incontri.
# Gli incontri (sorveglianti con "!") e il Distributore lanciano la battaglia V2; al ritorno la mappa ricorda chi e' stato battuto
# (WorldV2Ctx). Nessun salvataggio, nessun premio: e' un addestramento.
#
# Ambientazione: la citta' di ODISPEL (urban fantasy, notte). Piazza del Nodo (partenza), Via Elettra (LibraCorp),
# Vicolo delle Rondini (Magabondi), Via della Serranda (chiusa finche' non si battono i due sorveglianti) e il
# Largo del Distributore (l'Anomalia del Test V2). Vedi docs/MONDO.md.

const W: float = 1280.0
const H: float = 720.0
const SPEED: float = 4.4
const RADIUS: float = 0.35
const SPAWN: Vector2 = Vector2(0.0, 6.5)
const SIGHT: float = 6.5
const FOLLOW_GAP: float = 1.15
const CHAR_H: float = 2.0
const BOSS_POS: Vector2 = Vector2(0.0, -35.5)
const BOSS_AGGRO: float = 4.6
const CAM_OFF: Vector3 = Vector3(0.0, 19.0, 24.0)    # camera ortografica a ~38 gradi: nessuna distorsione di prospettiva
const CAM_SIZE: float = 11.5
const EXCL_MIN_SCALE: float = 0.05
const GATE_RECT: Rect2 = Rect2(-3.0, -15.4, 6.0, 0.8)

# Zone camminabili (x, z, larghezza, profondita'); z negativa = nord
const AREAS: Array = [
	{"name": "PIAZZA DEL NODO", "rect": Rect2(-9, -4, 18, 15)},
	{"name": "VIA ELETTRA", "rect": Rect2(9, -1, 14, 6)},
	{"name": "VICOLO DELLE RONDINI", "rect": Rect2(-23, 3, 14, 6)},
	{"name": "VIA DELLA SERRANDA", "rect": Rect2(-3, -26, 6, 22)},
	{"name": "LARGO DEL DISTRIBUTORE", "rect": Rect2(-10, -40, 20, 14)},
	{"name": "MERCATO NOTTURNO", "rect": Rect2(23, -7, 22, 16)},
	{"name": "TERRAZZA DEI TETTI", "rect": Rect2(32, -22, 8, 15)},
	{"name": "CORTILE DEI MAGABONDI", "rect": Rect2(-45, 0, 22, 14)},
	{"name": "GIARDINO DELLE RANE", "rect": Rect2(-42, -16, 12, 16)},
	{"name": "BOSCHETTO DEI SINISTRI", "rect": Rect2(-40, -30, 10, 14)},
	{"name": "PASSAGGIO DEL CANALE", "rect": Rect2(-4, 11, 8, 5), "open": [1]},
	{"name": "LUNGOCANALE", "rect": Rect2(-14, 16, 28, 8), "open": [1]},
	{"name": "BANCHINA DELLE LANTERNE", "rect": Rect2(14, 17, 12, 7), "open": [1]},
	{"name": "PONTE DEI DESIDERI", "rect": Rect2(26, 19.5, 14, 2.5), "open": [0, 1]},
	{"name": "ISOLOTTO DEL CILIEGIO", "rect": Rect2(40, 15, 10, 11), "open": [0, 1, 2, 3]},
]

const RUN_SPEED: float = 7.0
const VISTA_RECT: Rect2 = Rect2(33.0, -21.5, 6.0, 3.5)
const TINTS: Array = [Color("#ff9bd0"), Color("#7ff2ee"), Color("#ffb86b"), Color("#b79cff"), Color("#ffe97a"), Color("#ffc2e8"), Color("#a6f7c0"), Color("#9fd0ff"), Color("#ffd29a"), Color("#8f7fd6"), Color("#c9f06b"), Color("#ff9aa8"), Color("#8fe3ff"), Color("#ffd98a"), Color("#ff9bd0")]

const COLOR_RGB: Dictionary = {
	"rosso": Color("#ff5a4f"), "verde": Color("#4fd17a"), "blu": Color("#4f9bff"),
	"giallo": Color("#ffd23f"), "viola": Color("#a45cff"),
}

# STILE: fumetto pop (Gorillaz / The World Ends With You): colori saturi piatti, contorno nero spesso,
# ombre a due toni con retino, scritte da graffiti. Niente luci dinamiche (shader senza luce: piu' leggero su telefono).
const INK: Color = Color("#0b0814")
const POP: Array = [Color("#ff3d8b"), Color("#2ee6e6"), Color("#ffe14a"), Color("#ff8a3d"), Color("#8a5bff"), Color("#5dffb0")]
const CREAM: Color = Color("#fff3d6")

const HALFTONE_CODE: String = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV;
	float edge = max(abs(uv.x - 0.5), abs(uv.y - 0.5)) * 2.0;
	float k = smoothstep(0.62, 1.0, edge);
	vec2 q = FRAGCOORD.xy / 9.0;
	float dots = length(fract(q + vec2(0.25 * floor(q.y), 0.0)) - 0.5);
	float a = dots < 0.1 + 0.34 * k ? 0.42 * k : 0.0;
	COLOR = vec4(0.54, 0.1, 0.45, a);
}
"""

const TOON_CODE: String = """
shader_type spatial;
render_mode unshaded, cull_back;
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_tex = false;
uniform bool flat_color = false;
uniform bool use_vcol = false;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec3 light_dir = vec3(-0.5, 0.85, 0.45);
varying vec3 wn;
varying vec4 vcol;
void vertex() { wn = normalize((MODEL_NORMAL_MATRIX * NORMAL)); vcol = COLOR; }
void fragment() {
	vec3 c = albedo.rgb;
	if (use_vcol) { c *= vcol.rgb; }
	if (use_tex) { c *= texture(tex, UV * uv_scale).rgb; }
	if (!flat_color) {
		float d = dot(normalize(wn), normalize(light_dir));
		if (d > 0.6) { c = c; }
		else if (d > 0.05) { c = c * vec3(0.78, 0.72, 0.9); }
		else {
			vec2 q = FRAGCOORD.xy / 7.0;
			float dots = length(fract(q) - 0.5);
			vec3 sh = c * vec3(0.5, 0.4, 0.72);
			c = dots < 0.3 ? sh * 0.78 : sh;
		}
	}
	ALBEDO = c;
}
"""

const OUTLINE_CODE: String = """
shader_type spatial;
render_mode unshaded, cull_front;
uniform float w = 0.08;
void vertex() { VERTEX += sign(VERTEX) * w; }
void fragment() { ALBEDO = vec3(0.043, 0.031, 0.078); }
"""

const SKY_CODE: String = """
shader_type sky;
void sky() {
	float h = clamp(EYEDIR.y * 1.6 + 0.15, 0.0, 1.0);
	vec3 c = mix(vec3(1.0, 0.36, 0.62), vec3(0.2, 0.09, 0.46), smoothstep(0.0, 0.9, h));
	vec2 q = EYEDIR.xy * 90.0;
	float dots = length(fract(q) - 0.5);
	if (h > 0.25 && h < 0.7 && dots < 0.22 * (1.0 - abs(h - 0.47) * 3.5)) { c = mix(c, vec3(1.0, 0.88, 0.29), 0.85); }
	COLOR = c;
}
"""

var _toon_sh: Shader
var _line_sh: Shader
var _sprite_cache: Dictionary = {}
var test_move: Vector2 = Vector2.ZERO      # SOLO PER I TEST: movimento forzato
var mode: String = "walk"                  # walk, dialog, exclaim, approach, fade, pause
var player: Vector2 = SPAWN
var facing: float = 1.0
var roster: Dictionary = {}
var party: Array = []                      # id dei 3 della front row
var chars: Array = []                      # {"id", "node", "sprite", "shadow", "pos", "moving"}
var trail: Array = []
var trainers: Array = []
var talk_objs: Array = []                  # oggetti con cui si interagisce
var obstacles: Array = []                  # Rect2
var gate_node: Node3D
var gate_open: bool = false
var boss_node: Node3D
var boss_light: OmniLight3D
var boss_screen: MeshInstance3D
var cam: Camera3D
var _t: float = 0.0
var _moving: bool = false
var _last_zone: String = ""
var _zone_t: float = 0.0
var _lines: Array = []
var _line_i: int = 0
var _dialog_done: Callable = Callable()
var _last_adv: float = -10.0
var _enc: Dictionary = {}                  # incontro in corso
var _enc_t: float = 0.0
var _stick_idx: int = -1
var _stick_vec: Vector2 = Vector2.ZERO
var _near: Dictionary = {}                 # oggetto interagibile piu' vicino
var _wmats: Array = []
var _act_sig: String = ""
var _prev_fps: int = -1
var DISC_EXTRA: Array = []                 # scoperte che non sono oggetti (es. il panorama)
var _disc: Array = []                      # {did, pos, title, secret}
var _npcs: Array = []
var _spray_nodes: Dictionary = {}
var _vel: Vector2 = Vector2.ZERO
var _run_on: bool = false
var _dust: CPUParticles3D
var _cam_size_t: float = CAM_SIZE
var _vista_t: float = 0.0
var _sit_t: float = 0.0
var _sit_obj: Dictionary = {}
var _sit_drop: float = 0.0
var _banner_t: float = 0.0
var _mm_t: float = 0.0
var _complete_pending: bool = false
var banner: Label
var stat_label: Label
var minimap: MiniMap
var run_btn: Button

var ui: Control
var zone_label: Label
var obj_label: Label
var prompt: Label
var dlg: PanelContainer
var dlg_who: Label
var dlg_text: Label
var dlg_hint: Label
var pad: Pad
var act: ActBtn
var pause_btn: Button
var pause_menu: Control
var fade: ColorRect
var flash: ColorRect


class Pad extends Control:
	var base: Vector2 = Vector2.ZERO
	var knob: Vector2 = Vector2.ZERO
	var on: bool = false
	var home: Vector2 = Vector2(170, 540)
	const R: float = 95.0

	func _draw() -> void:
		var c: Vector2 = base if on else home
		var a: float = 0.9 if on else 0.55
		draw_circle(c + Vector2(6, 6), R, Color(0.04, 0.03, 0.08, 0.35 * a))
		draw_circle(c, R, Color(1.0, 0.95, 0.84, 0.28 * a + 0.1))
		draw_arc(c, R, 0.0, TAU, 48, Color(0.04, 0.03, 0.08, a), 6.0, true)
		var k: Vector2 = c + (knob if on else Vector2.ZERO)
		draw_circle(k, 44.0, Color(0.04, 0.03, 0.08, a))
		draw_circle(k, 36.0, Color(1.0, 0.24, 0.55, a))


class ActBtn extends Control:
	var label: String = ""
	var live: bool = false
	var pulse: float = 0.0

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var a: float = 1.0 if live else 0.6
		var k: float = 1.0 + (0.06 * sin(pulse * 6.0) if live else 0.0)
		draw_circle(c + Vector2(7, 7), 72.0 * k, Color(1.0, 0.24, 0.55, a))
		draw_circle(c, 72.0 * k, Color(0.04, 0.03, 0.08, a))
		draw_circle(c, 65.0 * k, Color(1.0, 0.88, 0.29, a) if live else Color(0.8, 0.78, 0.7, a))
		var f: Font = BattleTheme.display()
		var fs: int = 26
		var w: float = f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, c + Vector2(-w * 0.5, 9.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.04, 0.03, 0.08, 1.0))


# ---------------------------------------------------------------- avvio

func _exit_tree() -> void:
	if _prev_fps >= 0:
		Engine.max_fps = _prev_fps


func _ready() -> void:
	Settings.load_settings()
	# esplorazione leggera: sui telefoni senza limite scelto si ferma a 60 fotogrammi (meno calore e batteria che a 90/120)
	if OS.has_feature("mobile") and Settings.fps_limit == 0 and (Engine.max_fps == 0 or Engine.max_fps > 60):
		_prev_fps = Engine.max_fps
		Engine.max_fps = 60
	roster = RosterStore.load_or_new()
	var team: Array = roster.get("team", [])
	for i in range(mini(team.size(), BattleTypes.FRONT_SIZE)):
		party.append(str(team[i]))
	if party.is_empty():
		party = ["kira"]
	_build_env()
	_build_map()
	_disc_init()
	_build_party()
	if not chars.is_empty():
		_dust = _puffs(Vector3(0, 0.12, 0), CREAM, 10, 0.9, 0.3, 0.5, Vector3.ZERO, -1.0, 55.0)
		if _dust != null:
			_dust.reparent(chars[0]["node"], false)
			_dust.emitting = false
	_build_ui()
	for e in WorldV2Ctx.sprayed:
		_paint_tag(int(e["i"]), int(e["c"]))
	if WorldV2Ctx.pos != Vector2.INF:
		player = WorldV2Ctx.pos
		facing = WorldV2Ctx.facing
	_seed_trail()
	_apply_progress()
	_place_all()
	_visit_zones()
	_camera(1.0, true)
	var pend: String = WorldV2Ctx.pending
	if pend != "":
		var res: String = WorldV2Ctx.result
		WorldV2Ctx.pending = ""
		WorldV2Ctx.result = ""
		_after_battle(pend, res)
	elif not bool(WorldV2Ctx.read.get("intro", false)):
		WorldV2Ctx.read["intro"] = true
		_say([
			["CENTRALE · CAM-07", "Operatore, la squadra è sul posto. Anomalia segnalata al Largo del Distributore, a nord."],
			["CENTRALE · CAM-07", "La serranda di Via della Serranda è abbassata: serve il nulla osta di due sorveglianti della zona. Uno è in Via Elettra (est), l'altro nel Vicolo delle Rondini (ovest)."],
			["CENTRALE · CAM-07", "Non fatevi vedere a caso: chi vi nota vi mette alla prova. Buona fortuna."],
		])


# ---------------------------------------------------------------- ambiente

func _mat(c: Color, emit: float = 0.0, outline: float = 0.05) -> ShaderMaterial:
	if _toon_sh == null:
		_toon_sh = Shader.new()
		_toon_sh.code = TOON_CODE
		_line_sh = Shader.new()
		_line_sh.code = OUTLINE_CODE
	var m := ShaderMaterial.new()
	m.shader = _toon_sh
	m.set_shader_parameter("albedo", c)
	m.set_shader_parameter("flat_color", emit > 0.0)
	if outline > 0.0:
		var o := ShaderMaterial.new()
		o.shader = _line_sh
		o.set_shader_parameter("w", outline)
		m.next_pass = o
	return m


func _box(center: Vector3, size: Vector3, m: Material, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = center
	(parent if parent != null else self).add_child(mi)
	return mi


func _cyl(center: Vector3, radius: float, height: float, m: Material, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 14
	mi.mesh = cm
	mi.material_override = m
	mi.position = center
	(parent if parent != null else self).add_child(mi)
	return mi


func _text3d(text: String, pos: Vector3, size: int, col: Color, parent: Node = null, billboard: bool = false) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = BattleTheme.display()
	l.font_size = size
	l.pixel_size = 0.01
	l.modulate = col
	l.outline_size = 16
	l.outline_modulate = INK
	l.shaded = false
	l.double_sided = false
	if billboard:
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	(parent if parent != null else self).add_child(l)
	return l


func _build_env() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	var ssh := Shader.new()
	ssh.code = SKY_CODE
	sm.shader = ssh
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = CAM_SIZE
	cam.near = 0.1
	cam.far = 120.0
	cam.current = true
	add_child(cam)


# Facciata da fumetto: finestre con contorno nero, colori pieni, qualche striscia di graffiti
func _window_tex(seed_v: int) -> Texture2D:
	var img := Image.create(128, 256, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	img.fill(Color.WHITE)
	var fills: Array = [Color("#ffe14a"), Color("#2ee6e6"), Color("#ff3d8b"), Color("#3a2478"), Color("#3a2478"), Color("#fff3d6")]
	for row in range(6):
		for col in range(3):
			var x0: int = 10 + col * 38
			var y0: int = 24 + row * 38
			img.fill_rect(Rect2i(x0 - 3, y0 - 3, 30, 32), INK)
			img.fill_rect(Rect2i(x0, y0, 24, 26), fills[rng.randi() % fills.size()])
	img.fill_rect(Rect2i(0, 0, 128, 8), INK)
	img.fill_rect(Rect2i(0, 248, 128, 8), INK)
	# (la striscia 9..22 resta bianca: i tetti campionano li')
	return ImageTexture.create_from_image(img)


func _floor_tex() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	img.fill_rect(Rect2i(32, 0, 32, 32), Color(0.88, 0.88, 0.88))
	img.fill_rect(Rect2i(0, 32, 32, 32), Color(0.88, 0.88, 0.88))
	for i in range(64):
		for t in range(3):
			img.set_pixel(i, t, INK)
			img.set_pixel(t, i, INK)
	return ImageTexture.create_from_image(img)


func _blob_tex() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var d: float = Vector2(x - 31.5, y - 31.5).length() / 31.0
			img.set_pixel(x, y, Color(0.04, 0.02, 0.1, 0.6) if d < 1.0 else Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


func _in_walk(p: Vector2) -> bool:
	for a in AREAS:
		if (a["rect"] as Rect2).has_point(p):
			return true
	return false


func _build_map() -> void:
	_batch_begin()
	# strada: viola scuro pieno
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(240, 240)
	ground.mesh = pm
	ground.material_override = _mat(Color("#2a1458"), 1.0, 0.0)
	ground.position = Vector3(0, -0.02, 0)
	add_child(ground)
	# selciato a scacchi, un colore per zona (si capisce dove si e')
	var ftex: Texture2D = _floor_tex()
	var tints: Array = TINTS
	var ai: int = 0
	for a in AREAS:
		var r: Rect2 = a["rect"]
		var m: ShaderMaterial = _mat(tints[ai % tints.size()], 0.0, 0.0)
		m.set_shader_parameter("light_dir", Vector3(0, 1, 0))
		m.set_shader_parameter("use_tex", true)
		m.set_shader_parameter("tex", ftex)
		m.set_shader_parameter("uv_scale", Vector2(r.size.x / 2.0, r.size.y / 2.0))
		ai += 1
		var mi := MeshInstance3D.new()
		var q := PlaneMesh.new()
		q.size = r.size
		mi.mesh = q
		mi.material_override = m
		mi.position = Vector3(r.position.x + r.size.x * 0.5, 0.0, r.position.y + r.size.y * 0.5)
		add_child(mi)
	# strisce spesse gialle e nere nelle due vie
	var zz: float = -5.0
	while zz > -25.0:
		_bbox(Vector3(0, 0.03, zz), Vector3(0.45, 0.03, 1.3), Color("#ffe14a"), 0.0)
		zz -= 2.6
	var xx: float = 11.0
	while xx < 22.5:
		_bbox(Vector3(xx, 0.03, 2.0), Vector3(1.3, 0.03, 0.45), Color("#ffe14a"), 0.0)
		xx += 2.6
	_decals()
	# sole enorme da fumetto, in fondo al cielo
	var sun := MeshInstance3D.new()
	var sq := QuadMesh.new()
	sq.size = Vector2(46, 46)
	sun.mesh = sq
	var sunm: ShaderMaterial = _mat(Color("#ffe14a"), 1.0, 0.0)
	sun.material_override = sunm
	sun.position = Vector3(-18, 28, -85)
	add_child(sun)
	# edifici ai bordi
	for i in range(3):
		_wmats.append(_window_tex(11 + i * 7))
	_build_walls()
	# fontana al centro della piazza
	_cyl(Vector3(0, 0.25, 3), 1.5, 0.5, _mat(Color("#ff3d8b"), 0.0, 0.08))
	_cyl(Vector3(0, 0.52, 3), 1.25, 0.06, _mat(Color("#2ee6e6"), 1.0, 0.0))
	_cyl(Vector3(0, 0.9, 3), 0.18, 0.8, _mat(Color("#ffe14a"), 0.0, 0.05))
	obstacles.append(Rect2(-1.5, 1.5, 3.0, 3.0))
	_lamp(Vector3(-5.5, 0, 6.5), Color("#ffd98a"), true)
	_lamp(Vector3(5.5, 0, 6.5), Color("#ffd98a"), true)
	_lamp(Vector3(0, 0, -7.0), Color("#8fe9ff"), true)
	_lamp(Vector3(0, 0, -22.0), Color("#ffd98a"), false)
	_lamp(Vector3(-6.0, 0, -30.0), Color("#ffd98a"), false)
	_lamp(Vector3(6.0, 0, -30.0), Color("#ffd98a"), false)
	_props()
	_expansion()
	_batch_flush()
	_gate()
	_boss_machine()
	_trainers()


# Macchie di vernice e stelle sul selciato (stesso linguaggio delle pennellate della HUD di battaglia)
func _splat_tex(col: Color, seed_v: int) -> Texture2D:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var blobs: Array = []
	for i in range(7):
		var a: float = rng.randf() * TAU
		var d: float = rng.randf() * 26.0
		blobs.append([Vector2(64, 64) + Vector2(cos(a), sin(a)) * d, 14.0 + rng.randf() * 18.0])
	for y in range(128):
		for x in range(128):
			var best: float = 999.0
			for b in blobs:
				best = minf(best, Vector2(x, y).distance_to(b[0]) - float(b[1]))
			if best < 0.0:
				img.set_pixel(x, y, col)
			elif best < 4.0:
				img.set_pixel(x, y, INK)
	return ImageTexture.create_from_image(img)


func _decal(c2: Vector2, size: float, col: Color, seed_v: int, rot: float = 0.0) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.orientation = PlaneMesh.FACE_Y
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = _splat_tex(col, seed_v)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	mi.position = Vector3(c2.x, 0.015, c2.y)
	mi.rotation.y = rot
	add_child(mi)


func _decals() -> void:
	_decal(Vector2(-4.5, 2.0), 4.2, Color("#ff3d8b"), 3)
	_decal(Vector2(5.0, 7.5), 3.4, Color("#2ee6e6"), 8, 0.8)
	_decal(Vector2(-1.0, 8.5), 2.6, Color("#ffe14a"), 5, 2.0)
	_decal(Vector2(14.0, 1.0), 3.6, Color("#8a5bff"), 11)
	_decal(Vector2(-15.0, 6.0), 3.8, Color("#ff8a3d"), 17, 1.1)
	_decal(Vector2(1.5, -19.0), 3.0, Color("#ff3d8b"), 23, 0.4)
	_decal(Vector2(-3.0, -31.0), 4.4, Color("#2ee6e6"), 29)
	_decal(Vector2(4.0, -36.0), 3.6, Color("#ff3d8b"), 31, 2.2)
	# strisce pedonali all'imbocco di Via della Serranda
	for i in range(6):
		_bbox(Vector3(-2.25 + i * 0.9, 0.03, -3.3), Vector3(0.55, 0.03, 1.6), CREAM, 0.0)


func _lamp(p: Vector3, c: Color, _with_light: bool) -> void:
	_bbox(p + Vector3(0, 1.6, 0), Vector3(0.14, 3.2, 0.14), INK, 0.04)
	_bbox(p + Vector3(0, 3.25, 0), Vector3(0.5, 0.26, 0.5), c, 0.06)


func _build_walls() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var names: Array = ["OSTERIA DA NINO", "TABACCHI 24H", "LIBRACORP", "FARMACIA", "RONDINI BAR", "MAGA·MARKET", "KAIROS?", "ELETTRO NODO", "NOODLE"]
	var sign_cols: Array = [Color("#2ee6e6"), Color("#ff3d8b"), Color("#ffe14a"), Color("#5dffb0")]
	var ni: int = 0
	var roof_m: ShaderMaterial = _mat(Color("#ff3d8b"), 0.0, 0.07)
	for a in AREAS:
		var r: Rect2 = a["rect"]
		# lato: 0 nord, 1 sud, 2 ovest, 3 est
		for side in range(4):
			if (a.get("open", []) as Array).has(side):
				continue
			var horizontal: bool = side < 2
			var length: float = r.size.x if horizontal else r.size.y
			var cur: float = 0.0
			while cur < length:
				var outside: Vector2 = _edge_point(r, side, cur + 0.5, 0.7)
				if _in_walk(outside):
					cur += 1.0
					continue
				var run_end: float = cur
				while run_end < length and not _in_walk(_edge_point(r, side, run_end + 0.5, 0.7)):
					run_end += 1.0
				# riempi la serie con edifici larghi 3..5.5
				var pos: float = cur
				while pos < run_end - 0.01:
					var w: float = minf(3.0 + rng.randf() * 2.5, run_end - pos)
					if run_end - pos - w < 1.5:
						w = run_end - pos
					var depth: float = 3.0 + rng.randf() * 2.0
					var h: float = 4.5 + rng.randf() * 4.0
					if side == 1:
						h = 0.55 + rng.randf() * 0.25         # davanti alla camera: fioriere/recinti sottili, non coprono la vista
						depth = 0.6
					var mid: Vector2 = _edge_point(r, side, pos + w * 0.5, depth * 0.5)
					# camera ortografica: un edificio alto coprirebbe lo spazio camminabile a nord di lui -> lo si abbassa
					if h > 1.2 and _occludes(mid, h):
						h = 0.55 + rng.randf() * 0.25
						depth = 0.6
						mid = _edge_point(r, side, pos + w * 0.5, depth * 0.5)
					var size3: Vector3 = Vector3(w, h, depth) if horizontal else Vector3(depth, h, w)
					var uvk := Vector2(maxf(1.0, w / 3.4), maxf(0.6, h / 6.8))
					var uvo := Vector2(rng.randf(), rng.randf() * 0.5)
					_batch_box(Vector3(mid.x, h * 0.5, mid.y), size3, POP[rng.randi() % POP.size()], uvk, uvo, 0.14)
					_batch_box(Vector3(mid.x, h + 0.1, mid.y), Vector3(size3.x + 0.2, 0.2, size3.z + 0.2), POP[(rng.randi() + 2) % POP.size()], Vector2.ZERO, Vector2.ZERO, 0.07)
					# insegna sulle facce rivolte a sud (le piu' visibili) e qualche volta sulle altre
					if side == 0 and h > 5.5 and w > 2.8 and rng.randf() < 0.55:
						var col: Color = sign_cols[ni % sign_cols.size()]
						var face: Vector2 = _edge_point(r, side, pos + w * 0.5, -0.05)
						_text3d(names[ni % names.size()], Vector3(face.x, 3.1, face.y), 42, col, self)
						ni += 1
					pos += w
				cur = run_end


# ---- edifici in un solo mesh (tutti i corpi) e un solo mesh di contorni: poche decine di disegni invece di centinaia ----
var _bst: SurfaceTool
var _ost: SurfaceTool


func _batch_begin() -> void:
	_bst = SurfaceTool.new()
	_bst.begin(Mesh.PRIMITIVE_TRIANGLES)
	_ost = SurfaceTool.new()
	_ost.begin(Mesh.PRIMITIVE_TRIANGLES)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color, uv: Array) -> void:
	# ordine dei vertici: oraria vista da fuori (convenzione di Godot)
	var tri: Array = [[a, b, c, 0, 1, 2], [a, c, d, 0, 2, 3]]
	for t in tri:
		var va: Vector3 = t[0]
		var vb: Vector3 = t[1]
		var vc: Vector3 = t[2]
		var ia: int = t[3]
		var ib: int = t[4]
		var ic: int = t[5]
		if (vb - va).cross(vc - va).dot(n) > 0.0:
			var tmp: Vector3 = vb
			vb = vc
			vc = tmp
			var ti: int = ib
			ib = ic
			ic = ti
		for pr in [[va, ia], [vb, ib], [vc, ic]]:
			st.set_normal(n)
			st.set_color(col)
			st.set_uv(uv[pr[1]])
			st.add_vertex(pr[0])


func _batch_box(c: Vector3, sz: Vector3, col: Color, uvk: Vector2, uvo: Vector2, outline: float) -> void:
	var hx: float = sz.x * 0.5
	var hy: float = sz.y * 0.5
	var hz: float = sz.z * 0.5
	var roof: bool = uvk == Vector2.ZERO
	var ru := Vector2(0.5, 0.075)
	# facce laterali: u lungo l'orizzontale, v in altezza (finestre ripetute); sopra/sotto: striscia bianca
	var faces: Array = [
		[Vector3(0, 0, 1), Vector3(-hx, -hy, hz), Vector3(hx, -hy, hz), Vector3(hx, hy, hz), Vector3(-hx, hy, hz), sz.x],
		[Vector3(0, 0, -1), Vector3(hx, -hy, -hz), Vector3(-hx, -hy, -hz), Vector3(-hx, hy, -hz), Vector3(hx, hy, -hz), sz.x],
		[Vector3(1, 0, 0), Vector3(hx, -hy, hz), Vector3(hx, -hy, -hz), Vector3(hx, hy, -hz), Vector3(hx, hy, hz), sz.z],
		[Vector3(-1, 0, 0), Vector3(-hx, -hy, -hz), Vector3(-hx, -hy, hz), Vector3(-hx, hy, hz), Vector3(-hx, hy, -hz), sz.z],
		[Vector3(0, 1, 0), Vector3(-hx, hy, hz), Vector3(hx, hy, hz), Vector3(hx, hy, -hz), Vector3(-hx, hy, -hz), 0.0],
		[Vector3(0, -1, 0), Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz), Vector3(hx, -hy, hz), Vector3(-hx, -hy, hz), 0.0],
	]
	for f in faces:
		var uv: Array
		if f[5] == 0.0 or roof:
			uv = [ru, ru, ru, ru]
		else:
			var u1: float = float(f[5]) / 3.4
			var v1: float = sz.y / 6.8
			uv = [Vector2(uvo.x, uvo.y + v1), Vector2(uvo.x + u1, uvo.y + v1), Vector2(uvo.x + u1, uvo.y), Vector2(uvo.x, uvo.y)]
		_quad(_bst, c + (f[1] as Vector3), c + (f[2] as Vector3), c + (f[3] as Vector3), c + (f[4] as Vector3), f[0], col, uv)
	if outline <= 0.0:
		return
	# contorno: stesso box ingrandito (si vede solo il retro, dietro al corpo)
	var e := Vector3(outline, outline, outline)
	var ox: float = hx + e.x
	var oy: float = hy + e.y
	var oz: float = hz + e.z
	var ofaces: Array = [
		[Vector3(0, 0, 1), Vector3(-ox, -oy, oz), Vector3(ox, -oy, oz), Vector3(ox, oy, oz), Vector3(-ox, oy, oz)],
		[Vector3(0, 0, -1), Vector3(ox, -oy, -oz), Vector3(-ox, -oy, -oz), Vector3(-ox, oy, -oz), Vector3(ox, oy, -oz)],
		[Vector3(1, 0, 0), Vector3(ox, -oy, oz), Vector3(ox, -oy, -oz), Vector3(ox, oy, -oz), Vector3(ox, oy, oz)],
		[Vector3(-1, 0, 0), Vector3(-ox, -oy, -oz), Vector3(-ox, -oy, oz), Vector3(-ox, oy, oz), Vector3(-ox, oy, -oz)],
		[Vector3(0, 1, 0), Vector3(-ox, oy, oz), Vector3(ox, oy, oz), Vector3(ox, oy, -oz), Vector3(-ox, oy, -oz)],
		[Vector3(0, -1, 0), Vector3(-ox, -oy, -oz), Vector3(ox, -oy, -oz), Vector3(ox, -oy, oz), Vector3(-ox, -oy, oz)],
	]
	var z4: Array = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	for f in ofaces:
		_quad(_ost, c + (f[1] as Vector3), c + (f[2] as Vector3), c + (f[3] as Vector3), c + (f[4] as Vector3), f[0], INK, z4)


func _bbox(center: Vector3, size: Vector3, col: Color, outline: float = 0.05) -> void:
	_batch_box(center, size, col, Vector2.ZERO, Vector2.ZERO, outline)


func _batch_flush() -> void:
	var body := MeshInstance3D.new()
	body.mesh = _bst.commit()
	var m: ShaderMaterial = _mat(Color.WHITE, 0.0, 0.0)
	m.set_shader_parameter("use_vcol", true)
	m.set_shader_parameter("use_tex", true)
	m.set_shader_parameter("tex", _wmats[0])
	body.material_override = m
	add_child(body)
	var line := MeshInstance3D.new()
	line.mesh = _ost.commit()
	var lm := ShaderMaterial.new()
	lm.shader = _line_sh
	lm.set_shader_parameter("w", 0.0)
	line.material_override = lm
	add_child(line)


func _occludes(c: Vector2, h: float) -> bool:
	# vista dall'alto a ~38 gradi un edificio alto h copre circa 1.3*h metri di suolo a nord di lui
	for k in range(2, int(h * 1.3) + 3):
		if _in_walk(Vector2(c.x, c.y - float(k))):
			return true
	return false


func mid_z_of(r: Rect2, side: int, along: float) -> float:
	return _edge_point(r, side, along, 0.0).y


# punto a distanza `out` fuori dal lato `side` del rettangolo, a `along` dall'inizio del lato
func _edge_point(r: Rect2, side: int, along: float, out: float) -> Vector2:
	match side:
		0: return Vector2(r.position.x + along, r.position.y - out)
		1: return Vector2(r.position.x + along, r.end.y + out)
		2: return Vector2(r.position.x - out, r.position.y + along)
	return Vector2(r.end.x + out, r.position.y + along)


func _prop(c2: Vector2, size3: Vector3, col: Color, emit: float = 0.0, collide: bool = true) -> void:
	_bbox(Vector3(c2.x, size3.y * 0.5, c2.y), size3, col)
	if collide:
		obstacles.append(Rect2(c2.x - size3.x * 0.5, c2.y - size3.z * 0.5, size3.x, size3.z))


func _props() -> void:
	# distributore guasto (la prima cosa che si vede: avvisa del tono)
	_prop(Vector2(-6.4, -3.3), Vector3(0.95, 1.9, 0.8), Color("#ff3d8b"))
	_bbox(Vector3(-6.4, 1.15, -2.88), Vector3(0.7, 1.0, 0.05), Color("#ffcf5a"))
	_text3d("NON SPINGERE", Vector3(-6.4, 1.8, -2.87), 22, Color("#fff1c0"))
	_talk("vend", Vector2(-6.4, -2.4), "Distributore guasto", [
		["", "Un distributore spento. Sul display, a intermittenza: «NON SPINGERE»."],
		["", "Dentro, dietro il vetro, qualcosa si muove piano. Meglio non insistere."]])
	# bacheca dei Rondini
	_prop(Vector2(4.6, -3.4), Vector3(2.0, 1.6, 0.18), Color("#ffb86b"))
	_text3d("RONDINI · TURNI", Vector3(4.6, 1.95, -3.3), 24, Color("#ffd23f"))
	_talk("bacheca", Vector2(4.6, -2.5), "Bacheca dei Rondini", [
		["", "Turni di ronda scritti a mano: «Notte di giovedì — Piazza del Nodo — in piccoli gruppi, senza dare nell'occhio»."],
		["", "In un angolo, a pennarello: «LibraCorp ha ricominciato a controllare le licenze. Occhio a Via Elettra»."]])
	# tombino fumante
	var mh := _cyl(Vector3(3.2, 0.03, 7.0), 0.6, 0.05, _mat(Color("#0b0814")))
	mh.name = "Tombino"
	_cyl(Vector3(3.2, 0.06, 7.0), 0.42, 0.03, _mat(Color("#ff8a3d"), 1.1))
	_puffs(Vector3(3.2, 0.2, 7.0), Color("#ff8a3d"), 8, 1.1, 0.4, 1.4)
	_talk("tombino", Vector2(3.2, 7.0), "Tombino", [
		["", "Il tombino è tiepido. Un filo di vapore arancione esce dalle fessure e profuma di ferro."],
		["", "Le Anomalie urbane, di notte, preferiscono i posti dove la gente non guarda."]], 1.5)
	# semaforo che lampeggia (via Elettra)
	_prop(Vector2(9.9, -0.3), Vector3(0.18, 3.2, 0.18), Color("#0b0814"))
	_bbox(Vector3(9.9, 3.2, -0.3), Vector3(0.45, 1.1, 0.35), Color("#0b0814"))
	_bbox(Vector3(9.9, 3.55, -0.1), Vector3(0.2, 0.2, 0.05), Color("#ff5a4f"))
	_bbox(Vector3(9.9, 3.2, -0.1), Vector3(0.2, 0.2, 0.05), Color("#ffd23f"))
	_bbox(Vector3(9.9, 2.85, -0.1), Vector3(0.2, 0.2, 0.05), Color("#4fd17a"))
	_talk("semaforo", Vector2(10.0, 0.9), "Semaforo", [
		["", "Il semaforo lampeggia sul rosso da un'ora. Nessuno lo ha mai visto passare al verde."],
		["", "Forse è solo guasto. Forse no."]], 1.7)
	# cassonetti
	_prop(Vector2(12.0, -0.2), Vector3(0.9, 1.0, 0.7), Color("#2ee6e6"))
	_prop(Vector2(13.1, -0.2), Vector3(0.9, 1.0, 0.7), Color("#2ee6e6"))
	# panchine nella piazza
	_prop(Vector2(-6.0, 9.6), Vector3(2.0, 0.5, 0.6), Color("#ff8a3d"))
	_prop(Vector2(6.0, 9.6), Vector3(2.0, 0.5, 0.6), Color("#ff8a3d"))
	# rifugio dei Rondini (insegna in fondo alla piazza, verso la camera: solo un'insegna bassa)
	# cabina telefonica (fondo del vicolo)
	_prop(Vector2(-21.8, 5.5), Vector3(1.1, 2.4, 1.1), Color("#ff3d8b"))
	_bbox(Vector3(-21.25, 1.4, 5.5), Vector3(0.05, 1.6, 0.8), Color("#bfe9ff"))
	_talk("cabina", Vector2(-20.4, 5.5), "Cabina telefonica", [
		["", "La cornetta è sganciata. Dall'altra parte, qualcuno respira piano."],
		["", "Riattacchi. Il filo, notate, non è collegato a niente."]], 1.9)
	# casse e luci nel vicolo
	_prop(Vector2(-12.0, 3.7), Vector3(1.0, 0.8, 0.8), Color("#ffe14a"))
	_prop(Vector2(-18.5, 8.2), Vector3(1.0, 0.8, 0.8), Color("#ffe14a"))
	# terminale LibraCorp: la scheda del Distributore (cosa fa e come si contrasta)
	_prop(Vector2(2.35, -9.5), Vector3(0.8, 1.5, 0.6), Color("#8a5bff"))
	_bbox(Vector3(2.35, 1.2, -9.18), Vector3(0.6, 0.5, 0.05), Color("#4fe3ff"))
	_text3d("LIBRACORP\nSCHEDA ANOMALIA", Vector3(2.35, 1.95, -9.15), 20, Color("#4fe3ff"))
	_talk("terminale", Vector2(1.5, -9.5), "Terminale LibraCorp", _boss_card(), 2.0)
	# serranda: interazione con la serranda, il testo dipende dallo stato
	_talk("serranda", Vector2(0, -13.7), "Serranda", [], 2.4, {"nodid": true})


# ---------------------------------------------------------------- ESPANSIONE: nuove zone da girare senza meta
# I testi di queste zone sono BOZZE (atmosfera): non fissano la trama. Le uniche cose "vere" sono quelle di docs/MONDO.md.

const WATER_CODE: String = """
shader_type spatial;
render_mode unshaded;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float w = sin(wp.x * 0.9 + TIME * 0.8) + sin(wp.z * 1.3 - TIME * 0.6 + wp.x * 0.3);
	float band = step(0.35, w);
	float stripe = step(0.93, fract(wp.z * 0.35 + 0.15 * sin(wp.x * 0.5 + TIME * 0.5)));
	vec3 c = mix(vec3(0.10, 0.07, 0.36), vec3(0.12, 0.45, 0.80), band);
	c = mix(c, vec3(0.55, 0.95, 1.0), stripe * 0.8);
	ALBEDO = c;
}
"""


func _expansion() -> void:
	_water()
	_zone_piazza()
	_zone_mercato()
	_zone_terrazza()
	_zone_cortile()
	_zone_rane()
	_zone_boschetto()
	_zone_canale()
	_zone_isola()


func _water() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(106, 55)
	mi.mesh = pm
	var sh := Shader.new()
	sh.code = WATER_CODE
	var m := ShaderMaterial.new()
	m.shader = sh
	mi.material_override = m
	mi.position = Vector3(37, -0.005, 42.5)
	add_child(mi)


func _tree(x: float, z: float, col: Color, h: float = 1.5, w: float = 2.0) -> void:
	_prop(Vector2(x, z), Vector3(0.5, h, 0.5), Color("#6b3b2a"))
	_bbox(Vector3(x, h + 0.7, z), Vector3(w, 1.4, w), col, 0.08)
	_bbox(Vector3(x, h + 1.7, z), Vector3(w * 0.62, 0.9, w * 0.62), col.lightened(0.18), 0.08)


func _stall(x: float, z: float, body: Color, awn: Color, sign_txt: String) -> void:
	_prop(Vector2(x, z), Vector3(2.6, 1.0, 1.1), body)
	_bbox(Vector3(x, 2.25, z - 0.1), Vector3(3.0, 0.14, 1.7), awn, 0.06)
	_bbox(Vector3(x - 1.35, 1.1, z - 0.5), Vector3(0.1, 2.2, 0.1), INK, 0.03)
	_bbox(Vector3(x + 1.35, 1.1, z - 0.5), Vector3(0.1, 2.2, 0.1), INK, 0.03)
	_text3d(sign_txt, Vector3(x, 1.7, z + 0.62), 20, CREAM)


# panchina: ci si siede (la posizione "spot" e' davanti alla panchina)
func _bench(x: float, z: float, id: String, title: String, thoughts: Array, col: Color = Color("#ff8a3d")) -> void:
	_prop(Vector2(x, z), Vector3(2.0, 0.5, 0.6), col)
	_bbox(Vector3(x, 0.95, z - 0.25), Vector3(2.0, 0.55, 0.1), col.darkened(0.2))
	_talk(id, Vector2(x, z + 0.95), title, [], 1.3, {"sit": true, "thoughts": thoughts, "verb": "SIEDITI"})


func _rail(x0: float, x1: float, z: float) -> void:
	var cx: float = (x0 + x1) * 0.5
	_bbox(Vector3(cx, 1.0, z), Vector3(x1 - x0, 0.1, 0.12), CREAM, 0.04)
	_bbox(Vector3(cx, 0.12, z + 0.15), Vector3(x1 - x0, 0.24, 0.3), Color("#ffe14a"), 0.04)
	var x: float = x0
	while x <= x1 + 0.01:
		_bbox(Vector3(x, 0.5, z), Vector3(0.12, 1.0, 0.12), INK, 0.03)
		x += 2.0


func _zone_piazza() -> void:
	_talk("fontana", Vector2(0, 5.4), "Fontana", [
		["", "Sul fondo della fontana brillano monete di tutte le epoche e qualche gettone senza paese."],
		["", "Ne lanci una. Esprimi un desiderio. L'acqua, per un secondo, diventa rosa."]], 2.0)
	_bench(-6.0, 9.6, "panca_p1", "Panchina", [
		"Il quartiere respira piano. Si sente solo la fontana.",
		"Da qui la piazza sembra un disegno ancora da colorare.",
		"Ogni tanto una luce lampeggia, lontano. Poi torna il silenzio."])
	_bench(6.0, 9.6, "panca_p2", "Panchina", [
		"Un tombino fuma, una lampada ronza. Strani amici.",
		"Nessuno ti aspetta da nessuna parte. Che bella sensazione.",
		"Il sole di carta resta fisso lassù. Non tramonta mai."], Color("#2ee6e6"))
	_cat("gatto", "Gatto di quartiere", Vector2(-4.0, 8.2),
		[Vector2(-4, 8.2), Vector2(4, 8.5), Vector2(7, 4), Vector2(5, -1), Vector2(-5, -1), Vector2(-7, 5)],
		["Fa le fusa e ti sfiora una gamba. Poi se ne va, serissimo.", "Ti guarda, sbadiglia, ti perdona per qualcosa che non hai fatto.", "Si strofina sullo zaino. Ha deciso che sei suo."], false)
	_npc("passante", "Passante", Vector2(-7, -1.2), Color("#ffb86b"), Color("#2ee6e6"), false,
		[Vector2(-7, -1.2), Vector2(7, -1.2), Vector2(7.5, 8.5), Vector2(-7.5, 8.5)],
		["Porto l'ombrello anche quando non piove. Qui non si sa mai da cosa ripararsi.",
		 "Di sera la piazza è bellissima. Basta non guardare il distributore.",
		 "Ho sentito dire che al Largo, a nord, è comparsa un'Anomalia. Io passo di là domani. Forse."])


func _zone_mercato() -> void:
	_stall(25.5, -4.5, Color("#ff8a3d"), Color("#ffe14a"), "RAMEN 24H")
	_talk("ramen", Vector2(25.5, -3.2), "Banco del ramen", [
		["", "Un banco di ramen fumante. L'insegna dice «APERTO». Il cuoco dice «forse»."],
		["CUOCO", "Brodo di mezzanotte, uova di luna e un pizzico di niente. Offre la casa, ma solo con lo sguardo."]], 1.8)
	_stall(29.5, -4.5, Color("#8a5bff"), Color("#ff3d8b"), "MASCHERE")
	_talk("maschere", Vector2(29.5, -3.2), "Banco delle maschere", [
		["", "File di maschere di cartapesta appese: volpi, gufi, un faccione sorridente che ti segue con lo sguardo."],
		["", "«Servono per le sere in cui non vuoi essere riconosciuto», dice la bancarella. Sembra una cosa da Magabondi."]], 1.8)
	_stall(42.5, -4.5, Color("#2ee6e6"), Color("#ffe14a"), "AMULETI")
	_talk("amuleti", Vector2(42.5, -3.2), "Banco degli amuleti", [
		["", "Ciondoli, sassi forati, chiavi che non aprono nulla. Un cartello: «NON SONO MAGICI (GARANZIA LIBRACORP)»."],
		["", "Il cartello è stato aggiunto a pennarello. Sotto, in piccolo: «…o forse sì»."]], 1.8)
	# musicista di strada
	_npc("musicista", "Musicista", Vector2(36.5, 4.5), Color("#8a5bff"), Color("#ffe14a"), true, [],
		["Do-re-mi-fa… no, aspetta. Do-re-mi-fa-sol-la-si… Ecco. Questa l'ho scritta stanotte.",
		 "Suono per chi cammina senza una meta. Sono i miei clienti preferiti."], {"note": true, "title": "Musicista di strada"})
	_npc("cuffie", "Ragazza con le cuffie", Vector2(26, 6.5), Color("#ff3d8b"), Color("#5dffb0"), false,
		[Vector2(26, 6.5), Vector2(32, 7), Vector2(43, 7), Vector2(38, 0.5), Vector2(28, 0.5)],
		["Scusa, non ti sento: ho il volume a palla. …Ah, sì, il ramen è buono.",
		 "Il musicista oggi è in forma. Stasera fa pure il bis."])
	# distributore del mercato (battuta: questo e' innocuo)
	_prop(Vector2(43.8, 7.6), Vector3(0.95, 1.9, 0.8), Color("#5dffb0"))
	_text3d("TUTTO OK", Vector3(43.8, 1.8, 7.9), 20, CREAM)
	_talk("snack", Vector2(43.8, 6.7), "Distributore (tranquillo)", [
		["", "Un distributore. Spento? No. Acceso, ordinato, con un display che dice «TUTTO OK»."],
		["", "Compri una bibita. Esce una bibita. Nessuna Anomalia. Quasi commovente."]], 1.7)
	_prop(Vector2(44.2, -5.7), Vector3(1.0, 0.8, 0.8), Color("#ffe14a"))
	_prop(Vector2(24.2, 8.2), Vector3(1.0, 0.8, 0.8), Color("#ffe14a"))
	# lanterne appese e lampioni
	_bbox(Vector3(34, 3.3, -6.3), Vector3(21, 0.05, 0.05), INK, 0.0)
	var lx: float = 24.0
	var li: int = 0
	while lx < 45.0:
		_bbox(Vector3(lx, 3.0, -6.3), Vector3(0.32, 0.4, 0.32), POP[li % POP.size()], 0.05)
		lx += 1.4
		li += 1
	_lamp(Vector3(27.5, 0, 2.0), Color("#ffd98a"), false)
	_lamp(Vector3(35, 0, 1.0), Color("#8fe9ff"), false)
	_lamp(Vector3(43, 0, 2.0), Color("#ffd98a"), false)
	_decal(Vector2(30, 3), 3.4, Color("#ff3d8b"), 41, 0.3)
	_decal(Vector2(40, 2), 3.0, Color("#2ee6e6"), 43, 1.4)


func _zone_terrazza() -> void:
	for bx in [32.8, 39.2]:
		_prop(Vector2(bx, -14.0), Vector3(0.9, 0.5, 9.0), Color("#5dffb0"))
		var fz: float = -17.8
		var fi: int = 0
		while fz < -10.0:
			_bbox(Vector3(bx, 0.62, fz), Vector3(0.28, 0.2, 0.28), POP[fi % POP.size()], 0.03)
			fz += 1.5
			fi += 1
	_talk("fiori", Vector2(34.1, -14.0), "Aiuole", [
		["", "Fiori finti? No: veri. Piccoli, tosti, ostinati. Crescono fra le crepe del cemento."],
		["", "Qualcuno li innaffia ogni sera. Si vede dal modo in cui non sono morti."]], 1.6)
	_bench(36.0, -11.0, "panca_t", "Panchina sul tetto", [
		"Da qui il rumore del mercato arriva ovattato, come da un altro mondo.",
		"Sotto i piedi, la città. Sopra, un cielo fatto a puntini.",
		"Se resti fermo abbastanza, le luci iniziano a sembrare una canzone."], Color("#ffe14a"))
	_prop(Vector2(36, -19.6), Vector3(0.5, 1.3, 0.5), INK)
	_bbox(Vector3(36.4, 1.55, -19.6), Vector3(1.4, 0.34, 0.34), Color("#ff3d8b"), 0.05)
	_talk("telescopio", Vector2(36, -18.6), "Telescopio", [
		["", "Un telescopio a gettoni, già carico. Guardi: un puntino verde lontanissimo a nord, il Largo del Distributore."],
		["", "Sul tetto di fronte, un'insegna spenta a metà: «KAIROS?». Il punto interrogativo è dipinto a mano."]], 1.8)
	_npc("signora", "Signora delle piante", Vector2(38.0, -13.0), Color("#5dffb0"), Color("#ff8a3d"), false, [],
		["Pomodori sul tetto, a due passi dal cielo di cartapesta. Non chiedermi come.",
		 "Le piante crescono meglio con un po' di musica. Il musicista giù al mercato lo sa."], {"title": "Signora delle piante"})
	_lamp(Vector3(33.4, 0, -8.6), Color("#ffd98a"), false)
	_lamp(Vector3(38.6, 0, -8.6), Color("#ffd98a"), false)
	DISC_EXTRA.append({"did": "panorama", "pos": Vector2(36, -20), "title": "Panorama dal tetto", "secret": false})


func _zone_cortile() -> void:
	var xs: Array = [-43.2, -38.2, -33.2, -28.2]
	for i in range(xs.size()):
		var bx: float = xs[i]
		_prop(Vector2(bx, 3.0), Vector3(3.0, 2.2, 0.2), Color("#3a2a5e"))
		_bbox(Vector3(bx, 2.28, 3.0), Vector3(3.2, 0.14, 0.34), Color("#ffe14a"), 0.04)
		_talk("tag%d" % i, Vector2(bx, 4.5), "Muro da dipingere", [], 1.6, {"spray": i, "verb": "SPRUZZA"})
	_prop(Vector2(-27.5, 12.0), Vector3(0.9, 1.1, 0.9), Color("#6b4a8a"))
	_prop(Vector2(-24.8, 2.2), Vector3(0.9, 1.1, 0.9), Color("#6b4a8a"))
	_puffs(Vector3(-27.5, 1.2, 12.0), Color("#ff8a3d"), 8, 1.3, 0.35, 0.8)
	_puffs(Vector3(-24.8, 1.2, 2.2), Color("#ff8a3d"), 8, 1.3, 0.35, 0.8)
	_talk("bidone", Vector2(-27.5, 10.9), "Bidone acceso", [
		["", "Un bidone con il fuoco dentro, per scaldarsi. Intorno, scarpe spaiate e una cassetta di mele."],
		["", "Chi è passato qui non ha lasciato un nome: solo il calore."]], 1.6)
	_prop(Vector2(-35.0, 10.9), Vector3(2.4, 0.7, 0.9), Color("#ff3d8b"))
	_bbox(Vector3(-35.0, 1.1, 10.4), Vector3(2.4, 0.7, 0.2), Color("#c91f66"))
	_talk("divano", Vector2(-35.0, 9.8), "Divano abbandonato", [], 1.4, {"sit": true, "verb": "SIEDITI", "thoughts": [
		"Il divano ha visto cose. E ha ancora tutte le molle.",
		"Qui nessuno ti chiede la licenza. Basta stare comodi.",
		"Da qualche parte un registratore trasmette musica sporca di polvere."]})
	_prop(Vector2(-23.9, 13.3), Vector3(0.8, 0.6, 0.8), Color("#ffe14a"))
	_talk("nascondiglio", Vector2(-23.9, 12.4), "Cassa di fortuna", [
		["", "Sotto un telo trovi un sacchetto: sigilli scarabocchiati, gessetti e una licenza magica. Scaduta da anni."],
		["", "Nel retro, a penna: «Un giorno la rinnovo». Poi, più sotto, cancellato: «O forse no»."]], 1.5, {"secret": true})
	_npc("mago", "Mago di strada", Vector2(-31.0, 10.5), Color("#8a5bff"), Color("#ff8a3d"), true, [],
		["Senza licenza, senza albo e senza vergogna. Però il cappello ce l'ho.",
		 "Nesso, ad ovest nel vicolo, tiene un'Anomalia come cagnolino. Io preferisco i piccioni.",
		 "Fa' un tag sui muri, se ti va. Qui nessuno chiama la polizia."], {"title": "Mago di strada"})
	_lamp(Vector3(-30, 0, 6.5), Color("#ffd98a"), false)
	_lamp(Vector3(-41, 0, 9.0), Color("#ff8fd0"), false)
	_decal(Vector2(-38, 9), 3.6, Color("#ff8a3d"), 51, 0.6)
	_decal(Vector2(-27, 7), 3.0, Color("#8a5bff"), 53, 2.0)


func _zone_rane() -> void:
	_cyl(Vector3(-36, 0.06, -8), 3.0, 0.1, _mat(Color("#2ee6e6"), 1.0, 0.05))
	for p in [Vector2(-37.5, -9.2), Vector2(-34.8, -6.8), Vector2(-34.6, -9.6), Vector2(-37.8, -6.6)]:
		_cyl(Vector3(p.x, 0.13, p.y), 0.45, 0.04, _mat(Color("#5dffb0"), 0.0, 0.03))
	obstacles.append(Rect2(-39.0, -11.0, 6.0, 6.0))
	_bbox(Vector3(-36, 0.5, -8), Vector3(0.9, 0.7, 0.9), Color("#5dffb0"))
	_bbox(Vector3(-36.2, 1.0, -7.7), Vector3(0.22, 0.22, 0.22), Color("#fff3d6"), 0.03)
	_bbox(Vector3(-35.8, 1.0, -7.7), Vector3(0.22, 0.22, 0.22), Color("#fff3d6"), 0.03)
	_talk("rane", Vector2(-36, -4.6), "Stagno delle rane", [
		["", "Al centro dello stagno, una statuetta di rana con una corona storta."],
		["", "Qualcosa fa «plop». Guardi: cerchi sull'acqua, nessuna rana. Le rane qui sono molto timide, o molto furbe."]], 2.0)
	_tree(-40.7, -14.6, Color("#5dffb0"))
	_tree(-31.4, -14.6, Color("#ff9bd0"))
	_tree(-31.2, -3.0, Color("#5dffb0"), 1.2, 1.7)
	_bench(-38.6, -2.4, "panca_r", "Panchina dello stagno", [
		"Lo stagno riflette le lucine come un secondo cielo.",
		"Plop. Un'altra rana, forse. Sai che non la vedrai mai.",
		"Fa quasi freddo, e non c'è nessuna fretta."], Color("#c9f06b"))
	_prop(Vector2(-31.2, -12.6), Vector3(0.4, 0.1, 0.4), Color("#ffe14a"), 0.0, false)
	_talk("moneta", Vector2(-31.2, -11.8), "Qualcosa che luccica", [
		["", "Una moneta vecchia, con una rana incisa. Pesa più di quanto dovrebbe."],
		["", "La infili in tasca. Porta fortuna. O almeno lo dice la rana."]], 1.2, {"secret": true})
	_fireflies(Vector3(-36, 1.4, -8), Vector3(5.5, 1.0, 6.5), Color("#c9ff6b"))


func _zone_boschetto() -> void:
	var col: Color = Color("#4b2a8a")
	_tree(-39.2, -28.3, col, 1.6, 2.2)
	_tree(-30.8, -28.3, col.darkened(0.15), 1.6, 2.2)
	_tree(-39.3, -22.0, col.darkened(0.1), 1.4, 2.0)
	_tree(-30.7, -19.5, col, 1.4, 2.0)
	_tree(-39.2, -17.4, col.darkened(0.2), 1.4, 2.0)
	_tree(-30.8, -25.0, col.darkened(0.2), 1.5, 2.1)
	# occhi tra le fronde
	for e in [Vector3(-39.2, 3.4, -21.5), Vector3(-30.7, 3.3, -19.0), Vector3(-30.8, 3.6, -24.5), Vector3(-39.2, 3.5, -27.8)]:
		_bbox(e + Vector3(-0.28, 0, 0.0), Vector3(0.16, 0.1, 0.05), Color("#ffe14a"), 0.0)
		_bbox(e + Vector3(0.28, 0, 0.0), Vector3(0.16, 0.1, 0.05), Color("#ffe14a"), 0.0)
	_prop(Vector2(-35, -27.2), Vector3(1.4, 1.0, 1.0), Color("#2a1f4a"))
	_cyl(Vector3(-35, 1.6, -27.2), 0.3, 0.5, _mat(Color("#8a5bff"), 1.2, 0.0))
	_text3d("KAIROS?", Vector3(-35, 2.5, -27.0), 28, Color("#c9a8ff"))
	_talk("santuario", Vector2(-35, -25.9), "Piccolo santuario", [
		["", "Una pietra bassa, una sfera viola che pulsa piano. Sopra, scritto a gesso: «KAIROS?»."],
		["", "Qualcuno lascia qui piccole offerte: bottoni, dadi, un dente di latte. Non è chiaro se per ringraziare o per tenerli lontani."],
		["CENTRALE · CAM-07", "Operatore, segnalo: quel nome compare nei fascicoli sulle Anomalie. I Sinistri, dicono. Non facciamo supposizioni."]], 1.8)
	_talk("occhi", Vector2(-33.0, -21.5), "Fronde inquiete", [
		["", "Sei coppie di puntini gialli, fra le foglie. Nessuna si muove. Nessuna smette di guardare."],
		["", "Probabilmente lucciole. Probabilmente."]], 2.2)
	_fireflies(Vector3(-35, 1.3, -23), Vector3(4.0, 1.0, 5.5), Color("#b79cff"))


func _zone_canale() -> void:
	_lamp(Vector3(-3.4, 0, 14.8), Color("#8fe9ff"), false)
	_lamp(Vector3(3.4, 0, 14.8), Color("#8fe9ff"), false)
	_rail(-14.0, 26.0, 24.0)
	for lxp in [-10.0, 0.0, 10.0, 20.0]:
		_lamp(Vector3(lxp, 0, 23.4), Color("#ffd98a"), false)
	_bench(-9.0, 21.0, "panca_c", "Panchina sul canale", [
		"L'acqua scorre al contrario, o forse sei tu a muoverti. Meglio non chiederselo.",
		"Il riflesso delle lanterne fa i disegni sul canale.",
		"Un battello senza luci scivola via, lento. Nessuno sopra. Ottimo."], Color("#ff9bd0"))
	_npc("pescatore", "Pescatore", Vector2(-3.5, 23.0), Color("#2ee6e6"), Color("#ffe14a"), false, [],
		["Pesco da quindici anni. Ho preso uno stivale, una radio e una volta un nome di donna.",
		 "Non mi interessa il pesce. Mi interessa che l'acqua mi dica qualcosa.",
		 "Se vedi una bottiglia con un messaggio, non aprirla di sera. Parola mia."], {"title": "Pescatore"})
	_bbox(Vector3(-2.3, 2.1, 23.6), Vector3(2.4, 0.06, 0.06), INK, 0.0)
	_bbox(Vector3(-1.1, 1.0, 24.5), Vector3(0.02, 2.2, 0.02), INK, 0.0)
	_stall(5.5, 18.5, Color("#ff9bd0"), Color("#fff3d6"), "GELATI")
	_talk("gelato", Vector2(5.5, 19.8), "Chiosco dei gelati", [
		["", "Un chiosco con quindici gusti e un solo cliente alla volta. Il gelataio è serissimo."],
		["GELATAIO", "Il gusto del giorno è «ricordo d'estate». Non l'ho ancora assaggiato, ma pare funzioni."]], 1.8)
	_prop(Vector2(-12.6, 22.6), Vector3(0.3, 0.7, 0.3), Color("#5dffb0"), 0.0, false)
	_talk("bottiglia", Vector2(-12.6, 21.6), "Bottiglia", [
		["", "Una bottiglia incastrata fra i sassi, con un biglietto dentro."],
		["", "«Per chi leggerà: la strada più bella è quella senza destinazione». Firmato con un disegnino di rondine."]], 1.4)
	_npc("studente", "Studente", Vector2(-11.5, 19.8), Color("#ffe14a"), Color("#8a5bff"), false,
		[Vector2(-11.5, 19.8), Vector2(12, 19.8), Vector2(12, 22.2), Vector2(-11.5, 22.2)],
		["Domani ho l'esame all'albo. Se mi scambiano per un Magabondo, sono finito.",
		 "Sto ripassando le Anomalie. Ce ne sono di strane: una mi ha fissato un'ora dal tombino."])
	_decal(Vector2(-6, 19), 3.2, Color("#2ee6e6"), 61, 0.9)
	# banchina delle lanterne (est)
	_bench(17.5, 21.0, "panca_b", "Panchina della banchina", [
		"Le lanterne oscillano e fanno ombre che sembrano vive.",
		"Una barca sbatte piano contro il molo. Tic. Tic. Tic.",
		"Dall'altra parte del ponte, un albero rosa. Domani, magari."], Color("#ffd98a"))
	for lp in [Vector3(16, 0, 23.4), Vector3(22, 0, 23.4)]:
		_lamp(lp, Color("#ff8fd0"), false)
	var gx: float = 15.0
	var gi: int = 0
	_bbox(Vector3(20, 3.3, 20.0), Vector3(11, 0.05, 0.05), INK, 0.0)
	while gx < 25.5:
		_bbox(Vector3(gx, 3.0, 20.0), Vector3(0.3, 0.4, 0.3), POP[gi % POP.size()], 0.05)
		gx += 1.3
		gi += 1
	_talk("lanterne", Vector2(21, 21.5), "Lanterne di carta", [
		["", "Lanterne di carta con nomi scritti sopra: città che non esistono, o che non esistono più."],
		["", "Una dice «CASA». Nient'altro. Sotto, il solito pennarello: «tornerò»."]], 1.9)
	_prop(Vector2(24.6, 22.0), Vector3(0.9, 0.5, 0.8), Color("#8a5bff"))
	_cat("gatto_dorme", "Gatto addormentato", Vector2(24.6, 22.0), [], ["Ronf. Ronf. Un orecchio si gira verso di te, poi torna al sonno.", "Dorme su una cassa come se fosse un trono. Ha ragione."], true)
	_rail(14.0, 26.0, 24.0)


func _zone_isola() -> void:
	# ponte: due parapetti e lampioni
	_rail(26.0, 40.0, 19.5)
	_rail(26.0, 40.0, 22.0)
	for lxp in [29.0, 36.0]:
		_lamp(Vector3(lxp, 0, 19.5), Color("#8fe9ff"), false)
	_talk("ponte", Vector2(33, 20.75), "Il ponte", [
		["", "Sotto il ponte l'acqua scorre in direzione sbagliata. Dopo un po' ti ci abitui."],
		["", "Dall'altra parte, il profilo di un albero in fiore. Nessuno ti ha chiesto di arrivare fin là."]], 1.6)
	# isolotto: bordo basso e ciliegio
	_bbox(Vector3(45, 0.15, 15.15), Vector3(10.2, 0.3, 0.3), CREAM, 0.04)
	_bbox(Vector3(45, 0.15, 25.85), Vector3(10.2, 0.3, 0.3), CREAM, 0.04)
	_bbox(Vector3(49.85, 0.15, 20.5), Vector3(0.3, 0.3, 11.0), CREAM, 0.04)
	_prop(Vector2(45, 19.6), Vector3(0.7, 1.9, 0.7), Color("#6b3b2a"))
	_bbox(Vector3(45, 3.1, 19.6), Vector3(3.8, 1.5, 3.8), Color("#ff9bd0"), 0.08)
	_bbox(Vector3(45, 4.1, 19.6), Vector3(2.5, 1.0, 2.5), Color("#ffc2e8"), 0.08)
	_talk("ciliegio", Vector2(45, 21.6), "Ciliegio", [
		["", "Un ciliegio in fiore, in mezzo all'acqua. I petali cadono piano e non finiscono mai."],
		["", "Non c'è un cartello, una missione, un nemico. Solo l'ombra rosa e il rumore del canale. Resti un po'."]], 2.2)
	_bench(47.5, 22.4, "panca_i", "Panchina dell'isolotto", [
		"Hai camminato fin qui. Nessuno te l'aveva chiesto.",
		"I petali si posano sull'acqua. Il mondo, per un attimo, è fermo.",
		"Il quartiere sembra piccolo, da qui. E invece è pieno di angoli da scoprire."], Color("#ff9bd0"))
	_prop(Vector2(42.4, 17.6), Vector3(0.6, 0.4, 0.6), Color("#8a5bff"))
	_talk("biglietto", Vector2(42.6, 18.6), "Sasso con biglietto", [
		["", "Un biglietto sotto un sasso: «Se sei arrivato fin qui senza un motivo, è il motivo migliore.»"],
		["", "In basso, una rondine disegnata a penna. È la stessa del messaggio in bottiglia."]], 1.6)
	_lamp(Vector3(42.0, 0, 24.2), Color("#ff8fd0"), false)
	_petals(Vector3(45, 4.2, 19.6))


# ---------------------------------------------------------------- ESPLORAZIONE: scoperte, vita ambientale, vernice, panchine

func _talk(id: String, c2: Vector2, title: String, lines: Array, radius: float = 1.9, extra: Dictionary = {}) -> Dictionary:
	var d: Dictionary = {"id": id, "pos": c2, "title": title, "lines": lines, "radius": radius, "did": ("" if bool(extra.get("nodid", false)) else id)}
	for k in extra:
		d[k] = extra[k]
	talk_objs.append(d)
	return d


func _disc_init() -> void:
	_disc.clear()
	for o in talk_objs:
		if str(o["did"]) != "":
			_disc.append({"did": str(o["did"]), "pos": o["pos"], "title": str(o["title"]), "secret": bool(o.get("secret", false))})
	for e in DISC_EXTRA:
		_disc.append(e)


func _found_count() -> int:
	var n: int = 0
	for d in _disc:
		if WorldV2Ctx.found.has(str(d["did"])):
			n += 1
	return n


func _banner_show(txt: String) -> void:
	if banner == null:
		return
	banner.text = txt
	banner.size = banner.get_combined_minimum_size()
	banner.position = Vector2((ui.size.x - banner.size.x) * 0.5, 150.0)
	banner.modulate.a = 1.0
	banner.visible = true
	_banner_t = 3.2


func _discover(did: String, title: String) -> void:
	if did == "" or WorldV2Ctx.found.has(did):
		return
	WorldV2Ctx.found[did] = true
	WorldV2Ctx.save_persist()
	var n: int = _found_count()
	_banner_show("NUOVA SCOPERTA · %s   %d/%d" % [title.to_upper(), n, _disc.size()])
	Snd.play("toast")
	if n >= _disc.size() and not _disc.is_empty():
		_complete_pending = true


func _visit_zones() -> void:
	for i in range(AREAS.size()):
		if (AREAS[i]["rect"] as Rect2).has_point(player) and not WorldV2Ctx.zones.has(i):
			WorldV2Ctx.zones[i] = true
			WorldV2Ctx.save_persist()
			if WorldV2Ctx.zones.size() > 1:
				_banner_show("NUOVA ZONA · %s   %d/%d" % [str(AREAS[i]["name"]), WorldV2Ctx.zones.size(), AREAS.size()])
				Snd.play("toast")


# ---- particelle (vapore, lucciole, petali, polvere): saltate se l'utente ha scelto gli effetti ridotti
func _puffs(p: Vector3, col: Color, amount: int, speed: float, size: float, life: float, box: Vector3 = Vector3.ZERO, grav: float = 0.0, spread: float = 25.0) -> CPUParticles3D:
	if Settings.light_fx:
		return null
	var cp := CPUParticles3D.new()
	cp.amount = amount
	cp.lifetime = life
	cp.local_coords = false
	cp.position = p
	cp.direction = Vector3(0, 1, 0)
	cp.spread = spread
	cp.initial_velocity_min = speed * 0.5
	cp.initial_velocity_max = speed
	cp.gravity = Vector3(0, grav, 0)
	if box != Vector3.ZERO:
		cp.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		cp.emission_box_extents = box
	var qm := QuadMesh.new()
	qm.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.material = mat
	cp.mesh = qm
	var g := Gradient.new()
	g.set_color(0, Color(col.r, col.g, col.b, 0.9))
	g.set_color(1, Color(col.r, col.g, col.b, 0.0))
	cp.color_ramp = g
	add_child(cp)
	return cp


func _fireflies(c: Vector3, ext: Vector3, col: Color) -> void:
	_puffs(c, col, 14, 0.18, 0.13, 4.0, ext, 0.0, 180.0)


func _petals(c: Vector3) -> void:
	_puffs(c, Color("#ffc2e8"), 16, 0.25, 0.15, 4.0, Vector3(1.8, 0.2, 1.8), -0.55, 60.0)


# ---- PNG di contorno (sagome segnaposto, come i sorveglianti) e gatti
func _npc(id: String, nm: String, p: Vector2, body: Color, accent: Color, hood: bool, route: Array, quips: Array, extra: Dictionary = {}) -> void:
	var node := Node3D.new()
	add_child(node)
	var sp := Sprite3D.new()
	var tex: Texture2D = _outlined(_figure_tex(body, accent, hood), "n_" + id)
	sp.texture = tex
	sp.pixel_size = (CHAR_H * 0.95) / _content_h(tex)
	sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sp.shaded = false
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sp.position = Vector3(0, CHAR_H * 0.475, 0)
	node.add_child(sp)
	var sh := _shadow(node)
	node.position = Vector3(p.x, 0, p.y)
	var nn: Label3D = null
	if bool(extra.get("note", false)):
		nn = _text3d("♪", Vector3(0.7, CHAR_H + 0.6, 0), 40, Color("#ffe14a"), node, true)
		nn.no_depth_test = true
	var o: Dictionary = _talk(id, p, str(extra.get("title", nm)), [], 1.9, {"verb": "PARLA", "ni": _npcs.size()})
	if route.size() < 2:
		obstacles.append(Rect2(p.x - 0.35, p.y - 0.35, 0.7, 0.7))
	_npcs.append({"kind": "npc", "node": node, "sprite": sp, "shadow": sh, "pos": p, "route": route, "ri": 0, "wait": 0.2, "quips": quips, "qi": 0,
		"speed": 1.3, "obj": o, "name": nm, "narr": false, "mv": false, "note": nn, "ph": float(_npcs.size()) * 1.7})


func _cat_tex(sleeping: bool) -> Texture2D:
	var img := Image.create(44, 30, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var fur: Color = Color("#fff3d6") if sleeping else Color("#ff8a3d")
	var dark: Color = fur.darkened(0.25)
	if sleeping:
		img.fill_rect(Rect2i(4, 12, 32, 14), fur)
		img.fill_rect(Rect2i(28, 8, 12, 14), fur)
		img.fill_rect(Rect2i(29, 4, 3, 5), fur)
		img.fill_rect(Rect2i(36, 4, 3, 5), fur)
		img.fill_rect(Rect2i(8, 12, 4, 14), dark)
		img.fill_rect(Rect2i(16, 12, 4, 14), dark)
		img.fill_rect(Rect2i(33, 14, 3, 1), INK)
		img.fill_rect(Rect2i(2, 20, 6, 4), dark)
	else:
		img.fill_rect(Rect2i(8, 12, 26, 12), fur)
		img.fill_rect(Rect2i(30, 5, 12, 12), fur)
		img.fill_rect(Rect2i(31, 1, 3, 5), fur)
		img.fill_rect(Rect2i(38, 1, 3, 5), fur)
		img.fill_rect(Rect2i(12, 12, 3, 12), dark)
		img.fill_rect(Rect2i(20, 12, 3, 12), dark)
		img.fill_rect(Rect2i(8, 22, 4, 7), fur)
		img.fill_rect(Rect2i(30, 22, 4, 7), fur)
		img.fill_rect(Rect2i(36, 9, 2, 2), INK)
		img.fill_rect(Rect2i(2, 2, 4, 18), fur)
		img.fill_rect(Rect2i(2, 2, 4, 4), dark)
	img.resize(176, 120, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


func _cat(id: String, title: String, p: Vector2, route: Array, quips: Array, sleeping: bool) -> void:
	var node := Node3D.new()
	add_child(node)
	var sp := Sprite3D.new()
	var tex: Texture2D = _outlined(_cat_tex(sleeping), "cat_%s" % ("s" if sleeping else "w"))
	sp.texture = tex
	sp.pixel_size = (0.5 if sleeping else 0.62) / _content_h(tex)
	sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sp.shaded = false
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sp.position = Vector3(0, 0.32 if sleeping else 0.36, 0)
	node.add_child(sp)
	if sleeping:
		_text3d("z z z", Vector3(0, 1.1, 0), 30, Color("#bff6ff"), node, true)
	var sh := _shadow(node)
	sh.scale = Vector3.ONE * 0.5
	node.position = Vector3(p.x, 0.5 if sleeping else 0.0, p.y)
	var o: Dictionary = _talk(id, p, title, [], 1.6, {"verb": "ACCAREZZA", "ni": _npcs.size()})
	_npcs.append({"kind": "cat", "node": node, "sprite": sp, "pos": p, "route": route, "ri": 0, "wait": 0.2, "quips": quips, "qi": 0,
		"speed": 1.9, "obj": o, "name": title, "narr": true, "mv": false, "note": null, "ph": 0.0, "lift": 0.5 if sleeping else 0.0})


func _npcs_step(dt: float) -> void:
	for n in _npcs:
		var route: Array = n["route"]
		var node: Node3D = n["node"]
		var p: Vector2 = n["pos"]
		var near: bool = p.distance_to(player) < 2.6
		n["mv"] = false
		if route.size() >= 2 and (mode == "walk" or mode == "sit") and not near:
			if float(n["wait"]) > 0.0:
				n["wait"] = float(n["wait"]) - dt
			else:
				var d: Vector2 = (route[int(n["ri"])] as Vector2) - p
				if d.length() < 0.15:
					n["ri"] = (int(n["ri"]) + 1) % route.size()
					n["wait"] = 1.5 + float((int(_t * 7.0) + int(n["ri"])) % 30) / 10.0
				else:
					p += d.normalized() * minf(float(n["speed"]) * dt, d.length())
					n["pos"] = p
					n["mv"] = true
					var right: bool = d.x > 0.0
					if absf(d.x) > 0.05:
						(n["sprite"] as Sprite3D).flip_h = (not right) if n["kind"] == "npc" else (not right)
		(n["obj"] as Dictionary)["pos"] = p
		var lift: float = float(n.get("lift", 0.0))
		node.position = Vector3(p.x, lift, p.y)
		if n["kind"] == "npc":
			var bob: float = (absf(sin(_t * 8.0 + float(n["ph"]))) * 0.07) if bool(n["mv"]) else (sin(_t * 1.8 + float(n["ph"])) * 0.012)
			(n["sprite"] as Sprite3D).position.y = CHAR_H * 0.475 + bob * clampf(Settings.shake, 0.0, 1.0)
			if n["note"] != null:
				(n["note"] as Label3D).position.y = CHAR_H + 0.6 + absf(sin(_t * 3.0)) * 0.25
		else:
			node.position.y = lift + (absf(sin(_t * 12.0)) * 0.06 if bool(n["mv"]) else 0.0)


# ---- vernice sui muri del Cortile
func _paint_tag(i: int, c: int) -> void:
	var xs: Array = [-43.2, -38.2, -33.2, -28.2]
	var mi: MeshInstance3D = _spray_nodes.get(i)
	if mi == null:
		mi = MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(2.8, 2.0)
		mi.mesh = q
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = m
		mi.position = Vector3(float(xs[i]), 1.15, 3.12)
		mi.rotation.z = (-0.06 if i % 2 == 0 else 0.07)
		add_child(mi)
		_spray_nodes[i] = mi
	(mi.material_override as StandardMaterial3D).albedo_texture = _splat_tex(POP[c % POP.size()], 100 + i * 7 + c)


func _spray(i: int) -> void:
	var idx: int = -1
	for k in range(WorldV2Ctx.sprayed.size()):
		if int(WorldV2Ctx.sprayed[k]["i"]) == i:
			idx = k
	var c: int = 0
	var fresh: bool = idx < 0
	if fresh:
		c = (i * 2 + 1) % POP.size()
		WorldV2Ctx.sprayed.append({"i": i, "c": c})
	else:
		c = (int(WorldV2Ctx.sprayed[idx]["c"]) + 1) % POP.size()
		WorldV2Ctx.sprayed[idx]["c"] = c
	_paint_tag(i, c)
	WorldV2Ctx.save_persist()
	Snd.play("wipe")
	if fresh:
		_discover("tag%d" % i, "Tag %d" % (i + 1))
	else:
		_banner_show("TAG RIFATTO · ancora per cambiare colore")


# ---- seduta sulle panchine
func _sit(o: Dictionary) -> void:
	mode = "sit"
	_sit_obj = o
	_sit_t = 0.0
	player = o["pos"]
	_vel = Vector2.ZERO
	_moving = false
	_cam_size_t = 8.4
	_discover(str(o["did"]), str(o["title"]))


func _stand() -> void:
	mode = "walk"
	_cam_size_t = CAM_SIZE
	_last_adv = Time.get_ticks_msec() / 1000.0
	_sit_obj = {}


# ---- minimappa
func _update_minimap() -> void:
	if minimap == null:
		return
	var near: Dictionary = {}
	for i in range(AREAS.size()):
		if WorldV2Ctx.zones.has(i):
			continue
		var g: Rect2 = (AREAS[i]["rect"] as Rect2).grow(0.6)
		for j in WorldV2Ctx.zones.keys():
			if g.intersects(AREAS[int(j)]["rect"]):
				near[i] = true
	var marks: Array = []
	for d in _disc:
		if WorldV2Ctx.found.has(str(d["did"])) or bool(d["secret"]):
			continue
		for i in WorldV2Ctx.zones.keys():
			if (AREAS[int(i)]["rect"] as Rect2).grow(0.3).has_point(d["pos"]):
				marks.append(d["pos"])
				break
	minimap.seen = WorldV2Ctx.zones
	minimap.near = near
	minimap.marks = marks
	minimap.me = player
	minimap.pulse = _t
	minimap.queue_redraw()
	stat_label.text = "SCOPERTE %d/%d  ·  ZONE %d/%d" % [_found_count(), _disc.size(), WorldV2Ctx.zones.size(), AREAS.size()]


class MiniMap extends Control:
	# Una sola texture ricostruita solo quando cambia qualcosa (zone, scoperte): pochi disegni per fotogramma
	var rects: Array = []
	var cols: Array = []
	var seen: Dictionary = {}
	var near: Dictionary = {}
	var marks: Array = []
	var me: Vector2 = Vector2.ZERO
	var pulse: float = 0.0
	var font: Font
	var _img: Image
	var _tex: ImageTexture
	var _sig: String = ""
	const BOUNDS: Rect2 = Rect2(-46, -41, 98, 67)
	const PPM: float = 2.5

	func _px(p: Vector2) -> Vector2i:
		return Vector2i(int((p.x - BOUNDS.position.x) * PPM), int((p.y - BOUNDS.position.y) * PPM))

	func rebuild() -> void:
		var sg: String = "%s|%s|%s" % [seen.keys(), near.keys(), marks.size()]
		if sg == _sig and _tex != null:
			return
		_sig = sg
		var w: int = int(BOUNDS.size.x * PPM)
		var h: int = int(BOUNDS.size.y * PPM)
		if _img == null:
			_img = Image.create(w, h, false, Image.FORMAT_RGBA8)
		_img.fill(Color(0.04, 0.03, 0.08, 0.82))
		for i in range(rects.size()):
			var r: Rect2 = rects[i]
			var a: Vector2i = _px(r.position)
			var b: Vector2i = _px(r.end)
			var rr := Rect2i(a, b - a)
			if seen.has(i):
				var c: Color = cols[i % cols.size()]
				_img.fill_rect(rr, Color(c.r, c.g, c.b, 0.95))
			elif near.has(i):
				var wc := Color(1, 1, 1, 0.45)
				_img.fill_rect(Rect2i(rr.position, Vector2i(rr.size.x, 1)), wc)
				_img.fill_rect(Rect2i(rr.position.x, rr.end.y - 1, rr.size.x, 1), wc)
				_img.fill_rect(Rect2i(rr.position, Vector2i(1, rr.size.y)), wc)
				_img.fill_rect(Rect2i(rr.end.x - 1, rr.position.y, 1, rr.size.y), wc)
		for m in marks:
			var q: Vector2i = _px(m)
			_img.fill_rect(Rect2i(q.x - 2, q.y - 2, 5, 5), Color("#fff3d6"))
			_img.fill_rect(Rect2i(q.x - 1, q.y - 1, 3, 3), Color("#0b0814"))
		if _tex == null:
			_tex = ImageTexture.create_from_image(_img)
		else:
			_tex.update(_img)

	func _draw() -> void:
		rebuild()
		draw_texture_rect(_tex, Rect2(Vector2.ZERO, size), false)
		var pm: Vector2 = Vector2((me.x - BOUNDS.position.x) / BOUNDS.size.x * size.x, (me.y - BOUNDS.position.y) / BOUNDS.size.y * size.y)
		var rad: float = 4.0 + 1.0 * sin(pulse * 5.0)
		draw_rect(Rect2(pm - Vector2(rad + 2.0, rad + 2.0), Vector2((rad + 2.0) * 2.0, (rad + 2.0) * 2.0)), Color("#0b0814"))
		draw_rect(Rect2(pm - Vector2(rad, rad), Vector2(rad * 2.0, rad * 2.0)), Color("#ff3d8b"))
		draw_rect(Rect2(Vector2.ZERO, size), Color("#0b0814"), false, 3.0)
func _boss_card() -> Array:
	var b: Dictionary = BattleContent.BOSSES["distributore"]
	var col: String = str(b["color"])
	var strong: String = ""
	for k in BattleTypes.BEATS:
		if str(BattleTypes.BEATS[k]) == col:
			strong = str(k)
	var who: Array = []
	for id in party:
		if str(BattleContent.CHARACTERS[id]["color"]) == strong:
			who.append(str(BattleContent.CHARACTERS[id]["name"]))
	var moves: Array = []
	var bleed: bool = false
	for m in b["cycle"]:
		var d: Dictionary = BattleContent.BOSS_MOVES[m]
		var tgt: String = "tutti" if str(d["target"]) == "all" else "1 bersaglio"
		var extra: String = ""
		if d.has("status") and (d["status"] as Dictionary).has("bleed"):
			extra = ", sanguinamento"
			bleed = true
		moves.append("%s (%s, x%.1f%s)" % [str(d["name"]), tgt, float(d["mult"]), extra])
	var lines: Array = []
	lines.append(["SCHEDA · " + str(b["name"]).to_upper(), "%s. Colore %s." % [str(b["title"]), col.to_upper()]])
	var adv: String = "Il %s lo colpisce a x%.1f." % [strong.to_upper(), BattleTypes.COLOR_ADVANTAGE]
	adv += (" In squadra: %s." % ", ".join(who)) if not who.is_empty() else " Nessuno, in squadra, ha quel colore."
	lines.append(["SCHEDA · COLORE", adv])
	lines.append(["SCHEDA · MOSSE", "Ciclo: " + " → ".join(moves) + "."])
	var tip: String = "In battaglia l'annuncio in alto mostra mossa e bersaglio PRIMA che scegli: usa scudi e Guardia contro i colpi forti."
	if bleed:
		tip += " Dopo la Scossa porta una cura: il sanguinamento resta."
	lines.append(["SCHEDA · CONTROMISURE", tip])
	return lines


func _gate() -> void:
	gate_node = Node3D.new()
	gate_node.position = Vector3(0, 0, -15.0)
	add_child(gate_node)
	_box(Vector3(0, 2.0, 0), Vector3(6.0, 4.0, 0.25), _mat(Color("#2ee6e6")), gate_node)
	for i in range(8):
		_box(Vector3(-2.6 + i * 0.75, 2.0, 0.14), Vector3(0.08, 4.0, 0.05), _mat(Color("#0b0814")), gate_node)
	_text3d("ACCESSO CHIUSO\nNULLA OSTA × 2", Vector3(0, 2.4, 0.2), 34, Color("#ff7a6a"), gate_node)
	obstacles.append(GATE_RECT)


func _boss_machine() -> void:
	boss_node = Node3D.new()
	boss_node.position = Vector3(BOSS_POS.x, 0, BOSS_POS.y)
	add_child(boss_node)
	_box(Vector3(0, 2.3, 0), Vector3(3.4, 4.6, 2.2), _mat(Color("#ffd23f")), boss_node)
	_box(Vector3(0, 2.6, 1.12), Vector3(2.6, 2.4, 0.06), _mat(Color("#0b0814")), boss_node)
	boss_screen = _box(Vector3(0, 2.6, 1.16), Vector3(2.3, 2.1, 0.04), _mat(Color("#ffe27a"), 1.7), boss_node)
	for i in range(3):
		_box(Vector3(-0.8 + i * 0.8, 3.0, 1.2), Vector3(0.5, 0.5, 0.02), _mat(Color("#ff5a4f") if i == 1 else Color("#f6f0cf"), 1.0), boss_node)
	_box(Vector3(0, 0.8, 1.15), Vector3(1.6, 0.7, 0.1), _mat(Color("#0b0814")), boss_node)
	_box(Vector3(1.2, 1.5, 1.14), Vector3(0.7, 0.9, 0.06), _mat(Color("#ff3d8b")), boss_node)
	_text3d("NON SPINGERE", Vector3(0, 4.15, 1.15), 40, Color("#2a1500"), boss_node)
	obstacles.append(Rect2(BOSS_POS.x - 1.8, BOSS_POS.y - 1.2, 3.6, 2.5))
	_talk("boss", Vector2(BOSS_POS.x, BOSS_POS.y + 3.0), "Il Distributore", [], 2.0, {"nodid": true, "verb": "AFFRONTA"})


# ---------------------------------------------------------------- sorveglianti

func _figure_tex(body: Color, accent: Color, hood: bool) -> Texture2D:
	var img := Image.create(128, 256, false, Image.FORMAT_RGBA8)
	var skin := Color("#e8c9a8")
	for y in range(256):
		for x in range(128):
			var c: Color = Color(0, 0, 0, 0)
			var head: float = Vector2(x - 64, y - 52).length()
			if head < 24.0:
				c = body.darkened(0.2) if hood and y < 54 else skin
			if y >= 70 and y < 80 and abs(x - 64) < 9:
				c = skin
			if y > 78 and y < 190 and abs(x - 64) < 34 - (y - 80) * 0.08:
				c = body
			if y > 190 and y < 246 and (abs(x - 50) < 12 or abs(x - 78) < 12):
				c = body.darkened(0.35)
			if y > 92 and y < 100 and abs(x - 64) < 36:
				c = accent
			if y > 44 and y < 54 and abs(x - 64) < 22 and head < 24.0 and not hood:
				c = accent
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _trainers() -> void:
	var defs: Array = [
		{"id": "libracorp", "name": "AGENTE BRANDI · LIBRACORP", "pos": Vector2(15, 2.0), "face": Vector2(-1, 0),
		 "body": Color("#2e6bff"), "accent": Color("#ffe14a"), "hood": false,
		 "pre": [
			["AGENTE BRANDI", "Alt! Zona sotto sequestro LibraCorp. Licenza magica, prego."],
			["AGENTE BRANDI", "…Non risulti all'albo, o l'hai lasciata a casa. E un distributore difettoso mi si è appena staccato dal muro."],
			["AGENTE BRANDI", "Procedura d'emergenza: ti metto alla prova. Se ci riesci, ti firmo il nulla osta!"]],
		 "win": [
			["AGENTE BRANDI", "Distributore in stand-by. Rapporto: «operatori in gamba, licenza da verificare»."],
			["AGENTE BRANDI", "Ecco il mio nulla osta. Per la serranda ne serve un altro: quello dei ragazzi nel Vicolo delle Rondini."]],
		 "after": "Brandi sta compilando il rapporto. Non alza lo sguardo."},
		{"id": "magabondo", "name": "NESSO · MAGABONDO", "pos": Vector2(-16.5, 6.0), "face": Vector2(1, 0),
		 "body": Color("#8a5bff"), "accent": Color("#ff3d8b"), "hood": true,
		 "pre": [
			["NESSO", "Ehi, ehi! Chi va là? Niente licenza, niente albo: qui la magia si fa per strada."],
			["NESSO", "Se volete il mio sigillo per la serranda dovete dimostrare che non siete spie di LibraCorp."],
			["NESSO", "Un'Anomalia l'ho addomesticata io. Vediamo come ve la cavate!"]],
		 "win": [
			["NESSO", "Va bene, va bene. Non siete spie, siete solo… testardi."],
			["NESSO", "Prendi il sigillo. Con questo e quello di Brandi la serranda a nord si apre."]],
		 "after": "Nesso accarezza il suo distributore. «Bravo. Bravo, cattivo…»"},
	]
	for d in defs:
		var t: Dictionary = d.duplicate(true)
		var node := Node3D.new()
		add_child(node)
		var sp := Sprite3D.new()
		var ttex: Texture2D = _outlined(_figure_tex(t["body"], t["accent"], bool(t["hood"])), "t_" + str(t["id"]))
		sp.texture = ttex
		sp.pixel_size = CHAR_H / _content_h(ttex)
		sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sp.shaded = false
		sp.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
		sp.position = Vector3(0, CHAR_H * 0.5, 0)
		node.add_child(sp)
		var sh := _shadow(node)
		var tag: Label3D = _text3d(str(t["name"]), Vector3(0, CHAR_H + 0.35, 0), 20, Color("#fff1c0"), node, true)
		tag.no_depth_test = true
		var ex: Label3D = _make_excl(Vector3(0, CHAR_H + 1.3, 0), node, 120)
		ex.visible = false
		# cono visivo: il giocatore deve poterlo leggere
		var cone := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(SIGHT * 0.9, SIGHT)
		q.orientation = PlaneMesh.FACE_Y
		cone.mesh = q
		var cm := StandardMaterial3D.new()
		cm.albedo_texture = _cone_tex()
		cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cm.albedo_color = Color(1.0, 0.35, 0.25, 0.9)
		cm.cull_mode = BaseMaterial3D.CULL_DISABLED
		cone.material_override = cm
		cone.position = Vector3(0, 0.04, -SIGHT * 0.5)
		var pivot := Node3D.new()
		pivot.add_child(cone)
		pivot.rotation.y = atan2(-(t["face"] as Vector2).x, -(t["face"] as Vector2).y)
		node.add_child(pivot)
		var pp: Vector2 = t["pos"]
		node.position = Vector3(pp.x, 0, pp.y)
		t["node"] = node
		t["sprite"] = sp
		t["shadow"] = sh
		t["excl"] = ex
		t["cone"] = pivot
		t["done"] = false
		t["home"] = pp
		trainers.append(t)
		obstacles.append(Rect2(pp.x - 0.4, pp.y - 0.4, 0.8, 0.8))
		t["obst"] = obstacles.size() - 1
		_talk(str(t["id"]), pp + Vector2(-(t["face"] as Vector2).x * 0.0, 0.0), str(t["name"]), [], 1.9, {"nodid": true, "verb": "PARLA"})


var _burst: Texture2D


func _burst_tex() -> Texture2D:
	if _burst == null:
		var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
		for y in range(128):
			for x in range(128):
				var v := Vector2(x - 63.5, y - 63.5)
				var ang: float = atan2(v.y, v.x)
				var r: float = 44.0 + 17.0 * cos(ang * 9.0)
				var d: float = v.length()
				if d < r - 5.0:
					img.set_pixel(x, y, Color("#ffe14a"))
				elif d < r:
					img.set_pixel(x, y, INK)
		_burst = ImageTexture.create_from_image(img)
	return _burst


# "!" da fumetto: scritta nera su stella gialla
func _make_excl(pos: Vector3, parent: Node, size: int) -> Label3D:
	var ex: Label3D = _text3d("!", pos, size, INK, parent, true)
	ex.outline_size = 0
	ex.no_depth_test = true
	ex.render_priority = 2
	var b := Sprite3D.new()
	b.texture = _burst_tex()
	b.pixel_size = 0.02 * float(size) / 120.0
	b.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	b.shaded = false
	b.no_depth_test = true
	b.render_priority = 1
	b.position = Vector3(0, 0, -0.02)
	ex.add_child(b)
	return ex


func _cone_tex() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			# punta in basso al centro (dove sta il sorvegliante, a z=0 locale), si allarga verso l'alto
			var k: float = 1.0 - float(y) / 63.0
			var half: float = 0.08 + 0.42 * k
			var dx: float = absf(float(x) / 63.0 - 0.5)
			var a: float = 0.0
			if dx < half:
				a = (1.0 - dx / half) * 0.35 * (0.35 + 0.65 * (1.0 - k))
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _shadow(parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.1, 1.1)
	q.orientation = PlaneMesh.FACE_Y
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = _blob_tex()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	mi.position = Vector3(0, 0.03, 0)
	parent.add_child(mi)
	return mi


# ---------------------------------------------------------------- squadra

# Contorno da fumetto: bordo nero spesso + filo crema esterno (effetto adesivo), generato una volta sola per immagine
func _outlined(tex: Texture2D, key: String) -> Texture2D:
	if _sprite_cache.has(key):
		return _sprite_cache[key]
	var src: Image = tex.get_image()
	if src == null:
		return tex
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	if src.get_height() > 480:
		var k: float = 480.0 / float(src.get_height())
		src.resize(int(float(src.get_width()) * k), 480, Image.INTERPOLATE_BILINEAR)
	var w: int = src.get_width()
	var h: int = src.get_height()
	var r_in: int = maxi(3, int(round(h / 90.0)))
	var r_out: int = r_in * 2
	var m: int = r_out + 2
	var rect := Rect2i(0, 0, w, h)
	var canvas := Image.create(w + 2 * m, h + 2 * m, false, Image.FORMAT_RGBA8)
	for ring in [[r_out, CREAM], [r_in, INK]]:
		var fillc := Image.create(w, h, false, Image.FORMAT_RGBA8)
		fillc.fill(ring[1])
		var sil := Image.create(w, h, false, Image.FORMAT_RGBA8)
		sil.blit_rect_mask(fillc, src, rect, Vector2i.ZERO)
		for i in range(18):
			var a: float = TAU * float(i) / 18.0
			var off := Vector2i(int(round(cos(a) * float(ring[0]))), int(round(sin(a) * float(ring[0]))))
			canvas.blend_rect(sil, rect, Vector2i(m + off.x, m + off.y))
	canvas.blend_rect(src, rect, Vector2i(m, m))
	var out: ImageTexture = ImageTexture.create_from_image(canvas)
	out.set_meta("m", m)
	_sprite_cache[key] = out
	return out


func _content_h(tex: Texture2D) -> float:
	return float(tex.get_height() - 2 * int(tex.get_meta("m", 0)))


func _char_tex(id: String) -> Texture2D:
	var t: Texture2D = ArtLibrary.battle_sprite(id)
	if t == null:
		t = ArtLibrary.icon(id)
	if t == null:
		t = ArtLibrary.portrait(id)
	if t == null:
		var col: Color = COLOR_RGB.get(str(BattleContent.CHARACTERS[id]["color"]), Color("#8899cc"))
		t = _figure_tex(col, CREAM, false)
	return t


func _build_party() -> void:
	for i in range(party.size()):
		var id: String = str(party[i])
		var node := Node3D.new()
		add_child(node)
		var sp := Sprite3D.new()
		var tex: Texture2D = _outlined(_char_tex(id), "c_" + id)
		sp.texture = tex
		var th: float = _content_h(tex)
		var hh: float = CHAR_H if i == 0 else CHAR_H * 0.94
		sp.pixel_size = hh / th
		sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sp.shaded = false
		sp.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
		sp.position = Vector3(0, hh * 0.5, 0)
		node.add_child(sp)
		var sh := _shadow(node)
		if i == 0:
			var nm: Label3D = _text3d(str(BattleContent.CHARACTERS[id]["name"]).to_upper(), Vector3(0, hh + 0.3, 0), 18, Color("#bff6ff"), node, true)
			nm.no_depth_test = true
		chars.append({"id": id, "node": node, "sprite": sp, "shadow": sh, "pos": SPAWN, "h": hh, "moving": false})


func _seed_trail() -> void:
	trail.clear()
	var back: Vector2 = Vector2(-facing * 0.0, 1.0)
	for i in range(6, -1, -1):
		trail.append(player + back * float(i) * 0.7)
	trail.append(player)


func _trail_point(dist: float) -> Vector2:
	var acc: float = 0.0
	for i in range(trail.size() - 1, 0, -1):
		var a: Vector2 = trail[i]
		var b: Vector2 = trail[i - 1]
		var seg: float = a.distance_to(b)
		if acc + seg >= dist:
			return a.lerp(b, (dist - acc) / maxf(seg, 0.0001))
		acc += seg
	return trail[0]


# Un po' di lato rispetto alla scia, cosi' i tre non si coprono a vicenda vista dall'alto
func _slot_pos(i: int) -> Vector2:
	if i == 0:
		return player
	return _trail_point(FOLLOW_GAP * float(i)) + Vector2(0.0, -0.7 if i == 1 else 0.7)


func _place_all() -> void:
	for i in range(chars.size()):
		var p: Vector2 = _slot_pos(i)
		chars[i]["pos"] = p
		(chars[i]["node"] as Node3D).position = Vector3(p.x, 0, p.y)


# ---------------------------------------------------------------- avanzamento

func _apply_progress() -> void:
	for t in trainers:
		var done: bool = bool(WorldV2Ctx.defeated.get(str(t["id"]), false))
		t["done"] = done
		(t["cone"] as Node3D).visible = not done
		if done:
			# il sorvegliante si volta di spalle
			(t["sprite"] as Sprite3D).flip_h = true
	var both: bool = true
	for t in trainers:
		both = both and bool(t["done"])
	gate_open = both
	if gate_open:
		gate_node.position.y = 4.4
		var i: int = obstacles.find(GATE_RECT)
		if i >= 0:
			obstacles.remove_at(i)
	var bd: bool = bool(WorldV2Ctx.defeated.get("distributore", false))
	if bd:
		_boss_off()
	_update_objective()


func _boss_off() -> void:
	if boss_screen != null:
		(boss_screen.material_override as ShaderMaterial).set_shader_parameter("albedo", Color("#3a3358"))
	if boss_light != null:
		boss_light.light_energy = 0.0


func _update_objective() -> void:
	if obj_label == null:
		return
	var n: int = 0
	for t in trainers:
		if bool(t["done"]):
			n += 1
	if bool(WorldV2Ctx.defeated.get("distributore", false)):
		obj_label.text = "ANOMALIA CHIUSA · Test V2 completato. Il quartiere è tuo: gira, siediti, scopri."
	elif gate_open:
		obj_label.text = "OBIETTIVO · Raggiungi il Largo del Distributore, a nord."
	else:
		obj_label.text = "OBIETTIVO · Nulla osta %d/2 — sorvegliante a est (Via Elettra) e a ovest (Vicolo delle Rondini)." % n


func _open_gate_anim() -> void:
	gate_open = true
	var i: int = obstacles.find(GATE_RECT)
	if i >= 0:
		obstacles.remove_at(i)
	var tw := create_tween()
	tw.tween_property(gate_node, "position:y", 4.4, 1.2 if Settings.shake > 0.0 else 0.01)
	_update_objective()


func _after_battle(pend: String, res: String) -> void:
	if res == "win":
		WorldV2Ctx.defeated[pend] = true
		if pend == "distributore":
			_boss_off()
			_update_objective()
			_say([
				["CENTRALE · CAM-07", "Segnale spento. Il Distributore è tornato un semplice distributore."],
				["CENTRALE · CAM-07", "Anomalia chiusa. Ottimo lavoro, squadra. (Fine del Test V2: puoi continuare a girare.)"]])
			return
		for t in trainers:
			if str(t["id"]) == pend:
				t["done"] = true
				(t["cone"] as Node3D).visible = false
				(t["sprite"] as Sprite3D).flip_h = true
				_say(t["win"], func() -> void:
					var all: bool = true
					for u in trainers:
						all = all and bool(u["done"])
					if all and not gate_open:
						_open_gate_anim()
						_say([["CENTRALE · CAM-07", "Due nulla osta registrati. Si sente una serranda salire, a nord."]])
					else:
						_update_objective())
				return
	else:
		# sconfitta o fuga: i Rondini ti riportano al rifugio, senza penalita' (addestramento)
		player = SPAWN
		facing = 1.0
		_seed_trail()
		_place_all()
		_camera(1.0, true)
		_say([["CENTRALE · CAM-07", ("Squadra a terra. I Rondini vi recuperano e vi riportano al rifugio. Nessun danno permanente." if res == "lose" else "Ritirata riuscita. Vi riportiamo al rifugio.")]])


# ---------------------------------------------------------------- interfaccia

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	var touch: bool = TouchUi.active()
	var fs: int = 22 if touch else 18

	zone_label = BattleTheme.make_label("", 34 if touch else 28, INK, true)
	zone_label.add_theme_stylebox_override("normal", _comic_box(Color("#ffe14a"), 4, Color("#ff3d8b"), Vector2(7, 7), 14))
	zone_label.position = Vector2(34, 22)
	zone_label.rotation = -0.035
	ui.add_child(zone_label)
	obj_label = BattleTheme.make_label("", 20 if touch else 16, Color.WHITE)
	obj_label.add_theme_stylebox_override("normal", _comic_box(Color(0.04, 0.03, 0.08, 0.86), 0, Color(0, 0, 0, 0), Vector2.ZERO, 12))
	obj_label.position = Vector2(34, 84 if touch else 76)
	obj_label.size = Vector2(760, 60)
	obj_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.add_child(obj_label)

	prompt = BattleTheme.make_label("", fs, Color("#ffe14a"), true)
	prompt.add_theme_color_override("font_outline_color", INK)
	prompt.add_theme_constant_override("outline_size", 10)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.size = Vector2(900, 40)
	ui.add_child(prompt)

	dlg = PanelContainer.new()
	dlg.add_theme_stylebox_override("panel", _comic_box(CREAM, 5, Color("#ff3d8b"), Vector2(9, 9), 22))
	dlg.visible = false
	dlg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dlg.offset_left = 60.0
	dlg.offset_right = -60.0
	dlg.offset_bottom = -26.0
	dlg.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dlg.mouse_filter = Control.MOUSE_FILTER_STOP
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	dlg.add_child(vb)
	dlg_who = BattleTheme.make_label("", 22 if touch else 18, Color.WHITE, true)
	dlg_who.add_theme_stylebox_override("normal", _comic_box(Color("#ff3d8b"), 3, Color(0, 0, 0, 0), Vector2.ZERO, 10))
	dlg_who.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	vb.add_child(dlg_who)
	dlg_text = BattleTheme.make_label("", 26 if touch else 21, INK)
	dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_text.custom_minimum_size = Vector2(900, 0)
	vb.add_child(dlg_text)
	dlg_hint = BattleTheme.make_label("TOCCA PER PROSEGUIRE" if touch else "INVIO / E / SPAZIO PER PROSEGUIRE", 15, Color("#6b4a8a"))
	dlg_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(dlg_hint)
	ui.add_child(dlg)

	pad = Pad.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.visible = touch
	ui.add_child(pad)
	act = ActBtn.new()
	act.mouse_filter = Control.MOUSE_FILTER_IGNORE
	act.custom_minimum_size = Vector2(170, 170)
	act.size = Vector2(170, 170)
	act.label = "AZIONE"
	act.visible = touch
	ui.add_child(act)

	pause_btn = Button.new()
	pause_btn.text = "II  MENU"
	pause_btn.size = Vector2(150 if touch else 130, 72 if touch else 44)
	BattleTheme.style_button(pause_btn, "normal", 22 if touch else 16)
	pause_btn.pressed.connect(_toggle_pause)
	pause_btn.focus_mode = Control.FOCUS_NONE
	ui.add_child(pause_btn)

	var mmw: float = 250.0 if touch else 200.0
	minimap = MiniMap.new()
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap.size = Vector2(mmw, mmw * 67.0 / 98.0)
	minimap.custom_minimum_size = minimap.size
	minimap.font = ThemeDB.fallback_font
	for a in AREAS:
		minimap.rects.append(a["rect"])
	minimap.cols = TINTS
	ui.add_child(minimap)
	stat_label = BattleTheme.make_label("", 17 if touch else 14, Color.WHITE, true)
	stat_label.add_theme_color_override("font_outline_color", INK)
	stat_label.add_theme_constant_override("outline_size", 6)
	ui.add_child(stat_label)
	banner = BattleTheme.make_label("", 28 if touch else 22, INK, true)
	banner.add_theme_stylebox_override("normal", _comic_box(Color("#5dffb0"), 4, Color("#ff3d8b"), Vector2(6, 6), 14))
	banner.visible = false
	ui.add_child(banner)
	run_btn = Button.new()
	run_btn.text = "CORRI"
	run_btn.toggle_mode = true
	run_btn.size = Vector2(150, 70)
	BattleTheme.style_button(run_btn, "normal", 22)
	run_btn.focus_mode = Control.FOCUS_NONE
	run_btn.visible = touch
	run_btn.toggled.connect(func(on: bool) -> void: _run_on = on)
	ui.add_child(run_btn)

	if not touch:
		var help := BattleTheme.make_label("WASD / FRECCE = CAMMINA   ·   SHIFT = CORRI   ·   E / INVIO = INTERAGISCI   ·   ESC = MENU", 14, BattleTheme.CY_DIM)
		help.name = "Help"
		ui.add_child(help)

	pause_menu = Control.new()
	pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.visible = false
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.6)
	pause_menu.add_child(shade)
	var pb := VBoxContainer.new()
	pb.name = "Box"
	pb.custom_minimum_size = Vector2(380, 0)
	pb.add_theme_constant_override("separation", 14)
	pause_menu.add_child(pb)
	var title := BattleTheme.make_label("PAUSA", 48, Color("#fff36b"), true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pb.add_child(title)
	var rb := Button.new()
	rb.text = "RIPRENDI"
	rb.custom_minimum_size = Vector2(0, 64)
	BattleTheme.style_button(rb, "primary", 24)
	rb.pressed.connect(_toggle_pause)
	pb.add_child(rb)
	var eb := Button.new()
	eb.text = "ESCI DAL TEST V2"
	eb.custom_minimum_size = Vector2(0, 64)
	BattleTheme.style_button(eb, "normal", 24)
	eb.pressed.connect(_leave)
	pb.add_child(eb)
	ui.add_child(pause_menu)

	var halftone := ColorRect.new()
	halftone.set_anchors_preset(Control.PRESET_FULL_RECT)
	halftone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hm := ShaderMaterial.new()
	var hs := Shader.new()
	hs.code = HALFTONE_CODE
	hm.shader = hs
	halftone.material = hm
	halftone.visible = not Settings.light_fx
	ui.add_child(halftone)
	ui.move_child(halftone, 0)
	flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(flash)
	fade = ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade)

	ui.resized.connect(_layout)
	_layout()
	_update_objective()


func _comic_box(bg: Color, border: int, shadow: Color, off: Vector2, pad_px: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = INK
	b.set_border_width_all(border)
	b.set_corner_radius_all(3)
	b.content_margin_left = pad_px
	b.content_margin_right = pad_px
	b.content_margin_top = pad_px * 0.5
	b.content_margin_bottom = pad_px * 0.5
	if shadow.a > 0.0:
		b.shadow_color = shadow
		b.shadow_size = 1
		b.shadow_offset = off
	return b


func _layout() -> void:
	var s: Vector2 = ui.size
	if s.x < 10.0:
		s = Vector2(W, H)
	var touch: bool = TouchUi.active()
	pause_btn.position = Vector2(s.x - pause_btn.size.x - 24, 22)
	prompt.position = Vector2(s.x * 0.5 - 450, s.y - (250 if touch else 250))
	pad.size = s
	pad.home = Vector2(190, s.y - 190)
	act.position = Vector2(s.x - 230, s.y - 260)
	run_btn.position = Vector2(s.x - 220, s.y - 345)
	minimap.position = Vector2(s.x - minimap.size.x - 24, pause_btn.size.y + 36)
	stat_label.position = Vector2(minimap.position.x, minimap.position.y + minimap.size.y + 6)
	var hb: Node = ui.get_node_or_null("Help")
	if hb != null:
		(hb as Control).position = Vector2(30, s.y - 34)
	var box: Control = pause_menu.get_node("Box")
	box.position = Vector2(s.x * 0.5 - 190, s.y * 0.5 - 130)


func _say(lines: Array, done: Callable = Callable()) -> void:
	_lines = lines
	_line_i = 0
	_dialog_done = done
	mode = "dialog"
	_show_line()


func _show_line() -> void:
	var l: Array = _lines[_line_i]
	dlg_who.text = str(l[0])
	dlg_who.visible = str(l[0]) != ""
	dlg_text.text = str(l[1])
	dlg.visible = true
	prompt.text = ""
	var hb: Node = ui.get_node_or_null("Help")
	if hb != null:
		(hb as Control).visible = false


func _advance_dialog() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_adv < 0.18:
		return
	_last_adv = now
	_line_i += 1
	if _line_i >= _lines.size():
		dlg.visible = false
		var hb: Node = ui.get_node_or_null("Help")
		if hb != null:
			(hb as Control).visible = true
		mode = "walk"
		var cb: Callable = _dialog_done
		_dialog_done = Callable()
		if cb.is_valid():
			cb.call()
	else:
		_show_line()


func _toggle_pause() -> void:
	if mode == "pause":
		mode = "walk"
		pause_menu.visible = false
	elif mode == "walk":
		mode = "pause"
		pause_menu.visible = true
		_stick_idx = -1
		_stick_vec = Vector2.ZERO
		pad.on = false
		pad.queue_redraw()


func _leave() -> void:
	WorldV2Ctx.reset()
	SceneRouter.go("squad_v2")


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = (event as InputEventKey).physical_keycode
		if k == KEY_ESCAPE:
			_toggle_pause()
			return
		if k == KEY_E or k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
			_interact_pressed()
			return
	if mode == "dialog":
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			_advance_dialog()
		return
	if mode != "walk" and mode != "sit":
		return
	if event is InputEventScreenTouch:
		var e: InputEventScreenTouch = event
		if e.pressed:
			if _hit_act(e.position):
				_interact_pressed()
			elif _stick_idx < 0 and e.position.x < ui.size.x * 0.55 and e.position.y > ui.size.y * 0.25:
				_stick_idx = e.index
				pad.base = e.position
				pad.knob = Vector2.ZERO
				pad.on = true
				pad.queue_redraw()
		elif e.index == _stick_idx:
			_stick_idx = -1
			_stick_vec = Vector2.ZERO
			pad.on = false
			pad.queue_redraw()
	elif event is InputEventScreenDrag:
		var d: InputEventScreenDrag = event
		if d.index == _stick_idx:
			var off: Vector2 = (d.position - pad.base)
			var len: float = minf(off.length(), Pad.R)
			pad.knob = off.limit_length(Pad.R)
			_stick_vec = off.limit_length(Pad.R) / Pad.R
			if len / Pad.R < 0.15:
				_stick_vec = Vector2.ZERO
			pad.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and act.visible:
		if _hit_act((event as InputEventMouseButton).position):
			_interact_pressed()


func _hit_act(p: Vector2) -> bool:
	return act.visible and p.distance_to(act.position + act.size * 0.5) <= 84.0


func _interact_pressed() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if mode == "dialog":
		_advance_dialog()
		return
	if mode == "sit":
		if now - _last_adv >= 0.25:
			_stand()
		return
	if mode != "walk":
		return
	if now - _last_adv < 0.25:
		return
	_last_adv = now
	if not _near.is_empty():
		_use(_near)


func _input_vec() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		v.y += 1.0
	if v != Vector2.ZERO:
		v = v.normalized()
	if _stick_vec != Vector2.ZERO:
		v = _stick_vec
	if test_move != Vector2.ZERO:
		v = test_move.limit_length(1.0)
	return v


# ---------------------------------------------------------------- interazione

func _use(o: Dictionary) -> void:
	var id: String = str(o["id"])
	if id == "serranda":
		if gate_open:
			_say([["", "La serranda è alzata. La via porta al Largo del Distributore."]])
		else:
			_say([["", "La serranda è abbassata. Un cartello LibraCorp: «ACCESSO SOLO CON DUE NULLA OSTA DI ZONA»."],
				["", "Uno è di un sorvegliante in Via Elettra (est), l'altro di chi controlla il Vicolo delle Rondini (ovest)."]])
		return
	if id == "boss":
		if bool(WorldV2Ctx.defeated.get("distributore", false)):
			_say([["", "Il distributore è spento. Il display mostra solo: «GRAZIE»."]])
		else:
			_start_encounter({"id": "distributore", "kind": "boss"})
		return
	for t in trainers:
		if str(t["id"]) == id:
			if bool(t["done"]):
				_say([[str(t["name"]), str(t["after"])]])
			else:
				_start_encounter(t)
			return
	if o.has("spray"):
		_spray(int(o["spray"]))
		return
	if o.has("sit"):
		_sit(o)
		return
	if o.has("ni"):
		var n: Dictionary = _npcs[int(o["ni"])]
		var qs: Array = n["quips"]
		var q: String = str(qs[int(n["qi"]) % qs.size()])
		n["qi"] = int(n["qi"]) + 1
		_discover(str(o["did"]), str(o["title"]))
		_say([["" if bool(n["narr"]) else str(n["name"]).to_upper(), q]])
		return
	_discover(str(o["did"]), str(o["title"]))
	_say(o["lines"])


func _find_near() -> Dictionary:
	var best: Dictionary = {}
	var bd: float = 99.0
	for o in talk_objs:
		var d: float = player.distance_to(o["pos"])
		if d <= float(o["radius"]) and d < bd:
			bd = d
			best = o
	return best


# ---------------------------------------------------------------- incontri

func _sees(t: Dictionary) -> bool:
	if bool(t["done"]):
		return false
	var tp: Vector2 = t["pos"]
	var f: Vector2 = t["face"]
	var rel: Vector2 = player - tp
	var along: float = rel.dot(f)
	var side: float = absf(rel.x * f.y - rel.y * f.x)
	if along < 0.4 or along > SIGHT:
		return false
	if side > along * 0.5 + 0.5:
		return false
	# ostacoli sulla linea di vista (escluso il sorvegliante stesso)
	for s in range(1, 7):
		var p: Vector2 = tp.lerp(player, float(s) / 7.0)
		for i in range(obstacles.size()):
			if i == int(t["obst"]):
				continue
			if (obstacles[i] as Rect2).has_point(p):
				return false
	return true


func _start_encounter(t: Dictionary) -> void:
	_enc = t
	_enc_t = 0.0
	mode = "exclaim"
	_stick_idx = -1
	_stick_vec = Vector2.ZERO
	pad.on = false
	pad.queue_redraw()
	prompt.text = ""
	var ex: Label3D = null
	if t.has("excl"):
		ex = t["excl"]
	else:
		ex = _boss_excl()
	ex.visible = true
	ex.scale = Vector3.ONE * EXCL_MIN_SCALE      # mai zero: una matrice non invertibile puo' far cadere il driver grafico dei telefoni
	Settings.buzz(35)
	if Settings.flash > 0.0:
		flash.color = Color(1, 1, 1, 0.38 * Settings.flash)
		var tw := create_tween()
		tw.tween_property(flash, "color:a", 0.0, 0.35)


var _boss_ex: Label3D


func _boss_excl() -> Label3D:
	if _boss_ex == null:
		_boss_ex = _make_excl(Vector3(BOSS_POS.x, 6.6, BOSS_POS.y + 1.0), self, 170)
	return _boss_ex


func _encounter_step(dt: float) -> void:
	_enc_t += dt
	var ex: Label3D = _enc["excl"] if _enc.has("excl") else _boss_excl()
	if mode == "exclaim":
		var k: float = clampf(_enc_t / 0.28, 0.0, 1.0)
		var s: float = 1.0 + 0.45 * sin(k * PI)         # piccolo rimbalzo
		ex.scale = Vector3.ONE * maxf(EXCL_MIN_SCALE, k * s)
		var target: Vector2 = (_enc["pos"] as Vector2) if _enc.has("pos") else BOSS_POS
		facing = -1.0 if target.x < player.x else 1.0
		if _enc_t >= 0.95:
			if str(_enc["kind"] if _enc.has("kind") else "") == "boss":
				_encounter_dialog()
			else:
				mode = "approach"
				_enc_t = 0.0
	elif mode == "approach":
		var tp: Vector2 = _enc["pos"]
		var dist: float = tp.distance_to(player)
		if dist > 1.7:
			var np: Vector2 = tp + (player - tp).normalized() * minf(5.2 * dt, dist - 1.7)
			_enc["pos"] = np
			(_enc["node"] as Node3D).position = Vector3(np.x, 0, np.y)
			(_enc["sprite"] as Sprite3D).flip_h = player.x < np.x
			(_enc["cone"] as Node3D).visible = false
		else:
			_encounter_dialog()


func _encounter_dialog() -> void:
	var lines: Array
	if str(_enc.get("kind", "")) == "boss":
		lines = [
			["", "Il Distributore si accende. Il display mostra due occhi gialli. Tutta la strada vibra."],
			["DISTRIBUTORE", "ERRORE. ERRORE. RESTO NON EROGABILE."],
			["CENTRALE · CAM-07", "Squadra, è lui. Ricordate la scheda: colore giallo, il viola lo colpisce forte. Aprite il fuoco!"]]
	else:
		lines = _enc["pre"]
	var id: String = str(_enc["id"])
	_say(lines, func() -> void: _launch_battle(id))


func _launch_battle(id: String) -> void:
	mode = "fade"
	WorldV2Ctx.active = true
	WorldV2Ctx.pending = id
	WorldV2Ctx.result = ""
	WorldV2Ctx.boss_id = "distributore"
	var back: Vector2 = player
	WorldV2Ctx.pos = back
	WorldV2Ctx.facing = facing
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.3)
	tw.tween_callback(_handoff)


# Prima di caricare la battaglia si libera la mappa 3D (mesh, texture, ambiente) con lo schermo gia' coperto dalla dissolvenza:
# il picco di memoria video resta quello della sola battaglia (su telefono evita di tenere insieme le due scene).
func _handoff() -> void:
	set_process(false)
	set_process_input(false)
	_sprite_cache.clear()
	_burst = null
	for c in get_children():
		if c is Node3D or c is WorldEnvironment:
			c.queue_free()
	cam = null
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree():
		SceneRouter.go("battle_v2", true)


# ---------------------------------------------------------------- ciclo

func _free(p: Vector2) -> bool:
	for dx in [-RADIUS, RADIUS]:
		for dz in [-RADIUS, RADIUS]:
			var q := Vector2(p.x + dx, p.y + dz)
			if not _in_walk(q):
				return false
			for r in obstacles:
				if (r as Rect2).has_point(q):
					return false
	return true


func _process(dt: float) -> void:
	_t += dt
	if mode == "walk":
		_walk(dt)
	elif mode == "exclaim" or mode == "approach":
		_encounter_step(dt)
		_moving = false
	elif mode == "sit":
		_sit_t += dt
		_moving = false
		if _sit_t > 0.5 and _input_vec().length() > 0.3:
			_stand()
	else:
		_moving = false
	if mode != "walk":
		_vel = Vector2.ZERO
		if _dust != null:
			_dust.emitting = false
	_npcs_step(dt)
	_follow(dt)
	_animate(dt)
	_camera(dt, false)
	_hud(dt)


func _walk(dt: float) -> void:
	var v: Vector2 = _input_vec()
	var run: bool = v.length() > 0.05 and (_run_on or Input.is_physical_key_pressed(KEY_SHIFT))
	var tv: Vector2 = v * (RUN_SPEED if run else SPEED)
	_vel = _vel.move_toward(tv, (34.0 if tv.length() > _vel.length() else 44.0) * dt)
	_moving = _vel.length() > 0.25
	if _dust != null:
		_dust.emitting = run and _moving
	if _vel.length() > 0.02:
		var step: Vector2 = _vel * dt
		var np := Vector2(player.x + step.x, player.y)
		if _free(np):
			player = np
		np = Vector2(player.x, player.y + step.y)
		if _free(np):
			player = np
		if absf(v.x) > 0.12:
			facing = 1.0 if v.x > 0.0 else -1.0
		var last: Vector2 = trail[trail.size() - 1]
		if player.distance_to(last) > 0.12:
			trail.append(player)
			if trail.size() > 220:
				trail.remove_at(0)
	# incontri
	for t in trainers:
		if _sees(t):
			_start_encounter(t)
			return
	if not bool(WorldV2Ctx.defeated.get("distributore", false)) and player.distance_to(BOSS_POS) < BOSS_AGGRO:
		_start_encounter({"id": "distributore", "kind": "boss"})


func _follow(dt: float) -> void:
	for i in range(chars.size()):
		var c: Dictionary = chars[i]
		var target: Vector2 = _slot_pos(i)
		var cur: Vector2 = c["pos"]
		var nxt: Vector2 = cur if i == 0 and false else cur.lerp(target, minf(1.0, 14.0 * dt))
		if i == 0:
			nxt = player
		c["moving"] = nxt.distance_to(cur) > 0.4 * dt
		c["pos"] = nxt
		(c["node"] as Node3D).position = Vector3(nxt.x, 0, nxt.y)
		var sp: Sprite3D = c["sprite"]
		if i == 0:
			sp.flip_h = facing < 0.0
		elif nxt.distance_to(cur) > 0.0005:
			sp.flip_h = (nxt.x - cur.x) < -0.0005 if absf(nxt.x - cur.x) > 0.0005 else sp.flip_h


func _animate(_dt: float) -> void:
	var amp: float = clampf(Settings.shake, 0.0, 1.0)
	for i in range(chars.size()):
		var c: Dictionary = chars[i]
		var sp: Sprite3D = c["sprite"]
		var h: float = float(c["h"])
		var bob: float = 0.0
		if bool(c["moving"]):
			bob = absf(sin(_t * 9.0 + float(i) * 1.3)) * 0.09 * amp
		else:
			bob = sin(_t * 2.0 + float(i)) * 0.012 * amp
		sp.position.y = h * 0.5 + bob
		(c["shadow"] as MeshInstance3D).scale = Vector3.ONE * (1.0 - bob * 0.8)
	_sit_drop = lerpf(_sit_drop, 0.24 if mode == "sit" else 0.0, 0.2)
	if not chars.is_empty():
		var s0: Sprite3D = chars[0]["sprite"]
		s0.position.y -= _sit_drop
		s0.scale.y = 1.0 - _sit_drop * 0.6
	for t in trainers:
		var sp2: Sprite3D = t["sprite"]
		sp2.position.y = CHAR_H * 0.5 + sin(_t * 1.6 + (t["home"] as Vector2).x) * 0.012 * amp
		var cone: Node3D = t["cone"]
		if cone.visible:
			var mi: MeshInstance3D = cone.get_child(0)
			var m: StandardMaterial3D = mi.material_override
			m.albedo_color.a = 0.9 if Settings.flash <= 0.0 else 0.65 + 0.3 * sin(_t * 3.0)
	if boss_screen != null and not bool(WorldV2Ctx.defeated.get("distributore", false)):
		var on: bool = Settings.flash <= 0.0 or int(_t * 3.0) % 2 == 0
		(boss_screen.material_override as ShaderMaterial).set_shader_parameter("albedo", Color("#ffe14a") if on else Color("#fff3d6"))


func _camera(dt: float, snap: bool) -> void:
	var tgt := Vector3(player.x + _vel.x * 0.16, 0.9, player.y - 2.2 + _vel.y * 0.16)      # la camera guarda un po' avanti (a nord) e verso dove si va
	var pos: Vector3 = tgt + CAM_OFF
	var want: float = _cam_size_t + (0.9 if _vel.length() > SPEED + 0.5 else 0.0)
	if snap:
		cam.global_position = pos
		cam.size = want
	else:
		cam.global_position = cam.global_position.lerp(pos, minf(1.0, 6.0 * dt))
		cam.size = lerpf(cam.size, want, minf(1.0, 2.2 * dt))
	cam.look_at(cam.global_position - CAM_OFF, Vector3.UP)



func _hud(dt: float) -> void:
	# zona
	var zone: String = ""
	for a in AREAS:
		if (a["rect"] as Rect2).has_point(player):
			zone = str(a["name"])
	if zone != "" and zone != _last_zone:
		_last_zone = zone
		zone_label.text = zone
		_zone_t = 0.0
	_zone_t += dt
	# il nome della zona resta in alto ma si attenua dopo qualche secondo
	zone_label.modulate.a = 1.0
	# oggetto vicino
	_near = _find_near() if mode == "walk" else {}
	if mode == "sit":
		var th: Array = _sit_obj.get("thoughts", [])
		prompt.text = str(th[int(_sit_t / 4.5) % th.size()]) if not th.is_empty() else ""
		act.label = "ALZATI"
		act.live = true
	elif _near.is_empty():
		prompt.text = ""
		act.label = "AZIONE"
		act.live = false
	else:
		var verb: String = str(_near.get("verb", "LEGGI"))
		act.label = verb
		act.live = true
		prompt.text = ("%s · %s" % [verb, str(_near["title"])]) if TouchUi.active() else ("[E]  %s · %s" % [verb, str(_near["title"])])
	# si ridisegna il tasto solo se pulsa (azione disponibile) o se e' appena cambiato: a vuoto non costa nulla
	var sig: String = "%s|%s" % [act.label, act.live]
	if act.live or sig != _act_sig:
		act.pulse += dt
		act.queue_redraw()
	_act_sig = sig
	# esplorazione: zone, panorama, avviso, minimappa
	if mode == "walk":
		_visit_zones()
		if not bool(WorldV2Ctx.read.get("vista", false)) and VISTA_RECT.has_point(player):
			WorldV2Ctx.read["vista"] = true
			_vista_t = 5.5
			_cam_size_t = 16.5
			_discover("panorama", "Panorama dal tetto")
		if _complete_pending:
			_complete_pending = false
			Snd.play("success")
			_say([["CENTRALE · CAM-07", "Operatore… avete visto ogni angolo del quartiere. Nessuno ve l'aveva chiesto."],
				["CENTRALE · CAM-07", "Lo segno a verbale come «passeggiata». È il miglior rapporto della settimana."]])
	if _vista_t > 0.0:
		_vista_t -= dt
		if _vista_t <= 0.0 and mode != "sit":
			_cam_size_t = CAM_SIZE
	if _banner_t > 0.0:
		_banner_t -= dt
		banner.modulate.a = clampf(_banner_t, 0.0, 1.0)
		banner.visible = _banner_t > 0.0
	_mm_t -= dt
	if _mm_t <= 0.0:
		_mm_t = 0.2
		_update_minimap()


func _is_trainer(id: String) -> bool:
	for t in trainers:
		if str(t["id"]) == id:
			return true
	return false
