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

# rarity: indice in BattleTypes.RARITIES (quanto e' raro da reclutare)
const CHARACTERS: Dictionary = {
	"kira": {"name": "Kira", "color": "viola", "cls": "striker", "rarity": 3, "skill": "colpo_caricato", "ult": "spezzatutto", "passive": "p_atk", "faction": "rondini",
		"role": "Mascotte e volto del gioco", "stat_mult": {"hp": 1.0, "atk": 1.0}},
	"dax": {"name": "Dax", "color": "rosso", "cls": "vanguard", "rarity": 0, "skill": "provoca", "ult": "bastione", "passive": "p_hp", "faction": "libracorp", "stat_mult": {"hp": 1.15, "atk": 1.2}},
	"elle": {"name": "Elle", "color": "verde", "cls": "warden", "rarity": 0, "skill": "cura", "ult": "rinascita", "passive": "p_swap", "faction": "magabondi", "stat_mult": {"hp": 1.15, "atk": 1.2}},
	"bruno": {"name": "Bruno", "color": "blu", "cls": "vanguard", "rarity": 0, "skill": "barriera", "ult": "bastione", "passive": "p_hp", "faction": "libracorp", "stat_mult": {"hp": 1.15, "atk": 1.2, "def": 1.05}},
	"nova": {"name": "Nova", "color": "giallo", "cls": "striker", "rarity": 1, "skill": "marchio", "ult": "spezzatutto", "passive": "p_hunter", "faction": "rondini"},
	"mira": {"name": "Mira", "color": "blu", "cls": "warden", "rarity": 1, "skill": "purifica", "ult": "rinascita", "passive": "p_swap", "faction": "libracorp", "stat_mult": {"hp": 1.35, "atk": 1.4}},
	"rex": {"name": "Rex", "color": "rosso", "cls": "striker", "rarity": 0, "skill": "colpo_caricato", "ult": "spezzatutto", "passive": "p_atk", "faction": "rondini", "stat_mult": {"atk": 0.95}},
	"ivo": {"name": "Ivo", "color": "blu", "cls": "striker", "rarity": 1, "skill": "marchio", "ult": "spezzatutto", "passive": "p_swap", "faction": "magabondi", "style": "atipico"},
	"sera": {"name": "Sera", "color": "verde", "cls": "warden", "rarity": 2, "skill": "barriera", "ult": "rinascita", "passive": "p_hunter", "faction": "rondini", "stat_mult": {"hp": 1.25, "atk": 1.35}},
	"eco": {"name": "Eco", "color": "giallo", "cls": "striker", "rarity": 2, "skill": "marchio", "ult": "spezzatutto", "passive": "p_atk", "faction": "kairos", "stat_mult": {"atk": 0.94}},
	"tana": {"name": "Tana", "color": "giallo", "cls": "vanguard", "rarity": 3, "skill": "provoca", "ult": "bastione", "passive": "p_hunter", "faction": "libracorp", "stat_mult": {"hp": 1.3, "atk": 1.35}},
	# Agent 02: tiratore scelto. Angela: mecamante, glass cannon con 12 munizioni.
	# Nico: l'amico di Kira, ricomparso nello Specchio. Solo storia: non esce dai reclutamenti.
	"nico": {"name": "Nico", "color": "rosso", "cls": "vanguard", "rarity": 2, "skill": "intimidisci", "ult": "bastione", "passive": "p_swap", "faction": "kairos",
		"role": "Custode del rifugio", "story_only": true},
	"dafne": {"name": "Dafne", "color": "giallo", "arch": "dex", "cls": "striker", "rarity": 3, "skill": "u_dafne_a", "ult": "coordinated_shot", "passive": "p_atk", "faction": "libracorp",
		"role": "Tiratore scelto", "ammo_max": 6, "stat_mult": {"hp": 0.85, "atk": 0.98}},
	"angela": {"name": "Angela", "color": "giallo", "cls": "striker", "rarity": 3, "skill": "u_angela_a", "ult": "orbital_strike", "passive": "p_atk", "faction": "libracorp",
		"role": "Mecamante", "ammo_max": 12, "stat_mult": {"hp": 0.75, "atk": 1.12, "def": 0.8}},
	# Roster 2: dieci operatori nuovi (3 Magabondi, 3 Kairos, 2 Rondini, 2 LibraCorp).
	"moro": {"name": "Moro", "color": "rosso", "cls": "vanguard", "rarity": 1, "skill": "provoca", "ult": "u_moro_ult", "passive": "p_hp", "faction": "magabondi",
		"role": "Difensore resistente", "stat_mult": {"hp": 1.15, "atk": 1.25, "def": 1.1}},
	"vesper": {"name": "Vesper", "color": "viola", "cls": "striker", "rarity": 2, "skill": "marchio", "ult": "u_vesper_ult", "passive": "p_atk", "faction": "magabondi",
		"role": "Cacciatore di marchiati", "stat_mult": {"hp": 1.0, "atk": 1.08}},
	"nami": {"name": "Nami", "color": "verde", "cls": "warden", "rarity": 0, "skill": "barriera", "ult": "u_nami_ult", "passive": "p_hp", "faction": "magabondi",
		"role": "Custode dei piccoli rituali", "stat_mult": {"hp": 1.6, "atk": 1.95}},
	"oriel": {"name": "Oriel", "color": "blu", "cls": "warden", "rarity": 3, "skill": "cura", "ult": "u_oriel_ult", "passive": "p_swap", "faction": "kairos",
		"role": "Custode della soglia", "stat_mult": {"hp": 1.35, "atk": 1.45}},
	"silex": {"name": "Silex", "color": "viola", "cls": "vanguard", "rarity": 1, "skill": "provoca", "ult": "u_silex_ult", "passive": "p_hp", "faction": "kairos",
		"role": "Il muro che avanza", "stat_mult": {"hp": 1.12, "atk": 1.15}},
	"yuna": {"name": "Yuna", "color": "blu", "cls": "striker", "rarity": 2, "skill": "colpo_caricato", "ult": "u_yuna_ult", "passive": "p_atk", "faction": "kairos",
		"role": "Attaccante rapido"},
	"rhea": {"name": "Rhea", "color": "verde", "cls": "warden", "rarity": 1, "skill": "purifica", "ult": "u_rhea_ult", "passive": "p_swap", "faction": "rondini",
		"role": "Specialista del contenimento", "stat_mult": {"hp": 1.25, "atk": 1.3}},
	"flux": {"name": "Flux", "color": "blu", "cls": "striker", "rarity": 3, "skill": "colpo_caricato", "ult": "u_flux_ult", "passive": "p_atk", "faction": "rondini",
		"role": "Picco di potenza", "stat_mult": {"hp": 0.9, "atk": 0.95}},
	"cato": {"name": "Cato", "color": "viola", "cls": "vanguard", "rarity": 0, "skill": "barriera", "ult": "u_cato_ult", "passive": "p_hp", "faction": "libracorp",
		"role": "Operatore standard", "stat_mult": {"hp": 1.2, "atk": 1.5, "def": 1.15}},
	"lyra": {"name": "Lyra", "color": "viola", "cls": "striker", "rarity": 3, "skill": "marchio", "ult": "u_lyra_ult", "passive": "p_atk", "faction": "libracorp",
		"role": "Stratega del bersaglio", "stat_mult": {"hp": 0.92, "atk": 0.95}},
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
	"porte": {"name": "Porte che si chiudono", "target": "one", "mult": 1.9},
	"caduta_libera": {"name": "Caduta libera", "target": "all", "mult": 0.8, "status": {"bleed": 3}},
	"piano_zero": {"name": "Piano zero", "target": "weakest", "mult": 0.9, "drain": 0.5},
	"manutenzione": {"name": "Manutenzione", "target": "all", "mult": 0.5, "status": {"mark": 2}, "self_shield": 0.08},
	"posa": {"name": "Posa", "target": "one", "mult": 1.7},
	"vetrina": {"name": "Vetrina", "target": "all", "mult": 0.6, "status": {"mark": 2}},
	"copia": {"name": "Copia", "target": "weakest", "mult": 0.9, "drain": 0.6},
	"sfilata": {"name": "Sfilata", "target": "all", "mult": 1.0},
	"rintocco": {"name": "Rintocco", "target": "one", "mult": 2.0},
	"lancette": {"name": "Lancette", "target": "all", "mult": 0.9, "status": {"bleed": 3}},
	"ora_zero": {"name": "Ora zero", "target": "all", "mult": 0.65, "status": {"mark": 2}, "self_shield": 0.06},
	"tempo_perso": {"name": "Tempo perso", "target": "weakest", "mult": 1.0, "drain": 0.7},
	"riflesso": {"name": "Riflesso", "target": "one", "mult": 2.1},
	"frantumi": {"name": "Frantumi", "target": "all", "mult": 0.95, "status": {"bleed": 3}},
	"doppio": {"name": "Doppio", "target": "weakest", "mult": 0.85, "drain": 0.5, "self_shield": 0.05},
	"furia": {"name": "Furia", "target": "all", "mult": 0.7, "status": {"bleed": 2}},
	"ultimo_respiro": {"name": "Ultimo respiro", "target": "all", "mult": 0.9, "status": {"mark": 3}, "self_shield": 0.04},
	"simmetria": {"name": "Simmetria", "target": "all", "mult": 0.7, "status": {"mark": 3}, "self_shield": 0.06},
	"ululato": {"name": "Ululato", "target": "all", "mult": 0.6, "status": {"mark": 2}},
	"allarme": {"name": "Allarme rosso", "target": "one", "mult": 1.9},
	"stridio": {"name": "Stridio", "target": "weakest", "mult": 0.9, "drain": 0.5},
	"coprifuoco": {"name": "Coprifuoco", "target": "all", "mult": 0.5, "status": {"bleed": 2}, "self_shield": 0.06},
	"abbaglio": {"name": "Abbaglio", "target": "one", "mult": 1.9},
	"buio": {"name": "Buio improvviso", "target": "all", "mult": 0.6, "status": {"mark": 2}},
	"falena": {"name": "Falena", "target": "weakest", "mult": 0.9, "drain": 0.6},
	"cono_di_luce": {"name": "Cono di luce", "target": "all", "mult": 0.8, "status": {"bleed": 3}},
	"prelievo": {"name": "Prelievo", "target": "weakest", "mult": 1.0, "drain": 0.7},
	"commissione": {"name": "Commissione", "target": "all", "mult": 0.6, "status": {"mark": 2}},
	"saldo_negativo": {"name": "Saldo negativo", "target": "one", "mult": 2.0},
	"blocco_carta": {"name": "Blocco carta", "target": "all", "mult": 0.5, "status": {"bleed": 2}, "self_shield": 0.08},
	"gradino": {"name": "Gradino mancante", "target": "one", "mult": 2.0},
	"risalita": {"name": "Risalita", "target": "all", "mult": 0.75, "status": {"bleed": 3}},
	"senso_inverso": {"name": "Senso inverso", "target": "weakest", "mult": 0.9, "drain": 0.5},
	"arresto": {"name": "Arresto di emergenza", "target": "all", "mult": 0.5, "status": {"mark": 2}, "self_shield": 0.06},
	"fruscio": {"name": "Fruscio", "target": "all", "mult": 0.55, "status": {"mark": 2}},
	"sintonia": {"name": "Sintonia forzata", "target": "one", "mult": 2.0},
	"disturbo": {"name": "Disturbo", "target": "all", "mult": 0.85, "status": {"bleed": 3}, "self_shield": 0.04},
	"onda_lunga": {"name": "Onda lunga", "target": "weakest", "mult": 1.0, "drain": 0.6},
	"binario": {"name": "Binario morto", "target": "one", "mult": 2.1},
	"ultima_corsa": {"name": "Ultima corsa", "target": "all", "mult": 0.9, "status": {"bleed": 3}},
	"fermata": {"name": "Fermata richiesta", "target": "all", "mult": 0.6, "status": {"mark": 2}, "self_shield": 0.06},
	"capolinea": {"name": "Capolinea", "target": "weakest", "mult": 1.0, "drain": 0.6},
	"serratura": {"name": "Serratura", "target": "one", "mult": 2.1},
	"combinazione": {"name": "Combinazione", "target": "all", "mult": 0.65, "status": {"mark": 3}},
	"blindatura": {"name": "Blindatura", "target": "all", "mult": 0.45, "self_shield": 0.1},
	"furto": {"name": "Furto", "target": "weakest", "mult": 0.95, "drain": 0.7},
	"fascio": {"name": "Fascio", "target": "one", "mult": 2.2},
	"nebbia": {"name": "Nebbia", "target": "all", "mult": 0.7, "status": {"mark": 3}},
	"naufragio": {"name": "Naufragio", "target": "all", "mult": 1.0, "status": {"bleed": 3}},
	"marea_nera": {"name": "Marea nera", "target": "weakest", "mult": 1.0, "drain": 0.6, "self_shield": 0.05},
	"cancellazione": {"name": "Cancellazione", "target": "one", "mult": 2.3},
	"protocollo_nero": {"name": "Protocollo nero", "target": "all", "mult": 0.75, "status": {"mark": 3}},
	"fascicolo": {"name": "Fascicolo", "target": "all", "mult": 1.0, "status": {"bleed": 3}},
	"archiviazione": {"name": "Archiviazione", "target": "weakest", "mult": 1.05, "drain": 0.7, "self_shield": 0.06},
	"oscuramento": {"name": "Oscuramento", "target": "all", "mult": 0.7, "status": {"mark": 3}, "self_shield": 0.06},
	"corona": {"name": "Corona", "target": "one", "mult": 2.4},
	"penombra": {"name": "Penombra", "target": "weakest", "mult": 1.05, "drain": 0.7},
	"ora_nera": {"name": "Ora nera", "target": "all", "mult": 1.1, "status": {"bleed": 3}},
}

# Livelli di difficolta': moltiplicano PV e ATK del boss, aggiungono difesa e premi.
const TIERS: Array = [
	{"id": "normale", "name": "NORMALE", "hp": 1.0, "atk": 1.0, "def": 0, "reward": 1.0},
	{"id": "difficile", "name": "DIFFICILE", "hp": 1.5, "atk": 1.25, "def": 8, "reward": 2.0},
	{"id": "incubo", "name": "INCUBO", "hp": 2.1, "atk": 1.55, "def": 15, "reward": 3.2},
]

# Ordine di sblocco: si apre il boss successivo battendo il precedente (almeno a NORMALE).
const BOSS_ORDER: Array = ["distributore", "semaforo", "tombino", "cabina", "ascensore", "manichino", "orologio", "specchio",
	"sirena", "lampione", "bancomat", "scala", "radio", "metro", "cassaforte", "faro", "registro", "eclissi"]

const BOSSES: Dictionary = {
	"distributore": {
		"name": "Distributore", "title": "CLASSE ANOMALIA · MINACCIA BASSA", "color": "giallo", "hp_per_player": 900,
		"atk": 390, "def": 25, "spd": 105,
		"desc": "Un distributore automatico impazzito. Colpi pesanti a un solo bersaglio e scosse che fanno sanguinare.",
		"cycle": ["scarica", "raffica", "scossa", "sovraccarico"],
		"ally": "eco",
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 3,
		"reward": {"coins": 600, "nucleo": [4, 8], "lega": [2, 6], "gear_chance": 65},
	},
	"semaforo": {
		"name": "Semaforo", "title": "CLASSE ANOMALIA · MINACCIA MEDIA", "color": "rosso", "hp_per_player": 850,
		"atk": 380, "def": 20, "spd": 118,
		"desc": "Un semaforo che non cambia piu' colore. Veloce: agisce prima di quasi tutti. Marchia la squadra e punta chi e' piu' ferito.",
		"cycle": ["lampeggio", "rosso", "giallo", "verde"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 3,
		"reward": {"coins": 900, "nucleo": [6, 10], "lega": [4, 8], "gear_chance": 75},
	},
	"tombino": {
		"name": "Tombino", "title": "CLASSE ANOMALIA · MINACCIA ALTA", "color": "viola", "hp_per_player": 1000,
		"atk": 340, "def": 35, "spd": 82,
		"desc": "Qualcosa vive sotto il tombino. Lento ma resistente: si cura risucchiando i feriti e si chiude sotto uno scudo.",
		"cycle": ["gorgo", "risucchio", "alluvione", "chiusura"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 4,
		"reward": {"coins": 1300, "nucleo": [8, 14], "lega": [6, 12], "gear_chance": 85},
	},
	"cabina": {
		"name": "Cabina", "title": "CLASSE ANOMALIA · MINACCIA CRITICA", "color": "blu", "hp_per_player": 1100,
		"atk": 360, "def": 30, "spd": 96,
		"desc": "Una cabina telefonica che squilla da sola. Marchia la squadra, chiama un bersaglio con un colpo pesante e si nutre di chi e' gia' ferito.",
		"cycle": ["squillo", "chiamata", "interferenza", "linea_occupata"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 4,
		"reward": {"coins": 1700, "nucleo": [10, 16], "lega": [8, 14], "gear_chance": 95},
	},
	"ascensore": {
		"name": "Ascensore", "title": "CLASSE ANOMALIA · MINACCIA ESTREMA", "color": "blu", "hp_per_player": 1200,
		"atk": 380, "def": 40, "spd": 90,
		"desc": "L'ascensore della torre LibraCorp: sale a piani che non esistono. Porte che si chiudono su un solo bersaglio, cadute su tutta la squadra, e una manutenzione che lo protegge.",
		"cycle": ["porte", "caduta_libera", "piano_zero", "manutenzione"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 4,
		"reward": {"coins": 2100, "nucleo": [12, 18], "lega": [9, 15], "gear_chance": 100},
	},
	"manichino": {
		"name": "Manichino", "title": "CLASSE ANOMALIA · MINACCIA ESTREMA", "color": "verde", "hp_per_player": 1150,
		"atk": 400, "def": 28, "spd": 112,
		"desc": "Un manichino in vetrina che copia chi lo guarda. Veloce: marchia tutti dietro il vetro, posa su un bersaglio e si nutre dei feriti.",
		"cycle": ["posa", "vetrina", "copia", "sfilata"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 4,
		"reward": {"coins": 2500, "nucleo": [14, 20], "lega": [11, 17], "gear_chance": 100},
	},
	"orologio": {
		"name": "Orologio", "title": "CLASSE ANOMALIA · MINACCIA ASSOLUTA", "color": "viola", "hp_per_player": 1500,
		"atk": 420, "def": 45, "spd": 100,
		"desc": "L'orologio della torre, al centro di CAM-00. Ferma il tempo per chi lo guarda: colpi pesanti, lancette che feriscono tutti e un'ora zero che marchia la squadra.",
		"cycle": ["rintocco", "lancette", "ora_zero", "tempo_perso"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 3500, "nucleo": [18, 26], "lega": [14, 22], "gear_chance": 100},
	},
	"specchio": {
		"name": "Specchio", "title": "CLASSE ANOMALIA · OLTRE LA SCALA", "color": "rosso", "hp_per_player": 1700,
		"atk": 440, "def": 50, "spd": 108,
		"ally": "nico",
		"desc": "Lo specchio che c'era dietro l'orologio: mostra la squadra come sarebbe stata se il tempo non si fosse fermato. Un riflesso colpisce un solo bersaglio, i frantumi feriscono tutti e il doppio si nutre dei piu' deboli.",
		"cycle": ["riflesso", "frantumi", "doppio", "simmetria"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 4600, "nucleo": [22, 30], "lega": [18, 26], "gear_chance": 100},
	},
	"sirena": {
		"name": "Sirena", "title": "S2 · MINACCIA ALTA", "color": "rosso", "hp_per_player": 1250,
		"atk": 430, "def": 42, "spd": 104,
		"ally": "dafne",
		"desc": "La sirena d'allarme di Via Pia: urla da sola da tre notti. Marchia tutta la squadra, chiama un solo bersaglio con l'allarme rosso e si ripara dietro il coprifuoco.",
		"cycle": ["ululato", "allarme", "stridio", "coprifuoco"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 5000, "nucleo": [24, 32], "lega": [20, 28], "gear_chance": 100},
	},
	"lampione": {
		"name": "Lampione", "title": "S2 · MINACCIA ALTA", "color": "giallo", "hp_per_player": 1300,
		"atk": 440, "def": 44, "spd": 98,
		"desc": "Un lampione di Piazza dei Salici che accende il buio invece di spegnerlo. Abbaglia un bersaglio, marchia tutti nel buio e attira le falene sui piu' feriti.",
		"cycle": ["abbaglio", "buio", "falena", "cono_di_luce"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 5800, "nucleo": [26, 34], "lega": [22, 30], "gear_chance": 100},
	},
	"bancomat": {
		"name": "Bancomat", "title": "S2 · MINACCIA ESTREMA", "color": "verde", "hp_per_player": 1350,
		"atk": 450, "def": 46, "spd": 92,
		"desc": "Un bancomat che non restituisce niente. Preleva vita ai piu' deboli, addebita commissioni a tutti e chiude la carta sotto uno scudo.",
		"cycle": ["prelievo", "commissione", "saldo_negativo", "blocco_carta"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 6600, "nucleo": [28, 36], "lega": [24, 32], "gear_chance": 100},
	},
	"scala": {
		"name": "Scala mobile", "title": "S2 · MINACCIA ESTREMA", "color": "blu", "hp_per_player": 1400,
		"atk": 455, "def": 48, "spd": 100,
		"desc": "La scala mobile della stazione, che scende anche quando sale. Un gradino mancante colpisce uno solo, la risalita ferisce tutti.",
		"cycle": ["gradino", "risalita", "senso_inverso", "arresto"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 7500, "nucleo": [30, 38], "lega": [26, 34], "gear_chance": 100},
	},
	"radio": {
		"name": "Radio", "title": "S2 · MINACCIA ESTREMA", "color": "viola", "hp_per_player": 1450,
		"atk": 465, "def": 50, "spd": 110,
		"desc": "Una radio che trasmette voci di chi non c'e' piu'. Veloce: marchia tutti col fruscio, forza la sintonia su un bersaglio e succhia chi e' gia' a terra.",
		"cycle": ["fruscio", "sintonia", "disturbo", "onda_lunga"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 8400, "nucleo": [32, 40], "lega": [28, 36], "gear_chance": 100},
	},
	"metro": {
		"name": "Metro", "title": "S2 · MINACCIA ASSOLUTA", "color": "rosso", "hp_per_player": 1550,
		"atk": 480, "def": 52, "spd": 114,
		"desc": "Il treno fantasma dell'ultima corsa. Veloce e pesante: binario morto su un bersaglio, ultima corsa su tutti, capolinea sui piu' deboli.",
		"cycle": ["binario", "ultima_corsa", "fermata", "capolinea"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 9400, "nucleo": [34, 42], "lega": [30, 38], "gear_chance": 100},
	},
	"cassaforte": {
		"name": "Cassaforte", "title": "S2 · MINACCIA ASSOLUTA", "color": "verde", "hp_per_player": 1650,
		"atk": 470, "def": 66, "spd": 84,
		"desc": "La cassaforte del caveau LibraCorp. Lenta ma blindata: la combinazione marchia la squadra, la blindatura la protegge e il furto svuota i feriti.",
		"cycle": ["serratura", "combinazione", "blindatura", "furto"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 10500, "nucleo": [36, 44], "lega": [32, 40], "gear_chance": 100},
	},
	"faro": {
		"name": "Faro", "title": "S2 · MINACCIA ASSOLUTA", "color": "blu", "hp_per_player": 1700,
		"atk": 490, "def": 58, "spd": 102,
		"desc": "Il faro del porto vecchio, che guida le navi verso gli scogli. Il fascio colpisce un solo bersaglio, la nebbia marchia tutti, il naufragio ferisce l'intera squadra.",
		"cycle": ["fascio", "nebbia", "naufragio", "marea_nera"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 11700, "nucleo": [38, 46], "lega": [34, 42], "gear_chance": 100},
	},
	"registro": {
		"name": "Registro", "title": "S2 · OLTRE LA SCALA", "color": "giallo", "hp_per_player": 1850,
		"atk": 510, "def": 62, "spd": 106,
		"desc": "L'archivio nero di LibraCorp: dove finisce chi viene cancellato. Cancella un bersaglio, schedatura marchia tutti, l'archiviazione si nutre dei piu' deboli.",
		"cycle": ["cancellazione", "protocollo_nero", "fascicolo", "archiviazione"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 13000, "nucleo": [40, 48], "lega": [36, 44], "gear_chance": 100},
	},
	"eclissi": {
		"name": "Eclissi", "title": "S2 · IL FINALE", "color": "viola", "hp_per_player": 2100,
		"atk": 540, "def": 70, "spd": 110,
		"desc": "Il sole nero sopra i sette minuti perduti. Oscura e marchia tutti, la corona schiaccia un solo bersaglio, la penombra beve i piu' deboli e l'ora nera ferisce tutta la squadra.",
		"cycle": ["oscuramento", "corona", "penombra", "ora_nera"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 15000, "nucleo": [44, 54], "lega": [40, 50], "gear_chance": 100},
	},
}


# Il ciclo di mosse del boss cambia a ogni fase (meta' e un quarto dei PV): ordine diverso e mosse nuove.
static func cycle_for(boss_id: String, phase: int) -> Array:
	var c: Array = BOSSES[boss_id]["cycle"]
	if phase >= 3 and c.size() >= 4:
		return ["ultimo_respiro", c[1], c[3], "furia", c[0], c[2]]
	if phase == 2 and c.size() >= 4:
		return [c[2], c[0], "furia", c[3], c[1]]
	return c


static func tier_of(tier: int) -> Dictionary:
	return TIERS[clampi(tier, 0, TIERS.size() - 1)]


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
	if faction_of(char_id) == "libracorp":
		return ["attack", str(CHARACTERS[char_id]["skill"]), "ricarica", "guard"]
	return ["attack", str(CHARACTERS[char_id]["skill"]), "guard"]


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
