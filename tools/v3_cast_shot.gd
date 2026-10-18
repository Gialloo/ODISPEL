extends SceneTree

# Foto di riferimento dei segnaposto: per ogni personaggio fronte, tre quarti, lato e retro su fondo neutro.
# Uso: xvfb-run -a godot --path . --resolution 1600x900 -s tools/v3_cast_shot.gd -- <cartella>

var out: String = "/tmp/cast"
var face: bool = false


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	face = args.has("face")
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#2a2140")
	env.environment = e
	world.add_child(env)
	Toon.set_fog(Color("#2a2140"), 200.0, 300.0)
	var cam := Camera3D.new()
	cam.fov = 30.0
	world.add_child(cam)
	cam.current = true
	for id in CastVisual.ORDER:
		var row := Node3D.new()
		world.add_child(row)
		var angles: Array = [0.0, PI * 0.25, PI * 0.5, PI]
		for i in angles.size():
			var cv := CharacterVisual.new()
			cv.setup(id)
			row.add_child(cv)
			cv.position = Vector3((-1.2 + 0.8 * i) if face else (-2.7 + 1.8 * i), 0, 0)
			cv.rotation.y = PI + float(angles[i])
		if face:
			cam.position = Vector3(0, 1.62, 3.4)
			cam.look_at(Vector3(0, 1.58, 0), Vector3.UP)
		else:
			cam.position = Vector3(0, 1.0, 7.0)
			cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
		for f in 6:
			await process_frame
		root.get_texture().get_image().save_png(out + "/" + id + ".png")
		row.queue_free()
		await process_frame
	quit()
