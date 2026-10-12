extends SceneTree

# Immagini dei boss e della scelta missione (serve un display, anche virtuale):
#   godot --path . --resolution 1280x720 -s res://tools/mission_shot.gd -- cartella_uscita

var _out: String = "user://"


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_run()


func _shot(name: String) -> void:
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
	print("salvata ", name)


func _run() -> void:
	var r: Dictionary = RosterState.new_roster()
	RosterState.mark_cleared(r, "distributore", 0)
	var m: Control = load("res://scenes/missions/mission_screen.tscn").instantiate()
	m.roster = r
	root.add_child(m)
	await _shot("missione")
	m.queue_free()
	for id in BattleContent.BOSS_ORDER:
		MissionConfig.set_mission(id, 1)
		var b: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
		root.add_child(b)
		await _shot("boss_" + id)
		# un paio di round per vedere telegrafi diversi
		for i in 2:
			var c: Dictionary = BattleAI.choose(b.source.battle, "p1")
			b.pending_swap = str(c["swap"])
			b._on_order_pressed(str(c["move"]))
			while b.animating:
				await create_timer(0.1).timeout
		await _shot("boss_%s_r3" % id)
		b.queue_free()
		await process_frame
	quit(0)
