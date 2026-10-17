extends SceneTree
# Round vero con didascalie/esiti: godot -s tools/battle_v2_esito_shot.gd -- <dir> [touch]
func _init() -> void:
	_run()
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "/tmp/es"
	DirAccess.make_dir_recursive_absolute(dir)
	if args.size() > 1 and args[1] == "touch":
		TouchUi.force = true
	Settings.tutorial_done = true
	var scn = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate()
	root.add_child(scn)
	await create_timer(1.5).timeout
	scn.ult_sempre = false
	scn._auto_round()
	for i in 8:
		await create_timer(0.3).timeout
		var txt := []
		for n in get_nodes_in_group("v2_fb"):
			txt.append([(n as Label).text, (n as Control).position, (n as Control).size.x])
		print("T", i, " ", txt)
		root.get_viewport().get_texture().get_image().save_png("%s/es_%d.png" % [dir, i])
	quit(0)
