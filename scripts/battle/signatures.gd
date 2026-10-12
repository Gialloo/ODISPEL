class_name Signatures
extends RefCounted

# Ogni operatore ha una PASSIVA UNICA e 1 o 2 ABILITA' UNICHE, pensate per il suo ruolo e la sua rarita':
#   comune / rara    -> 1 abilita' unica (sempre disponibile)
#   epica / leggendaria -> 2 abilita' uniche (la seconda si sblocca a rank 3)
# Il RANK (le copie) le potenzia: la passiva sale del 15% a rank; a rank 5 c'e' il RISVEGLIO
# (ultimate +25% e +25 di carica a inizio battaglia).
# Le mosse uniche non si trovano come premio: appartengono al personaggio.

const PASSIVE_RANK_SCALE: float = 0.15
const SECOND_SKILL_RANK: int = 3
const AWAKEN_RANK: int = 5
const AWAKEN_ULT: float = 1.25
const AWAKEN_GAUGE: int = 25

# key -> come si legge il valore nel testo (%s = percentuale)
const KEY_TEXT: Dictionary = {
	"dmg_vs_mark": "+%s%% di danno ai bersagli marchiati",
	"thorns": "chi lo colpisce subisce %s%% del suo ATK",
	"regen": "recupera %s%% dei PV massimi a fine round",
	"round_shield": "inizia ogni round con uno scudo del %s%% dei PV massimi",
	"crit_marked": "+%s%% di critico contro i bersagli marchiati",
	"heal_shield": "le sue cure danno anche uno scudo pari al %s%% della cura",
	"low_hp_atk": "+%s%% di danno sotto meta' PV",
	"lifesteal": "recupera il %s%% del danno inflitto",
	"link_boost": "i suoi LINK danno +%s%% di danno in piu' per anello",
	"gauge_regen": "+%s di ultimate a fine round",
	"guard_shield": "Guardia da' uno scudo del %s%% dei PV massimi",
}

# base: valore a rank 0 (frazione, tranne gauge_regen e crit_marked che sono punti)
const PASSIVES: Dictionary = {
	"kira": {"name": "Scintilla viola", "key": "dmg_vs_mark", "base": 0.15},
	"dax": {"name": "Muro di spine", "key": "thorns", "base": 0.25},
	"elle": {"name": "Mano gentile", "key": "regen", "base": 0.04},
	"bruno": {"name": "Scudo reattivo", "key": "round_shield", "base": 0.08},
	"nova": {"name": "Occhio di falco", "key": "crit_marked", "base": 0.15},
	"mira": {"name": "Protocollo salute", "key": "heal_shield", "base": 0.30},
	"rex": {"name": "Sangue caldo", "key": "low_hp_atk", "base": 0.25},
	"ivo": {"name": "Colpo storto", "key": "lifesteal", "base": 0.12},
	"sera": {"name": "Soffio d'ali", "key": "link_boost", "base": 0.10},
	"eco": {"name": "Risonanza", "key": "gauge_regen", "base": 8.0},
	"tana": {"name": "Fortezza", "key": "guard_shield", "base": 0.20},
}

# Abilita' uniche (id -> mossa). "unique" = personaggio proprietario.
const MOVES: Dictionary = {
	"u_kira_a": {"name": "Taglio spettrale", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.8, "pierce": 60, "status": {"mark": 1},
		"bonus": {"stat": "crit", "pct": 20}, "unique": "kira"},
	"u_dax_a": {"name": "Ariete", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.3, "self_status": {"taunt": 1, "guard": 1},
		"bonus": {"stat": "def", "pct": 25}, "unique": "dax"},
	"u_elle_a": {"name": "Respiro", "kind": "skill", "cost": 3, "priority": 0, "target": "allies", "heal": 0.9,
		"bonus": {"stat": "max_hp", "pct": 4}, "unique": "elle"},
	"u_bruno_a": {"name": "Parata lampo", "kind": "skill", "cost": 1, "priority": 2, "target": "ally", "shield": 1.2,
		"bonus": {"stat": "def", "pct": 20}, "unique": "bruno"},
	"u_nova_a": {"name": "Raffica marchiante", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.2, "status": {"mark": 2, "bleed": 2},
		"bonus": {"stat": "crit", "pct": 18}, "unique": "nova"},
	"u_mira_a": {"name": "Iniezione", "kind": "skill", "cost": 2, "priority": 0, "target": "ally", "heal": 1.0, "shield": 0.6, "cleanse": true,
		"bonus": {"stat": "max_hp", "pct": 5}, "unique": "mira"},
	"u_rex_a": {"name": "Carica furiosa", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 2.2, "status": {"bleed": 2},
		"bonus": {"stat": "atk", "pct": 20}, "unique": "rex"},
	"u_ivo_a": {"name": "Sgambetto", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "mult": 0.8, "status": {"mark": 1, "bleed": 1}, "energy": 1,
		"bonus": {"stat": "spd", "pct": 12}, "unique": "ivo"},
	"u_sera_a": {"name": "Ala protettiva", "kind": "skill", "cost": 2, "priority": 1, "target": "allies", "shield": 1.2,
		"bonus": {"stat": "def", "pct": 20}, "unique": "sera"},
	"u_sera_b": {"name": "Vento di coda", "kind": "skill", "cost": 2, "priority": 0, "target": "allies", "heal": 0.8, "cleanse": true, "energy": 1,
		"bonus": {"stat": "max_hp", "pct": 5}, "unique": "sera"},
	"u_eco_a": {"name": "Eco ripetuto", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.6, "status": {"mark": 2},
		"bonus": {"stat": "crit", "pct": 22}, "unique": "eco"},
	"u_eco_b": {"name": "Frequenza critica", "kind": "skill", "cost": 3, "priority": 0, "target": "enemy", "mult": 3.0, "pierce": 40,
		"bonus": {"stat": "crit", "pct": 30}, "unique": "eco"},
	"u_tana_a": {"name": "Bastione vivente", "kind": "skill", "cost": 2, "priority": 1, "target": "allies", "shield": 1.4, "self_status": {"taunt": 1},
		"bonus": {"stat": "def", "pct": 24}, "unique": "tana"},
	"u_tana_b": {"name": "Muro totale", "kind": "skill", "cost": 2, "priority": 1, "target": "self", "shield": 2.0, "self_status": {"taunt": 1, "guard": 1},
		"bonus": {"stat": "def", "pct": 40}, "unique": "tana"},
}

const SKILLS: Dictionary = {
	"kira": ["u_kira_a"], "dax": ["u_dax_a"], "elle": ["u_elle_a"], "bruno": ["u_bruno_a"],
	"nova": ["u_nova_a"], "mira": ["u_mira_a"], "rex": ["u_rex_a"], "ivo": ["u_ivo_a"],
	"sera": ["u_sera_a", "u_sera_b"], "eco": ["u_eco_a", "u_eco_b"], "tana": ["u_tana_a", "u_tana_b"],
}


static func has_passive(char_id: String) -> bool:
	return PASSIVES.has(char_id)


static func passive_name(char_id: String) -> String:
	return str(PASSIVES.get(char_id, {}).get("name", ""))


# Valore della passiva unica al rank dato.
static func passive_value(char_id: String, rank: int) -> float:
	var d: Dictionary = PASSIVES.get(char_id, {})
	if d.is_empty():
		return 0.0
	return float(d["base"]) * (1.0 + PASSIVE_RANK_SCALE * float(rank))


static func passive_text(char_id: String, rank: int) -> String:
	var d: Dictionary = PASSIVES.get(char_id, {})
	if d.is_empty():
		return ""
	var v: float = passive_value(char_id, rank)
	var key: String = str(d["key"])
	var shown: String = "%d" % int(round(v)) if key == "gauge_regen" else ("%.1f" % (v * 100.0)).trim_suffix(".0")
	return str(KEY_TEXT[key]) % shown


# Abilita' uniche disponibili a quel rank.
static func skills_for(char_id: String, rank: int) -> Array:
	var out: Array = []
	var all: Array = SKILLS.get(char_id, [])
	for i in all.size():
		if i == 0 or rank >= SECOND_SKILL_RANK:
			out.append(str(all[i]))
	return out


# Tutte (anche quelle ancora bloccate), con il rank che le sblocca.
static func all_skills(char_id: String) -> Array:
	var out: Array = []
	var all: Array = SKILLS.get(char_id, [])
	for i in all.size():
		out.append({"id": str(all[i]), "rank": 0 if i == 0 else SECOND_SKILL_RANK})
	return out


# Effetti attivi di un'unita' (chiave -> valore), per il motore.
static func effects_for(char_id: String, rank: int) -> Dictionary:
	var d: Dictionary = PASSIVES.get(char_id, {})
	if d.is_empty():
		return {}
	# interi (per mille): lo stato di battaglia viaggia come JSON e non puo' contenere decimali
	return {str(d["key"]): int(round(passive_value(char_id, rank) * 1000.0))}


static func value(u: Dictionary, key: String) -> float:
	return float(u.get("uniq", {}).get(key, 0)) / 1000.0


# Moltiplicatore di danno dalle passive uniche.
static func damage_mult(attacker: Dictionary, defender: Dictionary) -> float:
	var m: float = 1.0
	var v: float = value(attacker, "dmg_vs_mark")
	if v > 0.0 and defender.get("statuses", {}).has("mark"):
		m *= 1.0 + v
	var low: float = value(attacker, "low_hp_atk")
	if low > 0.0 and float(attacker["hp"]) < float(attacker["max_hp"]) * 0.5:
		m *= 1.0 + low
	return m


static func crit_bonus(attacker: Dictionary, defender: Dictionary) -> int:
	var v: float = value(attacker, "crit_marked")
	if v > 0.0 and defender.get("statuses", {}).has("mark"):
		return int(round(v * 1000.0))
	return 0
