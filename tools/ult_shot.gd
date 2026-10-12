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
	var at: Vector2 = scene._stage.anchor_of("p1_0") if false else Vector2(150, 380)
	for st in ["strike", "shield", "heal"]:
		UltFx.play(scene._fx, at, Color("#b07bff") if st == "strike" else (Color("#ff4d6d") if st == "shield" else Color("#6bffb0")), st, Vector2(780, 330) if st == "strike" else Vector2.ZERO)
		await create_timer(0.55).timeout
		root.get_viewport().get_texture().get_image().save_png(out.path_join("ult_" + st + ".png"))
		await create_timer(1.0).timeout
	quit()
