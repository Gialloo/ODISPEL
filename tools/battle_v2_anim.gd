extends SceneTree

# Fotogrammi dell'animazione della Battaglia V2 (ingresso pennellate, scelta SKILL, scelta ULTIMATE).
#   xvfb-run -a godot --path . --resolution 1280x720 -s tools/battle_v2_anim.gd -- <cartella_output>

var out_dir: String = "/tmp"


func _shot(name: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(out_dir.path_join("anim_%s.png" % name))


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out_dir = a[0]
	var scn := (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate() as BattleV2
	root.add_child(scn)
	await create_timer(0.25).timeout
	await _shot("a_ingresso_025")
	await create_timer(0.1).timeout
	await create_timer(0.35).timeout
	await _shot("b_ingresso_060")
	await create_timer(1.0).timeout
	await _shot("c_libera_flusso")
	scn._tap(scn.wheel_front.hits[1].get_center())
	await create_timer(0.12).timeout
	await _shot("d_skill_012")
	await create_timer(0.6).timeout
	await _shot("e_skill_072")
	scn._cancel()
	await create_timer(0.6).timeout
	scn._slot_unit(scn.cur)["gauge"] = 100
	scn._build_cmds()
	scn._refresh()
	await create_timer(0.7).timeout
	scn._tap(scn.wheel_front.hits[2].get_center())
	await create_timer(0.1).timeout
	await _shot("f_ult_010")
	await create_timer(0.3).timeout
	await _shot("g_ult_040")
	await create_timer(0.8).timeout
	await _shot("h_ult_120")
	print("picked=", scn.picked)
	quit(0)
