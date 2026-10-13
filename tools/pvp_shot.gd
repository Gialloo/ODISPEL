extends SceneTree

# Foto della schermata PvP: godot -s res://tools/pvp_shot.gd -- <cartella> <modalita>
func _initialize() -> void:
	_run()

func _run() -> void:
	var args: Array = OS.get_cmdline_user_args()
	var dir: String = str(args[0]) if args.size() > 0 else "/tmp"
	var mode: String = str(args[1]) if args.size() > 1 else "duel"
	var src := PvpLocalSource.new()
	var team: Array = RosterState.team_entries(RosterState.new_roster()).slice(0, 3)
	src.start(team, mode, true, 77)
	var screen: Node = (load(SceneRouter.path_of("pvp")) as PackedScene).instantiate()
	screen.set("pending_source", src)
	root.add_child(screen)
	current_scene = screen
	for i in 20:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/pvp_%s_1.png" % [dir, mode])
	screen.call("_on_move", "attack")
	if mode != "duel":
		screen.call("_on_target", str(PvpEngine.enemies_of(src.battle, "p1")[0]["id"]))
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1500:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/pvp_%s_2.png" % [dir, mode])
	print("round ", src.battle["round"])
	quit()
