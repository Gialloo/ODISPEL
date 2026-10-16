extends SceneTree

# Prova del flusso: eventi forgiati (ult devastante che abbatte il boss) + qualche round vero con l'IA.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/impact_flow.gd

func _init() -> void:
	_run()


func _run() -> void:
	Settings.light_fx = false
	var s: Node = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(s)
	await create_timer(0.9).timeout
	for c in s.get_children():
		if c is TutorialOverlay:
			c.queue_free()
	var boss: Dictionary = BattleState.boss(s.shown)
	var mx: int = int(boss["max_hp"])
	var ally: String = ""
	for uid in s.shown["units"]:
		if str(uid) != BattleState.BOSS_ID:
			ally = str(uid)
			break
	var ev: Array = [
		{"t": "act", "unit": ally, "move": "x", "kind": "ult"},
		{"t": "damage", "src": ally, "dst": BattleState.BOSS_ID, "amount": int(mx * 0.5), "absorbed": 0, "crit": true},
		{"t": "down", "unit": BattleState.BOSS_ID}]
	var t0: int = Time.get_ticks_msec()
	await s._play_events(ev)
	print("FLOW forged: livello=%d count=%d ko_flag='%s' ms=%d" % [s._impact.last_played, s._impact.count, s._ko_impact_for, Time.get_ticks_msec() - t0])
	var tries: int = 0
	var rounds: int = 0
	while rounds < 6 and tries < 400:
		tries += 1
		if not s.animating and s.source != null and s.source.battle.get("winner", "") == "":
			var c: Dictionary = BattleAI.choose(s.source.battle, "p1")
			s.pending_swap = str(c["swap"])
			s._on_order_pressed(str(c["move"]))
			rounds += 1
		await create_timer(0.1).timeout
	print("FLOW rounds=%d count=%d" % [rounds, s._impact.count])
	quit()
