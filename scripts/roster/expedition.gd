class_name Expedition
extends RefCounted

# SPEDIZIONE: una run roguelite in 6 tappe (da soli o in cooperativa), con conseguenze che restano.
#   PERCORSO -> COMBATTIMENTO -> EVENTO -> COMBATTIMENTO (con distorsione) -> BIVIO -> BOSS FINALE
# Dopo ogni combattimento si sceglie un potenziamento (1 su 3). I PV si portano dietro, le Provviste si spendono per riposare.
# Conseguenze: chi cade e perde la run resta FERITO (PV massimi -10% in ogni battaglia, finche' non passa il tempo o paghi la cura);
# chi completa la spedizione (o arriva al checkpoint) diventa VETERANO: bonus permanenti piccoli, fino al livello 5.
# Tutta la logica e' deterministica e vive in un dizionario "run" (serializzabile): in rete lo possiede l'host.

const KINDS: Array = ["path", "combat", "event", "combat", "cross", "boss"]
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

const PATHS: Array = [
	{"id": "infestata", "name": "ZONA INFESTATA", "tag": "RISCHIO", "desc": "Un'elite custodisce una reliquia: un potenziamento in piu', ma il nemico e' piu' duro."},
	{"id": "archivio", "name": "ARCHIVIO RITUALE", "tag": "INFORMAZIONI", "desc": "Scopri la debolezza del boss finale: partira' con meno equilibrio e il suo comportamento sara' noto."},
	{"id": "rifugio", "name": "RIFUGIO INSTABILE", "tag": "RECUPERO", "desc": "Niente bottino: la squadra recupera i PV e guadagna 1 Provvista."},
]
const EVENT_OPTIONS: Array = [
	{"id": "accetta", "name": "ACCETTA IL PATTO", "tag": "PREZZO", "desc": "Un'entita' offre 2 potenziamenti, ma un operatore resta indebolito (PV massimi -15%) per tutta la spedizione."},
	{"id": "rifiuta", "name": "RIFIUTA", "tag": "SICURO", "desc": "Nessun rischio: guadagni 1 Provvista."},
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

static func new_run(seed_value: int, boss_id: String, tier: int, coop: bool = false) -> Dictionary:
	return {
		"v": 1, "id": absi(seed_value) + 1, "seed": absi(seed_value) + 1, "boss": boss_id,
		"tier": clampi(tier, 0, BattleContent.TIERS.size() - 1), "coop": coop,
		"stage": 0, "phase": "choose", "next": 0, "boon_left": 0,
		"boons": [], "carry": {}, "supplies": 1, "clue": 0, "elite": false, "heal": 0.0,
		"pact_unit": "", "fell": {}, "log": [], "votes": {}, "result": "", "wins": 0, "fights": 0,
	}


# Che cosa chiede la run adesso: path, event, cross (decisioni), boon (potenziamento), fight (da combattere), done.
static func kind(run: Dictionary) -> String:
	match str(run.get("phase", "")):
		"done":
			return "done"
		"boon":
			return "boon"
		"battle":
			return "fight"
	return str(KINDS[clampi(int(run.get("stage", 0)), 0, KINDS.size() - 1)])


# Ruolo del combattimento corrente: combat1, combat2, elite, boss.
static func role(run: Dictionary) -> String:
	match int(run.get("stage", 0)):
		1:
			return "combat1"
		3:
			return "combat2"
		4:
			return "elite"
	return "boss"


static func stage_title(run: Dictionary) -> String:
	var k: String = kind(run)
	match k:
		"path":
			return "SCEGLI IL PERCORSO"
		"event":
			return "EVENTO: IL PATTO"
		"cross":
			return "BIVIO PRIMA DEL BOSS"
		"boon":
			return "SCEGLI UN POTENZIAMENTO"
		"fight":
			return {"combat1": "PRIMO SCONTRO", "combat2": "SECONDO SCONTRO", "elite": "ELITE FACOLTATIVA", "boss": "BOSS FINALE"}[role(run)]
		"done":
			return "SPEDIZIONE COMPLETATA" if str(run.get("result", "")) == "win" else "SPEDIZIONE FALLITA"
	return ""


# Opzioni della decisione corrente: [{id, name, tag, desc}].
static func options(run: Dictionary) -> Array:
	match kind(run):
		"path":
			return PATHS
		"event":
			return EVENT_OPTIONS
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
	return Endless.offer(int(run["seed"]) % 9973 + int(run["fights"]) * 31)


static func option_ids(run: Dictionary) -> Array:
	var out: Array = []
	for o in options(run):
		out.append(str(o["id"]))
	return out


static func _log(run: Dictionary, text: String) -> void:
	(run["log"] as Array).append(text)


# Applica la decisione (percorso, evento, bivio, potenziamento). Ritorna "" se ok, altrimenti il motivo.
static func choose(run: Dictionary, option_id: String) -> String:
	var k: String = kind(run)
	if not option_ids(run).has(option_id):
		return "scelta non valida"
	run["votes"] = {}
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
			run["stage"] = 1
			run["phase"] = "battle"
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
			run["stage"] = 3
			run["phase"] = "battle"
		"cross":
			match option_id:
				"elite":
					_log(run, "Bivio: ELITE FACOLTATIVA")
					run["stage"] = 4
					run["phase"] = "battle"
					return ""
				"esplora":
					run["clue"] = int(run["clue"]) + 1
					_log(run, "Bivio: ESPLORA (altro indizio)")
				"riposo":
					var big: bool = int(run["supplies"]) > 0
					run["heal"] = REST_HEAL * (2.0 if big else 1.0)
					if big:
						run["supplies"] = int(run["supplies"]) - 1
					_log(run, "Bivio: RIPOSO")
			run["stage"] = 5
			run["phase"] = "battle"
		"boon":
			(run["boons"] as Array).append(option_id)
			_log(run, "Potenziamento: %s" % str(Endless.BOONS[option_id]["name"]))
			run["boon_left"] = int(run["boon_left"]) - 1
			if int(run["boon_left"]) <= 0:
				run["stage"] = int(run["next"])
				run["phase"] = "battle" if int(run["next"]) == 5 else "choose"
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
	match r:
		"combat1":
			return {"role": r, "boss": pool[sd % pool.size()], "tier": 0, "floor": 4 if bool(run["elite"]) else 2, "mod": "", "hp": 0.6}
		"combat2":
			var mods: Array = Endless.MODS
			return {"role": r, "boss": pool[(sd / 3 + 1) % pool.size()], "tier": 0, "floor": 4, "mod": str(mods[sd % mods.size()]["id"]), "hp": 0.6}
		"elite":
			var mods2: Array = Endless.MODS
			return {"role": r, "boss": pool[(sd / 5 + 2) % pool.size()], "tier": 0, "floor": 5, "mod": str(mods2[(sd / 2) % mods2.size()]["id"]), "hp": 0.8}
	return {"role": "boss", "boss": str(run["boss"]), "tier": int(run["tier"]), "floor": 1, "mod": "", "hp": 1.0}


static func mod_name(id: String) -> String:
	for m in Endless.MODS:
		if str(m["id"]) == id:
			return str(m["name"])
	return ""


# Prepara lo stato di battaglia (dopo BattleState.create): scala il nemico e porta dentro tutto cio' che la run ha accumulato.
static func apply_to_battle(run: Dictionary, state: Dictionary) -> void:
	var bp: Dictionary = battle_params(run)
	if int(bp["floor"]) > 1 or str(bp["mod"]) != "":
		Endless.apply(state, int(bp["floor"]), str(bp["mod"]))
		state.erase("endless")
	var boss: Dictionary = BattleState.boss(state)
	if float(bp["hp"]) != 1.0:
		boss["max_hp"] = maxi(1, int(round(float(boss["max_hp"]) * float(bp["hp"]))))
		boss["hp"] = int(boss["max_hp"])
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
	if pu != "":
		for uid in state["units"]:
			var u2: Dictionary = state["units"][uid]
			if str(u2["side"]) == "player" and str(u2.get("char", "")) == pu:
				u2["max_hp"] = int(round(float(u2["max_hp"]) * PACT_HP))
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
		if str(u["side"]) == "player" and int(u["hp"]) <= 0:
			run["fell"][str(u.get("char", ""))] = true
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
	if r == "combat1" and bool(run["elite"]):
		n = 2
		lines.append("Reliquia trovata: scegli due potenziamenti.")
	run["boon_left"] = n
	run["next"] = {"combat1": 2, "combat2": 4, "elite": 5}[r]
	run["phase"] = "boon"
	return lines


# Una battaglia dà i premi normali (e conta come boss battuto) solo se non e' una tappa intermedia della spedizione.
static func pays_rewards(state: Dictionary) -> bool:
	return not state.has("expedition") or str(state["expedition"].get("role", "")) == "boss"


# Premi della spedizione (crediti e materiali), proporzionali ai combattimenti vinti.
static func reward(run: Dictionary) -> Dictionary:
	var coins: int = COIN_PER_STAGE * int(run["wins"])
	var mats: Dictionary = {}
	if str(run.get("result", "")) == "win":
		coins += COIN_WIN
		mats = {"nucleo": 3, "lega": 3}
	elif int(run["wins"]) >= 2:
		mats = {"nucleo": 1, "lega": 1}
	return {"coins": coins, "materials": mats}


# Tappa raggiunta (0-5), per i record.
static func reached(run: Dictionary) -> int:
	return int(run["stage"]) + (1 if str(run.get("result", "")) == "win" else 0)


static func checkpoint_reached(run: Dictionary) -> bool:
	return str(run.get("result", "")) == "win" or int(run["wins"]) >= 2


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
		var gain: int = 2 if won else 1
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
	out.append("Incontri superati: %d / 4" % mini(4, int(run["wins"])))
	out.append("Potenziamenti: %d  ·  Provviste: %d  ·  Indizi: %d" % [(run["boons"] as Array).size(), int(run["supplies"]), int(run["clue"])])
	if not (run["fell"] as Dictionary).is_empty():
		var names: Array = []
		for c in run["fell"]:
			names.append(str(BattleContent.CHARACTERS.get(str(c), {}).get("name", c)).to_upper())
		out.append("Caduti: %s" % ", ".join(PackedStringArray(names)))
	for l in run["log"]:
		out.append(str(l))
	return out
