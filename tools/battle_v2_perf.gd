extends SceneTree
# Misure indicative (renderer software: non dicono nulla sul telefono, servono solo a confrontare prima/dopo)
#   xvfb-run -a godot --path . --resolution 1280x720 -s tools/battle_v2_perf.gd
func _init() -> void:
	_run()
func _sample(label: String, secs: float) -> void:
	var t_proc := 0.0; var calls := 0; var objs := 0; var prims := 0; var n := 0
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		await process_frame
		t_proc += Performance.get_monitor(Performance.TIME_PROCESS)
		calls = maxi(calls, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		objs = maxi(objs, int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
		n += 1
	print("PERF %-22s frames=%d process_ms=%.3f drawcalls_max=%d objs_max=%d nodes=%d" % [label, n, 1000.0 * t_proc / maxf(1.0, n), calls, objs, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
func _run() -> void:
	Settings.tutorial_done = true
	var scn = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate()
	root.add_child(scn)
	await create_timer(1.5).timeout
	await _sample("fermo (attesa)", 2.0)
	scn._tap(scn.wheel_front.hits[0].get_center())
	await create_timer(0.5).timeout
	await _sample("comando selezionato", 2.0)
	scn.ult_sempre = true
	scn._charge_ult()
	scn._tap(scn.wheel_front.hits[2].get_center())
	await create_timer(0.6).timeout
	await _sample("ultimate selezionata", 2.0)
	scn.picked = ""
	scn._refresh()
	scn._auto_round()
	await _sample("round in corso", 3.0)
	print("PERF fine")
	quit(0)
