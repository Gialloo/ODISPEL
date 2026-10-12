extends SceneTree
func _init() -> void:
	_run()
func _run() -> void:
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.12, 0.16)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(bg)
	var i: int = 0
	for e in [["kira", "neutral"], ["dafne", "angry"], ["angela", "happy"], ["elle", "sad"]]:
		var pv := PortraitView.new().setup(e[0], "bust")
		pv.show_expression_text = false
		pv.size = Vector2(310, 560)
		pv.position = Vector2(10 + i * 318, 150)
		host.add_child(pv)
		pv.set_expression(e[1])
		i += 1
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].path_join("bust.png"))
	quit()
