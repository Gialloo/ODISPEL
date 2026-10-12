extends SceneTree
func _init() -> void:
	_run()
func _run() -> void:
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(bg)
	var i: int = 0
	for id in ["kira", "dafne", "angela", "elle"]:
		var pv := PortraitView.new().setup(id, "bust")
		pv.card = true
		pv.position = Vector2(60 + i * 300, 100)
		pv.size = Vector2(260, 400)
		host.add_child(pv)
		i += 1
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].path_join("cards.png"))
	quit()
