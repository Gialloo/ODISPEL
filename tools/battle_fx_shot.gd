extends SceneTree

# Foto a meta' animazione di una battaglia, per vedere i tratti di luce.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/battle_fx_shot.gd -- <cartella> [secondi_dopo_ordine] [turni_prima]

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_run(args[0] if args.size() > 0 else "/tmp", float(args[1]) if args.size() > 1 else 0.35, int(args[2]) if args.size() > 2 else 0)


func _run(dir: String, when: float, before: int) -> void:
	var s: Node = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(s)
	await create_timer(0.9).timeout
	for c in s.get_children():
		if c is TutorialOverlay:
			c.queue_free()
	var tries: int = 0
	while not s.animating and tries < 8:
		var c: Dictionary = BattleAI.choose(s.source.battle, "p1")
		s.pending_swap = str(c["swap"])
		s._on_order_pressed(str(c["move"]))
		await create_timer(0.05).timeout
		tries += 1
	var shot: int = 0
	var t: float = 0.0
	while t < when * 16.0 and shot < 16:
		await create_timer(when).timeout
		t += when
		root.get_viewport().get_texture().get_image().save_png(dir.path_join("bfx_%d.png" % shot))
		shot += 1
	quit()
