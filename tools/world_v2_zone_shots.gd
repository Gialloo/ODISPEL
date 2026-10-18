extends SceneTree
# Giro delle zone nuove: godot -s tools/world_v2_zone_shots.gd -- <dir> [touch]
func _init() -> void:
	_run()
func _shot(dir: String, n: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, n])
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "/tmp/wz"
	DirAccess.make_dir_recursive_absolute(dir)
	if args.size() > 1 and args[1] == "touch":
		TouchUi.force = true
	Settings.tutorial_done = true
	WorldV2Ctx.reset()
	WorldV2Ctx.active = true
	WorldV2Ctx.read["intro"] = true
	var scn = (load("res://scenes/world_v2/world_v2.tscn") as PackedScene).instantiate()
	root.add_child(scn)
	await create_timer(0.8).timeout
	var spots := {
		"mercato": Vector2(33, 1.5), "terrazza": Vector2(36, -12), "vista": Vector2(36, -19.5), "cortile": Vector2(-34, 7),
		"rane": Vector2(-36, -3), "boschetto": Vector2(-35, -23), "canale": Vector2(0, 19), "banchina": Vector2(20, 21),
		"ponte": Vector2(33, 20.7), "isolotto": Vector2(45, 22), "piazza": Vector2(0, 7)}
	for k in spots:
		scn.player = spots[k]
		scn.trail.clear(); scn._seed_trail()
		scn._place_all()
		scn.mode = "walk"
		await create_timer(1.3).timeout
		await _shot(dir, "z_" + k)
	# tag
	scn.player = Vector2(-38.2, 4.5)
	scn.trail.clear(); scn._seed_trail()
	await create_timer(0.5).timeout
	scn._near = scn._find_near()
	scn._use(scn._near)
	await create_timer(0.4).timeout
	await _shot(dir, "z_tag")
	# seduta
	scn.player = Vector2(-9, 21.95)
	await create_timer(0.3).timeout
	scn._near = scn._find_near()
	print("near=", scn._near.get("id"))
	scn._use(scn._near)
	await create_timer(1.5).timeout
	await _shot(dir, "z_sit")
	print("mode=", scn.mode, " found=", WorldV2Ctx.found.keys())
	quit(0)
