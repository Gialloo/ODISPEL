extends SceneTree

# Screenshot del flusso completo: menu, apertura con dialoghi stile Persona, strada, indizio, attacco a sorpresa,
# combattimento (comandi, attacco, ultimate), dialogo di vittoria, finale.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_shot.gd -- <cartella> [touch]

var out: String = "/tmp/v3shot"
var main: Node


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.has("touch"):
		TouchUi.force = true
	Settings.ensure_loaded()
	Settings.surprise = true
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
	root.get_texture().get_image().save_png(out + "/" + name + ".png")
	print("shot ", name)


func _wait_dialog(dlg: Node, open: bool, limit: int = 600) -> void:
	var g: int = 0
	while bool(dlg.call("is_open")) != open and g < limit:
		g += 1
		await process_frame


func _run() -> void:
	await _secs(1.2)
	await _shot("01_menu")
	main.go("street")
	await _secs(1.5)
	await _shot("02_apertura_cupola")
	var st: Node = main.current
	var dlg: Node = st.get("_dialog")
	await _wait_dialog(dlg, true)
	await _secs(1.2)
	await _shot("03_apertura_zecca")
	dlg.call("advance")
	dlg.call("advance")
	await _secs(1.0)
	await _shot("04_apertura_ferri")
	for i in 4:
		dlg.call("advance")
		dlg.call("advance")
	await _secs(0.8)
	await _shot("05_apertura_saul")
	dlg.call("skip")
	await _secs(0.6)
	await _shot("06_riassunto_e_cartello")
	await _secs(2.8)
	await _shot("07_strada")
	var pl: Node3D = st.get("player")
	pl.position = Vector3(3.2, 0.14, -27.6)
	await _secs(0.5)
	await _shot("08_vicino_scontrino")
	st.call("_interact")
	await _secs(1.2)
	await _shot("09_dialogo_scontrino")
	for i in 4:
		dlg.call("advance")
	await _secs(1.0)
	pl.position = Vector3(3.6, 0.14, -31.4)
	st.set("yaw", -0.6)
	await _secs(1.0)
	await _shot("10_attacca_o_parla")
	st.call("_strike")
	await _secs(2.6)
	var bt: Node = main.current
	await _shot("11_battaglia_sorpresa")
	var guard: int = 0
	while not bool(bt.get("waiting")) and guard < 600:
		guard += 1
		await process_frame
	await _secs(0.5)
	await _shot("12_battaglia_comandi")
	var b: Dictionary = bt.get("b")
	var u: Dictionary = BattleState.active_unit(b, str(bt.get("cur_pid")))
	u["gauge"] = BattleTypes.GAUGE_MAX
	bt.call("_refresh_hud")
	bt.call("_command", "ult")
	await _secs(0.55)
	await _shot("13_ultimate")
	bt.call("_toggle_auto")
	bt.call("_toggle_fast")
	guard = 0
	while not bool(bt.get("ended")) and guard < 8000:
		guard += 1
		await process_frame
	Engine.time_scale = 1.0
	await _secs(2.2)
	await _shot("14_vittoria_dialogo")
	for d in bt.get("_root").get_children():
		if d is DialogBox:
			d.call("skip")
	await _secs(0.8)
	await _shot("15_risultato")
	main.go("street", {"done": true, "won": true})
	await _secs(2.6)
	var st2: Node = main.current
	await _shot("16_finale_voce")
	var d2: Node = st2.get("_dialog")
	d2.call("skip")
	await _secs(1.0)
	await _shot("17_fine")
	quit()
