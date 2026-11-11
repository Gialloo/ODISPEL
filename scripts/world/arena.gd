extends Node3D
## Arena unica: spazio aperto al centro, qualche ostacolo, una piattaforma rialzata
## con rampa (zona speciale). Colori piatti e leggibili, nessuna ombra costosa.

const RADIUS := 26.0                # 0.6: più larga, centro sgombro per muoversi
const Prop = preload("res://scripts/world/prop.gd")

func _ready() -> void:
	El.puddles.clear()
	_environment()
	_floor()
	_walls()
	_obstacles()
	_props()

func _environment() -> void:
	# 0.11: look da fumetto al tramonto. Cielo arancio che sale al viola, sole basso e caldo per
	# ombre a blocchi lunghe, ombre viola (contrasto caldo/freddo), nebbia calda solo in lontananza:
	# l'arena resta nitida, la città fuori sfuma.
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.32, 0.2, 0.48)
	sm.sky_horizon_color = Color(1.0, 0.58, 0.3)
	sm.sky_curve = 0.12
	sm.ground_horizon_color = Color(1.0, 0.58, 0.3)
	sm.ground_bottom_color = Color(0.42, 0.22, 0.28)
	sm.sun_angle_max = 8.0
	sm.sun_curve = 0.05
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.58, 0.42, 0.62)
	env.ambient_light_energy = 0.5
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(1.0, 0.62, 0.42)
	env.fog_density = 0.85
	env.fog_depth_begin = 26.0
	env.fog_depth_end = 110.0
	env.fog_depth_curve = 1.4
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-24), deg_to_rad(-140), 0)
	sun.light_energy = 1.55
	sun.light_color = Color(1.0, 0.74, 0.5)
	sun.shadow_enabled = false
	add_child(sun)
	_skyline()

## Città al tramonto fuori dall'arena: case con tetti a punta, campanili, finestre accese.
## Tutto in tre MultiMesh (corpi, tetti, finestre): poche chiamate di disegno anche con cento case.
func _skyline() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var walls_cols := [Color(0.96, 0.78, 0.55), Color(0.88, 0.55, 0.38), Color(0.95, 0.66, 0.42), Color(0.78, 0.5, 0.46), Color(0.9, 0.82, 0.68)]
	var roof_cols := [Color(0.62, 0.18, 0.2), Color(0.3, 0.22, 0.42), Color(0.72, 0.3, 0.18), Color(0.22, 0.28, 0.45)]
	var bodies := []
	var roofs := []
	var wins := []
	# tre anelli di case: più alte man mano che si allontanano, così si vedono a strati
	for ring in [[34.0, 30, 4.0, 8.0], [46.0, 34, 6.0, 12.0], [62.0, 30, 9.0, 20.0]]:
		var r0: float = ring[0]
		var n: int = ring[1]
		for i in n:
			var a := TAU * (i + rng.randf_range(-0.3, 0.3)) / n
			var r := r0 + rng.randf_range(-2.5, 2.5)
			var w := rng.randf_range(4.0, 7.5)
			var d := rng.randf_range(4.0, 7.0)
			var h := rng.randf_range(ring[2], ring[3])
			var tower := rng.randf() < 0.12
			if tower:
				w = 3.2
				d = 3.2
				h *= 1.9
			var pos := Vector3(sin(a) * r, 0, cos(a) * r)
			var basis := Basis(Vector3.UP, a + rng.randf_range(-0.2, 0.2))
			bodies.append([Transform3D(basis.scaled(Vector3(w, h, d)), pos + Vector3(0, h * 0.5, 0)), walls_cols[rng.randi() % walls_cols.size()]])
			var rh: float = w * (1.6 if tower else rng.randf_range(0.45, 0.8))
			roofs.append([Transform3D(basis.scaled(Vector3(w * 1.12, rh, d * 1.12)), pos + Vector3(0, h + rh * 0.5, 0)), roof_cols[rng.randi() % roof_cols.size()]])
			# finestre accese sul lato che guarda l'arena
			var face := -pos.normalized()
			var right := Vector3(-face.z, 0, face.x)
			for k in rng.randi_range(1, 3):
				var wy := rng.randf_range(1.5, h - 1.0)
				var wx := rng.randf_range(-w * 0.3, w * 0.3)
				var wp := pos + face * (d * 0.5 + 0.05) + right * wx + Vector3(0, wy, 0)
				var wb := Basis.looking_at(face, Vector3.UP).scaled(Vector3(0.9, 1.3, 1))
				wins.append([Transform3D(wb, wp), Color(1.0, 0.86, 0.45) if rng.randf() < 0.75 else Color(0.25, 0.18, 0.3)])
	var body_mat := StandardMaterial3D.new()
	body_mat.vertex_color_use_as_albedo = true
	body_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	body_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	body_mat.next_pass = FX.outline_mat(0.02)   # piccolo: la MultiMesh lo scala con la casa
	var bm := BoxMesh.new()
	_multimesh(bm, body_mat, bodies)
	var pm := PrismMesh.new()
	_multimesh(pm, body_mat, roofs)
	var win_mat := StandardMaterial3D.new()
	win_mat.vertex_color_use_as_albedo = true
	win_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	win_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var qm := QuadMesh.new()
	_multimesh(qm, win_mat, wins)

func _multimesh(mesh: Mesh, mat: Material, items: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = items.size()
	for i in items.size():
		mm.set_instance_transform(i, items[i][0])
		mm.set_instance_color(i, items[i][1])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	add_child(mmi)

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
	img.set_pixel(0, 0, Color(0.74, 0.55, 0.44))
	img.set_pixel(1, 1, Color(0.74, 0.55, 0.44))
	img.set_pixel(1, 0, Color(0.58, 0.4, 0.36))
	img.set_pixel(0, 1, Color(0.58, 0.4, 0.36))
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
	rm.albedo_color = Color(0.3, 0.13, 0.22, 1)   # 0.11 tramonto; 0.6: più tenue, è solo un riferimento
	ring.material_override = rm
	add_child(ring)

func _walls() -> void:
	# muro continuo e calmo: un solo colore, pochi pannelli più alti come riferimento
	var n := 28
	for i in n:
		var a := TAU * i / n
		var p := Vector3(sin(a), 0, cos(a)) * (RADIUS + 1.0)
		var tall := i % 7 == 0
		var h := 6.0 if tall else 4.0
		var c := Color(0.36, 0.2, 0.4) if tall else Color(0.62, 0.33, 0.27)   # 0.11: mattone caldo, pannelli alti viola
		_static_box(Vector3(6.4, h, 1.2), p + Vector3(0, h * 0.5, 0), c, a)

func _obstacles() -> void:
	# 0.6: pochi ostacoli e tutti ai bordi, il centro resta libero per il combattimento
	for p in [Vector3(15, 0, 11), Vector3(-16, 0, 10)]:
		_static_box(Vector3(1.8, 5.0, 1.8), p + Vector3(0, 2.5, 0), Color(0.42, 0.22, 0.42))
	# un muretto basso da saltare
	_static_box(Vector3(5.0, 1.0, 0.8), Vector3(0, 0.5, 18), Color(0.92, 0.76, 0.58))
	# piattaforma rialzata con rampa: zona speciale
	var plat := _static_box(Vector3(7.0, 2.2, 7.0), Vector3(-15, 1.1, -15), Color(0.48, 0.28, 0.48))
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
	mi.material_override = _mat(Color(0.58, 0.36, 0.52))
	ramp.add_child(mi)
	ramp.position = Vector3(-15, 1.0, -8.6)
	ramp.rotation.x = atan2(2.2, len) * 1.0
	add_child(ramp)

## Oggetti raccolti in tre "postazioni" ai bordi, ognuna con una funzione chiara;
## il centro resta sgombro. Poche cose, ben leggibili.
func _props() -> void:
	# postazione elettrica (est): bobina accanto alla pozza
	_puddle(Vector3(12, 0, -4), 3.0)
	_spawn_prop("coil", Vector3(16, 0, -5))
	# postazione del fuoco (ovest): due bidoni e una cassa
	_spawn_prop("barrel", Vector3(-14, 0, -1))
	_spawn_prop("barrel", Vector3(-15.5, 0, 1.5))
	_spawn_prop("light", Vector3(-11.5, 0, 1))
	# muretto da sfondare (nord) e blocco di metallo (sud-est)
	_spawn_prop("cover", Vector3(2, 0, -15))
	_spawn_prop("heavy", Vector3(9, 0, 14))
	# poche casse leggere a portata del centro, per il potere
	for p in [Vector3(7, 0, 5), Vector3(-6, 0, -7), Vector3(-5, 0, 9)]:
		_spawn_prop("light", p)

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
	var r := randf_range(12.0, 21.0)
	return Vector3(sin(a) * r, 0.2, cos(a) * r)
