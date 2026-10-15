extends SceneTree

# Foto dei tratti di luce: 4 mani (righe) x 5 colori (colonne).
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/lightpaint_shot.gd -- <cartella> [line|ring|spiral] [secondi]

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_run(args[0] if args.size() > 0 else "/tmp", args[1] if args.size() > 1 else "line", float(args[2]) if args.size() > 2 else 0.2)


func _run(dir: String, shape: String, when: float) -> void:
	var bg := ColorRect.new()
	bg.color = Color("#1a1030")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	LightPaint.max_live = 60
	var hues: Array = ["rosso", "giallo", "viola", "verde", "blu"]
	for r in LightPaint.HANDS.size():
		for c in hues.size():
			var x: float = 60.0 + float(c) * 245.0
			var y: float = 100.0 + float(r) * 160.0
			if shape == "line":
				LightPaint.play(bg, LightPaint.HANDS[r], hues[c], "line", Vector2(x, y + 40.0), Vector2(x + 190.0, y - 10.0), 1.0)
			else:
				LightPaint.play(bg, LightPaint.HANDS[r], hues[c], shape, Vector2(x + 100.0, y), Vector2(x + 100.0, y), 1.0)
	await create_timer(when).timeout
	root.get_viewport().get_texture().get_image().save_png(dir.path_join("lp_%s.png" % shape))
	quit()
