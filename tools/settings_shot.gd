extends SceneTree
func _init() -> void:
	_run()
func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	SettingsPanel.open(host)
	await create_timer(0.6).timeout
	root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].path_join("settings.png"))
	quit()
