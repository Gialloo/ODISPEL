extends SceneTree

# REGISTRA UNA BATTAGLIA CON IL SUONO: gioca da sola (AUTO) e, lanciata col Movie Maker di Godot, scrive video e audio.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 --write-movie /tmp/battaglia.avi --fixed-fps 30 \
#        -s tools/v3_suono_battaglia.gd -- [boss=semaforo] [arena=strada] [minore] [livello=6] [secondi=90]
var main: Node


func _init() -> void:
	Story.save_path = "user://salvataggio_prova_suono.cfg"
	Settings.path = "user://settings_prova_suono.cfg"
	Settings.ensure_loaded()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run()


func _run() -> void:
	var boss: String = "semaforo"
	var arena: String = "strada"
	var minore: bool = false
	var secs: float = 90.0
	var liv: int = 6
	for a in OS.get_cmdline_user_args():
		var s: String = str(a)
		if s.begins_with("boss="):
			boss = s.substr(5)
		elif s.begins_with("arena="):
			arena = s.substr(6)
		elif s == "minore":
			minore = true
		elif s.begins_with("livello="):
			liv = int(s.substr(8))
		elif s.begins_with("secondi="):
			secs = float(s.substr(8))
	for i in 10:
		await process_frame
	main.go("battle", {"boss": boss, "visual": boss, "arena": arena, "livello": liv, "minore": minore})
	while main.get("_busy"):
		await process_frame
	var bt: Node = main.current
	bt.set("auto_on", true)
	var frames: int = int(secs * 30.0)
	var f: int = 0
	while f < frames and is_instance_valid(bt) and not bool(bt.get("ended")):
		await process_frame
		f += 1
	for i in 150:               # la vittoria e il suo motivetto
		await process_frame
	quit()
