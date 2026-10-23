extends SceneTree

# Vetrina degli asset visivi: i quattro protagonisti (fronte, retro, primo piano) e i nemici, su fondo notte.
# Serve a confrontare i segnaposto con lo stile (docs/STILE_VISIVO.md) senza giocare l'atto.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_vetrina.gd -- <cartella>

var out: String = "/tmp/v3vetrina"
var stage: Node3D
var cam: Camera3D


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	_run()


func _stage() -> void:
	if stage != null:
		stage.queue_free()
		await process_frame
	stage = Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#120b22")
	stage.add_child(env)
	Toon.set_fog(Color("#120b22"), 30.0, 80.0)
	cam = Camera3D.new()
	cam.fov = 40.0
	stage.add_child(cam)
	cam.current = true


func _shot(name: String) -> void:
	for i in 6:
		await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _run() -> void:
	await process_frame
	# protagonisti: fronte e retro
	for view in ["fronte", "retro", "battaglia"]:
		await _stage()
		var xs: Array = [-1.8, -0.6, 0.6, 1.8]
		for i in CastVisual.ORDER.size():
			var cv := CharacterVisual.new()
			cv.setup(str(CastVisual.ORDER[i]))
			stage.add_child(cv)
			cv.position = Vector3(xs[i], 0, 0)
			cv.stance = view == "battaglia"
			cv.rotation.y = 0.0 if view == "retro" else PI
		cam.position = Vector3(0, 1.1, 7.2)
		cam.look_at(Vector3(0, 0.95, 0))
		await _shot("personaggi_" + view)
	# primi piani
	for id in CastVisual.ORDER:
		await _stage()
		var cv := CharacterVisual.new()
		cv.setup(str(id))
		stage.add_child(cv)
		cv.rotation.y = PI - 0.35
		cam.position = Vector3(0, 1.45, 2.3)
		cam.look_at(Vector3(0, 1.3, 0))
		await _shot("primo_piano_" + str(id))
	# Rio dopo il capitolo 3: la maschera incrinata
	Story.chapter = 4
	await _stage()
	var rio := CharacterVisual.new()
	rio.setup("zecca")
	stage.add_child(rio)
	rio.rotation.y = PI - 0.35
	cam.position = Vector3(0, 1.62, 1.1)
	cam.look_at(Vector3(0, 1.58, 0))
	await _shot("primo_piano_zecca_crepa")
	Story.chapter = 0
	# nemici
	var kinds: Array = ["distributore", "semaforo", "cabina", "manichino", "cassaforte", "autovelox", "telecamera", "frammento_giallo"]
	for k in kinds:
		await _stage()
		var m := VendingVisual.new()
		m.kind = str(k)
		m.awake = true
		m.rotation.y = PI
		stage.add_child(m)
		cam.position = Vector3(0, 2.0, 7.5)
		cam.look_at(Vector3(0, 1.6, 0))
		await _shot("nemico_" + str(k))
	# effetti di luce (LightFx) e cupola (SkyDome), fermati a meta' animazione
	await _stage()
	stage.add_child(SkyDome.new())
	var hero := CharacterVisual.new()
	hero.setup("nox")
	hero.stance = true
	stage.add_child(hero)
	hero.position = Vector3(-1.6, 0, 1.5)
	var boss := VendingVisual.new()
	boss.kind = "distributore"
	boss.awake = true
	boss.rotation.y = PI
	stage.add_child(boss)
	boss.position = Vector3(1.4, 0, -1.5)
	hero.look_at(boss.position, Vector3.UP)
	LightFx.seal(stage, boss.position)
	LightFx.glyph(stage, hero.position, CastVisual.col("nox", "accent"))
	cam.fov = 58.0
	cam.position = Vector3(-3.5, 2.2, 6.5)
	cam.look_at(Vector3(0, 1.4, -0.5))
	await create_timer(0.3).timeout
	LightFx.stroke(stage, hero.chest_point(), boss.chest_point(), CastVisual.col("nox", "accent"), 0.32)
	await create_timer(0.2).timeout
	await _shot("effetti_pennellata")
	LightFx.sparks(stage, boss.chest_point(), LightFx.IMPACT, 12)
	await create_timer(0.08).timeout
	await _shot("effetti_scintille")
	LightFx.rise(stage, hero.position, CastVisual.col("nox", "accent"))
	await create_timer(0.3).timeout
	await _shot("effetti_spirale")
	# BREAK: vetro rotto dal petto del nemico, a tre istanti (appena colpito, sospeso, ricaduta). Il vetro e' lo stesso della battaglia.
	var bc := BrokenCam.new()
	root.add_child(bc)
	await process_frame
	var sz: Vector2 = root.get_visible_rect().size
	var u: Vector2 = cam.unproject_position(boss.chest_point())
	bc.shatter("boss", 1.0, Vector2(u.x / sz.x, u.y / sz.y), true)
	for ph in [["break_1_impatto", 0.05], ["break_2_sospeso", 0.35], ["break_3_ricaduta", 0.6]]:
		await create_timer(float(ph[1])).timeout
		await _shot(str(ph[0]))
	bc.queue_free()
	cam.position = Vector3(0, 1.6, 8.0)
	cam.look_at(Vector3(0, 12.0, -40.0))
	await _shot("cielo_cupola")
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(ui)
	LightFx.blackout(ui, CastVisual.col("zecca", "top"))
	await process_frame
	await _shot("effetti_ultimate_nero")
	ui.queue_free()
	quit()
