extends SceneTree
# Screenshot squadra/ultimate: godot -s tools/battle_v2_squadra_shot.gd -- <dir> [touch]
func _init() -> void:
	_run()
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "/tmp/sq2"
	DirAccess.make_dir_recursive_absolute(dir)
	if args.size() > 1 and args[1] == "touch":
		TouchUi.force = true
	Settings.tutorial_done = true
	var scn = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate()
	root.add_child(scn)
	await create_timer(1.5).timeout
	var b: Dictionary = scn._battle()
	var u1: Dictionary = BattleState.unit(b, str(scn._slot_unit(1)["id"]))
	u1["hp"] = int(float(u1["max_hp"]) * 0.22)
	var u2: Dictionary = BattleState.unit(b, str(scn._slot_unit(2)["id"]))
	u2["hp"] = 0
	scn._refresh()
	await create_timer(0.8).timeout
	root.get_viewport().get_texture().get_image().save_png(dir + "/sq_a.png")
	scn.ult_sempre = false
	var u0: Dictionary = BattleState.unit(b, str(scn._slot_unit(0)["id"]))
	u0["gauge"] = 40
	scn._refresh()
	await create_timer(0.8).timeout
	root.get_viewport().get_texture().get_image().save_png(dir + "/sq_b_ult_non_pronta.png")
	quit(0)
