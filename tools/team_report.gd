extends SceneTree

# Analisi delle squadre da 3: ogni riga e' una partita (squadra, esito, round). L'analisi si fa poi fuori dal gioco.
# Uso: godot --headless --path . -s res://tools/team_report.gd -- pve <boss> <livello> <rank> <tier> <ripetizioni>
#      godot --headless --path . -s res://tools/team_report.gd -- pvp <ripetizioni> [prima_squadra_da] [fino_a]
#      godot --headless --path . -s res://tools/team_report.gd -- probe <livello> <rank> <tier>
# pve: ogni terna (senza Nico) combatte <ripetizioni> volte il boss.  pvp: ogni terna affronta <ripetizioni> terne a caso (bilanciato).

func _entries(ids: Array, level: int, rank: int) -> Array:
	var out: Array = []
	for id in ids:
		out.append(BattleContent.default_entry(str(id), level, rank))
	return out


func _trios() -> Array:
	var ids: Array = []
	for id in BattleContent.CHARACTERS:
		if str(id) != "nico":
			ids.append(str(id))
	ids.sort()
	var out: Array = []
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			for k in range(j + 1, ids.size()):
				out.append([ids[i], ids[j], ids[k]])
	return out


func _pve(boss_id: String, team: Array, level: int, rank: int, tier: int, seed_value: int) -> Dictionary:
	var spec := {"id": "p1", "name": "p1", "ai": true, "team": _entries(team, level, rank)}
	var state: Dictionary = BattleState.create([spec], boss_id, seed_value, tier)
	var guard: int = 0
	while str(state["winner"]) == "" and guard < 120:
		BattleResolver.resolve_round(state, true)
		guard += 1
	var alive: int = 0
	for u in state["units"].values():
		if str(u["side"]) == "player" and int(u["hp"]) > 0:
			alive += 1
	return {"win": str(state["winner"]) == "players", "round": int(state["round"]), "alive": alive}


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "probe"
	var trios: Array = _trios()
	if mode == "probe":
		var level: int = int(args[1])
		var rank: int = int(args[2])
		var tier: int = int(args[3])
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for boss_id in BattleContent.BOSS_ORDER:
			var w: int = 0
			var n: int = 300
			var rsum: int = 0
			for k in n:
				var r: Dictionary = _pve(str(boss_id), trios[rng.randi() % trios.size()], level, rank, tier, 500 + k)
				if r["win"]:
					w += 1
				rsum += int(r["round"])
			print("BOSS\t%s\t%.1f\t%.1f" % [boss_id, 100.0 * w / n, float(rsum) / n])
	elif mode == "pve":
		var boss: String = args[1]
		var level2: int = int(args[2])
		var rank2: int = int(args[3])
		var tier2: int = int(args[4])
		var reps: int = int(args[5])
		for t in trios:
			var w2: int = 0
			var rs: int = 0
			var al: int = 0
			for k in reps:
				var r2: Dictionary = _pve(boss, t, level2, rank2, tier2, 3000 + k)
				if r2["win"]:
					w2 += 1
				rs += int(r2["round"])
				al += int(r2["alive"])
			print("T\t%s\t%d\t%d\t%.2f\t%.2f" % [",".join(t), reps, w2, float(rs) / reps, float(al) / reps])
	else:
		var reps2: int = int(args[1])
		var from_i: int = int(args[2]) if args.size() > 2 else 0
		var to_i: int = int(args[3]) if args.size() > 3 else trios.size()
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = 99 + from_i
		for ti in range(from_i, mini(to_i, trios.size())):
			var t1: Array = trios[ti]
			var w3: int = 0
			var d3: int = 0
			var rs3: int = 0
			for k in reps2:
				var t2: Array = trios[rng2.randi() % trios.size()]
				var overlap: bool = true
				while overlap:                     # l'avversario non ha operatori in comune con la squadra provata
					overlap = false
					for c in t2:
						if t1.has(c):
							overlap = true
					if overlap:
						t2 = trios[rng2.randi() % trios.size()]
				var spec1 := {"id": "a", "name": "a", "ai": true, "team": _entries(t1, 20, 2)}
				var spec2 := {"id": "b", "name": "b", "ai": true, "team": _entries(t2, 20, 2)}
				var swap: bool = (k % 2) == 1
				var st: Dictionary = PvpEngine.simulate([spec2, spec1] if swap else [spec1, spec2], "duel", true, 20000 + ti * 31 + k)
				var mine: String = "t2" if swap else "t1"
				if str(st["winner"]) == mine:
					w3 += 1
				elif str(st["winner"]) == "draw":
					d3 += 1
				rs3 += int(st["round"])
			print("T\t%s\t%d\t%d\t%d\t%.2f" % [",".join(t1), reps2, w3, d3, float(rs3) / reps2])
	quit()
