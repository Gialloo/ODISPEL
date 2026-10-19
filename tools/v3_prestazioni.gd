extends SceneTree

# Misura il costo di ogni area e di ogni arena di battaglia: chiamate di disegno, primitive, oggetti, nodi,
# tempo medio di un fotogramma (CPU) e tempo di caricamento. Non e' un telefono vero, ma i numeri si confrontano tra versioni.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_prestazioni.gd

var main: Node


func _init() -> void:
	Story.save_path = "user://salvataggio_prova.cfg"
	Settings.ensure_loaded()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _measure(label: String, screen: String, args: Dictionary) -> void:
	var t0: int = Time.get_ticks_msec()
	main.go(screen, args)
	while main.get("_busy"):
		await process_frame
	var load_ms: int = Time.get_ticks_msec() - t0
	await _frames(20)
	var dc: float = 0.0
	var prim: float = 0.0
	var obj: float = 0.0
	var proc: float = 0.0
	var n: int = 30
	Engine.max_fps = 0
	var w0: int = Time.get_ticks_usec()
	for i in n:
		await process_frame
		dc += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		prim += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		obj += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	proc = float(Time.get_ticks_usec() - w0) / 1000000.0
	Engine.max_fps = GameConfig.MAX_FPS
	print("MISURA %-28s carico %5d ms | draw %6.0f | primitive %8.0f | oggetti %5.0f | nodi %5d | fotogramma %.2f ms | mem %.0f MB" % [
		label, load_ms, dc / n, prim / n, obj / n, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), proc / n * 1000.0,
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0])


func _run() -> void:
	await _frames(10)
	for id in (Story.data().get("aree", {}) as Dictionary):
		await _measure("area " + str(id), "area", {"area": str(id), "resume": {"pos": Vector3(0, 0.14, 0)}})
	for ar in ["strada", "anomalia_rossa", "anomalia_blu", "anomalia_verde", "caveau", "tangenziale"]:
		await _measure("battaglia " + ar, "battle", {"boss": "distributore", "visual": "distributore", "arena": ar})
	quit()
