class_name TestArena
extends Node3D

# Arena di prova: il parcheggio notturno di ODISPEL, costruito col codice con
# forme semplici (segnaposto). Contiene cio' che serve a provare il movimento:
#   - spazio aperto per correre e schivare;
#   - auto parcheggiate (1,6 m) su cui saltare;
#   - banchina di carico (1,2 m) con gradini e una cassa sopra;
#   - rampa che sale a una terrazza (2,5 m);
#   - piloni e barriere per provare la telecamera contro gli ostacoli;
#   - il Distributore spento in un angolo (il futuro piccolo boss).

const HALF: float = 22.0
const PLAYER_SPAWN: Vector3 = Vector3(0.0, 0.1, 6.0)

var _asphalt: StandardMaterial3D
var _concrete: StandardMaterial3D
var _car: StandardMaterial3D
var _line: StandardMaterial3D


func _ready() -> void:
	_asphalt = ActionTheme.flat_material(Color("#0b1f25"), 0.95)
	_concrete = ActionTheme.flat_material(Color("#1d3d46"), 0.9)
	_car = ActionTheme.flat_material(Color("#14262c"), 0.5)
	_line = ActionTheme.glow_material(Color("#9ceaf5"), 0.5)
	_build_environment()
	_build_ground()
	_build_props()
	_build_skyline()


# ---------- Luci e atmosfera ----------

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#03070a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#3b7f8f")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	env.fog_enabled = true
	env.fog_light_color = Color("#06202a")
	env.fog_density = 0.012
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var moon := DirectionalLight3D.new()
	moon.light_color = Color("#a8e6ff")
	moon.light_energy = 0.55
	moon.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(30.0), 0.0)
	moon.shadow_enabled = true
	moon.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	moon.directional_shadow_max_distance = 30.0
	add_child(moon)

	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_lamp(Vector3(corner.x * (HALF - 3.0), 0.0, corner.y * (HALF - 3.0)))


func _lamp(base: Vector3) -> void:
	_mesh_box(Vector3(0.2, 6.0, 0.2), base + Vector3(0.0, 3.0, 0.0), _concrete, true)
	_mesh_box(Vector3(0.7, 0.15, 0.4), base + Vector3(0.0, 6.0, 0.0), ActionTheme.glow_material(Color("#d6ffff"), 4.0), false)
	var light := OmniLight3D.new()
	light.light_color = Color("#bff8ff")
	light.light_energy = 1.6
	light.omni_range = 12.0
	light.position = base + Vector3(0.0, 5.6, 0.0)
	add_child(light)


# ---------- Suolo e confini ----------

func _build_ground() -> void:
	_mesh_box(Vector3(HALF * 2.0, 1.0, HALF * 2.0), Vector3(0.0, -0.5, 0.0), _asphalt, true)

	# barriere basse visibili + pareti invisibili alte che tengono dentro
	for side in [-1.0, 1.0]:
		_mesh_box(Vector3(HALF * 2.0, 0.9, 0.6), Vector3(0.0, 0.45, side * (HALF - 0.3)), _concrete, true)
		_mesh_box(Vector3(0.6, 0.9, HALF * 2.0), Vector3(side * (HALF - 0.3), 0.45, 0.0), _concrete, true)
		_wall(Vector3(HALF * 2.0, 8.0, 1.0), Vector3(0.0, 4.0, side * (HALF + 0.5)))
		_wall(Vector3(1.0, 8.0, HALF * 2.0), Vector3(side * (HALF + 0.5), 4.0, 0.0))

	# strisce dei posti auto (solo grafica)
	for row_z in [-9.0, 9.0]:
		var x: float = -16.0
		while x <= 16.0:
			_mesh_box(Vector3(0.12, 0.02, 4.8), Vector3(x, 0.011, row_z), _line, false)
			x += 3.2


# ---------- Ostacoli ----------

func _build_props() -> void:
	# auto parcheggiate: si puo' saltare sul tetto
	for spot in [Vector3(-11.2, 0.0, -9.0), Vector3(-1.6, 0.0, -9.0), Vector3(8.0, 0.0, 9.0)]:
		_parked_car(spot)

	# banchina di carico a nord, con gradini e una cassa
	_mesh_box(Vector3(10.0, 1.2, 5.0), Vector3(0.0, 0.6, -18.5), _concrete, true)
	for i in 3:
		var h: float = 0.4 * float(i + 1)
		_mesh_box(Vector3(2.4, h, 0.6), Vector3(-3.5, h * 0.5, -14.3 - 0.6 * float(i)), _concrete, true)
	_mesh_box(Vector3(2.0, 1.6, 2.0), Vector3(3.0, 2.0, -19.0), _car, true)

	# rampa a 20 gradi verso la terrazza a est (alta 2,5 m)
	_mesh_box(Vector3(6.0, 2.5, 8.0), Vector3(16.0, 1.25, 0.0), _concrete, true)
	_mesh_box(Vector3(0.6, 2.0, 8.0), Vector3(18.7, 3.5, 0.0), _concrete, true)
	var ramp_angle: float = deg_to_rad(20.0)
	var ramp_len: float = 2.5 / sin(ramp_angle) + 0.1
	var ramp_mid_x: float = 13.0 - 2.5 / tan(ramp_angle) * 0.5
	var ramp := _mesh_box(Vector3(ramp_len, 0.4, 4.0), Vector3(ramp_mid_x + 0.2 * sin(ramp_angle), 1.25 - 0.2 * cos(ramp_angle), -2.0), _concrete, true)
	ramp.rotation.z = ramp_angle

	# piloni e blocchi di cemento: provano la telecamera contro gli ostacoli
	for p in [Vector3(-6.0, 0.0, 2.0), Vector3(5.0, 0.0, 4.5)]:
		_mesh_box(Vector3(0.9, 5.0, 0.9), p + Vector3(0.0, 2.5, 0.0), _concrete, true)
	_mesh_box(Vector3(3.0, 0.8, 1.0), Vector3(-12.0, 0.4, 4.0), _concrete, true)
	_mesh_box(Vector3(1.0, 0.8, 3.0), Vector3(-3.0, 0.4, 14.0), _concrete, true)

	_distributor(Vector3(-17.5, 0.0, 17.5))


func _parked_car(spot: Vector3) -> void:
	_mesh_box(Vector3(1.9, 1.0, 4.2), spot + Vector3(0.0, 0.5, 0.0), _car, true)
	_mesh_box(Vector3(1.6, 0.6, 2.2), spot + Vector3(0.0, 1.3, 0.2), _car, true)
	var tail := ActionTheme.glow_material(ActionTheme.RD, 2.5)
	for side in [-0.7, 0.7]:
		_mesh_box(Vector3(0.35, 0.12, 0.05), spot + Vector3(side, 0.75, 2.11), tail, false)


# Il Distributore: un distributore automatico posseduto. Qui e' spento.
func _distributor(base: Vector3) -> void:
	var body := _mesh_box(Vector3(1.4, 2.3, 1.0), base + Vector3(0.0, 1.15, 0.0), ActionTheme.flat_material(Color("#0c222a"), 0.4), true)
	body.rotation.y = deg_to_rad(-45.0)   # guarda verso il centro
	var glass := _mesh_box(Vector3(0.8, 1.3, 0.04), Vector3(-0.2, 0.0, -0.51), ActionTheme.glow_material(ActionTheme.CY_DIM, 1.2), false)
	glass.reparent(body, false)
	for side in [-0.3, 0.3]:
		var eye := _mesh_box(Vector3(0.25, 0.1, 0.04), Vector3(side, 0.95, -0.51), ActionTheme.glow_material(ActionTheme.RD, 3.0), false)
		eye.reparent(body, false)
	var sign_label := Label3D.new()
	sign_label.text = "ESAURITO"
	sign_label.font_size = 48
	sign_label.pixel_size = 0.006
	sign_label.modulate = ActionTheme.WH
	sign_label.position = Vector3(0.0, 0.75, -0.53)
	sign_label.rotation.y = PI
	body.add_child(sign_label)


# Palazzi lontani oltre il parcheggio: solo sagome con una striscia di finestre.
func _build_skyline() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var building := ActionTheme.flat_material(Color("#061a20"), 1.0)
	var windows := ActionTheme.glow_material(Color("#8ff6ff"), 0.8)
	for i in 16:
		var angle: float = TAU * float(i) / 16.0 + rng.randf_range(-0.1, 0.1)
		var dist: float = rng.randf_range(70.0, 90.0)
		var h: float = rng.randf_range(18.0, 45.0)
		var w: float = rng.randf_range(10.0, 18.0)
		var pos := Vector3(cos(angle) * dist, h * 0.5, sin(angle) * dist)
		var b := _mesh_box(Vector3(w, h, w), pos, building, false)
		b.rotation.y = PI * 0.5 - angle   # finestre verso il parcheggio
		var strip := _mesh_box(Vector3(w * 0.7, 0.4, 0.05), Vector3(0.0, rng.randf_range(-h * 0.3, h * 0.4), -w * 0.5 - 0.03), windows, false)
		strip.reparent(b, false)


# ---------- Utilita' ----------

# Scatola con mesh; se solid, anche con collisione (livello WORLD).
func _mesh_box(size: Vector3, pos: Vector3, material: Material, solid: bool) -> Node3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	if not solid:
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.position = pos
		add_child(mesh)
		return mesh
	var body := StaticBody3D.new()
	body.collision_layer = GameLayers.WORLD
	body.collision_mask = 0
	body.position = pos
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	body.add_child(mesh)
	add_child(body)
	return body


func _wall(size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = GameLayers.WORLD
	body.collision_mask = 0
	body.position = pos
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	add_child(body)
