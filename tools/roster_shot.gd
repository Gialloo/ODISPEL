extends SceneTree

# Immagini della schermata squadra/reclutamento (serve un display, anche virtuale):
#   godot --path . --resolution 1280x720 -s res://tools/roster_shot.gd -- cartella_uscita

var _out: String = "user://"


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_run()


func _shot(name: String) -> void:
	await create_timer(0.25).timeout
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(_out.path_join(name + ".png"))
	print("salvata ", name)


func _run() -> void:
	var r: Dictionary = RosterState.new_roster()
	r["coins"] = 3500
	r["materials"] = {"nucleo": 12, "lega": 4}
	RosterState.add_character(r, "nova")
	RosterState.add_character(r, "sera")
	var scene: Control = load("res://scenes/roster/roster_screen.tscn").instantiate()
	scene.roster = r
	scene.save_path = "user://shot_roster_tmp.json"
	root.add_child(scene)
	await create_timer(0.3).timeout
	await _shot("r1_squadra")
	scene.next_seed = 5
	scene.show_tab("reclutamento")
	scene.pull(10)
	await _shot("r2_reclutamento")
	quit()
