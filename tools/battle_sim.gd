extends SceneTree

# Simulazione di bilanciamento: tutte le squadre sono guidate dall'IA.
# Uso: godot --headless --path . -s res://tools/battle_sim.gd [-- partite [boss [tier]]]
#   senza boss/tier li prova tutti.

const TEAMS: Array = [
	["kira", "dax", "elle"],
	["nova", "bruno", "mira"],
	["dax", "kira", "mira"],
]
const LEVELS: Array = [1, 3, 6, 10, 15, 20]


func _entries(ids: Array, level: int) -> Array:
	var out: Array = []
	for id in ids:
		out.append(BattleContent.default_entry(str(id), level, 0))
	return out


func _run(boss_id: String, tier: int, players: int, level: int, n: int) -> String:
	var wins: int = 0
	var rounds: int = 0
	var survivors: int = 0
	for g in n:
		var specs: Array = []
		for i in players:
			specs.append({"id": "p%d" % (i + 1), "name": "P%d" % (i + 1), "ai": true, "team": _entries(TEAMS[i % TEAMS.size()], level)})
		var state: Dictionary = BattleState.create(specs, boss_id, 1000 + g, tier)
		var guard: int = 0
		while str(state["winner"]) == "" and guard < 120:
			BattleResolver.resolve_round(state, true)
			guard += 1
		if str(state["winner"]) == "players":
			wins += 1
		rounds += int(state["round"])
		for u in state["units"].values():
			if str(u["side"]) == "player" and int(u["hp"]) > 0:
				survivors += 1
	return "%3d%% (%4.1f r)" % [100 * wins / n, float(rounds) / n]


func _init() -> void:
	var n: int = 100
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		n = int(args[0])
	var bosses: Array = BattleContent.BOSS_ORDER
	if args.size() > 1:
		bosses = [args[1]]
	var tiers: Array = [0, 1, 2]
	if args.size() > 2:
		tiers = [int(args[2])]
	for boss_id in bosses:
		for tier in tiers:
			print("== %s / %s ==" % [boss_id, BattleContent.tier_of(tier)["name"]])
			for players in [1, 2, 3]:
				var line: String = "%d giocatori:" % players
				for lv in LEVELS:
					line += "  Lv%-2d %s" % [lv, _run(boss_id, tier, players, lv, n)]
				print(line)
	quit(0)
