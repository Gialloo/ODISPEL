class_name BattleContent
extends RefCounted

# Dati di gioco del nuovo motore: mosse, passive, personaggi, equipaggiamento, boss.
# Tutto e' dato statico: per aggiungere contenuti basta aggiungere voci qui.

# kind: basic | skill | ult
# target: enemy | self | ally | allies
# cost: energia (skill). Le ultimate costano la barra piena.
# rarity: indice in BattleTypes.RARITIES
const MOVES: Dictionary = {
	"attack": {"name": "Attacco", "kind": "basic", "cost": 0, "priority": 0, "rarity": 0, "target": "enemy", "mult": 1.0},
	"guard": {"name": "Guardia", "kind": "basic", "cost": 0, "priority": 1, "rarity": 0, "target": "self", "self_status": {"guard": 1}, "energy": 1},
	"colpo_caricato": {"name": "Colpo caricato", "kind": "skill", "cost": 2, "priority": 0, "rarity": 0, "target": "enemy", "mult": 2.0},
	"marchio": {"name": "Marchio", "kind": "skill", "cost": 1, "priority": 0, "rarity": 0, "target": "enemy", "mult": 0.5, "status": {"mark": 2}},
	"provoca": {"name": "Provoca", "kind": "skill", "cost": 1, "priority": 1, "rarity": 0, "target": "self", "self_status": {"taunt": 1}, "shield": 0.6},
	"barriera": {"name": "Barriera", "kind": "skill", "cost": 2, "priority": 1, "rarity": 1, "target": "allies", "shield": 1.0},
	"cura": {"name": "Cura", "kind": "skill", "cost": 2, "priority": 0, "rarity": 1, "target": "ally", "heal": 1.4},
	"purifica": {"name": "Purifica", "kind": "skill", "cost": 1, "priority": 0, "rarity": 1, "target": "ally", "heal": 0.4, "cleanse": true},
	"spezzatutto": {"name": "Spezzatutto", "kind": "ult", "cost": 0, "priority": 0, "rarity": 2, "target": "enemy", "mult": 4.5},
	"bastione": {"name": "Bastione", "kind": "ult", "cost": 0, "priority": 1, "rarity": 2, "target": "allies", "shield": 2.0},
	"rinascita": {"name": "Rinascita", "kind": "ult", "cost": 0, "priority": 0, "rarity": 3, "target": "allies", "heal": 1.5, "cleanse": true},
}

# Passive: bonus statistici (moltiplicatori) o effetti a evento.
const PASSIVES: Dictionary = {
	"p_atk": {"name": "Furia", "rarity": 0, "atk_mult": 1.10},
	"p_hp": {"name": "Tempra", "rarity": 0, "hp_mult": 1.10},
	"p_swap": {"name": "Entrata scudata", "rarity": 1, "on_enter_shield": 0.6},
	"p_hunter": {"name": "Cacciatore", "rarity": 2, "hunter": true},
}

# Statistiche base per classe: hp, atk, def, spd.
const CLASS_STATS: Dictionary = {
	"striker": {"hp": 900, "atk": 100, "def": 20, "spd": 110},
	"vanguard": {"hp": 1300, "atk": 80, "def": 50, "spd": 90},
	"warden": {"hp": 1000, "atk": 80, "def": 30, "spd": 100},
}
const LEVEL_BONUS: float = 0.08
const RANK_BONUS: float = 0.05

const CHARACTERS: Dictionary = {
	"kira": {"name": "Kira", "color": "viola", "cls": "striker", "skill": "colpo_caricato", "ult": "spezzatutto", "passive": "p_atk"},
	"dax": {"name": "Dax", "color": "rosso", "cls": "vanguard", "skill": "provoca", "ult": "bastione", "passive": "p_hp"},
	"elle": {"name": "Elle", "color": "verde", "cls": "warden", "skill": "cura", "ult": "rinascita", "passive": "p_swap"},
	"bruno": {"name": "Bruno", "color": "blu", "cls": "vanguard", "skill": "barriera", "ult": "bastione", "passive": "p_hp"},
	"nova": {"name": "Nova", "color": "giallo", "cls": "striker", "skill": "marchio", "ult": "spezzatutto", "passive": "p_hunter"},
	"mira": {"name": "Mira", "color": "blu", "cls": "warden", "skill": "purifica", "ult": "rinascita", "passive": "p_swap"},
}

# Equipaggiamento: valore base per slot, moltiplicato da rarita' e livello.
const GEAR_BASE: Dictionary = {
	"arma": {"atk": 12},
	"petto": {"hp": 140, "def": 6},
	"stivali": {"spd": 8},
}
const GEAR_RARITY_MULT: Array = [1.0, 1.3, 1.7, 2.2]
const GEAR_LEVEL_BONUS: float = 0.10
# Livello massimo di un pezzo, per rarita'.
const GEAR_MAX_LEVEL: Array = [10, 15, 20, 30]

# Materiali per potenziare: Nucleo (personaggi), Lega (pezzi).
const MATERIALS: Dictionary = {"nucleo": "Nucleo", "lega": "Lega"}

# Boss. Il ciclo di mosse e' annunciato un round prima.
# target "one": un giocatore scelto e annunciato; "all": tutti i giocatori.
const BOSS_MOVES: Dictionary = {
	"scarica": {"name": "Scarica", "target": "one", "mult": 1.6},
	"raffica": {"name": "Raffica", "target": "all", "mult": 0.7},
	"scossa": {"name": "Scossa", "target": "one", "mult": 0.9, "status": {"bleed": 3}},
	"sovraccarico": {"name": "Sovraccarico", "target": "all", "mult": 1.2},
}
const BOSSES: Dictionary = {
	"distributore": {
		"name": "Distributore", "color": "giallo", "hp_per_player": 900,
		"atk": 390, "def": 25, "spd": 105,
		"cycle": ["scarica", "raffica", "scossa", "sovraccarico"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 2,
		"reward": {"coins": 300, "nucleo": [2, 4], "lega": [1, 3], "gear_chance": 40},
	},
}


static func has_move(id: String) -> bool:
	return MOVES.has(id)


static func rarity_of(kind: String, id: String) -> int:
	var table: Dictionary = MOVES if kind != "passive" else PASSIVES
	if not table.has(id):
		return 0
	var entry: Dictionary = table[id]
	return int(entry.get("rarity", 0))


# Statistiche calcolate di un personaggio del roster.
# entry: {char, level, rank, skills, ult, passives, gear:[{slot, rarity, level}]}
static func compute_stats(entry: Dictionary) -> Dictionary:
	var def: Dictionary = CHARACTERS[str(entry.get("char", "kira"))]
	var base: Dictionary = CLASS_STATS[str(def["cls"])]
	var level: int = int(entry.get("level", 1))
	var rank: int = int(entry.get("rank", 0))
	var factor: float = (1.0 + LEVEL_BONUS * float(level - 1)) * (1.0 + RANK_BONUS * float(rank))
	var hp: float = float(base["hp"]) * factor
	var atk: float = float(base["atk"]) * factor
	var dfn: float = float(base["def"]) * factor
	var spd: float = float(base["spd"]) * factor

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
static func default_entry(char_id: String, level: int = 1, rank: int = 0) -> Dictionary:
	var def: Dictionary = CHARACTERS[char_id]
	return {
		"char": char_id,
		"level": level,
		"rank": rank,
		"skills": [str(def["skill"])],
		"ult": str(def["ult"]),
		"passives": [str(def["passive"])],
		"gear": [],
	}


# Rarita' estratta con un tiro: 45% comune, 30% rara, 22% epica, 3% leggendaria.
static func _roll_rarity(rng: RNGState) -> int:
	var roll: int = rng.random_int(1, 100)
	if roll > 97:
		return 3
	if roll > 85:
		return 2
	if roll > 55:
		return 1
	return 0


# Estrae le mosse e passive lasciate da un boss. Ogni premio e' {kind, id, rarity}.
static func roll_drops(boss_id: String, rng: RNGState) -> Array:
	var boss: Dictionary = BOSSES.get(boss_id, {})
	var drops: Array = []
	for i in int(boss.get("drops", 1)):
		var rarity: int = _roll_rarity(rng)
		var pool: Array = []
		for id in MOVES:
			var m: Dictionary = MOVES[id]
			if str(m["kind"]) != "basic" and int(m["rarity"]) == rarity:
				pool.append({"kind": "move", "id": id, "rarity": rarity})
		for id in PASSIVES:
			if int(PASSIVES[id]["rarity"]) == rarity:
				pool.append({"kind": "passive", "id": id, "rarity": rarity})
		if pool.is_empty():
			continue
		drops.append(pool[rng.random_index(pool.size())])
	return drops


# Estrae un pezzo di equipaggiamento: {kind: "gear", slot, rarity}.
static func roll_gear(rng: RNGState) -> Dictionary:
	var rarity: int = _roll_rarity(rng)
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
	return errors
