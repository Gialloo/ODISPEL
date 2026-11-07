extends SceneTree

# Schermate del menu comandi per tutta la squadra, col menu a ventaglio (autore, 7/11/2026) o con l'HUD di prima.
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/v3_hud_ventaglio.gd -- <cartella> [touch|pc] [ventaglio|ritratto]
# Per ognuno (Lance, Nox, Saul, Rio): turno libero e un comando acceso (SKILL; ULTIMATE per Lance).

var out: String = "/tmp/v3ventaglio"
const COL: Dictionary = {"lance": Color("#e8343f"), "nox": Color("#39b7ff"), "rio": Color("#8e3df0"), "saul": Color("#2f8f5a")}


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	TouchUi.force = a.size() > 1 and a[1] == "touch"
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	Settings.hud_ritratto = true
	Settings.hud_ventaglio = not (a.size() > 2 and a[2] == "ritratto")
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
	var g: int = 0
	while not bool(bt.get("waiting")) and g < 2000:
		g += 1
		await process_frame
	await create_timer(1.2).timeout
	var w: Node = bt.get("_wheel")
	print("HUD ", w.get_class(), " ", w.get_script().resource_path)
	for id in ["lance", "nox", "saul", "rio"]:
		w.call("set_who", id)
		w.set("col", COL[id])
		w.set("appear", 0.0)
		await create_timer(0.6).timeout
		await _shot(id + "_1_libero")
		bt.call("_pick", "skill" if id != "lance" else "attack")
		await create_timer(0.5).timeout
		await _shot(id + "_2_scelto")
		bt.call("_pick", "")
		await create_timer(0.2).timeout
		print("FATTO ", id)
	# il tocco: il centro di ogni lama deve dare il suo comando
	if w.has_method("_kind_at"):
		var polys: Dictionary = w.get("_polys")
		for k in ["skill", "attack", "ult", "guard"]:
			var c := Vector2.ZERO
			for v in polys[k]:
				c += v
			c /= float((polys[k] as PackedVector2Array).size())
			print("TOCCO ", k, " -> ", w.call("_kind_at", c))
	quit()
