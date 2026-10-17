extends SceneTree
# PROVA: esplosione nera dell'ultimate lanciata. xvfb-run -a godot --path . --resolution 1280x720 -s tools/ulti_nera_shot.gd -- <dir>
func _init() -> void:
	var out: String = "/tmp"
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	var scn: BattleV2 = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate() as BattleV2
	root.add_child(scn)
	await create_timer(1.4).timeout
	BattleV2._G.cmds[2]["ok"] = true
	scn._tap(scn.wheel_front.hits[2].get_center())
	await create_timer(0.8).timeout
	root.get_viewport().get_texture().get_image().save_png(out.path_join("ulti_a_selezionata.png"))
	scn.ult_hold = true
	scn._tap(BattleV2.CONFIRM_RECT.get_center())
	for i in 3:
		await create_timer(0.06).timeout
		root.get_viewport().get_texture().get_image().save_png(out.path_join("ulti_b_esplosione_%d.png" % i))
	scn.ult_hold = false
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png(out.path_join("ulti_c_dopo.png"))
	print("cut=", scn.ult_cut)
	quit(0)
