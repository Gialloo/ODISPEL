extends SceneTree

# Schermate dell'HUD col ritratto 2D (riferimento dell'autore, 2/11/2026): turno libero e ATTACCO scelto.
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/v3_hud_ritratto.gd -- <cartella> [touch|pc] [gregario]
# (gregario, es. frammento_rosso: scontro con due nemici, per vedere MIRA QUI e la scheggia con questo HUD)

var out: String = "/tmp/v3ritratto"
var greg: String = ""


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1 and a[1] == "touch":
		TouchUi.force = true
	if a.size() > 2:
		greg = a[2]
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
	var cfg: Dictionary = {"boss": "autovelox", "livello": 11, "arena": "tangenziale"}
	if greg != "":
		cfg = {"boss": "frammento_blu", "livello": 6, "arena": "tangenziale", "gregario": greg}
	bt.configure(cfg)
	root.add_child(bt)
	var guard: int = 0
	while not bool(bt.get("waiting")) and guard < 600:
		guard += 1
		await process_frame
	await create_timer(1.2).timeout
	print("TURNO ", bt.get("cur_pid"))
	await _shot("1_turno")
	bt.call("_pick", "attack")
	await create_timer(0.6).timeout
	await _shot("2_attacco_scelto")
	bt.call("_pick", "")
	await create_timer(0.3).timeout
	quit()
