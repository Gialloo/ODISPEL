extends SceneTree

# Portrait SEGNAPOSTO dei dialoghi, resi dai personaggi 3D: mezzo busto, tre quarti verso destra, sfondo trasparente.
# Stessi nomi dei portrait veri (assets/portraits/<id>_<espressione>.png): quando arrivano quelli disegnati, si sostituiscono i file.
# Uso: xvfb-run -a godot --path . --resolution 512x768 -s tools/v3_portraits.gd -- assets/portraits

var out: String = "res://assets/portraits"


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func _run() -> void:
	root.transparent_bg = true
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	env.environment = e
	world.add_child(env)
	Toon.set_fog(Color("#2a2140"), 500.0, 600.0)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	world.add_child(cam)
	cam.current = true
	for id in CastVisual.ORDER:
		var list: Array = CastVisual.EXPR_ORDER.duplicate()
		if id == "zecca":
			list.append("maschera")
		for expr in list:
			var cv := CharacterVisual.new()
			var ov: Dictionary = CastVisual.expression(id, expr)
			ov["no_props"] = true                  # bastoni, carte e mazza coprirebbero il ritratto
			cv.setup(id, ov)
			world.add_child(cv)
			cv.rotation.y = PI + 0.64
			var s: float = float(CastVisual.spec(id)["height"]) / 1.75
			# i copricapi forti (elmo, cappuccio con orecchie, cappello da giullare) alzano la cima
			var top: float = float({"ferri": 2.06, "nox": 2.08, "zecca": 2.16, "saul": 2.04}.get(id, 2.0)) * s
			var bottom: float = 1.16 * s
			cam.size = (top - bottom) * 1.04
			cam.position = Vector3(0.02, (top + bottom) * 0.5, 6.0)
			cam.look_at(Vector3(0.02, (top + bottom) * 0.5, 0), Vector3.UP)
			for f in 4:
				await process_frame
			var img: Image = root.get_texture().get_image()
			img.save_png(out.path_join("%s_%s.png" % [id, expr]))
			cv.queue_free()
			await process_frame
	quit()
