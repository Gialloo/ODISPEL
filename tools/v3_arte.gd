extends SceneTree

# Schermate dell'art director: gioca a mano (niente AUTO) i momenti da vedere: turno con mirino, comando scelto, colpo, BREAK
# (si porta l'equilibrio del nemico a 1 cosi' il primo colpo rompe) e i quattro minigiochi di reazione.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_arte.gd -- <cartella> [touch]

var out: String = "/tmp/v3arte"
var main: Node
var n: int = 0


func _init() -> void:
	Story.save_path = "user://salvataggio_prova.cfg"     # mai il salvataggio vero
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.has("touch"):
		TouchUi.force = true
	Settings.ensure_loaded()
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


func _wait_turn(sc: Node) -> bool:
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 60000:
		await process_frame
		if not is_instance_valid(sc) or bool(sc.get("ended")):
			return false
		if bool(sc.get("waiting")):
			return true
	return false


func _run() -> void:
	await _secs(1.0)
	main.go("battle", {"from": "menu", "boss": "distributore", "livello": 3})
	await _secs(2.0)
	var sc: Node = main.get("current")
	# salta i tutorial se ci sono
	var td: Variant = sc.get("_tut_dlg")
	while td != null and is_instance_valid(td):
		td.call("skip")
		await _secs(0.6)
		td = sc.get("_tut_dlg")
	if not await _wait_turn(sc):
		quit()
		return
	await _secs(0.35)
	await _shot("turno_mirino")
	# primo colpo normale: comando scelto e colpo
	sc.call("_command", "attack")
	await _secs(0.04)
	await _shot("comando_scelto")
	await _secs(1.1)
	await _shot("colpo")
	await _secs(0.5)
	await _shot("colpo_numeri")
	# secondo turno: equilibrio quasi a zero, il colpo rompe
	if not await _wait_turn(sc):
		quit()
		return
	var b: Dictionary = sc.get("b")
	(b["units"][BattleState.BOSS_ID] as Dictionary)["balance"] = 1
	sc.call("_refresh_hud")
	await _secs(0.3)
	await _shot("turno_prima_del_break")
	sc.call("_command", "attack")
	var marks: Array = [0.9, 1.15, 1.35, 1.7, 2.3]
	var prev: float = 0.0
	for m in marks:
		await _secs(float(m) - prev)
		prev = float(m)
		await _shot("break_%03d" % int(float(m) * 100.0))
	# minigiochi di reazione sopra la battaglia (si aspetta il turno dei comandi e li si nasconde, come nel turno del nemico)
	if not await _wait_turn(sc):
		quit()
		return
	sc.call("_show_commands", false)
	for mode in ["arrow", "hold", "mash", "beat"]:
		var g := ReactGame.new(mode, "NOX", Ui.CYAN, true)
		root.add_child(g)
		await _secs(0.3)
		if mode == "hold":
			var d := InputEventMouseButton.new()
			d.button_index = MOUSE_BUTTON_LEFT
			d.pressed = true
			d.position = Vector2(400, 300)
			Input.parse_input_event(d)
			await _secs(0.78)
		if mode == "beat":
			await _secs(0.16)
		await _shot("reazione_" + mode)
		g.queue_free()
		await _secs(0.2)
	quit()
