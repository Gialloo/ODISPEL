extends SceneTree

# Un solo fendente (VFX-001) in grande, a piu' istanti, per controllarne la forma.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/slash_shot.gd -- <cartella> [mano] [colore] [senza_alone: qualsiasi quarto argomento]

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_run(args[0] if args.size() > 0 else "/tmp", args[1] if args.size() > 1 else "rondini", args[2] if args.size() > 2 else "viola")


func _run(dir: String, hand: String, hue: String) -> void:
	var bg := ColorRect.new()
	bg.color = Color("#1a1030")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	LightPaint.max_live = 40
	LightPaint.halo_enabled = OS.get_cmdline_user_args().size() < 4
	var times: Array = [0.1, 0.17, 0.22, 0.34]
	for i in times.size():
		LightPaint.play(bg, hand, hue, "slash", Vector2(60.0 + float(i) * 320.0, 260.0), Vector2(160.0 + float(i) * 320.0, 360.0), 1.2)
	# un solo tratto per volta sul tempo: si scattano 4 foto distinte
	await create_timer(times[0]).timeout
	root.get_viewport().get_texture().get_image().save_png(dir.path_join("slash_0.png"))
	await create_timer(times[1] - times[0]).timeout
	root.get_viewport().get_texture().get_image().save_png(dir.path_join("slash_1.png"))
	await create_timer(times[2] - times[1]).timeout
	root.get_viewport().get_texture().get_image().save_png(dir.path_join("slash_2.png"))
	await create_timer(times[3] - times[2]).timeout
	root.get_viewport().get_texture().get_image().save_png(dir.path_join("slash_3.png"))
	quit()
