extends SceneTree

# Schermate delle telecamere che si incrinano (PIANO fase 2): chi e' di turno al 40% e al 20% dei PV, il K.O. di un compagno
# (la sua telecamera va in frantumi e perde il segnale) e la cura che la ricalibra.
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/v3_telecamere.gd -- <cartella> [touch|pc]

var out: String = "/tmp/v3telecamere"


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


func _shot(n: String, frames: int = 3) -> void:
	for i in frames:
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
	var b: Dictionary = bt.get("b")
	var uid: String = str(BattleState.player(b, str(bt.get("cur_pid")))["active"])
	var u: Dictionary = b["units"][uid]
	var mx: int = int(u["max_hp"])
	# 1-2: le crepe che restano sulla telecamera di chi e' di turno
	u["hp"] = int(mx * 0.4)
	bt.call("_refresh_hud")
	bt.call("_update_broken_cam")
	await create_timer(0.8).timeout
	await _shot("1_incrinata_40")
	u["hp"] = int(mx * 0.2)
	bt.call("_refresh_hud")
	bt.call("_update_broken_cam")
	await create_timer(0.8).timeout
	await _shot("2_rotta_20")
	# 3: K.O. di un compagno (non quello di turno): frantumi + SEGNALE PERSO
	var slots: Array = bt.get("slots")
	var other: Dictionary = bt.call("_slot_unit", 1 if slots.size() > 1 else 0)
	other["hp"] = 0
	bt.call("_refresh_hud")
	bt.call("_signal_lost_later", str(other["id"]) if other.has("id") else str(BattleState.player(b, str(slots[1]))["active"]), 0.0)
	await _shot("3_ko_frantumi", 1)
	await create_timer(0.7).timeout
	await _shot("4_ko_segnale_perso")
	# 5: la cura riporta chi e' di turno sopra il 50%: SEGNALE RECUPERATO, le crepe spariscono
	await create_timer(1.2).timeout
	var amt: int = int(mx * 0.45)
	u["hp"] = int(mx * 0.2) + amt
	bt.call("_signal_back", uid, amt, 0.0)
	bt.call("_refresh_hud")
	bt.call("_update_broken_cam")
	await create_timer(0.5).timeout
	await _shot("5_segnale_recuperato")
	print("OK telecamere")
	quit(0)
