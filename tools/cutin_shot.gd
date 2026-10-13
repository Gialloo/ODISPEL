extends SceneTree

# Immagine della sequenza dell'ultimate (cut-in) di un personaggio:
#   xvfb-run -a godot --path . --resolution 1200x540 -s res://tools/cutin_shot.gd -- cartella kira

func _init() -> void:
	_run()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0]
	var who: String = args[1] if args.size() > 1 else "kira"
	Settings.tutorial_done = true
	var scene: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout
	if scene._tutorial != null:
		scene._tutorial.queue_free()
	CutIn.play(scene._fx, who, "SPEZZATUTTO", Color("#ff3d6e"))
	await create_timer(0.55).timeout
	root.get_viewport().get_texture().get_image().save_png(out.path_join("cutin_" + who + ".png"))
	quit()
