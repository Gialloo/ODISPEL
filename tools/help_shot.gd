extends SceneTree

# Immagine delle pagine "?" di un operatore. Uso: godot --path . -s res://tools/help_shot.gd -- cartella id
func _init() -> void:
	_run()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var scene: Control = load("res://scenes/roster/roster_screen.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout
	scene.select(args[1] if args.size() > 1 else "kira")
	var g: Node = scene.open_legend()
	for i in 3:
		await create_timer(0.3).timeout
		root.get_viewport().get_texture().get_image().save_png(args[0].path_join("help%d.png" % i))
		g.show_page(1, true)
	quit()
