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
const STARTER_TEAM: Array = ["kira", "dax", "elle", "bruno"]


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
		"cleared": {},
		"faction_sync": 1,
	}
	for id in STARTER_CHARACTERS:
		add_character(roster, str(id))
	set_team(roster, STARTER_TEAM)
	return roster


# ---------- Possesso ----------

static func owns(roster: Dictionary, char_id: String) -> bool:
	return roster["characters"].has(char_id)


# Copie necessarie per salire dal rank r al rank r+1.
const RANK_COPY_COST: Array = [1, 1, 2, 2, 3]


static func rank_cost(rank: int) -> int:
	return int(RANK_COPY_COST[clampi(rank, 0, RANK_COPY_COST.size() - 1)])


# Copie di un operatore che non sono ancora state spese in un RANK UP.
static func copies(roster: Dictionary, char_id: String) -> int:
	if not owns(roster, char_id):
		return 0
	return maxi(0, int(roster["characters"][char_id].get("copies", 0)))


static func can_rank_up(roster: Dictionary, char_id: String) -> bool:
	if not owns(roster, char_id):
		return false
	var rank: int = int(roster["characters"][char_id].get("rank", 0))
	return rank < MAX_RANK and copies(roster, char_id) >= rank_cost(rank)


# Spende le copie e porta l'operatore al rank successivo. Il rank non sale mai da solo.
static func rank_up(roster: Dictionary, char_id: String) -> bool:
	if not can_rank_up(roster, char_id):
		return false
	var entry: Dictionary = roster["characters"][char_id]
	entry["copies"] = copies(roster, char_id) - rank_cost(int(entry["rank"]))
	entry["rank"] = int(entry["rank"]) + 1
	return true


# Nuovo personaggio, oppure una copia in piu': si conserva (poi si spende col RANK UP).
# Ritorna "new", "copy" oppure "max" (rank gia' al massimo: la copia diventa monete) o "" se sconosciuto.
static func add_character(roster: Dictionary, char_id: String) -> String:
	if not BattleContent.CHARACTERS.has(char_id):
		return ""
	if owns(roster, char_id):
		var entry: Dictionary = roster["characters"][char_id]
		if int(entry["rank"]) >= MAX_RANK:
			return "max"
		entry["copies"] = copies(roster, char_id) + 1
		return "copy"
	var fresh: Dictionary = BattleContent.default_entry(char_id)
	roster["characters"][char_id] = fresh
	# la mossa, l'ultimate e la passiva innate sono sempre possedute
	for sk in fresh["skills"]:
		if not BattleTypes.BASIC_MOVES.has(str(sk)) and not Signatures.skills_for(char_id, 0).has(str(sk)):
			_inventory_add(roster["moves"], str(sk))
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


# Gli operatori posseduti piu' forti (rarita', poi livello, poi rank), al massimo TEAM_SIZE.
static func best_team(roster: Dictionary) -> Array:
	var ids: Array = roster["characters"].keys()
	ids.sort()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ca: Dictionary = roster["characters"][a]
		var cb: Dictionary = roster["characters"][b]
		var ra: int = int(BattleContent.CHARACTERS[a]["rarity"])
		var rb: int = int(BattleContent.CHARACTERS[b]["rarity"])
		if ra != rb:
			return ra > rb
		if int(ca["level"]) != int(cb["level"]):
			return int(ca["level"]) > int(cb["level"])
		return int(ca.get("rank", 0)) > int(cb.get("rank", 0)))
	return ids.slice(0, BattleTypes.TEAM_SIZE)


static func team_entries(roster: Dictionary) -> Array:
	var out: Array = []
	var icons: Array = Profile.owned_icons()
	var act: Array = Titles.active(roster, icons)       # una volta sola per tutta la squadra
	for id in roster["team"]:
		var e: Dictionary = roster["characters"][id].duplicate(true)
		e.erase("copies")          # le copie non spese sono affari del salvataggio, non della battaglia
		Expedition.decorate_entry(roster, e)
		Titles.decorate_entry(roster, e, icons, act)
		Extras.decorate_entry(roster, e)
		out.append(e)
	return out


# Personaggi posseduti fuori squadra: i compagni IA nelle partite in solitaria.
static func spare_entries(roster: Dictionary) -> Array:
	var out: Array = []
	var ids: Array = roster["characters"].keys()
	ids.sort()
	var icons: Array = Profile.owned_icons()
	var act: Array = Titles.active(roster, icons)
	for id in ids:
		if not roster["team"].has(id):
			var e: Dictionary = roster["characters"][id].duplicate(true)
			e.erase("copies")
			Titles.decorate_entry(roster, e, icons, act)
			Extras.decorate_entry(roster, e)
			out.append(e)
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


static func _basic_count(skills: Array) -> int:
	var n: int = 0
	for m in skills:
		n += 1 if BattleTypes.BASIC_MOVES.has(str(m)) else 0
	return n


# Mette una skill nello slot (0..SKILL_SLOTS-1). id "" svuota lo slot.
static func equip_skill(roster: Dictionary, char_id: String, slot: int, move_id: String) -> bool:
	if not owns(roster, char_id) or slot < 0 or slot >= BattleTypes.SKILL_SLOTS:
		return false
	var skills: Array = roster["characters"][char_id]["skills"]
	var after: Array = skills.duplicate()
	if move_id == "":
		if slot < after.size():
			after.remove_at(slot)
	else:
		if slot > skills.size():
			return false
		var basic: bool = BattleTypes.BASIC_MOVES.has(move_id)
		var kind: String = str(BattleContent.MOVES[move_id]["kind"]) if BattleContent.MOVES.has(move_id) else ""
		if kind != "skill" and not basic:
			return false
		var mine: bool = str(BattleContent.MOVES[move_id].get("unique", "")) == char_id
		if BattleContent.MOVES[move_id].has("unique") and not mine:
			return false      # l'abilita' unica e' solo del suo personaggio
		if not basic and not mine and int(roster["moves"].get(move_id, 0)) <= _used(roster, "skills", move_id, char_id, slot):
			return false
		for i in skills.size():
			if i != slot and str(skills[i]) == move_id:
				return false
		if slot == after.size():
			after.append(move_id)
		else:
			after[slot] = move_id
	if _basic_count(after) == 0:
		return false          # almeno una mossa base (Attacco o Guardia) resta sempre nel kit
	roster["characters"][char_id]["skills"] = after
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


# Cambia lo stile (ortodosso/atipico). Ha senso solo per chi appartiene a una fazione. Gratuito: e' una scelta di strategia.
static func set_style(roster: Dictionary, char_id: String, style: String) -> bool:
	if not owns(roster, char_id) or not Factions.STYLES.has(style):
		return false
	if BattleContent.faction_of(char_id) == "":
		return false
	roster["characters"][char_id]["style"] = style
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
	# fazione e rarita' vengono dalla definizione: una squadra ricevuta dalla rete non puo' truccarle
	var def: Dictionary = BattleContent.CHARACTERS[char_id]
	if entry.has("faction") and str(entry["faction"]) != str(def.get("faction", "")):
		return "fazione non valida"
	if entry.has("rarity") and int(entry["rarity"]) != int(def["rarity"]):
		return "rarita' non valida"
	if entry.has("style") and not Factions.STYLES.has(str(entry["style"])):
		return "stile non valido"
	if int(entry.get("vet", 0)) < 0 or int(entry.get("vet", 0)) > Expedition.VET_MAX:
		return "veterano non valido"
	if entry.has("acc"):
		if not (entry["acc"] is Dictionary):
			return "bonus titoli non valido"
		for k in (entry["acc"] as Dictionary):
			if not Titles.STATS.has(str(k)) or int(entry["acc"][k]) < 0 or int(entry["acc"][k]) > Titles.MAX_BP:
				return "bonus titoli non valido"
	if not Extras.mastery_valid(entry):
		return "maestria non valida"
	var skills: Array = entry.get("skills", [])
	if skills.size() > BattleTypes.SKILL_SLOTS:
		return "troppe skill"
	var seen: Dictionary = {}
	for m in skills:
		if not BattleContent.MOVES.has(str(m)) or (str(BattleContent.MOVES[str(m)]["kind"]) != "skill" and not BattleTypes.BASIC_MOVES.has(str(m))):
			return "skill non valida"
		if BattleContent.MOVES[str(m)].has("unique") and str(BattleContent.MOVES[str(m)]["unique"]) != str(entry.get("char", "")):
			return "abilita' unica di un altro personaggio"
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
	var cleared_err: String = _validate_cleared(roster.get("cleared", {}))
	if cleared_err != "":
		return cleared_err
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


static func _validate_cleared(cleared: Variant) -> String:
	if not (cleared is Dictionary):
		return "progressi non validi"
	for id in cleared:
		if not BattleContent.BOSSES.has(str(id)):
			return "progressi: boss sconosciuto %s" % id
		var n: Variant = cleared[id]
		if not (n is int) or int(n) < 0 or int(n) > BattleContent.TIERS.size():
			return "progressi: valore non valido per %s" % id
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
		if str(drop.get("kind", "")) == "icon":
			# icona gia' posseduta: non succede nulla (le monete dei premi restano esatte)
			if Profile.unlock(str(drop.get("id", ""))):
				applied += 1
			continue
		if str(drop.get("kind", "")) == "gear":
			if new_gear(roster, str(drop.get("slot", "")), int(drop.get("rarity", -1))) != "":
				applied += 1
		elif add_drop(roster, drop):
			applied += 1
	return applied


# ---------- Battaglia ----------

# Partita in solitaria: solo il tuo party (front row + back row), niente alleati assegnati dall'IA.
static func create_solo_battle(roster: Dictionary, player_name: String, boss_id: String, seed_value: int, ai_count: int = 0, tier: int = 0) -> Dictionary:
	var state: Dictionary = BattleState.create_solo(player_name, team_entries(roster), [], boss_id, seed_value, ai_count, tier)
	state["known"] = Discoveries.known(roster)
	return state


# ---------- Progressi e sblocchi ----------

# Alcuni boss, una volta battuti (anche solo a NORMALE), portano un nuovo alleato nella storia.
# Idempotente: si puo' richiamare a ogni caricamento (chi aveva gia' battuto il boss lo riceve).
static func grant_story_allies(roster: Dictionary) -> void:
	for boss_id in BattleContent.BOSS_ORDER:
		var ally: String = str(BattleContent.BOSSES.get(boss_id, {}).get("ally", ""))
		if ally == "" or cleared_tiers(roster, str(boss_id)) < 1:
			continue
		if BattleContent.CHARACTERS.has(ally) and not owns(roster, ally):
			add_character(roster, ally)


# Quanti livelli di difficolta' di un boss sono stati battuti (0..3).
static func cleared_tiers(roster: Dictionary, boss_id: String) -> int:
	return int(roster.get("cleared", {}).get(boss_id, 0))


# Registra una vittoria: sblocca il livello di difficolta' successivo. Ritorna true se e' un progresso nuovo.
static func mark_cleared(roster: Dictionary, boss_id: String, tier: int) -> bool:
	if not BattleContent.BOSSES.has(boss_id) or tier < 0 or tier >= BattleContent.TIERS.size():
		return false
	if not roster.has("cleared"):
		roster["cleared"] = {}
	if cleared_tiers(roster, boss_id) >= tier + 1:
		return false
	roster["cleared"][boss_id] = tier + 1
	grant_story_allies(roster)
	return true


# Cosa si e' sbloccato battendo `boss_id` al livello `tier` per la prima volta.
static func unlock_news(boss_id: String, tier: int) -> Array:
	var news: Array = []
	var ally: String = str(BattleContent.BOSSES.get(boss_id, {}).get("ally", ""))
	if tier == 0 and ally != "":
		news.append("NUOVO ALLEATO: %s si unisce alla squadra" % str(BattleContent.CHARACTERS[ally]["name"]).to_upper())
	if tier + 1 < BattleContent.TIERS.size():
		news.append("LIVELLO %s SBLOCCATO: %s" % [str(BattleContent.TIERS[tier + 1]["name"]), MissionConfig.boss_title(boss_id)])
	var index: int = BattleContent.BOSS_ORDER.find(boss_id)
	if tier == 0 and index >= 0 and index + 1 < BattleContent.BOSS_ORDER.size():
		news.append("NUOVO BERSAGLIO: %s" % MissionConfig.boss_title(str(BattleContent.BOSS_ORDER[index + 1])))
	return news


# Il primo boss e' sempre aperto; gli altri si aprono battendo il precedente (almeno a NORMALE).
static func is_boss_unlocked(roster: Dictionary, boss_id: String) -> bool:
	var i: int = BattleContent.BOSS_ORDER.find(boss_id)
	if i < 0:
		return false
	if i == 0:
		return true
	return cleared_tiers(roster, str(BattleContent.BOSS_ORDER[i - 1])) >= 1


# NORMALE e' aperto con il boss; ogni livello successivo si apre battendo quello prima.
static func is_tier_unlocked(roster: Dictionary, boss_id: String, tier: int) -> bool:
	if tier < 0 or tier >= BattleContent.TIERS.size() or not is_boss_unlocked(roster, boss_id):
		return false
	return tier <= cleared_tiers(roster, boss_id)


# ---------- JSON ----------

# Salvataggi scritti prima delle munizioni: gli operatori LibraCorp ricevono Ricarica se hanno uno slot libero.
# Vecchi salvataggi: Attacco e Guardia erano fissi, ora stanno negli slot.
static func migrate_kits(roster: Dictionary) -> void:
	var chars: Variant = roster.get("characters", {})
	if not (chars is Dictionary):
		return
	for id in chars:
		var entry: Dictionary = chars[id]
		var skills: Variant = entry.get("skills", null)
		if skills is Array and _basic_count(skills) == 0:
			entry["skills"] = BattleState.kit_of(skills, Signatures.skills_for(str(entry.get("char", id)), int(entry.get("rank", 0))))


static func sync_faction_moves(roster: Dictionary) -> void:
	var chars: Variant = roster.get("characters", {})
	if not (chars is Dictionary) or not (roster.get("moves", null) is Dictionary) or int(roster.get("faction_sync", 0)) >= 1:
		return
	roster["faction_sync"] = 1     # una volta sola: se poi il giocatore la toglie, non torna
	for id in chars:
		if not BattleContent.CHARACTERS.has(str(id)) or BattleContent.faction_of(str(id)) != "libracorp":
			continue
		var skills: Variant = chars[id].get("skills", null)
		if skills is Array and skills.size() < BattleTypes.SKILL_SLOTS and not skills.has("ricarica"):
			skills.append("ricarica")
			_inventory_add(roster["moves"], "ricarica")


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
	if not roster.has("cleared"):
		roster["cleared"] = {}
	sync_faction_moves(roster)
	migrate_kits(roster)
	grant_story_allies(roster)
	if int(roster.get("version", 0)) != VERSION or validate(roster) != "":
		return {}
	return roster
