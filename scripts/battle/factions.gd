class_name Factions
extends RefCounted

# Fazioni: aure passive, bonus temporanei e statistica critico.
# Tutto in numeri interi ("per mille": 50 = 5%) cosi' lo stato resta JSON senza perdite.
#
# - Ogni operatore vivo di una fazione da' a tutti i compagni VIVI della stessa fazione nella squadra
#   (se stesso compreso) un bonus alla statistica d'aura della fazione, che cresce con la sua rarita'.
#   La somma e' limitata da AURA_CAP_PM.
# - Stile atipico: aura data e ricevuta dimezzata, in cambio di +8% ATK e +5% VEL personali.
# - Stile atipico: aura data e ricevuta dimezzata, in cambio di +8% ATK e +5% VEL personali.
# - I Magabondi non danno aure: ricevono meta' dell'aura piu' forte presente nella squadra.
# - Una fazione puo' essere "spenta" per qualche turno (state["aura_off"][fazione]): niente aure date ne' ricevute.
# - Modifiche temporanee (mods): {id, stat, pm, turns}; stessa id = si rinnova, non si somma. Servono ai tratti
#   a evento (es. "colpito: +5% difesa") e ai debuff (pm negativo).
# - Le statistiche vere (atk, def, spd, crit) si ricalcolano da `base` con refresh(): chiamarlo dopo ogni
#   cambiamento di aure o mods.

const AURA_PM: Array = [10, 20, 35, 50]      # per rarita': comune, rara, epica, leggendaria
const AURA_CAP_PM: int = 250                 # massimo per una fazione sulla stessa statistica
const MULT_STATS: Array = ["atk", "def", "spd"]
const ADD_STATS: Array = ["crit"]            # probabilita' di colpo critico, in per mille
const CRIT_DMG_PM: int = 1500                # danno del colpo critico: x1.5
const MIN_MULT_PM: int = -900                # un debuff non porta mai una statistica sotto il 10%

# stat: statistica dell'aura ("" = non da' aure). La statistica delle Rondini e' provvisoria.
const FACTIONS: Dictionary = {
	"libracorp": {"name": "LibraCorp", "doctrine": "Protocollo", "stat": "def"},
	"rondini": {"name": "Rondini", "doctrine": "Ronda", "stat": "crit"},
	"magabondi": {"name": "Magabondi", "doctrine": "Improvvisazione", "stat": ""},
	"kairos": {"name": "Kairos", "doctrine": "Dissonanza", "stat": ""},
}
const ORDER: Array = ["libracorp", "rondini", "magabondi", "kairos"]
const STYLES: Array = ["ortodosso", "atipico"]
# Stile: l'ortodosso dà e riceve l'aura per intero; l'atipico ne dà e ne riceve la metà, ma guadagna bonus personali.
const ATYPICAL_AURA_PCT: int = 50
const ATYPICAL_SELF_PM: Dictionary = {"atk": 80, "spd": 50}
# RONDA: una Rondine con aura attiva porta la "carica" (stato ronda): +8% ATK e +8% VEL finche' ce l'ha,
# e il suo prossimo attacco (base, abilita' o ultimate) esce in forma POTENZIATA. Poi si ricarica dopo qualche round.
const RONDA_STAT_PM: int = 80
const RONDA_MULT: float = 1.3
const RONDA_UNIQUE_MULT: float = 1.15       # in piu' per le abilita' uniche e per l'ultimate
const RONDA_CRIT_PM: int = 250
const RONDA_RECHARGE: int = 2
const STAT_LABELS: Dictionary = {"atk": "ATK", "def": "DIF", "spd": "VEL", "crit": "CRIT"}


static func is_atypical(u: Dictionary) -> bool:
	return str(u.get("style", "ortodosso")) == "atipico"


static func capped(pm: int) -> int:
	return clampi(pm, -AURA_CAP_PM, AURA_CAP_PM)


static func name_of(faction: String) -> String:
	return str(FACTIONS.get(faction, {}).get("name", ""))


static func aura_stat(faction: String) -> String:
	return str(FACTIONS.get(faction, {}).get("stat", ""))


static func aura_value(rarity: int) -> int:
	return int(AURA_PM[clampi(rarity, 0, AURA_PM.size() - 1)])


static func is_suppressed(state: Dictionary, faction: String) -> bool:
	return int(state.get("aura_off", {}).get(faction, 0)) > 0


# Spegne le aure di una fazione per `turns` turni (Dissonanza).
static func suppress(state: Dictionary, faction: String, turns: int) -> void:
	if not state.has("aura_off"):
		state["aura_off"] = {}
	state["aura_off"][faction] = maxi(int(state["aura_off"].get(faction, 0)), turns)


# Aggiunge (o rinnova) una modifica temporanea. pm negativo = debuff.
static func add_mod(u: Dictionary, id: String, stat: String, pm: int, turns: int) -> void:
	var mods: Array = u["mods"]
	for m in mods:
		if str(m["id"]) == id:
			m["stat"] = stat
			m["pm"] = pm
			m["turns"] = maxi(int(m["turns"]), turns)
			return
	mods.append({"id": id, "stat": stat, "pm": pm, "turns": turns})


static func remove_mod(u: Dictionary, id: String) -> void:
	var mods: Array = u["mods"]
	for i in range(mods.size() - 1, -1, -1):
		if str(mods[i]["id"]) == id:
			mods.remove_at(i)


# Fine round: scadono mods e spegnimenti.
static func tick(state: Dictionary) -> void:
	for uid in state["units"]:
		var mods: Array = state["units"][uid].get("mods", [])
		for i in range(mods.size() - 1, -1, -1):
			mods[i]["turns"] = int(mods[i]["turns"]) - 1
			if int(mods[i]["turns"]) <= 0:
				mods.remove_at(i)
	var off: Dictionary = state.get("aura_off", {})
	for f in off.keys():
		off[f] = int(off[f]) - 1
		if int(off[f]) <= 0:
			off.erase(f)


# Aure di ogni unita' della squadra di un giocatore: {unit_id: {stat: pm}}.
static func auras_for_team(state: Dictionary, team: Array) -> Dictionary:
	# somma per fazione (solo unita' vive, fazione non spenta)
	var totals: Dictionary = {}
	for uid in team:
		var u: Dictionary = BattleState.unit(state, uid)
		var f: String = str(u.get("faction", ""))
		if f == "" or not BattleState.is_alive(u) or is_suppressed(state, f) or aura_stat(f) == "":
			continue
		var given: int = aura_value(int(u.get("rarity", 0)))
		if is_atypical(u):
			given = given * ATYPICAL_AURA_PCT / 100
		totals[f] = int(totals.get(f, 0)) + given
	for f in totals:
		totals[f] = capped(int(totals[f]))

	# i Magabondi prendono meta' dell'aura piu' forte presente
	var best_f: String = ""
	for f in ORDER:
		if totals.has(f) and (best_f == "" or int(totals[f]) > int(totals[best_f])):
			best_f = f

	var out: Dictionary = {}
	for uid in team:
		var u: Dictionary = BattleState.unit(state, uid)
		var f: String = str(u.get("faction", ""))
		var auras: Dictionary = {}
		if f != "" and not is_suppressed(state, f):
			if totals.has(f):
				var received: int = int(totals[f])
				# i Magabondi (atipici per natura) non dimezzano due volte
				if is_atypical(u) and f != "magabondi":
					received = received * ATYPICAL_AURA_PCT / 100
				auras[aura_stat(f)] = received
			elif f == "magabondi" and best_f != "":
				auras[aura_stat(best_f)] = int(totals[best_f]) / 2
		out[uid] = auras
	return out


static func ronda_ready(u: Dictionary) -> bool:
	return str(u.get("faction", "")) == "rondini" and u["statuses"].has("ronda") and not u.get("aura", {}).is_empty()


# Inizio round: chi ha l'aura e non e' carico scala la ricarica e, a zero, si carica. Chi perde l'aura perde la carica.
static func ronda_tick(state: Dictionary, events: Array) -> void:
	for p in state["players"]:
		for uid in p["team"]:
			var u: Dictionary = BattleState.unit(state, uid)
			if u.is_empty() or str(u.get("faction", "")) != "rondini" or not BattleState.is_alive(u):
				continue
			if u.get("aura", {}).is_empty():
				u["statuses"].erase("ronda")
				continue
			if u["statuses"].has("ronda"):
				continue
			var cd: int = int(u.get("ronda_cd", 0)) - 1
			u["ronda_cd"] = maxi(0, cd)
			if cd <= 0:
				u["statuses"]["ronda"] = 99
				events.append({"t": "ronda", "unit": uid, "on": 1})
	refresh(state)


# Ricalcola atk, def, spd e crit di tutte le unita' dei giocatori: base + aure + mods.
static func refresh(state: Dictionary) -> void:
	for p in state["players"]:
		var team: Array = p["team"]
		var auras: Dictionary = auras_for_team(state, team)
		for uid in team:
			var u: Dictionary = BattleState.unit(state, uid)
			if u.is_empty() or not u.has("base"):
				continue
			var aura: Dictionary = auras.get(uid, {})
			u["aura"] = aura
			var total: Dictionary = {}
			for s in aura:
				total[s] = int(total.get(s, 0)) + int(aura[s])
			if is_atypical(u):
				for st in ATYPICAL_SELF_PM:
					total[st] = int(total.get(st, 0)) + int(ATYPICAL_SELF_PM[st])
				var extra: Dictionary = Atypical.mods_for(u)
				for st in extra:
					total[st] = int(total.get(st, 0)) + int(extra[st])
			if u["statuses"].has("ronda") and not aura.is_empty():
				total["atk"] = int(total.get("atk", 0)) + RONDA_STAT_PM
				total["spd"] = int(total.get("spd", 0)) + RONDA_STAT_PM
			for m in Archetypes.mods_for(u):
				total[str(m["stat"])] = int(total.get(str(m["stat"]), 0)) + int(m["pm"])
			for m in u["mods"]:
				total[str(m["stat"])] = int(total.get(str(m["stat"]), 0)) + int(m["pm"])
			for s in MULT_STATS:
				var pm: int = maxi(MIN_MULT_PM, int(total.get(s, 0)))
				u[s] = int(round(float(u["base"][s]) * float(1000 + pm) / 1000.0))
			u["crit"] = clampi(int(u["base"]["crit"]) + int(total.get("crit", 0)), 0, 1000)


# Chi contribuisce all'aura di un'unita': [{name, pm}], solo operatori vivi della stessa fazione nella stessa squadra.
static func aura_sources(state: Dictionary, u: Dictionary) -> Array:
	var out: Array = []
	var f: String = str(u.get("faction", ""))
	if f == "" or aura_stat(f) == "" or is_suppressed(state, f):
		return out
	var p: Dictionary = BattleState.player(state, str(u.get("owner", "")))
	for uid in p.get("team", []):
		var v: Dictionary = BattleState.unit(state, uid)
		if str(v.get("faction", "")) != f or not BattleState.is_alive(v):
			continue
		var pm: int = aura_value(int(v.get("rarity", 0)))
		if is_atypical(v):
			pm = pm * ATYPICAL_AURA_PCT / 100
		out.append({"name": str(v["name"]), "pm": pm})
	return out


# Riepilogo leggibile delle aure di un'unita': "DIF +7%".
static func aura_text(u: Dictionary) -> String:
	var parts: Array = []
	var aura: Dictionary = u.get("aura", {})
	for s in aura:
		if int(aura[s]) != 0:
			parts.append("%s %+.1f%%" % [str(STAT_LABELS.get(s, s)), float(aura[s]) / 10.0])
	return ", ".join(parts)


# Tratti a evento. Protocollo (LibraCorp): chi viene colpito e resta in piedi prende +5% DIF e +5% VEL per il round dopo.
# add_mod rinnova invece di sommare, quindi vale al massimo una volta per turno.
const PROTOCOL_HIT_PM: int = 50


static func on_hit_taken(state: Dictionary, defender: Dictionary, events: Array = []) -> void:
	# tratto atipico di Nico: chi viene colpito guadagna slancio
	if Atypical.fx(defender, "rage_hit") > 0 and str(defender.get("side", "")) == "player":
		defender["momentum"] = mini(Archetypes.MOMENTUM_MAX, int(defender.get("momentum", 0)) + 1)
	if str(defender.get("faction", "")) != "libracorp" or str(defender.get("side", "")) != "player":
		return
	if is_suppressed(state, "libracorp") or str(defender.get("style", "ortodosso")) != "ortodosso":
		return
	add_mod(defender, "protocollo_def", "def", PROTOCOL_HIT_PM, 2)
	add_mod(defender, "protocollo_spd", "spd", PROTOCOL_HIT_PM, 2)
	events.append({"t": "trait", "unit": defender["id"], "trait": "protocollo"})
	refresh(state)


# Il colpo e' critico? Deterministico: dipende solo dal seme e da cio' che sta accadendo, cosi' host e client
# vedono lo stesso risultato e non si consuma il generatore dei tiri (chi non ha critico non cambia nulla).
static func rolls_crit(state: Dictionary, attacker: Dictionary, defender: Dictionary, salt: int, extra_pm: int = 0) -> bool:
	if Atypical.forces_crit(attacker, defender):
		return true
	var chance: int = int(attacker.get("crit", 0)) + Signatures.crit_bonus(state, attacker, defender) + extra_pm
	if chance <= 0:
		return false
	if chance >= 1000:
		return true
	var key: String = "%s|%s|%s|%s|%d" % [str(state["rng_seed"]), str(state["round"]), str(attacker["id"]), str(defender["id"]), salt]
	# String.hash() da' valori vicini a chiavi vicine: si rimescola per spargere bene i tiri.
	var h: int = int(key.hash()) & 0xFFFFFFFF
	h = ((h ^ (h >> 16)) * 0x45D9F3B) & 0xFFFFFFFF
	h = ((h ^ (h >> 16)) * 0x45D9F3B) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return int(h % 1000) < chance
