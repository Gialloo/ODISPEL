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
	env.fog_light_color = Color(0.8, 0.5, 0.52)   # foschia rosa-viola: la città lontana sfuma nel tramonto
	env.fog_density = 0.72
	env.fog_depth_begin = 60.0
	env.fog_depth_end = 400.0
	env.fog_depth_curve = 1.4
	env.fog_sky_affect = 0.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED   # niente riflessi: risparmia la radianza del cielo
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

## 0.14: città LONTANA, solo sfondo. Fascia di palazzine basse a 90-130 m e skyline di grattacieli
## anni 2000 (vetro a fasce, gradoni, antenne) a 150-260 m. Niente vicino al muro dell'arena.
## Tutto in poche MultiMesh senza contorno (costa quasi niente); finestre con texture a griglia
## proiettata nel mondo (triplanar), così ogni palazzo ha finestre della misura giusta.
func _skyline() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var low := []
	var roofs := []
	var towers := []
	var tops := []
	var low_cols := [Color(0.62, 0.42, 0.42), Color(0.55, 0.36, 0.4), Color(0.66, 0.46, 0.4), Color(0.48, 0.34, 0.44)]
	var roof_cols := [Color(0.55, 0.2, 0.22), Color(0.3, 0.22, 0.4), Color(0.6, 0.3, 0.2)]
	# palazzine basse, a fascia continua: fanno da "primo piano" della città
	for i in 46:
		var a := TAU * (i + rng.randf_range(-0.35, 0.35)) / 46.0
		var r := rng.randf_range(140.0, 175.0)   # lontane: dall'arena spuntano appena sopra il muro
		var w := rng.randf_range(10.0, 18.0)
		var h := rng.randf_range(8.0, 15.0)
		var pos := Vector3(sin(a) * r, 0, cos(a) * r)
		var b := Basis(Vector3.UP, a + rng.randf_range(-0.3, 0.3))
		low.append([Transform3D(b.scaled(Vector3(w, h, w * 0.8)), pos + Vector3(0, h * 0.5, 0)), low_cols[rng.randi() % low_cols.size()]])
		if rng.randf() < 0.5:
			var rh := w * 0.35
			roofs.append([Transform3D(b.scaled(Vector3(w * 1.05, rh, w * 0.85)), pos + Vector3(0, h + rh * 0.5, 0)), roof_cols[rng.randi() % roof_cols.size()]])
	# grattacieli anni 2000: torri di vetro, alcune a gradoni, alcune con antenna
	# colori scuri e freddi: in controluce col tramonto diventano sagome, la nebbia fa il resto
	var glass := [Color(0.22, 0.24, 0.38), Color(0.3, 0.24, 0.4), Color(0.18, 0.22, 0.32), Color(0.36, 0.28, 0.38), Color(0.26, 0.3, 0.42)]
	for i in 44:
		var a := TAU * (i + rng.randf_range(-0.4, 0.4)) / 44.0
		var r := rng.randf_range(230.0, 360.0)
		var w := rng.randf_range(14.0, 26.0)
		var h := rng.randf_range(40.0, 105.0)
		var pos := Vector3(sin(a) * r, 0, cos(a) * r)
		var b := Basis(Vector3.UP, rng.randf_range(0, PI))
		var col: Color = glass[rng.randi() % glass.size()]
		towers.append([Transform3D(b.scaled(Vector3(w, h, w)), pos + Vector3(0, h * 0.5, 0)), col])
		var y := h
		if rng.randf() < 0.55:
			# gradone: un corpo più stretto sopra
			var h2 := h * rng.randf_range(0.15, 0.3)
			towers.append([Transform3D(b.scaled(Vector3(w * 0.65, h2, w * 0.65)), pos + Vector3(0, y + h2 * 0.5, 0)), col.lightened(0.08)])
			y += h2
		if rng.randf() < 0.45:
			var ah := rng.randf_range(10.0, 25.0)
			tops.append([Transform3D(Basis().scaled(Vector3(0.8, ah, 0.8)), pos + Vector3(0, y + ah * 0.5, 0)), Color(0.12, 0.08, 0.14)])
	var wt: Array = _window_textures()
	var win: ImageTexture = wt[0]
	var lm := StandardMaterial3D.new()
	lm.vertex_color_use_as_albedo = true
	lm.vertex_color_is_srgb = true   # i colori scuri restano scuri
	lm.albedo_texture = win
	lm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	lm.uv1_triplanar = true
	lm.uv1_world_triplanar = true
	lm.uv1_scale = Vector3(0.07, 0.07, 0.07)   # piani da ~1,8 m: da lontano finestre, non rumore
	lm.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	lm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	# niente emissione: col triplanare sbiancava i palazzi, e senza costa meno; le finestre accese sono già chiare
	var bm := BoxMesh.new()
	_multimesh(bm, lm, low)
	_multimesh(bm, lm, towers)
	var rm := StandardMaterial3D.new()
	rm.vertex_color_use_as_albedo = true
	rm.vertex_color_is_srgb = true
	rm.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	rm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_multimesh(PrismMesh.new(), rm, roofs)
	var am := StandardMaterial3D.new()
	am.vertex_color_use_as_albedo = true
	am.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_multimesh(bm, am, tops)
	_power_lines()

## Griglia di finestre 8x8: molte accese (giallo caldo), alcune spente. Bianco = muro (preso dal colore del palazzo).
func _window_textures() -> Array:
	var img := Image.create(8, 8, false, Image.FORMAT_RGB8)
	var glow := Image.create(8, 8, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for y in 8:
		for x in 8:
			var c := Color(1, 1, 1)
			var g := Color(0, 0, 0)
			if x % 2 == 1 and y % 2 == 1:
				var lit := rng.randf() < 0.5
				c = Color(1.0, 0.85, 0.5) if lit else Color(0.25, 0.22, 0.35)
				g = Color(1.0, 0.8, 0.45) if lit else g
			img.set_pixel(x, y, c)
			glow.set_pixel(x, y, g)
	return [ImageTexture.create_from_image(img), ImageTexture.create_from_image(glow)]

## 0.14: linee elettriche che partono da fuori l'arena e corrono via verso la città, in linea retta:
## pali in fila che si rimpiccioliscono in lontananza, fili tesi da un palo al successivo.
func _power_lines() -> void:
	var poles := []
	var bars := []
	var wires := []
	# ogni linea parte fuori dal muro e scappa via in diagonale: dall'arena si vede di sbieco,
	# con i pali che si rimpiccioliscono e i fili che corrono verso l'orizzonte
	for a in [0.35, 2.4, 4.3]:
		var out := Vector3(sin(a), 0, cos(a))
		var dir := out.rotated(Vector3.UP, 0.55)
		var side := Vector3(dir.z, 0, -dir.x)
		var start := out * 48.0
		var prev_tops: Array = []
		for k in 11:
			var p := start + dir * (k * 26.0)
			var h := 14.0
			var th := 0.45 + k * 0.05          # più spessi lontano, così non spariscono
			poles.append([Transform3D(Basis().scaled(Vector3(th, h, th)), p + Vector3(0, h * 0.5, 0)), Color(0.16, 0.1, 0.12)])
			bars.append([Transform3D(Basis.looking_at(side, Vector3.UP).scaled(Vector3(0.3 + k * 0.03, 0.3 + k * 0.03, 4.6)), p + Vector3(0, h - 0.8, 0)), Color(0.16, 0.1, 0.12)])
			var c := p + Vector3(0, h - 0.6, 0)
			var tops := [c + side * 2.0, c - side * 2.0, c + side * 0.7]
			if not prev_tops.is_empty():
				for w in 3:
					_wire(wires, prev_tops[w], tops[w], 1.4, 0.1 + k * 0.025)
			prev_tops = tops
	var pm := StandardMaterial3D.new()
	pm.vertex_color_use_as_albedo = true
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.5
	cm.height = 1.0
	cm.radial_segments = 5
	_multimesh(cm, pm, poles)
	_multimesh(BoxMesh.new(), pm, bars)
	_multimesh(BoxMesh.new(), pm, wires)

## Filo che pende: quattro tratti dritti con la pancia in mezzo.
func _wire(out: Array, a: Vector3, b: Vector3, sag: float, thick := 0.12) -> void:
	var pts: Array[Vector3] = []
	for k in 5:
		var t := k / 4.0
		pts.append(a.lerp(b, t) - Vector3(0, sag * 4.0 * t * (1.0 - t), 0))
	for k in 4:
		var p0: Vector3 = pts[k]
		var p1: Vector3 = pts[k + 1]
		var d := p0.distance_to(p1)
		var basis := Basis.looking_at(p1 - p0, Vector3.UP).scaled(Vector3(thick, thick, d))
		out.append([Transform3D(basis, (p0 + p1) * 0.5), Color(0.06, 0.04, 0.07)])

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
