extends SceneTree

# Confronto A/B della battaglia: sfondo a comandi di disegno contro sfondo in texture.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/bench_ab.gd

const FRAMES: int = 200


func _initialize() -> void:
	_run()


func _ms(cache: bool, boss: String) -> float:
	BattleStage.cache_background = cache
	MissionConfig.set_mission(boss, 0)
	var s: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(s)
	for i in 30:
		await process_frame
	var t0: int = Time.get_ticks_usec()
	for i in FRAMES:
		await process_frame
	var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0 / float(FRAMES)
	s.queue_free()
	await process_frame
	return ms


func _run() -> void:
	await process_frame
	Engine.max_fps = 0
	Settings.path = "user://bench_settings.cfg"
	Settings.tutorial_done = true
	for boss in BattleContent.BOSS_ORDER:
		var a: float = await _ms(false, boss)
		var b: float = await _ms(true, boss)
		print("%-12s comandi %6.2f ms   texture %6.2f ms" % [boss, a, b])
	quit(0)
