extends SceneTree
# Immagine di prova: marchi, malus, torretta, drone, ronda e nascosto.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/marks_shot.gd -- cartella
func _init() -> void:
	_run()
func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var scene: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout
	if scene._tutorial != null:
		scene._tutorial.queue_free()
	var s: Dictionary = scene.shown
	var ids: Array = s["players"].map(func(p): return str(p["active"]))
	var boss: Dictionary = BattleState.boss(s)
	boss["marks"] = 3
	boss["statuses"]["mark"] = 99
	boss["mods"] = [{"id": "debuff_def", "stat": "def", "pm": -150, "turns": 2}, {"id": "debuff_spd", "stat": "spd", "pm": -150, "turns": 2}]
	var u0: Dictionary = BattleState.unit(s, ids[0])
	u0["statuses"]["ronda"] = 99
	var u1: Dictionary = BattleState.unit(s, ids[1])
	u1["statuses"]["hidden"] = 2
	u1["ammo"] = 2
	u1["ammo_max"] = 12
	s["summons"] = [{"id": "turret:" + ids[1], "owner": ids[1], "kind": "turret"}, {"id": "drone:" + ids[2], "owner": ids[2], "kind": "drone"}]
	scene._stage.set_state(s)
	scene._refresh_boss()
	scene._stage.mark_pulse = 1.0
	scene._stage.summon_pulse = 0.6
	await create_timer(1.6).timeout
	root.get_viewport().get_texture().get_image().save_png(out.path_join("marks.png"))
	quit()
