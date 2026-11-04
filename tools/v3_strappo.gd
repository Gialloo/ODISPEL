extends SceneTree

# Prova dell'ingresso in battaglia «nastro strappato» (main.go_tear): fotogrammi ogni 0,1 s dal contatto.
# Uso: xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 -s tools/v3_strappo.gd -- <cartella>

var out: String = "/tmp/v3strappo"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func _run() -> void:
	await process_frame
	var m: Node = load("res://scripts/v3/main.gd").new()
	root.add_child(m)
	await create_timer(2.5).timeout
	var args: Dictionary = {"boss": "frammento_rosso", "visual": "frammento_rosso", "livello": 2, "arena": "strada",
		"ritorno": {"tipo": "area", "area": "incrocio", "vinto": {}, "perso": {}}}
	var t0: int = Time.get_ticks_msec()
	m.call("go_tear", "battle", args)
	for i in 16:
		await create_timer(0.1).timeout
		await process_frame
		root.get_viewport().get_texture().get_image().save_png(out.path_join("s%02d.png" % i))
		print("fotogramma ", i, " t=", Time.get_ticks_msec() - t0)
	quit()
