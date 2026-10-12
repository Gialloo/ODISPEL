extends SceneTree

# Quanti piani del Ciclo Infinito regge una squadra guidata dall'IA (con PV riportati).
# Uso: godot --headless --path . -s res://tools/endless_sim.gd [-- partite]

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 20
	for level in [6, 10, 15, 20, 30]:
		var total: int = 0
		var best: int = 0
		for g in n:
			var carry: Dictionary = {}
			var floor_n: int = 1
			while floor_n < 80:
				var team: Array = []
				for c in ["kira", "dax", "elle"]:
					team.append(BattleContent.default_entry(c, level, 0))
				var spare: Array = [BattleContent.default_entry("nova", level, 0), BattleContent.default_entry("bruno", level, 0)]
				var st: Dictionary = BattleState.create_solo("IO", team, spare, Endless.boss_for(floor_n), 500 + g * 100 + floor_n, 2, Endless.tier_for(floor_n))
				st["players"][0]["ai"] = true
				Endless.apply(st, floor_n)
				if floor_n > 1:
					Endless.apply_carry(st, carry)
				var guard: int = 0
				while str(st["winner"]) == "" and guard < 150:
					BattleResolver.resolve_round(st, true)
					guard += 1
				if str(st["winner"]) != "players":
					break
				carry = Endless.carry_from(st)
				floor_n += 1
			total += floor_n - 1
			best = maxi(best, floor_n - 1)
		print("livello %2d: piani medi %.1f, max %d" % [level, float(total) / float(n), best])
	quit()
