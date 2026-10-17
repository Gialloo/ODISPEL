extends SceneTree
# Screenshot delle scritte di feedback: godot -s tools/battle_v2_feedback_shot.gd -- <dir> [touch]
func _init() -> void:
	_run()
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "/tmp/fb"
	DirAccess.make_dir_recursive_absolute(dir)
	Settings.tutorial_done = true
	var scn = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate()
	root.add_child(scn)
	await create_timer(1.5).timeout
	var h: String = str(scn._slot_unit(0)["id"])
	var b: String = BattleState.BOSS_ID
	scn._on_events([
		{"t": "damage", "src": h, "dst": b, "amount": 320, "absorbed": 0, "crit": true},
		{"t": "break", "src": h},
		{"t": "heal", "src": h, "dst": h, "amount": 55},
		{"t": "shield", "src": h, "dst": h, "amount": 80},
		{"t": "dodge", "unit": h},
		{"t": "phase", "phase": 2},
	])
	for i in 4:
		await create_timer(0.45).timeout
		root.get_viewport().get_texture().get_image().save_png("%s/fb_%d.png" % [dir, i])
	quit(0)
