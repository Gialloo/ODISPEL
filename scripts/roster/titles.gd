class_name Titles
extends RefCounted

# TITOLI: riconoscimenti dell'account, epici e leggendari, con un piccolo bonus PERMANENTE per i personaggi.
# Non si "riscuotono": si ottengono da soli quando la condizione e' vera (e quindi valgono anche per chi
# ha gia' giocato prima di questa versione). Il bonus e' in "punti base" (100 = 1%) e finisce nella
# scheda del personaggio come entry["acc"] = {hp, atk, def}, cosi' vale in ogni battaglia, anche online.
#
# Ogni titolo appartiene a una LINEA (es. "maestria_rosso"): conta solo il piu' alto ottenuto della linea,
# quindi il leggendario SOSTITUISCE l'epico (+0,5% -> +1%), non si somma.
#
# Ambito (scope): "all" = tutti i personaggi, "color:rosso", "faction:kairos", "class:vanguard".
# Statistica: "hp" (PV), "atk" (attacco = danni), "def" (difesa).

const EPIC: int = 2
const LEGENDARY: int = 3
const MAX_BP: int = 1500                 # tetto totale per statistica (15%)
const STATS: Array = ["hp", "atk", "def"]
const STAT_NAMES: Dictionary = {"hp": "PV", "atk": "danni", "def": "difesa"}
const COLORS: Array = ["rosso", "blu", "verde", "giallo", "viola"]
const CLASS_STAT: Dictionary = {"striker": "atk", "vanguard": "def", "warden": "hp"}
const CLASS_NAMES: Dictionary = {"striker": "Striker", "vanguard": "Vanguard", "warden": "Warden"}

# Bonus dei titoli-icona (le icone epiche e leggendarie del profilo): id icona -> [stat, punti base].
const ICON_BONUS: Dictionary = {
	"e_kairos": ["hp", 25], "e_libracorp": ["def", 25], "e_rondini": ["atk", 25], "e_magabondi": ["hp", 25],
	"e_studioso": ["atk", 25],
	"l_striker": ["atk", 50], "l_vanguard": ["def", 50], "l_warden": ["hp", 50], "l_duello": ["atk", 50],
}

static var _all: Array = []


static func _t(id: String, line: String, name: String, rarity: int, scope: String, stat: String, bp: int, metric: String, arg: String, goal: int, desc: String) -> Dictionary:
	return {"id": id, "line": line, "name": name, "rarity": rarity, "scope": scope, "stat": stat, "bp": bp,
		"metric": metric, "arg": arg, "goal": goal, "desc": desc}


static func all() -> Array:
	if not _all.is_empty():
		return _all
	var out: Array = []
	# titoli-icona del profilo
	for icon_id in ICON_BONUS:
		var info: Array = Profile.ICONS[icon_id]
		var ib: Array = ICON_BONUS[icon_id]
		out.append(_t("icon_" + icon_id, "icon_" + icon_id, str(info[0]), int(info[1]), "all", str(ib[0]), int(ib[1]), "icon", icon_id, 1,
			"Sblocca l'icona «%s» del profilo." % str(info[0])))
	# maestria dei colori
	for c in COLORS:
		out.append(_t("mc_%s_e" % c, "maestria_" + c, "Maestria del %s" % c, EPIC, "color:" + c, "atk", 50, "owned_color", c, 2,
			"Possiedi 2 operatori %s." % c))
		out.append(_t("mc_%s_l" % c, "maestria_" + c, "Maestria del %s · Suprema" % c, LEGENDARY, "color:" + c, "atk", 100, "owned_color", c, 4,
			"Possiedi 4 operatori %s." % c))
	# fazioni
	for f in Factions.FACTIONS:
		var fname: String = Factions.name_of(str(f))
		out.append(_t("fz_%s_e" % f, "fazione_" + str(f), "Alleato: %s" % fname, EPIC, "faction:" + str(f), "hp", 50, "owned_faction", str(f), 3,
			"Possiedi 3 operatori di %s." % fname))
		out.append(_t("fz_%s_l" % f, "fazione_" + str(f), "Colonna di %s" % fname, LEGENDARY, "faction:" + str(f), "hp", 100, "owned_faction", str(f), 5,
			"Possiedi 5 operatori di %s." % fname))
	# classi
	for cls in CLASS_STAT:
		out.append(_t("cl_%s_e" % cls, "classe_" + cls, "Scuola %s" % CLASS_NAMES[cls], EPIC, "class:" + cls, str(CLASS_STAT[cls]), 40, "owned_class", cls, 3,
			"Possiedi 3 operatori %s." % CLASS_NAMES[cls]))
		out.append(_t("cl_%s_l" % cls, "classe_" + cls, "Maestro %s" % CLASS_NAMES[cls], LEGENDARY, "class:" + cls, str(CLASS_STAT[cls]), 80, "owned_class", cls, 6,
			"Possiedi 6 operatori %s." % CLASS_NAMES[cls]))
	# account
	out.append(_t("coll_e", "collezione", "Collezionista", EPIC, "all", "hp", 30, "owned", "", 10, "Possiedi 10 operatori."))
	out.append(_t("coll_l", "collezione", "Grande Collezionista", LEGENDARY, "all", "hp", 60, "owned", "", 20, "Possiedi 20 operatori."))
	out.append(_t("vet_e", "veterano", "Veterano", EPIC, "all", "atk", 30, "max_level", "", 25, "Porta un operatore al livello 25."))
	out.append(_t("vet_l", "veterano", "Leggenda Vivente", LEGENDARY, "all", "atk", 60, "max_level", "", 50, "Porta un operatore al livello massimo (50)."))
	out.append(_t("exp_e", "spedizione", "Esploratore", EPIC, "all", "def", 30, "exp_wins", "", 1, "Completa 1 SPEDIZIONE."))
	out.append(_t("exp_l", "spedizione", "Signore delle Spedizioni", LEGENDARY, "all", "def", 60, "exp_wins", "", 5, "Completa 5 SPEDIZIONI."))
	out.append(_t("clr_e", "conquista", "Conquistatore", EPIC, "all", "atk", 25, "cleared_all", "", 1, "Sconfiggi ogni boss almeno a NORMALE."))
	out.append(_t("clr_l", "conquista", "Incubo Domato", LEGENDARY, "all", "atk", 50, "cleared_all", "", 3, "Sconfiggi ogni boss a INCUBO."))
	_all = out
	return out


static func by_id(id: String) -> Dictionary:
	for t in all():
		if str(t["id"]) == id:
			return t
	return {}


static func rarity_name(t: Dictionary) -> String:
	return "LEGGENDARIO" if int(t["rarity"]) >= LEGENDARY else "EPICO"


# Conteggi della collezione calcolati una volta sola (servono a tutti i titoli).
static func _context(roster: Dictionary) -> Dictionary:
	var ctx: Dictionary = {"color": {}, "faction": {}, "cls": {}, "owned": 0, "max_level": 0}
	for id in roster.get("characters", {}):
		var def: Dictionary = BattleContent.CHARACTERS.get(str(id), {})
		for field in ["color", "faction", "cls"]:
			var k: String = str(def.get(field, ""))
			ctx[field][k] = int(ctx[field].get(k, 0)) + 1
		ctx["owned"] = int(ctx["owned"]) + 1
		ctx["max_level"] = maxi(int(ctx["max_level"]), int(roster["characters"][id].get("level", 1)))
	ctx["exp_wins"] = int(Expedition.data(roster).get("wins", 0))
	var low: int = 99
	for b in BattleContent.BOSS_ORDER:
		low = mini(low, RosterState.cleared_tiers(roster, str(b)))
	ctx["cleared_all"] = 0 if low == 99 else low
	return ctx


# Valore attuale della condizione. icons: icone sbloccate (di norma Profile.unlocked). ctx: _context gia' calcolato (facoltativo).
static func value(roster: Dictionary, t: Dictionary, icons: Array, ctx: Variant = null) -> int:
	if ctx == null:
		ctx = _context(roster)
	match str(t["metric"]):
		"icon":
			return 1 if icons.has(str(t["arg"])) else 0
		"owned_color":
			return int(ctx["color"].get(str(t["arg"]), 0))
		"owned_faction":
			return int(ctx["faction"].get(str(t["arg"]), 0))
		"owned_class":
			return int(ctx["cls"].get(str(t["arg"]), 0))
		"owned":
			return int(ctx["owned"])
		"max_level":
			return int(ctx["max_level"])
		"exp_wins":
			return int(ctx["exp_wins"])
		"cleared_all":
			return int(ctx["cleared_all"])
	return 0


static func is_earned(roster: Dictionary, t: Dictionary, icons: Array = [], ctx: Variant = null) -> bool:
	return value(roster, t, icons, ctx) >= int(t["goal"])


static func earned(roster: Dictionary, icons: Array = []) -> Array:
	var out: Array = []
	var ctx: Dictionary = _context(roster)
	for t in all():
		if is_earned(roster, t, icons, ctx):
			out.append(t)
	return out


static func scope_matches(scope: String, char_id: String) -> bool:
	if scope == "all":
		return true
	var def: Dictionary = BattleContent.CHARACTERS.get(char_id, {})
	var parts: PackedStringArray = scope.split(":")
	if parts.size() != 2:
		return false
	match parts[0]:
		"color":
			return str(def.get("color", "")) == parts[1]
		"faction":
			return str(def.get("faction", "")) == parts[1]
		"class":
			return str(def.get("cls", "")) == parts[1]
	return false


# I titoli che contano davvero (il migliore di ogni linea).
static func active(roster: Dictionary, icons: Array = []) -> Array:
	var best: Dictionary = {}
	for t in earned(roster, icons):
		var line: String = str(t["line"])
		if not best.has(line) or int(t["bp"]) > int(best[line]["bp"]):
			best[line] = t
	return best.values()


# Bonus totale (punti base) per un personaggio: {hp, atk, def}.
# act: i titoli attivi gia' calcolati (active); chi deve calcolare piu' personaggi li passa per non rifare il conto ogni volta.
static func bonus_for(roster: Dictionary, char_id: String, icons: Array = [], act: Variant = null) -> Dictionary:
	var out: Dictionary = {"hp": 0, "atk": 0, "def": 0}
	if act == null:
		act = active(roster, icons)
	for t in act:
		if scope_matches(str(t["scope"]), char_id):
			out[str(t["stat"])] = int(out[str(t["stat"])]) + int(t["bp"])
	for s in STATS:
		out[s] = mini(int(out[s]), MAX_BP)
	return out


static func has_bonus(b: Dictionary) -> bool:
	return int(b.get("hp", 0)) > 0 or int(b.get("atk", 0)) > 0 or int(b.get("def", 0)) > 0


# Consegna il bonus alla scheda (come fa la SPEDIZIONE con i veterani).
static func decorate_entry(roster: Dictionary, entry: Dictionary, icons: Array = [], act: Variant = null) -> void:
	var b: Dictionary = bonus_for(roster, str(entry.get("char", "")), icons, act)
	if has_bonus(b):
		entry["acc"] = b


# Moltiplicatori da una scheda (verifica anche i valori: arrivano dalla rete).
static func stat_mult(entry: Dictionary) -> Dictionary:
	var acc: Dictionary = entry.get("acc", {}) if entry.get("acc", {}) is Dictionary else {}
	var out: Dictionary = {}
	for s in STATS:
		out[s] = 1.0 + float(clampi(int(acc.get(s, 0)), 0, MAX_BP)) / 10000.0
	return out


static func bp_text(bp: int) -> String:
	var whole: int = bp / 100
	var frac: int = bp % 100
	if frac == 0:
		return "%d%%" % whole
	if frac % 10 == 0:
		return "%d,%d%%" % [whole, frac / 10]
	return "%d,%02d%%" % [whole, frac]


static func scope_text(scope: String) -> String:
	if scope == "all":
		return "tutti i personaggi"
	var parts: PackedStringArray = scope.split(":")
	match parts[0]:
		"color":
			return "gli operatori %s" % parts[1]
		"faction":
			return "gli operatori di %s" % Factions.name_of(parts[1])
		"class":
			return "gli operatori %s" % CLASS_NAMES.get(parts[1], parts[1])
	return scope


static func bonus_text(t: Dictionary) -> String:
	return "+%s %s a %s" % [bp_text(int(t["bp"])), STAT_NAMES[str(t["stat"])], scope_text(str(t["scope"]))]


static func summary(roster: Dictionary, icons: Array = []) -> Dictionary:
	var act: Array = active(roster, icons)
	return {"earned": earned(roster, icons).size(), "total": all().size(), "active": act.size()}
