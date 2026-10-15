extends SceneTree

# Cerca cosa pesa di piu' a schermata ferma: spegne un nodo con _process alla volta e misura il tempo per fotogramma.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/perf_hunt.gd

func _init() -> void:
	_run()


func _measure(frames: int) -> float:
	var sum: float = 0.0
	for i in frames:
		var t0: int = Time.get_ticks_usec()
		await process_frame
		sum += float(Time.get_ticks_usec() - t0) / 1000.0
	return sum / float(frames)


func _desc(n: Node) -> String:
	var sc: String = ""
	if n.get_script() != null:
		sc = str((n.get_script() as Script).resource_path).get_file()
	var extra: String = ""
	if n is Control:
		extra = " size=%dx%d" % [int((n as Control).size.x), int((n as Control).size.y)]
	if (n as CanvasItem).material != null:
		extra += " MATERIAL"
	return "%s [%s %s]%s kids=%d" % [n.name, n.get_class(), sc, extra, n.get_child_count()]


func _run() -> void:
	Settings.light_fx = false
	Settings.fps_limit = 0
	Engine.max_fps = 0
	var s: Node = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(s)
	await create_timer(1.0).timeout
	for c in s.get_children():
		if c is TutorialOverlay:
			c.queue_free()
	await create_timer(0.3).timeout
	var base: float = await _measure(30)
	print("BASE fermo: %.1f ms" % base)
	var res: Array = []
	for n in s.get_children():
		if not (n is CanvasItem) or not (n as CanvasItem).visible:
			continue
		(n as CanvasItem).visible = false
		var t: float = await _measure(10)
		(n as CanvasItem).visible = true
		res.append({"name": _desc(n), "gain": base - t})
	res.sort_custom(func(a, b) -> bool: return float(a["gain"]) > float(b["gain"]))
	for r in res:
		print("HUNT -%.1f ms  %s" % [r["gain"], r["name"]])
	# dentro i due piu' pesanti
	quit()
