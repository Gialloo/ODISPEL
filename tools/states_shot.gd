extends SceneTree

# Foto della battaglia con stati critici: vita bassa, KO, numeri lunghissimi, boss quasi infuriato e colpo letale annunciato.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/states_shot.gd -- <cartella> [touch 0/1]
func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	TouchUi.force = args.size() > 1 and args[1] == "1"
	_run(args[0] if args.size() > 0 else "/tmp")


func _run(dir: String) -> void:
	Settings.tutorial_done = true
	var s: Node = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(s)
	await create_timer(0.9).timeout
	for c in s.get_children():
		if c is TutorialOverlay:
			c.queue_free()
	var st: Dictionary = s.source.battle
	var boss: Dictionary = BattleState.boss(st)
	boss["hp"] = int(float(boss["max_hp"]) * 0.58)
	var p1: Dictionary = BattleState.active_unit(st, "p1")
	p1["hp"] = int(float(p1["max_hp"]) * 0.12)                 # vita bassa
	var second: Dictionary = BattleState.active_unit(st, "p1_f2")
	second["hp"] = 0                                           # KO
	var third: Dictionary = BattleState.active_unit(st, "p1_f3")
	third["max_hp"] = 987654
	third["hp"] = 987654                                       # numero lungo
	third["shield"] = 123456
	s.source.battle_updated.emit()
	await create_timer(1.0).timeout
	root.get_viewport().get_texture().get_image().save_png(dir.path_join("stati.png"))
	quit()
