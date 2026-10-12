extends SceneTree

# Screenshot della guida STRATEGIE (una per pagina). Uso: xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/strategy_shots.gd -- cartella


func _init() -> void:
	var dir: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp"
	var screen: Control = load("res://scenes/roster/roster_screen.tscn").instantiate()
	screen.roster = RosterState.new_roster()
	screen.save_path = "user://shot_strategy_tmp.json"
	root.add_child(screen)
	await create_timer(0.5).timeout
	var g: GachaGuide = screen.open_strategy_guide()
	var n: int = StrategyInfo.pages().size()
	for i in n:
		g.show_page(i, false)
		await create_timer(0.3).timeout
		root.get_viewport().get_texture().get_image().save_png("%s/strategia_%d.png" % [dir, i])
	quit()
