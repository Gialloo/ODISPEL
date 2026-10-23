class_name Progress
extends RefCounted

# PROGRESSIONE DELLA SQUADRA (stile Persona 5): esperienza a ogni scontro, livelli, sblocchi e cosa si equipaggia nel menu SQUADRA.
# - Ogni scontro vinto da' esperienza a tutti e quattro (anche a chi e' KO). Il level up si vede a fine scontro.
# - Coi livelli si sbloccano abilita', Ultimate, reazioni personali, tratti e sinergie; si scelgono in pausa > SQUADRA.
# - Saul ruba le mosse ai nemici (Il trucco del mago): restano per sempre e chiunque puo' equipaggiarle come ABILITA'.
# - Altre mosse arriveranno dall'esplorazione (PROVVISORIO: per ora solo livelli e furti).
# I numeri sono tarati perche' giocando l'atto 1 normalmente si arrivi a ogni boss al livello previsto dai dati
# (1, 3, 5, 7, 9, 11): saltando meta' dei nemici minori si arriva un livello sotto. Chi resta indietro prende di piu'.

const CAST: Array = ["ferri", "nox", "zecca", "saul"]
const MAX_LEVEL: int = 30

# kind: skill | ult | react | trait | syn
const UNLOCKS: Dictionary = {
	"ferri": [[1, "skill", "u_ferri_a"], [1, "ult", "u_ferri_ult"], [3, "skill", "u_ferri_b"], [5, "react", "muro"],
		[6, "syn", "turno_di_notte"], [8, "trait", "t_pelle_dura"], [9, "syn", "vecchie_conoscenze"], [11, "ult", "u_ferri_ult2"]],
	"nox": [[1, "skill", "u_nox_a"], [1, "ult", "u_nox_ult"], [3, "skill", "u_nox_b"], [5, "react", "reperibile"],
		[6, "syn", "diretta_notturna"], [8, "trait", "t_sonno_leggero"], [9, "syn", "turno_di_notte"], [11, "ult", "u_nox_ult2"]],
	"zecca": [[1, "skill", "u_zecca_a"], [1, "ult", "u_zecca_ult"], [3, "skill", "u_zecca_b"], [5, "react", "cambio_scena"],
		[6, "syn", "il_pubblico_paga"], [8, "trait", "t_follower"], [9, "syn", "diretta_notturna"], [11, "ult", "u_zecca_ult2"]],
	"saul": [[1, "skill", "u_saul_b"], [1, "skill", "u_saul_a"], [1, "ult", "u_saul_ult"], [3, "skill", "u_saul_c"], [5, "react", "sgattaiolare"],
		[6, "syn", "vecchie_conoscenze"], [7, "skill", "u_saul_d"], [8, "trait", "t_guanti_velluto"], [9, "syn", "il_pubblico_paga"],
		[11, "ult", "u_saul_ult2"]],
}

# Reazioni personali: cambiano la reazione di squadra quando la usa quel personaggio (BattleResolver._react_perk)
const REACT_MODS: Dictionary = {
	"muro": {"name": "Muro", "desc": "Quando Lance usa COPRI prende ancora meno danno e carica l'Ultimate."},
	"reperibile": {"name": "Reperibile", "desc": "Il SOCCORRI di Nox rialza con molti più PV e le ridà 1 energia."},
	"cambio_scena": {"name": "Cambio di scena", "desc": "Quando Rio SCHIVA: +20 Hype e carica l'Ultimate."},
	"sgattaiolare": {"name": "Sgattaiolare", "desc": "Quando Saul SCHIVA risponde con un colpo e si riprende 1 energia."},
}

# Sinergie: basta che uno dei due la equipaggi; finche' sono in squadra entrambi hanno +8% attacco e difesa
const SYNERGIES: Dictionary = {
	"turno_di_notte": {"name": "Turno di notte", "pair": ["ferri", "nox"], "desc": "Lance e Nox: +8% attacco e difesa a entrambi."},
	"vecchie_conoscenze": {"name": "Vecchie conoscenze", "pair": ["ferri", "saul"], "desc": "Lance e Saul: +8% attacco e difesa a entrambi."},
	"diretta_notturna": {"name": "Diretta notturna", "pair": ["nox", "zecca"], "desc": "Nox e Rio: +8% attacco e difesa a entrambi."},
	"il_pubblico_paga": {"name": "Il pubblico paga", "pair": ["zecca", "saul"], "desc": "Rio e Saul: +8% attacco e difesa a entrambi."},
}
const SYN_PM: int = 80

const TRAIT_DESC: Dictionary = {
	"t_pelle_dura": "+12% PV massimi.",
	"t_sonno_leggero": "+6% PV massimi e +6% attacco.",
	"t_follower": "+10% attacco.",
	"t_guanti_velluto": "+12% attacco.",
}

static var data: Dictionary = {}


static func reset() -> void:
	data = {"lv": {}, "exp": {}, "equip": {}, "stolen": [], "stolen_from": {}}
	for c in CAST:
		data["lv"][c] = 1
		data["exp"][c] = 0
		data["equip"][c] = default_equip(c)


static func ensure() -> void:
	if data.is_empty():
		reset()


static func from_save(v: Variant) -> void:
	reset()
	if not (v is Dictionary):
		return
	var d: Dictionary = v
	for k in ["lv", "exp", "equip", "stolen_from"]:
		if d.get(k) is Dictionary:
			(data[k] as Dictionary).merge(d[k], true)
	if d.get("stolen") is Array:
		data["stolen"] = (d["stolen"] as Array).duplicate()
	register_stolen()


static func default_equip(c: String) -> Dictionary:
	var eq: Dictionary = {"skill": "", "ult": "", "react": "", "trait": "", "syn": ""}
	for u in UNLOCKS[c]:
		if int(u[0]) <= 1 and str(eq[str(u[1])]) == "":
			eq[str(u[1])] = str(u[2])
	return eq


static func level(c: String) -> int:
	ensure()
	return int(data["lv"].get(c, 1))


static func team_level() -> int:
	var s: int = 0
	for c in CAST:
		s += level(c)
	return int(round(float(s) / float(CAST.size())))


static func exp_need(lv: int) -> int:
	return 30 + 30 * lv


static func exp_ratio(c: String) -> float:
	return float(data["exp"].get(c, 0)) / float(exp_need(level(c)))


# Esperienza di uno scontro vinto. Chi e' indietro rispetto al nemico prende di piu' (+35% per livello di differenza),
# chi e' molto avanti meno. bonus_pct: Tasche piene / Il colpo del secolo di Saul.
static func battle_exp(enemy_level: int, boss: bool, bonus_pct: int = 0) -> int:
	var base: float = (40.0 + 30.0 * enemy_level) if boss else (10.0 + 10.0 * enemy_level)
	var gap: int = enemy_level - team_level()
	var mult: float = 1.0 + 0.35 * float(gap) if gap > 0 else (1.0 if gap > -2 else 0.6)
	return int(round(base * mult * (1.0 + float(bonus_pct) / 100.0)))


# Da' l'esperienza a tutti. Ritorna una riga per personaggio: livello prima/dopo, barra prima/dopo, sblocchi nuovi.
static func grant(amount: int) -> Array:
	ensure()
	var out: Array = []
	for c in CAST:
		var lv0: int = level(c)
		var r0: float = exp_ratio(c)
		var x: int = int(data["exp"].get(c, 0)) + amount
		var lv: int = lv0
		while lv < MAX_LEVEL and x >= exp_need(lv):
			x -= exp_need(lv)
			lv += 1
		data["lv"][c] = lv
		data["exp"][c] = x
		var news: Array = []
		for u in UNLOCKS[c]:
			if int(u[0]) > lv0 and int(u[0]) <= lv:
				news.append({"kind": str(u[1]), "id": str(u[2]), "name": item_name(str(u[1]), str(u[2]))})
				_auto_equip(c, str(u[1]), str(u[2]))
		out.append({"char": c, "lv0": lv0, "lv": lv, "r0": r0, "r": exp_ratio(c), "gain": amount, "news": news})
	return out


# Uno slot ancora vuoto si riempie da solo con la prima cosa sbloccata (il giocatore non deve passare dal menu per usarla)
static func _auto_equip(c: String, kind: String, id: String) -> void:
	var eq: Dictionary = data["equip"][c]
	if str(eq.get(kind, "")) == "":
		eq[kind] = id


# Cosa si puo' scegliere per uno slot: [[id, sbloccato, livello richiesto]]. Per le abilita' anche le mosse rubate.
static func options(c: String, kind: String) -> Array:
	var out: Array = []
	for u in UNLOCKS[c]:
		if str(u[1]) == kind:
			out.append([str(u[2]), level(c) >= int(u[0]), int(u[0])])
	if kind == "skill":
		for bm in data.get("stolen", []):
			out.append([stolen_id(str(bm)), true, 0])
	if kind in ["react", "trait", "syn"]:
		out.push_front(["", true, 0])
	return out


static func equip(c: String, kind: String, id: String) -> void:
	ensure()
	(data["equip"][c] as Dictionary)[kind] = id


static func equipped(c: String, kind: String) -> String:
	ensure()
	return str((data["equip"].get(c, {}) as Dictionary).get(kind, ""))


static func item_name(kind: String, id: String) -> String:
	if id == "":
		return "Vuoto"
	match kind:
		"skill", "ult":
			return str(BattleContent.MOVES.get(id, {}).get("name", id))
		"react":
			return str(REACT_MODS.get(id, {}).get("name", id))
		"trait":
			return str(BattleContent.PASSIVES.get(id, {}).get("name", id))
		"syn":
			return str(SYNERGIES.get(id, {}).get("name", id))
	return id


static func item_desc(kind: String, id: String) -> String:
	if id == "":
		return "Slot libero."
	match kind:
		"skill", "ult":
			var m: Dictionary = BattleContent.MOVES.get(id, {})
			var cost: String = (" ·\u00a0%d\u00a0ENERGIA" % int(m.get("cost", 0))) if kind == "skill" else ""
			return str(m.get("desc", "")) + cost
		"react":
			return str(REACT_MODS.get(id, {}).get("desc", ""))
		"trait":
			return str(TRAIT_DESC.get(id, ""))
		"syn":
			return str(SYNERGIES.get(id, {}).get("desc", ""))
	return ""


# ---------------------------------------------------------------- in battaglia

# Voce della squadra per BattleContent/BattleState: livello, abilita' e Ultimate equipaggiate, tratto
static func entry_for(c: String) -> Dictionary:
	ensure()
	var e: Dictionary = BattleContent.default_entry(c, level(c))
	var sk: String = equipped(c, "skill")
	if sk != "" and BattleContent.MOVES.has(sk):
		var list: Array = ["attack", "guard", sk]
		if BattleContent.faction_of(c) == "libracorp":
			list.append("ricarica")
		e["skills"] = list
	var ul: String = equipped(c, "ult")
	if ul != "" and BattleContent.MOVES.has(ul):
		e["ult"] = ul
	var tr: String = equipped(c, "trait")
	if tr != "":
		(e["passives"] as Array).append(tr)
	return e


# Dopo aver creato la battaglia: reazioni personali, sinergie, abilita' scelta e mosse gia' rubate (per non rubarle due volte)
static func apply_to_battle(b: Dictionary) -> Array:
	var msgs: Array = []
	var by_char: Dictionary = {}
	for uid in b["units"]:
		var u: Dictionary = b["units"][uid]
		if str(u.get("side", "")) == "player":
			by_char[str(u["char"])] = u
			u["react_mod"] = equipped(str(u["char"]), "react")
			u["equip_skill"] = equipped(str(u["char"]), "skill")
	var done: Dictionary = {}
	for c in by_char:
		var syn: String = equipped(c, "syn")
		if syn == "" or done.has(syn) or not SYNERGIES.has(syn):
			continue
		var pair: Array = SYNERGIES[syn]["pair"]
		if not (by_char.has(pair[0]) and by_char.has(pair[1])):
			continue
		done[syn] = true
		for who in pair:
			Factions.add_mod(by_char[who], "sinergia_" + syn + "_atk", "atk", SYN_PM, 999)
			Factions.add_mod(by_char[who], "sinergia_" + syn + "_def", "def", SYN_PM, 999)
		msgs.append("SINERGIA · %s: +8%% attacco e difesa" % str(SYNERGIES[syn]["name"]))
	Factions.refresh(b)
	b["stolen_known"] = (data.get("stolen", []) as Array).duplicate()
	return msgs


# ---------------------------------------------------------------- mosse rubate

static func stolen_id(bm: String) -> String:
	return "r_" + bm


# Versione giocabile di una mossa del nemico: colpisce il nemico, forza presa dalla mossa originale (contenuta)
static func stolen_def(bm: String) -> Dictionary:
	var m: Dictionary = BattleContent.BOSS_MOVES.get(bm, {})
	var all: bool = str(m.get("target", "one")) == "all"
	var mult: float = clampf(float(m.get("mult", 1.0)) * 1.15, 1.1, 2.1)
	var d: Dictionary = {"name": str(m.get("name", bm)), "kind": "skill", "cost": 2, "priority": 0, "rarity": 1, "target": "enemy",
		"mult": mult * (0.55 if all else 1.0), "stolen": bm,
		"desc": "Rubata da Saul nello scontro con %s." % str(data.get("stolen_from", {}).get(bm, "un nemico"))}
	if all:
		d["hits"] = 2
		d["desc"] = str(d["desc"]) + " Due colpi."
	if m.get("status") is Dictionary:
		for s in m["status"]:
			if str(s) in ["bleed", "weak", "slow"]:
				d["status"] = {str(s): int(m["status"][s])}
	return d


static func register_stolen() -> void:
	for bm in data.get("stolen", []):
		BattleContent.MOVES[stolen_id(str(bm))] = stolen_def(str(bm))


static func add_stolen(bm: String, from_name: String) -> bool:
	ensure()
	if bm == "" or (data["stolen"] as Array).has(bm):
		return false
	(data["stolen"] as Array).append(bm)
	data["stolen_from"][bm] = from_name
	register_stolen()
	return true
