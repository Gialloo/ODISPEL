extends SceneTree
# Mappa del Test V2: godot -s tools/world_v2_shot.gd -- <dir> [touch]
func _init() -> void:
	_run()
func _shot(dir: String, n: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, n])
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "/tmp/wd"
	DirAccess.make_dir_recursive_absolute(dir)
	if args.size() > 1 and args[1] == "touch":
		TouchUi.force = true
	Settings.tutorial_done = true
	WorldV2Ctx.reset()
	WorldV2Ctx.active = true
	var scn = (load("res://scenes/world_v2/world_v2.tscn") as PackedScene).instantiate()
	root.add_child(scn)
	await create_timer(1.0).timeout
	await _shot(dir, "w_0_intro")
	scn._advance_dialog(); await create_timer(0.3).timeout
	scn._advance_dialog(); await create_timer(0.3).timeout
	scn._advance_dialog(); await create_timer(0.5).timeout
	await _shot(dir, "w_1_start")
	# cammina verso nord-est (piazza)
	scn.test_move = Vector2(0.4, -1.0)
	await create_timer(1.6).timeout
	scn.test_move = Vector2.ZERO
	await create_timer(0.4).timeout
	await _shot(dir, "w_2_walk")
	# verso est: via Elettra fino a farsi vedere
	scn.player = Vector2(5.0, 1.0)
	scn.test_move = Vector2(1.0, 0.0)
	var k := 0
	while scn.mode == "walk" and k < 200:
		await create_timer(0.05).timeout
		k += 1
	await create_timer(0.35).timeout
	print("mode=", scn.mode, " player=", scn.player)
	await _shot(dir, "w_3_exclaim")
	scn.test_move = Vector2.ZERO
	await create_timer(1.2).timeout
	await _shot(dir, "w_4_dialog")
	# terminale
	scn.mode = "walk"; scn.dlg.visible = false
	scn.player = Vector2(1.2, -8.5)
	scn.trail.clear(); scn._seed_trail()
	await create_timer(0.8).timeout
	await _shot(dir, "w_5_terminale")
	scn._interact_pressed()
	await create_timer(0.3).timeout
	await _shot(dir, "w_6_scheda")
	scn.dlg.visible = false; scn.mode = "walk"
	# boss
	scn.player = Vector2(0.0, -29.0)
	scn.trail.clear(); scn._seed_trail()
	scn.gate_open = true
	await create_timer(1.0).timeout
	await _shot(dir, "w_7_largo")
	quit(0)
