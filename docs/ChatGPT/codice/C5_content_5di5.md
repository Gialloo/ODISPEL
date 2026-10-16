FILE battle_content.gd - PARTE 5 DI 5
Percorso: scripts/battle/battle_content.gd
(Codice GDScript, rientri con tab. Questa e' l'ultima parte: ora puoi analizzare tutto il file.)

```gdscript
static func compute_stats(entry: Dictionary) -> Dictionary:
	var def: Dictionary = CHARACTERS[str(entry.get("char", "kira"))]
	var base: Dictionary = CLASS_STATS[str(def["cls"])]
	var level: int = int(entry.get("level", 1))
	var rank: int = int(entry.get("rank", 0))
	var char_rarity: int = clampi(int(def.get("rarity", 0)), 0, RARITY_STAT_MULT.size() - 1)
	if bool(entry.get("flat_rarity", false)):      # PvP bilanciato: tutti come un comune
		char_rarity = 0
	var factor: float = (1.0 + LEVEL_BONUS * float(level - 1)) * (1.0 + rank_bonus(char_rarity) * float(rank)) * float(RARITY_STAT_MULT[char_rarity])
	var sm: Dictionary = def.get("stat_mult", {})
	var hp: float = float(base["hp"]) * factor * float(sm.get("hp", 1.0))
	var atk: float = float(base["atk"]) * factor * float(sm.get("atk", 1.0))
	var dfn: float = float(base["def"]) * factor * float(sm.get("def", 1.0))
	var spd: float = float(base["spd"]) * factor * float(sm.get("spd", 1.0))

	var xm: Dictionary = Expedition.stat_mult(entry)       # veterano (+) e ferito (-) dalla SPEDIZIONE
	hp *= float(xm["hp"])
	atk *= float(xm["atk"])
	var tm: Dictionary = Titles.stat_mult(entry)           # bonus permanenti dei TITOLI dell'account
	hp *= float(tm["hp"])
	atk *= float(tm["atk"])
	dfn *= float(tm["def"])

	if full_kit(entry):
		var kb: float = 1.0 + float(BattleTypes.KIT_BONUS_PCT) / 100.0
		hp *= kb
		atk *= kb
		dfn *= kb

	var gear: Array = entry.get("gear", [])
	for piece in gear:
		var slot: String = str(piece.get("slot", ""))
		if not GEAR_BASE.has(slot):
			continue
		var rarity: int = clampi(int(piece.get("rarity", 0)), 0, GEAR_RARITY_MULT.size() - 1)
		var glevel: int = int(piece.get("level", 1))
		var gmult: float = float(GEAR_RARITY_MULT[rarity]) * (1.0 + GEAR_LEVEL_BONUS * float(glevel - 1))
		var stats: Dictionary = GEAR_BASE[slot]
		hp += float(stats.get("hp", 0)) * gmult
		atk += float(stats.get("atk", 0)) * gmult
		dfn += float(stats.get("def", 0)) * gmult
		spd += float(stats.get("spd", 0)) * gmult

	for pid in entry.get("passives", []):
		var p: Dictionary = PASSIVES.get(str(pid), {})
		hp *= float(p.get("hp_mult", 1.0))
		atk *= float(p.get("atk_mult", 1.0))

	return {"hp": int(round(hp)), "atk": int(round(atk)), "def": int(round(dfn)), "spd": int(round(spd))}


# Equipaggiamento di base di un personaggio (innata + ultimate + passiva innata).
# Le skill di partenza: quella innata e, per la LibraCorp, Ricarica (senza munizioni il loro stile non funziona).
static func _default_skills(char_id: String) -> Array:
	# come prima (Attacco, Guardia, la skill del personaggio, Ricarica per i LibraCorp); gli slot che avanzano vanno alle abilita' uniche
	var list: Array = ["attack", "guard", str(CHARACTERS[char_id]["skill"])]
	if faction_of(char_id) == "libracorp":
		list.append("ricarica")
	list.append_array(Signatures.skills_for(char_id, 0))
	return list.slice(0, BattleTypes.SKILL_SLOTS)


static func default_entry(char_id: String, level: int = 1, rank: int = 0) -> Dictionary:
	var def: Dictionary = CHARACTERS[char_id]
	return {
		"char": char_id,
		"level": level,
		"rank": rank,
		"skills": _default_skills(char_id),
		"ult": str(def["ult"]),
		"passives": [str(def["passive"])],
		"gear": [],
	}


# Rarita' di un tiro da 1 a 100: 1-55 comune, 56-85 rara, 86-97 epica, 98-100 leggendaria.
static func rarity_for_roll(roll: int) -> int:
	if roll > 97:
		return 3
	if roll > 85:
		return 2
	if roll > 55:
		return 1
	return 0


# Quote di estrazione in percentuale (comune, rara, epica, leggendaria), calcolate dai tiri.
static func rarity_odds() -> Array:
	var odds: Array = [0, 0, 0, 0]
	for roll in range(1, 101):
		odds[rarity_for_roll(roll)] += 1
	return odds


# Rarita' estratta con un tiro (quote: rarity_odds).
# bonus: sposta il tiro verso le rarita' alte (i livelli di difficolta' lo usano).
static func roll_rarity(rng: RNGState, bonus: int = 0) -> int:
	return rarity_for_roll(mini(100, rng.random_int(1, 100) + bonus))


# Estrae le mosse e passive lasciate da un boss. Ogni premio e' {kind, id, rarity}.
static func roll_drops(boss_id: String, rng: RNGState, tier: int = 0) -> Array:
	var boss: Dictionary = BOSSES.get(boss_id, {})
	var drops: Array = []
	var t: int = clampi(tier, 0, TIERS.size() - 1)
	for i in int(boss.get("drops", 1)) + t:
		var rarity: int = roll_rarity(rng, t * 6)
		var pool: Array = []
		for id in MOVES:
			var m: Dictionary = MOVES[id]
			if str(m["kind"]) != "basic" and int(m["rarity"]) == rarity and not m.has("unique"):
				pool.append({"kind": "move", "id": id, "rarity": rarity})
		for id in PASSIVES:
			if int(PASSIVES[id]["rarity"]) == rarity:
				pool.append({"kind": "passive", "id": id, "rarity": rarity})
		if pool.is_empty():
			continue
		drops.append(pool[rng.random_index(pool.size())])
	return drops


# Estrae un pezzo di equipaggiamento: {kind: "gear", slot, rarity}.
static func roll_gear(rng: RNGState, tier: int = 0) -> Dictionary:
	var rarity: int = roll_rarity(rng, clampi(tier, 0, TIERS.size() - 1) * 6)
	var slot: String = str(BattleTypes.GEAR_SLOTS[rng.random_index(BattleTypes.GEAR_SLOTS.size())])
	return {"kind": "gear", "slot": slot, "rarity": rarity}


# Costo per salire di livello: {coins, nucleo} per i personaggi, {coins, lega} per i pezzi.
static func character_upgrade_cost(level: int) -> Dictionary:
	return {"coins": 50 * level, "nucleo": 1 + level / 3}


static func gear_upgrade_cost(rarity: int, level: int) -> Dictionary:
	return {"coins": 40 * level * (rarity + 1), "lega": 1 + (level / 3) * (rarity + 1)}


# Controllo di coerenza dei dati. Ritorna la lista degli errori trovati.
static func validate() -> Array:
	var errors: Array = []
	for id in CHARACTERS:
		var c: Dictionary = CHARACTERS[id]
		if int(c.get("rarity", -1)) < 0 or int(c.get("rarity", -1)) >= BattleTypes.RARITIES.size():
			errors.append("%s: rarita' non valida" % id)
		if not BattleTypes.COLORS.has(c["color"]):
			errors.append("%s: colore sconosciuto" % id)
		if not CLASS_STATS.has(c["cls"]):
			errors.append("%s: classe sconosciuta" % id)
		if not MOVES.has(c["skill"]):
			errors.append("%s: skill sconosciuta" % id)
		elif MOVES[c["skill"]]["kind"] != "skill":
			errors.append("%s: la skill non e' di tipo skill" % id)
		if not MOVES.has(c["ult"]):
			errors.append("%s: ultimate sconosciuta" % id)
		elif MOVES[c["ult"]]["kind"] != "ult":
			errors.append("%s: l'ultimate non e' di tipo ult" % id)
		if not PASSIVES.has(c["passive"]):
			errors.append("%s: passiva sconosciuta" % id)
	for id in BOSSES:
		for m in BOSSES[id]["cycle"]:
			if not BOSS_MOVES.has(m):
				errors.append("%s: mossa boss sconosciuta %s" % [id, m])
		var b: Dictionary = BOSSES[id]
		if not BattleTypes.COLORS.has(b.get("color", "")):
			errors.append("%s: colore del boss sconosciuto" % id)
		if not b.has("reward") or not b.has("name") or not b.has("desc") or not b.has("title"):
			errors.append("%s: boss incompleto (nome, titolo, descrizione, premi)" % id)
		if not BOSS_ORDER.has(id):
			errors.append("%s: boss fuori da BOSS_ORDER" % id)
	for id in BOSS_ORDER:
		if not BOSSES.has(id):
			errors.append("BOSS_ORDER: boss sconosciuto %s" % id)
	for id in BOSS_MOVES:
		if not ["one", "all", "weakest"].has(str(BOSS_MOVES[id]["target"])):
			errors.append("%s: bersaglio del boss sconosciuto" % id)
	return errors
```
