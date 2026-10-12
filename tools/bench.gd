extends SceneTree

# Misura quanto costa ogni schermata (millisecondi per frame, media su molti frame).
# Serve un display, anche virtuale:
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/bench.gd

const FRAMES: int = 240
const WARMUP: int = 30


func _initialize() -> void:
	_run()


func _measure(label: String, scene: Control) -> void:
	root.add_child(scene)
	for i in WARMUP:
		await process_frame
	var t0: int = Time.get_ticks_usec()
	for i in FRAMES:
		await process_frame
	var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0 / float(FRAMES)
	print("%-24s %6.2f ms/frame   chiamate di disegno %4d   primitive %6d   nodi %d" % [
		label, ms,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	scene.queue_free()
	await process_frame


func _run() -> void:
	await process_frame
	Engine.max_fps = 0
	Settings.path = "user://bench_settings.cfg"
	Settings.tutorial_done = true
	for id in BattleContent.BOSS_ORDER:
		MissionConfig.set_mission(id, 0)
		await _measure("battaglia " + id, load("res://scenes/battle/battle_screen.tscn").instantiate())
	var hub: Control = load("res://scenes/hub/hub_demo.tscn").instantiate()
	hub.roster = RosterState.new_roster()
	await _measure("hub", hub)
	var ms: Control = load("res://scenes/missions/mission_screen.tscn").instantiate()
	ms.roster = RosterState.new_roster()
	await _measure("missioni", ms)
	var ro: Control = load("res://scenes/roster/roster_screen.tscn").instantiate()
	ro.roster = RosterState.new_roster()
	await _measure("squadra", ro)
	await _measure("lobby", load("res://scenes/lobby/lobby_demo.tscn").instantiate())
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://bench_settings.cfg"))
	quit()
