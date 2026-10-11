extends SceneTree

# Simulazione di bilanciamento: tutte le squadre sono guidate dall'IA.
# Uso: godot --headless --path . -s res://tools/battle_sim.gd [-- partite]

const TEAMS: Array = [
	["kira", "dax", "elle"],
	["nova", "bruno", "mira"],
	["dax", "kira", "mira"],
]


func _entries(ids: Array, level: int) -> Array:
	var out: Array = []
	for id in ids:
		out.append(BattleContent.default_entry(str(id), level, 0))
	return out


func _run(players: int, level: int, n: int, label: String, locked_active: bool = false) -> void:
	var wins: int = 0
	var rounds: int = 0
	var survivors: int = 0
	for g in n:
		var specs: Array = []
		for i in players:
			specs.append({"id": "p%d" % (i + 1), "name": "P%d" % (i + 1), "ai": true, "team": _entries(TEAMS[i % TEAMS.size()], level)})
		var state: Dictionary = BattleState.create(specs, "distributore", 1000 + g)
		var guard: int = 0
		while str(state["winner"]) == "" and guard < 80:
			BattleResolver.resolve_round(state, true)
			guard += 1
		if str(state["winner"]) == "players":
			wins += 1
		rounds += int(state["round"])
		for u in state["units"].values():
			if str(u["side"]) == "player" and int(u["hp"]) > 0:
				survivors += 1
	print("%-28s vittorie %3d%%  round medi %4.1f  PG vivi %4.1f/%d" % [label, 100 * wins / n, float(rounds) / n, float(survivors) / n, players * 3])


func _init() -> void:
	var n: int = 200
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		n = int(args[0])
	for lv in [1, 3, 5]:
		for pc in [1, 2, 3]:
			_run(pc, lv, n, "%d giocatori, livello %d" % [pc, lv])
	quit(0)
