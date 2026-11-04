extends SceneTree

# COLPO FINALE DIVERSO PER OGNI NEMICO: registra la piccola morte di ogni Anomalia (VendingVisual.ko()) fotogramma per fotogramma,
# su fondo notte, per vederle senza giocare. Un fotogramma ogni 1/30 s: con ffmpeg diventano clip.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 --fixed-fps 30 -s tools/v3_finali.gd -- <cartella> [nemico]

const KINDS: Array = ["semaforo", "cassaforte", "telecamera", "autovelox", "cabina", "distributore", "manichino", "frammento_giallo"]

var out: String = "/tmp/v3finali"
var only: String = ""
var stage: Node3D
var cam: Camera3D


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		only = args[1]
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
	stage.add_child(SkyDome.new())
	cam = Camera3D.new()
	cam.fov = 50.0
	stage.add_child(cam)
	cam.current = true


func _run() -> void:
	await process_frame
	for k in KINDS:
		if only != "" and not str(k).begins_with(only):
			continue
		await _stage()
		var dir: String = "%s/%s" % [out, str(k).split("_")[0]]
		DirAccess.make_dir_recursive_absolute(dir)
		var m := VendingVisual.new()
		m.kind = str(k)
		m.awake = true
		m.rotation.y = PI
		stage.add_child(m)
		cam.position = Vector3(-2.2, 2.4, 8.0)
		cam.look_at(Vector3(0.6, 1.4, 0))
		for i in 12:
			await process_frame
		var f: int = 0
		for i in 8:
			await process_frame
			root.get_texture().get_image().save_png("%s/f%03d.png" % [dir, f])
			f += 1
		m.ko()
		for i in 60:
			await process_frame
			root.get_texture().get_image().save_png("%s/f%03d.png" % [dir, f])
			f += 1
		print("FINALE ", k, " fotogrammi ", f)
	quit()
