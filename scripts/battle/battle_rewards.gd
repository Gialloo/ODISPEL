class_name BattleRewards
extends RefCounted

# Premi di fine battaglia. Sono deterministici: stesso boss, seed e giocatore
# danno sempre gli stessi premi, quindi l'host non deve mandare nulla in piu'.
#
# {coins: int, materials: {nucleo: int, lega: int}, drops: [{kind, ...}]}


static func for_player(boss_id: String, seed_value: int, player_index: int, victory: bool) -> Dictionary:
	var empty: Dictionary = {"coins": 0, "materials": {}, "drops": []}
	if not BattleContent.BOSSES.has(boss_id):
		return empty
	var cfg: Dictionary = BattleContent.BOSSES[boss_id].get("reward", {})
	if cfg.is_empty():
		return empty

	# Sconfitta: solo un piccolo premio di consolazione in monete.
	if not victory:
		return {"coins": int(cfg.get("coins", 0)) / 4, "materials": {}, "drops": []}

	var rng: RNGState = RNGState.new()
	rng.setup(seed_value * 31 + player_index + 7)

	var materials: Dictionary = {}
	for mat in BattleContent.MATERIALS:
		var range_: Array = cfg.get(mat, [0, 0])
		var amount: int = rng.random_int(int(range_[0]), int(range_[1]))
		if amount > 0:
			materials[mat] = amount

	var drops: Array = BattleContent.roll_drops(boss_id, rng)
	if rng.random_int(1, 100) <= int(cfg.get("gear_chance", 0)):
		drops.append(BattleContent.roll_gear(rng))

	return {"coins": int(cfg.get("coins", 0)), "materials": materials, "drops": drops}


# Premi di tutti i giocatori di una battaglia finita, per id giocatore.
static func for_battle(state: Dictionary, boss_id: String, seed_value: int) -> Dictionary:
	var result: Dictionary = {}
	if str(state.get("winner", "")) == "":
		return result
	var victory: bool = str(state["winner"]) == "players"
	var index: int = 0
	for p in state["players"]:
		result[str(p["id"])] = for_player(boss_id, seed_value, index, victory)
		index += 1
	return result
