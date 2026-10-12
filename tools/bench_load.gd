extends SceneTree

# Tempi di caricamento: lettura della scena, costruzione dei nodi, primo fotogramma.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/bench_load.gd

func _initialize() -> void:
	_run()


func _us() -> int:
	return Time.get_ticks_usec()


func _scene(label: String, path: String) -> void:
	var t0: int = _us()
	var packed: PackedScene = load(path)
	var t1: int = _us()
	var node: Node = packed.instantiate()
	var t2: int = _us()
	root.add_child(node)
	var t3: int = _us()
	await process_frame
	await process_frame
	var t4: int = _us()
	print("%-14s carica %6.1f   costruisce %6.1f   _ready %6.1f   2 fotogrammi %6.1f   totale %6.1f ms" % [
		label, (t1 - t0) / 1000.0, (t2 - t1) / 1000.0, (t3 - t2) / 1000.0, (t4 - t3) / 1000.0, (t4 - t0) / 1000.0])
	node.queue_free()
	await process_frame


func _run() -> void:
	await process_frame
	print("avvio motore -> primo fotogramma: %.0f ms" % (Time.get_ticks_msec()))
	Settings.path = "user://bench_settings.cfg"
	Settings.tutorial_done = true
	var t0: int = _us()
	BattleTheme.display()
	BattleTheme.mono()
	var l := BattleTheme.make_label("PROVA 0123", 20, Color.WHITE, true)
	root.add_child(l)
	await process_frame
	print("font: creazione + primo testo %.1f ms" % ((_us() - t0) / 1000.0))
	l.queue_free()
	await _scene("hub", "res://scenes/hub/hub_demo.tscn")
	await create_timer(1.0).timeout      # il tempo che si passa a guardare l'hub
	await _scene("hub (2a volta)", "res://scenes/hub/hub_demo.tscn")
	await _scene("missioni", "res://scenes/missions/mission_screen.tscn")
	await _scene("squadra", "res://scenes/roster/roster_screen.tscn")
	await _scene("lobby", "res://scenes/lobby/lobby_demo.tscn")
	await _scene("battaglia", "res://scenes/battle/battle_screen.tscn")
	await _scene("battaglia (2a)", "res://scenes/battle/battle_screen.tscn")
	quit(0)
