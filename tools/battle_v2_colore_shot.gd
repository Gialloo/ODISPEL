extends SceneTree
# Screenshot del vantaggio di colore nel V2 (scelta libera e con ATTACCO selezionato).
#   xvfb-run -a godot --path . --resolution 1280x720 -s tools/battle_v2_colore_shot.gd -- <cartella> [touch]
func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = a[0] if a.size() > 0 else "/tmp"
	if a.size() > 1 and a[1] == "touch":
		TouchUi.force = true
	Settings.tutorial_done = true
	var scn: BattleV2 = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate() as BattleV2
	root.add_child(scn)
	await create_timer(1.4).timeout
	var au: Dictionary = scn._slot_unit(0)
	var boss: Dictionary = BattleState.boss(scn._battle())
	for case in [["viola", "giallo", false, "efficace"], ["viola", "giallo", true, "efficace_sel"], ["verde", "rosso", true, "sfavorevole_sel"], ["rosso", "rosso", true, "neutro_sel"]]:
		scn._cancel()
		au["color"] = case[0]
		boss["color"] = case[1]
		scn._refresh()
		if case[2]:
			scn._tap(scn.wheel_front.hits[0].get_center())
		await create_timer(0.9).timeout
		root.get_viewport().get_texture().get_image().save_png(out.path_join("col_%s.png" % case[3]))
	quit(0)
