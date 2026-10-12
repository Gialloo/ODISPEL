class_name Recruiting
extends RefCounted

# Reclutamento con le monete del gioco (niente denaro vero).
#
# - Un reclutamento costa SINGLE_COST monete; dieci costano TEN_COST (sconto 10%)
#   e garantiscono almeno un personaggio raro o migliore.
# - Garanzia: dopo PITY_LIMIT reclutamenti senza epici o leggendari, il successivo
#   e' almeno epico.
# - Un personaggio gia' posseduto e' una copia: sale di rank. A rank massimo
#   viene convertito in monete.

const SINGLE_COST: int = 300
const TEN_COST: int = 2700
const PITY_LIMIT: int = 30
const REFUND_PER_RARITY: int = 100   # monete = (rarita' + 1) * questo


static func cost_for(count: int) -> int:
	if count == 1:
		return SINGLE_COST
	if count == 10:
		return TEN_COST
	return -1


# Ritorna {ok, error, cost, results:[{char, rarity, outcome, refund}]}.
# outcome: "new" | "rank" | "max". Lo stesso seed e la stessa collezione
# danno gli stessi risultati; ogni reclutamento sposta il contatore "pulls".
static func pull(roster: Dictionary, count: int, seed_value: int) -> Dictionary:
	var fail: Dictionary = {"ok": false, "error": "", "cost": 0, "results": []}
	var cost: int = cost_for(count)
	if cost < 0:
		fail["error"] = "quantita' non valida"
		return fail
	if int(roster["coins"]) < cost:
		fail["error"] = "monete"
		fail["cost"] = cost
		return fail

	roster["coins"] = int(roster["coins"]) - cost
	var rng: RNGState = RNGState.new()
	rng.setup(seed_value * 131 + int(roster["pulls"]) + 11)

	var results: Array = []
	var got_rare: bool = false
	for i in count:
		var rarity: int = BattleContent.roll_rarity(rng)
		if count == 10 and i == 9 and not got_rare:
			rarity = maxi(rarity, 1)
		if int(roster["pity"]) >= PITY_LIMIT - 1 and rarity < 2:
			rarity = 2
		var char_id: String = _pick(rarity, rng)
		var actual: int = int(BattleContent.CHARACTERS[char_id]["rarity"])
		if actual >= 1:
			got_rare = true
		roster["pity"] = 0 if actual >= 2 else int(roster["pity"]) + 1

		var outcome: String = RosterState.add_character(roster, char_id)
		var refund: int = 0
		if outcome == "max":
			refund = (actual + 1) * REFUND_PER_RARITY
			roster["coins"] = int(roster["coins"]) + refund
		results.append({"char": char_id, "rarity": actual, "outcome": outcome, "refund": refund, "rank": int(roster["characters"][char_id]["rank"])})

	roster["pulls"] = int(roster["pulls"]) + count
	return {"ok": true, "error": "", "cost": cost, "results": results}


# Un personaggio a caso della rarita' chiesta; se non ce ne sono, della piu' bassa disponibile.
static func _pick(rarity: int, rng: RNGState) -> String:
	var r: int = rarity
	while r >= 0:
		var pool: Array = []
		for id in BattleContent.CHARACTERS:
			if int(BattleContent.CHARACTERS[id]["rarity"]) == r:
				pool.append(id)
		if not pool.is_empty():
			pool.sort()
			return str(pool[rng.random_index(pool.size())])
		r -= 1
	return "kira"
