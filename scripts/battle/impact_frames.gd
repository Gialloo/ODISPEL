class_name ImpactFrames
extends RefCounted

# Impact frames in stile anime (0.26.0): CLASSIFICAZIONE e PIANO. Solo presentazione: non ricalcola ne' altera il danno,
# non scrive nello stato e non e' mai serializzato (nessun effetto sulla rete).
#
# Livelli (priorita' esplicita, dal piu' forte): ULT_EXCEPTIONAL > ULT_CRIT > EXCEPTIONAL > CRIT > NONE.
#   CRIT              critico "pesante": critico con almeno CRIT_MIN_FRAC dei PV massimi del bersaglio
#   EXCEPTIONAL       danno eccezionale (soglia RELATIVA, vedi sotto), anche non critico
#   ULT_CRIT          ultimate che mette a segno un critico (solo sul colpo decisivo della mossa)
#   ULT_EXCEPTIONAL   ultimate con danno oltre la soglia superiore (solo sul colpo decisivo)
#
# Soglie relative (non assolute: boss, operatori e difficolta' hanno scale di PV diverse). Criterio scelto: rapporto fra
# il danno realmente inflitto ("amount", gia' al netto di scudi e guardia) e i PV MASSIMI del bersaglio, oppure una
# fetta grande dei PV CORRENTI (colpo che svolta lo scontro) purche' non sia un colpetto di rifinitura (minimo sui PV massimi).
# Il "danno atteso" della mossa non e' esposto in modo affidabile (dipende da modificatori nati nel round): non usato.
# Contro gli operatori le soglie sono piu' alte: i loro PV sono pochi rispetto ai colpi del boss e l'effetto sarebbe continuo.

const NONE: int = 0
const CRIT: int = 1
const EXCEPTIONAL: int = 2
const ULT_CRIT: int = 3
const ULT_EXCEPTIONAL: int = 4

const CFG: Dictionary = {
	"crit_min_frac": 0.03,
	"exc_frac_boss": 0.18, "exc_frac_player": 0.35,
	"exc_cur_frac": 0.60, "exc_cur_min_frac": 0.08,
	"ult_frac_boss": 0.28, "ult_frac_player": 0.50,
	"ult_cur_frac": 0.75, "ult_cur_min_frac": 0.12,
}
# Durata iniziale dell'hit-stop in secondi per livello (valori da provare su dispositivo, non regole).
const HIT_STOP: Array = [0.0, 0.040, 0.060, 0.080, 0.120]
# Durata visiva totale dell'overlay per livello.
const OVERLAY_LEN: Array = [0.0, 0.22, 0.30, 0.42, 0.62]


# Livello di un singolo colpo (kind: "basic" | "skill" | "ult"). max_hp/hp_before = valori del bersaglio PRIMA del colpo.
static func level_for(kind: String, amount: int, crit: bool, max_hp: int, hp_before: int, to_boss: bool) -> int:
	if amount <= 0 or max_hp <= 0:
		return NONE
	var mx: float = float(max_hp)
	var a: float = float(amount)
	var cur: float = float(maxi(1, hp_before))
	var exc: bool = a >= mx * float(CFG["exc_frac_boss" if to_boss else "exc_frac_player"]) \
		or (a >= mx * float(CFG["exc_cur_min_frac"]) and a >= cur * float(CFG["exc_cur_frac"]))
	var ult_exc: bool = a >= mx * float(CFG["ult_frac_boss" if to_boss else "ult_frac_player"]) \
		or (a >= mx * float(CFG["ult_cur_min_frac"]) and a >= cur * float(CFG["ult_cur_frac"]))
	if kind == "ult":
		if ult_exc:
			return ULT_EXCEPTIONAL
		if crit:
			return ULT_CRIT
	if exc:
		return EXCEPTIONAL
	if crit and a >= mx * float(CFG["crit_min_frac"]):
		return CRIT
	return NONE


# Piano per un round: per ogni evento, a quale mossa appartiene e se e' il colpo DECISIVO del suo gruppo.
# Il legame colpo -> mossa NON si deduce dall'evento precedente: un gruppo e' (evento "act"/"boss_move", sorgente del danno).
# Cosi' contrattacchi (sorgente diversa), spine e costi (thorns/cost) non ereditano mai l'ultimate, e le ultimate
# multi-bersaglio hanno un solo colpo decisivo (il piu' grande in rapporto ai PV massimi; a parita' il primo).
# unit_lookup(uid) -> Dictionary con "max_hp" (e opzionale "side"); serve solo a confrontare i colpi dello stesso gruppo.
# Ritorna un Array allineato a events: {"kind", "group", "decisive", "skip"}.
static func plan(events: Array, unit_lookup: Callable, boss_id: String = "boss") -> Array:
	var out: Array = []
	var act_i: int = -1
	var act_unit: String = ""
	var act_kind: String = "basic"
	var groups: Dictionary = {}
	for i in events.size():
		var e: Dictionary = events[i]
		var t: String = str(e.get("t", ""))
		var entry: Dictionary = {"kind": "basic", "group": "", "decisive": true, "skip": false}
		if t == "act":
			act_i = i
			act_unit = str(e.get("unit", ""))
			act_kind = str(e["kind"]) if e.has("kind") else str(BattleContent.MOVES.get(str(e.get("move", "")), {}).get("kind", "basic"))
			if act_kind != "ult" and act_kind != "skill":
				act_kind = "basic"
		elif t == "boss_move":
			act_i = i
			act_unit = boss_id
			act_kind = "basic"
		elif t == "round" or t == "phase":
			act_i = -1
			act_unit = ""
			act_kind = "basic"
		elif t == "damage":
			if bool(e.get("thorns", false)) or bool(e.get("cost", false)) or int(e.get("amount", 0)) <= 0:
				entry["skip"] = true
			else:
				var src: String = str(e.get("src", ""))
				entry["kind"] = act_kind if (act_i >= 0 and src == act_unit) else "basic"
				var key: String = "%d|%s" % [act_i, src]
				entry["group"] = key
				if not groups.has(key):
					groups[key] = []
				(groups[key] as Array).append(i)
		out.append(entry)
	for key in groups.keys():
		var idxs: Array = groups[key]
		var best: int = int(idxs[0])
		var best_r: float = -1.0
		for ix in idxs:
			var ev: Dictionary = events[int(ix)]
			var mx: float = maxf(1.0, float(unit_lookup.call(str(ev.get("dst", ""))).get("max_hp", 1)))
			var r: float = float(int(ev.get("amount", 0))) / mx
			if r > best_r + 0.000001:
				best_r = r
				best = int(ix)
		for ix in idxs:
			(out[int(ix)] as Dictionary)["decisive"] = int(ix) == best
	return out


# Livello effettivo di un evento, dato il suo piano e lo stato PRIMA del colpo.
# I colpi non decisivi di un gruppo con piu' colpi non fanno mai partire un frame: un solo evento forte per mossa.
static func level_of_event(e: Dictionary, entry: Dictionary, max_hp: int, hp_before: int, to_boss: bool) -> int:
	if bool(entry.get("skip", false)) or str(e.get("t", "")) != "damage":
		return NONE
	var lv: int = level_for(str(entry.get("kind", "basic")), int(e.get("amount", 0)), bool(e.get("crit", false)), max_hp, hp_before, to_boss)
	if not bool(entry.get("decisive", true)):
		return NONE
	return lv
