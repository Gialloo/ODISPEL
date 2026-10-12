extends SceneTree
func _init() -> void:
	_run()
func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	for b in ["ascensore", "manichino", "orologio"]:
		var scene: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
		MissionConfig.boss_id = b
		root.add_child(scene)
		await create_timer(0.5).timeout
		if scene._tutorial != null:
			scene._tutorial.queue_free()
		await create_timer(0.3).timeout
		root.get_viewport().get_texture().get_image().save_png(out.path_join(b + ".png"))
		scene.queue_free()
		await process_frame
	var m: Control = load("res://scenes/missions/mission_screen.tscn").instantiate()
	root.add_child(m)
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png(out.path_join("missioni.png"))
	quit()
