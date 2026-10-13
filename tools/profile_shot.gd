extends SceneTree
# Foto dell'hub con il profilo, della finestra profilo e della lobby con la chat.
func _init() -> void:
	_run()
func _run() -> void:
	var dir: String = OS.get_cmdline_user_args()[0]
	root.content_scale_size = Vector2i(1280, 720)
	Profile.ensure_loaded()
	Profile.unlocked = ["l_striker", "e_kairos"]
	Profile.icon = "l_striker"
	Profile.banner = 1
	Profile.player_name = "Gianluca"
	var hub: Node = load("res://scenes/hub/hub_demo.tscn").instantiate()
	root.add_child(hub)
	await create_timer(1.0).timeout
	root.get_viewport().get_texture().get_image().save_png(dir.path_join("hub.png"))
	ProfilePanel.open(hub)
	await create_timer(0.6).timeout
	root.get_viewport().get_texture().get_image().save_png(dir.path_join("profile.png"))
	quit()
