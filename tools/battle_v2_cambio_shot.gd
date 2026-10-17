extends SceneTree
# Sequenza del cambio personaggio: godot -s tools/battle_v2_cambio_shot.gd -- <dir> [touch]
func _init() -> void:
	_run()
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "/tmp/cm"
	DirAccess.make_dir_recursive_absolute(dir)
	if args.size() > 1 and args[1] == "touch":
		TouchUi.force = true
	Settings.tutorial_done = true
	Settings.shake = 1.0
	var scn = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate()
	root.add_child(scn)
	await create_timer(1.6).timeout
	root.get_viewport().get_texture().get_image().save_png(dir + "/cm_0.png")
	scn._tap(scn.wheel_front.hits[0].get_center())
	await create_timer(0.4).timeout
	scn._tap(BattleV2.CONFIRM_RECT.get_center())
	var k := 1
	for t in [0.05, 0.1, 0.12, 0.15, 0.3]:
		await create_timer(t).timeout
		root.get_viewport().get_texture().get_image().save_png("%s/cm_%d.png" % [dir, k])
		print("F", k, " cur=", scn.cur, " cam=", scn.cam, " off=", snappedf(scn.hero_off, 0.1))
		k += 1
	quit(0)
