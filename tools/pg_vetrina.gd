extends SceneTree

# PROVA GREZZA · schermate: inizio, MIRINO dell'AFFONDO, CONTRO, SPAZZATA, CROLLO, PIANO, fine.
# Uso: xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 -s tools/pg_vetrina.gd -- <cartella>

var out: String = "/tmp/pg_vetrina"


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
	var sc: Node = load("res://scripts/prova_grezza/pg_scene.gd").new()
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
	await create_timer(0.5, true, false, true).timeout
	sc.call("_gesture", "tocco")
	await create_timer(0.12, true, false, true).timeout
	await _shot("4_colpo_lampo")
	await _wait_tele(e, "spazzata", 0.35)
	await _shot("5_mirino_spazzata")
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
	await _shot("6_crollo")
	e.fiato = 60.0
	sc.call("_open_piano")
	sc.call("_piano_add", "tocco")
	sc.call("_piano_add", "su")
	await _shot("7_piano")
	sc.call("_piano_close")
	e.ehp = 1.0
	sc.call("_gesture", "verso")
	await create_timer(2.5, true, false, true).timeout
	await _shot("8_fine")
	quit(0)
