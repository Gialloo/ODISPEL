extends SceneTree

# Schermate dell'HUD 0.61 (P0: RITMO di squadra, prossima mossa, avvisi), mockup approvati dall'autore il 7/11/2026.
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
	quit()
