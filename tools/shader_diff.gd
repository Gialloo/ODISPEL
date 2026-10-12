extends SceneTree

# Confronta due versioni dello shader del velo: stesso disegno, pixel per pixel.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/shader_diff.gd -- vecchio.gdshader nuovo.gdshader

func _initialize() -> void:
	_run()


func _render(path: String, on_top: bool) -> Image:
	var rect := ColorRect.new()
	rect.size = Vector2(1280, 720)
	var m := ShaderMaterial.new()
	m.shader = load(path)
	m.set_shader_parameter("noise_strength", 0.0)       # il rumore dipende dal tempo
	m.set_shader_parameter("dots_on_top", on_top)
	rect.material = m
	var bg := ColorRect.new()
	bg.color = Color("#0c3038")
	bg.size = Vector2(1280, 720)
	root.add_child(bg)
	root.add_child(rect)
	await process_frame
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	rect.queue_free()
	bg.queue_free()
	await process_frame
	return img


func _run() -> void:
	await process_frame
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for on_top in [true, false]:
		var a: Image = await _render(args[0], on_top)
		var b: Image = await _render(args[1], on_top)
		var worst: float = 0.0
		var total: float = 0.0
		var n: int = 0
		for y in range(260, 720):                    # sotto la banda che scorre col tempo
			for x in range(0, 1280, 3):
				var ca: Color = a.get_pixel(x, y)
				var cb: Color = b.get_pixel(x, y)
				var d: float = maxf(absf(ca.r - cb.r), maxf(absf(ca.g - cb.g), absf(ca.b - cb.b)))
				worst = maxf(worst, d)
				total += d
				n += 1
		print("dots_on_top=%s  differenza massima %.4f (su 1.0)  media %.6f" % [on_top, worst, total / float(n)])
	quit(0)
