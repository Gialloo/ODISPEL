extends SceneTree

# Immagini del tutorial e delle impostazioni (serve un display, anche virtuale):
#   godot --path . --resolution 1280x720 -s res://tools/tutorial_shot.gd -- cartella_uscita

var _out: String = "user://"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_run()


func _shot(name: String, wait: float = 0.35) -> void:
	await create_timer(wait).timeout
	root.get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
	print("salvata ", name)


func _run() -> void:
	await process_frame
	Settings.path = "user://shot_settings.cfg"
	MissionConfig.set_mission("distributore", 0)
	var scene: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.8).timeout
	for i in 6:
		await _shot("tutorial_%d" % (i + 1))
		if scene._tutorial != null:
			scene._tutorial.next()
	scene.queue_free()
	var hub: Node = load("res://scenes/hub/hub_demo.tscn").instantiate()
	root.add_child(hub)
	current_scene = hub
	await create_timer(0.3).timeout
	SettingsPanel.open(hub)
	await _shot("impostazioni")
	quit(0)
