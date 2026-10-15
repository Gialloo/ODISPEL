extends SceneTree

# Squadre al massimo (livello 50, rank 5, pezzi leggendari al massimo) contro i boss, tutte guidate dall'IA.
# L'IA gioca peggio di una persona: la percentuale e' una stima PRUDENTE.
# Uso: godot --headless --path . -s res://tools/maxed_sim.gd -- [partite] [tier] [boss|tutti]

const TEAMS: Array = [
	["kira", "tana", "oriel", "flux", "dafne", "lyra"],
	["angela", "tana", "oriel", "kira", "flux", "lyra"],
	["flux", "kira", "tana", "oriel", "angela", "dafne"],
]


func maxed(id: String) -> Dictionary:
	var e: Dictionary = BattleContent.default_entry(id, RosterState.MAX_LEVEL, RosterState.MAX_RANK)
	var gear: Array = []
	for slot in BattleTypes.GEAR_SLOTS:
		gear.append({"slot": slot, "rarity": 3, "level": int(BattleContent.GEAR_MAX_LEVEL[3])})
	e["gear"] = gear
	return e


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 20
	var tier: int = int(args[1]) if args.size() > 1 else BattleContent.TIERS.size() - 1
	var bosses: Array = BattleContent.BOSS_ORDER
	if args.size() > 2 and args[2] != "tutti":
		bosses = [args[2]]
	var st0: Dictionary = BattleContent.compute_stats(maxed("kira"))
	print("Kira al massimo: PV %d ATK %d DEF %d" % [st0["hp"], st0["atk"], st0["def"]])
	var grand: int = 0
	var grand_n: int = 0
	for boss_id in bosses:
		var line: String = "%-12s %-9s" % [boss_id, str(BattleContent.tier_of(tier)["name"])]
		var tot_w: int = 0
		for ti in TEAMS.size():
			var ids: Array = TEAMS[ti]
			var wins: int = 0
			var rounds: int = 0
			for g in n:
				var team: Array = []
				var spare: Array = []
				for i in ids.size():
					(team if i < 3 else spare).append(maxed(str(ids[i])))
				var st: Dictionary = BattleState.create_solo("IO", team, spare, str(boss_id), 700 + g * 31 + ti, 2, tier)
				st["players"][0]["ai"] = true
				var guard: int = 0
				while str(st["winner"]) == "" and guard < 150:
					BattleResolver.resolve_round(st, true)
					guard += 1
				if str(st["winner"]) == "players":
					wins += 1
				rounds += int(st["round"])
			tot_w += wins
			line += "  sq%d %3d%% (%4.1f r)" % [ti + 1, 100 * wins / n, float(rounds) / n]
		grand += tot_w
		grand_n += n * TEAMS.size()
		print(line)
	print("MEDIA vittorie: %d%%" % (100 * grand / maxi(1, grand_n)))
	quit()
