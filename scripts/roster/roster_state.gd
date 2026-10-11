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
#   passives: {passive_id: copie}
# }

const VERSION: int = 1
const MAX_LEVEL: int = 50
const MAX_RANK: int = 5
const STARTER_CHARACTERS: Array = ["kira", "dax", "elle", "bruno", "nova", "mira"]
const STARTER_TEAM: Array = ["kira", "dax", "elle"]


static func new_roster() -> Dictionary:
	var roster: Dictionary = {
		"version": VERSION,
		"coins": 0,
		"characters": {},
		"team": [],
		"moves": {},
		"passives": {},
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
	if int(roster.get("version", 0)) != VERSION or validate(roster) != "":
		return {}
	return roster
