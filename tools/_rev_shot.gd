extends SceneTree
func _init() -> void:
	_run()
func _run() -> void:
	await process_frame
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var res: Array = [{"char": "dafne", "rarity": 3, "outcome": "new", "copies": 0, "rank": 0}]
	PullReveal.play(host, res)
	await create_timer(2.5).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/reveal.png" % OS.get_cmdline_user_args()[0])
	quit()
