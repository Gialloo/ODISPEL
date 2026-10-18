extends SceneTree

# Screenshot del test 0.29.0: menu, strada, dialogo, combattimento (comandi, azione, ultimate), fine.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_shot.gd -- <cartella> [touch]

var out: String = "/tmp/v3shot"
var main: Node


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.has("touch"):
		TouchUi.force = true
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _secs(s: float) -> void:
	await create_timer(s).timeout


func _shot(name: String) -> void:
	await _frames(2)
	var img: Image = root.get_texture().get_image()
	img.save_png(out + "/" + name + ".png")
	print("shot ", name)


func _run() -> void:
	await _secs(1.2)
	await _shot("01_menu")
	main.go("street")
	await _secs(1.6)
	await _shot("02_strada")
	var st: Node = main.current
	var pl: Node3D = st.get("player")
	# cammina un po' in avanti
	for i in 40:
		pl.position.z -= 0.25
		pl.set("move_speed", 1.0)
		await process_frame
	await _shot("03_strada_cammino")
	pl.position = Vector3(3.6, 0.14, -31.4)
	st.set("yaw", -0.6)
	await _secs(1.0)
	await _shot("04_vicino_distributore")
	st.call("_interact")
	await _secs(1.4)
	await _shot("05_dialogo")
	var dlg: Node = st.get("_dialog")
	dlg.call("advance")
	dlg.call("advance")
	await _secs(1.2)
	dlg.call("advance")
	dlg.call("advance")
	await _secs(2.6)
	var bt: Node = main.current
	await _shot("06_battaglia_inizio")
	# aspetta il primo turno del giocatore
	var guard: int = 0
	while not bool(bt.get("waiting")) and guard < 400:
		guard += 1
		await process_frame
	await _secs(0.6)
	await _shot("07_battaglia_comandi")
	bt.call("_command", "attack")
	await _secs(0.75)
	await _shot("08_battaglia_attacco")
	guard = 0
	while not bool(bt.get("waiting")) and guard < 900:
		guard += 1
		await process_frame
	# ultimate carica per la foto
	var b: Dictionary = bt.get("b")
	var u: Dictionary = BattleState.active_unit(b, str(bt.get("cur_pid")))
	u["gauge"] = BattleTypes.GAUGE_MAX
	bt.call("_refresh_hud")
	await _secs(0.4)
	await _shot("09_battaglia_ult_pronta")
	bt.call("_command", "ult")
	await _secs(0.55)
	await _shot("10_ultimate")
	await _secs(1.4)
	await _shot("11_ultimate_colpo")
	# il resto in AUTO, veloce
	bt.call("_toggle_auto")
	guard = 0
	while not bool(bt.get("ended")) and guard < 6000:
		guard += 1
		await process_frame
	await _secs(1.6)
	await _shot("12_risultato")
	main.go("street", {"done": true, "won": true})
	await _secs(1.6)
	await _shot("13_fine")
	Engine.time_scale = 1.0
	quit()
