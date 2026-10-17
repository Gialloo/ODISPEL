extends SceneTree

# Prova automatica della Battaglia V2: avvia la scena, tocca i comandi come farebbe un dito, gioca fino alla fine e salva gli screenshot.
#   xvfb-run -a godot --path . --resolution 1280x720 -s tools/battle_v2_shot.gd -- <cartella_output>

var out_dir: String = "/tmp"
var scn: BattleV2


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(out_dir.path_join("v2_%s.png" % name))


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out_dir = a[0]
	if a.size() > 1 and a[1] == "touch":
		TouchUi.force = true
	scn = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate() as BattleV2
	root.add_child(scn)
	await create_timer(1.2).timeout
	var fails: int = 0
	await _shot("1_libera")
	# tocco sul comando SKILL (come un dito): il rettangolo di tocco arriva dal disegno
	var skill_hit: Rect2 = scn.wheel_front.hits[1]
	print("TOCCO SKILL ", skill_hit)
	scn._tap(skill_hit.get_center())
	await create_timer(0.3).timeout
	if scn.picked != "SKILL" and bool(BattleV2._G.cmds[1]["ok"]):
		fails += 1
		print("FALLITO: SKILL non selezionata")
	await _shot("2_skill_scelta")
	scn._cancel()
	# gioca fino alla fine: per ogni slot ATTACK e conferma
	var rounds: int = 0
	while not scn.ended and rounds < 60:
		var guard: int = 0
		while scn.cur >= 0 and not scn.locked and guard < 10:
			guard += 1
			var pick: int = 0
			if bool(BattleV2._G.cmds[2]["ok"]):
				pick = 2
			elif bool(BattleV2._G.cmds[1]["ok"]):
				pick = 1
			scn._tap(scn.wheel_front.hits[pick].get_center())
			await create_timer(0.05).timeout
			if rounds == 0 and guard == 1:
				await _shot("3_scelta_primo_slot")
			scn._tap(BattleV2.CONFIRM_RECT.get_center())
			await create_timer(0.05).timeout
		rounds += 1
		if rounds == 1:
			await create_timer(0.3).timeout
			await _shot("4_dopo_round")
		await create_timer(1.1).timeout
	print("FINE ended=", scn.ended, " round=", scn._battle().get("round"), " winner=", scn._battle().get("winner"), " fails=", fails)
	await _shot("5_fine")
	quit(0 if (scn.ended and fails == 0) else 1)
