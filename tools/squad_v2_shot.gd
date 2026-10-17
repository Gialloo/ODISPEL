extends SceneTree

# Prova della schermata SQUADRA V2: screenshot delle schede e azioni vere (potenzia, equipaggia, squadra, combatti).
#   xvfb-run -a godot --path . --resolution 1280x720 -s tools/squad_v2_shot.gd -- <cartella_output>

var out_dir: String = "/tmp"


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(out_dir.path_join("sq_%s.png" % name))


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out_dir = a[0]
	if a.size() > 1 and a[1] == "touch":
		TouchUi.force = true
	var scn: SquadV2 = (load("res://scenes/squad_v2/squad_v2.tscn") as PackedScene).instantiate() as SquadV2
	scn.save_path = "user://squad_test.json"
	root.add_child(scn)
	await create_timer(1.0).timeout
	var fails: int = 0
	scn.test_resources()
	await _shot("1_potenzia")
	var lv0: int = int(scn.roster["characters"][scn.selected]["level"])
	scn.upgrade()
	if int(scn.roster["characters"][scn.selected]["level"]) != lv0 + 1:
		fails += 1
		print("FALLITO: potenzia")
	scn.select("dax")
	await create_timer(0.8).timeout
	scn._set_tab("equip")
	await create_timer(0.3).timeout
	await _shot("2_equip")
	scn.equip_slot = "skill0"
	scn.refresh()
	await create_timer(0.3).timeout
	await _shot("3_equip_mosse")
	scn._set_tab("leggenda")
	await create_timer(0.3).timeout
	await _shot("4_leggenda")
	var n0: int = (scn.roster["team"] as Array).size()
	scn.toggle_team()
	if (scn.roster["team"] as Array).size() != n0 - 1:
		fails += 1
		print("FALLITO: togli squadra")
	scn.toggle_team()
	# squadra piena: un operatore di riserva prende il posto di quello scelto
	RosterState.add_character(scn.roster, "rex")
	scn.refresh(false)
	scn.select("kira")
	scn.select("rex")
	await create_timer(0.5).timeout
	scn._set_tab("potenzia")
	await create_timer(0.3).timeout
	await _shot("5_riserva")
	scn.toggle_team()
	if not (scn.roster["team"] as Array).has("rex") or (scn.roster["team"] as Array).has("kira") or (scn.roster["team"] as Array).size() != 6:
		fails += 1
		print("FALLITO: sostituzione")
	await create_timer(0.4).timeout
	await _shot("6_dopo")
	print("FINE fails=%d squadra=%s" % [fails, str(scn.roster["team"])])
	scn.fight()
	await create_timer(4.0).timeout
	var cur: Node = current_scene
	print("SCENA DOPO COMBATTI: ", cur.scene_file_path if cur != null else "nessuna")
	quit()
