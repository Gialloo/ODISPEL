extends SceneTree

# Reazione al colpo firmata dei quattro (Review 01 del game director, 4/11/2026): Lance alza la guardia e non arretra,
# Nox si piega e si chiude, Rio perde l'equilibrio e ne fa una posa, Saul la scampa per un pelo.
# Fotografa la squadra di profilo a riposo e in tre istanti della reazione, tutti insieme per confrontarli.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_reazioni_colpo.gd -- <cartella>

var out: String = "/tmp/v3reazioni"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	_run()


func _run() -> void:
	await process_frame
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#120b22")
	stage.add_child(env)
	Toon.set_fog(Color("#120b22"), 30.0, 80.0)
	var cam := Camera3D.new()
	cam.fov = 40.0
	stage.add_child(cam)
	cam.current = true
	var cvs: Array = []
	var xs: Array = [-2.4, -0.8, 0.8, 2.4]
	for i in CastVisual.ORDER.size():
		var cv := CharacterVisual.new()
		cv.setup(str(CastVisual.ORDER[i]))
		stage.add_child(cv)
		cv.position = Vector3(xs[i], 0, 0)
		cv.stance = true
		cv.rotation.y = PI * 0.5          # di profilo: il colpo arriva da destra
		cvs.append(cv)
	cam.position = Vector3(0, 1.1, 8.0)
	cam.look_at(Vector3(0, 0.95, 0))
	for i in 20:
		await process_frame
	root.get_texture().get_image().save_png(out.path_join("0_riposo.png"))
	for cv in cvs:
		cv.call("hit")
	# si va a tempo di gioco (somma dei delta), non a orologio: sotto xvfb i primi fotogrammi sono lenti
	var el: float = 0.0
	for step in [[0.07, "1_impatto"], [0.2, "2_reazione"], [0.42, "3_ripresa"]]:
		while el < float(step[0]):
			await process_frame
			el += root.get_process_delta_time()
		print(step[1], " lean ", cvs.map(func(c: Node) -> float: return snappedf(float(c.get("lean")), 0.01)))
		root.get_texture().get_image().save_png(out.path_join(str(step[1]) + ".png"))
	quit()
