extends SceneTree

# COLPO FINALE DIVERSO PER OGNI NEMICO, dentro la battaglia vera: il boss parte con 1 PV, il primo ATTACCO lo abbatte e si
# registrano i fotogrammi (rallentatore, fermo immagine con la parola del finale, piccola morte dell'oggetto).
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_finale_battaglia.gd -- <cartella> <nemico>   (aggiungere --fixed-fps 30 prima di -s)

var out: String = "/tmp/v3finale_b"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	var id: String = a[1] if a.size() > 1 else "cassaforte"
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	Story.set_flag("lezioni_fatte")
	_run(id)


func _run(id: String) -> void:
	await process_frame
	var bt: Node = load("res://scripts/v3/battle3d.gd").new()
	bt.configure({"boss": id, "visual": id, "livello": 3, "arena": "strada", "ingresso": "normale",
		"ritorno": {"tipo": "storia", "area": "incrocio", "perso": {}}, "debolezze": []})
	root.add_child(bt)
	var t0: int = Time.get_ticks_msec()
	while not bool(bt.get("waiting")) and Time.get_ticks_msec() - t0 < 20000:
		await process_frame
	var b: Dictionary = bt.get("b")
	(b["units"][BattleState.BOSS_ID] as Dictionary)["hp"] = 1
	bt.call("_command", "attack")
	var f: int = 0
	while f < 180:            # con --fixed-fps 30: sei secondi di gioco
		await process_frame
		root.get_viewport().get_texture().get_image().save_png(out.path_join("f%03d.png" % f))
		f += 1
	print("FINALE_BATTAGLIA ", id, " fotogrammi ", f, " finito ", bt.get("ended"))
	quit(0)
