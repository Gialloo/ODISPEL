extends SceneTree

# Benchmark ripetibile di aree e arene: caricamento, draw call, primitive, oggetti,
# nodi, memoria e distribuzione dei tempi frame/processo.
# I valori sono confrontabili tra build, ma non sostituiscono un profiler GPU su dispositivo reale.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_prestazioni.gd

const WARMUP_FRAMES: int = 30
const SAMPLE_FRAMES: int = 180

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


func _percentile(values: Array[float], p: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	var index: int = clampi(int(ceil(float(sorted.size() - 1) * p)), 0, sorted.size() - 1)
	return sorted[index]


func _average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += value
	return total / float(values.size())


func _measure(label: String, screen: String, args: Dictionary) -> void:
	var t0: int = Time.get_ticks_msec()
	main.go(screen, args)
	while main.get("_busy"):
		await process_frame
	var load_ms: int = Time.get_ticks_msec() - t0
	await _frames(WARMUP_FRAMES)

	var draw_calls: float = 0.0
	var primitives: float = 0.0
	var objects: float = 0.0
	var frame_ms: Array[float] = []
	var process_ms: Array[float] = []
	var previous_max_fps: int = Engine.max_fps
	Engine.max_fps = 0

	for i in SAMPLE_FRAMES:
		var frame_start: int = Time.get_ticks_usec()
		await process_frame
		frame_ms.append(float(Time.get_ticks_usec() - frame_start) / 1000.0)
		process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		objects += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)

	Engine.max_fps = previous_max_fps

	var avg_frame: float = _average(frame_ms)
	var avg_fps: float = 1000.0 / avg_frame if avg_frame > 0.0 else 0.0
	print("MISURA %s | carico %d ms | FPS medio %.1f | frame ms media/p50/p95/max %.2f/%.2f/%.2f/%.2f | processo ms media/p95/max %.2f/%.2f/%.2f | draw %.0f | primitive %.0f | oggetti %.0f | nodi %d | memoria %.1f MB" % [
		label,
		load_ms,
		avg_fps,
		avg_frame,
		_percentile(frame_ms, 0.50),
		_percentile(frame_ms, 0.95),
		_percentile(frame_ms, 1.0),
		_average(process_ms),
		_percentile(process_ms, 0.95),
		_percentile(process_ms, 1.0),
		draw_calls / SAMPLE_FRAMES,
		primitives / SAMPLE_FRAMES,
		objects / SAMPLE_FRAMES,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	])


func _run() -> void:
	await _frames(10)
	print("BENCHMARK ODISPEL | Godot %s | OS %s | viewport %s | FPS target progetto %d | warmup %d | campioni %d" % [
		str(Engine.get_version_info().get("string", "sconosciuta")),
		OS.get_name(),
		str(root.get_viewport().get_visible_rect().size),
		GameConfig.MAX_FPS,
		WARMUP_FRAMES,
		SAMPLE_FRAMES
	])
	for id in (Story.data().get("aree", {}) as Dictionary):
		await _measure("area " + str(id), "area", {"area": str(id), "resume": {"pos": Vector3(0, 0.14, 0)}})
	for arena in ["strada", "anomalia_rossa", "anomalia_blu", "anomalia_verde", "caveau", "tangenziale"]:
		await _measure("battaglia " + arena, "battle", {"boss": "distributore", "visual": "distributore", "arena": arena})
	quit()
