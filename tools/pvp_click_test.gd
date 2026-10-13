extends SceneTree
func _click(c: Vector2) -> void:
	var mv := InputEventMouseMotion.new()
	mv.position = c
	mv.global_position = c
	Input.parse_input_event(mv)
	await process_frame
	var ev := InputEventMouseButton.new()
	ev.position = c
	ev.global_position = c
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	var up: InputEventMouseButton = ev.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
func _run() -> void:
	var mode: String = OS.get_cmdline_user_args()[1]
	var src := PvpLocalSource.new()
	src.start(RosterState.team_entries(RosterState.new_roster()).slice(0, 3), mode, true, 77)
	var screen: Node = (load(SceneRouter.path_of("pvp")) as PackedScene).instantiate()
	screen.set("pending_source", src)
	root.add_child(screen)
	for i in 6:
		await process_frame
	for r in 3:
		var b: Button = screen.buttons["attack"]
		await _click(b.global_position + b.size * 0.5)
		print("pending=", screen.pending_move, " round=", src.battle["round"])
		if screen.pending_move != "":
			var enemy: String = ""
			for pid in screen.zones:
				if screen.zones[pid].active:
					enemy = pid
					break
			var z: Control = screen.zones[enemy]
			await _click(z.global_position + z.size * 0.5)
		for i in 120:
			await process_frame
			if not screen.animating and not screen.locked:
				break
		print("dopo: round=", src.battle["round"], " winner=", src.battle["winner"])
	root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].path_join("pvpclick.png"))
	quit()
func _init() -> void:
	_run()
