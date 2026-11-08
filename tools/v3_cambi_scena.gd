extends SceneTree

# Prova ripetibile dei CAMBI DI SCENA (strada <-> battaglia, piu' volte di fila).
# Per ogni giro stampa: tempo del cambio, fotogramma peggiore durante il cambio e nei 2 secondi dopo,
# FPS medio a regime, nodi, oggetti, risorse, nodi orfani e memoria.
# Se i nodi o la memoria crescono a ogni giro qualcosa resta in vita tra una scena e l'altra (perdita).
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_cambi_scena.gd [-- giri=N]

const SAMPLE_FRAMES: int = 120

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


func _go(screen: String, args: Dictionary) -> Array:
	# ritorna [ms del cambio, fotogramma peggiore nel cambio, fotogramma peggiore nei 2 s dopo]
	var t0: int = Time.get_ticks_msec()
	var worst: float = 0.0
	main.go(screen, args)
	var last: int = Time.get_ticks_usec()
	while main.get("_busy"):
		await process_frame
		var now: int = Time.get_ticks_usec()
		worst = maxf(worst, float(now - last) / 1000.0)
		last = now
	var change_ms: int = Time.get_ticks_msec() - t0
	var worst_after: float = 0.0
	last = Time.get_ticks_usec()
	for i in 120:
		await process_frame
		var now2: int = Time.get_ticks_usec()
		worst_after = maxf(worst_after, float(now2 - last) / 1000.0)
		last = now2
	return [change_ms, worst, worst_after]


func _steady() -> float:
	var prev: int = Engine.max_fps
	Engine.max_fps = 0
	var t0: int = Time.get_ticks_usec()
	await _frames(SAMPLE_FRAMES)
	var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0 / SAMPLE_FRAMES
	Engine.max_fps = prev
	return ms


func _report(label: String, r: Array, frame_ms: float) -> void:
	print("CAMBIO %-22s | cambio %4d ms | peggiore nel cambio %6.1f ms | peggiore dopo %6.1f ms | regime %5.2f ms (%5.1f FPS) | nodi %5d | oggetti %6d | risorse %5d | orfani %4d | memoria %6.1f MB" % [
		label, r[0], r[1], r[2], frame_ms, 1000.0 / maxf(frame_ms, 0.001),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0])


func _run() -> void:
	var giri: int = 4
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("giri="):
			giri = int(str(a).substr(5))
	await _frames(10)
	var area_id: String = str((Story.data().get("aree", {}) as Dictionary).keys()[0])
	for g in giri:
		var r: Array = await _go("area", {"area": area_id, "resume": {"pos": Vector3(0, 0.14, 0)}})
		_report("%d strada" % (g + 1), r, await _steady())
		r = await _go("battle", {"boss": "distributore", "visual": "distributore", "arena": "strada"})
		_report("%d battaglia" % (g + 1), r, await _steady())
	r_menu()


func r_menu() -> void:
	var r: Array = await _go("menu", {})
	_report("fine menu", r, await _steady())
	quit()
