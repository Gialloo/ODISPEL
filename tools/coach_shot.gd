extends SceneTree

# Immagine della guida passo-passo. Uso: godot --path . --resolution 1600x720 -s res://tools/coach_shot.gd -- cartella
func _init() -> void:
	_run()


func _run() -> void:
	Settings.tutorial_done = true
	Settings.coach_step = 0
	var scene: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(scene)
	await create_timer(1.0).timeout
	if scene._tutorial != null:
		scene._tutorial.queue_free()
	scene._start_coach()
	await create_timer(0.8).timeout
	root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].path_join("coach0.png"))
	scene._on_order_pressed("attack")
	await create_timer(6.0).timeout
	root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].path_join("coach1.png"))
	print("coach step: ", scene._coach.index if scene._coach != null else -1)
	quit()
