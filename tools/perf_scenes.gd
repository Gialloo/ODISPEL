extends SceneTree

# Profilo di TUTTE le schermate: caricamento (ms), nodi, costo a schermata ferma (ms di processo, draw call), nodi che girano ogni frame.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/perf_scenes.gd [-- touch]

const KEYS: Array = ["hub", "roster", "lobby", "missions", "feats", "titles", "tutorial", "expedition", "battle", "pvp"]


func _init() -> void:
	_run()


func _count(n: Node) -> int:
	var c: int = 1
	for k in n.get_children():
		c += _count(k)
	return c


func _proc(n: Node, out: Array) -> void:
	if n.is_processing():
		out.append(n.get_script().resource_path.get_file() if n.get_script() else n.get_class())
	for k in n.get_children():
		_proc(k, out)


func _run() -> void:
	for key in KEYS:
		var path: String = SceneRouter.path_of(key)
		var t0: int = Time.get_ticks_usec()
		var packed: PackedScene = load(path)
		var t1: int = Time.get_ticks_usec()
		var node: Node = packed.instantiate()
		var t2: int = Time.get_ticks_usec()
		root.add_child(node)
		await process_frame
		var t3: int = Time.get_ticks_usec()
		await create_timer(1.0).timeout
		var sp: float = 0.0
		var dc: float = 0.0
		var n: int = 90
		for i in n:
			await process_frame
			sp += Performance.get_monitor(Performance.TIME_PROCESS)
			dc += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var pr: Array = []
		_proc(root, pr)
		var counts: Dictionary = {}
		for p in pr:
			counts[p] = int(counts.get(p, 0)) + 1
		print("PS %-11s load=%5.1f inst=%5.1f first=%5.1f ms  nodi=%4d  process=%5.2f ms  draw=%4.0f  proc=%s" % [key, (t1 - t0) / 1000.0, (t2 - t1) / 1000.0, (t3 - t2) / 1000.0, _count(node), sp / n * 1000.0, dc / n, str(counts)])
		node.queue_free()
		await process_frame
		await process_frame
	print("PS mem estatica MB=%.0f" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))
	quit()
