extends SceneTree

# Immagine della schermata OBIETTIVI:  xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/feats_shot.gd -- cartella

var _out: String = "user://"


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_run()


func _run() -> void:
	await process_frame
	var r: Dictionary = RosterState.new_roster()
	r["cleared"] = {"distributore": 3, "semaforo": 1}
	r["pulls"] = 12
	r["stats"] = {"plays": 9, "wins": 6}
	var s: Control = load("res://scenes/feats/feats_screen.tscn").instantiate()
	s.roster = r
	s.save_path = "user://shot_feats_tmp.json"
	root.add_child(s)
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png(_out.path_join("feats_ready.png"))
	s.show_group("TUTTE")
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png(_out.path_join("feats_all.png"))
	quit()
