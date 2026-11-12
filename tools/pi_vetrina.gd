extends SceneTree

# PROVA GREZZA ISO · schermate: inizio, mirino, CONTRO, carica, sospensione, STAFFETTA, CROLLO, PIANO, fine.
# Uso: xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 -s tools/pi_vetrina.gd -- <cartella>

var out: String = "/tmp/pi_vetrina"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	_run()


func _shot(n: String) -> void:
	for i in 3:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out.path_join(n + ".png"))


func _wait_tele(e: PgEngine, kind: String, left: float) -> void:
	for _i in range(3000):
		await process_frame
		var d: Dictionary = e.danger()
		if not d.is_empty() and d["kind"] != kind:
			e.iframes = 0.5
		if not d.is_empty() and d["kind"] == kind and float(d["left"]) <= left:
			e.iframes = 0.0
			return


func _run() -> void:
	await process_frame
	var sc: Node = load("res://scripts/prova_grezza/pg_iso_scene.gd").new()
	root.add_child(sc)
	await create_timer(1.0).timeout
	await _shot("1_inizio")
	var e: PgEngine = sc.get("eng")
	await _wait_tele(e, "affondo", 0.25)
	await _shot("2_mirino_affondo")
	e.posture = e.danger()["color"]
	sc.call("_gesture", "verso")
	await create_timer(0.05, true, false, true).timeout
	await _shot("3_contro")
	await create_timer(1.2, true, false, true).timeout
	# carica a terra
	e.idle_wait = 99.0
	e.est = "idle"
	e.st = "idle"
	sc.call("_press")
	await create_timer(1.0, true, false, true).timeout
	await _shot("4_carica")
	sc.call("_release")
	await create_timer(0.12, true, false, true).timeout
	await _shot("5_scatto")
	await create_timer(0.6, true, false, true).timeout
	# STAFFETTA nel lampo bianco
	e.px = e.ex - 1.3
	e.st = "idle"
	sc.call("_press")
	sc.call("_release")
	for _i in 60:
		await process_frame
		if e.can_cancel_now():
			break
	e.switch_ready = 0.0
	sc.call("_switch", 1)
	await create_timer(0.08, true, false, true).timeout
	await _shot("6_staffetta")
	await create_timer(0.8, true, false, true).timeout
	# sospensione in aria
	e.st = "idle"
	e.p_air = 0.6
	sc.call("_press")
	await create_timer(0.6, true, false, true).timeout
	await _shot("7_sospeso")
	sc.call("_release")
	await create_timer(1.0, true, false, true).timeout
	# CROLLO
	e.seg = 0.5
	e.last_seg_loss = e.time
	e.pending = {}
	e.st = "idle"
	e.p_air = 0.0
	e.est = "stun"
	e.est_t = 1.0
	e.px = e.ex - 1.3
	sc.call("_gesture", "tocco")
	await create_timer(0.6, true, false, true).timeout
	await _shot("8_crollo")
	e.fiato = 60.0
	sc.call("_open_piano")
	sc.call("_piano_add", "carica")
	sc.call("_piano_add", "cambio")
	await _shot("9_piano")
	sc.call("_piano_close")
	e.ehp = 1.0
	sc.call("_gesture", "verso")
	await create_timer(2.5, true, false, true).timeout
	await _shot("10_fine")
	quit(0)
