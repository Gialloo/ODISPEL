extends SceneTree
func _init() -> void:
	_run()
func _run() -> void:
	var dir: String = OS.get_cmdline_user_args()[0]
	Settings.ensure_loaded()
	Settings.gacha_guide_seen = true
	Settings.tutorial_done = true
	var s: Node = load("res://scenes/roster/roster_screen.tscn").instantiate()
	root.add_child(s)
	await create_timer(0.8).timeout
	s.show_tab("reclutamento")
	await create_timer(0.8).timeout
	for c in s.get_children():
		if c is GachaGuide:
			c.queue_free()
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png(dir.path_join("recluta.png"))
	s.show_tab("equip")
	await create_timer(0.8).timeout
	root.get_viewport().get_texture().get_image().save_png(dir.path_join("equip.png"))
	quit()
