extends SceneTree
# PROVA: schermo nero con ULTIMATE. xvfb-run -a godot --path . --resolution 1280x720 -s tools/ulti_nera_shot.gd -- <dir>
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
	if a.size() > 1:
		for n in scn.paint_flat: n.visible = false
		for n in scn.paint_light: n.visible = false
	for i in 14:
		await create_timer(0.1).timeout
		if i == 3 or i == 13:
			await process_frame
			root.get_viewport().get_texture().get_image().save_png(out.path_join("ulti_%d.png" % i))
	print("picked=", scn.picked)
	quit(0)
