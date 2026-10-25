class_name Signatures
extends RefCounted

# Ogni operatore ha una PASSIVA UNICA e 1 o 2 ABILITA' UNICHE (sempre disponibili), pensate per il suo ruolo e la sua rarita'.
# Il RANK si compra con le copie (RANK UP manuale) e potenzia il kit; l'aumento dipende dalla rarita'
# (comune < rara < epica < leggendaria):
#   rank 1: SKILL 1 potenziata        rank 4: SKILL 1 e 2 potenziate ancora
#   rank 2: SKILL 2 potenziata        rank 5: ULTIMATE potenziata ancora + RISVEGLIO (parte con +25 di carica)
#   rank 3: ULTIMATE potenziata
# SKILL 1 = prima abilita' unica; SKILL 2 = seconda abilita' unica (o, se ne ha una sola, la sua skill di base).
# In piu' ogni rank da' statistiche e potenzia la passiva. Le mosse uniche non si trovano come premio: sono del personaggio.

const PASSIVE_SCALE_BY_RARITY: Array = [0.08, 0.10, 0.12, 0.15]    # passiva: +% a rank
const SKILL_UP_BY_RARITY: Array = [0.08, 0.10, 0.12, 0.15]         # skill: +% a grado
const ULT_UP_BY_RARITY: Array = [0.10, 0.12, 0.15, 0.20]           # ultimate: +% a grado
const AWAKEN_RANK: int = 5
const AWAKEN_GAUGE: int = 25
const CRIT_PER_MARK_CAP: int = 12      # marchi che contano per la passiva di Dafne

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
	"mark_ammo": "ogni marchio applicato al nemico ricarica %s munizione/i a tutti i LibraCorp della squadra",
	"crit_per_mark": "+%s%% di critico per ogni marchio applicato al nemico (nella battaglia)",
}

# base: valore a rank 0 (frazione, tranne gauge_regen e crit_marked che sono punti)
# SOSTEGNO DALLA PANCHINA: un guardiano vivo in back row aiuta chi combatte a fine round, anche senza entrare in campo.
# Ogni guardiano ha il suo aiuto; cresce del 10% a rank. heal/shield = frazione dei PV massimi di chi combatte,
# gauge = carica dell'ultimate, energy = energia.
const BENCH: Dictionary = {
	"elle": {"heal": 0.03},
	"nami": {"shield": 0.08},
	"sera": {"gauge": 8},
	"rhea": {"energy": 1},
	"mira": {"shield": 0.04, "gauge": 4},
	"oriel": {"heal": 0.02, "shield": 0.04},
}
const BENCH_RANK_STEP: float = 0.10
const BENCH_PVP_FACTOR: float = 0.3          # in PvP l'aiuto vale meno (le squadre di guardiani erano troppo forti)
const BENCH_PVE_FACTOR: float = 1.5          # contro i boss serve di piu' (un solo operatore in campo)


static func has_bench(char_id: String) -> bool:
	return BENCH.has(char_id)


static func bench_value(char_id: String, key: String, rank: int) -> float:
	var base: float = float(BENCH.get(char_id, {}).get(key, 0.0))
	if key == "energy":
		return base + (1.0 if rank >= 3 else 0.0)
	return base * (1.0 + BENCH_RANK_STEP * float(rank))


static func bench_text(char_id: String, rank: int) -> String:
	var parts: Array = []
	var d: Dictionary = BENCH.get(char_id, {})
	if d.has("heal"):
		parts.append("cura chi combatte del %.1f%% dei PV" % (bench_value(char_id, "heal", rank) * 100.0))
	if d.has("shield"):
		parts.append("da' a chi combatte uno scudo del %.1f%% dei PV" % (bench_value(char_id, "shield", rank) * 100.0))
	if d.has("gauge"):
		parts.append("carica l'ultimate di %d" % int(round(bench_value(char_id, "gauge", rank))))
	if d.has("energy"):
		parts.append("da' +%d energia" % int(bench_value(char_id, "energy", rank)))
	return ("IN PANCHINA, a fine round: " + ", ".join(parts)) if not parts.is_empty() else ""


# Applica l'aiuto di un guardiano in panchina a chi combatte. Ritorna gli eventi (cura/scudo) da registrare.
static func apply_bench(helper: Dictionary, target: Dictionary, factor: float = 1.0) -> Array:
	var out: Array = []
	var cid: String = str(helper.get("char", ""))
	if not BENCH.has(cid):
		return out
	var rank: int = int(helper.get("rank", 0))
	var heal: float = bench_value(cid, "heal", rank) * factor
	if heal > 0.0:
		var before: int = int(target["hp"])
		target["hp"] = mini(int(target["max_hp"]), before + int(round(float(target["max_hp"]) * heal)))
		if int(target["hp"]) > before:
			out.append({"t": "heal", "src": str(helper["id"]), "dst": str(target["id"]), "amount": int(target["hp"]) - before})
	var sh: float = bench_value(cid, "shield", rank) * factor
	if sh > 0.0:
		var amount: int = int(round(float(target["max_hp"]) * sh))
		target["shield"] = int(target.get("shield", 0)) + amount
		out.append({"t": "shield", "src": str(helper["id"]), "dst": str(target["id"]), "amount": amount})
	var g: float = bench_value(cid, "gauge", rank) * factor
	if g > 0.0:
		target["gauge"] = mini(BattleTypes.GAUGE_MAX, int(target["gauge"]) + int(round(g)))
	var en: float = bench_value(cid, "energy", rank) * factor
	if en >= 1.0:
		target["energy"] = mini(BattleTypes.MAX_ENERGY, int(target["energy"]) + int(round(en)))
	return out



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
	"dafne": {"name": "Occhio del cecchino", "key": "crit_per_mark", "base": 0.025},
	"angela": {"name": "Rete di rifornimento", "key": "mark_ammo", "base": 1.0},
	"nico": {"name": "Sciarpa rossa", "key": "regen", "base": 0.035},
	"moro": {"name": "Contraccolpo", "key": "thorns", "base": 0.15},
	"vesper": {"name": "Predazione", "key": "dmg_vs_mark", "base": 0.12},
	"nami": {"name": "Guardia preparata", "key": "guard_shield", "base": 0.12},
	"oriel": {"name": "Cura schermata", "key": "heal_shield", "base": 0.25},
	"silex": {"name": "Armatura ciclica", "key": "round_shield", "base": 0.06},
	"yuna": {"name": "Fiato rubato", "key": "lifesteal", "base": 0.08},
	"rhea": {"name": "Recupero costante", "key": "regen", "base": 0.03},
	"flux": {"name": "Precisione opportunistica", "key": "crit_marked", "base": 0.12},
	"cato": {"name": "Corazza a spilli", "key": "thorns", "base": 0.12},
	"lyra": {"name": "Priorita' assoluta", "key": "dmg_vs_mark", "base": 0.1},
}

# Abilita' uniche (id -> mossa). "unique" = personaggio proprietario.
const MOVES: Dictionary = {
	"u_kira_a": {"name": "Taglio spettrale", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.8, "pierce": 60, "status": {"mark": 1},
		"bonus": {"stat": "crit", "pct": 25}, "unique": "kira"},
	"u_dax_a": {"name": "Ariete", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.3, "self_status": {"taunt": 1, "guard": 1},
		"bonus": {"stat": "def", "pct": 25}, "unique": "dax"},
	"u_elle_a": {"name": "Respiro", "kind": "skill", "cost": 2, "priority": 0, "target": "allies", "heal": 0.9, "energy": 1,
		"bonus": {"stat": "max_hp", "pct": 4}, "ally_buff": {"atk": 3}, "unique": "elle"},
	"u_bruno_a": {"name": "Parata lampo", "kind": "skill", "cost": 1, "priority": 2, "target": "ally", "shield": 1.2,
		"bonus": {"stat": "def", "pct": 20}, "unique": "bruno"},
	"u_nova_a": {"name": "Raffica marchiante", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.2, "status": {"mark": 2, "bleed": 2},
		"bonus": {"stat": "crit", "pct": 18}, "unique": "nova"},
	"u_mira_a": {"name": "Iniezione", "kind": "skill", "cost": 2, "priority": 1, "target": "ally", "heal": 1.0, "shield": 0.6, "cleanse": true,
		"bonus": {"stat": "max_hp", "pct": 5}, "ally_buff": {"atk": 3}, "unique": "mira"},
	"u_rex_a": {"name": "Carica furiosa", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 2.2, "status": {"bleed": 2},
		"bonus": {"stat": "atk", "pct": 20}, "unique": "rex"},
	"u_ivo_a": {"name": "Sgambetto", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "mult": 0.8, "status": {"mark": 1, "bleed": 1}, "energy": 1,
		"bonus": {"stat": "spd", "pct": 12}, "unique": "ivo"},
	"u_sera_a": {"name": "Ala protettiva", "kind": "skill", "cost": 2, "priority": 1, "target": "allies", "shield": 1.2,
		"bonus": {"stat": "def", "pct": 20}, "ally_buff": {"atk": 3}, "unique": "sera"},
	"u_sera_b": {"name": "Vento di coda", "kind": "skill", "cost": 2, "priority": 0, "target": "allies", "heal": 0.8, "cleanse": true, "energy": 1,
		"bonus": {"stat": "max_hp", "pct": 5}, "unique": "sera"},
	"u_eco_a": {"name": "Eco ripetuto", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.5, "status": {"mark": 2}, "debuff": {"spd": 1},
		"bonus": {"stat": "crit", "pct": 18}, "unique": "eco"},
	"u_eco_b": {"name": "Frequenza critica", "kind": "skill", "cost": 3, "priority": 0, "target": "enemy", "mult": 2.5, "pierce": 40, "debuff": {"def": 1},
		"bonus": {"stat": "crit", "pct": 30}, "unique": "eco"},
	"u_tana_a": {"name": "Bastione vivente", "kind": "skill", "cost": 2, "priority": 1, "target": "allies", "shield": 1.4, "self_status": {"taunt": 1},
		"bonus": {"stat": "def", "pct": 24}, "unique": "tana"},
	# --- DAFNE (Agent 02, tiratore scelto): marchia, buca le difese, si nasconde
	"u_dafne_a": {"name": "Marchio", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "mult": 0.4, "status": {"mark": 1},
		"bonus": {"stat": "crit", "pct": 10}, "unique": "dafne"},
	"u_dafne_b": {"name": "Colpo mirato", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "mult": 1.7, "ammo": 1, "crit_pm": 200, "debuff": {"def": 1},
		"bonus": {"stat": "crit", "pct": 20}, "unique": "dafne"},
	"u_dafne_c": {"name": "Copertura", "kind": "skill", "cost": 0, "priority": 1, "target": "self", "self_status": {"hidden": 1}, "shield": 0.35, "ammo_gain": 2, "energy": 0,
		"bonus": {"stat": "def", "pct": 15}, "unique": "dafne"},
	"coordinated_shot": {"name": "Colpo coordinato", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 2.9, "ammo": 1, "status": {"mark": 3},
		"crit_dmg_per_mark": 110, "crit_dmg_cap": 650, "debuff": {"spd": 1, "atk": 1, "def": 1}, "ally_buff": {"atk": 1, "spd": 1},
		"bonus": {"stat": "crit", "pct": 40}, "unique": "dafne"},
	# --- ANGELA (Orbital Laser Goddess, mecamante): torretta, drone, raffica, raggio orbitale che spende i marchi
	"u_angela_a": {"name": "Torretta fucile", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 0.6, "ammo": 1, "status": {"mark": 1}, "summon": "turret",
		"bonus": {"stat": "atk", "pct": 12}, "unique": "angela"},
	"u_angela_b": {"name": "Drone munizioni", "kind": "skill", "cost": 3, "priority": 0, "target": "enemy", "status": {"mark": 3}, "team_ammo": 3, "summon": "drone",
		"unique": "angela"},
	"u_angela_c": {"name": "Mitragliatrice", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 0.85, "ammo": 3, "hits": 3, "crit_pm": 250,
		"bonus": {"stat": "atk", "pct": 10}, "unique": "angela"},
	"orbital_strike": {"name": "Raggio orbitale", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 3.2, "status": {"mark": 1}, "consume_marks": 0.15,
		"bonus": {"stat": "atk", "pct": 30}, "unique": "angela"},
	"u_nico_a": {"name": "Segnale di fumo", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "mult": 0.6, "debuff": {"atk": 1},
		"bonus": {"stat": "spd", "pct": 14}, "unique": "nico"},
	"u_nico_b": {"name": "Porta aperta", "kind": "skill", "cost": 2, "priority": 1, "target": "allies", "shield": 1.1, "energy": 1,
		"bonus": {"stat": "def", "pct": 22}, "unique": "nico"},
	"u_tana_b": {"name": "Muro totale", "kind": "skill", "cost": 2, "priority": 1, "target": "self", "shield": 2.0, "self_status": {"taunt": 1, "guard": 1},
		"bonus": {"stat": "def", "pct": 40}, "unique": "tana"},
	"u_kira_b": {"name": "Pugno incanalato", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "mult": 1.45,
		"bonus": {"stat": "atk", "pct": 12}, "unique": "kira"},
	# --- Roster 2: dieci nuovi operatori (progetto con ChatGPT) ---
	"u_vesper_b": {"name": "Taglio d'ombra", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.3, "debuff": {"def": 1}, "bonus": {"stat": "atk", "pct": 10}, "unique": "vesper"},
	"u_yuna_b": {"name": "Scatto vettoriale", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 0.55, "hits": 3, "bonus": {"stat": "spd", "pct": 10}, "unique": "yuna"},
	"u_oriel_b": {"name": "Interdizione", "kind": "skill", "cost": 1, "priority": 1, "target": "ally", "shield": 1.0, "bonus": {"stat": "def", "pct": 20}, "unique": "oriel"},
	"u_flux_b": {"name": "Scarica diretta", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "mult": 1.35, "bonus": {"stat": "crit", "pct": 15}, "unique": "flux"},
	"u_lyra_b": {"name": "Esecuzione calibrata", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.7, "pierce": 25, "bonus": {"stat": "crit", "pct": 20}, "unique": "lyra"},
	"u_moro_a": {"name": "Ritorsione", "kind": "skill", "cost": 2, "priority": 1, "target": "enemy", "mult": 1.0, "self_status": {"guard": 1}, "bonus": {"stat": "def", "pct": 20}, "unique": "moro"},
	"u_moro_ult": {"name": "Legge del Contraccolpo", "kind": "ult", "cost": 0, "priority": 1, "target": "allies", "shield": 1.6, "bonus": {"stat": "def", "pct": 35}, "unique": "moro"},
	"u_vesper_a": {"name": "Taglio Predatorio", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.5, "status": {"mark": 1}, "bonus": {"stat": "crit", "pct": 15}, "unique": "vesper"},
	"u_vesper_ult": {"name": "Eclissi Cremisi", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 3.4, "pierce": 30, "bonus": {"stat": "atk", "pct": 30}, "unique": "vesper"},
	"u_nami_a": {"name": "Riparo Improvvisato", "kind": "skill", "cost": 1, "priority": 1, "target": "ally", "shield": 0.8, "bonus": {"stat": "def", "pct": 15}, "ally_buff": {"atk": 3}, "unique": "nami"},
	"u_nami_ult": {"name": "Cerchio Sicuro", "kind": "ult", "cost": 0, "priority": 1, "target": "allies", "shield": 1.4, "bonus": {"stat": "max_hp", "pct": 10}, "unique": "nami"},
	"u_oriel_a": {"name": "Protocollo di Soccorso", "kind": "skill", "cost": 2, "priority": 1, "target": "ally", "heal": 0.9, "shield": 0.5, "cleanse": true, "bonus": {"stat": "max_hp", "pct": 5}, "ally_buff": {"atk": 2}, "unique": "oriel"},
	"u_oriel_ult": {"name": "Rifugio Assoluto", "kind": "ult", "cost": 0, "priority": 1, "target": "allies", "shield": 2.0, "cleanse": true, "bonus": {"stat": "def", "pct": 40}, "unique": "oriel"},
	"u_silex_a": {"name": "Frattura Minerale", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.2, "debuff": {"def": 1}, "bonus": {"stat": "def", "pct": 20}, "unique": "silex"},
	"u_silex_ult": {"name": "Fortezza Geometrica", "kind": "ult", "cost": 0, "priority": 1, "target": "allies", "shield": 1.8, "bonus": {"stat": "def", "pct": 35}, "unique": "silex"},
	"u_yuna_a": {"name": "Passo Fulmineo", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "mult": 1.0, "status": {"mark": 1}, "bonus": {"stat": "spd", "pct": 15}, "unique": "yuna"},
	"u_yuna_ult": {"name": "Lama del Futuro", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 3.0, "pierce": 25, "bonus": {"stat": "spd", "pct": 30}, "unique": "yuna"},
	"u_rhea_a": {"name": "Ricomposizione", "kind": "skill", "cost": 2, "priority": 0, "target": "ally", "heal": 1.2, "bonus": {"stat": "max_hp", "pct": 5}, "ally_buff": {"atk": 3}, "unique": "rhea"},
	"u_rhea_ult": {"name": "Alba Condivisa", "kind": "ult", "cost": 0, "priority": 0, "target": "allies", "heal": 1.1, "cleanse": true, "bonus": {"stat": "max_hp", "pct": 10}, "unique": "rhea"},
	"u_flux_a": {"name": "Raffica Sincronizzata", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 0.65, "hits": 2, "status": {"mark": 1}, "bonus": {"stat": "atk", "pct": 12}, "unique": "flux"},
	"u_flux_ult": {"name": "Punto di Rottura", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 3.0, "pierce": 30, "bonus": {"stat": "crit", "pct": 30}, "unique": "flux"},
	"u_cato_a": {"name": "Impatto di Contenimento", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "mult": 0.9, "self_status": {"guard": 1}, "bonus": {"stat": "def", "pct": 15}, "unique": "cato"},
	"u_cato_ult": {"name": "Linea Invalicabile", "kind": "ult", "cost": 0, "priority": 1, "target": "allies", "shield": 1.5, "bonus": {"stat": "def", "pct": 30}, "unique": "cato"},
	"u_lyra_a": {"name": "Marchio di Priorita'", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "mult": 0.6, "status": {"mark": 2}, "bonus": {"stat": "crit", "pct": 10}, "unique": "lyra"},
	"u_lyra_ult": {"name": "Sentenza Coordinata", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 2.8, "status": {"mark": 1}, "debuff": {"def": 1}, "bonus": {"stat": "atk", "pct": 30}, "unique": "lyra"},
	# --- V3: i kit dei quattro (Kits, odispel/v3/KIT_PERSONAGGI.md). "kit" = effetto speciale gestito da Kits.
	# Lance organizza: protegge chi sta per essere colpito, legge i tempi, spezza la guardia.
	"u_ferri_a": {"name": "Copertura", "kind": "skill", "cost": 1, "priority": 1, "target": "self", "kit": "cover", "unique": "ferri",
		"desc": "Prendi tu il prossimo colpo diretto a un compagno (meno danno). Se il colpo è per te o per tutti, ti metti in guardia."},
	"u_ferri_ult": {"name": "Braccio della Legge", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 3.6, "pierce": 40, "kit": "arm",
		"bonus": {"stat": "atk", "pct": 20}, "unique": "ferri",
		"desc": "Via il guanto: colpo pesante che toglie quasi tutto l'equilibrio del nemico."},
	# Saul sfrutta: la fortuna, l'occasione, quello che hanno gli altri.
	"u_saul_a": {"name": "Testa o croce", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.25, "kit": "coin",
		"bonus": {"stat": "atk", "pct": 15}, "unique": "saul",
		"desc": "Lancia la moneta. Testa: critico sicuro. Croce: passa 2 energia al compagno che ne ha meno."},
	"u_saul_ult": {"name": "Il colpo grosso", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 3.4, "pierce": 30, "kit": "heist",
		"bonus": {"stat": "crit", "pct": 20}, "unique": "saul",
		"desc": "Ruba lo scudo del nemico e lo divide con la squadra. Se non ha scudi, colpisce più forte."},
	# Rio spettacolarizza: piu' pubblico ha, piu' fa.
	"u_zecca_a": {"name": "Inquadratura", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "mult": 0.7, "status": {"mark": 2}, "kit": "frame",
		"bonus": {"stat": "spd", "pct": 10}, "unique": "zecca",
		"desc": "Marchia il nemico: chi lo colpisce carica l'Ultimate. +Hype."},
	"u_zecca_ult": {"name": "Gran finale", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 1.0, "hits": 3, "kit": "finale",
		"bonus": {"stat": "atk", "pct": 10}, "unique": "zecca",
		"desc": "Tre colpi: più Hype hai, più fanno male. Sotto il 50% di Hype è un'anteprima: colpisce meno ma dà +1 energia e Ultimate ai compagni. Consuma l'Hype."},
	# Nox evita il lavoro inutile: cura quando serve, altrimenti si riposa.
	# cura alzata (1.6 -> 2.3, bonus 6% -> 10%): l'autore la trovava troppo debole; un po' di cura va anche al secondo piu' ferito
	"u_nox_a": {"name": "Pausa caffè", "kind": "skill", "cost": 2, "priority": 0, "target": "ally", "heal": 2.3, "kit": "coffee",
		"bonus": {"stat": "max_hp", "pct": 10}, "unique": "nox",
		"desc": "Cura molto il compagno più ferito (e un po' il secondo) e gli dà 1 energia. Se stanno tutti bene, offre il caffè: scudo e 1 energia a tutti, e il round dopo agisce due volte."},
	"u_nox_ult": {"name": "Rispondo io", "kind": "ult", "cost": 0, "priority": 1, "target": "self", "kit": "answer", "unique": "nox",
		"desc": "Rimette in piedi un compagno KO. Se sono tutti in piedi, annulla il prossimo colpo del nemico."},
	# --- V3: mosse che si sbloccano coi livelli (Progress, menu SQUADRA). Saul e' un ladro gentiluomo: ruba scudi, esperienza e mosse.
	"u_saul_b": {"name": "Mano lesta", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "mult": 1.0, "kit": "pickpocket",
		"bonus": {"stat": "atk", "pct": 12}, "unique": "saul",
		"desc": "Ruba lo scudo del nemico e lo tiene. Senza scudo gli sfila equilibrio e si riprende l'energia."},
	"u_saul_c": {"name": "Tasche piene", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.15, "kit": "loot_exp",
		"bonus": {"stat": "atk", "pct": 12}, "unique": "saul",
		"desc": "Colpisce e intasca: +25% di esperienza a fine scontro per tutta la squadra (fino a +50%)."},
	"u_saul_d": {"name": "Il trucco del mago", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 0.9, "kit": "steal_move",
		"bonus": {"stat": "atk", "pct": 10}, "unique": "saul",
		"desc": "Ruba una mossa al nemico, per sempre: nel menu SQUADRA tutti possono equipaggiarla."},
	"u_saul_ult2": {"name": "Il colpo del secolo", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 3.0, "pierce": 30, "kit": "heist2",
		"bonus": {"stat": "crit", "pct": 20}, "unique": "saul",
		"desc": "Il colpo grosso, ma meglio: ruba lo scudo e mezza esperienza in più per la squadra."},
	"u_ferri_b": {"name": "Fila indiana", "kind": "skill", "cost": 2, "priority": 1, "target": "allies", "shield": 0.9, "unique": "ferri",
		"bonus": {"stat": "def", "pct": 12},
		"desc": "Tutti in fila dietro di lui: scudo a tutta la squadra."},
	"u_ferri_ult2": {"name": "Mani in alto", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 2.8, "pierce": 30, "kit": "arm2",
		"bonus": {"stat": "atk", "pct": 20}, "unique": "ferri",
		"desc": "Arresto in flagranza: colpo forte che toglie moltissimo equilibrio."},
	"u_nox_b": {"name": "Camomilla", "kind": "skill", "cost": 3, "priority": 0, "target": "allies", "heal": 1.0, "unique": "nox",
		"bonus": {"stat": "max_hp", "pct": 5},
		"desc": "Una tazza per tutti: cura tutta la squadra."},
	"u_nox_ult2": {"name": "Turno doppio", "kind": "ult", "cost": 0, "priority": 1, "target": "allies", "heal": 1.7, "cleanse": true, "unique": "nox",
		"bonus": {"stat": "max_hp", "pct": 8},
		"desc": "Nox fa gli straordinari: cura forte a tutti e toglie i sanguinamenti."},
	"u_zecca_b": {"name": "Zoom", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "mult": 1.25, "kit": "zoom",
		"bonus": {"stat": "spd", "pct": 10}, "unique": "zecca",
		"desc": "Primo piano sul nemico: colpo pulito e +15 Hype."},
	"u_zecca_ult2": {"name": "Live di mezzanotte", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 0.85, "hits": 4, "kit": "finale",
		"bonus": {"stat": "atk", "pct": 10}, "unique": "zecca",
		"desc": "Quattro colpi in diretta: più Hype hai, più fanno male. Consuma l'Hype."},
	# --- V3, oltre l'atto 1 (Replica della diretta / New Game+): abilita' ai livelli 14, 35, 65 e Ultimate ai livelli 25, 55, 100.
	# Stesse regole del gruppo, piu' forti. Campi in piu' gestiti da Kits.extras: drain (equilibrio tolto), hype_gain,
	# loot / loot_cap (esperienza in piu' %), team_energy e team_gauge (a tutta la squadra).
	"u_ferri_c": {"name": "Rapporto di servizio", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.4, "debuff": {"def": 1}, "drain": 3,
		"bonus": {"stat": "atk", "pct": 14}, "unique": "ferri",
		"desc": "Verbale sul nemico: colpo, difesa giù e un po' di equilibrio in meno."},
	"u_ferri_d": {"name": "Sveglia alle 06:00", "kind": "skill", "cost": 3, "priority": 1, "target": "allies", "shield": 1.2, "team_energy": 1,
		"bonus": {"stat": "def", "pct": 16}, "unique": "ferri",
		"desc": "Partenza alle sei, appello alle sei e un minuto: scudo e 1 energia a tutta la squadra."},
	"u_ferri_e": {"name": "Copertura blindata", "kind": "skill", "cost": 2, "priority": 1, "target": "self", "kit": "cover", "shield": 1.6,
		"bonus": {"stat": "def", "pct": 22}, "unique": "ferri",
		"desc": "Come Copertura, ma prima Lance si carica di uno scudo pesante."},
	"u_ferri_ult3": {"name": "Fuori servizio", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 4.2, "pierce": 45, "drain": 12,
		"bonus": {"stat": "atk", "pct": 24}, "unique": "ferri",
		"desc": "Il turno è finito, il guanto no: colpo pesantissimo che toglie quasi tutto l'equilibrio."},
	"u_ferri_ult4": {"name": "Ultimo avviso", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 4.8, "pierce": 50, "drain": 16, "debuff": {"def": 1},
		"bonus": {"stat": "atk", "pct": 28}, "unique": "ferri",
		"desc": "L'ha detto una volta sola: colpo enorme, difesa giù, equilibrio a pezzi."},
	"u_ferri_ult5": {"name": "Ora zero", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 6.0, "pierce": 60, "drain": 20, "team_gauge": 20,
		"bonus": {"stat": "atk", "pct": 34}, "unique": "ferri",
		"desc": "Al secondo esatto: il colpo più forte di Lance svuota l'equilibrio e ricarica l'Ultimate della squadra."},
	"u_nox_c": {"name": "Caffè ristretto", "kind": "skill", "cost": 2, "priority": 0, "target": "ally", "heal": 2.8, "cleanse": true,
		"bonus": {"stat": "max_hp", "pct": 11}, "unique": "nox",
		"desc": "Poco, ma forte: cura molto un compagno e gli toglie i sanguinamenti."},
	"u_nox_d": {"name": "Aperto alle quattro", "kind": "skill", "cost": 3, "priority": 0, "target": "allies", "heal": 1.3, "team_energy": 1,
		"bonus": {"stat": "max_hp", "pct": 6}, "unique": "nox",
		"desc": "Lei sa qual è l'unico posto aperto alle quattro del mattino: cura tutta la squadra e 1 energia a tutti."},
	"u_nox_e": {"name": "Turno coperto", "kind": "skill", "cost": 3, "priority": 1, "target": "allies", "heal": 0.8, "shield": 1.3,
		"bonus": {"stat": "max_hp", "pct": 6}, "unique": "nox",
		"desc": "Nessuno resta scoperto: cura e scudo a tutta la squadra."},
	"u_nox_ult3": {"name": "Linea diretta", "kind": "ult", "cost": 0, "priority": 1, "target": "allies", "heal": 1.2, "kit": "answer",
		"bonus": {"stat": "max_hp", "pct": 6}, "unique": "nox",
		"desc": "Risponde al primo squillo: cura tutti, poi rialza chi è KO o annulla il prossimo colpo del nemico."},
	"u_nox_ult4": {"name": "Notte bianca", "kind": "ult", "cost": 0, "priority": 1, "target": "allies", "heal": 2.2, "shield": 0.8, "cleanse": true, "team_energy": 1,
		"bonus": {"stat": "max_hp", "pct": 9}, "unique": "nox",
		"desc": "Non dorme nessuno, ma stanno tutti in piedi: cura forte, scudo e 1 energia a tutti."},
	"u_nox_ult5": {"name": "Alba", "kind": "ult", "cost": 0, "priority": 1, "target": "allies", "heal": 3.0, "shield": 1.2, "cleanse": true, "kit": "answer", "team_energy": 2,
		"bonus": {"stat": "max_hp", "pct": 12}, "unique": "nox",
		"desc": "La notte è finita: cura e scudo a tutti, 2 energia, e rialza chi è a terra o annulla il prossimo colpo."},
	"u_zecca_c": {"name": "TITOLO IN MAIUSCOLO", "kind": "skill", "cost": 1, "priority": 0, "target": "enemy", "mult": 0.9, "status": {"mark": 2}, "hype_gain": 25,
		"bonus": {"stat": "spd", "pct": 10}, "unique": "zecca",
		"desc": "Il video ha già il titolo: marchia il nemico e +25 Hype."},
	"u_zecca_d": {"name": "Colonna sonora", "kind": "skill", "cost": 2, "priority": 0, "target": "allies", "ally_buff": {"atk": 1}, "hype_gain": 15, "team_gauge": 10,
		"unique": "zecca",
		"desc": "Musica per tutti, anche in ascensore: più attacco alla squadra, Ultimate più carica e +15 Hype."},
	"u_zecca_e": {"name": "Rifacciamola, raga", "kind": "skill", "cost": 3, "priority": 0, "target": "enemy", "mult": 0.95, "hits": 3, "hype_gain": 20,
		"bonus": {"stat": "atk", "pct": 10}, "unique": "zecca",
		"desc": "Era venuta male: tre colpi e +20 Hype."},
	"u_zecca_ult3": {"name": "Trend del momento", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 0.9, "hits": 5, "kit": "finale",
		"bonus": {"stat": "atk", "pct": 12}, "unique": "zecca",
		"desc": "Cinque colpi in tendenza: più Hype hai, più fanno male. Consuma l'Hype."},
	"u_zecca_ult4": {"name": "Prima serata", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 1.0, "hits": 5, "pierce": 30, "kit": "finale",
		"bonus": {"stat": "atk", "pct": 14}, "unique": "zecca",
		"desc": "Cinque colpi in prima serata che passano le difese: più Hype, più danno. Consuma l'Hype."},
	"u_zecca_ult5": {"name": "In tendenza ovunque", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 1.0, "hits": 6, "pierce": 40, "kit": "finale", "team_gauge": 15,
		"bonus": {"stat": "atk", "pct": 16}, "unique": "zecca",
		"desc": "Sei colpi visti da tutti: più Hype, più danno, e il pubblico ricarica l'Ultimate della squadra. Consuma l'Hype."},
	"u_saul_e": {"name": "Il resto sbagliato", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 0.8, "hits": 2, "kit": "pickpocket",
		"bonus": {"stat": "atk", "pct": 12}, "unique": "saul",
		"desc": "Due colpi e intanto si tiene il resto: ruba lo scudo del nemico, o gli sfila equilibrio e si riprende l'energia."},
	"u_saul_f": {"name": "Doppio o niente", "kind": "skill", "cost": 2, "priority": 0, "target": "enemy", "mult": 1.7, "kit": "coin",
		"bonus": {"stat": "atk", "pct": 18}, "unique": "saul",
		"desc": "La moneta, ma a posta doppia. Testa: critico sicuro. Croce: 2 energia al compagno che ne ha meno."},
	"u_saul_g": {"name": "Interessi composti", "kind": "skill", "cost": 3, "priority": 0, "target": "enemy", "mult": 1.5, "loot": 25, "loot_cap": 100, "team_energy": 1,
		"bonus": {"stat": "atk", "pct": 14}, "unique": "saul",
		"desc": "Colpisce, intasca esperienza (+25%, fino a +100%) e dà 1 energia a tutti. Gli interessi li calcola dopo."},
	"u_saul_ult3": {"name": "Il colpo del millennio", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 3.8, "pierce": 35, "kit": "heist2",
		"bonus": {"stat": "crit", "pct": 24}, "unique": "saul",
		"desc": "Il colpo del secolo era poco: ruba lo scudo e lo divide, colpisce più forte e mezza esperienza in più."},
	"u_saul_ult4": {"name": "Fortuna sfacciata", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 4.6, "pierce": 40, "kit": "coin",
		"bonus": {"stat": "crit", "pct": 28}, "unique": "saul",
		"desc": "Tira la moneta sul colpo grosso. Testa: critico sicuro. Croce: 2 energia a un compagno. Va bene comunque."},
	"u_saul_ult5": {"name": "Il colpo di una vita", "kind": "ult", "cost": 0, "priority": 0, "target": "enemy", "mult": 5.6, "pierce": 50, "kit": "heist2", "team_gauge": 15,
		"bonus": {"stat": "crit", "pct": 32}, "unique": "saul",
		"desc": "Il colpo grosso di tutta una carriera: ruba lo scudo, danno enorme, esperienza in più e Ultimate a tutta la squadra."},
}

# Rank che sblocca ogni abilita' unica: tutte subito (il rank ora le potenzia invece di sbloccarle).
const UNLOCK: Dictionary = {}

const SKILLS: Dictionary = {
	"kira": ["u_kira_a", "u_kira_b"], "dax": ["u_dax_a"], "elle": ["u_elle_a"], "bruno": ["u_bruno_a"],
	"nova": ["u_nova_a"], "mira": ["u_mira_a"], "rex": ["u_rex_a"], "ivo": ["u_ivo_a"],
	"sera": ["u_sera_a", "u_sera_b"], "eco": ["u_eco_a", "u_eco_b"], "tana": ["u_tana_a", "u_tana_b"],
	"dafne": ["u_dafne_b", "u_dafne_c"], "angela": ["u_angela_b", "u_angela_c"],
	"nico": ["u_nico_a", "u_nico_b"],
	"moro": ["u_moro_a"],
	"vesper": ["u_vesper_a", "u_vesper_b"],
	"nami": ["u_nami_a"],
	"oriel": ["u_oriel_a", "u_oriel_b"],
	"silex": ["u_silex_a"],
	"yuna": ["u_yuna_a", "u_yuna_b"],
	"rhea": ["u_rhea_a"],
	"flux": ["u_flux_a", "u_flux_b"],
	"cato": ["u_cato_a"],
	"lyra": ["u_lyra_a", "u_lyra_b"],
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
	return float(d["base"]) * (1.0 + passive_scale(char_id) * float(rank))


static func passive_text(char_id: String, rank: int) -> String:
	var d: Dictionary = PASSIVES.get(char_id, {})
	if d.is_empty():
		return ""
	var v: float = passive_value(char_id, rank)
	var key: String = str(d["key"])
	var shown: String = "%d" % int(round(v)) if (key == "gauge_regen" or key == "mark_ammo") else ("%.1f" % (v * 100.0)).trim_suffix(".0")
	return str(KEY_TEXT[key]) % shown


# Abilita' uniche disponibili a quel rank.
static func unlock_rank(char_id: String, index: int) -> int:
	var table: Array = UNLOCK.get(char_id, [0, 0])
	return int(table[mini(index, table.size() - 1)])


static func skills_for(char_id: String, rank: int) -> Array:
	var out: Array = []
	var all: Array = SKILLS.get(char_id, [])
	for i in all.size():
		if rank >= unlock_rank(char_id, i):
			out.append(str(all[i]))
	return out


# Tutte (anche quelle ancora bloccate), con il rank che le sblocca.
static func all_skills(char_id: String) -> Array:
	var out: Array = []
	var all: Array = SKILLS.get(char_id, [])
	for i in all.size():
		out.append({"id": str(all[i]), "rank": unlock_rank(char_id, i)})
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
	return m * Atypical.damage_mult(attacker, defender)


static func crit_bonus(state: Dictionary, attacker: Dictionary, defender: Dictionary) -> int:
	var total: int = 0
	var v: float = value(attacker, "crit_marked")
	if v > 0.0 and defender.get("statuses", {}).has("mark"):
		total += int(round(v * 1000.0))
	# Occhio del cecchino: +critico per ogni marchio applicato nella battaglia (con tetto)
	var per: float = value(attacker, "crit_per_mark")
	if per > 0.0:
		total += mini(int(round(per * 1000.0 * float(mini(int(state.get("marks_applied", 0)), CRIT_PER_MARK_CAP)))), 1000)
	return total


static func _rarity(char_id: String) -> int:
	return clampi(int(BattleContent.CHARACTERS.get(char_id, {}).get("rarity", 0)), 0, 3)


static func passive_scale(char_id: String) -> float:
	return float(PASSIVE_SCALE_BY_RARITY[_rarity(char_id)])


static func skill_pct(char_id: String) -> float:
	return float(SKILL_UP_BY_RARITY[_rarity(char_id)])


static func ult_pct(char_id: String) -> float:
	return float(ULT_UP_BY_RARITY[_rarity(char_id)])


# Quale skill del kit e' questa mossa: 1 (prima unica), 2 (seconda unica, o la skill di base se ne ha una sola), 0 = nessuna.
static func skill_slot(char_id: String, move_id: String) -> int:
	var all: Array = SKILLS.get(char_id, [])
	if not all.is_empty() and str(all[0]) == move_id:
		return 1
	var second: String = str(all[1]) if all.size() > 1 else str(BattleContent.CHARACTERS.get(char_id, {}).get("skill", ""))
	return 2 if second != "" and second == move_id else 0


# Quanti gradi di potenziamento ha una skill (0-2) o l'ultimate (0-2) a quel rank.
static func skill_grade(slot: int, rank: int) -> int:
	if slot == 1:
		return (1 if rank >= 1 else 0) + (1 if rank >= 4 else 0)
	if slot == 2:
		return (1 if rank >= 2 else 0) + (1 if rank >= 4 else 0)
	return 0


static func ult_grade(rank: int) -> int:
	return (1 if rank >= 3 else 0) + (1 if rank >= 5 else 0)


static func upgrade_grade(u: Dictionary, move_id: String, kind: String) -> int:
	var char_id: String = str(u.get("char", ""))
	var rank: int = int(u.get("rank", 0))
	if kind == "ult":
		return ult_grade(rank)
	if kind == "skill":
		return skill_grade(skill_slot(char_id, move_id), rank)
	return 0


# Moltiplicatore di potenza (danno, cure, scudi) di una mossa dell'unita', dato il suo rank.
static func upgrade_mult(u: Dictionary, move_id: String, kind: String) -> float:
	var char_id: String = str(u.get("char", ""))
	var rank: int = int(u.get("rank", 0))
	if kind == "ult":
		return 1.0 + ult_pct(char_id) * float(ult_grade(rank))
	if kind == "skill":
		return 1.0 + skill_pct(char_id) * float(skill_grade(skill_slot(char_id, move_id), rank))
	return 1.0


# Cosa da' un rank (per la scheda e per i messaggi di rank up).
static func rank_perk_text(char_id: String, rank: int) -> String:
	var parts: Array = ["+%d%% STAT" % int(round(BattleContent.rank_bonus(_rarity(char_id)) * 100.0 * float(rank)))]
	if has_passive(char_id):
		parts.append("PASSIVA +%d%%" % int(round(passive_scale(char_id) * 100.0 * float(rank))))
	if rank >= AWAKEN_RANK:
		parts.append("RISVEGLIO")
	return " · ".join(parts)


# Nome della skill 1 / skill 2 del kit (per i testi).
static func skill_name(char_id: String, slot: int) -> String:
	var all: Array = SKILLS.get(char_id, [])
	var id: String = ""
	if slot == 1 and not all.is_empty():
		id = str(all[0])
	elif slot == 2:
		id = str(all[1]) if all.size() > 1 else str(BattleContent.CHARACTERS.get(char_id, {}).get("skill", ""))
	return BattleText.move_name(id) if id != "" else ""


# Cosa da' il rank indicato, in una frase ("" per il rank 0).
static func rank_upgrade_text(char_id: String, rank: int) -> String:
	var sp: int = int(round(skill_pct(char_id) * 100.0))
	var up: int = int(round(ult_pct(char_id) * 100.0))
	match rank:
		1:
			return "SKILL 1 POTENZIATA: %s +%d%%" % [skill_name(char_id, 1), sp]
		2:
			return "SKILL 2 POTENZIATA: %s +%d%%" % [skill_name(char_id, 2), sp]
		3:
			return "ULTIMATE POTENZIATA: +%d%%" % up
		4:
			return "SKILL 1 E 2 POTENZIATE ANCORA: %s e %s +%d%%" % [skill_name(char_id, 1), skill_name(char_id, 2), sp * 2]
		5:
			return "ULTIMATE POTENZIATA ANCORA: +%d%% · RISVEGLIO: parte con +%d di carica" % [up * 2, AWAKEN_GAUGE]
	return ""


# Il prossimo traguardo ("" se si e' al massimo).
static func next_milestone(char_id: String, rank: int) -> String:
	if rank >= AWAKEN_RANK:
		return ""
	return "RANK %d: %s" % [rank + 1, rank_upgrade_text(char_id, rank + 1)]


# Cosa si e' appena ottenuto salendo a questo rank ("" se rank 0).
static func rank_unlock_text(char_id: String, rank: int) -> String:
	return rank_upgrade_text(char_id, rank)
