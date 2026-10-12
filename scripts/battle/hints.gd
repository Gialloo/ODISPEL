class_name Hints
extends RefCounted

# Schede informative della battaglia: cosa significa ogni icona, aura, classe e mossa.
# Funzioni pure (stato in ingresso, testo in uscita): la grafica le mostra al passaggio del mouse o al tocco.
# Ogni scheda: {title, body, color}.

const FACTION_COLORS: Dictionary = {
	"libracorp": Color("#7cf0ff"),
	"rondini": Color("#f2fdff"),
	"magabondi": Color("#ffd25f"),
	"kairos": Color("#ff2d55"),
}
const FACTION_CODES: Dictionary = {"libracorp": "LC", "rondini": "RN", "magabondi": "MB", "kairos": "KR"}
const STAT_WORDS: Dictionary = {"atk": "attacco", "def": "difesa", "spd": "velocita'", "crit": "probabilita' di critico"}


static func faction_color(faction: String) -> Color:
	return FACTION_COLORS.get(faction, BattleTheme.CY)


static func faction_code(faction: String) -> String:
	return str(FACTION_CODES.get(faction, "--"))


static func _card(title: String, body: Array, color: Color) -> Dictionary:
	return {"title": title, "body": "\n".join(PackedStringArray(body)), "color": color}


static func faction_card(u: Dictionary) -> Dictionary:
	var f: String = str(u.get("faction", ""))
	if f == "":
		return _card("SENZA FAZIONE", ["Non da' ne' riceve aure."], BattleTheme.CY_DIM)
	var info: Dictionary = Factions.FACTIONS[f]
	var t: Dictionary = StrategyInfo.faction_text(f)
	var style: String = str(u.get("style", "ortodosso"))
	var body: Array = [
		"DOTTRINA: %s" % str(info["doctrine"]).to_upper(),
		str(t.get("idea", "")),
		"COME SI VINCE: " + str(t.get("win", "")),
		"STILE %s: %s" % [style.to_upper(), str(StrategyInfo.STYLES.get(style, ""))],
	]
	return _card(str(info["name"]).to_upper(), body, faction_color(f))


static func aura_card(state: Dictionary, u: Dictionary) -> Dictionary:
	var f: String = str(u.get("faction", ""))
	var color: Color = faction_color(f)
	if f == "":
		return _card("AURA", ["Nessuna fazione, nessuna aura."], BattleTheme.CY_DIM)
	if Factions.is_suppressed(state, f):
		return _card("AURA SPENTA", ["Le aure di %s sono spente per qualche turno." % Factions.name_of(f)], BattleTheme.RD)
	var stat: String = Factions.aura_stat(f)
	var body: Array = []
	var aura: Dictionary = u.get("aura", {})
	if stat == "":
		body.append("%s non da' aure." % Factions.name_of(f))
		if str(f) == "magabondi":
			body.append("Riceve meta' dell'aura piu' forte della squadra.")
	else:
		var total: int = int(aura.get(stat, 0))
		body.append("%s +%.1f%% (massimo +%.0f%%)" % [str(STAT_WORDS.get(stat, stat)).to_upper(), float(total) / 10.0, float(Factions.AURA_CAP_PM) / 10.0])
		for s in Factions.aura_sources(state, u):
			body.append("- %s: +%.1f%%" % [str(s["name"]), float(s["pm"]) / 10.0])
		body.append("L'aura cresce con la rarita' di chi la da' e sparisce se va K.O.")
	if int(u.get("crit", 0)) > 0:
		body.append("CRITICO: %.1f%% di probabilita', danno x%.1f." % [float(u["crit"]) / 10.0, float(Factions.CRIT_DMG_PM) / 1000.0])
	return _card("AURA %s" % Factions.name_of(f).to_upper(), body, color)


static func ammo_card(u: Dictionary) -> Dictionary:
	var body: Array = [
		"MUNIZIONI: %d / %d" % [int(u.get("ammo", 0)), int(u.get("ammo_max", 0))],
		"Ogni CONTRATTACCO ne costa 1: se vieni colpito e resti in piedi, rispondi al boss.",
		"Colpo mirato (1) e Colpo alla testa (2) ne consumano e ignorano meta' della difesa.",
		"RICARICA le riporta a %d, la GUARDIA ne da' 1." % BattleTypes.AMMO_MAX,
	]
	if int(u.get("ammo", 0)) == 0:
		body.append("A SECCO: niente contrattacco finche' non ricarichi!")
	return _card("MUNIZIONI", body, faction_color("libracorp"))


static func mods_card(u: Dictionary) -> Dictionary:
	var body: Array = []
	for m in u.get("mods", []):
		var id: String = str(m["id"])
		body.append("%s: %s %+.1f%% (ancora %d turni)" % [mod_name(id), str(STAT_WORDS.get(str(m["stat"]), m["stat"])), float(m["pm"]) / 10.0, int(m["turns"])])
	if body.is_empty():
		body.append("Nessun effetto attivo.")
	return _card("EFFETTI ATTIVI", body, BattleTheme.GOLD)


static func mod_name(id: String) -> String:
	if id.begins_with("protocollo"):
		return "PROTOCOLLO"
	return id.to_upper()


static func class_card(u: Dictionary) -> Dictionary:
	var cls: String = str(u.get("cls", ""))
	var t: Dictionary = StrategyInfo.class_text(cls)
	if t.is_empty():
		return _card(cls.to_upper(), [""], BattleTheme.CY_DIM)
	var body: Array = [str(t["role"]), "COSA FA: " + str(t["does"])]
	for n in t["needs"]:
		body.append("- " + str(n))
	return _card("CLASSE " + str(t["label"]), body, BattleTheme.CY)


# Scheda di una mossa per l'operatore u. err: motivo per cui non si puo' usare ora ("" = disponibile).
static func move_card(u: Dictionary, move_id: String, err: String = "") -> Dictionary:
	var m: Dictionary = BattleContent.MOVES.get(move_id, {})
	var body: Array = []
	var kind: String = str(m.get("kind", "basic"))
	match kind:
		"skill":
			var cost: String = "COSTO: %d energia" % int(m["cost"])
			if int(m.get("ammo", 0)) > 0:
				cost += " + %d munizioni" % int(m["ammo"])
			body.append(cost)
		"ult":
			body.append("ULTIMATE: serve la barra piena (%d)." % BattleTypes.GAUGE_MAX)
		_:
			body.append("Azione base, gratuita.")
	body.append_array(effect_lines(m, u))
	if err != "":
		body.append("NON DISPONIBILE: " + err + ".")
	return _card(BattleText.move_name(move_id), body, BattleTheme.RD if kind == "ult" else BattleTheme.CY)


static func effect_lines(m: Dictionary, u: Dictionary = {}) -> Array:
	var out: Array = []
	if m.has("mult"):
		var line: String = "Danno x%.1f." % float(m["mult"])
		if int(m.get("pierce", 0)) > 0:
			line += " Ignora il %d%% della difesa." % int(m["pierce"])
		out.append(line)
		if int(u.get("crit", 0)) > 0:
			out.append("Critico: %.1f%% (x%.1f)." % [float(u["crit"]) / 10.0, float(Factions.CRIT_DMG_PM) / 1000.0])
	if m.has("heal"):
		out.append("Cura x%.1f del tuo attacco." % float(m["heal"]))
	if m.has("shield"):
		out.append("Scudo x%.1f del tuo attacco." % float(m["shield"]))
	if m.has("bonus"):
		var bn: Dictionary = m["bonus"]
		var amount: String = "%d" % int(round(BattleContent.move_bonus(u, m))) if not u.is_empty() else ""
		out.append("+%s%% di %s%s." % [BattleText._pct_text(float(bn["pct"])), str(BattleContent.STAT_NAMES.get(bn["stat"], "")), (" (= +%s adesso)" % amount) if amount != "" else ""])
	for s in m.get("status", {}):
		if str(s) == "mark":
			out.append("Applica %d MARCHI: ogni marchio = +10%% danni al bersaglio (+15%% ai colpi a munizioni)." % int(m["status"][s]))
		else:
			out.append("Applica %s per %d turni." % [BattleText.status_name(str(s)), int(m["status"][s])])
	if int(m.get("hits", 1)) > 1:
		out.append("%d colpi in un'azione." % int(m["hits"]))
	if int(m.get("crit_pm", 0)) > 0:
		out.append("Critico piu' probabile (+%.1f%%)." % (float(m["crit_pm"]) / 10.0))
	if m.has("crit_dmg_per_mark"):
		out.append("Danno critico +%.0f%% per marchio (max +%.0f%%)." % [float(m["crit_dmg_per_mark"]) / 10.0, float(m.get("crit_dmg_cap", 650)) / 10.0])
	if m.has("consume_marks"):
		out.append("CONSUMA tutti i marchi: +%d%% danno per ognuno." % int(round(float(m["consume_marks"]) * 100.0)))
	for st in m.get("debuff", {}):
		out.append("Bersaglio: %s -%d grado per 2 turni." % [str(BattleContent.STAT_NAMES.get(str(st), str(st).to_upper())), int(m["debuff"][st])])
	if m.has("ally_buff"):
		out.append("Alleati: ATK e VEL su di un grado.")
	if m.has("team_ammo"):
		out.append("Tutta la squadra LibraCorp: +%d munizioni." % int(m["team_ammo"]))
	if m.has("summon"):
		if str(m["summon"]) == "turret":
			out.append("TORRETTA: spara ogni round (-1 mun). A secco ESPLODE sul boss.")
		else:
			out.append("DRONE: scosse ogni round (-1 mun). A secco ESPLODE in SCUDI per la squadra.")
	if str(m.get("kind", "")) != "guard" and m.has("mult") and not u.is_empty() and Factions.ronda_ready(u):
		out.append("RONDA PRONTA: esce in forma POTENZIATA (+30% danno, piu' critico).")
	for s in m.get("self_status", {}):
		out.append("Ti da' %s (%d turno)." % [BattleText.status_name(str(s)), int(m["self_status"][s])])
	if bool(m.get("cleanse", false)):
		out.append("Toglie il sanguinamento.")
	if int(m.get("energy", 0)) > 0:
		out.append("Ridona %d energia." % int(m["energy"]))
	if int(m.get("ammo_gain", 0)) > 0:
		out.append("Ricarica %d munizioni (solo LibraCorp)." % int(m["ammo_gain"]))
	if int(m.get("priority", 0)) > 0:
		out.append("Agisce prima delle altre mosse.")
	return out
