extends SceneTree

# Prova del BREAK e dell'ATTACCO DI SQUADRA in battaglia vera: equilibrio del nemico a 1, ATTACCO, poi si guarda
# se i PV del nemico scendono per ogni compagno e si salvano le schermate della sequenza.
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/v3_break_squadra.gd -- <cartella>

var out: String = "/tmp/v3break"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	TouchUi.force = true
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	_run()


func _shot(n: String) -> void:
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
	await create_timer(1.0).timeout
	var b: Dictionary = bt.get("b")
	var boss: Dictionary = BattleState.boss(b)
	boss["balance"] = 1
	var hp0: int = int(boss["hp"])
	print("PRIMA: PV nemico ", hp0, " turno ", bt.get("cur_pid"))
	bt.call("_wheel_tap", "attack")
	bt.call("_wheel_tap", "attack")
	for i in 14:
		await create_timer(0.45).timeout
		await _shot("break_%02d" % i)
		print("t=%.1f PV nemico %d squadra=%s" % [0.45 * (i + 1), int(boss["hp"]), str(bt.get("_team_on"))])
	var hp1: int = int(boss["hp"])
	print("ESITO: PV nemico ", hp0, " -> ", hp1)
	quit(0)
