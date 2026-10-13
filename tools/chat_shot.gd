extends SceneTree
func _init() -> void:
	_run()
func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	var m := NetworkManager.new()
	m.local_player_id = "a"
	m.chat_log = [
		{"id": "b", "name": "Chiara", "text": "Io tengo il taunt, voi caricate l'ultimate!", "icon": "e_kairos", "banner": 1},
		{"id": "a", "name": "Gianluca", "text": "Ok, round 3 tutti ultimate", "icon": "l_striker", "banner": 2},
		{"id": "c", "name": "Marco", "text": "Cura su Dax prima del colpo del boss", "icon": "r_burst", "banner": 4},
	]
	var bg := ColorRect.new()
	bg.color = Color("#0b1220")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var chat := ChatPanel.new().setup(m, true, Vector2(400, 210))
	chat.position = Vector2(20, 100)
	root.add_child(chat)
	chat.toggle()
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].path_join("chat.png"))
	quit()
