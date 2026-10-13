extends SceneTree
# Fotogrammi dello scatto d'attacco: xvfb-run godot --resolution 1280x720 -s res://tools/anim_shot.gd -- cartella
func _init() -> void:
	_run()
func _run() -> void:
	var dir: String = OS.get_cmdline_user_args()[0]
	Settings.tutorial_done = true
	var s: Node = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(s)
	await create_timer(0.8).timeout
	for c in s.get_children():
		if c is TutorialOverlay:
			c.queue_free()
	var st: BattleStage = s._stage
	var uid: String = str(BattleState.player(s.source.battle, "p1")["active"])
	st.acting = uid
	st._lunge_who = uid
	st._lunge_t = 0.0
	var i: int = 0
	for t in [0.09, 0.13, 0.12, 0.1, 0.25]:
		await create_timer(t).timeout
		root.get_viewport().get_texture().get_image().save_png(dir.path_join("lunge%d.png" % i))
		print("frame ", i, " t=", st._lunge_t)
		i += 1
	quit()
