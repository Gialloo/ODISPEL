extends SceneTree

# Schermate della CORNICE dei personaggi (prova, 7/11/2026): stesso momento con la cornice accesa e spenta.
# Uso: xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 -s tools/v3_hud_cornici.gd -- <cartella> [touch|pc] [id]
var out: String = "/tmp/v3cornici"
var who: String = "saul"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1 and a[1] == "touch":
		TouchUi.force = true
	if a.size() > 2:
		who = a[2]
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	Settings.hud_ritratto = true
	_run()


func _shot(n: String) -> void:
	for i in 4:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out.path_join(n + ".png"))


func _as_who(bt: Node, ult_full: bool) -> void:
	var w: PortraitHud = bt.get("_wheel")
	var b: Dictionary = bt.get("b")
	var u: Dictionary = {}
	for p in BattleState.alive_players(b):
		if str(p.get("char", "")) == who:
			u = p
	var items: Array = (w.get("items") as Array).duplicate(true)
	for it in items:
		if str(it.get("kind", "")) == "ult":
			it["ok"] = ult_full
			if not ult_full:
				it["cost"] = "45%"
	w.set_who(who)
	w.setup(str(u.get("name", who)).to_upper() if not u.is_empty() else who.to_upper(), bt.call("_col", u) if not u.is_empty() else Color("#2e8b3d"), items)


func _run() -> void:
	await process_frame
	var bt: Node = load("res://scripts/v3/battle3d.gd").new()
	bt.configure({"boss": "autovelox", "livello": 11, "arena": "tangenziale"})
	root.add_child(bt)
	var guard: int = 0
	while not bool(bt.get("waiting")) and guard < 600:
		guard += 1
		await process_frame
	await create_timer(4.5).timeout          # gli avvisi d'inizio se ne vanno
	for on in [false, true]:
		Settings.hud_cornice = on
		var w: PortraitHud = bt.get("_wheel")
		w.set("who_id", "")                  # ricarica i livelli
		var tag: String = "dopo" if on else "prima"
		_as_who(bt, true)
		await create_timer(0.6).timeout
		await _shot("%s_%s_ult_pronta" % [who, tag])
		_as_who(bt, false)
		await create_timer(0.3).timeout
		await _shot("%s_%s_ult_carica" % [who, tag])
		w.pick("attack")
		await create_timer(0.5).timeout
		await _shot("%s_%s_attacco_scelto" % [who, tag])
		w.pick("")
		await create_timer(0.3).timeout
	if Settings.hud_foto:
		# ANTEPRIMA DELLO STILE (dati messi a mano solo per la schermata): sinergia, ritmo acceso, tasti di REAZIONE e Ultimate in diretta
		var w2: PortraitHud = bt.get("_wheel")
		w2.banner_title = "SINERGIA"
		w2.banner_sub = "Tec: +12% attacco e difesa"
		var b2: Dictionary = bt.get("b")
		var r: Dictionary = Ritmo.st(b2)
		r["level"] = 1
		r["ardore"] = 52
		r["ready"] = true
		bt.call("_refresh_hud")
		var rb: Dictionary = bt.get("_react_btns")
		(bt.get("_react_box") as Control).visible = true
		for rid in ["schivata", "intercettazione", "interruzione"]:
			(rb[rid] as Button).visible = true
		var names: Array = ["ULT NOX", "ULT LANCE"]
		var lbs: Array = bt.get("_live_btns")
		for i in 2:
			(lbs[i] as Button).text = names[i]
			(lbs[i] as Button).visible = true
		_as_who(bt, true)
		w2.banner_title = "SINERGIA"
		w2.banner_sub = "Tec: +12% attacco e difesa"
		w2.queue_redraw()
		await create_timer(0.5).timeout
		await _shot("%s_anteprima_stile" % who)
	quit()
