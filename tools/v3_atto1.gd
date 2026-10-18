extends SceneTree

# Gioca da solo tutto l'atto 1 (scene saltate, indizi raccolti, battaglie in AUTO) e salva screenshot di ogni passo.
# Serve a trovare blocchi ed errori e a vedere il bilanciamento: stampa l'esito di ogni battaglia.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_atto1.gd -- <cartella> [touch] [tutte]
#   "tutte" = combatte anche un frammento per area (altrimenti solo il primo dell'atto)

var out: String = "/tmp/v3atto1"
var main: Node
var n: int = 0
var all_fights: bool = false
var report: Array = []
var start_ch: int = -1


func _init() -> void:
	Story.save_path = "user://salvataggio_prova.cfg"     # mai il salvataggio vero
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.has("touch"):
		TouchUi.force = true
	all_fights = args.has("tutte")
	for a in args:
		if a.begins_with("capitolo="):
			start_ch = int(a.substr(9))
	Settings.ensure_loaded()
	Settings.surprise = true
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run()


func _secs(s: float) -> void:
	await create_timer(s, true, false, true).timeout


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	n += 1
	root.get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, name])


func _cur() -> Node:
	return main.get("current")


func _run() -> void:
	await _secs(1.0)
	await _shot("menu")
	Story.new_game()
	if start_ch >= 0:
		Story.start_chapter(start_ch)
	main.next_story()
	var fought_minor: bool = false
	var guard: int = 0
	while guard < 80:
		guard += 1
		await _secs(0.9)
		var sc: Node = _cur()
		if sc == null or not is_instance_valid(sc):
			continue
		var path: String = sc.get_script().resource_path.get_file()
		var tag: String = "c%d_p%d" % [Story.chapter, Story.step]
		print("PASSO ", tag, " ", path)
		if path == "ending_screen.gd":
			await _shot("fine")
			break
		elif path == "card_screen.gd":
			await _shot(tag + "_cartello")
			await _wait_change(sc, 6.0)
		elif path == "scene_screen.gd":
			await _secs(1.0)
			await _shot(tag + "_scena")
			var dlg: Node = sc.get("_dialog")
			for i in 3:
				if is_instance_valid(dlg):
					dlg.call("advance")
					dlg.call("advance")
			await _secs(0.7)
			if is_instance_valid(dlg):
				await _shot(tag + "_scena_b")
				dlg.call("skip")
			await _wait_change(sc, 8.0)
		elif path == "area.gd":
			await _play_area(sc, tag, not fought_minor or all_fights)
			fought_minor = true
		elif path == "battle3d.gd":
			await _play_battle(sc, tag)
		else:
			print("SCHERMATA INATTESA ", path)
			break
	print("---- ESITO BATTAGLIE ----")
	for r in report:
		print(r)
	quit()


func _wait_change(sc: Variant, limit: float) -> void:
	var t: float = 0.0
	if not is_instance_valid(sc):
		return
	while is_instance_valid(sc) and _cur() == sc and t < limit:
		await _secs(0.2)
		t += 0.2
	if is_instance_valid(sc) and _cur() == sc:
		print("BLOCCATO su ", sc.get_script().resource_path.get_file())


func _dialog_through(sc: Node, shot_name: String) -> void:
	var dlg: Node = sc.get("_dialog")
	var g: int = 0
	while not bool(dlg.call("is_open")) and g < 120:
		g += 1
		await process_frame
	if bool(dlg.call("is_open")):
		await _secs(0.8)
		if shot_name != "":
			await _shot(shot_name)
		dlg.call("skip")
		await _secs(0.6)


func _place(sc: Node, p: Vector3) -> void:
	var pl: Node3D = sc.get("player")
	pl.position = p
	sc.call("_update_camera", 1.0, true)
	await _secs(0.25)
	sc.call("_update_target")


func _play_area(sc: Node, tag: String, fight: bool) -> void:
	# l'apertura del prologo
	if str(sc.get("mode")).begins_with("intro"):
		await _dialog_through(sc, tag + "_apertura")
		var g: int = 0
		while is_instance_valid(sc) and str(sc.get("mode")) != "walk" and g < 400:
			g += 1
			await process_frame
	await _secs(0.6)
	if not is_instance_valid(sc):
		return
	await _shot(tag + "_area")
	var cfg: Dictionary = sc.get("cfg")
	var clues: Array = sc.get("clues")
	var k: int = 0
	for c in cfg.get("indizi", []):
		if clues.has(str(c["id"])):
			continue
		var cp: Array = c["pos"]
		await _place(sc, Vector3(float(cp[0]) + 0.6, 0.14, float(cp[1]) + 0.6))
		if str(sc.get("_target")) != "indizio:" + str(c["id"]):
			print("  indizio non raggiungibile: ", c["id"], " target=", sc.get("_target"))
			continue
		sc.call("_interact")
		await _dialog_through(sc, tag + "_indizio" if k == 0 else "")
		k += 1
	await _secs(2.5)
	if not is_instance_valid(sc) or _cur() != sc:
		return
	await _shot(tag + "_chiacchiere")
	# un frammento: attacco a sorpresa
	var enemies: Dictionary = sc.get("_enemies")
	if fight and not enemies.is_empty():
		var id: String = str(enemies.keys()[0])
		var ep: Vector3 = (enemies[id]["node"] as Node3D).position
		await _place(sc, ep + Vector3(1.6, 0, 0))
		sc.call("_strike")
		return
	if cfg.has("boss"):
		var bn: Node3D = sc.get("_boss")
		await _place(sc, bn.position + Vector3(0, 0, 2.2))
		sc.call("_interact")
		await _dialog_through(sc, tag + "_boss_parla")
	elif cfg.has("uscita"):
		var ex: Node3D = sc.get("_exit_node")
		await _place(sc, ex.position + Vector3(0, 0, 1.4))
		if str(sc.get("_target")) != "uscita":
			print("  uscita non raggiungibile, target=", sc.get("_target"))
		sc.call("_interact")
		await _dialog_through(sc, tag + "_uscita")
	await _wait_change(sc, 8.0)


func _play_battle(sc: Node, tag: String) -> void:
	await _secs(2.5)
	await _shot(tag + "_battaglia_" + str(sc.get("boss_id")))
	sc.call("_toggle_auto")
	var t: float = 0.0
	Engine.time_scale = 4.0
	var shot_mid: bool = false
	while not bool(sc.get("ended")) and t < 600.0:
		await _secs(0.5)
		t += 0.5
		if not shot_mid and t > 6.0:
			shot_mid = true
			Engine.time_scale = 1.0
			await _shot(tag + "_battaglia_turno")
			Engine.time_scale = 4.0
	Engine.time_scale = 1.0
	var b: Dictionary = sc.get("b")
	var win: bool = str(b.get("winner", "")) == "players"
	report.append("%s %s lv%d -> %s (round %s, %ds sim)" % [tag, sc.get("boss_id"), sc.get("level"), "VITTORIA" if win else "SCONFITTA", str(b.get("round", "?")), int(t * 4.0)])
	await _secs(2.0)
	await _shot(tag + "_esito")
	if win:
		sc.call("_continue_story")
	else:
		# per proseguire il giro di prova si fa finta di aver vinto
		var r: Dictionary = sc.get("ritorno")
		if str(r.get("tipo", "")) == "area":
			main.go("area", {"area": str(r.get("area", "")), "resume": r.get("vinto", {})})
		else:
			sc.call("_continue_story")
	await _secs(1.0)
