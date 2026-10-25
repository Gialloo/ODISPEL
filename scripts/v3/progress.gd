class_name Progress
extends RefCounted

# PROGRESSIONE DELLA SQUADRA (stile Persona 5): esperienza a ogni scontro, livelli, sblocchi e cosa si equipaggia nel menu SQUADRA.
# - Ogni scontro vinto da' esperienza a tutti e quattro (anche a chi e' KO). Il level up si vede a fine scontro.
# - Coi livelli si sbloccano abilita', Ultimate, reazioni personali, tratti e sinergie; si scelgono in pausa > SQUADRA.
# - Saul ruba le mosse ai nemici (Il trucco del mago): restano per sempre e chiunque puo' equipaggiarle come ABILITA'.
# - Altre mosse arriveranno dall'esplorazione (PROVVISORIO: per ora solo livelli e furti).
# I numeri sono tarati perche' giocando l'atto 1 normalmente si arrivi a ogni boss al livello previsto dai dati
# (1, 3, 5, 7, 9, 11): saltando meta' dei nemici minori si arriva un livello sotto. Chi resta indietro prende di piu'.
# Dopo l'atto 1 si continua nella Replica della diretta (New Game+, fino a NG+10): nemici dal livello 14 in su e molta piu'
# esperienza, e gli sblocchi proseguono fino al livello 100 (una cosa nuova ogni 5 livelli circa, a turno per tipo).

const CAST: Array = ["ferri", "nox", "zecca", "saul"]
const MAX_LEVEL: int = 100

# kind: skill | ult | react | trait | syn
const UNLOCKS: Dictionary = {
	"ferri": [[1, "skill", "u_ferri_a"], [1, "ult", "u_ferri_ult"], [3, "skill", "u_ferri_b"], [5, "react", "muro"],
		[6, "syn", "turno_di_notte"], [8, "trait", "t_pelle_dura"], [9, "syn", "vecchie_conoscenze"], [11, "ult", "u_ferri_ult2"],
		[14, "skill", "u_ferri_c"], [18, "trait", "t_ora_esatta"], [20, "react", "scorta"], [25, "ult", "u_ferri_ult3"],
		[30, "syn", "risultato_operativo"], [35, "skill", "u_ferri_d"], [40, "trait", "t_manuale"], [45, "react", "al_secondo_netto"],
		[50, "syn", "riunione_sul_divano"], [55, "ult", "u_ferri_ult4"], [65, "skill", "u_ferri_e"], [75, "trait", "t_veterano"],
		[80, "react", "muro_libracorp"], [90, "syn", "rituale_della_notte"], [100, "ult", "u_ferri_ult5"]],
	"nox": [[1, "skill", "u_nox_a"], [1, "ult", "u_nox_ult"], [3, "skill", "u_nox_b"], [5, "react", "reperibile"],
		[6, "syn", "diretta_notturna"], [8, "trait", "t_sonno_leggero"], [9, "syn", "turno_di_notte"], [11, "ult", "u_nox_ult2"],
		[14, "skill", "u_nox_c"], [18, "trait", "t_thermos_pieno"], [20, "react", "reperibile_h24"], [25, "ult", "u_nox_ult3"],
		[30, "syn", "tre_snack"], [35, "skill", "u_nox_d"], [40, "trait", "t_divano_migliore"], [45, "react", "ci_penso_io"],
		[50, "syn", "appello_0601"], [55, "ult", "u_nox_ult4"], [65, "skill", "u_nox_e"], [75, "trait", "t_civetta"],
		[80, "react", "sveglia_per_tutti"], [90, "syn", "rituale_della_notte"], [100, "ult", "u_nox_ult5"]],
	"zecca": [[1, "skill", "u_zecca_a"], [1, "ult", "u_zecca_ult"], [3, "skill", "u_zecca_b"], [5, "react", "cambio_scena"],
		[6, "syn", "il_pubblico_paga"], [8, "trait", "t_follower"], [9, "syn", "diretta_notturna"], [11, "ult", "u_zecca_ult2"],
		[14, "skill", "u_zecca_c"], [18, "trait", "t_specchietto"], [20, "react", "controcampo"], [25, "ult", "u_zecca_ult3"],
		[30, "syn", "risultato_operativo"], [35, "skill", "u_zecca_d"], [40, "trait", "t_kit_professionale"], [45, "react", "ralenti"],
		[50, "syn", "seconda_ripresa"], [55, "ult", "u_zecca_ult4"], [65, "skill", "u_zecca_e"], [75, "trait", "t_ospite_fisso"],
		[80, "react", "standing_ovation"], [90, "syn", "rituale_della_notte"], [100, "ult", "u_zecca_ult5"]],
	"saul": [[1, "skill", "u_saul_b"], [1, "skill", "u_saul_a"], [1, "ult", "u_saul_ult"], [3, "skill", "u_saul_c"], [5, "react", "sgattaiolare"],
		[6, "syn", "vecchie_conoscenze"], [7, "skill", "u_saul_d"], [8, "trait", "t_guanti_velluto"], [9, "syn", "il_pubblico_paga"],
		[11, "ult", "u_saul_ult2"],
		[14, "skill", "u_saul_e"], [18, "trait", "t_accendino"], [20, "react", "porta_sul_retro"], [25, "ult", "u_saul_ult3"],
		[30, "syn", "tre_snack"], [35, "skill", "u_saul_f"], [40, "trait", "t_metodo_saul"], [45, "react", "tre_carte"],
		[50, "syn", "altoparlante"], [55, "ult", "u_saul_ult4"], [65, "skill", "u_saul_g"], [75, "trait", "t_nonna_diceva"],
		[80, "react", "il_conto_prego"], [90, "syn", "rituale_della_notte"], [100, "ult", "u_saul_ult5"]],
}

# Reazioni personali: cambiano la reazione di squadra quando la usa quel personaggio (BattleResolver._react_perk)
const REACT_MODS: Dictionary = {
	"muro": {"name": "Muro", "desc": "Quando Lance usa COPRI prende ancora meno danno e carica l'Ultimate."},
	"reperibile": {"name": "Reperibile", "desc": "Il SOCCORRI di Nox rialza con molti più PV e le ridà 1 energia."},
	"cambio_scena": {"name": "Cambio di scena", "desc": "Quando Rio SCHIVA: +20 Hype e carica l'Ultimate."},
	"sgattaiolare": {"name": "Sgattaiolare", "desc": "Quando Saul SCHIVA risponde con un colpo e si riprende 1 energia."},
	# oltre l'atto 1 (livelli 20, 45, 80): le stesse idee, piu' forti. I numeri stanno in Kits.REACT_PERKS.
	"scorta": {"name": "Scorta", "desc": "Quando Lance usa COPRI prende poco danno, carica molto l'Ultimate e si riprende 1 energia."},
	"al_secondo_netto": {"name": "Al secondo netto", "desc": "COPRI di Lance: quasi niente danno, molta Ultimate e il nemico perde equilibrio."},
	"muro_libracorp": {"name": "Muro della LibraCorp", "desc": "COPRI di Lance: il colpo quasi non passa, Ultimate e energia, il nemico perde molto equilibrio."},
	"reperibile_h24": {"name": "Reperibile H24", "desc": "Il SOCCORSO di Nox rialza con tanti PV, le ridà 1 energia e le carica l'Ultimate."},
	"ci_penso_io": {"name": "Ci penso io", "desc": "Il SOCCORSO di Nox rialza quasi del tutto, 2 energia e Ultimate."},
	"sveglia_per_tutti": {"name": "Sveglia per tutti", "desc": "Il SOCCORSO di Nox rialza quasi del tutto e dà 1 energia a tutta la squadra."},
	"controcampo": {"name": "Controcampo", "desc": "Quando Rio SCHIVA: +30 Hype e carica molto l'Ultimate."},
	"ralenti": {"name": "Ralenti", "desc": "Quando Rio SCHIVA: +35 Hype, Ultimate e un colpo di risposta al rallentatore."},
	"standing_ovation": {"name": "Standing ovation", "desc": "Quando Rio SCHIVA: +50 Hype, un colpo di risposta e il pubblico carica l'Ultimate di tutti."},
	"porta_sul_retro": {"name": "Porta sul retro", "desc": "Quando Saul SCHIVA risponde con un colpo più forte e si riprende 1 energia."},
	"tre_carte": {"name": "Il gioco delle tre carte", "desc": "Quando Saul SCHIVA: colpo di risposta, 2 energia e si tiene lo scudo del nemico."},
	"il_conto_prego": {"name": "Il conto, prego", "desc": "Quando Saul SCHIVA presenta il conto: colpo pesante, 2 energia e Ultimate."},
}

# Sinergie: basta che uno dei due la equipaggi; finche' sono in squadra entrambi hanno +8% attacco e difesa
const SYNERGIES: Dictionary = {
	"turno_di_notte": {"name": "Turno di notte", "pair": ["ferri", "nox"], "desc": "Lance e Nox: +8% attacco e difesa a entrambi."},
	"vecchie_conoscenze": {"name": "Vecchie conoscenze", "pair": ["ferri", "saul"], "desc": "Lance e Saul: +8% attacco e difesa a entrambi."},
	"diretta_notturna": {"name": "Diretta notturna", "pair": ["nox", "zecca"], "desc": "Nox e Rio: +8% attacco e difesa a entrambi."},
	"il_pubblico_paga": {"name": "Il pubblico paga", "pair": ["zecca", "saul"], "desc": "Rio e Saul: +8% attacco e difesa a entrambi."},
	# oltre l'atto 1: coppie che mancavano (livello 30), terzetti (50) e tutti e quattro (90). "pm" = per mille, "gauge" = Ultimate di partenza.
	# I nomi vengono dalle gag del gruppo (odispel/PERSONAGGI_E_UMORISMO.md), mai dai loro payoff.
	"risultato_operativo": {"name": "Risultato operativo", "pair": ["ferri", "zecca"], "pm": 120,
		"desc": "Lance e Rio (lui vuole il rapporto, Rio ci scrive le visualizzazioni): +12% attacco e difesa a entrambi."},
	"tre_snack": {"name": "Tre snack", "pair": ["nox", "saul"], "pm": 120,
		"desc": "Nox e Saul (lei sa quale macchinetta dà il resto, lui la combinazione): +12% attacco e difesa a entrambi."},
	"riunione_sul_divano": {"name": "Riunione sul divano", "pair": ["ferri", "nox", "zecca"], "pm": 120, "gauge": 10,
		"desc": "Lance, Nox e Rio: +12% attacco e difesa ai tre e Ultimate un po' più carica a inizio scontro."},
	"appello_0601": {"name": "Appello alle 06:01", "pair": ["ferri", "nox", "saul"], "pm": 120, "gauge": 10,
		"desc": "Lance, Nox e Saul: +12% attacco e difesa ai tre e Ultimate un po' più carica a inizio scontro."},
	"seconda_ripresa": {"name": "Seconda ripresa", "pair": ["zecca", "ferri", "saul"], "pm": 120, "gauge": 10,
		"desc": "Rio, Lance e Saul: +12% attacco e difesa ai tre e Ultimate un po' più carica a inizio scontro."},
	"altoparlante": {"name": "L'altoparlante", "pair": ["saul", "nox", "zecca"], "pm": 120, "gauge": 10,
		"desc": "Saul, Nox e Rio: +12% attacco e difesa ai tre e Ultimate un po' più carica a inizio scontro."},
	"rituale_della_notte": {"name": "Il rituale della notte", "pair": ["ferri", "nox", "zecca", "saul"], "pm": 150, "gauge": 20,
		"desc": "Chi fa la guardia, chi dorme, chi va a prendere da mangiare: +15% attacco e difesa a tutti e Ultimate più carica."},
}
const SYN_PM: int = 80

const TRAIT_DESC: Dictionary = {
	"t_pelle_dura": "+12% PV massimi.",
	"t_sonno_leggero": "+6% PV massimi e +6% attacco.",
	"t_follower": "+10% attacco.",
	"t_guanti_velluto": "+12% attacco.",
	"t_ora_esatta": "+8% PV massimi e +10% difesa.",
	"t_manuale": "+12% attacco e +8% difesa.",
	"t_veterano": "+18% PV massimi, +12% difesa e +8% attacco.",
	"t_thermos_pieno": "+10% PV massimi e +6% velocità.",
	"t_divano_migliore": "+14% PV massimi e +8% difesa.",
	"t_civetta": "+15% PV massimi, +10% attacco e +8% velocità.",
	"t_specchietto": "+8% attacco e +8% velocità.",
	"t_kit_professionale": "+14% attacco.",
	"t_ospite_fisso": "+20% attacco e +8% PV massimi.",
	"t_accendino": "+10% attacco e +6% velocità.",
	"t_metodo_saul": "+14% attacco e +6% PV massimi.",
	"t_nonna_diceva": "+20% attacco e +10% PV massimi.",
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
	if level(c) >= MAX_LEVEL:
		return 1.0
	return float(data["exp"].get(c, 0)) / float(exp_need(level(c)))


# Esperienza di uno scontro vinto. Chi e' indietro rispetto al nemico prende di piu' (+35% per livello di differenza),
# chi e' molto avanti meno. bonus_pct: Tasche piene / Il colpo del secolo di Saul.
# replica: nella Replica della diretta (New Game+) l'esperienza e' molto di piu' (BattleTypes.replica_exp: da x2 a x4,25).
static func battle_exp(enemy_level: int, boss: bool, bonus_pct: int = 0, replica: int = 0) -> int:
	var base: float = (40.0 + 30.0 * enemy_level) if boss else (10.0 + 10.0 * enemy_level)
	var gap: int = mini(enemy_level - team_level(), 8)       # tetto: oltre 8 livelli di distacco non serve di piu'
	var mult: float = 1.0 + 0.35 * float(gap) if gap > 0 else (1.0 if gap > -2 else 0.6)
	# il di piu' della Replica vale finche' la squadra non e' 3 o piu' livelli sopra il nemico: cosi' si sale in fretta,
	# ma il livello 100 arriva verso la fine della NG+9 e non a meta' (simulato con gli scontri dell'atto 1)
	var rk: float = BattleTypes.replica_exp(replica) if gap > -3 else 1.0
	return int(round(base * mult * (1.0 + float(bonus_pct) / 100.0) * rk))


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
		if lv >= MAX_LEVEL:
			x = 0       # al livello 100 la barra resta piena
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
			return BattleContent.move_desc(id) + cost
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
			# tutte le abilita' sbloccate si usano dal menu ABILITA' (oltre i 4 posti del kit); quella equipaggiata e' la FIRMA
			for o in options(str(u["char"]), "skill"):
				if bool(o[1]) and BattleContent.MOVES.has(str(o[0])) and not (u["skills"] as Array).has(str(o[0])):
					(u["skills"] as Array).append(str(o[0]))
	var done: Dictionary = {}
	for c in by_char:
		var syn: String = equipped(c, "syn")
		if syn == "" or done.has(syn) or not SYNERGIES.has(syn):
			continue
		# coppie, terzetti e tutti e quattro: servono tutti in squadra
		var pair: Array = SYNERGIES[syn]["pair"]
		var all_in: bool = true
		for who in pair:
			if not by_char.has(who):
				all_in = false
		if not all_in:
			continue
		done[syn] = true
		var pm: int = int(SYNERGIES[syn].get("pm", SYN_PM))
		for who in pair:
			Factions.add_mod(by_char[who], "sinergia_" + syn + "_atk", "atk", pm, 999)
			Factions.add_mod(by_char[who], "sinergia_" + syn + "_def", "def", pm, 999)
			if SYNERGIES[syn].has("gauge"):
				by_char[who]["syn_gauge"] = int(by_char[who].get("syn_gauge", 0)) + int(SYNERGIES[syn]["gauge"])
		msgs.append("SINERGIA · %s: +%d%% attacco e difesa" % [str(SYNERGIES[syn]["name"]), int(round(float(pm) / 10.0))])
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
