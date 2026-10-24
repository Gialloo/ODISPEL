extends SceneTree

# Prova della minaccia a terra del nemico: inquadratura larga con attacco SU TUTTI e con attacco su UNO.
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/v3_minaccia.gd -- <cartella>

var out: String = "/tmp/v3minaccia"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	TouchUi.force = true
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	_run()


func _shot(n: String) -> void:
	for i in 3:
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
	bt.call("_show_commands", false)
	bt.call("_cam_set", Vector3(0.0, 6.5, 9.5), Vector3(0.0, 0.0, -0.6), 99.0)
	var one: String = ""
	var all: String = ""
	for k in BattleContent.BOSS_MOVES:
		var m: Dictionary = BattleContent.BOSS_MOVES[k]
		if bool(m.get("camera", false)):
			continue
		if str(m.get("target", "one")) == "all" and all == "":
			all = str(k)
		elif str(m.get("target", "one")) != "all" and one == "":
			one = str(k)
	b["telegraph"] = {"move": all, "target": ""}
	bt.call("_refresh_hud")
	await create_timer(0.8).timeout
	await _shot("minaccia_tutti")
	var p: Dictionary = BattleState.alive_players(b)[1]
	b["telegraph"] = {"move": one, "target": str(p["id"])}
	bt.call("_refresh_hud")
	await create_timer(0.8).timeout
	await _shot("minaccia_uno")
	print("ESITO: tutti=", all, " uno=", one)
	quit(0)
