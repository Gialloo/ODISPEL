extends SceneTree

# Immagini dell'apertura reclutamento per ogni rarita':
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/rarity_shots.gd -- cartella

var _out: String = "user://"


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_run()


func _run() -> void:
	await process_frame
	for rarity in 4:
		var host := Control.new()
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(host)
		PullReveal.play(host, [{"char": ["dax", "bruno", "kira", "nova"][rarity], "rarity": rarity, "outcome": "new", "refund": 0}])
		await create_timer(0.45).timeout
		root.get_viewport().get_texture().get_image().save_png(_out.path_join("rar%d.png" % rarity))
		print("salvata ", rarity)
		host.queue_free()
		await create_timer(0.1).timeout
	quit()
