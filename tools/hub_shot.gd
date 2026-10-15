extends SceneTree

# Immagine dell'hub: godot --path . --resolution 1280x720 -s res://tools/hub_shot.gd -- cartella [touch 0/1] [larghezza_inset_notch]

func _init() -> void:
	_run()


func _run() -> void:
	var ua: PackedStringArray = OS.get_cmdline_user_args()
	TouchUi.force = ua.size() > 1 and ua[1] == "1"
	await process_frame      # lascia partire gli autoload (font, maiuscole)
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var scene: Control = load("res://scenes/hub/hub_demo.tscn").instantiate()
	root.add_child(scene)
	await create_timer(1.2).timeout
	root.get_viewport().get_texture().get_image().save_png(out.path_join("hub_touch.png" if TouchUi.force else "hub.png"))
	quit()
