class_name BattleState
extends RefCounted

# Lo stato di una battaglia e' un Dictionary fatto solo di int, String, Array e
# Dictionary: si serializza in JSON senza perdite (vedi from_json).
#
# {
#   round, winner ("" | "players" | "boss"), cycle_index,
#   players: [{id, name, ai, team:[unit_id], active, choice}],
#   units: {unit_id: unit},   # il boss e' units["boss"]
#   telegraph: {move, target},  # mossa del boss annunciata, target = id giocatore
#   events: [..],               # cosa e' successo nell'ultimo round
#   rng_seed, rng_state         # stringhe (int64)
# }

const BOSS_ID: String = "boss"


static func unit_id(player_id: String, char_id: String) -> String:
	return "%s:%s" % [player_id, char_id]


# Campi comuni a ogni unita' (giocatori e boss): un solo posto da aggiornare quando ne nasce uno nuovo.
static func _blank_unit(id: String, char_id: String, side: String, owner: String, def: Dictionary, cls: String, stats: Dictionary) -> Dictionary:
	return {
		"id": id,
		"char": char_id,
		"name": str(def["name"]),
		"side": side,
		"owner": owner,
		"color": str(def["color"]),
		"cls": cls,
		"level": 1,
		"max_hp": int(stats["hp"]),
		"hp": int(stats["hp"]),
		"atk": int(stats["atk"]),
		"def": int(stats["def"]),
		"spd": int(stats["spd"]),
		"energy": 0,
		"gauge": 0,
		"skills": [],
		"ult": "",
		"passives": [],
		"statuses": {},
		"shield": 0,
		"ammo": 0,
		"ammo_max": 0,
		"marks": 0,
	}


# Le mosse del menu: max SKILL_SLOTS (Attacco, Guardia, skill e abilita' uniche contano tutte allo stesso modo).
# Un kit senza Attacco ne' Guardia e' un vecchio salvataggio: riceve Attacco, le abilita' uniche e Guardia.
# Nel kit resta sempre almeno una mossa base (e' quella che si puo' sempre usare).
static func kit_of(equipped: Array, sigs: Array) -> Array:
	var list: Array = []
	for m in equipped:
		if not list.has(str(m)):
			list.append(str(m))
	var has_basic: bool = false
	for m in list:
		has_basic = has_basic or BattleTypes.BASIC_MOVES.has(str(m))
	if not has_basic:
		var legacy: Array = ["attack"]
		for m in list:
			if not legacy.has(m):
				legacy.append(m)
		for m in sigs:
			if not legacy.has(str(m)):
				legacy.append(str(m))
		legacy.append("guard")
		list = legacy
	while list.size() > BattleTypes.SKILL_SLOTS:
		list.pop_back()
	has_basic = false
	for m in list:
		has_basic = has_basic or BattleTypes.BASIC_MOVES.has(str(m))
	if not has_basic:
		list[list.size() - 1] = "attack"
	var out: Array = []
	for m in list:
		if BattleTypes.BASIC_MOVES.has(str(m)):
			out.append(str(m))
	for m in list:
		if not BattleTypes.BASIC_MOVES.has(str(m)):
			out.append(str(m))
	return out


static func make_unit(player_id: String, entry: Dictionary) -> Dictionary:
	var char_id: String = str(entry["char"])
	var def: Dictionary = BattleContent.CHARACTERS[char_id]
	var stats: Dictionary = BattleContent.compute_stats(entry)
	var u: Dictionary = _blank_unit(unit_id(player_id, char_id), char_id, "player", player_id, def, str(def["cls"]), stats)
	u["level"] = int(entry.get("level", 1))
	u["energy"] = BattleTypes.START_ENERGY
	var sigs: Array = Signatures.skills_for(char_id, int(entry.get("rank", 0)))
	u["skills"] = kit_of(entry.get("skills", []), sigs)
	u["ult"] = str(entry.get("ult", ""))
	u["passives"] = entry.get("passives", []).duplicate()
	# abilita' e passiva uniche del personaggio; il rank le potenzia
	var rank: int = int(entry.get("rank", 0))
	u["rank"] = rank
	u["uniq"] = Signatures.effects_for(char_id, rank)
	u["awake"] = rank >= Signatures.AWAKEN_RANK
	u["rarity"] = int(entry.get("rarity", def.get("rarity", 0)))
	u["faction"] = BattleContent.faction_of(char_id, entry)
	if str(u["faction"]) == "libracorp":
		var cap: int = int(def.get("ammo_max", BattleTypes.AMMO_MAX))
		u["ammo"] = cap
		u["ammo_max"] = cap
	u["style"] = BattleContent.style_of(char_id, entry)
	u["arch_override"] = str(def.get("arch", ""))
	u["crit"] = 0
	u["crit_dmg"] = Factions.CRIT_DMG_PM
	u["base"] = {"atk": int(stats["atk"]), "def": int(stats["def"]), "spd": int(stats["spd"]), "crit": 0}
	u["aura"] = {}
	u["mods"] = []
	u["mastery"] = (entry.get("mastery", {}) as Dictionary).duplicate()
	Archetypes.setup(u)
	Atypical.setup(u)
	if bool(u.get("awake", false)):
		u["gauge"] = mini(BattleTypes.GAUGE_MAX, int(u["gauge"]) + Signatures.AWAKEN_GAUGE)
	return u


# Il boss scala con i "giocatori effettivi": un giocatore vale 1, un compagno IA
# ("ally": true, creato in solitaria) vale AI_WEIGHT. Un giocatore umano che esce
# e viene sostituito dall'IA resta un giocatore intero.
const AI_WEIGHT: float = 0.5


static func effective_players(specs: Array) -> float:
	var total: float = 0.0
	for spec in specs:
		total += float(spec.get("weight", AI_WEIGHT if bool(spec.get("ally", false)) else 1.0))
	return maxf(1.0, total)


# Valore della lista a "posizione" frazionaria (1 = primo elemento), interpolato.
static func _interpolate(values: Array, position: float) -> float:
	var x: float = clampf(position, 1.0, float(values.size()))
	var lower: int = int(floor(x))
	var upper: int = mini(lower + 1, values.size())
	var t: float = x - float(lower)
	return float(values[lower - 1]) * (1.0 - t) + float(values[upper - 1]) * t


static func make_boss(boss_id: String, effective: float, tier: int = 0) -> Dictionary:
	var def: Dictionary = BattleContent.BOSSES[boss_id]
	var t: Dictionary = BattleContent.tier_of(tier)
	# i livelli "appiattiti" (ABISSO) avvicinano PV e attacco base di ogni boss alla media: tutti ugualmente duri
	var flat: float = float(t.get("flatten", 0.0))
	var base_hp: float = lerpf(float(def["hp_per_player"]), BattleTypes.FLAT_BOSS_HP, flat)
	var base_atk: float = lerpf(float(def["atk"]), BattleTypes.FLAT_BOSS_ATK, flat)
	var hp: int = int(round(base_hp * maxf(1.0, effective) * float(t["hp"])))
	var atk_scale: float = _interpolate(def.get("atk_scale", [1.0]), effective)
	var stats: Dictionary = {
		"hp": hp,
		"atk": int(round(base_atk * atk_scale * float(t["atk"]))),
		"def": int(def["def"]) + int(t["def"]),
		"spd": int(def["spd"]),
	}
	var u: Dictionary = _blank_unit(BOSS_ID, boss_id, "boss", "", def, "boss", stats)
	var bmax: int = int(round(BattleTypes.BREAK_BASE + BattleTypes.BREAK_PER_PLAYER * maxf(1.0, effective))) + BattleTypes.BREAK_PER_TIER * tier
	u["weak2"] = str(def.get("weak2", ""))
	u["balance_max"] = bmax
	u["balance"] = bmax
	u["stun"] = 0
	u["exposed"] = false
	return u


# specs: [{id, name, ai, team:[entry]}]
static func create(specs: Array, boss_id: String, seed_value: int, tier: int = 0) -> Dictionary:
	var state: Dictionary = {
		"tier": clampi(tier, 0, BattleContent.TIERS.size() - 1),
		"round": 1,
		"winner": "",
		"cycle_index": 0,
		"phase": 1,
		"reserve": BattleTypes.RESERVE_START,
		"players": [],
		"units": {},
		"telegraph": {},
		"events": [],
		"summons": [],
		"marks_applied": 0,
		"rng_seed": str(seed_value),
		"rng_state": "0",
	}
	var units: Dictionary = state["units"]
	var players: Array = state["players"]
	for spec in specs:
		var pid: String = str(spec["id"])
		var team: Array = []
		var entries: Array = spec["team"]
		for i in mini(entries.size(), int(spec.get("max_team", BattleTypes.NET_TEAM_SIZE))):
			var unit: Dictionary = make_unit(pid, entries[i])
			units[unit["id"]] = unit
			team.append(unit["id"])
		var slot: Dictionary = {
			"id": pid,
			"name": str(spec.get("name", pid)),
			"ai": bool(spec.get("ai", false)),
			"team": team,
			"active": team[0] if not team.is_empty() else "",
			"choice": null,
		}
		players.append(slot)
		# slot di front row aggiuntivi dello stesso party: stessa squadra, un proprio personaggio in campo
		for extra in spec.get("extra_slots", []):
			players.append({
				"id": str(extra),
				"name": str(spec.get("name", pid)),
				"ai": bool(spec.get("ai", false)),
				"team": [],
				"leader": pid,
				"active": "",
				"choice": null,
			})
		var front_index: int = 1
		for extra in spec.get("extra_slots", []):
			var sp: Dictionary = player(state, str(extra))
			if front_index < team.size():
				sp["active"] = team[front_index]
			front_index += 1
	units[BOSS_ID] = make_boss(boss_id, effective_players(specs), int(state["tier"]))
	Factions.refresh(state)
	var rng: RNGState = RNGState.new()
	rng.setup(seed_value)
	state["rng_state"] = str(rng.state_value)
	Tactics.setup(state)
	BattleResolver.begin_round(state)
	return state


# Partita in solitaria: SOLO il party del giocatore (fino a 6 personaggi). I primi 3 sono la front row
# (uno slot ciascuno, tutti decisi dal giocatore), gli altri sono la back row e si scambiano coi front.
# `spare` e `ai_count` restano per compatibilita': non si assegnano piu' alleati esterni.
static func create_solo(player_name: String, team: Array, _spare: Array, boss_id: String, seed_value: int, _ai_count: int = 0, tier: int = 0) -> Dictionary:
	var fronts: int = clampi(team.size(), 1, BattleTypes.FRONT_SIZE)
	var extra: Array = []
	for i in range(1, fronts):
		extra.append("p1_f%d" % (i + 1))
	var spec: Dictionary = {"id": "p1", "name": player_name, "ai": false, "team": team, "max_team": BattleTypes.TEAM_SIZE, "extra_slots": extra,
		"weight": 1.0 + 0.5 * float(extra.size())}
	return create([spec], boss_id, seed_value, tier)


# ---------- Party, front row e back row ----------

# Gli id di tutti i personaggi del party a cui appartiene lo slot (in rete: la squadra del giocatore).
static func party_of(state: Dictionary, p: Dictionary) -> Array:
	var lead: String = str(p.get("leader", ""))
	if lead != "":
		return player(state, lead).get("team", [])
	return p["team"]


static func is_front(state: Dictionary, uid: String) -> bool:
	for q in state["players"]:
		if str(q["active"]) == uid:
			return true
	return false


# Personaggi vivi del party in back row (non in campo in nessuno slot).
static func back_row(state: Dictionary, p: Dictionary) -> Array:
	var out: Array = []
	for uid in party_of(state, p):
		if not is_front(state, str(uid)) and is_alive(unit(state, str(uid))):
			out.append(str(uid))
	return out


# Lo slot in cui il personaggio e' in campo ("" se e' in back row).
static func slot_of(state: Dictionary, uid: String) -> String:
	for q in state["players"]:
		if str(q["active"]) == uid:
			return str(q["id"])
	return ""


static func unit(state: Dictionary, uid: String) -> Dictionary:
	return state["units"].get(uid, {})


static func boss(state: Dictionary) -> Dictionary:
	return state["units"][BOSS_ID]


static func player(state: Dictionary, pid: String) -> Dictionary:
	for p in state["players"]:
		if p["id"] == pid:
			return p
	return {}


static func is_alive(u: Dictionary) -> bool:
	return not u.is_empty() and int(u["hp"]) > 0


static func active_unit(state: Dictionary, pid: String) -> Dictionary:
	var p: Dictionary = player(state, pid)
	if p.is_empty():
		return {}
	return unit(state, str(p["active"]))


static func player_alive(state: Dictionary, p: Dictionary) -> bool:
	if is_alive(unit(state, str(p["active"]))):
		return true
	for uid in party_of(state, p):
		if is_alive(unit(state, str(uid))) and not is_front(state, str(uid)):
			return true
	return false


static func alive_players(state: Dictionary) -> Array:
	var result: Array = []
	for p in state["players"]:
		if player_alive(state, p):
			result.append(p)
	return result


static func to_json(state: Dictionary) -> String:
	return JSON.stringify(state)


# Dopo il passaggio da JSON i numeri tornano float: qui si riportano a int.
# Nello stato non ci sono float veri, quindi la conversione e' sicura.
static func normalize(value: Variant) -> Variant:
	if value is float:
		return int(value)
	if value is Array:
		var out_a: Array = []
		for v in value:
			out_a.append(normalize(v))
		return out_a
	if value is Dictionary:
		var out_d: Dictionary = {}
		for k in value:
			out_d[k] = normalize(value[k])
		return out_d
	return value


# Legge una partita salvata. Se il testo e' rovinato o incompleto ritorna {} (usa check_json per sapere perche').
static func from_json(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {}
	var state: Dictionary = normalize(parsed)
	return state if validate(state) == "" else {}


# Come from_json, ma ritorna il motivo in italiano: {"ok": bool, "state": Dictionary, "error": String}.
static func check_json(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {"ok": false, "state": {}, "error": "Il salvataggio e' rovinato: non si legge."}
	var state: Dictionary = normalize(parsed)
	var err: String = validate(state)
	return {"ok": err == "", "state": state if err == "" else {}, "error": err}


# Controlla che uno stato di battaglia (gia' normalizzato) sia completo e coerente. Ritorna "" se va bene,
# altrimenti il motivo in italiano. NON ripara nulla: uno stato rovinato si rifiuta.
const _STATE_KEYS: Dictionary = {"round": TYPE_INT, "winner": TYPE_STRING, "players": TYPE_ARRAY, "units": TYPE_DICTIONARY,
	"events": TYPE_ARRAY, "rng_seed": TYPE_STRING, "rng_state": TYPE_STRING}
const _UNIT_INTS: Array = ["hp", "max_hp", "atk", "def", "spd", "energy", "gauge", "shield"]


static func validate(state: Dictionary) -> String:
	for k in _STATE_KEYS:
		if not state.has(k):
			return "Salvataggio incompleto: manca '%s'." % k
		if typeof(state[k]) != int(_STATE_KEYS[k]):
			return "Salvataggio rovinato: '%s' ha un tipo sbagliato." % k
	var units: Dictionary = state["units"]
	if not bool(state.get("pvp", false)):       # la sfida PvP non ha ne' boss ne' annuncio
		if not units.has(BOSS_ID):
			return "Salvataggio incompleto: manca il boss."
		if not (state.get("telegraph", null) is Dictionary):
			return "Salvataggio incompleto: manca l'annuncio del boss."
	if (state["players"] as Array).is_empty():
		return "Salvataggio incompleto: nessun giocatore."
	for uid in units:
		var u: Variant = units[uid]
		if not (u is Dictionary):
			return "Salvataggio rovinato: l'unita' '%s' non e' valida." % uid
		for k in _UNIT_INTS:
			if not (u as Dictionary).has(k) or typeof(u[k]) != TYPE_INT:
				return "Salvataggio rovinato: '%s' ha '%s' mancante o sbagliato." % [uid, k]
		if int(u["hp"]) < 0 or int(u["hp"]) > int(u["max_hp"]) or int(u["max_hp"]) <= 0:
			return "Salvataggio rovinato: i PV di '%s' non sono validi." % uid
		if not (u.get("statuses", {}) is Dictionary) or not (u.get("skills", []) is Array):
			return "Salvataggio rovinato: '%s' ha stati o mosse non validi." % uid
	for p in state["players"]:
		var members_key: String = "units" if bool(state.get("pvp", false)) else "team"    # nel PvP "team" e' la fazione
		if not (p is Dictionary) or not (p as Dictionary).has("id") or not (p.get(members_key, null) is Array):
			return "Salvataggio rovinato: un giocatore non e' valido."
		for tid in p[members_key]:
			if not units.has(tid):
				return "Salvataggio rovinato: il personaggio '%s' non esiste." % tid
		var active: String = str(p.get("active", ""))
		if active != "" and not units.has(active):
			return "Salvataggio rovinato: il personaggio in campo '%s' non esiste." % active
	return ""
