extends SceneTree

# Prova delle battute a fumetto della squadra (battle_quips.gd): una battaglia giocata da sola in ATTACCO, stampa ogni
# battuta che esce e fa le schermate; poi mostra a comando un botta e risposta per vedere i due fumetti.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_battute.gd -- <cartella> [nemico] [arena]

var out: String = "/tmp/v3battute"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	Story.save_path = "user://salvataggio_prova.cfg"
	Settings.ensure_loaded()
	Story.set_flag("lezioni_fatte")
	_run(a[1] if a.size() > 1 else "semaforo", a[2] if a.size() > 2 else "strada")


func _shot(n: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(out.path_join(n + ".png"))


func _run(id: String, ar: String) -> void:
	await process_frame
	var bt: Node = load("res://scripts/v3/battle3d.gd").new()
	bt.configure({"boss": id, "visual": id, "livello": 3, "arena": ar, "ingresso": "normale",
		"ritorno": {"tipo": "area", "area": "incrocio", "vinto": {}, "perso": {}}, "minore": true})
	root.add_child(bt)
	var t0: int = Time.get_ticks_msec()
	while not bool(bt.get("waiting")) and Time.get_ticks_msec() - t0 < 15000:
		await process_frame
	# 1) a comando: botta e risposta (Rio fa il critico, Lance risponde)
	var rows: Array = [{"chi": "zecca", "testo": "Avete visto QUELLO CHE HO FATTO?"}, {"chi": "ferri", "testo": "Sì. Torna in formazione."}]
	bt.call("_quip_show", rows, 0.0)
	await create_timer(0.7).timeout
	await _shot("1_battuta")
	await create_timer(BattleQuips.hold(str(rows[0]["testo"]))).timeout
	await _shot("2_risposta")
	await create_timer(3.0).timeout
	# 2) battaglia vera: ogni battuta che compare nel fumetto
	var lbl: Label = bt.get("_quip_lbl")
	var last: String = ""
	var n: int = 0
	var turns: int = 0
	var tt: int = Time.get_ticks_msec()
	var end_t: int = -1
	while Time.get_ticks_msec() - tt < 150000:
		if not is_instance_valid(bt) or not bt.is_inside_tree():
			break
		if lbl != null and lbl.visible and lbl.text != last and lbl.text != "":
			last = lbl.text
			n += 1
			print("BATTUTA ", n, ": ", last)
			if n <= 4:
				await create_timer(0.4).timeout
				await _shot("battaglia_%d" % n)
		if bool(bt.get("ended")):
			if end_t < 0:
				end_t = Time.get_ticks_msec()
			elif Time.get_ticks_msec() - end_t > 5000:      # la battuta del colpo finale esce mentre si festeggia
				break
		if bool(bt.get("waiting")):
			await create_timer(0.3).timeout
			bt.call("_command", "attack")
			turns += 1
		await process_frame
	print("BATTUTE: %d in %d turni" % [n, turns])
	quit(0)
