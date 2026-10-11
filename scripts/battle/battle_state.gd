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


static func make_unit(player_id: String, entry: Dictionary) -> Dictionary:
	var char_id: String = str(entry["char"])
	var def: Dictionary = BattleContent.CHARACTERS[char_id]
	var stats: Dictionary = BattleContent.compute_stats(entry)
	return {
		"id": unit_id(player_id, char_id),
		"char": char_id,
		"name": str(def["name"]),
		"side": "player",
		"owner": player_id,
		"color": str(def["color"]),
		"cls": str(def["cls"]),
		"level": int(entry.get("level", 1)),
		"max_hp": int(stats["hp"]),
		"hp": int(stats["hp"]),
		"atk": int(stats["atk"]),
		"def": int(stats["def"]),
		"spd": int(stats["spd"]),
		"energy": BattleTypes.START_ENERGY,
		"gauge": 0,
		"skills": entry.get("skills", []).duplicate(),
		"ult": str(entry.get("ult", "")),
		"passives": entry.get("passives", []).duplicate(),
		"statuses": {},
		"shield": 0,
	}


static func make_boss(boss_id: String, player_count: int) -> Dictionary:
	var def: Dictionary = BattleContent.BOSSES[boss_id]
	var hp: int = int(def["hp_per_player"]) * maxi(1, player_count)
	var scale_list: Array = def.get("atk_scale", [1.0])
	var atk_scale: float = float(scale_list[clampi(player_count, 1, scale_list.size()) - 1])
	return {
		"id": BOSS_ID,
		"char": boss_id,
		"name": str(def["name"]),
		"side": "boss",
		"owner": "",
		"color": str(def["color"]),
		"cls": "boss",
		"level": 1,
		"max_hp": hp,
		"hp": hp,
		"atk": int(round(float(def["atk"]) * atk_scale)),
		"def": int(def["def"]),
		"spd": int(def["spd"]),
		"energy": 0,
		"gauge": 0,
		"skills": [],
		"ult": "",
		"passives": [],
		"statuses": {},
		"shield": 0,
	}


# specs: [{id, name, ai, team:[entry]}]
static func create(specs: Array, boss_id: String, seed_value: int) -> Dictionary:
	var state: Dictionary = {
		"round": 1,
		"winner": "",
		"cycle_index": 0,
		"players": [],
		"units": {},
		"telegraph": {},
		"events": [],
		"rng_seed": str(seed_value),
		"rng_state": "0",
	}
	var units: Dictionary = state["units"]
	var players: Array = state["players"]
	for spec in specs:
		var pid: String = str(spec["id"])
		var team: Array = []
		var entries: Array = spec["team"]
		for i in mini(entries.size(), BattleTypes.TEAM_SIZE):
			var unit: Dictionary = make_unit(pid, entries[i])
			units[unit["id"]] = unit
			team.append(unit["id"])
		players.append({
			"id": pid,
			"name": str(spec.get("name", pid)),
			"ai": bool(spec.get("ai", false)),
			"team": team,
			"active": team[0] if not team.is_empty() else "",
			"choice": null,
		})
	units[BOSS_ID] = make_boss(boss_id, specs.size())
	var rng: RNGState = RNGState.new()
	rng.setup(seed_value)
	state["rng_state"] = str(rng.state_value)
	BattleResolver.begin_round(state)
	return state


# Partita in solitaria: i compagni sono personaggi del roster non in squadra,
# controllati dall'IA. Ogni compagno IA e' un giocatore a se' con 1 personaggio
# attivo + i suoi eventuali sostituti.
static func create_solo(player_name: String, team: Array, spare: Array, boss_id: String, seed_value: int, ai_count: int = 2) -> Dictionary:
	var specs: Array = [{"id": "p1", "name": player_name, "ai": false, "team": team}]
	var buckets: Array = []
	for i in ai_count:
		buckets.append([])
	for i in spare.size():
		var b: Array = buckets[i % ai_count] if ai_count > 0 else []
		if ai_count > 0 and b.size() < BattleTypes.TEAM_SIZE:
			b.append(spare[i])
	for i in ai_count:
		var b: Array = buckets[i]
		if b.is_empty():
			continue
		specs.append({"id": "ai%d" % (i + 1), "name": "IA %d" % (i + 1), "ai": true, "team": b})
	return create(specs, boss_id, seed_value)


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
	for uid in p["team"]:
		if is_alive(unit(state, uid)):
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


static func from_json(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {}
	return normalize(parsed)
