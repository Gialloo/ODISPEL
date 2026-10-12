extends SceneTree

# Quanto costa a ogni frame il disegno dell'inquadratura di battaglia (microsecondi di
# script), con lo sfondo statico e con lo sfondo ridisegnato a ogni frame.
#   godot --headless --path . -s res://tools/bench_stage.gd

const FRAMES: int = 300


func _initialize() -> void:
	_run()


func _measure(boss: String, static_bg: bool) -> float:
	BattleStage.static_background = static_bg
	MissionConfig.set_mission(boss, 0)
	var scene: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(scene)
	for i in 20:
		await process_frame
	BattleStage.profile = true
	BattleStage.profile_usec = 0
	BattleStage.profile_frames = 0
	for i in FRAMES:
		await process_frame
	BattleStage.profile = false
	var per: float = float(BattleStage.profile_usec) / maxf(1.0, float(BattleStage.profile_frames))
	scene.queue_free()
	await process_frame
	return per


func _run() -> void:
	await process_frame
	Settings.path = "user://bench_settings.cfg"
	Settings.tutorial_done = true
	for boss in BattleContent.BOSS_ORDER:
		var old_us: float = await _measure(boss, false)
		var new_us: float = await _measure(boss, true)
		print("%-14s prima %7.1f us/frame   dopo %7.1f us/frame   (%.1fx piu' veloce)" % [boss, old_us, new_us, old_us / maxf(new_us, 0.1)])
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://bench_settings.cfg"))
	quit()
