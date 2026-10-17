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
const CAM_OFF: Vector3 = Vector3(0.0, 8.5, 12.5)
const GATE_RECT: Rect2 = Rect2(-3.0, -15.4, 6.0, 0.8)

# Zone camminabili (x, z, larghezza, profondita'); z negativa = nord
const AREAS: Array = [
	{"name": "PIAZZA DEL NODO", "rect": Rect2(-9, -4, 18, 15)},
	{"name": "VIA ELETTRA", "rect": Rect2(9, -1, 14, 6)},
	{"name": "VICOLO DELLE RONDINI", "rect": Rect2(-23, 3, 14, 6)},
	{"name": "VIA DELLA SERRANDA", "rect": Rect2(-3, -26, 6, 22)},
	{"name": "LARGO DEL DISTRIBUTORE", "rect": Rect2(-10, -40, 20, 14)},
]

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
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec3 light_dir = vec3(-0.5, 0.85, 0.45);
varying vec3 wn;
void vertex() { wn = normalize((MODEL_NORMAL_MATRIX * NORMAL)); }
void fragment() {
	vec3 c = albedo.rgb;
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

func _ready() -> void:
	Settings.load_settings()
	roster = RosterStore.load_or_new()
	var team: Array = roster.get("team", [])
	for i in range(mini(team.size(), BattleTypes.FRONT_SIZE)):
		party.append(str(team[i]))
	if party.is_empty():
		party = ["kira"]
	_build_env()
	_build_map()
	_build_party()
	_build_ui()
	if WorldV2Ctx.pos != Vector2.INF:
		player = WorldV2Ctx.pos
		facing = WorldV2Ctx.facing
	_seed_trail()
	_apply_progress()
	_place_all()
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
	cam.fov = 34.0
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
	for k in range(3):
		var y: int = 8 + rng.randi() % 230
		img.fill_rect(Rect2i(0, y, 128, 2), Color(0.0, 0.0, 0.0, 1.0).lerp(Color.WHITE, 0.7))
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
	var tints: Array = [Color("#ff9bd0"), Color("#7ff2ee"), Color("#ffb86b"), Color("#b79cff"), Color("#ffe97a")]
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
	var line_m: ShaderMaterial = _mat(Color("#ffe14a"), 1.0, 0.0)
	var zz: float = -5.0
	while zz > -25.0:
		_box(Vector3(0, 0.03, zz), Vector3(0.45, 0.03, 1.3), line_m)
		zz -= 2.6
	var xx: float = 11.0
	while xx < 22.5:
		_box(Vector3(xx, 0.03, 2.0), Vector3(1.3, 0.03, 0.45), line_m)
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
		_box(Vector3(-2.25 + i * 0.9, 0.03, -3.3), Vector3(0.55, 0.03, 1.6), _mat(CREAM, 1.0, 0.0))


func _lamp(p: Vector3, c: Color, _with_light: bool) -> void:
	_cyl(p + Vector3(0, 1.6, 0), 0.08, 3.2, _mat(INK, 0.0, 0.04))
	var bulb: MeshInstance3D = _box(p + Vector3(0, 3.25, 0), Vector3(0.5, 0.26, 0.5), _mat(c, 1.0, 0.06))
	bulb.name = "Bulb"


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
						h = 0.7 + rng.randf() * 0.35          # davanti alla camera: bassissimi (fioriere/recinti), per non coprire la vista
						depth = 1.3
					elif side >= 2 and mid_z_of(r, side, pos + w * 0.5) > 1.0:
						h = 0.7 + rng.randf() * 0.35          # pareti laterali verso la camera: bassissime, non nascondono i passaggi
						depth = 1.3
					var mid: Vector2 = _edge_point(r, side, pos + w * 0.5, depth * 0.5)
					var size3: Vector3 = Vector3(w, h, depth) if horizontal else Vector3(depth, h, w)
					var bm: ShaderMaterial = _mat(POP[rng.randi() % POP.size()], 0.0, 0.14)
					bm.set_shader_parameter("use_tex", true)
					bm.set_shader_parameter("tex", _wmats[rng.randi() % _wmats.size()])
					bm.set_shader_parameter("uv_scale", Vector2(maxf(1.0, w / 3.4), maxf(0.6, h / 6.8)))
					_box(Vector3(mid.x, h * 0.5, mid.y), size3, bm)
					_box(Vector3(mid.x, h + 0.1, mid.y), Vector3(size3.x + 0.2, 0.2, size3.z + 0.2), _mat(POP[(rng.randi() + 2) % POP.size()], 0.0, 0.07))
					# insegna sulle facce rivolte a sud (le piu' visibili) e qualche volta sulle altre
					if side == 0 and h > 5.5 and w > 2.8 and rng.randf() < 0.55:
						var col: Color = sign_cols[ni % sign_cols.size()]
						var face: Vector2 = _edge_point(r, side, pos + w * 0.5, -0.05)
						_text3d(names[ni % names.size()], Vector3(face.x, 3.1, face.y), 42, col, self)
						ni += 1
					pos += w
				cur = run_end


func mid_z_of(r: Rect2, side: int, along: float) -> float:
	return _edge_point(r, side, along, 0.0).y


# punto a distanza `out` fuori dal lato `side` del rettangolo, a `along` dall'inizio del lato
func _edge_point(r: Rect2, side: int, along: float, out: float) -> Vector2:
	match side:
		0: return Vector2(r.position.x + along, r.position.y - out)
		1: return Vector2(r.position.x + along, r.end.y + out)
		2: return Vector2(r.position.x - out, r.position.y + along)
	return Vector2(r.end.x + out, r.position.y + along)


func _prop(c2: Vector2, size3: Vector3, col: Color, emit: float = 0.0, collide: bool = true) -> MeshInstance3D:
	var mi: MeshInstance3D = _box(Vector3(c2.x, size3.y * 0.5, c2.y), size3, _mat(col, emit))
	if collide:
		obstacles.append(Rect2(c2.x - size3.x * 0.5, c2.y - size3.z * 0.5, size3.x, size3.z))
	return mi


func _talk(id: String, c2: Vector2, title: String, lines: Array, radius: float = 1.9) -> void:
	talk_objs.append({"id": id, "pos": c2, "title": title, "lines": lines, "radius": radius})


func _props() -> void:
	# distributore guasto (la prima cosa che si vede: avvisa del tono)
	_prop(Vector2(-6.4, -3.3), Vector3(0.95, 1.9, 0.8), Color("#ff3d8b"))
	_box(Vector3(-6.4, 1.15, -2.88), Vector3(0.7, 1.0, 0.05), _mat(Color("#ffcf5a"), 1.8))
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
	_talk("tombino", Vector2(3.2, 7.0), "Tombino", [
		["", "Il tombino è tiepido. Un filo di vapore arancione esce dalle fessure e profuma di ferro."],
		["", "Le Anomalie urbane, di notte, preferiscono i posti dove la gente non guarda."]], 1.5)
	# semaforo che lampeggia (via Elettra)
	_prop(Vector2(9.9, -0.3), Vector3(0.18, 3.2, 0.18), Color("#0b0814"))
	_box(Vector3(9.9, 3.2, -0.3), Vector3(0.45, 1.1, 0.35), _mat(Color("#0b0814")))
	_box(Vector3(9.9, 3.55, -0.1), Vector3(0.2, 0.2, 0.05), _mat(Color("#ff5a4f"), 2.4))
	_box(Vector3(9.9, 3.2, -0.1), Vector3(0.2, 0.2, 0.05), _mat(Color("#ffd23f"), 0.5))
	_box(Vector3(9.9, 2.85, -0.1), Vector3(0.2, 0.2, 0.05), _mat(Color("#4fd17a"), 0.5))
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
	_box(Vector3(-21.25, 1.4, 5.5), Vector3(0.05, 1.6, 0.8), _mat(Color("#bfe9ff"), 1.0))
	_talk("cabina", Vector2(-20.4, 5.5), "Cabina telefonica", [
		["", "La cornetta è sganciata. Dall'altra parte, qualcuno respira piano."],
		["", "Riattacchi. Il filo, notate, non è collegato a niente."]], 1.9)
	# casse e luci nel vicolo
	_prop(Vector2(-12.0, 3.7), Vector3(1.0, 0.8, 0.8), Color("#ffe14a"))
	_prop(Vector2(-18.5, 8.2), Vector3(1.0, 0.8, 0.8), Color("#ffe14a"))
	# terminale LibraCorp: la scheda del Distributore (cosa fa e come si contrasta)
	_prop(Vector2(2.35, -9.5), Vector3(0.8, 1.5, 0.6), Color("#8a5bff"))
	_box(Vector3(2.35, 1.2, -9.18), Vector3(0.6, 0.5, 0.05), _mat(Color("#4fe3ff"), 2.0))
	_text3d("LIBRACORP\nSCHEDA ANOMALIA", Vector3(2.35, 1.95, -9.15), 20, Color("#4fe3ff"))
	_talk("terminale", Vector2(1.5, -9.5), "Terminale LibraCorp", _boss_card(), 2.0)
	# serranda: interazione con la serranda, il testo dipende dallo stato
	_talk("serranda", Vector2(0, -13.7), "Serranda", [], 2.4)


# Scheda del Distributore, ricavata dai dati del motore (colore, ciclo di mosse, vantaggio)
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
	_talk("boss", Vector2(BOSS_POS.x, BOSS_POS.y + 3.0), "Il Distributore", [], 2.0)


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
		_talk(str(t["id"]), pp + Vector2(-(t["face"] as Vector2).x * 0.0, 0.0), str(t["name"]), [], 1.9)


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
		obj_label.text = "ANOMALIA CHIUSA · Test V2 completato. Puoi continuare a esplorare."
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
	prompt.size = Vector2(700, 40)
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

	if not touch:
		var help := BattleTheme.make_label("WASD / FRECCE = CAMMINA   ·   E / INVIO = INTERAGISCI   ·   ESC = MENU", 14, BattleTheme.CY_DIM)
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
	prompt.position = Vector2(s.x * 0.5 - 350, s.y - (250 if touch else 250))
	pad.size = s
	pad.home = Vector2(190, s.y - 190)
	act.position = Vector2(s.x - 230, s.y - 260)
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
	if mode != "walk":
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
	ex.scale = Vector3.ZERO
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
		ex.scale = Vector3.ONE * (k * s)
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
	tw.tween_callback(func() -> void: SceneRouter.go("battle_v2", true))


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
	else:
		_moving = false
	_follow(dt)
	_animate(dt)
	_camera(dt, false)
	_hud(dt)


func _walk(dt: float) -> void:
	var v: Vector2 = _input_vec()
	_moving = v.length() > 0.05
	if _moving:
		var step: Vector2 = v * SPEED * dt
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
	var tgt := Vector3(player.x, 0.9, player.y)
	var pos: Vector3 = tgt + CAM_OFF
	if snap:
		cam.global_position = pos
	else:
		cam.global_position = cam.global_position.lerp(pos, minf(1.0, 6.0 * dt))
	cam.look_at(cam.global_position - CAM_OFF, Vector3.UP)
	if Settings.shake > 0.0:
		cam.rotate_object_local(Vector3.FORWARD, deg_to_rad(-2.5))


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
	if _near.is_empty():
		prompt.text = ""
		act.label = "AZIONE"
		act.live = false
	else:
		var verb: String = "PARLA" if _is_trainer(str(_near["id"])) else ("AFFRONTA" if str(_near["id"]) == "boss" else "LEGGI")
		act.label = verb
		act.live = true
		prompt.text = ("%s · %s" % [verb, str(_near["title"])]) if TouchUi.active() else ("[E]  %s · %s" % [verb, str(_near["title"])])
	act.pulse += dt
	act.queue_redraw()


func _is_trainer(id: String) -> bool:
	for t in trainers:
		if str(t["id"]) == id:
			return true
	return false
