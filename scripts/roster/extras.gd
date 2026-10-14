class_name Extras
extends RefCounted

# Funzioni di contorno della battaglia che si ricordano da una partita all'altra:
#  - MAESTRIA: ogni mossa usata tanto sale di livello (salvata in roster["mastery"]); il livello (0..3) vale +4% per livello.
#  - RIENTRO: dopo 3 sconfitte di fila la battaglia dopo parte con un piccolo aiuto (Riserva +2 e un po' di scudo).
#  - IL BOSS IMPARA: se hai gia' battuto un boss, la volta dopo ha imparato qualcosa dal tuo stile e si presenta con una contromisura chiara.
# Tutto e' deterministico e vive nel salvataggio o nello stato di battaglia (che e' gia' JSON).

const MASTERY_STEP: int = 25                # usi per livello (come Tactics.MASTERY_STEP)
const MASTERY_MAX: int = 3
const COMEBACK_AFTER: int = 3               # sconfitte di fila
const COMEBACK_RESERVE: int = 2
const COMEBACK_SHIELD: float = 0.10         # in % dei PV massimi

# Contromisure del boss per lo stile con cui e' stato battuto l'ultima volta.
const LEARNED: Dictionary = {
	"DIFENSIVO": {"name": "HA IMPARATO LA PAZIENZA", "desc": "Hai vinto parando tutto: ora colpisce piu' forte (+8% attacco).", "atk": 0.08},
	"COORDINATO": {"name": "HA IMPARATO A ROMPERE LE SINERGIE", "desc": "Hai vinto con le combo: ora ha piu' difesa (+8%).", "def": 0.08},
	"INCISIVO": {"name": "HA IMPARATO A PROTEGGERSI", "desc": "Hai vinto spezzando le guardie: ora ha una placca in piu' e piu' equilibrio.", "plate": 1, "balance": 1},
}


# ---------- Maestria ----------

static func _mastery(roster: Dictionary) -> Dictionary:
	if not roster.has("mastery") or not (roster["mastery"] is Dictionary):
		roster["mastery"] = {}
	return roster["mastery"]


static func level_of_uses(uses: int) -> int:
	return clampi(uses / MASTERY_STEP, 0, MASTERY_MAX)


static func uses_of(roster: Dictionary, char_id: String, move_id: String) -> int:
	return int((_mastery(roster).get(char_id, {}) as Dictionary).get(move_id, 0))


static func levels_for(roster: Dictionary, char_id: String) -> Dictionary:
	var out: Dictionary = {}
	for m in (_mastery(roster).get(char_id, {}) as Dictionary):
		var lv: int = level_of_uses(int(roster["mastery"][char_id][m]))
		if lv > 0:
			out[str(m)] = lv
	return out


# Aggiunge gli usi della battaglia. Ritorna le righe "MAESTRIA: ..." per i livelli appena saliti.
static func record_mastery(roster: Dictionary, stats: Dictionary) -> Array:
	var lines: Array = []
	var store: Dictionary = _mastery(roster)
	var uses: Dictionary = stats.get("uses", {})
	for cid in uses:
		if not roster.get("characters", {}).has(str(cid)):
			continue
		if not store.has(str(cid)) or not (store[str(cid)] is Dictionary):
			store[str(cid)] = {}
		for mid in uses[cid]:
			var before: int = int(store[str(cid)].get(str(mid), 0))
			var after: int = before + int(uses[cid][mid])
			store[str(cid)][str(mid)] = after
			if level_of_uses(after) > level_of_uses(before):
				var cname: String = str(BattleContent.CHARACTERS.get(str(cid), {}).get("name", cid))
				lines.append("MAESTRIA: %s · %s livello %d" % [cname, BattleText.move_name(str(mid)), level_of_uses(after)])
	return lines


static func decorate_entry(roster: Dictionary, entry: Dictionary) -> void:
	var lv: Dictionary = levels_for(roster, str(entry.get("char", "")))
	if not lv.is_empty():
		entry["mastery"] = lv


# Un'entry che arriva dalla rete: livelli interi tra 0 e il massimo.
static func mastery_valid(entry: Dictionary) -> bool:
	if not entry.has("mastery"):
		return true
	if not (entry["mastery"] is Dictionary):
		return false
	for k in (entry["mastery"] as Dictionary):
		var v: int = int(entry["mastery"][k])
		if v < 0 or v > MASTERY_MAX:
			return false
	return true


# ---------- Rientro dopo le sconfitte ----------

static func _streak(roster: Dictionary) -> Dictionary:
	if not roster.has("streak") or not (roster["streak"] is Dictionary):
		roster["streak"] = {"losses": 0}
	roster["streak"]["losses"] = int(roster["streak"].get("losses", 0))
	return roster["streak"]


static func losses(roster: Dictionary) -> int:
	return int(_streak(roster)["losses"])


static func record_result(roster: Dictionary, won: bool) -> void:
	var s: Dictionary = _streak(roster)
	s["losses"] = 0 if won else int(s["losses"]) + 1


static func comeback_ready(roster: Dictionary) -> bool:
	return losses(roster) >= COMEBACK_AFTER


# Applica l'aiuto alla battaglia (e la segna nello stato: serve all'interfaccia e al resoconto).
static func apply_comeback(state: Dictionary) -> void:
	state["comeback"] = 1
	state["reserve"] = int(state.get("reserve", 0)) + COMEBACK_RESERVE
	for uid in state["units"]:
		var u: Dictionary = state["units"][uid]
		if str(u["side"]) == "player":
			u["shield"] = int(u["shield"]) + int(round(float(u["max_hp"]) * COMEBACK_SHIELD))


# ---------- Il boss impara ----------

static func _learned(roster: Dictionary) -> Dictionary:
	if not roster.has("learned") or not (roster["learned"] is Dictionary):
		roster["learned"] = {}
	return roster["learned"]


static func style_vs(roster: Dictionary, boss_id: String) -> String:
	return str(_learned(roster).get(boss_id, ""))


# Dopo una vittoria: ricorda con quale stile hai battuto il boss (solo se lo stile e' chiaro).
static func remember(roster: Dictionary, boss_id: String, won: bool, stats: Dictionary) -> void:
	if not won:
		return
	var style: String = Discoveries.style_of(stats)
	if style != "" and LEARNED.has(style):
		_learned(roster)[boss_id] = style


# All'inizio di una battaglia: la contromisura del boss. Ritorna il testo ("" se non c'e').
static func apply_learned(state: Dictionary, style: String) -> String:
	if style == "" or not LEARNED.has(style):
		return ""
	var c: Dictionary = LEARNED[style]
	var boss: Dictionary = BattleState.boss(state)
	if boss.is_empty():
		return ""
	if c.has("atk"):
		boss["atk"] = int(round(float(boss["atk"]) * (1.0 + float(c["atk"]))))
		if boss.has("base"):
			boss["base"]["atk"] = boss["atk"]
	if c.has("def"):
		boss["def"] = int(round(float(boss["def"]) * (1.0 + float(c["def"]))))
		if boss.has("base"):
			boss["base"]["def"] = boss["def"]
	if c.has("plate"):
		boss["plates"] = int(boss.get("plates", 0)) + int(c["plate"])
		if not boss.has("plate_max"):
			boss["plate_max"] = maxi(1, int(round(float(boss["max_hp"]) * Tactics.PLATE_PCT)))
		boss["plate_hp"] = int(boss["plate_max"])
	if c.has("balance"):
		boss["balance_max"] = int(boss["balance_max"]) + int(c["balance"])
		boss["balance"] = int(boss["balance_max"])
	state["learned"] = {"style": style, "name": str(c["name"])}
	return "%s: %s" % [str(c["name"]), str(c["desc"])]
