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
	"guard": {"name": "Guardia", "kind": "basic", "cost": 0, "priority": 1, "rarity": 0, "target": "self", "self_status": {"guard": 1}, "energy": 1, "ammo_gain": 1},
	"colpo_caricato": {"name": "Colpo caricato", "kind": "skill", "cost": 2, "priority": 0, "rarity": 0, "target": "enemy", "mult": 2.0},
	"marchio": {"name": "Marchio", "kind": "skill", "cost": 1, "priority": 0, "rarity": 0, "target": "enemy", "mult": 0.5, "status": {"mark": 2}},
	"provoca": {"name": "Provoca", "kind": "skill", "cost": 1, "priority": 1, "rarity": 0, "target": "self", "self_status": {"taunt": 1}, "shield": 0.6},
	"barriera": {"name": "Barriera", "kind": "skill", "cost": 2, "priority": 1, "rarity": 1, "target": "allies", "shield": 1.0},
	"cura": {"name": "Cura", "kind": "skill", "cost": 2, "priority": 0, "rarity": 1, "target": "ally", "heal": 1.4},
	"purifica": {"name": "Purifica", "kind": "skill", "cost": 1, "priority": 0, "rarity": 1, "target": "ally", "heal": 0.4, "cleanse": true},
	"ricarica": {"name": "Ricarica", "kind": "skill", "cost": 0, "priority": 1, "rarity": 0, "target": "self", "ammo_gain": 3, "energy": 1},
	"colpo_mirato": {"name": "Colpo mirato", "kind": "skill", "cost": 1, "priority": 0, "rarity": 1, "target": "enemy", "mult": 1.7, "ammo": 1, "pierce": 50},
	"colpo_alla_testa": {"name": "Colpo alla testa", "kind": "skill", "cost": 2, "priority": 0, "rarity": 2, "target": "enemy", "mult": 2.4, "ammo": 2, "pierce": 50},
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
# Un operatore piu' raro e' piu' forte di base: moltiplicatore delle statistiche
# per rarita' (comune, rara, epica, leggendaria). Sale come l'equipaggiamento.
const RARITY_STAT_MULT: Array = [1.0, 1.08, 1.18, 1.32]

# rarity: indice in BattleTypes.RARITIES (quanto e' raro da reclutare)
const CHARACTERS: Dictionary = {
	"kira": {"name": "Kira", "color": "viola", "cls": "striker", "rarity": 1, "skill": "colpo_caricato", "ult": "spezzatutto", "passive": "p_atk", "faction": "rondini"},
	"dax": {"name": "Dax", "color": "rosso", "cls": "vanguard", "rarity": 0, "skill": "provoca", "ult": "bastione", "passive": "p_hp", "faction": "libracorp"},
	"elle": {"name": "Elle", "color": "verde", "cls": "warden", "rarity": 0, "skill": "cura", "ult": "rinascita", "passive": "p_swap", "faction": "magabondi"},
	"bruno": {"name": "Bruno", "color": "blu", "cls": "vanguard", "rarity": 0, "skill": "barriera", "ult": "bastione", "passive": "p_hp", "faction": "libracorp"},
	"nova": {"name": "Nova", "color": "giallo", "cls": "striker", "rarity": 1, "skill": "marchio", "ult": "spezzatutto", "passive": "p_hunter", "faction": "rondini"},
	"mira": {"name": "Mira", "color": "blu", "cls": "warden", "rarity": 1, "skill": "purifica", "ult": "rinascita", "passive": "p_swap", "faction": "libracorp"},
	"rex": {"name": "Rex", "color": "rosso", "cls": "striker", "rarity": 0, "skill": "colpo_caricato", "ult": "spezzatutto", "passive": "p_atk", "faction": "rondini"},
	"ivo": {"name": "Ivo", "color": "blu", "cls": "striker", "rarity": 1, "skill": "marchio", "ult": "spezzatutto", "passive": "p_swap", "faction": "magabondi", "style": "atipico"},
	"sera": {"name": "Sera", "color": "verde", "cls": "warden", "rarity": 2, "skill": "barriera", "ult": "rinascita", "passive": "p_hunter", "faction": "rondini"},
	"tana": {"name": "Tana", "color": "giallo", "cls": "vanguard", "rarity": 3, "skill": "provoca", "ult": "bastione", "passive": "p_hunter", "faction": "libracorp"},
}

# Fazione e stile di un operatore (campi opzionali "faction" e "style" in CHARACTERS; l'entry del roster puo' avere
# gli stessi campi e ha la precedenza). Senza fazione: "" e niente aure.
static func faction_of(char_id: String, entry: Dictionary = {}) -> String:
	var def: Dictionary = CHARACTERS.get(char_id, {})
	return str(entry.get("faction", def.get("faction", "")))


static func style_of(char_id: String, entry: Dictionary = {}) -> String:
	var def: Dictionary = CHARACTERS.get(char_id, {})
	return str(entry.get("style", def.get("style", "ortodosso")))


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
# target "one": un giocatore scelto a caso e annunciato; "weakest": il piu' ferito
# (annunciato); "all": tutti i giocatori.
# Opzioni: "status" (sui bersagli), "self_shield" (scudo al boss, frazione dei PV
# massimi), "drain" (il boss recupera questa frazione del danno inflitto).
const BOSS_MOVES: Dictionary = {
	"scarica": {"name": "Scarica", "target": "one", "mult": 1.6},
	"raffica": {"name": "Raffica", "target": "all", "mult": 0.7},
	"scossa": {"name": "Scossa", "target": "one", "mult": 0.9, "status": {"bleed": 3}},
	"sovraccarico": {"name": "Sovraccarico", "target": "all", "mult": 1.2},
	"lampeggio": {"name": "Lampeggio", "target": "all", "mult": 0.55, "status": {"mark": 2}},
	"rosso": {"name": "Rosso", "target": "one", "mult": 1.9},
	"giallo": {"name": "Giallo", "target": "weakest", "mult": 0.7, "self_shield": 0.06},
	"verde": {"name": "Verde", "target": "all", "mult": 0.95},
	"gorgo": {"name": "Gorgo", "target": "one", "mult": 1.7},
	"risucchio": {"name": "Risucchio", "target": "weakest", "mult": 0.9, "drain": 0.6},
	"alluvione": {"name": "Alluvione", "target": "all", "mult": 0.6, "status": {"bleed": 3}},
	"chiusura": {"name": "Chiusura", "target": "all", "mult": 0.45, "self_shield": 0.05},
	"squillo": {"name": "Squillo", "target": "all", "mult": 0.5, "status": {"mark": 2}},
	"chiamata": {"name": "Chiamata", "target": "one", "mult": 1.8},
	"interferenza": {"name": "Interferenza", "target": "all", "mult": 0.85, "status": {"bleed": 3}, "self_shield": 0.04},
	"linea_occupata": {"name": "Linea occupata", "target": "weakest", "mult": 0.8, "drain": 0.5},
}

# Livelli di difficolta': moltiplicano PV e ATK del boss, aggiungono difesa e premi.
const TIERS: Array = [
	{"id": "normale", "name": "NORMALE", "hp": 1.0, "atk": 1.0, "def": 0, "reward": 1.0},
	{"id": "difficile", "name": "DIFFICILE", "hp": 1.5, "atk": 1.25, "def": 8, "reward": 1.7},
	{"id": "incubo", "name": "INCUBO", "hp": 2.1, "atk": 1.55, "def": 15, "reward": 2.6},
]

# Ordine di sblocco: si apre il boss successivo battendo il precedente (almeno a NORMALE).
const BOSS_ORDER: Array = ["distributore", "semaforo", "tombino", "cabina"]

const BOSSES: Dictionary = {
	"distributore": {
		"name": "Distributore", "title": "CLASSE ANOMALIA · MINACCIA BASSA", "color": "giallo", "hp_per_player": 900,
		"atk": 390, "def": 25, "spd": 105,
		"desc": "Un distributore automatico impazzito. Colpi pesanti a un solo bersaglio e scosse che fanno sanguinare.",
		"cycle": ["scarica", "raffica", "scossa", "sovraccarico"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 2,
		"reward": {"coins": 300, "nucleo": [2, 4], "lega": [1, 3], "gear_chance": 40},
	},
	"semaforo": {
		"name": "Semaforo", "title": "CLASSE ANOMALIA · MINACCIA MEDIA", "color": "rosso", "hp_per_player": 850,
		"atk": 380, "def": 20, "spd": 118,
		"desc": "Un semaforo che non cambia piu' colore. Veloce: agisce prima di quasi tutti. Marchia la squadra e punta chi e' piu' ferito.",
		"cycle": ["lampeggio", "rosso", "giallo", "verde"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 2,
		"reward": {"coins": 450, "nucleo": [3, 5], "lega": [2, 4], "gear_chance": 50},
	},
	"tombino": {
		"name": "Tombino", "title": "CLASSE ANOMALIA · MINACCIA ALTA", "color": "viola", "hp_per_player": 1000,
		"atk": 340, "def": 35, "spd": 82,
		"desc": "Qualcosa vive sotto il tombino. Lento ma resistente: si cura risucchiando i feriti e si chiude sotto uno scudo.",
		"cycle": ["gorgo", "risucchio", "alluvione", "chiusura"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 3,
		"reward": {"coins": 650, "nucleo": [4, 7], "lega": [3, 6], "gear_chance": 60},
	},
	"cabina": {
		"name": "Cabina", "title": "CLASSE ANOMALIA · MINACCIA CRITICA", "color": "blu", "hp_per_player": 1100,
		"atk": 360, "def": 30, "spd": 96,
		"desc": "Una cabina telefonica che squilla da sola. Marchia la squadra, chiama un bersaglio con un colpo pesante e si nutre di chi e' gia' ferito.",
		"cycle": ["squillo", "chiamata", "interferenza", "linea_occupata"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 3,
		"reward": {"coins": 850, "nucleo": [5, 8], "lega": [4, 7], "gear_chance": 70},
	},
}


static func tier_of(tier: int) -> Dictionary:
	return TIERS[clampi(tier, 0, TIERS.size() - 1)]


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
	var char_rarity: int = clampi(int(def.get("rarity", 0)), 0, RARITY_STAT_MULT.size() - 1)
	var factor: float = (1.0 + LEVEL_BONUS * float(level - 1)) * (1.0 + RANK_BONUS * float(rank)) * float(RARITY_STAT_MULT[char_rarity])
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
# Le skill di partenza: quella innata e, per la LibraCorp, Ricarica (senza munizioni il loro stile non funziona).
static func _default_skills(char_id: String) -> Array:
	var skills: Array = [str(CHARACTERS[char_id]["skill"])]
	if faction_of(char_id) == "libracorp":
		skills.append("ricarica")
	return skills


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
