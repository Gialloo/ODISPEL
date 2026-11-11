extends Node3D
## Arena unica: spazio aperto al centro, qualche ostacolo, una piattaforma rialzata
## con rampa (zona speciale). Colori piatti e leggibili, nessuna ombra costosa.

const RADIUS := 22.0
const Prop = preload("res://scripts/world/prop.gd")

func _ready() -> void:
	El.puddles.clear()
	_environment()
	_floor()
	_walls()
	_obstacles()
	_props()

func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.07, 0.11)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.7)
	env.ambient_light_energy = 0.75
	env.fog_enabled = true
	env.fog_light_color = Color(0.07, 0.07, 0.11)
	env.fog_density = 0.012
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(35), 0)
	sun.light_energy = 1.1
	sun.light_color = Color(1.0, 0.96, 0.9)
	sun.shadow_enabled = false
	add_child(sun)

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m

func _static_box(size: Vector3, pos: Vector3, c: Color, rot_y := 0.0) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = 1
	b.position = pos
	b.rotation.y = rot_y
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(c)
	b.add_child(mi)
	add_child(b)
	return b

func _floor() -> void:
	# pavimento a scacchi grandi: fa sentire velocità e distanze
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, Color(0.2, 0.21, 0.26))
	img.set_pixel(1, 1, Color(0.2, 0.21, 0.26))
	img.set_pixel(1, 0, Color(0.17, 0.18, 0.22))
	img.set_pixel(0, 1, Color(0.17, 0.18, 0.22))
	var tex := ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.uv1_scale = Vector3(RADIUS, RADIUS, 1)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(RADIUS * 2.4, 1, RADIUS * 2.4)
	cs.shape = sh
	cs.position.y = -0.5
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(RADIUS * 2.4, RADIUS * 2.4)
	mi.mesh = pm
	mi.material_override = m
	body.add_child(mi)
	add_child(body)
	# cerchio centrale: punto di riferimento
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 5.8
	tm.outer_radius = 6.0
	tm.ring_segments = 3
	tm.rings = 48
	ring.mesh = tm
	ring.scale = Vector3(1, 0.05, 1)
	ring.position.y = 0.01
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(0.35, 0.9, 1.0, 1)
	ring.material_override = rm
	add_child(ring)

func _walls() -> void:
	var n := 24
	for i in n:
		var a := TAU * i / n
		var p := Vector3(sin(a), 0, cos(a)) * (RADIUS + 1.0)
		var h := 4.0 if i % 3 else 6.5
		var c := Color(0.26, 0.27, 0.34) if i % 3 else Color(0.34, 0.3, 0.42)
		_static_box(Vector3(6.2, h, 1.2), p + Vector3(0, h * 0.5, 0), c, a)

func _obstacles() -> void:
	# pilastri: ripari e punti da cui girare intorno
	for p in [Vector3(9, 0, 6), Vector3(-10, 0, 4), Vector3(4, 0, -11), Vector3(-6, 0, -9)]:
		_static_box(Vector3(1.6, 5.0, 1.6), p + Vector3(0, 2.5, 0), Color(0.3, 0.32, 0.4))
	# muretti bassi: si saltano
	_static_box(Vector3(5.0, 1.0, 0.8), Vector3(-2, 0.5, 12), Color(0.36, 0.34, 0.3))
	_static_box(Vector3(0.8, 1.0, 5.0), Vector3(14, 0.5, -3), Color(0.36, 0.34, 0.3), 0.3)
	# piattaforma rialzata con rampa: zona speciale (in Fase 3 diventa interattiva)
	var plat := _static_box(Vector3(7.0, 2.2, 7.0), Vector3(-13, 1.1, -14), Color(0.28, 0.24, 0.36))
	plat.name = "Piattaforma"
	var ramp := StaticBody3D.new()
	ramp.collision_layer = 1
	var len := 6.5
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(3.0, 0.4, len)
	cs.shape = sh
	ramp.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sh.size
	mi.mesh = bm
	mi.material_override = _mat(Color(0.32, 0.28, 0.4))
	ramp.add_child(mi)
	ramp.position = Vector3(-13, 1.0, -7.6)
	ramp.rotation.x = atan2(2.2, len) * 1.0
	add_child(ramp)

## Oggetti manipolabili: casse leggere sparse e blocchi pesanti vicino ai pilastri.
func _props() -> void:
	var light := [Vector3(3, 0, 3), Vector3(-4, 0, 2), Vector3(6, 0, -4), Vector3(-7, 0, -3),
		Vector3(1, 0, -7), Vector3(-2, 0, 8), Vector3(10, 0, 1), Vector3(-11, 0, 9)]
	for p in light:
		_spawn_prop("light", p)
	for p in [Vector3(7.5, 0, 7.5), Vector3(-8, 0, 6), Vector3(5, 0, -9)]:
		_spawn_prop("heavy", p)
	# Fase 3: bidoni, bobine vicino all'acqua, muretti da sfondare
	for p in [Vector3(-3, 0, 4), Vector3(4, 0, 6), Vector3(0, 0, -11)]:
		_spawn_prop("barrel", p)
	_puddle(Vector3(9, 0, -5), 2.6)
	_puddle(Vector3(-4, 0, -5), 2.2)
	_spawn_prop("coil", Vector3(11.5, 0, -6.5))
	_spawn_prop("coil", Vector3(-7, 0, -6.5))
	_spawn_prop("cover", Vector3(-6, 0, 0), 0.4)
	_spawn_prop("cover", Vector3(6, 0, 10.5), -0.3)
	_spawn_prop("cover", Vector3(13, 0, 4), 1.4)

## Ogni oggetto distrutto torna al suo posto dopo un po': l'arena non si svuota.
func _spawn_prop(k: String, p: Vector3, rot := 0.0) -> void:
	var pr := Prop.new()
	pr.setup(k)
	pr.position = p + Vector3(0, 0.0 if k == "coil" or k == "cover" else 0.1, 0)
	pr.rotation.y = rot
	add_child(pr)
	pr.broke.connect(func(_x):
		get_tree().create_timer(12.0 if k == "cover" else 8.0).timeout.connect(func():
			if is_inside_tree():
				_spawn_prop(k, p, rot)
				FX.ring(p, Color(1, 1, 1, 0.5), 1.4, 0.3)))

## Pozza d'acqua: conduce la scossa a chi ci sta dentro, spegne il fuoco.
func _puddle(p: Vector3, r: float) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.02
	cm.radial_segments = 28
	mi.mesh = cm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.25, 0.55, 0.9, 0.45)
	mi.material_override = m
	mi.position = p + Vector3(0, 0.02, 0)
	add_child(mi)
	El.add_puddle(p, r, mi)

func spawn_point() -> Vector3:
	var a := randf() * TAU
	var r := randf_range(10.0, 17.0)
	return Vector3(sin(a) * r, 0.2, cos(a) * r)
