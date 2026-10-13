extends SceneTree

# Report di bilanciamento: tutte le squadre sono guidate dall'IA, livello/rank uguali per tutti.
# Uso: godot --headless --path . -s res://tools/balance_report.gd -- <modo> <partite> [livello] [rank]
#   modo: pvp1 (1v1 a gironi)  pvp3 (3v3 con squadre a caso)  pve (3 operatori a caso contro i boss)
# Scrive una riga per operatore: partite, vittorie, % e (PvE) round medi.

func _entries(ids: Array, level: int, rank: int) -> Array:
	var out: Array = []
	for id in ids:
		out.append(BattleContent.default_entry(str(id), level, rank))
	return out


func _ids() -> Array:
	var ids: Array = []
	for id in BattleContent.CHARACTERS:
		ids.append(str(id))
	ids.sort()
	return ids


func _spec(pid: String, team: Array, level: int, rank: int) -> Dictionary:
	return {"id": pid, "name": pid, "ai": true, "team": _entries(team, level, rank)}


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "pvp1"
	var n: int = int(args[1]) if args.size() > 1 else 50
	var level: int = int(args[2]) if args.size() > 2 else 20
	var rank: int = int(args[3]) if args.size() > 3 else 2
	var tier: int = int(args[4]) if args.size() > 4 else 1
	var fixed_boss: String = args[5] if args.size() > 5 else ""
	var ids: Array = _ids()
	var games: Dictionary = {}
	var wins: Dictionary = {}
	var rounds: Dictionary = {}
	for id in ids:
		games[id] = 0
		wins[id] = 0
		rounds[id] = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	if mode == "pvp1":
		for a in ids:
			for b in ids:
				if a == b:
					continue
				for k in n:
					var st: Dictionary = PvpEngine.simulate([_spec("a", [a], level, rank), _spec("b", [b], level, rank)], "duel", true, 100 + k)
					games[a] += 1
					games[b] += 1
					if str(st["winner"]) == "t1":
						wins[a] += 1
					elif str(st["winner"]) == "t2":
						wins[b] += 1
					rounds[a] += int(st["round"])
					rounds[b] += int(st["round"])
	elif mode == "pvp3":
		for k in n:
			var pool: Array = ids.duplicate()
			pool.erase("nico")
			var t1: Array = []
			var t2: Array = []
			for i in 3:
				t1.append(pool.pop_at(rng.randi() % pool.size()))
			for i in 3:
				t2.append(pool.pop_at(rng.randi() % pool.size()))
			var st: Dictionary = PvpEngine.simulate([_spec("a", t1, level, rank), _spec("b", t2, level, rank)], "duel", true, 7000 + k)
			for c in t1:
				games[c] += 1
				rounds[c] += int(st["round"])
			for c in t2:
				games[c] += 1
				rounds[c] += int(st["round"])
			print("G\t%s\t%d\t%d" % [",".join(t1), 1 if str(st["winner"]) == "t1" else (0 if str(st["winner"]) == "t2" else -1), int(st["round"])])
			print("G\t%s\t%d\t%d" % [",".join(t2), 1 if str(st["winner"]) == "t2" else (0 if str(st["winner"]) == "t1" else -1), int(st["round"])])
			if str(st["winner"]) == "t1":
				for c in t1:
					wins[c] += 1
			elif str(st["winner"]) == "t2":
				for c in t2:
					wins[c] += 1
	else:
		var bosses: Array = BattleContent.BOSS_ORDER
		for k in n:
			var pool: Array = ids.duplicate()
			pool.erase("nico")
			var team: Array = []
			for i in 3:
				team.append(pool.pop_at(rng.randi() % pool.size()))
			var boss_id: String = fixed_boss if fixed_boss != "" else str(bosses[k % bosses.size()])
			var state: Dictionary = BattleState.create([_spec("p1", team, level, rank)], boss_id, 900 + k, tier)
			var guard: int = 0
			while str(state["winner"]) == "" and guard < 120:
				BattleResolver.resolve_round(state, true)
				guard += 1
			var bu: Dictionary = state["units"].get("boss", {})
			var killed: float = 1.0 - clampf(float(bu.get("hp", 0)) / maxf(1.0, float(bu.get("max_hp", 1))), 0.0, 1.0)
			print("G\t%s\t%d\t%d\t%.3f" % [",".join(team), 1 if str(state["winner"]) == "players" else 0, int(state["round"]), killed])
			for c in team:
				games[c] += 1
				rounds[c] += int(state["round"])
				if str(state["winner"]) == "players":
					wins[c] += 1
	for id in ids:
		if int(games[id]) == 0:
			continue
		print("ROW\t%s\t%d\t%d\t%.1f\t%.1f" % [id, games[id], wins[id], 100.0 * float(wins[id]) / float(games[id]), float(rounds[id]) / float(games[id])])
	quit()
