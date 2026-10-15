extends SceneTree

# Tratti di luce dentro la schermata di battaglia vera: un colpo, uno scudo e una cura per personaggio.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/battle_lp_shot.gd -- <cartella>

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_run(args[0] if args.size() > 0 else "/tmp")


func _run(dir: String) -> void:
	var s: Node = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(s)
	await create_timer(0.9).timeout
	for c in s.get_children():
		if c is TutorialOverlay:
			c.queue_free()
	var ids: Array = []
	for p in s.shown["players"]:
		ids.append(str(BattleState.active_unit(s.shown, str(p["id"]))["id"]))
	Settings.light_fx = false
	LightPaint.max_live = 60
	if OS.get_cmdline_user_args().size() > 1:
		var mode: String = OS.get_cmdline_user_args()[1]
		var moves: Array = ["marchio_r", "frattura_r", "intimidisci_r"] if mode == "debuff" else []
		for i in moves.size():
			s._skill_light(BattleContent.MOVES[str(moves[i])], BattleState.unit(s.shown, ids[i]))
		if mode == "ult":
			var u: Dictionary = BattleState.unit(s.shown, ids[0])
			s._ult_signature(u, "strike", s._stage.anchor_of(ids[0]))
		await create_timer(0.55).timeout
		root.get_viewport().get_texture().get_image().save_png(dir.path_join("blp_%s.png" % mode))
		quit()
		return
	for id in ids:
		s._hit_anim({"src": id, "dst": BattleState.BOSS_ID}, BattleState.BOSS_ID, true, false, false)
	s._light_paint({"src": ids[0], "dst": ids[1]}, "ring")
	s._light_paint({"src": ids[2], "dst": ids[0]}, "spiral")
	var n: int = 0
	for c in s._fx.get_children():
		if c is LightPaint:
			n += 1
	print("TRATTI VIVI: ", n, " boss anchor ", s._stage.anchor_of(BattleState.BOSS_ID), " kira ", s._stage.anchor_of(ids[0]))
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png(dir.path_join("blp_a.png"))
	await create_timer(0.2).timeout
	root.get_viewport().get_texture().get_image().save_png(dir.path_join("blp_b.png"))
	quit()
