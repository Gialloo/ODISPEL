extends SceneTree

# Costo del cut-in Edgerunners da solo (senza battaglia): tempo medio e massimo di un fotogramma durante la sua durata.
# Software rendering (llvmpipe): i numeri assoluti non valgono per il telefono, il confronto prima/dopo si'.
# Uso: xvfb-run -a -s "-screen 0 1280x576x24" godot --path . --resolution 1280x576 -s tools/v3_cutin_costo.gd -- <ferri|nox|zecca|saul>


func _init() -> void:
	Settings.ensure_loaded()
	_run()


func _run() -> void:
	var who: String = "nox"
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		who = a[0]
	await process_frame
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	for i in 10:
		await process_frame
	Engine.max_fps = 0
	var t_first: int = Time.get_ticks_usec()
	var e := EdgeCutin.new()
	host.add_child(e)
	e.start(who, EdgeCutin.pal_for(who))
	await process_frame
	var first_ms: float = (Time.get_ticks_usec() - t_first) / 1000.0
	var ts: Array = []
	var last: int = Time.get_ticks_usec()
	for i in 90:
		await process_frame
		var now: int = Time.get_ticks_usec()
		ts.append((now - last) / 1000.0)
		last = now
	var sum: float = 0.0
	var mx: float = 0.0
	for t in ts:
		sum += float(t)
		mx = maxf(mx, float(t))
	print("CUTIN ", who, ": primo fotogramma ms=", snappedf(first_ms, 0.1), " medio ms=", snappedf(sum / ts.size(), 0.1), " massimo ms=", snappedf(mx, 0.1), " draw=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	quit(0)
