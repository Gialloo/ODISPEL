class_name BattleRewards
extends RefCounted

# Premi di fine battaglia. Sono deterministici: stesso boss, seed e giocatore
# danno sempre gli stessi premi, quindi l'host non deve mandare nulla in piu'.
#
# {coins: int, materials: {nucleo: int, lega: int}, drops: [{kind, ...}]}


static func for_player(boss_id: String, seed_value: int, player_index: int, victory: bool, tier: int = 0) -> Dictionary:
	var empty: Dictionary = {"coins": 0, "materials": {}, "drops": []}
	if not BattleContent.BOSSES.has(boss_id):
		return empty
	var cfg: Dictionary = BattleContent.BOSSES[boss_id].get("reward", {})
	if cfg.is_empty():
		return empty

	var t: Dictionary = BattleContent.tier_of(tier)
	var mult: float = float(t["reward"])

	# Sconfitta: solo un piccolo premio di consolazione in monete.
	if not victory:
		return {"coins": int(round(float(cfg.get("coins", 0)) * mult)) / 3, "materials": {}, "drops": []}

	var rng: RNGState = RNGState.new()
	rng.setup(seed_value * 31 + player_index + 7)

	var materials: Dictionary = {}
	for mat in BattleContent.MATERIALS:
		var range_: Array = cfg.get(mat, [0, 0])
		var amount: int = int(round(float(rng.random_int(int(range_[0]), int(range_[1]))) * mult))
		if amount > 0:
			materials[mat] = amount

	var drops: Array = BattleContent.roll_drops(boss_id, rng, tier)
	if rng.random_int(1, 100) <= int(cfg.get("gear_chance", 0)):
		drops.append(BattleContent.roll_gear(rng, tier))
	# icone del profilo (si estrae per ultima: non cambia gli altri premi)
	var icon_id: String = Profile.roll_icon(rng, tier)
	if icon_id != "":
		drops.append({"kind": "icon", "id": icon_id})

	return {"coins": int(round(float(cfg.get("coins", 0)) * mult)), "materials": materials, "drops": drops}


# Premi di tutti i giocatori di una battaglia finita, per id giocatore.
static func for_battle(state: Dictionary, boss_id: String, seed_value: int) -> Dictionary:
	var result: Dictionary = {}
	if str(state.get("winner", "")) == "":
		return result
	var victory: bool = str(state["winner"]) == "players"
	var index: int = 0
	for p in state["players"]:
		var r: Dictionary = for_player(boss_id, seed_value, index, victory, int(state.get("tier", 0)))
		if victory and Tactics.challenge_done(state):          # sfida facoltativa riuscita: premio extra
			r["coins"] = int(r["coins"]) + Tactics.CHALLENGE_COINS
			r["challenge"] = Tactics.CHALLENGE_COINS
		result[str(p["id"])] = r
		index += 1
	return result
