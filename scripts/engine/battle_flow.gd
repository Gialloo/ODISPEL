class_name BattleFlow
extends RefCounted

# GIRO DEI TURNI DELLA V3 NEL MOTORE (Fase 0 del piano del combattimento, 04/11/2026).
# Prima il giro stava nella battaglia (battle3d._advance) e il simulatore (tools/v3_bilancio.gd) ne aveva una copia sua:
# ordine del round, azione rapida dello SLANCIO, vantaggio/agguato del primo round, turno dato alla tecnica a due.
# Ora sta qui, nello stato (state["flow"]), e chi guida la battaglia chiede soltanto "chi tocca adesso?".
# Perche': il motore deve poter giocare uno scontro intero senza animazioni, e la Timeline (Fase 1) si scrive in un posto solo.
# SeqRound resta l'esecutore delle singole azioni.
#
# TIMELINE (Fase 1, 04/11/2026; handoff 4.1-4.4, design doc parte VI §17 e parte XII). Con BattleTypes.TIMELINE_ON:
#  - ognuno (i quattro slot degli eroi, il boss, la scheggia) ha un istante del prossimo turno (state["tl"], centesimi interi);
#    tocca a chi ha l'istante piu' basso. Dopo l'azione si riprogramma a: adesso + ΔT, ΔT = C × 100 / (100 + 0,3 × (VEL − 100)),
#    C = costo di tempo dell'azione (ATTACCO 100, FIRMA rapida/standard/pesante 100/110/120, ULTIMATE 130).
#  - Decisione D1 dell'autore (04/11): l'ordine si calcola sempre in base alla velocita'; chi e' piu' veloce / ha piu' azioni
#    bonus le usa subito, chi e' piu' lento agisce dopo. Quindi se il turno di Rio torna prima che Lance abbia giocato il suo,
#    Rio lo gioca subito; il round alleato si chiude quando tutti e quattro hanno fatto il turno ordinario (regola 4.1).
#  - i nemici possono agire piu' volte nello stesso round (o nessuna): la mossa annunciata e' quella della loro PROSSIMA azione.
#  - un eroe KO (o che ha dato il turno a una tecnica a due) consuma il turno quando arriva la sua posizione.
#  - pareggi (4.3): priorita' esplicita, poi chi era gia' programmato prima, poi la VEL (ordine iniziale), poi l'id. Mai il caso.
#  - ANTICIPO / RITARDO / INTERRUZIONE sono operazioni del motore (shift, interrupt): ancora nessuna mossa le usa (fasi dopo).
# Con TIMELINE_ON = false (o BattleFlow.timeline = false) si gioca il giro a round della Fase 0, identico al 0.52.
#
# Uso: start_round(state[, ingresso]) -> next(state) finche' non torna {"end": true} -> per ogni voce:
#      player_action(...) (voce di un eroe) oppure boss_action(...) (voce "boss") -> finish(state) a fine round.

static var timeline: bool = BattleTypes.TIMELINE_ON


# Apre il round: SeqRound.begin e la lista dei turni per velocita'.
# ingresso (solo il primo round dello scontro): "vantaggio" = i nemici agiscono per ultimi, "agguato" = per primi.
static func start_round(state: Dictionary, ingresso: String = "") -> void:
	SeqRound.begin(state)
	Stability.mark(state)        # Fase 3: stabilita' nemica e BREAK a finestra (vedi Stability)
	if timeline:
		_tl_round(state, ingresso)
		return
	var turns: Array = SeqRound.order(state)
	if ingresso == "vantaggio" or ingresso == "agguato":
		var foes: Array = turns.filter(func(e: Dictionary) -> bool: return bool(e["boss"]))
		var rest: Array = turns.filter(func(e: Dictionary) -> bool: return not bool(e["boss"]))
		turns = rest + foes if ingresso == "vantaggio" else foes + rest
	state["flow"] = {"list": turns, "i": -1}


# Il turno successivo. Salta da solo chi non puo' giocarlo (eroe caduto, o che ha dato il turno a una tecnica a due).
# Ritorna la voce ({unit, player, boss, spd, [greg], [quick]}) oppure {"end": true} quando il round e' finito.
static func next(state: Dictionary) -> Dictionary:
	if timeline:
		return _tl_next(state)
	var f: Dictionary = state.get("flow", {})
	if f.is_empty():
		return {"end": true}
	var turns: Array = f["list"]
	while true:
		f["i"] = int(f["i"]) + 1
		if int(f["i"]) >= turns.size():
			return {"end": true}
		var e: Dictionary = turns[int(f["i"])]
		if bool(e["boss"]) or _can_play(state, e):
			return e
	return {"end": true}


# Azione dell'eroe di turno (come SeqRound.player_action). Se guadagna SLANCIO, l'azione rapida entra subito dopo.
# Con la Timeline: se e' il turno ordinario di chi agisce, il turno e' fatto e lo slot si riprogramma col costo dell'azione.
# Un'azione di chi NON e' di turno (Ultimate in diretta) non tocca la Timeline: resta fuori turno e gratuita come oggi (D9).
static func player_action(state: Dictionary, pid: String, choice: Dictionary, quick: bool = false) -> Array:
	if timeline:
		return _tl_player(state, pid, choice, quick)
	var ev: Array = SeqRound.player_action(state, pid, choice, quick)
	if not quick:
		Stability.on_ally_action(state, ev)      # Fase 3: la finestra BREAK conta le azioni ordinarie alleate
	var f: Dictionary = state.get("flow", {})
	if not f.is_empty():
		for x in ev:
			if str(x.get("t", "")) == "slancio":
				(f["list"] as Array).insert(int(f["i"]) + 1, {"unit": str(x["unit"]), "player": str(x["player"]), "boss": false, "spd": -1, "extra": true, "quick": true})
	return ev


# Turno di un nemico (come SeqRound.boss_action). Con la Timeline la mossa annunciata e' quella della PROSSIMA azione del boss:
# dopo l'azione si riprogramma e annuncia subito la mossa successiva del ciclo (nel 0.52 l'annuncio era a inizio round e il boss,
# quasi sempre piu' lento, agiva dopo gli eroi: ora puo' agire per primo nel round, quindi l'annuncio non puo' aspettare il round).
static func boss_action(state: Dictionary, unit_id: String = BattleState.BOSS_ID) -> Array:
	if not timeline or not state.has("tl"):
		return SeqRound.boss_action(state, unit_id)
	var tl: Dictionary = state["tl"]
	var key: String = "greg" if unit_id == Gregario.ID else "boss"
	if key == "boss" and bool(tl.get("tele_used", false)):
		_announce_next(state)
	if key == "greg" and bool(tl.get("greg_used", false)):
		Gregario.telegraph(state)
	var ev: Array = SeqRound.boss_action(state, unit_id)
	if key == "boss":
		tl["tele_used"] = true
		tl["snap"] = (state["seq"].get("snap", {}) as Dictionary).duplicate(true)
	else:
		tl["greg_used"] = true
	var s: Dictionary = (tl["slots"] as Dictionary).get(key, {})
	if not s.is_empty():
		_schedule(tl, s, BattleTypes.TL_ENEMY_COST, _spd_of(state, s))
	if key == "boss" and str(state["winner"]) == "":
		_announce_next(state)      # la prossima mossa si annuncia subito: gli eroi che agiscono prima la vedono e possono rispondere
		# le reazioni scelte valevano per la mossa appena fatta; per la prossima si sceglie di nuovo (Ultimate in diretta compresa)
		state["reactions"] = []
		state["react_grade"] = {}
		if state.has("seq"):
			state["seq"]["boss_acted"] = false
	return ev


# Fine round (come SeqRound.finish). Con la Timeline la mossa annunciata e' quella della prossima azione del boss e resta
# la stessa anche a cavallo dei round (non si salta un pezzo del ciclo); cambia solo col cambio di fase (ciclo nuovo).
static func finish(state: Dictionary) -> Array:
	if not timeline or not state.has("tl"):
		return SeqRound.finish(state)
	var tl: Dictionary = state["tl"]
	var keep: bool = not bool(tl.get("tele_used", false))      # falso solo dopo un'INTERRUZIONE: la mossa e' persa
	var tele: Dictionary = (state.get("telegraph", {}) as Dictionary).duplicate()
	var cyc: int = int(state.get("cycle_index", 0))
	var phase: int = int(state.get("phase", 1))
	# Difese che aspettano il boss: SeqRound fa durare fino al round dopo gli stati e gli scudi presi DOPO la mossa del boss.
	# Con la Timeline un round puo' finire senza che il boss abbia agito: allora vale tutto cio' che e' stato preso dalla sua
	# ultima azione (o dall'inizio dello scontro), cosi' Guardia e scudi non scadono prima del colpo che dovevano parare.
	# Allo stesso modo le reazioni gia' scelte (Schiva, Copri, Interrompi, pagate con la Riserva) e l'esito dei loro minigiochi
	# restano per la prossima azione del boss, anche se arriva nel round dopo (SeqRound.begin le azzererebbe). Dopo ogni azione
	# del boss si azzerano (boss_action): quelle presenti a fine round sono sempre per la sua prossima mossa.
	if not (state.get("reactions", []) as Array).is_empty():
		tl["keep"] = {"reactions": (state["reactions"] as Array).duplicate(true), "react_grade": (state.get("react_grade", {}) as Dictionary).duplicate(true)}
	if state.has("seq") and not bool(state["seq"].get("boss_acted", false)):
		state["seq"]["boss_acted"] = true
		state["seq"]["snap"] = (tl["snap"] as Dictionary).duplicate(true) if tl.has("snap") else _empty_snap(state)
	var ev: Array = SeqRound.finish(state)
	if keep and str(state["winner"]) == "" and int(state.get("phase", 1)) == phase and not tele.is_empty():
		state["cycle_index"] = cyc
		var t: String = str(tele.get("target", ""))
		var tp: Dictionary = BattleState.player(state, t)
		if t == "" or tp.is_empty() or not BattleState.player_alive(state, tp):
			tele["target"] = str(state["telegraph"].get("target", ""))
		state["telegraph"]["move"] = str(tele["move"])
		state["telegraph"]["target"] = str(tele["target"])
		Tactics.roll_chain(state, BattleContent.cycle_for(str(BattleState.boss(state)["char"]), int(state.get("phase", 1))))
	elif str(state["winner"]) == "" and int(state.get("phase", 1)) != phase and (tl["slots"] as Dictionary).has("boss"):
		# CAMBIO DI FASE: la trasformazione occupa il boss come un'azione, rientra nella Timeline da adesso. Cosi' la prima mossa
		# della fase nuova (annunciata ora) arriva dopo i turni degli eroi e si puo' rispondere (nel 0.52 il boss agiva per ultimo).
		# Un'eventuale interruzione della fase precedente non deve saltare la prima mossa del nuovo ciclo.
		tl["tele_used"] = false
		_schedule(tl, tl["slots"]["boss"], BattleTypes.TL_ENEMY_COST, _spd_of(state, tl["slots"]["boss"]))
	# Non azzerare tele_used qui: se un'INTERRUZIONE ha cancellato la mossa e il boss
	# rientra solo nel round successivo, il flag deve arrivare a boss_action(), che annuncera' il nuovo attacco.
	tl["greg_used"] = false
	return ev


# Lista dei turni (per mostrarla) e posizione del turno attuale (-1 prima del primo).
# Con la Timeline e' una PREVISIONE: il turno attuale e poi i prossimi, come andrebbero se tutti facessero un ATTACCO.
static func turns(state: Dictionary) -> Array:
	if timeline and state.has("tl"):
		return preview(state, 8)
	return state.get("flow", {}).get("list", [])


static func index(state: Dictionary) -> int:
	if timeline and state.has("tl"):
		return 0 if str(state["tl"].get("cur", "")) != "" else -1
	return int(state.get("flow", {}).get("i", -1))


# Numero progressivo del turno nello scontro (per riconoscere "un turno nuovo" anche quando lo stesso eroe gioca due volte).
static func turn_no(state: Dictionary) -> int:
	if timeline and state.has("tl"):
		return int(state["tl"].get("n", 0))
	return index(state)


static func _can_play(state: Dictionary, e: Dictionary) -> bool:
	var pl: Dictionary = BattleState.player(state, str(e["player"]))
	if pl.is_empty() or not BattleState.player_alive(state, pl):
		return false
	if bool(e.get("quick", false)):
		return true
	var u: Dictionary = BattleState.active_unit(state, str(e["player"]))
	return not DuoTechs.spent(state, str(u.get("id", "")))


# ======================================================================== TIMELINE

# ΔT in centesimi: C × 100 / (100 + 0,3 × (VEL − 100)), arrotondato all'intero. Il divisore non scende sotto 10 (VEL assurde).
static func delta_t(cost: int, spd: int) -> int:
	var den: float = maxf(10.0, float(BattleTypes.TL_VEL_PIVOT) + BattleTypes.TL_VEL_K * float(spd - BattleTypes.TL_VEL_PIVOT))
	return int(round(float(cost) * 10000.0 / den))


# Costo di tempo di una mossa degli eroi (handoff 4.2). Una FIRMA puo' dichiarare "tempo": "rapida" | "standard" | "pesante".
static func time_cost(move_id: String) -> int:
	var m: Dictionary = BattleContent.MOVES.get(move_id, {})
	match str(m.get("kind", "basic")):
		"ult":
			return int(BattleTypes.TL_COST["ultimate"])
		"skill":
			return int(BattleTypes.TL_COST.get(str(m.get("tempo", BattleTypes.TL_SKILL_DEFAULT)), BattleTypes.TL_COST[BattleTypes.TL_SKILL_DEFAULT]))
	return int(BattleTypes.TL_COST["attacco"])


# ANTICIPO (family "anticipo") o RITARDO ("ritardo") sul tempo rimanente di uno slot ("p1"..., "boss", "greg").
# Non si accumula nella stessa famiglia: vale la piu' forte (handoff 4.4); anticipo e ritardo insieme si sommano.
# Ritorna l'evento {"t": "tl_shift", ...} (vuoto se non cambia nulla). Si azzera quando lo slot agisce.
static func shift(state: Dictionary, key: String, family: String, strength: String) -> Dictionary:
	var tl: Dictionary = state.get("tl", {})
	var s: Dictionary = (tl.get("slots", {}) as Dictionary).get(key, {})
	var pct: int = int(BattleTypes.TL_SHIFT.get(strength, 0))
	if s.is_empty() or pct <= 0 or (family != "anticipo" and family != "ritardo"):
		return {}
	var fk: String = "a" if family == "anticipo" else "r"
	if pct <= int(s.get(fk, 0)):
		return {}
	var now: int = int(tl["now"])
	var m_old: int = 100 - int(s.get("a", 0)) + int(s.get("r", 0))
	var base_rem: float = float(maxi(0, int(s["at"]) - now)) * 100.0 / float(maxi(1, m_old))
	s[fk] = pct
	var m_new: int = 100 - int(s.get("a", 0)) + int(s.get("r", 0))
	var before: int = int(s["at"])
	s["at"] = now + int(round(base_rem * float(m_new) / 100.0))
	return {"t": "tl_shift", "slot": key, "family": family, "pct": pct, "from": before - now, "to": int(s["at"]) - now}


# INTERRUZIONE: l'azione preparata dello slot si cancella e lo slot rientra nella Timeline con il 50% del costo
# dell'azione interrotta (handoff 4.4: mai una cancellazione permanente del turno). Per il boss la mossa annunciata e' persa:
# la prossima azione ne annuncia una nuova. Lo SBILANCIAMENTO arriva con la Fase 3.
static func interrupt(state: Dictionary, key: String, cost: int = -1) -> Dictionary:
	var tl: Dictionary = state.get("tl", {})
	var s: Dictionary = (tl.get("slots", {}) as Dictionary).get(key, {})
	if s.is_empty():
		return {}
	var c: int = (BattleTypes.TL_ENEMY_COST if bool(s["boss"]) else int(BattleTypes.TL_COST["attacco"])) if cost < 0 else cost
	_schedule(tl, s, int(round(float(c) * float(BattleTypes.TL_INTERRUPT_PCT) / 100.0)), _spd_of(state, s))
	if key == "boss":
		tl["tele_used"] = true
	return {"t": "tl_interrupt", "slot": key, "to": int(s["at"]) - int(tl["now"])}


# Previsione dei prossimi `n` turni (il primo e' quello attuale, se c'e'), senza toccare lo stato.
static func preview(state: Dictionary, n: int) -> Array:
	var tl: Dictionary = state.get("tl", {})
	if tl.is_empty():
		return []
	var out: Array = []
	var cur: String = str(tl.get("cur", ""))
	var sim: Dictionary = {}
	var done: Dictionary = (tl.get("done", {}) as Dictionary).duplicate()
	var st: int = int(tl.get("stamp", 0))
	for k in tl["slots"]:
		sim[k] = (tl["slots"][k] as Dictionary).duplicate()
	if cur != "" and sim.has(cur):
		var e0: Dictionary = _entry(state, sim[cur])
		if tl.has("cur_quick"):
			e0 = (tl["cur_quick"] as Dictionary).duplicate()
		else:
			# Il turno corrente e' gia' mostrato: simula anche il suo completamento,
			# altrimenti _pick() lo seleziona di nuovo come se non avesse ancora agito.
			var current_slot: Dictionary = sim[cur]
			var current_cost: int = BattleTypes.TL_ENEMY_COST if bool(current_slot.get("boss", false)) else int(BattleTypes.TL_COST["attacco"])
			current_slot["at"] = int(tl.get("now", current_slot.get("at", 0))) + delta_t(current_cost, _spd_of(state, current_slot))
			current_slot["a"] = 0
			current_slot["r"] = 0
			current_slot.erase("prio")
			st += 1
			current_slot["stamp"] = st
			if not bool(current_slot.get("boss", false)):
				done[cur] = true
		out.append(e0)
	for q in (tl.get("quick", []) as Array):
		out.append((q as Dictionary).duplicate(true))
	# La previsione deve mostrare anche gli SLANCI protetti gia' pronti: next() li esegue
	# prima di scegliere il prossimo slot ordinario. Qui non chiamiamo ready_kept(), perche'
	# quella funzione ripulisce lo stato eliminando i bersagli sconfitti.
	var kept: Array = []
	if str(state.get("winner", "")) == "" and state.has("slancio_kept"):
		for uid in state["slancio_kept"]:
			var saved: Dictionary = state["slancio_kept"][uid]
			var target: Dictionary = BattleState.unit(state, str(saved.get("dst", "")))
			var actor: Dictionary = BattleState.unit(state, str(uid))
			if target.is_empty() or actor.is_empty() or not BattleState.is_alive(target) or not BattleState.is_alive(actor) or Slancio.blocked(target):
				continue
			var slot: String = BattleState.slot_of(state, str(uid))
			var saved_slot: Dictionary = (tl["slots"] as Dictionary).get(slot, {})
			kept.append({"unit": str(uid), "player": str(saved.get("player", slot)), "boss": false, "spd": -1, "extra": true, "quick": true, "slancio": true, "kept": true, "waive": bool(saved.get("waive", false)), "_at": int(saved_slot.get("at", 0))})
	kept.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["_at"]) < int(b["_at"]))
	for q in kept:
		q.erase("_at")
		out.append(q)
	var extra: Array = (tl.get("extra", []) as Array).duplicate()
	var guard: int = 0
	while out.size() < n and guard < 64:
		guard += 1
		if _all_done(state, done):
			var found_bonus: bool = false
			while not extra.is_empty():
				var bonus: Dictionary = extra.pop_front()
				if _can_play(state, bonus):
					out.append(bonus)
					found_bonus = true
					break
			if found_bonus:
				continue
			break
		var k: String = _pick(sim)
		if k == "":
			break
		var s: Dictionary = sim[k]
		var t: int = int(s["at"])
		s["at"] = t + delta_t(BattleTypes.TL_ENEMY_COST if bool(s["boss"]) else int(BattleTypes.TL_COST["attacco"]), _spd_of(state, s))
		s["a"] = 0
		s["r"] = 0
		s.erase("prio")
		st += 1
		s["stamp"] = st
		if bool(s["boss"]):
			if k == "greg" and not Gregario.alive(state):
				sim.erase(k) # come _tl_next: un gregario sconfitto esce dalla Timeline
				continue
			if not BattleState.is_alive(BattleState.unit(state, str(_entry(state, s)["unit"]))):
				sim.erase(k)
				continue
			out.append(_entry(state, s))
			continue
		if not _hero_can_play(state, k):
			# Lo slot KO/ceduto non agisce, ma viene riprogrammato: senza questo
			# passaggio _pick lo riseleziona all'infinito e nasconde gli altri turni.
			done[k] = true
			s["at"] = t + delta_t(int(BattleTypes.TL_COST["attacco"]), _spd_of(state, s))
			s["a"] = 0
			s["r"] = 0
			s.erase("prio")
			st += 1
			s["stamp"] = st
			continue
		done[k] = true
		out.append(_entry(state, s))
	return out


# ---------------------------------------------------------------- interni della Timeline

# Inizio round con la Timeline: il primo round crea le posizioni (D8: tutti partono dal ΔT di un ATTACCO, quindi l'ordine
# iniziale e' quello per VEL, come nel 0.52); i round dopo continuano dalle posizioni raggiunte.
static func _tl_round(state: Dictionary, ingresso: String) -> void:
	if not state.has("tl"):
		_tl_init(state, ingresso)
	var tl: Dictionary = state["tl"]
	if tl.has("keep"):
		state["reactions"] = tl["keep"]["reactions"]
		state["react_grade"] = tl["keep"]["react_grade"]
		tl.erase("keep")
	tl["done"] = {}
	tl["quick"] = []
	tl["extra"] = Kits.extra_turns(state)       # il riposo di Nox: un turno in piu' alla fine del round, fuori Timeline (D9)
	tl["cur"] = ""
	tl.erase("cur_quick")
	# la scheggia puo' essere entrata o caduta: la sua voce segue chi c'e'
	if Gregario.alive(state) and not (tl["slots"] as Dictionary).has("greg"):
		var g: Dictionary = {"key": "greg", "player": "", "boss": true, "greg": true, "at": 0, "stamp": 0, "a": 0, "r": 0, "spd0": int(Gregario.unit(state)["spd"])}
		_schedule(tl, g, BattleTypes.TL_ENEMY_COST, _spd_of(state, g))
		tl["slots"]["greg"] = g
	elif not Gregario.alive(state):
		(tl["slots"] as Dictionary).erase("greg")
	state["flow"] = {"list": [], "i": -1}


static func _tl_init(state: Dictionary, ingresso: String) -> void:
	var tl: Dictionary = {"now": 0, "stamp": 0, "n": 0, "slots": {}, "done": {}, "quick": [], "extra": [], "cur": "", "tele_used": false, "greg_used": false}
	state["tl"] = tl
	var list: Array = []
	for p in state["players"]:
		var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
		list.append({"key": str(p["id"]), "player": str(p["id"]), "boss": false, "spd0": int(u.get("spd", 0))})
	var boss: Dictionary = BattleState.boss(state)
	list.append({"key": "boss", "player": "", "boss": true, "spd0": int(round(float(boss["spd"]) * Marks.boss_mult(boss, "spd")))})
	if Gregario.alive(state):
		list.append({"key": "greg", "player": "", "boss": true, "greg": true, "spd0": int(Gregario.unit(state)["spd"])})
	# timbri d'ingresso in ordine di VEL (pareggio per id dell'unita', come il 0.52): decidono i pareggi del primo giro
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["spd0"]) != int(b["spd0"]):
			return int(a["spd0"]) > int(b["spd0"])
		return _uid_of(state, a) < _uid_of(state, b))
	var last_hero: int = 0
	for s in list:
		s["at"] = 0
		s["a"] = 0
		s["r"] = 0
		_schedule_from(tl, s, 0, BattleTypes.TL_ENEMY_COST if bool(s["boss"]) else int(BattleTypes.TL_COST["attacco"]), _spd_of(state, s))
		if not bool(s["boss"]):
			last_hero = maxi(last_hero, int(s["at"]))
		tl["slots"][str(s["key"])] = s
	# D7: vantaggio = i nemici agiscono dopo tutti gli eroi al primo giro, agguato = prima (come nel 0.52)
	if ingresso == "vantaggio" or ingresso == "agguato":
		for k in tl["slots"]:
			var s: Dictionary = tl["slots"][k]
			if bool(s["boss"]):
				s["at"] = last_hero + 1 if ingresso == "vantaggio" else 0


static func _tl_next(state: Dictionary) -> Dictionary:
	if not state.has("tl"):
		return {"end": true}
	var tl: Dictionary = state["tl"]
	tl.erase("cur_quick")
	if not (tl["quick"] as Array).is_empty():
		var q: Dictionary = (tl["quick"] as Array).pop_front()
		tl["cur"] = str(q["player"])
		tl["cur_quick"] = q
		tl["n"] = int(tl["n"]) + 1
		return q
	# SLANCIO PROTETTO (Fase 2, handoff 5.6): appena il bersaglio torna vulnerabile, chi lo conservava lo usa subito,
	# nell'ordine della Timeline (chi ha il prossimo turno piu' vicino prima). Non e' un turno ordinario.
	var ready: Array = Slancio.ready_kept(state)
	if not ready.is_empty():
		ready.sort_custom(func(a: String, b: String) -> bool:
			var sa: Dictionary = (tl["slots"] as Dictionary).get(BattleState.slot_of(state, a), {})
			var sb: Dictionary = (tl["slots"] as Dictionary).get(BattleState.slot_of(state, b), {})
			return int(sa.get("at", 0)) < int(sb.get("at", 0)))
		var kq: Dictionary = Slancio.take_kept(state, str(ready[0]))
		tl["cur"] = str(kq["player"])
		tl["cur_quick"] = kq
		tl["n"] = int(tl["n"]) + 1
		return kq
	var guard: int = 0
	while guard < 256:
		guard += 1
		if _all_done(state, tl["done"]):
			while not (tl["extra"] as Array).is_empty():
				var x: Dictionary = (tl["extra"] as Array).pop_front()
				if _can_play(state, x):
					tl["cur"] = str(x["player"])
					tl["cur_quick"] = x
					tl["n"] = int(tl["n"]) + 1
					return x
			tl["cur"] = ""
			return {"end": true}
		var k: String = _pick(tl["slots"])
		if k == "":
			tl["cur"] = ""
			return {"end": true}
		var s: Dictionary = tl["slots"][k]
		tl["now"] = maxi(int(tl["now"]), int(s["at"]))
		if bool(s["boss"]):
			if k == "greg" and not Gregario.alive(state):
				(tl["slots"] as Dictionary).erase("greg")
				continue
			tl["cur"] = k
			tl["n"] = int(tl["n"]) + 1
			return _entry(state, s)
		if not _hero_can_play(state, k):
			# KO o turno dato alla tecnica a due: il turno ordinario si consuma quando arriva la sua posizione (4.1)
			tl["done"][k] = true
			_schedule(tl, s, int(BattleTypes.TL_COST["attacco"]), _spd_of(state, s))
			continue
		tl["cur"] = k
		tl["n"] = int(tl["n"]) + 1
		return _entry(state, s)
	return {"end": true}


static func _tl_player(state: Dictionary, pid: String, choice: Dictionary, quick: bool) -> Array:
	var tl: Dictionary = state.get("tl", {})
	var mine: bool = not tl.is_empty() and str(tl.get("cur", "")) == pid and not tl.has("cur_quick")
	var mv: String = str(choice.get("move", BattleTypes.ACTION_ATTACK))
	if BattleResolver.validate_choice(state, pid, choice) != "":
		mv = BattleTypes.ACTION_ATTACK                  # come SeqRound: una scelta non valida diventa un Attacco
	var ev: Array = SeqRound.player_action(state, pid, choice, quick)
	if tl.is_empty():
		return ev
	var s: Dictionary = (tl["slots"] as Dictionary).get(pid, {})
	if mine and not quick and not s.is_empty():
		tl["done"][pid] = true
		_schedule(tl, s, time_cost(mv), _spd_of(state, s))
	if mine and not quick:
		Stability.on_ally_action(state, ev)      # Fase 3: solo il turno ordinario consuma la finestra BREAK (non SLANCIO ne' Ultimate in diretta)
	_elite_delay(state, ev)
	var cq: Dictionary = tl.get("cur_quick", {})
	if quick and str(tl.get("cur", "")) == pid and not s.is_empty() and bool(cq.get("slancio", false)) and not bool(cq.get("waive", false)):
		s["at"] = int(s["at"]) + BattleTypes.TL_SLANCIO_EXTRA * 100      # l'azione dello SLANCIO costa +15 sul recupero gia' fissato
		# (lo SLANCIO protetto la prima volta non lo paga: handoff 5.6)
	for x in ev:
		if str(x.get("t", "")) == "slancio":
			(tl["quick"] as Array).append({"unit": str(x["unit"]), "player": str(x["player"]), "boss": false, "spd": -1, "extra": true, "quick": true, "slancio": true})
	return ev


# Fase 3: un elite rotto non perde l'azione, la sua prossima arriva in RITARDO forte (handoff 9.1).
static func _elite_delay(state: Dictionary, ev: Array) -> void:
	var boss: Dictionary = BattleState.boss(state)
	if not bool(boss.get("brk_delay", false)):
		return
	boss.erase("brk_delay")
	var sh: Dictionary = shift(state, "boss", "ritardo", "forte")
	if not sh.is_empty():
		ev.append(sh)


# Come SeqRound._snapshot, ma senza nulla: tutto cio' che la squadra ha adesso conta come preso dopo l'ultima mossa del boss
static func _empty_snap(state: Dictionary) -> Dictionary:
	var snap: Dictionary = {}
	for uid in state["units"]:
		if str(state["units"][uid]["side"]) == "player":
			snap[uid] = {"statuses": {}, "shield": 0}
	return snap


# Annuncia la prossima mossa del boss (avanza il ciclo di uno).
static func _announce_next(state: Dictionary) -> void:
	state["cycle_index"] = int(state["cycle_index"]) + 1
	BattleResolver.announce(state)
	state["tl"]["tele_used"] = false


# Tutti e quattro (tutti gli slot degli eroi) hanno fatto il turno ordinario?
static func _all_done(state: Dictionary, done: Dictionary) -> bool:
	for p in state["players"]:
		if not bool(done.get(str(p["id"]), false)):
			return false
	return true


static func _hero_can_play(state: Dictionary, pid: String) -> bool:
	return _can_play(state, {"player": pid})


# Chi tocca: istante piu' basso; pareggio: priorita' esplicita, poi chi era programmato prima (timbro), poi l'ordine iniziale
static func _pick(slots: Dictionary) -> String:
	var best: String = ""
	for k in slots:
		if best == "" or _first(slots[k], slots[best]):
			best = str(k)
	return best


static func _first(a: Dictionary, b: Dictionary) -> bool:
	if int(a["at"]) != int(b["at"]):
		return int(a["at"]) < int(b["at"])
	if int(a.get("prio", 0)) != int(b.get("prio", 0)):
		return int(a.get("prio", 0)) > int(b.get("prio", 0))
	return int(a["stamp"]) < int(b["stamp"])


static func _schedule(tl: Dictionary, s: Dictionary, cost: int, spd: int) -> void:
	_schedule_from(tl, s, int(tl["now"]), cost, spd)


static func _schedule_from(tl: Dictionary, s: Dictionary, from: int, cost: int, spd: int) -> void:
	s["at"] = from + delta_t(cost, spd)
	s["a"] = 0
	s["r"] = 0
	s.erase("prio")
	tl["stamp"] = int(tl["stamp"]) + 1
	s["stamp"] = int(tl["stamp"])


# VEL di chi sta nello slot adesso (gli eroi possono cambiare personaggio; il boss con i marchi, come SeqRound.order)
static func _spd_of(state: Dictionary, s: Dictionary) -> int:
	if bool(s.get("greg", false)):
		return int(Gregario.unit(state).get("spd", s.get("spd0", 100))) if Gregario.alive(state) else int(s.get("spd0", 100))
	if bool(s["boss"]):
		var boss: Dictionary = BattleState.boss(state)
		return int(round(float(boss["spd"]) * Marks.boss_mult(boss, "spd")))
	var u: Dictionary = BattleState.active_unit(state, str(s["player"]))
	return int(u.get("spd", s.get("spd0", 100)))


static func _uid_of(state: Dictionary, s: Dictionary) -> String:
	if bool(s.get("greg", false)):
		return Gregario.ID
	if bool(s["boss"]):
		return str(BattleState.boss(state)["id"])
	return str(BattleState.active_unit(state, str(s["player"])).get("id", ""))


# La voce come la usa chi guida i turni: {unit, player, boss, spd, [greg]} piu' "at" (istante, centesimi)
static func _entry(state: Dictionary, s: Dictionary) -> Dictionary:
	var e: Dictionary = {"unit": _uid_of(state, s), "player": str(s["player"]), "boss": bool(s["boss"]), "spd": _spd_of(state, s), "at": int(s["at"])}
	if bool(s.get("greg", false)):
		e["greg"] = true
	return e
