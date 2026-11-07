extends SceneTree

# Schermate della voce COLORI nel menu pausa (7/11/2026): battaglia senza il tasto, pausa con la voce, guida aperta.
# Uso: xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 -s tools/v3_guida_colori.gd -- <cartella> [touch|pc]
var out: String = "/tmp/v3colori"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1 and a[1] == "touch":
		TouchUi.force = true
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	_run()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(n: String) -> void:
	await _frames(4)
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
	await create_timer(4.5).timeout
	await _shot("battaglia_senza_colori")
	bt.call("_open_pause")
	await _frames(90)
	await _shot("pausa_con_colori")
	var p: Node = bt.get("_pause")
	p.add_child(ColorGuide.new())
	await _frames(10)
	await _shot("guida_colori")
	quit()
