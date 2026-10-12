extends SceneTree

# Misura quanto costa simulare battaglie complete (solo logica, senza grafica).
# Uso: godot --headless --path . -s res://tools/bench_sim.gd -- [partite]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 300
	var rounds: int = 0
	var t0: int = Time.get_ticks_usec()
	for g in n:
		var specs: Array = []
		for pid in ["a", "b"]:
			var team: Array = []
			for c in ["kira", "dax", "elle"]:
				team.append(BattleContent.default_entry(c, 5, 0))
			specs.append({"id": pid, "name": pid, "ai": true, "team": team})
		var state: Dictionary = BattleState.create(specs, "distributore", g)
		var guard: int = 0
		while str(state["winner"]) == "" and guard < 120:
			BattleResolver.resolve_round(state, true)
			guard += 1
		rounds += int(state["round"])
	var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
	print("%d partite, %d round: %.1f ms (%.3f ms/round)" % [n, rounds, ms, ms / maxf(1.0, float(rounds))])
	quit()
