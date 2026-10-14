extends SceneTree

# Foto dello schermo di battaglia (per rivedere la disposizione).
#   xvfb-run -a godot --path . --resolution 1600x720 -s res://tools/battle_shot.gd -- <cartella> [turni_da_giocare] [log 0/1]

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "/tmp"
	var rounds: int = int(args[1]) if args.size() > 1 else 0
	_run(dir, rounds)


func _run(dir: String, rounds: int) -> void:
	var s: Node = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(s)
	await create_timer(0.9).timeout
	for c in s.get_children():
		if c is TutorialOverlay:
			c.queue_free()
	for i in rounds:
		while s.animating:
			await create_timer(0.1).timeout
		var c2: Dictionary = BattleAI.choose(s.source.battle, "p1")
		s.pending_swap = str(c2["swap"])
		s._on_order_pressed(str(c2["move"]))
		await create_timer(0.1).timeout
	while s.animating:
		await create_timer(0.1).timeout
	await create_timer(0.6).timeout
	if args_log():
		s.toggle_log()
		await create_timer(0.6).timeout
	root.get_viewport().get_texture().get_image().save_png(dir.path_join("bs.png"))
	quit()


func args_log() -> bool:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	return a.size() > 2 and a[2] == "1"
