class_name Ritmo
extends RefCounted

# RITMO DI SQUADRA (handoff integrativo, 04/11/2026; fase R1: solo motore, niente UI, niente bonus).
# Una barra condivisa: il numero e' l'ARDORE, il livello e' CALMO, ACCESO, INCANDESCENTE o APICE.
# Ardore e livello non sono sinonimi (2.1): raggiungere la soglia apre l'avanzamento, ma il livello sale solo quando
# e' soddisfatta anche la condizione della transizione (2.4). Si sale un livello alla volta, l'Ardore si conserva.
# Tutti i numeri sono PROVVISORI (valori di prova approvati dall'autore il 04/11/2026), in BattleTypes.RITMO_*.
#
# Il RITMO legge gli eventi che il motore produce gia' (danno, BREAK, parata a tempo, soccorso, SLANCIO, tecnica a due,
# KO) e aggiunge i suoi eventi in coda alla stessa lista: la UI anima, non decide (separazione stato/UI).
# Eventi: {"t": "ritmo_gain", "src", "unit", "amount", "value", "wasted"} · {"t": "ritmo_loss", "amount", "value", "why"}
#         {"t": "ritmo_ready", "level"} (soglia raggiunta, manca la condizione) · {"t": "ritmo_cond", "level", "cond"}
#         {"t": "ritmo_level", "from", "to", "why"} (salita o discesa; to == 3 e' APICE)
# Il bonus del +10% al cambio di categoria (evento "rhythm") resta un bonus a parte e NON genera Ardore (autore, K2).

const CALMO: int = 0
const ACCESO: int = 1
const INCANDESCENTE: int = 2
const APICE: int = 3
const NAMES: Array = ["CALMO", "ACCESO", "INCANDESCENTE", "APICE"]

# CONDIZIONI DI AVANZAMENTO (2.5-2.7), provvisorie. Per ogni transizione (chiave = livello di arrivo): una principale e
# alternative, tutte universali (nessun personaggio obbligatorio). kind:
#   persistente  una volta fatta resta valida anche se la squadra perde Ardore
#   mantenimento vale solo finche' la situazione dura (si controlla adesso, non si ricorda)
#   finestra     va fatta durante un'opportunita' (qui: mentre il boss e' in BREAK)
# Le condizioni si contano solo da quando la squadra e' al livello di partenza: cosi' non si saltano livelli (2.4).
const CONDS: Dictionary = {
	ACCESO: [
		{"id": "debolezza", "cat": "pressione", "kind": "persistente", "text": "Colpisci una debolezza"},
		{"id": "parata", "cat": "difesa", "kind": "persistente", "text": "Para un colpo a tempo"},
	],
	INCANDESCENTE: [
		{"id": "collaborazione", "cat": "collaborazione", "kind": "persistente", "text": "Tre compagni diversi alimentano il RITMO"},
		{"id": "break", "cat": "pressione", "kind": "persistente", "text": "Manda il nemico in BREAK"},
		{"id": "marchio", "cat": "controllo", "kind": "mantenimento", "text": "Tieni il nemico marchiato"},
	],
	APICE: [
		{"id": "colpo_break", "cat": "pressione", "kind": "finestra", "text": "Colpisci il nemico durante il BREAK"},
		{"id": "parata_perfetta", "cat": "difesa", "kind": "persistente", "text": "Para alla perfezione"},
	],
}


# ---------------------------------------------------------------- stato

# Lo stato del RITMO (creato al primo uso: i salvataggi di prima non lo hanno e restano validi).
static func st(state: Dictionary) -> Dictionary:
	if not (state.get("ritmo", null) is Dictionary):
		state["ritmo"] = {"ardore": 0, "cap": BattleTypes.RITMO_CAP, "level": CALMO, "ready": false,
			"done": {}, "helpers": {}, "round": int(state.get("round", 1)), "gen": {}, "hold": false, "saves": {}}
	return state["ritmo"]


static func ardore(state: Dictionary) -> int:
	return int(st(state)["ardore"])


static func level(state: Dictionary) -> int:
	return int(st(state)["level"])


static func level_name(lv: int) -> String:
	return str(NAMES[clampi(lv, 0, NAMES.size() - 1)])


# Soglia di Ardore per stare (o arrivare) al livello lv. CALMO = 0.
static func threshold(lv: int) -> int:
	if lv <= CALMO:
		return 0
	return int(BattleTypes.RITMO_THRESHOLDS[mini(lv, APICE) - 1])


# Quanto Ardore puo' accumulare adesso: con l'avanzamento in attesa si arriva al margine sopra la soglia (2.4), mai oltre il tetto.
static func room(state: Dictionary) -> int:
	var r: Dictionary = st(state)
	var cap: int = int(r["cap"])
	var lv: int = int(r["level"])
	if lv < APICE:
		cap = mini(cap, threshold(lv + 1) + BattleTypes.RITMO_MARGIN)
	return cap


# La condizione `id` della prossima transizione e' soddisfatta adesso?
static func cond_ok(state: Dictionary, c: Dictionary) -> bool:
	var r: Dictionary = st(state)
	if str(c["kind"]) == "mantenimento":
		return _maintained(state, str(c["id"]))
	return (r["done"] as Dictionary).has(str(c["id"]))


static func next_conds(state: Dictionary) -> Array:
	var lv: int = level(state)
	if lv >= APICE:
		return []
	return CONDS[lv + 1]


# ---------------------------------------------------------------- guadagno e perdita (API per mosse, nemici e test)

# Aggiunge Ardore (gia' controllato contro il farming dal chiamante). Ritorna quanto e' entrato davvero.
# L'eccedenza oltre il tetto si perde (5.10): l'evento la riporta in "wasted".
static func gain(state: Dictionary, n: int, src: String, unit: String, events: Array) -> int:
	var r: Dictionary = st(state)
	if n <= 0:
		return 0
	var before: int = int(r["ardore"])
	var after: int = mini(room(state), before + n)
	after = maxi(after, before)
	r["ardore"] = after
	r["hold"] = false
	events.append({"t": "ritmo_gain", "resource": "ardore", "src": src, "unit": unit, "requested": n, "amount": after - before, "effective": after - before, "value": after, "wasted": n - (after - before)})
	if after > before and unit != "":
		(r["helpers"] as Dictionary)[unit] = true
	return after - before


# Toglie Ardore. keep_level = true: il livello resta anche se si scende sotto la soglia (2.3 tipo 1/4, «secondo l'effetto»)
# finche' non arriva un nuovo guadagno o una nuova perdita normale. Altrimenti il livello scende fin dove l'Ardore lo regge
# (2.3 tipo 2/5: si possono attraversare piu' soglie).
static func drain(state: Dictionary, n: int, why: String, events: Array, keep_level: bool = false) -> void:
	var r: Dictionary = st(state)
	var before: int = int(r["ardore"])
	var requested: int = maxi(0, n)
	r["ardore"] = maxi(0, before - requested)
	var effective: int = before - int(r["ardore"])
	events.append({"t": "ritmo_loss", "resource": "ardore", "requested": requested, "amount": effective, "effective": effective, "value": int(r["ardore"]), "why": why, "wasted": requested - effective})
	if keep_level:
		r["hold"] = true
		return
	r["hold"] = false
	_settle_down(state, why, events)


# Abbassa direttamente il livello di n, lasciando l'Ardore com'e' (2.3 tipo 3).
static func drop_level(state: Dictionary, n: int, why: String, events: Array) -> void:
	var r: Dictionary = st(state)
	var from: int = int(r["level"])
	var to: int = maxi(CALMO, from - maxi(0, n))
	if to == from:
		return
	_set_level(state, to, why, events)


# Azzeramento totale: zero Ardore e CALMO (2.3 tipo 6). Non ridà nessuna disponibilita' del round (4.9).
static func reset(state: Dictionary, why: String, events: Array) -> void:
	var r: Dictionary = st(state)
	var before: int = int(r["ardore"])
	r["ardore"] = 0
	r["hold"] = false
	events.append({"t": "ritmo_loss", "amount": before, "value": 0, "why": why})
	if int(r["level"]) != CALMO:
		_set_level(state, CALMO, why, events)
	else:
		_clear_progress(r)


# Cambia il tetto (3.6). Aumentarlo non da' Ardore. Se scende: mode "taglia" toglie subito l'eccedenza,
# "blocca" tiene il valore attuale e ferma solo i nuovi guadagni (room() non sale sopra il tetto).
static func set_cap(state: Dictionary, cap: int, mode: String, events: Array) -> void:
	var r: Dictionary = st(state)
	r["cap"] = maxi(threshold(APICE), cap)
	if mode == "taglia" and int(r["ardore"]) > int(r["cap"]):
		drain(state, int(r["ardore"]) - int(r["cap"]), "tetto", events)


# ---------------------------------------------------------------- lettura degli eventi del motore

# Da chiamare dopo ogni azione (eroe, boss, scheggia) con la sua lista di eventi: genera Ardore, segna le condizioni,
# fa salire o scendere il livello. Gli eventi del RITMO finiscono in coda alla stessa lista.
static func after_events(state: Dictionary, events: Array) -> void:
	if not BattleTypes.RITMO_ON or state.get("pvp", false):
		return
	var r: Dictionary = st(state)
	if int(r["round"]) != int(state.get("round", 1)):
		r["round"] = int(state.get("round", 1))
		r["gen"] = {}                  # i limiti per fonte valgono per round (anti-farming, 2.2)
		r["saves"] = {}                # e il salvataggio del RITMO torna disponibile a tutti (4.1, 4.9)
	var boss: Dictionary = BattleState.boss(state)
	var n: int = events.size()         # si leggono solo gli eventi del motore, non quelli che aggiungiamo noi
	_boss_threat(state, events, n)     # prima la perdita del colpo del boss (decisa dalla parata), poi il resto
	for i in n:
		var e: Dictionary = events[i]
		match str(e.get("t", "")):
			"damage":
				if boss.is_empty() or str(e.get("dst", "")) != str(boss["id"]) or int(e.get("amount", 0)) <= 0:
					continue
				var src: Dictionary = BattleState.unit(state, str(e.get("src", "")))
				if src.is_empty() or str(src.get("side", "")) != "player":
					continue
				if bool(boss.get("exposed", false)):
					_mark(state, "colpo_break", APICE, events)
				if BattleTypes.color_multiplier(str(src["color"]), str(boss["color"])) > 1.0 or BattleTypes.hits_weak2(src, boss):
					_source(state, "debolezza", str(src["id"]), events)
					_saul_apice(state, src, events)
					_mark(state, "debolezza", ACCESO, events)
			"break":
				_source(state, "break", str(e.get("src", "")), events)
				_mark(state, "break", INCANDESCENTE, events)
			"timed_guard":
				var perfect: bool = str(e.get("grade", "")) == "perfect"
				_source(state, "parata_perfetta" if perfect else "parata", str(e.get("unit", "")), events)
				_mark(state, "parata", ACCESO, events)
				if perfect:
					_mark(state, "parata_perfetta", APICE, events)
			"counter":
				_source(state, "contrattacco", str(e.get("unit", "")), events)
			"rescue":
				_source(state, "soccorso", str(e.get("unit", "")), events)
			"heal":
				# una cura conta solo se serve davvero: chi la riceve era sotto la soglia di pericolo (niente farming di cure)
				var dst: Dictionary = BattleState.unit(state, str(e.get("dst", "")))
				if dst.is_empty() or str(dst.get("side", "")) != "player" or int(e.get("amount", 0)) <= 0:
					continue
				var was: int = int(dst["hp"]) - int(e["amount"])
				if float(was) < float(dst["max_hp"]) * BattleTypes.RITMO_HEAL_BELOW:
					_source(state, "cura", str(e.get("src", "")), events)
			"slancio":
				_source(state, "slancio", str(e.get("unit", "")), events)
			"hype":
				_rio_apice(state, e, events)
			"duo":
				_source(state, "duo", str(e.get("unit", "")), events)
			"down":
				var du: Dictionary = BattleState.unit(state, str(e.get("unit", "")))
				if not du.is_empty() and str(du.get("side", "")) == "player":
					drain(state, BattleTypes.RITMO_LOSS_KO, "ko", events)
	if (r["helpers"] as Dictionary).size() >= BattleTypes.RITMO_HELPERS:
		_mark(state, "collaborazione", INCANDESCENTE, events)
	if not bool(r["hold"]):
		_settle_down(state, "ardore", events)      # un livello tenuto con keep_level si rilascia al primo guadagno
	_settle_up(state, events)


# SALVATAGGIO DEL RITMO (fase R2; handoff 4, con la decisione dell'autore K4: «un solo QTE, per i PV»).
# Il colpo annunciato del boss minaccia l'Ardore. Non c'e' un QTE in piu': decide la stessa parata a tempo che protegge i PV.
# - colpo normale: parata buona = perdita dimezzata, perfetta = nessuna perdita;
#   colpo pesante (BattleResolver.is_heavy_boss_move): buona = 75%, perfetta = 50% (efficacia limitata, 4.5);
#   "devastante": true nella mossa del boss = la parata non salva l'Ardore (nessuna mossa lo ha ancora: e' un dato di design).
# - Ogni personaggio salva una volta per round: chi para usa il suo salvataggio; se l'ha gia' usato, la parata protegge
#   solo i PV e l'Ardore si perde per intero. Torna disponibile al round nuovo, non con un azzeramento (4.1, 4.9).
# - Conta solo il colpo annunciato (il primo boss_move della lista), non i colpi in piu' della catena: e' il colpo che si para.
# - La perdita si applica dopo l'esito della parata, a colpo risolto (4.4). Una parata mancata non si distingue da nessuna
#   parata (la UI scrive solo good/perfect): quindi un fallimento non consuma il salvataggio.
# Limiti noti, da decidere: niente secondo tentativo (4.3: servirebbe un secondo QTE, in conflitto con K4); chi salva e'
# sempre chi para, non un compagno scelto dal giocatore (4.1).
static func _boss_threat(state: Dictionary, events: Array, n: int) -> void:
	var move_id: String = ""
	for i in n:
		if str(events[i].get("t", "")) == "boss_move":
			move_id = str(events[i].get("move", ""))
			break
	if move_id == "":
		return
	var move: Dictionary = BattleContent.BOSS_MOVES.get(move_id, {})
	if float(move.get("mult", 0.0)) <= 0.0 and not bool(move.get("camera", false)):
		return                                  # una mossa che non colpisce non minaccia il RITMO
	var heavy: bool = BattleResolver.is_heavy_boss_move(move)
	var loss: int = int(BattleTypes.RITMO_HIT_LOSS["pesante" if heavy else "normale"])
	if loss <= 0:
		return
	var grade: String = ""
	var who: String = ""
	for i in n:
		var e: Dictionary = events[i]
		if str(e.get("t", "")) == "timed_guard":
			grade = str(e.get("grade", ""))
			who = str(e.get("unit", ""))
			break
	var r: Dictionary = st(state)
	var out: Dictionary = save_outcome(move, grade, (r["saves"] as Dictionary).has(who))
	if bool(out["used"]):
		r["saves"][who] = true
	var keep: float = float(out["keep"])
	var result: String = str(out["result"])
	var lost: int = int(round(float(loss) * keep))
	events.append({"t": "ritmo_save", "unit": who, "result": result, "threat": loss, "lost": lost, "heavy": heavy})
	if lost > 0:
		drain(state, lost, "colpo", events)


# Esito del salvataggio (puro, senza stato): grade = "" (nessuna parata), "good" o "perfect"; already = salvataggio gia' usato.
# keep = frazione della perdita che resta; used = il salvataggio si consuma.
static func save_outcome(move: Dictionary, grade: String, already: bool) -> Dictionary:
	if grade == "":
		return {"result": "nessuna", "keep": 1.0, "used": false}
	if bool(move.get("devastante", false)):
		return {"result": "devastante", "keep": 1.0, "used": false}
	if already:
		return {"result": "gia_usato", "keep": 1.0, "used": false}
	var k: Dictionary = BattleTypes.RITMO_SAVE_KEEP["pesante" if BattleResolver.is_heavy_boss_move(move) else "normale"]
	return {"result": "perfetto" if grade == "perfect" else "normale", "keep": float(k.get(grade, 1.0)), "used": true}


# Il salvataggio di questo personaggio e' ancora disponibile in questo round?
static func save_ready(state: Dictionary, uid: String) -> bool:
	var r: Dictionary = st(state)
	if int(r["round"]) != int(state.get("round", 1)):
		return true
	return not (r["saves"] as Dictionary).has(uid)


# Una fonte di Ardore: quantita' e limite per round da BattleTypes.RITMO_GAIN / RITMO_PER_ROUND.
static func _source(state: Dictionary, src: String, unit: String, events: Array) -> void:
	var amount: int = int(BattleTypes.RITMO_GAIN.get(src, 0))
	if amount <= 0:
		return
	var r: Dictionary = st(state)
	var used: int = int((r["gen"] as Dictionary).get(src, 0))
	if used >= int(BattleTypes.RITMO_PER_ROUND):
		return
	r["gen"][src] = used + 1
	gain(state, amount, src, unit, events)


# Segna una condizione fatta, ma solo se appartiene alla prossima transizione (le altre non si portano avanti: niente salti).
static func _mark(state: Dictionary, id: String, for_level: int, events: Array) -> void:
	var r: Dictionary = st(state)
	if int(r["level"]) + 1 != for_level or (r["done"] as Dictionary).has(id):
		return
	for c in CONDS[for_level]:
		if str(c["id"]) == id and str(c["kind"]) != "mantenimento":
			r["done"][id] = true
			events.append({"t": "ritmo_cond", "level": for_level, "cond": id})
			return


static func _maintained(state: Dictionary, id: String) -> bool:
	var boss: Dictionary = BattleState.boss(state)
	match id:
		"marchio":
			return not boss.is_empty() and Marks.count(boss) > 0
	return false


# Salita: soglia raggiunta + una condizione della transizione = un livello in su (automatico, 2.8). Uno solo per volta:
# dopo la salita le condizioni ripartono da zero, anche se l'Ardore e' gia' oltre la soglia successiva.
static func _settle_up(state: Dictionary, events: Array) -> void:
	var r: Dictionary = st(state)
	var lv: int = int(r["level"])
	if lv >= APICE or bool(r["hold"]):
		return
	if int(r["ardore"]) < threshold(lv + 1):
		r["ready"] = false
		return
	for c in CONDS[lv + 1]:
		if cond_ok(state, c):
			_set_level(state, lv + 1, str(c["id"]), events)
			return
	if not bool(r["ready"]):
		r["ready"] = true
		events.append({"t": "ritmo_ready", "level": lv + 1})


# Discesa: il livello scende finche' l'Ardore non regge la sua soglia (APICE si perde sotto la soglia di APICE, 5.1).
static func _settle_down(state: Dictionary, why: String, events: Array) -> void:
	var r: Dictionary = st(state)
	var lv: int = int(r["level"])
	var to: int = lv
	while to > CALMO and int(r["ardore"]) < threshold(to):
		to -= 1
	if to != lv:
		_set_level(state, to, why, events)
	elif lv < APICE and int(r["ardore"]) < threshold(lv + 1):
		r["ready"] = false


static func _set_level(state: Dictionary, to: int, why: String, events: Array) -> void:
	var r: Dictionary = st(state)
	var from: int = int(r["level"])
	r["level"] = to
	_clear_progress(r)
	events.append({"t": "ritmo_level", "from": from, "to": to, "why": why})
	if to > from:
		_on_reach(state, to, events)


# Nuovo livello = nuova transizione: condizioni e compagni che hanno contribuito ripartono da zero.
static func _clear_progress(r: Dictionary) -> void:
	r["done"] = {}
	r["helpers"] = {}
	r["ready"] = false


# ---------------------------------------------------------------- fase R4: cosa danno i livelli (VALORI DI PROVA)
# Ogni livello aggiunge, non sostituisce: INCANDESCENTE tiene quello che da' ACCESO, APICE tiene tutto (5.3).
# I bonus passivi si leggono dal livello di ADESSO: quando APICE si perde spariscono subito, le azioni gia' fatte restano (5.2).
#   ACCESO        a ogni salita: +1 Riserva di squadra (le reazioni costano meno da inseguire)
#   INCANDESCENTE ogni colpo della squadra mette +1 pressione BREAK (distinta dal danno, sez. 9)
#   APICE         universale: +10% danno della squadra; a ogni salita +1 EN a chi e' in piedi
#                 individuale (5.4, nessuno obbligatorio): Lance +1 pressione BREAK in piu', Nox cure +25%,
#                 Rio +50% HYPE guadagnato, Saul +1 EN quando colpisce una debolezza (una volta per round)
# Il +10% al cambio di categoria (RHYTHM_BONUS) resta a parte e si somma (K2). Nessuna tecnica APICE ancora (servono i costi, R3).

static func _on_reach(state: Dictionary, lv: int, events: Array) -> void:
	if lv == ACCESO and int(BattleTypes.RITMO_BONUS["acceso_riserva"]) > 0:
		BattleResolver._gain_reserve(state, int(BattleTypes.RITMO_BONUS["acceso_riserva"]), "ritmo", events)
	if lv == APICE and int(BattleTypes.RITMO_BONUS["apice_en"]) > 0:
		for p in BattleState.alive_players(state):
			var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
			if BattleState.is_alive(u):
				u["energy"] = mini(BattleTypes.MAX_ENERGY, int(u["energy"]) + int(BattleTypes.RITMO_BONUS["apice_en"]))
		st(state)["apice_tech"] = {}      # ogni APICE raggiunto ridà a tutti la loro tecnica
		events.append({"t": "apice_on"})


static func _on(state: Dictionary) -> bool:
	return BattleTypes.RITMO_ON and not bool(state.get("pvp", false)) and state.get("ritmo", null) is Dictionary


static func dmg_mult(state: Dictionary, attacker: Dictionary) -> float:
	if not _on(state) or level(state) < APICE or str(attacker.get("side", "")) != "player":
		return 1.0
	return float(BattleTypes.RITMO_BONUS["apice_danno"])


static func pressure_bonus(state: Dictionary, attacker: Dictionary) -> int:
	if not _on(state) or str(attacker.get("side", "")) != "player":
		return 0
	var lv: int = level(state)
	var b: int = 0
	if lv >= INCANDESCENTE:
		b += int(BattleTypes.RITMO_BONUS["incandescente_pressione"])
	if lv >= APICE and str(attacker.get("char", "")) == "ferri":
		b += int(BattleTypes.RITMO_BONUS["apice_lance_pressione"])
	return b


static func heal_mult(state: Dictionary, actor: Dictionary) -> float:
	if not _on(state) or level(state) < APICE or str(actor.get("char", "")) != "nox":
		return 1.0
	return float(BattleTypes.RITMO_BONUS["apice_nox_cure"])


static func _rio_apice(state: Dictionary, e: Dictionary, events: Array) -> void:
	if level(state) < APICE or str(e.get("why", "")) == "apice":
		return
	var u: Dictionary = BattleState.unit(state, str(e.get("unit", "")))
	if u.is_empty() or str(u.get("char", "")) != "zecca":
		return
	var extra: int = int(floor(float(int(e.get("amount", 0))) * float(BattleTypes.RITMO_BONUS["apice_rio_hype"])))
	Kits.add_hype(u, extra, events, "apice")


static func _saul_apice(state: Dictionary, src: Dictionary, events: Array) -> void:
	if level(state) < APICE or str(src.get("char", "")) != "saul":
		return
	var r: Dictionary = st(state)
	if (r["gen"] as Dictionary).has("saul_apice"):
		return
	r["gen"]["saul_apice"] = 1
	src["energy"] = mini(BattleTypes.MAX_ENERGY, int(src["energy"]) + int(BattleTypes.RITMO_BONUS["apice_saul_en"]))
	events.append({"t": "apice_saul", "unit": src["id"], "energy": int(BattleTypes.RITMO_BONUS["apice_saul_en"])})


# Tecnica APICE: la prima azione di ognuno in APICE ha il suo tocco (BattleTypes.RITMO_TECH).
# Lance toglie equilibrio, Saul fa un critico sicuro più forte, Rio riempie l'Hype, Nox cura tutta la squadra.
static func apice_tech(state: Dictionary, actor: Dictionary, move_id: String, move: Dictionary, events: Array) -> Dictionary:
	var out: Dictionary = {"mult": 1.0, "crit_pm": 0}
	if not _on(state) or level(state) < APICE or str(actor.get("side", "")) != "player" or move_id == BattleTypes.ACTION_GUARD:
		return out
	var c: String = str(actor.get("char", ""))
	if not BattleTypes.RITMO_TECH.has(c):
		return out
	var r: Dictionary = st(state)
	if not r.has("apice_tech"):
		r["apice_tech"] = {}
	if (r["apice_tech"] as Dictionary).has(str(actor["id"])):
		return out
	var hits_enemy: bool = move.has("mult") and str(move.get("target", "")) == "enemy"
	var tech: Dictionary = BattleTypes.RITMO_TECH[c]
	match c:
		"ferri":
			var boss: Dictionary = BattleState.boss(state)
			if not hits_enemy or boss.is_empty():
				return out
			BattleResolver._drain_balance(boss, int(tech["balance"]), actor, events)
		"saul":
			if not hits_enemy:
				return out
			out["mult"] = float(tech["mult"])
			out["crit_pm"] = 1000
		"zecca":
			Kits.add_hype(actor, int(tech["hype"]), events, "apice")
		"nox":
			for p in BattleState.alive_players(state):
				var m: Dictionary = BattleState.active_unit(state, str(p["id"]))
				if not BattleState.is_alive(m):
					continue
				var before: int = int(m["hp"])
				m["hp"] = mini(int(m["max_hp"]), before + int(round(float(m["max_hp"]) * float(tech["heal"]))))
				if int(m["hp"]) > before:
					events.append({"t": "heal", "src": actor["id"], "dst": m["id"], "amount": int(m["hp"]) - before})
	r["apice_tech"][str(actor["id"])] = 1
	events.append({"t": "apice_tech", "unit": actor["id"], "name": str(tech["name"])})
	return out
