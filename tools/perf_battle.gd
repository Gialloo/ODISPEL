extends SceneTree

# Misura la fluidita' di una battaglia vera: tempo medio e peggiore per fotogramma e numero di disegni (draw call).
#   godot --headless --path . -s res://tools/perf_battle.gd -- [senza_luce] [turni]    (solo lavoro del codice, niente disegno)
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/perf_battle.gd -- [senza_luce] [turni]    (con disegno software)
# Con un argomento "senza_luce" i tratti di luce sono spenti (per confrontare).

func _init() -> void:
	_run()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var no_light: bool = args.size() > 0 and args[0] == "senza_luce"
	var turns: int = int(args[1]) if args.size() > 1 else 3
	Settings.light_fx = false
	Settings.fps_limit = 0
	Engine.max_fps = 0
	if no_light:
		LightPaint.max_live = 0
	BattleStage.profile = true
	LightPaint.profile = true
	var s: Node = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(s)
	await create_timer(0.9).timeout
	for c in s.get_children():
		if c is TutorialOverlay:
			c.queue_free()
	var times: Array = []
	var calls: Array = []
	var proc_sum: float = 0.0
	var proc_n: int = 0
	var prints: int = 0
	for t in turns:
		var tries: int = 0
		while not s.animating and tries < 8:
			var c: Dictionary = BattleAI.choose(s.source.battle, "p1")
			s.pending_swap = str(c["swap"])
			s._on_order_pressed(str(c["move"]))
			await process_frame
			tries += 1
		var guard: int = 0
		while s.animating and guard < 2400:
			var t0: int = Time.get_ticks_usec()
			await process_frame
			times.append(float(Time.get_ticks_usec() - t0) / 1000.0)
			proc_sum += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
			proc_n += 1
			calls.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
			guard += 1
	times.sort()
	var sum: float = 0.0
	for x in times:
		sum += float(x)
	var csum: float = 0.0
	var cmax: int = 0
	for x in calls:
		csum += float(x)
		cmax = maxi(cmax, int(x))
	var n: int = maxi(1, times.size())
	print("PERF %s: fotogrammi=%d medio=%.1f ms p95=%.1f ms peggiore=%.1f ms draw medi=%.0f max=%d" % [
		"SENZA luce" if no_light else "CON luce", times.size(), sum / float(n), float(times[int(float(n) * 0.95)]) if times.size() > 0 else 0.0, float(times[times.size() - 1]) if times.size() > 0 else 0.0, csum / float(n), cmax])
	print("PERF stage _draw: %.2f ms a fotogramma (%d fotogrammi)" % [float(BattleStage.profile_usec) / 1000.0 / float(maxi(1, BattleStage.profile_frames)), BattleStage.profile_frames])
	print("PERF process (script+layout+disegno-comandi) medio: %.2f ms su %d fotogrammi" % [proc_sum / float(maxi(1, proc_n)), proc_n])
	print("PERF luce: %.1f ms in totale, %d disegni, %.2f ms per disegno" % [float(LightPaint.profile_usec) / 1000.0, LightPaint.profile_calls, float(LightPaint.profile_usec) / 1000.0 / float(maxi(1, LightPaint.profile_calls))])
	quit()
