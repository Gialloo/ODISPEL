extends SceneTree

# Prova della ruota dei comandi (HUD di battaglia ripreso dalla V2): turno libero, ATTACCO scelto, ULTIMATE scelta.
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/v3_hud_ruota.gd -- <cartella> [touch]

var out: String = "/tmp/v3hud"


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
	await create_timer(1.2).timeout
	print("TURNO ", bt.get("cur_pid"))
	await _shot("1_libera")
	# ruota dei colori aperta col tasto COLORI (chiusa di solito: una cosa per volta)
	var leg: Control = bt.get("_legend")
	if leg != null:
		leg.visible = true
		await _shot("1b_colori")
		leg.visible = false
	if bt.has_method("_pick"):
		bt.call("_pick", "attack")
		await create_timer(0.6).timeout
		await _shot("2_attacco")
		var u: Dictionary = bt.call("_unit_of", bt.get("cur_pid"))
		u["gauge"] = 100
		bt.call("_pick", "")
		bt.call("_refresh_hud")
		bt.call("_pick", "ult")
		await create_timer(0.8).timeout
		await _shot("3_ultimate")
		bt.call("_pick", "")
		bt.call("_pick", "skill")
		await create_timer(0.6).timeout
		await _shot("4_abilita")
		# tocco vero (come un dito) su ATTACCO due volte: scelta, poi lancio
		bt.call("_pick", "")
		await create_timer(0.3).timeout
		var w: Control = bt.get("_wheel")
		var who: String = str(bt.get("cur_pid"))
		var hit: Rect2 = (w.get("hits") as Dictionary)["attack"]
		var p: Vector2 = (w.get("center") as Vector2) + hit.get_center()
		for k in 2:
			var ev := InputEventMouseButton.new()
			ev.button_index = MOUSE_BUTTON_LEFT
			ev.pressed = true
			ev.position = p
			root.get_viewport().push_input(ev, true)
			var up := InputEventMouseButton.new()
			up.button_index = MOUSE_BUTTON_LEFT
			up.position = p
			root.get_viewport().push_input(up, true)
			await create_timer(0.3).timeout
			print("TOCCO ", k + 1, " scelto=", bt.get("_picked"), " in attesa=", bt.get("waiting"))
		var ok: bool = not bool(bt.get("waiting")) or str(bt.get("cur_pid")) != who
		print("ESITO TOCCO: ", "OK" if ok else "FALLITO")
		quit(0 if ok else 1)
		return
	quit(0)
