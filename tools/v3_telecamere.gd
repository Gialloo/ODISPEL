extends SceneTree

# Schermate delle telecamere che si incrinano (PIANO fase 2): chi e' di turno al 40% e al 20% dei PV, il K.O. di un compagno
# (la sua telecamera va in frantumi e perde il segnale), la cura che la ricalibra, il cambio di telecamera tra i turni, e le sei
# idee per una battaglia piu' spettacolare: ingresso del nemico, colpo finale, zoom sul punto debole, parata perfetta, Rio in diretta,
# lunga esposizione.
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/v3_telecamere.gd -- <cartella> [touch|pc] [arena]
# arena: per esempio anomalia_rossa, per provare tutto dentro un'Anomalia come contro i boss (3/11/2026)

var out: String = "/tmp/v3telecamere"
var arena: String = "tangenziale"


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1 and a[1] == "touch":
		TouchUi.force = true
	if a.size() > 2:
		arena = a[2]
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
	bt.configure({"boss": "autovelox", "livello": 11, "arena": arena})
	root.add_child(bt)
	# 0: ingresso del nemico (prima dei turni)
	await create_timer(1.2).timeout
	await _shot("0_ingresso_nemico", 1)
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
	# 6: cambio di telecamera verso un compagno (il taglio a meta')
	var nx: String = str(BattleState.player(b, str(slots[0]))["active"])
	bt.set("_last_turn_uid", uid)
	bt.set("cur_pid", str(slots[0]))
	bt.call("_cam_actor", nx)
	bt.call("_cam_switch", nx)
	bt.call("_fx_turn", nx)
	bt.call("_cam_choose", nx)
	bt.call("_refresh_hud")
	bt.call("_update_broken_cam")
	await _shot("6_cambio_telecamera", 2)
	await _shot("6b_cartellino_cam", 8)
	await create_timer(1.0).timeout
	await _shot("7_dopo_il_taglio")
	# 8: colpo finale (rallentatore e fermo immagine)
	bt.set("_last_act", {"unit": nx, "move": "attack"})
	bt.call("_finisher", 0.0)
	await create_timer(0.7, true, false, true).timeout
	await _shot("8_colpo_finale_stop", 2)
	while bool(bt.get("_finishing")):
		await process_frame
	# 9: debolezza colpita: zoom digitale x2
	await create_timer(1.0).timeout
	bt.set("_dzoom_t", 0.75)
	(bt.get("_cam_hud") as Node).call("disturb", "ZOOM x2  ·  PUNTO DEBOLE", Ui.YELLOW, 0.9)
	await _shot("9_debolezza_zoom", 2)
	await create_timer(1.0).timeout
	# 10: parata perfetta
	bt.set("_dzoom_t", 0.0)
	bt.call("_parry_shot", str(slots[2]))
	await _shot("10_parata_perfetta", 3)
	await create_timer(1.0).timeout
	# 11: Rio in diretta (Hype alto): i commenti della chat sul bordo destro
	bt.call("_cam_choose", nx)
	(bt.get("_cam_hud") as Node).call("set_live", 40)
	await create_timer(4.5).timeout
	await _shot("11_rio_in_diretta")
	(bt.get("_cam_hud") as Node).call("set_live", 0)
	# 12: lunga esposizione: la pennellata dell'abilita' resta impressa
	var cv: Node = (bt.get("vis") as Dictionary)[nx]
	var bv: Node = (bt.get("vis") as Dictionary)[BattleState.BOSS_ID]
	var stk: LightFx = LightFx.stroke(bt, cv.call("chest_point"), bv.call("chest_point"), Color("#e8343f"), 0.42)
	stk.expose(0.5)
	await create_timer(0.2).timeout
	await _shot("12a_pennellata", 1)
	await create_timer(0.42).timeout
	await _shot("12_lunga_esposizione", 1)
	print("OK telecamere")
	quit(0)
