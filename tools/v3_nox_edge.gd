extends SceneTree

# Prova del cut-in "alla Edgerunners" di Nox: una schermata per ogni passo della ricetta e tre momenti dell'animazione.
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/v3_nox_edge.gd -- <cartella> [touch]

var out: String = "/tmp/v3noxedge"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1 and a[1] == "touch":
		TouchUi.force = true
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	_run()


func _shot(n: String) -> void:
	for i in 6:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out.path_join(n + ".png"))


func _run() -> void:
	await process_frame
	var bt: Node = load("res://scripts/v3/battle3d.gd").new()
	bt.configure({"boss": "autovelox", "livello": 11, "arena": "tangenziale"})
	root.add_child(bt)
	var guard: int = 0
	while not bool(bt.get("waiting")) and guard < 600:
		guard += 1
		await process_frame
	await create_timer(1.0).timeout
	# il cut-in vero, quello della battaglia (Nox), con il tempo deciso da noi
	var u: Dictionary = {}
	for i in 4:
		var cand: Dictionary = bt.call("_slot_unit", i)
		if str(cand["char"]) == "nox":
			u = cand
	if u.is_empty():
		print("ESITO: FALLITO (Nox non e' in squadra)")
		quit(1)
		return
	var cin: Control = bt.get("_cutin")
	# per i passi: solo il cut-in, senza HUD, ruota, fascia e scuro
	var hidden: Array = []
	for c in (bt.get("_root") as Control).get_children():
		if c != cin and c is CanvasItem and (c as CanvasItem).visible:
			(c as CanvasItem).visible = false
			hidden.append(c)
	for n in ["Dark", "Band", "Name", "Line"]:
		cin.get_node(n).visible = false
	cin.visible = true
	cin.modulate.a = 1.0
	var e := EdgeCutin.new()
	cin.add_child(e)
	cin.move_child(e, 0)
	e.start("nox")
	e.manual = true
	var steps: Array = [
		["1_persona_maschera", false, false, false, false, 0],
		["2_persona_kuwahara_bn", false, false, false, false, 1],
		["3_persona_colorata", false, false, false, false, 2],
		["4_sfondo_retino", true, false, false, false, -1],
		["5_sfondo_raggi", true, true, false, false, -1],
		["6_sfondo_solidi", true, true, true, false, -1],
		["7_sfondo_fiamme", true, true, true, true, -1],
		["8_completo", true, true, true, true, 2],
	]
	for s in steps:
		e.set_layers(s[1], s[2], s[3], s[4], s[5])
		e.apply_time(0.7)
		await _shot(str(s[0]))
	e.set_layers(true, true, true, true, 2)
	for m in [[0.1, "9_anim_0.10s"], [0.4, "10_anim_0.40s"], [1.2, "11_anim_1.20s"]]:
		e.apply_time(m[0])
		await _shot(str(m[1]))
	# costo: chiamate di disegno, primitive, memoria video e tempo medio di un fotogramma (software: indicativo)
	e.manual = false
	Engine.max_fps = 0
	var t_a: int = Time.get_ticks_usec()
	for i in 20:
		await process_frame
	var dc: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	print("COSTO CUT-IN: draw calls=", dc, " primitive=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), " video_mem_MB=", snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1), " ms/frame=", snappedf((Time.get_ticks_usec() - t_a) / 20000.0, 0.1))
	e.manual = true
	# prova vera: il cut-in della battaglia dall'inizio alla fine, con le sue scritte
	e.queue_free()
	await process_frame
	await process_frame
	var t_b: int = Time.get_ticks_usec()
	for i in 20:
		await process_frame
	print("SENZA CUT-IN: draw calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " video_mem_MB=", snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1), " ms/frame=", snappedf((Time.get_ticks_usec() - t_b) / 20000.0, 0.1))
	cin.visible = false
	for n in ["Dark", "Band", "Name", "Line"]:
		cin.get_node(n).visible = true
	for c in hidden:
		if is_instance_valid(c):
			(c as CanvasItem).visible = true
	# il rendering software e' lento: rallento il tempo di gioco per fotografare il cut-in vero a meta'
	Engine.time_scale = 0.15
	bt.call("_play_cutin", u, "PROVA")
	await create_timer(0.5 * 0.15).timeout
	print("CUTIN: attivo=", bt.get("_cutin_on"), " visibile=", cin.visible, " alfa=", cin.modulate.a, " figli=", cin.get_child_count(), " skip=", Settings.skip_cutin)
	await _shot("12_battaglia_cutin")
	Engine.time_scale = 1.0
	# durata totale: da _play_cutin alla fine (ci si ferma al tocco o al tempo massimo)
	var t0: int = Time.get_ticks_msec() - 700
	var g2: int = 0
	while bool(bt.get("_cutin_on")) and g2 < 400:
		g2 += 1
		await process_frame
	print("DURATA CUT-IN ms: ", Time.get_ticks_msec() - t0)
	print("ESITO: OK")
	quit(0)
