class_name Recruiting
extends RefCounted

# Reclutamento con le monete del gioco (niente denaro vero).
#
# - Un reclutamento costa SINGLE_COST monete; dieci costano TEN_COST (sconto 10%)
#   e garantiscono almeno un personaggio raro o migliore.
# - Garanzia: dopo PITY_LIMIT reclutamenti senza epici o leggendari, il successivo
#   e' almeno epico.
# - Un personaggio gia' posseduto e' una copia: si conserva e si spende col RANK UP
#   (il rank non sale mai da solo). A rank massimo viene convertito in monete.

const SINGLE_COST: int = 300
const TEN_COST: int = 2700
const PITY_LIMIT: int = 30
const REFUND_PER_RARITY: int = 100   # monete = (rarita' + 1) * questo

# BANNER: "standard" pesca da tutti gli operatori, ma i dieci nuovi hanno meta' delle probabilita' degli altri;
# "nuovi" pesca solo tra i dieci operatori del secondo roster (stesse quote di rarita', stesso costo, stessa garanzia).
const NEW_IDS: Array = ["moro", "vesper", "nami", "oriel", "silex", "yuna", "rhea", "flux", "cato", "lyra"]
const BANNERS: Array = ["standard", "nuovi"]
const NEW_WEIGHT_STANDARD: int = 1     # peso di un nuovo nel banner standard
const OLD_WEIGHT_STANDARD: int = 2     # peso di un operatore storico nel banner standard


static func cost_for(count: int) -> int:
	if count == 1:
		return SINGLE_COST
	if count == 10:
		return TEN_COST
	return -1


# Ritorna {ok, error, cost, results:[{char, rarity, outcome, refund}]}.
# outcome: "new" | "copy" | "max". Lo stesso seed e la stessa collezione
# danno gli stessi risultati; ogni reclutamento sposta il contatore "pulls".
static func pull(roster: Dictionary, count: int, seed_value: int, banner: String = "standard") -> Dictionary:
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
		var char_id: String = _pick(rarity, rng, banner)
		var actual: int = int(BattleContent.CHARACTERS[char_id]["rarity"])
		if actual >= 1:
			got_rare = true
		roster["pity"] = 0 if actual >= 2 else int(roster["pity"]) + 1

		var outcome: String = RosterState.add_character(roster, char_id)
		var refund: int = 0
		if outcome == "max":
			refund = (actual + 1) * REFUND_PER_RARITY
			roster["coins"] = int(roster["coins"]) + refund
		results.append({"char": char_id, "rarity": actual, "outcome": outcome, "refund": refund, "rank": int(roster["characters"][char_id]["rank"]), "copies": RosterState.copies(roster, char_id)})

	roster["pulls"] = int(roster["pulls"]) + count
	return {"ok": true, "error": "", "cost": cost, "results": results}


# Un personaggio a caso della rarita' chiesta (secondo il banner); se non ce ne sono, della piu' bassa disponibile.
static func _pick(rarity: int, rng: RNGState, banner: String = "standard") -> String:
	var r: int = rarity
	while r >= 0:
		var pool: Array = pool_for(r, banner)
		if not pool.is_empty():
			pool.sort()
			var total: int = 0
			for id in pool:
				total += weight_of(str(id), banner)
			var roll: int = rng.random_int(1, total)
			for id in pool:
				roll -= weight_of(str(id), banner)
				if roll <= 0:
					return str(id)
			return str(pool[pool.size() - 1])
		r -= 1
	return "kira"


# Gli operatori pescabili di una rarita' in un banner.
static func pool_for(rarity: int, banner: String = "standard") -> Array:
	var pool: Array = []
	for id in BattleContent.CHARACTERS:
		var def: Dictionary = BattleContent.CHARACTERS[id]
		if int(def["rarity"]) != rarity or bool(def.get("story_only", false)):
			continue
		if banner == "nuovi" and not NEW_IDS.has(str(id)):
			continue
		pool.append(id)
	return pool


static func weight_of(char_id: String, banner: String = "standard") -> int:
	if banner == "nuovi":
		return 1
	return NEW_WEIGHT_STANDARD if NEW_IDS.has(char_id) else OLD_WEIGHT_STANDARD
