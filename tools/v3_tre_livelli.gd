extends SceneTree

# Prova della GERARCHIA A TRE LIVELLI dell'HUD di battaglia (Review 01 del game director, 4/11/2026; regola in
# docs/STILE_VISIVO.md, «HUD a tre livelli»). Mette in scena il caso peggiore mentre si sceglie: Rio in diretta con la chat,
# una battuta a fumetto e un avviso, poi fotografa e controlla che il livello 3 non copra il livello 1.
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/v3_tre_livelli.gd -- <cartella> [touch|pc]
# Esce con codice 1 se qualcosa del livello 3 copre il livello 1 mentre si sceglie.

var out: String = "/tmp/v3livelli"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1 and a[1] == "touch":
		TouchUi.force = true
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
	bt.configure({"boss": "semaforo", "livello": 11, "arena": "tangenziale"})
	root.add_child(bt)
	var guard: int = 0
	while not bool(bt.get("waiting")) and guard < 900:
		guard += 1
		await process_frame
	await create_timer(1.0).timeout
	# caso peggiore: diretta di Rio accesa (chat), una battuta e un avviso proprio mentre si sceglie
	var ch: Node = bt.get("_cam_hud")
	if ch != null:
		ch.call("set_live", 60)
	bt.call("_quip_show", [{"chi": "rio", "testo": "Chat, guardate qua: questo semaforo non sa con chi ha a che fare!"}], 0.0)
	bt.call("_toast", "ROSSO FISSO · equilibrio x2", Ui.YELLOW, 4.0)
	await create_timer(2.2).timeout
	await _shot("1_scelta_caso_peggiore")
	var bad: Array = bt.call("livello3_sopra_livello1") if bt.has_method("livello3_sopra_livello1") else []
	print("SCELTA · livello 3 sopra il livello 1: ", bad)
	bt.call("_pick", "attack")
	await create_timer(0.6).timeout
	await _shot("2_attacco_scelto")
	# durante la mossa il livello 3 torna: la diretta riparte e la battuta rimasta in attesa esce
	bt.call("_command", "attack")
	await create_timer(1.2).timeout
	var ch2: Node = bt.get("_cam_hud")
	print("MOSSA · telecamera a riposo: ", ch2.get("quiet") if ch2 != null else "-")
	await _shot("3_durante_la_mossa")
	if bt.has_method("livello3_sopra_livello1"): bad.append_array(bt.call("livello3_sopra_livello1"))
	print("ESITO ", "OK" if bad.is_empty() else "COPERTO " + str(bad))
	quit(0 if bad.is_empty() else 1)
