extends SceneTree

# Misura per schermata: chiamate di disegno, nodi, tempo di processo medio.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/perf_probe.gd
func _initialize() -> void:
	_run()

func _measure(label: String) -> void:
	for i in 30:
		await process_frame
	var t0: int = Time.get_ticks_usec()
	var n: int = 90
	var calls: float = 0.0
	var proc: float = 0.0
	for i in n:
		await process_frame
		calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		proc += Performance.get_monitor(Performance.TIME_PROCESS)
	var wall: float = float(Time.get_ticks_usec() - t0) / 1000.0 / float(n)
	print("%-28s calls %6.0f  nodi %5d  oggetti %6d  process %.2f ms  frame %.1f ms" % [label, calls / n, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_COUNT)), proc / n * 1000.0, wall])

func _show(path: String, setup: Callable = Callable()) -> Node:
	var cur: Node = current_scene
	var s: Node = (load(path) as PackedScene).instantiate()
	if setup.is_valid():
		setup.call(s)
	root.add_child(s)
	current_scene = s
	if cur != null:
		cur.queue_free()
	return s

func _run() -> void:
	await process_frame
	for q in ["ALTA", "BASSA"]:
		Settings.light_fx = q == "BASSA"
		Settings.fps_limit = 0 if q == "ALTA" else 60
		print("--- qualita ", q)
		_show(SceneRouter.path_of("hub"))
		await _measure("hub")
		_show(SceneRouter.path_of("roster"))
		await _measure("squadra")
		_show(SceneRouter.path_of("lobby"))
		await _measure("lobby")
		_show(SceneRouter.path_of("battle"))
		await _measure("battaglia (planning)")
		var src := PvpLocalSource.new()
		src.start(RosterState.team_entries(RosterState.new_roster()).slice(0, 3), "ffa", true, 5)
		_show(SceneRouter.path_of("pvp"), func(s: Node) -> void: s.set("pending_source", src))
		await _measure("pvp ffa")
	quit()
