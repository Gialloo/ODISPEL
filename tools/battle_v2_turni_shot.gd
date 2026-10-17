extends SceneTree
# Sequenza AUTO a turni: godot -s tools/battle_v2_turni_shot.gd -- <dir> [touch]
func _init() -> void:
	_run()
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "/tmp/tn"
	DirAccess.make_dir_recursive_absolute(dir)
	if args.size() > 1 and args[1] == "touch":
		TouchUi.force = true
	Settings.tutorial_done = true
	Settings.shake = 1.0
	var scn = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate()
	root.add_child(scn)
	await create_timer(1.5).timeout
	scn.ult_sempre = false
	scn._auto_round()
	for i in 12:
		await create_timer(0.45).timeout
		var caps := []
		for n in get_nodes_in_group("v2_fb"):
			if n is Label: caps.append((n as Label).text)
		print("T%d turn_i=%d cur=%d boss_turn=%s cam=%s caps=%s" % [i, scn.turn_i, scn.cur, scn.boss_turn, snapped(scn.cam.x, 1.0), caps])
		root.get_viewport().get_texture().get_image().save_png("%s/tn_%02d.png" % [dir, i])
	quit(0)
