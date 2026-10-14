extends SceneTree

# Foto della schermata di fine battaglia (vittoria).
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/result_shot.gd -- <cartella> [touch 0/1] [spedizione 0/1] [replay 0/1]

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "/tmp"
	TouchUi.force = args.size() > 1 and args[1] == "1"
	if args.size() > 2 and args[2] == "1":
		MissionConfig.expedition = Expedition.new_run(21, "distributore", 0)
	_run(dir)


func _run(dir: String) -> void:
	Settings.tutorial_done = true
	var s: Node = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(s)
	await create_timer(0.9).timeout
	for c in s.get_children():
		if c is TutorialOverlay:
			c.queue_free()
	s.event_delay = 0.0
	var rew: Dictionary = {"coins": 450, "materials": {"nucleo": 3, "lega": 2}, "drops": [
		{"kind": "gear", "slot": "arma", "rarity": 3}, {"kind": "move", "id": "marchio", "rarity": 2},
		{"kind": "gear", "slot": "petto", "rarity": 1}, {"kind": "passive", "id": "p_hunter", "rarity": 1}]}
	s._show_result(true, rew)
	await create_timer(3.5).timeout
	if OS.get_cmdline_user_args().size() > 3 and OS.get_cmdline_user_args()[3] == "1":
		s._timeline = ["T1 · KIRA: COMBO TRACCIA + DETONAZIONE (-420)", "T2 · SCHIVATA: DAX SI SALVA DALLA CARICA", "T3 · ROTTURA! IL BOSS E' STORDITO"]
		s._open_replay()
		await create_timer(0.6).timeout
	root.get_viewport().get_texture().get_image().save_png(dir.path_join("res.png"))
	quit()
