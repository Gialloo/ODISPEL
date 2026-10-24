extends SceneTree

# Schermate degli sblocchi fino al 100 e del New Game+ senza giocare: menu SQUADRA al livello 100, scelta delle Ultimate
# e delle sinergie, fine dell'atto con il pulsante della Replica.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 --rendering-driver opengl3 -s tools/v3_sblocchi.gd -- /tmp/sblocchi

var main: Node
var out: String = "/tmp/sblocchi"


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("/"):
			out = str(a)
	DirAccess.make_dir_recursive_absolute(out)
	Story.save_path = "user://salvataggio_prova.cfg"
	Settings.ensure_loaded()
	Progress.reset()
	for c in Progress.CAST:
		Progress.data["lv"][c] = 100 if c != "zecca" else 62
		for u in Progress.UNLOCKS[c]:
			if int(u[0]) <= int(Progress.data["lv"][c]):
				Progress.equip(c, str(u[1]), str(u[2]))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run()


func _secs(s: float) -> void:
	await create_timer(s).timeout


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png(out + "/" + name + ".png")
	print("SHOT ", name)


func _run() -> void:
	await _secs(1.5)
	var layer := CanvasLayer.new()
	layer.layer = 50
	root.add_child(layer)
	var sm := SquadMenu.new(false, false)
	layer.add_child(sm)
	await _secs(0.5)
	await _shot("01_squadra_lance_100")
	sm.call("_open_picker", "ferri", "ult")
	await _secs(0.3)
	await _shot("02_lance_ultimate")
	sm.set("_sel", "zecca")
	sm.call("_refresh")
	sm.call("_open_picker", "zecca", "react")
	await _secs(0.3)
	await _shot("03_rio_reazioni_lv62")
	sm.set("_sel", "saul")
	sm.call("_refresh")
	sm.call("_open_picker", "saul", "syn")
	await _secs(0.3)
	await _shot("04_saul_sinergie")
	sm.call("_open_picker", "nox", "trait")
	await _secs(0.3)
	await _shot("05_nox_tratti")
	layer.queue_free()
	Story.flags = {"replica": 2}
	main.go("ending")
	await _secs(1.0)
	await _shot("06_fine_replica")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Story.save_path))
	quit()
