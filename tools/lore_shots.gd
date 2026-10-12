extends SceneTree

# Screenshot di scheda, legenda e archivio. Uso: xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/lore_shots.gd -- cartella


func _shot(dir: String, name: String) -> void:
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])


func _init() -> void:
	var dir: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp"
	var screen: Control = load("res://scenes/roster/roster_screen.tscn").instantiate()
	screen.roster = RosterState.new_roster()
	screen.save_path = "user://shot_lore_tmp.json"
	root.add_child(screen)
	await create_timer(0.5).timeout
	screen.select("kira")
	await _shot(dir, "lore_scheda")
	screen.open_legend()
	await _shot(dir, "lore_legenda")
	screen.get_children().filter(func(c): return c is GachaGuide)[0].queue_free()
	await create_timer(0.2).timeout
	var g: GachaGuide = screen.open_archive()
	await _shot(dir, "lore_archivio0")
	g.show_page(4, false)
	await _shot(dir, "lore_archivio4")
	quit()
