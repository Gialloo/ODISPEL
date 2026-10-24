extends SceneTree

# Prova dei ritocchi HUD: fumetto di un personaggio in battaglia, card con vetro rotto (PV bassi e KO), bersaglio che brilla.
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/v3_ritocchi.gd -- <cartella>

var out: String = "/tmp/v3rit"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
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
	var g: int = 0
	while not bool(bt.get("waiting")) and g < 600:
		g += 1
		await process_frame
	await create_timer(1.2).timeout
	var slots: Array = bt.get("slots")
	# PV bassi su uno, KO su un altro
	var u1: Dictionary = bt.call("_slot_unit", 1)
	u1["hp"] = maxi(1, int(u1["max_hp"]) / 5)
	var u2: Dictionary = bt.call("_slot_unit", 2)
	u2["hp"] = 0
	bt.call("_refresh_hud")
	await create_timer(0.6).timeout
	await _shot("r1_vetro_rotto")
	# battuta di un personaggio
	var cur: Dictionary = bt.call("_unit_of", bt.get("cur_pid"))
	var ch: Node = bt.get("_cutin")
	ch.visible = true
	(bt.get("_hint") as Label).text = ""
	(ch.get_node("Band") as ColorRect).color = Color(0.55, 0.3, 1.0, 0.85)
	(ch.get_node("Name") as Label).text = str(cur["name"]).to_upper() + " · ULTIMATE"
	bt.call("_say", cur, "«" + DialogData.ult_line(str(cur["char"])) + "»")
	await create_timer(0.4).timeout
	await _shot("r2_fumetto")
	bt.call("_say_off")
	ch.visible = false
	print("OK ritocchi")
	quit(0)
