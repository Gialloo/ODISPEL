extends SceneTree
func _init() -> void:
	_run()
func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var scene: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout
	if scene._tutorial != null:
		scene._tutorial.queue_free()
	var ids: Array = scene.shown["players"].map(func(p): return str(p["active"]))
	scene._fx_link({"t": "link", "unit": ids[1], "with": ids[0], "n": 3, "kind": "cross"})
	scene._stage.link_from = ids[0]
	scene._stage.link_to = ids[2]
	scene._stage.link_n = 3
	scene._stage.link_col = Color("#fff36b")
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png(out.path_join("link.png"))
	quit()
