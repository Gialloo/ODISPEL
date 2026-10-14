class_name Expedition
extends RefCounted

# SPEDIZIONE: una run roguelite in 6 tappe (da soli o in cooperativa), con conseguenze che restano.
#   PERCORSO -> COMBATTIMENTO -> EVENTO -> COMBATTIMENTO (con distorsione) -> BIVIO -> BOSS FINALE
# Dopo ogni combattimento si sceglie un potenziamento (1 su 3). I PV si portano dietro, le Provviste si spendono per riposare.
# Conseguenze: chi cade e perde la run resta FERITO (PV massimi -10% in ogni battaglia, finche' non passa il tempo o paghi la cura);
# chi completa la spedizione (o arriva al checkpoint) diventa VETERANO: bonus permanenti piccoli, fino al livello 5.
# Tutta la logica e' deterministica e vive in un dizionario "run" (serializzabile): in rete lo possiede l'host.

# Le due lunghezze. Ogni tappa: kind (path, event, event2, shelter, cross, fight) e, per i combattimenti, il ruolo.
const STAGES_SHORT: Array = [
	{"k": "path"}, {"k": "fight", "role": "combat1"}, {"k": "event"}, {"k": "fight", "role": "combat2"}, {"k": "cross"}, {"k": "fight", "role": "boss"},
]
const STAGES_LONG: Array = [
	{"k": "path"}, {"k": "fight", "role": "combat1"}, {"k": "event"}, {"k": "fight", "role": "combat2"}, {"k": "shelter"},
	{"k": "fight", "role": "guardian"}, {"k": "event2"}, {"k": "fight", "role": "combat3"}, {"k": "cross"}, {"k": "fight", "role": "boss"},
]
const NODE_LABELS: Dictionary = {"path": "PERCORSO", "event": "EVENTO", "event2": "RELIQUIA", "shelter": "RIFUGIO", "cross": "BIVIO",
	"combat1": "SCONTRO", "combat2": "SCONTRO", "combat3": "SCONTRO", "guardian": "GUARDIANO", "boss": "BOSS", "elite": "ELITE"}
const CHECKPOINT: int = 3                # tappa raggiunta (inizio) a partire dalla quale una sconfitta conta come checkpoint
const VET_MAX: int = 5
const VET_BONUS: float = 0.03            # per livello: PV e attacco
const WOUND_HP: float = 0.90
const WOUND_SECONDS: int = 6 * 3600
const HEAL_COST: int = 300
const UNLOCK_BOSSES: int = 2
const PACT_HP: float = 0.85
const REST_HEAL: float = 0.35
const COIN_PER_STAGE: int = 150
const COIN_WIN: int = 600
const COIN_WIN_LONG: int = 1400
const LONG_XP: int = 3
const CURSE_HP: float = 0.92

const PATHS: Array = [
	{"id": "infestata", "name": "ZONA INFESTATA", "tag": "RISCHIO", "desc": "Un'elite custodisce una reliquia: un potenziamento in piu', ma il nemico e' piu' duro."},
	{"id": "archivio", "name": "ARCHIVIO RITUALE", "tag": "INFORMAZIONI", "desc": "Scopri la debolezza del boss finale: partira' con meno equilibrio e il suo comportamento sara' noto."},
	{"id": "rifugio", "name": "RIFUGIO INSTABILE", "tag": "RECUPERO", "desc": "Niente bottino: la squadra recupera i PV e guadagna 1 Provvista."},
]
const EVENT_OPTIONS: Array = [
	{"id": "accetta", "name": "ACCETTA IL PATTO", "tag": "PREZZO", "desc": "Un'entita' offre 2 potenziamenti, ma un operatore resta indebolito (PV massimi -15%) per tutta la spedizione."},
	{"id": "rifiuta", "name": "RIFIUTA", "tag": "SICURO", "desc": "Nessun rischio: guadagni 1 Provvista."},
]
const EVENT2_OPTIONS: Array = [
	{"id": "accetta", "name": "PRENDI LA RELIQUIA", "tag": "PREZZO", "desc": "Un potenziamento in piu' subito, ma tutta la squadra perde l'8% dei PV massimi fino a fine spedizione."},
	{"id": "rifiuta", "name": "LASCIALA STARE", "tag": "SICURO", "desc": "Nessun rischio: guadagni 1 Provvista."},
]
const SHELTER_OPTIONS: Array = [
	{"id": "ripara", "name": "RIPARA E RIPOSA", "tag": "RECUPERO", "desc": "Recuperi il 40% dei PV massimi. Se hai una Provvista la spendi per recuperare il doppio."},
	{"id": "officina", "name": "OFFICINA RITUALE", "tag": "POTENZIAMENTO", "desc": "Scegli subito un potenziamento, ma non recuperi PV."},
]
# Modificatori volontari: piu' difficolta' = piu' premi.
const MODIFIERS: Array = [
	{"id": "poche_risorse", "name": "POCHE RISORSE", "desc": "Parti senza Provviste e senza Riserva di squadra.", "reward": 0.15},
	{"id": "boss_furioso", "name": "BOSS FURIOSO", "desc": "I nemici hanno +15% di attacco.", "reward": 0.2},
	{"id": "seconda_minaccia", "name": "SECONDA MINACCIA", "desc": "Il boss finale ha +20% di PV.", "reward": 0.2},
]
const CROSS_OPTIONS: Array = [
	{"id": "elite", "name": "ELITE FACOLTATIVA", "tag": "RISCHIO", "desc": "Un combattimento in piu' prima del boss: un potenziamento in piu' se vinci."},
	{"id": "esplora", "name": "ESPLORA", "tag": "INFORMAZIONI", "desc": "Un altro indizio sul boss: meno equilibrio e comportamento noto."},
	{"id": "riposo", "name": "RIPOSA", "tag": "RECUPERO", "desc": "Recuperi il 35% dei PV massimi. Se hai una Provvista, la spendi per recuperare il doppio."},
]


# ---------- Disponibilita' ----------

static func cleared_count(roster: Dictionary) -> int:
	return Endless.cleared_count(roster)


static func available(roster: Dictionary) -> bool:
	return cleared_count(roster) >= UNLOCK_BOSSES


# ---------- Creazione e avanzamento ----------

static func stages(run: Dictionary) -> Array:
	return STAGES_LONG if bool(run.get("long", false)) else STAGES_SHORT


static func new_run(seed_value: int, boss_id: String, tier: int, coop: bool = false, long: bool = false, mods: Array = []) -> Dictionary:
	var clean_mods: Array = []
	for m in mods:
		if not clean_mods.has(str(m)) and not modifier(str(m)).is_empty():
			clean_mods.append(str(m))
	return {
		"v": 2, "long": long, "mods": clean_mods, "elite_fight": false, "curse": 0.0, "id": absi(seed_value) + 1, "seed": absi(seed_value) + 1, "boss": boss_id,
		"tier": clampi(tier, 0, BattleContent.TIERS.size() - 1), "coop": coop,
		"stage": 0, "phase": "choose", "next": 0, "boon_left": 0,
		"boons": [], "carry": {}, "supplies": 0 if clean_mods.has("poche_risorse") else 1, "clue": 0, "elite": false, "heal": 0.0,
		"pact_unit": "", "fell": {}, "log": [], "votes": {}, "result": "", "wins": 0, "fights": 0,
	}


# Che cosa chiede la run adesso: path, event, event2, shelter, cross (decisioni), boon (potenziamento), fight (da combattere), done.
static func kind(run: Dictionary) -> String:
	match str(run.get("phase", "")):
		"done":
			return "done"
		"boon":
			return "boon"
		"battle":
			return "fight"
	var st: Array = stages(run)
	return str(st[clampi(int(run.get("stage", 0)), 0, st.size() - 1)]["k"])


# Ruolo del combattimento corrente: combat1/2/3, guardian, elite, boss.
static func role(run: Dictionary) -> String:
	if bool(run.get("elite_fight", false)):
		return "elite"
	var st: Array = stages(run)
	return str(st[clampi(int(run.get("stage", 0)), 0, st.size() - 1)].get("role", "boss"))


static func is_last(run: Dictionary) -> bool:
	return int(run.get("stage", 0)) >= stages(run).size() - 1


static func stage_title(run: Dictionary) -> String:
	var k: String = kind(run)
	match k:
		"path":
			return "SCEGLI IL PERCORSO"
		"event":
			return "EVENTO: IL PATTO"
		"event2":
			return "EVENTO: LA RELIQUIA MALEDETTA"
		"shelter":
			return "RIFUGIO A META' STRADA"
		"cross":
			return "BIVIO PRIMA DEL BOSS"
		"boon":
			return "SCEGLI UN POTENZIAMENTO"
		"fight":
			return {"combat1": "PRIMO SCONTRO", "combat2": "SECONDO SCONTRO", "combat3": "TERZO SCONTRO", "guardian": "IL GUARDIANO", "elite": "ELITE FACOLTATIVA", "boss": "BOSS FINALE"}[role(run)]
		"done":
			return "SPEDIZIONE COMPLETATA" if str(run.get("result", "")) == "win" else "SPEDIZIONE FALLITA"
	return ""


# Le tappe per la striscia della mappa: [{label, fight}]
static func map_nodes(run: Dictionary) -> Array:
	var out: Array = []
	for s in stages(run):
		out.append(str(NODE_LABELS[str(s.get("role", s["k"]))]))
	return out


static func modifier(id: String) -> Dictionary:
	for m in MODIFIERS:
		if str(m["id"]) == id:
			return m
	return {}


# Opzioni della decisione corrente: [{id, name, tag, desc}].
static func options(run: Dictionary) -> Array:
	match kind(run):
		"path":
			return PATHS
		"event":
			return EVENT_OPTIONS
		"event2":
			return EVENT2_OPTIONS
		"shelter":
			return SHELTER_OPTIONS
		"cross":
			return CROSS_OPTIONS
		"boon":
			var out: Array = []
			for bid in boon_offer(run):
				var d: Dictionary = Endless.BOONS[bid]
				out.append({"id": str(bid), "name": str(d["name"]), "tag": "POTENZIAMENTO", "desc": str(d["desc"])})
			return out
	return []


static func boon_offer(run: Dictionary) -> Array:
	return Endless.offer(int(run["seed"]) % 9973 + int(run["fights"]) * 31 + int(run["stage"]) * 5)


static func option_ids(run: Dictionary) -> Array:
	var out: Array = []
	for o in options(run):
		out.append(str(o["id"]))
	return out


static func _log(run: Dictionary, text: String) -> void:
	(run["log"] as Array).append(text)


# Passa alla tappa successiva (o al combattimento, se e' la prossima).
static func _go(run: Dictionary, stage: int) -> void:
	run["stage"] = stage
	var st: Array = stages(run)
	run["phase"] = "battle" if str(st[stage]["k"]) == "fight" else "choose"


# Applica la decisione (percorso, evento, rifugio, bivio, potenziamento). Ritorna "" se ok, altrimenti il motivo.
static func choose(run: Dictionary, option_id: String) -> String:
	var k: String = kind(run)
	if not option_ids(run).has(option_id):
		return "scelta non valida"
	run["votes"] = {}
	var here: int = int(run["stage"])
	match k:
		"path":
			match option_id:
				"infestata":
					run["elite"] = true
					_log(run, "Percorso: ZONA INFESTATA (elite e reliquia)")
				"archivio":
					run["clue"] = int(run["clue"]) + 1
					_log(run, "Percorso: ARCHIVIO RITUALE (indizio sul boss)")
				"rifugio":
					run["supplies"] = int(run["supplies"]) + 1
					run["heal"] = REST_HEAL
					_log(run, "Percorso: RIFUGIO INSTABILE (recupero)")
			_go(run, here + 1)
		"event":
			if option_id == "accetta":
				var ids: Array = pact_candidates(run)
				run["pact_unit"] = str(ids[int(run["seed"]) % ids.size()]) if not ids.is_empty() else ""
				for b in pact_boons(run):
					(run["boons"] as Array).append(b)
				_log(run, "Patto accettato: 2 potenziamenti, %s indebolito" % str(run["pact_unit"]).to_upper())
			else:
				run["supplies"] = int(run["supplies"]) + 1
				_log(run, "Patto rifiutato (+1 Provvista)")
			_go(run, here + 1)
		"event2":
			if option_id == "accetta":
				run["curse"] = float(run.get("curse", 0.0)) + 0.08
				(run["boons"] as Array).append(str(Endless.BOON_ORDER[(int(run["seed"]) / 3 + 5) % Endless.BOON_ORDER.size()]))
				_log(run, "Reliquia presa: +1 potenziamento, squadra -8% PV massimi")
			else:
				run["supplies"] = int(run["supplies"]) + 1
				_log(run, "Reliquia lasciata (+1 Provvista)")
			_go(run, here + 1)
		"shelter":
			if option_id == "ripara":
				var big: bool = int(run["supplies"]) > 0
				run["heal"] = REST_HEAL * (2.0 if big else 1.0) + 0.05
				if big:
					run["supplies"] = int(run["supplies"]) - 1
				_log(run, "Rifugio: riposo")
				_go(run, here + 1)
			else:
				_log(run, "Rifugio: officina rituale")
				run["boon_left"] = 1
				run["next"] = here + 1
				run["phase"] = "boon"
		"cross":
			match option_id:
				"elite":
					_log(run, "Bivio: ELITE FACOLTATIVA")
					run["elite_fight"] = true
					run["phase"] = "battle"
					return ""
				"esplora":
					run["clue"] = int(run["clue"]) + 1
					_log(run, "Bivio: ESPLORA (altro indizio)")
				"riposo":
					var big2: bool = int(run["supplies"]) > 0
					run["heal"] = REST_HEAL * (2.0 if big2 else 1.0)
					if big2:
						run["supplies"] = int(run["supplies"]) - 1
					_log(run, "Bivio: RIPOSO")
			_go(run, here + 1)
		"boon":
			(run["boons"] as Array).append(option_id)
			_log(run, "Potenziamento: %s" % str(Endless.BOONS[option_id]["name"]))
			run["boon_left"] = int(run["boon_left"]) - 1
			if int(run["boon_left"]) <= 0:
				_go(run, int(run["next"]))
	return ""


# Operatori che possono pagare il prezzo del patto: quelli visti finora (dal riporto PV) o, a inizio run, nessuno.
static func pact_candidates(run: Dictionary) -> Array:
	var out: Array = []
	for uid in run.get("carry", {}):
		var ch: String = str(uid).get_slice(":", 1) if ":" in str(uid) else str(uid)
		if not out.has(ch):
			out.append(ch)
	out.sort()
	return out


static func pact_boons(run: Dictionary) -> Array:
	var order: Array = Endless.BOON_ORDER
	return [str(order[int(run["seed"]) % order.size()]), str(order[(int(run["seed"]) / 7 + 3) % order.size()])]


# ---------- Voto (cooperativa) ----------

static func vote(run: Dictionary, player_id: String, option_id: String) -> bool:
	if not option_ids(run).has(option_id):
		return false
	run["votes"][player_id] = option_id
	return true


# Maggioranza dei voti; in pareggio vale il voto dell'host; senza voti la prima opzione. Non blocca mai la partita.
static func winner_of_votes(run: Dictionary, host_id: String) -> String:
	var ids: Array = option_ids(run)
	if ids.is_empty():
		return ""
	var tally: Dictionary = {}
	for pid in run.get("votes", {}):
		var o: String = str(run["votes"][pid])
		if ids.has(o):
			tally[o] = int(tally.get(o, 0)) + 1
	var best: int = 0
	for o in tally:
		best = maxi(best, int(tally[o]))
	var leaders: Array = []
	for o in ids:
		if int(tally.get(o, 0)) == best and best > 0:
			leaders.append(o)
	if leaders.size() == 1:
		return str(leaders[0])
	var host_vote: String = str(run.get("votes", {}).get(host_id, ""))
	if leaders.has(host_vote):
		return host_vote
	return str(leaders[0]) if not leaders.is_empty() else str(ids[0])


# ---------- Combattimenti ----------

static func _lesser_pool(run: Dictionary) -> Array:
	var pool: Array = []
	for id in BattleContent.BOSS_ORDER:
		if str(id) != str(run["boss"]):
			pool.append(str(id))
	if pool.is_empty():
		pool.append(str(run["boss"]))
	return pool


# Cosa si combatte adesso: {role, boss, tier, floor, mod, hp}
static func battle_params(run: Dictionary) -> Dictionary:
	var r: String = role(run)
	var pool: Array = _lesser_pool(run)
	var sd: int = int(run["seed"])
	var mods: Array = Endless.MODS
	var long: bool = bool(run.get("long", false))
	match r:
		"combat1":
			return {"role": r, "boss": pool[sd % pool.size()], "tier": 0, "floor": 4 if bool(run["elite"]) else 2, "mod": "", "hp": 0.6}
		"combat2":
			return {"role": r, "boss": pool[(sd / 3 + 1) % pool.size()], "tier": 0, "floor": 4, "mod": str(mods[sd % mods.size()]["id"]), "hp": 0.6}
		"combat3":
			return {"role": r, "boss": pool[(sd / 7 + 3) % pool.size()], "tier": mini(1, int(run["tier"])), "floor": 6, "mod": str(mods[(sd / 5) % mods.size()]["id"]), "hp": 0.7}
		"guardian":
			return {"role": r, "boss": pool[(sd / 11 + 1) % pool.size()], "tier": mini(1, int(run["tier"])), "floor": 1, "mod": str(mods[(sd / 13) % mods.size()]["id"]), "hp": 0.9}
		"elite":
			return {"role": r, "boss": pool[(sd / 5 + 2) % pool.size()], "tier": 0, "floor": 7 if long else 5, "mod": str(mods[(sd / 2) % mods.size()]["id"]), "hp": 0.8}
	return {"role": "boss", "boss": str(run["boss"]), "tier": int(run["tier"]), "floor": 1, "mod": "", "hp": 1.0}


static func mod_name(id: String) -> String:
	for m in Endless.MODS:
		if str(m["id"]) == id:
			return str(m["name"])
	return ""


# Prepara lo stato di battaglia (dopo BattleState.create): scala il nemico e porta dentro tutto cio' che la run ha accumulato.
static func apply_to_battle(run: Dictionary, state: Dictionary) -> void:
	var bp: Dictionary = battle_params(run)
	var mods: Array = run.get("mods", [])
	if int(bp["floor"]) > 1 or str(bp["mod"]) != "":
		Endless.apply(state, int(bp["floor"]), str(bp["mod"]))
		state.erase("endless")
	var boss: Dictionary = BattleState.boss(state)
	var hp_mult: float = float(bp["hp"])
	if str(bp["role"]) == "boss" and mods.has("seconda_minaccia"):
		hp_mult *= 1.2
	if hp_mult != 1.0:
		boss["max_hp"] = maxi(1, int(round(float(boss["max_hp"]) * hp_mult)))
		boss["hp"] = int(boss["max_hp"])
	if mods.has("boss_furioso"):
		boss["atk"] = int(round(float(boss["atk"]) * 1.15))
	if mods.has("poche_risorse"):
		state["reserve"] = 0
	Endless.apply_boons(state, run["boons"])
	if not (run["carry"] as Dictionary).is_empty():
		Endless.apply_carry(state, run["carry"])
	var heal: float = float(run.get("heal", 0.0))
	if heal > 0.0:
		for uid in state["units"]:
			var u: Dictionary = state["units"][uid]
			if str(u["side"]) == "player":
				u["hp"] = clampi(int(u["hp"]) + int(round(float(u["max_hp"]) * heal)), 1, int(u["max_hp"]))
		run["heal"] = 0.0
	var pu: String = str(run.get("pact_unit", ""))
	var curse: float = float(run.get("curse", 0.0))
	for uid in state["units"]:
		var u2: Dictionary = state["units"][uid]
		if str(u2["side"]) != "player":
			continue
		if pu != "" and str(u2.get("char", "")) == pu:
			u2["max_hp"] = int(round(float(u2["max_hp"]) * PACT_HP))
		if curse > 0.0:
			u2["max_hp"] = int(round(float(u2["max_hp"]) * (1.0 - curse)))
		u2["hp"] = mini(int(u2["hp"]), int(u2["max_hp"]))
	if str(bp["role"]) == "boss" and int(run["clue"]) > 0:
		boss["balance"] = maxi(2, int(boss.get("balance", 0)) - 2 * int(run["clue"]))
		var known: Dictionary = state.get("known", {})
		var kb: Array = known.get("behaviors", [])
		if not kb.has(str(run["boss"])):
			kb.append(str(run["boss"]))
		known["behaviors"] = kb
		state["known"] = known
	state["expedition"] = {"role": str(bp["role"]), "stage": int(run["stage"])}


# Registra l'esito di un combattimento. Ritorna le righe da mostrare.
static func after_battle(run: Dictionary, state: Dictionary) -> Array:
	var lines: Array = []
	if str(state.get("winner", "")) == "" or str(run.get("phase", "")) != "battle":
		return lines
	var won: bool = str(state["winner"]) == "players"
	run["fights"] = int(run["fights"]) + 1
	for uid in state["units"]:
		var u: Dictionary = state["units"][uid]
		if str(u["side"]) == "player" and (int(u["hp"]) <= 0 or bool(u.get("forbidden", false))):
			run["fell"][str(u.get("char", ""))] = true      # chi e' caduto o ha usato la tecnica proibita porta il segno
	if not won:
		run["phase"] = "done"
		run["result"] = "loss"
		lines.append("La squadra e' caduta.")
		return lines
	run["wins"] = int(run["wins"]) + 1
	run["carry"] = Endless.carry_from(state)
	var r: String = role(run)
	if r == "boss":
		run["phase"] = "done"
		run["result"] = "win"
		lines.append("SPEDIZIONE COMPLETATA")
		return lines
	var n: int = 1
	if (r == "combat1" and bool(run["elite"])) or r == "guardian":
		n = 2
		lines.append("Ricompensa speciale: scegli due potenziamenti.")
	run["boon_left"] = n
	run["next"] = int(run["stage"]) + 1
	run["elite_fight"] = false
	run["phase"] = "boon"
	return lines


# Una battaglia dà i premi normali (e conta come boss battuto) solo se non e' una tappa intermedia della spedizione.
static func pays_rewards(state: Dictionary) -> bool:
	return not state.has("expedition") or str(state["expedition"].get("role", "")) == "boss"


static func reward_mult(run: Dictionary) -> float:
	var m: float = 1.0
	for id in run.get("mods", []):
		m += float(modifier(str(id)).get("reward", 0.0))
	return m


# Premi della spedizione (crediti e materiali), proporzionali ai combattimenti vinti e ai modificatori scelti.
static func reward(run: Dictionary) -> Dictionary:
	var coins: int = COIN_PER_STAGE * int(run["wins"])
	var mats: Dictionary = {}
	var long: bool = bool(run.get("long", false))
	if str(run.get("result", "")) == "win":
		coins += COIN_WIN_LONG if long else COIN_WIN
		mats = {"nucleo": 5, "lega": 5} if long else {"nucleo": 3, "lega": 3}
	elif int(run["wins"]) >= (4 if long else 2):
		mats = {"nucleo": 1, "lega": 1}
	var m: float = reward_mult(run)
	coins = int(round(float(coins) * m))
	for k in mats:
		mats[k] = int(round(float(mats[k]) * m))
	return {"coins": coins, "materials": mats}


# Tappa raggiunta, per i record.
static func reached(run: Dictionary) -> int:
	return int(run["stage"]) + (1 if str(run.get("result", "")) == "win" else 0)


static func checkpoint_reached(run: Dictionary) -> bool:
	return str(run.get("result", "")) == "win" or int(run["wins"]) >= (4 if bool(run.get("long", false)) else 2)


# ---------- Conseguenze persistenti ----------

static func data(roster: Dictionary) -> Dictionary:
	if not roster.has("expedition") or not (roster["expedition"] is Dictionary):
		roster["expedition"] = {}
	var d: Dictionary = roster["expedition"]
	for k in ["xp", "wounds"]:
		if not d.has(k) or not (d[k] is Dictionary):
			d[k] = {}
	for k in ["runs", "wins", "best", "last_id"]:
		d[k] = int(d.get(k, 0))
	return d


static func vet_level(roster: Dictionary, char_id: String) -> int:
	return mini(VET_MAX, int(roster.get("expedition", {}).get("xp", {}).get(char_id, 0)) / 2)


static func is_wounded(roster: Dictionary, char_id: String, now: int = -1) -> bool:
	if now < 0:
		now = int(Time.get_unix_time_from_system())
	return int(roster.get("expedition", {}).get("wounds", {}).get(char_id, 0)) > now


static func wounded(roster: Dictionary, now: int = -1) -> Array:
	var out: Array = []
	for id in roster.get("expedition", {}).get("wounds", {}):
		if is_wounded(roster, str(id), now):
			out.append(str(id))
	out.sort()
	return out


static func heal(roster: Dictionary, char_id: String, now: int = -1) -> String:
	if not is_wounded(roster, char_id, now):
		return "non e' ferito"
	if int(roster.get("coins", 0)) < HEAL_COST:
		return "servono %d crediti" % HEAL_COST
	roster["coins"] = int(roster["coins"]) - HEAL_COST
	data(roster)["wounds"].erase(char_id)
	return ""


# Consegna al motore i bonus/penalita' di un operatore (cosi' valgono in ogni battaglia, anche online).
static func decorate_entry(roster: Dictionary, entry: Dictionary, now: int = -1) -> void:
	var id: String = str(entry.get("char", ""))
	var v: int = vet_level(roster, id)
	if v > 0:
		entry["vet"] = v
	if is_wounded(roster, id, now):
		entry["wound"] = true


# Moltiplicatori per le statistiche (PV, attacco) di una scheda.
static func stat_mult(entry: Dictionary) -> Dictionary:
	var v: int = clampi(int(entry.get("vet", 0)), 0, VET_MAX)
	var f: float = 1.0 + VET_BONUS * float(v)
	var hp: float = f * (WOUND_HP if bool(entry.get("wound", false)) else 1.0)
	return {"hp": hp, "atk": f}


# A fine spedizione: premi, veterani, ferite, record. Idempotente per spedizione. Ritorna le righe da mostrare.
static func finish(roster: Dictionary, run: Dictionary, now: int = -1) -> Array:
	var lines: Array = []
	if str(run.get("phase", "")) != "done":
		return lines
	var d: Dictionary = data(roster)
	if int(d["last_id"]) == int(run["id"]):
		return lines
	d["last_id"] = int(run["id"])
	if now < 0:
		now = int(Time.get_unix_time_from_system())
	var won: bool = str(run["result"]) == "win"
	d["runs"] = int(d["runs"]) + 1
	if won:
		d["wins"] = int(d["wins"]) + 1
	d["best"] = maxi(int(d["best"]), reached(run))
	var rw: Dictionary = reward(run)
	RosterState.apply_rewards(roster, rw)
	lines.append("SPEDIZIONE: +%d CREDITI" % int(rw["coins"]))
	var team: Array = roster.get("team", [])
	if checkpoint_reached(run):
		var gain: int = (LONG_XP if bool(run.get("long", false)) else 2) if won else 1
		for id in team:
			var before: int = vet_level(roster, str(id))
			d["xp"][str(id)] = mini(VET_MAX * 2, int(d["xp"].get(str(id), 0)) + gain)
			if vet_level(roster, str(id)) > before:
				lines.append("VETERANO: %s livello %d" % [str(BattleContent.CHARACTERS.get(str(id), {}).get("name", id)).to_upper(), vet_level(roster, str(id))])
	if not won:
		for id in team:
			if (run["fell"] as Dictionary).has(str(id)):
				d["wounds"][str(id)] = now + WOUND_SECONDS
				lines.append("FERITO: %s (cura %d crediti o attendi 6 ore)" % [str(BattleContent.CHARACTERS.get(str(id), {}).get("name", id)).to_upper(), HEAL_COST])
	return lines


# Riepilogo della spedizione, come nel documento: incontri, scoperte, momento decisivo.
static func summary(run: Dictionary) -> Array:
	var out: Array = []
	var total: int = 7 if bool(run.get("long", false)) else 4
	out.append("Incontri superati: %d / %d" % [mini(total, int(run["wins"])), total])
	if not (run.get("mods", []) as Array).is_empty():
		out.append("Modificatori: %s (premi x%.2f)" % [", ".join(PackedStringArray((run["mods"] as Array).map(func(x: Variant) -> String: return str(modifier(str(x)).get("name", x))))), reward_mult(run)])
	out.append("Potenziamenti: %d  ·  Provviste: %d  ·  Indizi: %d" % [(run["boons"] as Array).size(), int(run["supplies"]), int(run["clue"])])
	if not (run["fell"] as Dictionary).is_empty():
		var names: Array = []
		for c in run["fell"]:
			names.append(str(BattleContent.CHARACTERS.get(str(c), {}).get("name", c)).to_upper())
		out.append("Caduti: %s" % ", ".join(PackedStringArray(names)))
	for l in run["log"]:
		out.append(str(l))
	return out
