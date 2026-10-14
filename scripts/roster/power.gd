class_name Power
extends RefCounted

# POTERE: un solo numero per misurare quanto e' forte un personaggio (e la squadra, e tutto l'account).
# Si calcola dalle statistiche vere (quindi conta livello, rank, equipaggiamento e bonus dei titoli):
#   potere = PV/10 + ATK*2 + DEF*1.5 + VEL
# Il dettaglio mostra quanto ci mette ogni fonte, cosi' si vede crescere quando si sale di livello, rank, ecc.
# roster["power"] = {"seen": n}  e' l'ultimo totale visto: serve a mostrare "+N" dalla volta scorsa.

static func of_stats(st: Dictionary) -> int:
	return int(round(float(st["hp"]) / 10.0 + float(st["atk"]) * 2.0 + float(st["def"]) * 1.5 + float(st["spd"])))


static func of_entry(entry: Dictionary) -> int:
	return of_stats(BattleContent.compute_stats(entry))


# Scheda di un personaggio posseduto, con i bonus dei titoli.
static func entry_of(roster: Dictionary, char_id: String, icons: Array = [], act: Variant = null) -> Dictionary:
	var e: Dictionary = (roster["characters"][char_id] as Dictionary).duplicate(true)
	e["char"] = char_id
	Titles.decorate_entry(roster, e, icons, act)
	return e


static func of_character(roster: Dictionary, char_id: String, icons: Array = [], act: Variant = null) -> int:
	if not RosterState.owns(roster, char_id):
		return 0
	return of_entry(entry_of(roster, char_id, icons, act))


# {total, base, level, rank, gear, titles}: quanto aggiunge ogni fonte (sommano al totale).
static func breakdown(roster: Dictionary, char_id: String, icons: Array = []) -> Dictionary:
	var full: Dictionary = entry_of(roster, char_id, icons)
	var step: Dictionary = {"char": char_id, "level": 1, "rank": 0}
	var p_base: int = of_entry(step)
	step["level"] = int(full.get("level", 1))
	var p_level: int = of_entry(step)
	step["rank"] = int(full.get("rank", 0))
	var p_rank: int = of_entry(step)
	step["gear"] = full.get("gear", [])
	step["passives"] = full.get("passives", [])
	var p_gear: int = of_entry(step)
	var p_total: int = of_entry(full)
	return {"total": p_total, "base": p_base, "level": p_level - p_base, "rank": p_rank - p_level,
		"gear": p_gear - p_rank, "titles": p_total - p_gear}


static func team(roster: Dictionary, icons: Array = []) -> int:
	var n: int = 0
	var act: Array = Titles.active(roster, icons)
	for id in roster.get("team", []):
		n += of_character(roster, str(id), icons, act)
	return n


static func account(roster: Dictionary, icons: Array = []) -> int:
	var n: int = 0
	var act: Array = Titles.active(roster, icons)
	for id in roster.get("characters", {}):
		n += of_character(roster, str(id), icons, act)
	return n


# Grado leggibile del potere di un singolo personaggio.
static func tier_name(power: int) -> String:
	if power >= 2500:
		return "MITICO"
	if power >= 1500:
		return "ELITE"
	if power >= 800:
		return "FORTE"
	if power >= 400:
		return "ESPERTO"
	return "RECLUTA"


# Differenza dall'ultima volta che il giocatore ha guardato (0 se mai guardato).
static func delta(roster: Dictionary, icons: Array = []) -> int:
	var seen: int = int((roster.get("power", {}) as Dictionary).get("seen", 0))
	if seen <= 0:
		return 0
	return account(roster, icons) - seen


static func mark_seen(roster: Dictionary, icons: Array = []) -> void:
	roster["power"] = {"seen": account(roster, icons)}
