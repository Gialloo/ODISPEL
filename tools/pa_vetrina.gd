extends SceneTree

# PROVA GREZZA 2 · schermate dell'arena circolare: inizio, AFFONDO in arrivo, CONTRO CARICATO, SPAZZATA, montante,
# COPERTURA, CROLLO, PIANO.
# Uso: xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 -s tools/pa_vetrina.gd -- <cartella>

var out: String = "/tmp/pa_vetrina"


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


func _wait_tele(e: PgArena, kind: String, left: float) -> void:
	for _i in range(4000):
		await process_frame
		for f in e.fighters:
			f.hp = maxf(f.hp, 60.0)
		var d: Dictionary = e.danger()
		var ok: bool = not d.is_empty() and d["kind"] == kind and int(d["target"]) == e.active
		if not d.is_empty() and not ok:
			for f in e.fighters:
				f.iframes = 0.5
		if ok and float(d["left"]) <= left:
			return


func _run() -> void:
	await process_frame
	var sc: Node = load("res://scripts/prova_grezza/pg_arena_scene.gd").new()
	root.add_child(sc)
	await create_timer(1.2).timeout
	await _shot("1_inizio")
	var e: PgArena = sc.get("eng")
	e.press_attack()
	await create_timer(0.7).timeout
	await _shot("2_carica")
	await _wait_tele(e, "affondo", 0.25)
	await _shot("3_affondo_in_arrivo")
	e.release_attack()
	await create_timer(0.06, true, false, true).timeout
	await _shot("4_contro_caricato")
	e.release_attack()
	await _wait_tele(e, "spazzata", 0.35)
	await _shot("5_spazzata")
	e.est = "stun"
	e.est_t = 3.0
	e.eatk = {}
	e.me().pos = e.epos + Vector2(0, 1.4)
	e.me().st = "idle"
	e.me().p_air = 0.0
	e.me().posture = "blu"
	for k in 2:
		e.press_attack()
		e.release_attack()
		await create_timer(0.18, true, false, true).timeout
	await create_timer(0.45, true, false, true).timeout
	e.press_attack()
	e.release_attack()
	await create_timer(0.35, true, false, true).timeout
	await _shot("6_montante")
	e.seg = 1.0
	e.last_seg_loss = e.time
	e.est = "stun"
	e.est_t = 2.0
	e.e_air = 0.0
	e.me().p_air = 0.0
	e.me().st = "idle"
	e.press_attack()
	e.release_attack()
	await create_timer(0.7, true, false, true).timeout
	await _shot("7_crollo")
	e.fiato = 60.0
	sc.call("_open_piano")
	sc.call("_piano_add", "carica")
	sc.call("_piano_add", "cambio")
	await _shot("8_piano")
	sc.call("_piano_close")
	quit(0)
