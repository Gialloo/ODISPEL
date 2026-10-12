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
	scene.banter(scene._local_active_id(), "crit", true)
	await create_timer(0.7).timeout
	root.get_viewport().get_texture().get_image().save_png(out.path_join("banter.png"))
	quit()
