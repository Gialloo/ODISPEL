FILE battle_content.gd - PARTE 1 DI 5
Percorso: scripts/battle/battle_content.gd
(Codice GDScript, rientri con tab. Non rispondere finche' non scrivo FINE FILE.)

```gdscript
class_name BattleContent
extends RefCounted

# Dati di gioco del nuovo motore: mosse, passive, personaggi, equipaggiamento, boss.
# Tutto e' dato statico: per aggiungere contenuti basta aggiungere voci qui.

# kind: basic | skill | ult
# target: enemy | self | ally | allies
# cost: energia (skill). Le ultimate costano la barra piena.
# rarity: indice in BattleTypes.RARITIES
const BASE_MOVES: Dictionary = {
	"attack": {"name": "Attacco", "kind": "basic", "cost": 0, "priority": 0, "rarity": 0, "target": "enemy", "mult": 1.0},
	"guard": {"name": "Guardia", "kind": "basic", "cost": 0, "priority": 1, "rarity": 0, "target": "self", "self_status": {"guard": 1}, "energy": 1, "ammo_gain": 1},
	"ricarica": {"name": "Ricarica", "kind": "skill", "cost": 0, "priority": 1, "rarity": 0, "target": "self", "ammo_gain": 3, "energy": 1},
	# REAZIONI: solo contro una CARICA del boss. Costano Riserva di squadra (condivisa), non energia.
	"schivata": {"name": "Schivata", "kind": "reaction", "cost": 0, "reserve": 1, "priority": 3, "rarity": 0, "target": "self", "react": "dodge"},
	"intercettazione": {"name": "Intercettazione", "kind": "reaction", "cost": 0, "reserve": 2, "priority": 3, "rarity": 0, "target": "self", "react": "intercept"},
	"soccorso": {"name": "Soccorso", "kind": "rescue", "cost": 0, "reserve": 2, "priority": 3, "rarity": 0, "target": "self", "react": "rescue"},
	"interruzione": {"name": "Interruzione", "kind": "reaction", "cost": 0, "reserve": 2, "priority": 3, "rarity": 0, "target": "enemy", "react": "interrupt"},
}
const REACTIONS: Array = ["schivata", "intercettazione", "interruzione"]

# Mosse a livelli (una per rarita'). Ogni livello ha un valore base (mult / heal / shield, per il tuo ATK)
# PIU' una parte di una statistica di chi la usa: "bonus": {"stat": ..., "pct": ...}.
# Stat: atk, def, spd, max_hp, crit (il critico conta x10: 10% di crit = 100 punti).
# L'id del primo livello e' quello base ("cura"); gli altri: _r (rara), _e (epica), _l (leggendaria).
# "from": rarita' del primo livello. "values": un valore per livello; "pct": la percentuale della statistica per livello.
const FAMILIES: Dictionary = {
	"colpo_caricato": {"name": "Colpo caricato", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy",
		"key": "mult", "values": [2.0, 2.3, 2.7, 3.2], "stat": "atk", "pct": [8, 14, 22, 32]},
	"marchio": {"name": "Marchio", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "status": {"mark": 2},
		"key": "mult", "values": [0.5, 0.6, 0.75, 0.9], "stat": "crit", "pct": [10, 18, 28, 40]},
	"provoca": {"name": "Provoca", "kind": "skill", "cost": 1, "priority": 1, "target": "self", "self_status": {"taunt": 1},
		"key": "shield", "values": [0.6, 0.8, 1.05, 1.4], "stat": "def", "pct": [10, 16, 24, 34]},
	"barriera": {"name": "Barriera", "kind": "skill", "cost": 2, "priority": 1, "target": "allies", "ally_buff": {"atk": 1},
		"key": "shield", "values": [1.0, 1.3, 1.7, 2.2], "stat": "def", "pct": [10, 16, 24, 34]},
	"cura": {"name": "Cura", "kind": "skill", "cost": 2, "priority": 0, "target": "ally",
		"key": "heal", "values": [1.4, 1.8, 2.3, 2.8], "stat": "max_hp", "pct": [5, 6.5, 8, 10]},
	"sacrificio": {"name": "Sacrificio", "kind": "skill", "cost": 2, "priority": 1, "target": "self", "self_status": {"taunt": 1}, "self_cost_hp": 0.15,
		"from": 1, "key": "shield", "values": [1.9, 2.5, 3.3], "stat": "def", "pct": [16, 26, 40]},
	"purifica": {"name": "Purifica", "kind": "skill", "cost": 1, "priority": 0, "target": "ally", "cleanse": true,
		"key": "heal", "values": [0.4, 0.55, 0.7, 0.9], "stat": "max_hp", "pct": [2, 3, 4, 6]},
	"frattura": {"name": "Frattura", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "debuff": {"def": 1},
		"key": "mult", "values": [0.9, 1.1, 1.35, 1.6], "stat": "atk", "pct": [6, 10, 16, 24]},
	"intimidisci": {"name": "Intimidisci", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "debuff": {"atk": 1},
		"key": "mult", "values": [0.5, 0.65, 0.8, 1.0], "stat": "spd", "pct": [8, 12, 18, 26]},
	"doppio_colpo": {"name": "Doppio colpo", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "hits": 2,
		"from": 1, "key": "mult", "values": [0.9, 1.05, 1.25], "stat": "atk", "pct": [6, 10, 16]},
	"colpo_mirato": {"name": "Colpo mirato", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "ammo": 1, "pierce": 50,
		"from": 1, "key": "mult", "values": [1.7, 2.0, 2.4], "stat": "crit", "pct": [12, 20, 30]},
	"colpo_alla_testa": {"name": "Colpo alla testa", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "ammo": 2, "pierce": 50,
		"from": 2, "key": "mult", "values": [2.4, 2.9], "stat": "crit", "pct": [20, 34]},
	"spezzatutto": {"name": "Spezzatutto", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy",
		"from": 2, "key": "mult", "values": [4.5, 5.6], "stat": "atk", "pct": [20, 36]},
	"bastione": {"name": "Bastione", "kind": "ult", "cost": 0, "priority": 1, "target": "allies", "ally_buff": {"atk": 1},
		"from": 2, "key": "shield", "values": [2.0, 2.7], "stat": "def", "pct": [30, 48]},
	"rinascita": {"name": "Rinascita", "kind": "ult", "cost": 0, "priority": 0, "target": "allies", "ally_buff": {"atk": 1}, "cleanse": true,
		"from": 2, "key": "heal", "values": [1.1, 1.5], "stat": "max_hp", "pct": [8, 15]},
}
const TIER_SUFFIX: Array = ["", "_r", "_e", "_l"]
const TIER_NAMES: Array = ["", " II", " III", " IV"]

# Tutte le mosse: quelle di base e i livelli delle famiglie.
static var MOVES: Dictionary = _build_moves()


static func _build_moves() -> Dictionary:
	var out: Dictionary = BASE_MOVES.duplicate(true)
	for fid in FAMILIES:
		var f: Dictionary = FAMILIES[fid]
		var first: int = int(f.get("from", 0))
		var values: Array = f["values"]
		for i in values.size():
			var rarity: int = first + i
			var id: String = str(fid) + (str(TIER_SUFFIX[rarity]) if i > 0 else "")
			var m: Dictionary = {"name": str(f["name"]) + str(TIER_NAMES[i]), "kind": f["kind"], "cost": f["cost"], "priority": f["priority"],
				"rarity": rarity, "target": f["target"], "family": fid, "tier": i}
			for k in ["status", "self_status", "cleanse", "ammo", "pierce", "debuff", "hits", "ally_buff", "self_cost_hp"]:
				if f.has(k):
					m[k] = f[k].duplicate(true) if f[k] is Dictionary else f[k]
			m[str(f["key"])] = values[i]
			m["bonus"] = {"stat": f["stat"], "pct": f["pct"][i]}
			out[id] = m
	# abilita' uniche dei personaggi: prendono la rarita' del proprietario e non cadono come premio
	for mid in Signatures.MOVES:
		var um: Dictionary = Signatures.MOVES[mid].duplicate(true)
		um["rarity"] = int(CHARACTERS.get(str(um["unique"]), {}).get("rarity", 0))
		out[mid] = um
	return out


# Valore di una statistica per i bonus delle mosse.
static func stat_value(u: Dictionary, stat: String) -> float:
	match stat:
		"crit":
			return float(u.get("crit", 0)) * 10.0
		"max_hp":
			return float(u.get("max_hp", 0))
	return float(u.get(stat, 0))


# Punti in piu' che una mossa prende da una statistica di chi la usa (0 se la mossa non ha bonus).
static func move_bonus(u: Dictionary, move: Dictionary) -> float:
	if not move.has("bonus"):
		return 0.0
	var b: Dictionary = move["bonus"]
	return stat_value(u, str(b["stat"])) * float(b["pct"]) / 100.0


const STAT_NAMES: Dictionary = {"atk": "ATK", "def": "DIF", "spd": "VEL", "max_hp": "PV MAX", "crit": "CRITICO"}


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
	"vanguard": {"hp": 1300, "atk": 90, "def": 50, "spd": 90},
	"warden": {"hp": 940, "atk": 84, "def": 28, "spd": 100},
}
# Attacco base: i ruoli di supporto/tank colpiscono un po' di piu' con l'attacco semplice.
const CLASS_BASIC: Dictionary = {"striker": 1.0, "vanguard": 1.2, "warden": 1.3}
const LEVEL_BONUS: float = 0.08


static func basic_factor(unit: Dictionary) -> float:
	if not CHARACTERS.has(str(unit.get("char", ""))):
		return 1.0
	return float(CLASS_BASIC.get(str(unit.get("cls", "")), 1.0))
# Bonus statistico per rank, per rarita' (comune, rara, epica, leggendaria): piu' raro = piu' forte.
const RANK_BONUS_BY_RARITY: Array = [0.04, 0.05, 0.06, 0.08]


static func rank_bonus(rarity: int) -> float:
	return float(RANK_BONUS_BY_RARITY[clampi(rarity, 0, RANK_BONUS_BY_RARITY.size() - 1)])


# Un operatore piu' raro e' piu' forte di base: moltiplicatore delle statistiche
# per rarita' (comune, rara, epica, leggendaria). Sale come l'equipaggiamento.
const RARITY_STAT_MULT: Array = [1.0, 1.08, 1.18, 1.32]
```
