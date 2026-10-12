extends SceneTree

# Dove va il tempo di un fotogramma della battaglia: si spegne una parte alla volta.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/bench_parts.gd

const FRAMES: int = 150


func _initialize() -> void:
	_run()


func _ms() -> float:
	for i in 20:
		await process_frame
	var t0: int = Time.get_ticks_usec()
	for i in FRAMES:
		await process_frame
	return float(Time.get_ticks_usec() - t0) / 1000.0 / float(FRAMES)


func _run() -> void:
	await process_frame
	Engine.max_fps = 0
	Settings.path = "user://bench_settings.cfg"
	Settings.tutorial_done = true
	var s: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(s)
	print("tutto                    %6.2f ms" % await _ms())
	var parts: Array = []
	for c in s.get_children():
		parts.append(c)
	for c in parts:
		var was: bool = c.visible if "visible" in c else true
		if not ("visible" in c):
			continue
		c.visible = false
		var label: String = "%s (%s)" % [c.name, c.get_class()]
		print("senza %-30s %6.2f ms" % [label.substr(0, 30), await _ms()])
		c.visible = was
	quit(0)
