extends SceneTree

# Schermate dell'HUD 0.61 (P0: RITMO di squadra, prossima mossa, avvisi), mockup approvati dall'autore il 7/11/2026.
# (Nota: a risoluzioni alte sotto xvfb i timbri del P2 a volte non compaiono nelle schermate; a 1280x720 si vedono.)
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/v3_hud_061.gd -- <cartella> [touch|pc]
# Per ogni livello del RITMO: turno libero e ATTACCO scelto. I valori del RITMO sono messi a mano (solo per la schermata).

var out: String = "/tmp/v3hud061"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1 and a[1] == "touch":
		TouchUi.force = true
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	Settings.hud_ritratto = true
	_run()


func _shot(n: String) -> void:
	for i in 4:
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
	await create_timer(float(OS.get_environment("ATTESA") if OS.get_environment("ATTESA") != "" else "1.2")).timeout
	await _shot("0_inizio")
	bt.call("_pick", "attack")
	await create_timer(0.4).timeout
	await _shot("0_inizio_acceso")       # avvisi compatti col comando acceso (P0-C)
	bt.call("_pick", "")
	await create_timer(4.5).timeout      # gli avvisi d'inizio se ne vanno
	var b: Dictionary = bt.get("b")
	# un compagno con l'ULTIMATE piena (stella sulla card, P1-B)
	BattleState.active_unit(b, str(BattleState.alive_players(b)[1]["id"]))["gauge"] = BattleTypes.GAUGE_MAX
	# livello, ardore, soglia raggiunta senza condizione
	var casi: Array = [[0, 14, false], [1, 52, true], [2, 66, false], [3, 88, false]]
	for c in casi:
		var r: Dictionary = Ritmo.st(b)
		r["level"] = c[0]
		r["ardore"] = c[1]
		r["ready"] = c[2]
		r["done"] = {}
		bt.call("_refresh_hud")
		await create_timer(0.4).timeout
		var nm: String = "ritmo_%d_%s" % [int(c[0]), Ritmo.level_name(int(c[0])).to_lower()]
		await _shot(nm + "_libero")
		bt.call("_pick", "attack")
		await create_timer(0.6).timeout
		await _shot(nm + "_acceso")
		bt.call("_pick", "")
		await create_timer(0.3).timeout
	# prossima mossa: VERBALE (FORTE, su uno) e nemico stordito (dati del telegrafo messi a mano solo per la schermata)
	var pid: String = str(BattleState.alive_players(b)[0]["id"])
	var tele_ok: Dictionary = b.get("telegraph", {}).duplicate()
	b["telegraph"] = {"move": "verbale", "target": pid}
	BattleState.active_unit(b, pid)["hp"] = 60          # a un colpo dal KO: avviso di PERICOLO (P0-C) e "!" sul ritratto
	bt.call("_refresh_hud")
	await create_timer(0.3).timeout
	await _shot("minaccia_forte_libero")
	bt.call("_pick", "attack")
	await create_timer(0.6).timeout
	await _shot("minaccia_forte_acceso")
	bt.call("_pick", "")
	await create_timer(0.3).timeout
	BattleState.boss(b)["stun"] = 1
	bt.call("_refresh_hud")
	await create_timer(0.3).timeout
	await _shot("minaccia_stordito")
	BattleState.boss(b)["stun"] = 0
	b["telegraph"] = tele_ok
	bt.call("_refresh_hud")
	# P2: accenti nei timbri (DEBOLEZZA di ognuno) e +N ULTIMATE della parata perfetta (i timbri escono a comandi chiusi)
	bt.call("_show_commands", false)
	(bt.get("_wheel") as Control).visible = false
	for i in 4:
		var u: Dictionary = bt.call("_slot_unit", i)
		bt.set("_stamp_free_ms", 0)          # niente coda dei timbri: la schermata arriva subito
		bt.call("_stamp", "DEBOLEZZA!", "%s colpisce il punto debole" % str(u["name"]).to_upper(), Ui.YELLOW, 0.7, str(u.get("char", "")))
		await create_timer(0.75).timeout
		await _shot("accento_%s" % str(u.get("char", "")))
		await create_timer(1.2).timeout
	var pu: Dictionary = bt.call("_slot_unit", 0)
	bt.call("_parry_gain_fly", [{"t": "timed_guard", "unit": pu["id"], "grade": "perfect"},
		{"t": "resource_change", "resource": "gauge", "unit": pu["id"], "effective": BattleTypes.TIMED_PERFECT_GAUGE, "source": "timed_guard"}])
	await create_timer(0.55).timeout
	await _shot("parata_ultimate_1")
	await create_timer(0.55).timeout
	await _shot("parata_ultimate_2")
	(bt.get("_wheel") as Control).visible = true
	bt.call("_show_commands", true)
	await create_timer(0.5).timeout
	bt.call("_pick", "attack")
	await create_timer(0.08).timeout
	await _shot("lampo_scelta")
	bt.call("_pick", "")
	quit()
