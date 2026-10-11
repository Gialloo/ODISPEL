class_name RosterState
extends RefCounted

# Collezione del giocatore: personaggi posseduti, squadra di 3, mosse e passive
# in inventario. E' un Dictionary solo di int/String/Array/Dictionary (salvabile
# in JSON). Le funzioni sono statiche e modificano il Dictionary passato.
#
# {
#   version, coins,
#   characters: {char_id: entry},   # entry come in BattleContent.default_entry
#   team: [char_id],                # 1..3, il primo e' l'attivo iniziale
#   moves: {move_id: copie},        # inventario mosse/ultimate
#   passives: {passive_id: copie},
#   materials: {nucleo, lega: quantita'},
#   gear: {gear_id: {id, slot, rarity, level, equipped_by}},  # pezzi unici
#   next_gear: int,                                           # prossimo id pezzo
#   pulls: int, pity: int                                     # reclutamento
# }

const VERSION: int = 1
const MAX_LEVEL: int = 50
const MAX_RANK: int = 5
# Si parte con 4 personaggi: 3 in squadra e 1 di riserva (compagno IA in solitaria).
const STARTER_CHARACTERS: Array = ["kira", "dax", "elle", "bruno"]
const STARTER_TEAM: Array = ["kira", "dax", "elle"]


static func new_roster() -> Dictionary:
	var roster: Dictionary = {
		"version": VERSION,
		"coins": 0,
		"characters": {},
		"team": [],
		"moves": {},
		"passives": {},
		"materials": {},
		"gear": {},
		"next_gear": 1,
		"pulls": 0,
		"pity": 0,
	}
	for id in STARTER_CHARACTERS:
		add_character(roster, str(id))
	set_team(roster, STARTER_TEAM)
	return roster


# ---------- Possesso ----------

static func owns(roster: Dictionary, char_id: String) -> bool:
	return roster["characters"].has(char_id)


# Nuovo personaggio, oppure una copia in piu': sale di rank.
# Ritorna "new", "rank" oppure "max" (rank gia' al massimo) o "" se sconosciuto.
static func add_character(roster: Dictionary, char_id: String) -> String:
	if not BattleContent.CHARACTERS.has(char_id):
		return ""
	if owns(roster, char_id):
		var entry: Dictionary = roster["characters"][char_id]
		if int(entry["rank"]) >= MAX_RANK:
			return "max"
		entry["rank"] = int(entry["rank"]) + 1
		return "rank"
	var fresh: Dictionary = BattleContent.default_entry(char_id)
	roster["characters"][char_id] = fresh
	# la mossa, l'ultimate e la passiva innate sono sempre possedute
	_inventory_add(roster["moves"], str(fresh["skills"][0]))
	_inventory_add(roster["moves"], str(fresh["ult"]))
	_inventory_add(roster["passives"], str(fresh["passives"][0]))
	return "new"


static func _inventory_add(table: Dictionary, id: String) -> void:
	table[id] = int(table.get(id, 0)) + 1


# Assegna un premio ({kind: move|passive, id}) all'inventario.
static func add_drop(roster: Dictionary, drop: Dictionary) -> bool:
	var id: String = str(drop.get("id", ""))
	match str(drop.get("kind", "")):
		"move":
			if not BattleContent.MOVES.has(id) or str(BattleContent.MOVES[id]["kind"]) == "basic":
				return false
			_inventory_add(roster["moves"], id)
			return true
		"passive":
			if not BattleContent.PASSIVES.has(id):
				return false
			_inventory_add(roster["passives"], id)
			return true
	return false


# ---------- Squadra ----------

static func set_team(roster: Dictionary, ids: Array) -> bool:
	if ids.is_empty() or ids.size() > BattleTypes.TEAM_SIZE:
		return false
	var seen: Dictionary = {}
	for id in ids:
		if not owns(roster, str(id)) or seen.has(str(id)):
			return false
		seen[str(id)] = true
	var team: Array = []
	for id in ids:
		team.append(str(id))
	roster["team"] = team
	return true


static func team_entries(roster: Dictionary) -> Array:
	var out: Array = []
	for id in roster["team"]:
		out.append(roster["characters"][id].duplicate(true))
	return out


# Personaggi posseduti fuori squadra: i compagni IA nelle partite in solitaria.
static func spare_entries(roster: Dictionary) -> Array:
	var out: Array = []
	var ids: Array = roster["characters"].keys()
	ids.sort()
	for id in ids:
		if not roster["team"].has(id):
			out.append(roster["characters"][id].duplicate(true))
	return out


# ---------- Equipaggiamento ----------

# Quante copie di una mossa/passiva sono gia' equipaggiate (escluso un posto).
static func _used(roster: Dictionary, field: String, id: String, skip_char: String = "", skip_index: int = -1) -> int:
	var count: int = 0
	for cid in roster["characters"]:
		var entry: Dictionary = roster["characters"][cid]
		if field == "ult":
			if str(entry["ult"]) == id and not (cid == skip_char and skip_index == 0):
				count += 1
			continue
		var list: Array = entry[field]
		for i in list.size():
			if str(list[i]) == id and not (cid == skip_char and i == skip_index):
				count += 1
	return count


# Mette una skill nello slot (0..SKILL_SLOTS-1). id "" svuota lo slot.
static func equip_skill(roster: Dictionary, char_id: String, slot: int, move_id: String) -> bool:
	if not owns(roster, char_id) or slot < 0 or slot >= BattleTypes.SKILL_SLOTS:
		return false
	var skills: Array = roster["characters"][char_id]["skills"]
	if move_id == "":
		if slot < skills.size():
			skills.remove_at(slot)
		return true
	if slot > skills.size():
		return false
	if not BattleContent.MOVES.has(move_id) or str(BattleContent.MOVES[move_id]["kind"]) != "skill":
		return false
	if int(roster["moves"].get(move_id, 0)) <= _used(roster, "skills", move_id, char_id, slot):
		return false
	for i in skills.size():
		if i != slot and str(skills[i]) == move_id:
			return false
	if slot == skills.size():
		skills.append(move_id)
	else:
		skills[slot] = move_id
	return true


static func equip_ult(roster: Dictionary, char_id: String, move_id: String) -> bool:
	if not owns(roster, char_id):
		return false
	if not BattleContent.MOVES.has(move_id) or str(BattleContent.MOVES[move_id]["kind"]) != "ult":
		return false
	if int(roster["moves"].get(move_id, 0)) <= _used(roster, "ult", move_id, char_id, 0):
		return false
	roster["characters"][char_id]["ult"] = move_id
	return true


static func equip_passive(roster: Dictionary, char_id: String, slot: int, passive_id: String) -> bool:
	if not owns(roster, char_id) or slot < 0 or slot >= BattleTypes.PASSIVE_SLOTS:
		return false
	var list: Array = roster["characters"][char_id]["passives"]
	if passive_id == "":
		if slot < list.size():
			list.remove_at(slot)
		return true
	if slot > list.size() or not BattleContent.PASSIVES.has(passive_id):
		return false
	if int(roster["passives"].get(passive_id, 0)) <= _used(roster, "passives", passive_id, char_id, slot):
		return false
	for i in list.size():
		if i != slot and str(list[i]) == passive_id:
			return false
	if slot == list.size():
		list.append(passive_id)
	else:
		list[slot] = passive_id
	return true


# ---------- Validazione (anche per le squadre ricevute dalla rete) ----------

# Ritorna "" se la voce e' valida, altrimenti il motivo.
static func validate_entry(entry: Dictionary) -> String:
	var char_id: String = str(entry.get("char", ""))
	if not BattleContent.CHARACTERS.has(char_id):
		return "personaggio sconosciuto"
	var level: int = int(entry.get("level", 0))
	if level < 1 or level > MAX_LEVEL:
		return "livello non valido"
	var rank: int = int(entry.get("rank", -1))
	if rank < 0 or rank > MAX_RANK:
		return "rank non valido"
	var skills: Array = entry.get("skills", [])
	if skills.size() > BattleTypes.SKILL_SLOTS:
		return "troppe skill"
	var seen: Dictionary = {}
	for m in skills:
		if not BattleContent.MOVES.has(str(m)) or str(BattleContent.MOVES[str(m)]["kind"]) != "skill":
			return "skill non valida"
		if seen.has(str(m)):
			return "skill duplicata"
		seen[str(m)] = true
	var ult: String = str(entry.get("ult", ""))
	if ult != "" and (not BattleContent.MOVES.has(ult) or str(BattleContent.MOVES[ult]["kind"]) != "ult"):
		return "ultimate non valida"
	var passives: Array = entry.get("passives", [])
	if passives.size() > BattleTypes.PASSIVE_SLOTS:
		return "troppe passive"
	seen = {}
	for p in passives:
		if not BattleContent.PASSIVES.has(str(p)) or seen.has(str(p)):
			return "passiva non valida"
		seen[str(p)] = true
	for piece in entry.get("gear", []):
		if not BattleContent.GEAR_BASE.has(str(piece.get("slot", ""))):
			return "pezzo non valido"
		var r: int = int(piece.get("rarity", -1))
		if r < 0 or r >= BattleContent.GEAR_RARITY_MULT.size():
			return "rarita' pezzo non valida"
		var gl: int = int(piece.get("level", 0))
		if gl < 1 or gl > MAX_LEVEL:
			return "livello pezzo non valido"
	return ""


# Ritorna "" se la squadra e' valida per entrare in battaglia.
static func validate_team(entries: Array) -> String:
	if entries.is_empty() or entries.size() > BattleTypes.TEAM_SIZE:
		return "squadra di dimensione non valida"
	var seen: Dictionary = {}
	for e in entries:
		if not (e is Dictionary):
			return "voce non valida"
		var err: String = validate_entry(e)
		if err != "":
			return err
		if seen.has(str(e["char"])):
			return "personaggio duplicato"
		seen[str(e["char"])] = true
	return ""


# Controlla l'intera collezione: squadra, equipaggiamento e inventario.
static func validate(roster: Dictionary) -> String:
	if not roster.has("characters") or not roster.has("team") or not roster.has("moves") or not roster.has("passives"):
		return "dati mancanti"
	for id in roster["characters"]:
		var err: String = validate_entry(roster["characters"][id])
		if err != "":
			return "%s: %s" % [id, err]
	var gear_err: String = _validate_gear(roster)
	if gear_err != "":
		return gear_err
	var team: Array = roster["team"]
	if team.is_empty() or team.size() > BattleTypes.TEAM_SIZE:
		return "squadra non valida"
	for id in team:
		if not roster["characters"].has(id):
			return "squadra con personaggio non posseduto"
	for id in roster["moves"]:
		if _used(roster, "skills", str(id)) + _used(roster, "ult", str(id)) > int(roster["moves"][id]):
			return "mossa equipaggiata piu' volte di quante possedute: %s" % id
	for id in roster["passives"]:
		if _used(roster, "passives", str(id)) > int(roster["passives"][id]):
			return "passiva equipaggiata piu' volte di quante possedute: %s" % id
	return ""


static func _validate_gear(roster: Dictionary) -> String:
	if int(roster.get("coins", 0)) < 0:
		return "monete negative"
	if int(roster.get("pulls", 0)) < 0 or int(roster.get("pity", 0)) < 0:
		return "contatori di reclutamento negativi"
	for mat in roster.get("materials", {}):
		if not BattleContent.MATERIALS.has(mat) or int(roster["materials"][mat]) < 0:
			return "materiale non valido"
	var used: Dictionary = {}
	for gid in roster.get("gear", {}):
		var g: Dictionary = roster["gear"][gid]
		if str(g.get("id", "")) != str(gid):
			return "pezzo con id incoerente"
		if not BattleContent.GEAR_BASE.has(str(g.get("slot", ""))):
			return "pezzo con slot non valido"
		var r: int = int(g.get("rarity", -1))
		if r < 0 or r >= BattleContent.GEAR_RARITY_MULT.size():
			return "pezzo con rarita' non valida"
		var lv: int = int(g.get("level", 0))
		if lv < 1 or lv > int(BattleContent.GEAR_MAX_LEVEL[r]):
			return "pezzo con livello non valido"
		var owner_id: String = str(g.get("equipped_by", ""))
		if owner_id != "":
			if not roster["characters"].has(owner_id):
				return "pezzo equipaggiato a chi non c'e'"
			var key: String = "%s/%s" % [owner_id, g["slot"]]
			if used.has(key):
				return "due pezzi nello stesso slot"
			used[key] = true
	return ""


# ---------- Equipaggiamento: pezzi unici ----------

# Crea un pezzo nuovo e ritorna il suo id.
static func new_gear(roster: Dictionary, slot: String, rarity: int, level: int = 1) -> String:
	if not BattleContent.GEAR_BASE.has(slot):
		return ""
	if rarity < 0 or rarity >= BattleContent.GEAR_RARITY_MULT.size():
		return ""
	if level < 1 or level > int(BattleContent.GEAR_MAX_LEVEL[rarity]):
		return ""
	var gid: String = "g%d" % int(roster["next_gear"])
	roster["next_gear"] = int(roster["next_gear"]) + 1
	roster["gear"][gid] = {"id": gid, "slot": slot, "rarity": rarity, "level": level, "equipped_by": ""}
	return gid


# Rifa la lista "gear" di ogni personaggio dai pezzi equipaggiati:
# il motore di battaglia legge solo quella.
static func sync_gear(roster: Dictionary) -> void:
	for cid in roster["characters"]:
		roster["characters"][cid]["gear"] = []
	var ids: Array = roster["gear"].keys()
	ids.sort()
	for gid in ids:
		var g: Dictionary = roster["gear"][gid]
		var owner_id: String = str(g["equipped_by"])
		if owner_id != "" and roster["characters"].has(owner_id):
			roster["characters"][owner_id]["gear"].append({"id": gid, "slot": g["slot"], "rarity": g["rarity"], "level": g["level"]})


# Equipaggia un pezzo. Se era su un altro personaggio passa a questo;
# se c'era gia' un pezzo dello stesso slot, quello torna in inventario.
static func equip_gear(roster: Dictionary, char_id: String, gear_id: String) -> bool:
	if not owns(roster, char_id) or not roster["gear"].has(gear_id):
		return false
	var item: Dictionary = roster["gear"][gear_id]
	for other_id in roster["gear"]:
		var other: Dictionary = roster["gear"][other_id]
		if other_id != gear_id and str(other["equipped_by"]) == char_id and other["slot"] == item["slot"]:
			other["equipped_by"] = ""
	item["equipped_by"] = char_id
	sync_gear(roster)
	return true


static func unequip_gear(roster: Dictionary, gear_id: String) -> bool:
	if not roster["gear"].has(gear_id):
		return false
	roster["gear"][gear_id]["equipped_by"] = ""
	sync_gear(roster)
	return true


# ---------- Potenziamento ----------

static func _can_pay(roster: Dictionary, cost: Dictionary) -> String:
	if int(roster["coins"]) < int(cost.get("coins", 0)):
		return "monete"
	for mat in BattleContent.MATERIALS:
		if int(roster["materials"].get(mat, 0)) < int(cost.get(mat, 0)):
			return mat
	return ""


static func _pay(roster: Dictionary, cost: Dictionary) -> void:
	roster["coins"] = int(roster["coins"]) - int(cost.get("coins", 0))
	for mat in BattleContent.MATERIALS:
		var left: int = int(roster["materials"].get(mat, 0)) - int(cost.get(mat, 0))
		if left > 0:
			roster["materials"][mat] = left
		else:
			roster["materials"].erase(mat)


# Ritorna "" se riuscito, altrimenti cosa manca: "sconosciuto", "max", "monete", "nucleo".
static func level_up_character(roster: Dictionary, char_id: String) -> String:
	if not owns(roster, char_id):
		return "sconosciuto"
	var entry: Dictionary = roster["characters"][char_id]
	var level: int = int(entry["level"])
	if level >= MAX_LEVEL:
		return "max"
	var cost: Dictionary = BattleContent.character_upgrade_cost(level)
	var missing: String = _can_pay(roster, cost)
	if missing != "":
		return missing
	_pay(roster, cost)
	entry["level"] = level + 1
	return ""


# Ritorna "" se riuscito, altrimenti cosa manca: "sconosciuto", "max", "monete", "lega".
static func level_up_gear(roster: Dictionary, gear_id: String) -> String:
	if not roster["gear"].has(gear_id):
		return "sconosciuto"
	var item: Dictionary = roster["gear"][gear_id]
	var level: int = int(item["level"])
	var rarity: int = int(item["rarity"])
	if level >= int(BattleContent.GEAR_MAX_LEVEL[rarity]):
		return "max"
	var cost: Dictionary = BattleContent.gear_upgrade_cost(rarity, level)
	var missing: String = _can_pay(roster, cost)
	if missing != "":
		return missing
	_pay(roster, cost)
	item["level"] = level + 1
	sync_gear(roster)
	return ""


# ---------- Premi ----------

# Aggiunge alla collezione i premi di BattleRewards. Ritorna quanti premi
# (monete, materiali, oggetti) sono stati applicati.
static func apply_rewards(roster: Dictionary, rewards: Dictionary) -> int:
	var applied: int = 0
	var coins: int = int(rewards.get("coins", 0))
	if coins > 0:
		roster["coins"] = int(roster["coins"]) + coins
		applied += 1
	var materials: Dictionary = rewards.get("materials", {})
	for mat in materials:
		if BattleContent.MATERIALS.has(mat) and int(materials[mat]) > 0:
			roster["materials"][mat] = int(roster["materials"].get(mat, 0)) + int(materials[mat])
			applied += 1
	for drop in rewards.get("drops", []):
		if not (drop is Dictionary):
			continue
		if str(drop.get("kind", "")) == "gear":
			if new_gear(roster, str(drop.get("slot", "")), int(drop.get("rarity", -1))) != "":
				applied += 1
		elif add_drop(roster, drop):
			applied += 1
	return applied


# ---------- Battaglia ----------

# Partita in solitaria: la tua squadra + compagni IA con i personaggi fuori squadra.
static func create_solo_battle(roster: Dictionary, player_name: String, boss_id: String, seed_value: int, ai_count: int = 2) -> Dictionary:
	return BattleState.create_solo(player_name, team_entries(roster), spare_entries(roster), boss_id, seed_value, ai_count)


# ---------- JSON ----------

static func to_json(roster: Dictionary) -> String:
	return JSON.stringify(roster, "\t")


static func from_json(text: String) -> Dictionary:
	var json: JSON = JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return {}
	var parsed: Variant = json.data
	var roster: Dictionary = BattleState.normalize(parsed)
	# salvataggi scritti prima dei pezzi unici e dei materiali
	if not roster.has("materials"):
		roster["materials"] = {}
	if not roster.has("gear"):
		roster["gear"] = {}
	if not roster.has("next_gear"):
		roster["next_gear"] = 1
	if not roster.has("pulls"):
		roster["pulls"] = 0
	if not roster.has("pity"):
		roster["pity"] = 0
	if int(roster.get("version", 0)) != VERSION or validate(roster) != "":
		return {}
	return roster
