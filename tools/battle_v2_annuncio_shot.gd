extends SceneTree
# Screenshot dell'annuncio del boss nel V2 (mossa normale, pesante con nome lungo, con comando selezionato).
#   xvfb-run -a godot --path . --resolution 1280x720 -s tools/battle_v2_annuncio_shot.gd -- <cartella> [touch]
func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = a[0] if a.size() > 0 else "/tmp"
	if a.size() > 1 and a[1] == "touch":
		TouchUi.force = true
	Settings.tutorial_done = true
	var scn: BattleV2 = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate() as BattleV2
	root.add_child(scn)
	await create_timer(1.4).timeout
	for case in [["scossa", false, "normale"], ["porte", false, "pesante"], ["porte", true, "pesante_selezionato"], ["raffica", true, "normale_tutti_selezionato"]]:
		scn._cancel()
		scn._battle()["telegraph"]["move"] = case[0]
		scn._refresh()
		if case[1]:
			scn._tap(scn.wheel_front.hits[1].get_center())
		await create_timer(0.9).timeout
		root.get_viewport().get_texture().get_image().save_png(out.path_join("ann_%s.png" % case[2]))
	quit(0)
