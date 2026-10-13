class_name PvpRewards
extends RefCounted

# Borsa fight: premio di fine duello PvP. Deterministico (stesso seme e posto = stessa borsa), quindi l'host
# spedisce a ognuno la sua e nessuno puo' gonfiarla. Chi vince prende molto di piu'; il pareggio sta in mezzo.
# Stesso formato dei premi dei boss: {coins, materials: {nucleo, lega}, drops: [...]}.

const WIN_COINS: Array = [450, 700]
const DRAW_COINS: Array = [220, 320]
const LOSS_COINS: Array = [140, 220]
const TRAINING_SHARE: float = 0.25        # contro l'IA (allenamento) si prende solo una parte, senza drop


static func for_player(seed_value: int, seat: int, outcome: String, training: bool = false) -> Dictionary:
	var rng := RNGState.new()
	rng.setup(seed_value * 17 + seat * 5 + 3)
	var range_: Array = WIN_COINS if outcome == "win" else (DRAW_COINS if outcome == "draw" else LOSS_COINS)
	var coins: int = rng.random_int(int(range_[0]), int(range_[1]))
	var materials: Dictionary = {}
	var nucleo: int = rng.random_int(2, 4) if outcome == "win" else (rng.random_int(1, 2) if outcome == "draw" else rng.random_int(0, 1))
	var lega: int = rng.random_int(1, 3) if outcome == "win" else rng.random_int(0, 1)
	if training:
		return {"coins": int(round(float(coins) * TRAINING_SHARE)), "materials": {}, "drops": []}
	if nucleo > 0:
		materials["nucleo"] = nucleo
	if lega > 0:
		materials["lega"] = lega
	var drops: Array = []
	var gear_chance: int = 35 if outcome == "win" else 10
	if rng.random_int(1, 100) <= gear_chance:
		drops.append(BattleContent.roll_gear(rng, 0))
	if outcome == "win":
		drops.append_array(BattleContent.roll_drops("distributore", rng, 0).slice(0, 1))
		var icon_id: String = Profile.roll_icon(rng, 0)
		if icon_id != "":
			drops.append({"kind": "icon", "id": icon_id})
	return {"coins": coins, "materials": materials, "drops": drops}


# Premi di tutti gli umani di un duello finito, per id giocatore. Le IA non prendono nulla.
static func for_battle(state: Dictionary, seed_value: int) -> Dictionary:
	var result: Dictionary = {}
	var winner: String = str(state.get("winner", ""))
	if winner == "":
		return result
	var seat: int = 0
	for p in state["players"]:
		var pid: String = str(p["id"])
		if not pid.begins_with("ia_"):
			var outcome: String = "draw" if winner == "draw" else ("win" if str(p["team"]) == winner else "loss")
			result[pid] = for_player(seed_value, seat, outcome)
		seat += 1
	return result


static func text(rewards: Dictionary) -> String:
	var parts: Array = []
	if int(rewards.get("coins", 0)) > 0:
		parts.append("%d MONETE" % int(rewards["coins"]))
	var mats: Dictionary = rewards.get("materials", {})
	if int(mats.get("nucleo", 0)) > 0:
		parts.append("%d NUCLEI" % int(mats["nucleo"]))
	if int(mats.get("lega", 0)) > 0:
		parts.append("%d LEGHE" % int(mats["lega"]))
	for d in rewards.get("drops", []):
		match str(d.get("kind", "")):
			"gear":
				parts.append("EQUIP. %s" % str(d.get("slot", "")).to_upper())
			"move":
				parts.append("ABILITA': %s" % BattleText.move_name(str(d.get("id", ""))))
			"passive":
				parts.append("PASSIVA")
			"icon":
				parts.append("ICONA: %s" % Profile.icon_name(str(d.get("id", ""))))
	return "  ·  ".join(parts)
