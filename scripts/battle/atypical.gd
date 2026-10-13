class_name Atypical
extends RefCounted

# TRATTO ATIPICO: chi sceglie lo stile atipico ha sempre il bonus di fazione base (+8% ATK, +5% VEL, aura dimezzata),
# ma ogni operatore ha in piu' un modo SUO di giocare che dipende dalla rarita':
#   comune      -> niente di piu' (solo il bonus base)
#   raro        -> una piccola aggiunta (statistiche o una partenza migliore)
#   epico       -> un tratto proprio, evidente ma contenuto
#   leggendario -> un tratto unico, che cambia il modo di giocare quell'operatore
# Gli effetti "fx" vivono in u["atyp"] (interi, per mille dove serve) e sono letti dal motore; "mods" sono bonus
# statistici (per mille) sommati nel refresh delle aure; "energy" e "gauge" sono la partenza.

const TIER_NAMES: Array = ["COMUNE", "RARO", "EPICO", "LEGGENDARIO"]

# Valori degli effetti
const GAUGE_SHARE: int = 8             # Sera: ultimate dato all'alleato piu' scarico a fine round
const DEBUFF_DMG_PM: int = 150         # Eco: +15% di danno ai bersagli indeboliti
const REFLECT_PM: int = 400            # Tana: 40% del danno assorbito dallo scudo torna al boss
const EXECUTE_BELOW_PM: int = 300      # Dafne: critico sicuro sul boss sotto il 30% dei PV
const HEAT_PM: int = 30                # Angela: +3% di danno per ogni carica
const HEAT_MAX: int = 12

const TRAITS: Dictionary = {
	"kira": {"name": "Lama in ombra", "text": "+6% critico.", "mods": {"crit": 60}},
	"nova": {"name": "Occhio svelto", "text": "Parte con +1 energia.", "energy": 1},
	"mira": {"name": "Passo di corsia", "text": "+6% VEL e +6% DIF.", "mods": {"spd": 60, "def": 60}},
	"ivo": {"name": "Mano lesta", "text": "Parte con +15 di ultimate.", "gauge": 15},
	"sera": {"name": "Volo radente", "text": "A fine round l'alleato con meno ultimate ne riceve +%d." % GAUGE_SHARE, "fx": {"gauge_share": GAUGE_SHARE}},
	"eco": {"name": "Dissonanza viva", "text": "+15% di danno ai bersagli indeboliti (malus o marchi).", "fx": {"debuff_dmg": DEBUFF_DMG_PM}},
	"nico": {"name": "Rabbia lenta", "text": "Ogni volta che viene colpito e resta in piedi guadagna 1 slancio (come i colpi messi a segno).", "fx": {"rage_hit": 1}},
	"tana": {"name": "Baluardo che risponde", "text": "Il 40% del danno assorbito dal suo scudo torna al boss.", "fx": {"reflect_shield": REFLECT_PM}},
	"dafne": {"name": "Tiro di grazia", "text": "Colpo critico sicuro sul boss sotto il 30% dei PV; ogni critico le ridona 1 munizione.", "fx": {"execute_crit": EXECUTE_BELOW_PM, "crit_ammo": 1}},
	"angela": {"name": "Surriscaldamento", "text": "Ogni munizione spesa da' +3% di danno fino alla fine della battaglia (max 12 cariche).", "fx": {"heat": HEAT_PM}},
}


static func trait_of(char_id: String) -> Dictionary:
	return TRAITS.get(char_id, {})


static func has_trait(char_id: String) -> bool:
	return TRAITS.has(char_id)


static func trait_name(char_id: String) -> String:
	return str(trait_of(char_id).get("name", ""))


# Una riga per la scheda: "ATIPICO (RARO): Lama in ombra - +6% critico." Senza tratto: solo il bonus base.
static func describe(char_id: String) -> String:
	var rarity: int = clampi(int(BattleContent.CHARACTERS.get(char_id, {}).get("rarity", 0)), 0, TIER_NAMES.size() - 1)
	var t: Dictionary = trait_of(char_id)
	if t.is_empty():
		return "ATIPICO: nessun tratto proprio (solo il bonus base)."
	return "ATIPICO (%s): %s - %s" % [str(TIER_NAMES[rarity]), str(t["name"]), str(t["text"])]


# Alla creazione dell'unita': chi non e' atipico non ha niente.
static func setup(u: Dictionary) -> void:
	if str(u.get("style", "ortodosso")) != "atipico":
		return
	var t: Dictionary = trait_of(str(u.get("char", "")))
	if t.is_empty():
		return
	u["atyp"] = (t.get("fx", {}) as Dictionary).duplicate()
	if int(t.get("energy", 0)) > 0:
		u["energy"] = mini(BattleTypes.MAX_ENERGY, int(u["energy"]) + int(t["energy"]))
	if int(t.get("gauge", 0)) > 0:
		u["gauge"] = mini(BattleTypes.GAUGE_MAX, int(u["gauge"]) + int(t["gauge"]))


# Bonus statistici (per mille) dell'atipico, sommati nel refresh.
static func mods_for(u: Dictionary) -> Dictionary:
	if str(u.get("style", "ortodosso")) != "atipico":
		return {}
	return trait_of(str(u.get("char", ""))).get("mods", {})


static func fx(u: Dictionary, key: String) -> int:
	return int(u.get("atyp", {}).get(key, 0))


# Moltiplicatore di danno dei tratti atipici (Eco: bersagli indeboliti; Angela: cariche di calore).
static func damage_mult(attacker: Dictionary, defender: Dictionary) -> float:
	var m: float = 1.0
	var dd: int = fx(attacker, "debuff_dmg")
	if dd > 0 and _is_weakened(defender):
		m *= 1.0 + float(dd) / 1000.0
	var h: int = fx(attacker, "heat")
	if h > 0:
		m *= 1.0 + float(h) * float(mini(HEAT_MAX, int(attacker.get("heat", 0)))) / 1000.0
	return m


static func _is_weakened(defender: Dictionary) -> bool:
	if defender.get("statuses", {}).has("mark"):
		return true
	for m in defender.get("mods", []):
		if int(m["pm"]) < 0:
			return true
	return false


# Si spende una munizione: Angela accumula calore.
static func on_ammo_spent(u: Dictionary, n: int) -> void:
	if n > 0 and fx(u, "heat") > 0:
		u["heat"] = mini(HEAT_MAX, int(u.get("heat", 0)) + n)


# Dafne: contro il boss quasi finito il colpo e' sempre critico.
static func forces_crit(attacker: Dictionary, defender: Dictionary) -> bool:
	var below: int = fx(attacker, "execute_crit")
	return below > 0 and str(defender.get("side", "")) == "boss" and int(defender["hp"]) * 1000 < int(defender["max_hp"]) * below


# Fine round: Sera passa un po' di ultimate all'alleato piu' scarico della sua squadra.
static func end_of_round(state: Dictionary, events: Array) -> void:
	for p in state["players"]:
		for uid in p["team"]:
			var u: Dictionary = BattleState.unit(state, uid)
			var share: int = fx(u, "gauge_share")
			if share <= 0 or not BattleState.is_alive(u):
				continue
			var best: Dictionary = {}
			for other_id in p["team"]:
				var o: Dictionary = BattleState.unit(state, other_id)
				if str(other_id) == str(uid) or not BattleState.is_alive(o) or int(o["gauge"]) >= BattleTypes.GAUGE_MAX:
					continue
				if best.is_empty() or int(o["gauge"]) < int(best["gauge"]):
					best = o
			if not best.is_empty():
				best["gauge"] = mini(BattleTypes.GAUGE_MAX, int(best["gauge"]) + share)
				events.append({"t": "trait", "trait": "atipico", "unit": uid, "name": trait_name(str(u["char"]))})
