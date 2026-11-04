extends SceneTree

# FASE 1 DEL COMBATTIMENTO: la TIMELINE (BattleFlow con BattleTypes.TIMELINE_ON). Handoff 4.1-4.4, design doc 17 e regole XII.
# Si prova: la formula ΔT, l'ordine per VEL, il doppio turno di chi e' molto veloce (D1 dell'autore), il round che si chiude
# quando tutti e quattro hanno fatto il turno, il boss che agisce due volte o nessuna in un round (con la mossa annunciata giusta),
# KO che consuma il turno, pareggi senza caso, ANTICIPO/RITARDO senza accumulo, INTERRUZIONE al 50%, SLANCIO +15,
# vantaggio/agguato e scontri interi in AUTO ripetibili (stesso seme = stessi eventi).
var fails: int = 0


func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _team() -> Array:
	var t: Array = []
	for id in ["ferri", "nox", "zecca", "saul"]:
		t.append(BattleContent.default_entry(id))
	return t


func _fresh(boss: String, seed_value: int, greg: String = "") -> Dictionary:
	var s: Dictionary = BattleState.create_solo("IO", _team(), [], boss, seed_value)
	if greg != "":
		Gregario.add(s, greg)
	return s


func _pid(s: Dictionary, ch: String) -> String:
	for p in s["players"]:
		if str(BattleState.active_unit(s, str(p["id"])).get("char", "")) == ch:
			return str(p["id"])
	return ""


func _set_spd(s: Dictionary, ch: String, v: int) -> void:
	BattleState.active_unit(s, _pid(s, ch))["spd"] = v


func _attack() -> Dictionary:
	return {"swap": "", "move": BattleTypes.ACTION_ATTACK, "target": ""}


# Gioca il turno restituito da next() con un ATTACCO (o la mossa del nemico) e ritorna gli eventi
func _play(s: Dictionary, e: Dictionary) -> Array:
	if bool(e.get("greg", false)):
		return BattleFlow.boss_action(s, Gregario.ID)
	if bool(e["boss"]):
		return BattleFlow.boss_action(s)
	return BattleFlow.player_action(s, str(e["player"]), _attack(), bool(e.get("quick", false)))


func _formula() -> void:
	# la tabella della spec (handoff 4.2): ATTACCO a VEL 80..130
	var want: Dictionary = {80: 10638, 90: 10309, 100: 10000, 110: 9709, 120: 9434, 130: 9174}
	for v in want:
		check(BattleFlow.delta_t(100, int(v)) == int(want[v]), "ΔT attacco a VEL %d = %d (atteso %d)" % [v, BattleFlow.delta_t(100, int(v)), want[v]])
	check(BattleFlow.delta_t(130, 100) == 13000 and BattleFlow.delta_t(110, 100) == 11000, "ULTIMATE 130, FIRMA standard 110 a VEL 100")
	check(BattleFlow.delta_t(100, -1000) > 0, "VEL assurda: ΔT resta positivo")
	check(BattleFlow.time_cost("attack") == 100 and BattleFlow.time_cost("guard") == 100, "ATTACCO e GUARDIA costano 100")
	var ult: String = ""
	var skill: String = ""
	for id in BattleContent.MOVES:
		var k: String = str(BattleContent.MOVES[id].get("kind", ""))
		if k == "ult" and ult == "":
			ult = str(id)
		if k == "skill" and skill == "" and not BattleContent.MOVES[id].has("tempo"):
			skill = str(id)
	check(BattleFlow.time_cost(ult) == 130, "ULTIMATE costa 130 (%s)" % ult)
	check(BattleFlow.time_cost(skill) == 110, "FIRMA senza tempo dichiarato = standard 110 (%s)" % skill)


func _ordine_iniziale() -> void:
	var s: Dictionary = _fresh("semaforo", 1)
	BattleFlow.start_round(s)
	var old: Array = SeqRound.order(s)
	var got: Array = []
	var guard: int = 0
	while got.size() < old.size() and guard < 20:
		guard += 1
		var e: Dictionary = BattleFlow.next(s)
		if bool(e.get("end", false)):
			break
		if not bool(e.get("quick", false)):
			got.append(str(e["unit"]))      # l'azione rapida dello SLANCIO non e' nella lista del 0.52
		_play(s, e)
	var want: Array = []
	for e in old:
		want.append(str(e["unit"]))
	check(got == want, "primo giro: stesso ordine per VEL del 0.52 (%s / %s)" % [str(got), str(want)])


func _doppio_turno() -> void:
	# D1: Rio velocissimo, Lance lentissimo: Rio gioca subito il turno che gli torna prima che Lance abbia fatto il suo
	var s: Dictionary = _fresh("semaforo", 2)
	_set_spd(s, "zecca", 400)
	_set_spd(s, "ferri", 40)
	BattleFlow.start_round(s)
	var rio: String = _pid(s, "zecca")
	var lance: String = _pid(s, "ferri")
	var rio_n: int = 0
	var lance_seen: bool = false
	var rio_before_lance: int = 0
	var guard: int = 0
	while guard < 40:
		guard += 1
		var e: Dictionary = BattleFlow.next(s)
		if bool(e.get("end", false)):
			break
		if not bool(e["boss"]) and str(e["player"]) == rio and not bool(e.get("quick", false)):
			rio_n += 1
			if not lance_seen:
				rio_before_lance += 1
		if not bool(e["boss"]) and str(e["player"]) == lance:
			lance_seen = true
		_play(s, e)
		if str(s["winner"]) != "":
			break
	check(lance_seen, "il round si chiude solo dopo il turno di Lance")
	check(rio_before_lance >= 2, "Rio gioca almeno due turni prima di Lance (%d)" % rio_before_lance)
	check(bool(s["tl"]["done"].get(lance, false)), "a fine round Lance ha fatto il turno ordinario")


func _boss_due_volte() -> void:
	# boss molto piu' veloce: agisce piu' volte nello stesso round, e ogni volta con la mossa del ciclo successiva
	var s: Dictionary = _fresh("semaforo", 3)
	BattleState.boss(s)["spd"] = 600
	BattleFlow.start_round(s)
	var moves: Array = []
	var cycles: Array = []
	var guard: int = 0
	while guard < 40:
		guard += 1
		var e: Dictionary = BattleFlow.next(s)
		if bool(e.get("end", false)) or str(s["winner"]) != "":
			break
		if bool(e["boss"]) and not bool(e.get("greg", false)):
			moves.append(str(s["telegraph"]["move"]))
			cycles.append(int(s["cycle_index"]))
		_play(s, e)
	check(moves.size() >= 2, "boss veloce: piu' azioni nello stesso round (%d)" % moves.size())
	var inc: bool = true
	for i in range(1, cycles.size()):
		if int(cycles[i]) != int(cycles[i - 1]) + 1:
			inc = false
	check(inc, "ogni azione del boss nello stesso round usa la mossa successiva del ciclo (%s)" % str(cycles))
	# boss lentissimo: un round senza la sua azione non gli fa saltare la mossa annunciata
	var w: Dictionary = _fresh("semaforo", 4)
	BattleState.boss(w)["spd"] = 10
	BattleFlow.start_round(w)
	var tele: String = str(w["telegraph"]["move"])
	var cyc: int = int(w["cycle_index"])
	var acted: bool = false
	while true:
		var e2: Dictionary = BattleFlow.next(w)
		if bool(e2.get("end", false)):
			break
		if bool(e2["boss"]):
			acted = true
		_play(w, e2)
	check(not acted, "boss lentissimo: nel primo round non agisce")
	# dopo un'azione del boss la mossa successiva e' gia' annunciata (gli eroi la vedono prima che arrivi)
	var x: Dictionary = _fresh("semaforo", 12)
	BattleFlow.start_round(x)
	var c0: int = int(x["cycle_index"])
	var g2: int = 0
	while g2 < 20:
		g2 += 1
		var e3: Dictionary = BattleFlow.next(x)
		if bool(e3.get("end", false)):
			break
		_play(x, e3)
		if bool(e3["boss"]) and not bool(e3.get("greg", false)):
			check(int(x["cycle_index"]) == c0 + 1 and str(x["telegraph"]["move"]) != "", "subito dopo l'azione del boss c'e' gia' la sua prossima mossa")
			break
	BattleFlow.finish(w)
	BattleFlow.start_round(w)
	check(str(w["telegraph"]["move"]) == tele and int(w["cycle_index"]) == cyc, "la mossa annunciata resta la stessa finche' il boss non agisce")


func _ko_consuma() -> void:
	var s: Dictionary = _fresh("semaforo", 5)
	var lance: String = _pid(s, "ferri")
	BattleState.active_unit(s, lance)["hp"] = 0
	BattleFlow.start_round(s)
	var seen: bool = false
	var guard: int = 0
	while guard < 40:
		guard += 1
		var e: Dictionary = BattleFlow.next(s)
		if bool(e.get("end", false)):
			break
		if not bool(e["boss"]) and str(e["player"]) == lance:
			seen = true
		_play(s, e)
	check(not seen, "un eroe KO non riceve il turno")
	check(bool(s["tl"]["done"].get(lance, false)), "ma il suo turno ordinario risulta consumato (4.1)")
	check(int(s["tl"]["slots"][lance]["at"]) > 0, "e resta nella Timeline per il giro dopo")


func _pareggi() -> void:
	# stessa VEL per tutti gli eroi: il primo giro segue l'id dell'unita'; poi vince chi era programmato prima. Nessun caso.
	var a: Dictionary = _fresh("semaforo", 6)
	var b: Dictionary = _fresh("semaforo", 7)
	for ch in ["ferri", "nox", "zecca", "saul"]:
		_set_spd(a, ch, 100)
		_set_spd(b, ch, 100)
	BattleState.boss(a)["spd"] = 100
	BattleState.boss(b)["spd"] = 100
	BattleFlow.start_round(a)
	BattleFlow.start_round(b)
	var la: Array = []
	var lb: Array = []
	for i in 12:
		var ea: Dictionary = BattleFlow.next(a)
		var eb: Dictionary = BattleFlow.next(b)
		if bool(ea.get("end", false)) or bool(eb.get("end", false)):
			break
		la.append(str(ea["unit"]))
		lb.append(str(eb["unit"]))
		_play(a, ea)
		_play(b, eb)
	check(la == lb, "pareggi: semi diversi, stesso ordine (%s)" % str(la))
	var ids: Array = la.slice(0, 5)
	var sorted_ids: Array = ids.duplicate()
	sorted_ids.sort()
	check(ids == sorted_ids, "pareggio al primo giro: ordine per id come il 0.52 (%s)" % str(ids))


func _anticipo_ritardo() -> void:
	var s: Dictionary = _fresh("semaforo", 8)
	BattleFlow.start_round(s)
	var tl: Dictionary = s["tl"]
	var k: String = "boss"
	var rem: int = int(tl["slots"][k]["at"]) - int(tl["now"])
	BattleFlow.shift(s, k, "anticipo", "leggero")
	check(int(tl["slots"][k]["at"]) - int(tl["now"]) == int(round(rem * 0.85)), "ANTICIPO leggero: −15% del tempo rimanente")
	BattleFlow.shift(s, k, "anticipo", "forte")
	check(int(tl["slots"][k]["at"]) - int(tl["now"]) == int(round(rem * 0.75)), "ANTICIPO forte dopo leggero: vale il piu' forte (−25%), non −40%")
	var ev: Dictionary = BattleFlow.shift(s, k, "anticipo", "leggero")
	check(ev.is_empty() and int(tl["slots"][k]["at"]) - int(tl["now"]) == int(round(rem * 0.75)), "ANTICIPO leggero dopo forte: nessun effetto")
	BattleFlow.shift(s, k, "ritardo", "leggero")
	check(absi(int(tl["slots"][k]["at"]) - int(tl["now"]) - int(round(rem * 0.90))) <= 1, "ANTICIPO forte + RITARDO leggero: famiglie diverse, −25% +15%")
	# dopo l'azione i modificatori si azzerano
	var guard: int = 0
	while guard < 20:
		guard += 1
		var e: Dictionary = BattleFlow.next(s)
		if bool(e.get("end", false)):
			break
		var was_boss: bool = bool(e["boss"]) and not bool(e.get("greg", false))
		_play(s, e)
		if was_boss:
			break
	check(int(tl["slots"][k].get("a", 0)) == 0 and int(tl["slots"][k].get("r", 0)) == 0, "dopo l'azione ANTICIPO e RITARDO si azzerano")


func _interruzione() -> void:
	var s: Dictionary = _fresh("semaforo", 9)
	BattleFlow.start_round(s)
	var tl: Dictionary = s["tl"]
	var e: Dictionary = BattleFlow.next(s)
	_play(s, e)
	var spd: int = int(BattleFlow._spd_of(s, tl["slots"]["boss"]))
	var ev: Dictionary = BattleFlow.interrupt(s, "boss", 120)
	check(int(ev.get("to", -1)) == BattleFlow.delta_t(60, spd), "INTERRUZIONE: rientra col 50%% del costo interrotto (%d)" % int(ev.get("to", -1)))
	check(bool(tl["tele_used"]), "INTERRUZIONE: la mossa annunciata e' persa, la prossima azione ne annuncia una nuova")


func _slancio_costo() -> void:
	var s: Dictionary = _fresh("semaforo", 10)
	BattleFlow.start_round(s)
	var tl: Dictionary = s["tl"]
	var e: Dictionary = BattleFlow.next(s)
	while bool(e["boss"]):
		_play(s, e)
		e = BattleFlow.next(s)
	var pid: String = str(e["player"])
	s["seq"]["slancio"] = true          # niente SLANCIO vero da questo colpo: lo si mette a mano
	BattleFlow.player_action(s, pid, _attack())
	var at0: int = int(tl["slots"][pid]["at"])
	(tl["quick"] as Array).append({"unit": str(e["unit"]), "player": pid, "boss": false, "spd": -1, "extra": true, "quick": true, "slancio": true})
	var q: Dictionary = BattleFlow.next(s)
	check(bool(q.get("quick", false)) and str(q["player"]) == pid, "SLANCIO: l'azione rapida e' subito dopo, dello stesso eroe")
	BattleFlow.player_action(s, pid, _attack(), true)
	check(int(tl["slots"][pid]["at"]) == at0 + 1500, "SLANCIO: +15 sul recupero gia' fissato (%d -> %d)" % [at0, int(tl["slots"][pid]["at"])])
	check(bool(tl["done"].get(pid, false)), "SLANCIO non conta come turno ordinario in piu' (il turno era gia' fatto)")


func _ingresso() -> void:
	for ing in ["vantaggio", "agguato"]:
		var s: Dictionary = _fresh("semaforo", 11, "frammento_blu")
		BattleFlow.start_round(s, ing)
		var first: Dictionary = BattleFlow.next(s)
		if ing == "agguato":
			check(bool(first["boss"]), "agguato: i nemici agiscono per primi")
		else:
			var heroes: int = 0
			var e: Dictionary = first
			while not bool(e.get("end", false)) and not bool(e["boss"]):
				if not bool(e.get("quick", false)):
					heroes += 1
				_play(s, e)
				e = BattleFlow.next(s)
			check(heroes == 4, "vantaggio: prima tutti e quattro gli eroi (%d)" % heroes)


func _scontri_interi() -> void:
	var n: int = 0
	var wins: int = 0
	var doubles: int = 0
	for boss in ["semaforo", "cabina", "manichino", "cassaforte", "autovelox", "distributore"]:
		for greg in ["", "frammento_blu"]:
			for sd in [1, 2, 3]:
				var a: Array = _auto(_fresh(boss, sd, greg))
				var b: Array = _auto(_fresh(boss, sd, greg))
				n += 1
				check(JSON.stringify(a[0]) == JSON.stringify(b[0]), "stesso seme, stessi eventi: %s %s %d" % [boss, greg, sd])
				check(str(a[1]) != "", "lo scontro finisce: %s %s %d" % [boss, greg, sd])
				check(bool(a[3]), "ogni round: tutti gli slot hanno fatto il turno prima della fine (%s %s %d)" % [boss, greg, sd])
				if str(a[1]) == "p1" or str(a[1]) == "player" or str(a[1]) == "players":
					wins += 1
				doubles += int(a[2])
	print("timeline: %d scontri in AUTO ripetibili; round con un nemico che agisce due volte: %d" % [n, doubles])


# Scontro intero in AUTO: [eventi, vincitore, round con un nemico che agisce 2+ volte, invariante del round]
func _auto(s: Dictionary) -> Array:
	var log: Array = []
	var doubles: int = 0
	var inv: bool = true
	var guard: int = 0
	var first: bool = true
	while str(s["winner"]) == "" and guard < 80:
		guard += 1
		BattleFlow.start_round(s, "")
		first = false
		var boss_n: int = 0
		while true:
			var e: Dictionary = BattleFlow.next(s)
			if str(s["winner"]) != "":
				return [log, s["winner"], doubles, inv]
			if bool(e.get("end", false)):
				for p in s["players"]:
					if not bool(s["tl"]["done"].get(str(p["id"]), false)):
						inv = false
				log.append_array(BattleFlow.finish(s))
				break
			if bool(e["boss"]) and not bool(e.get("greg", false)):
				boss_n += 1
				if boss_n == 2:
					doubles += 1
			if bool(e.get("greg", false)):
				log.append_array(BattleFlow.boss_action(s, Gregario.ID))
			elif bool(e["boss"]):
				log.append_array(BattleFlow.boss_action(s))
			else:
				var pid: String = str(e["player"])
				var quick: bool = bool(e.get("quick", false))
				log.append_array(BattleFlow.player_action(s, pid, BattleAI.choose_quick(s, pid) if quick else BattleAI.choose(s, pid), quick))
	return [log, s["winner"], doubles, inv]


func _init() -> void:
	BattleFlow.timeline = true
	_formula()
	_ordine_iniziale()
	_doppio_turno()
	_boss_due_volte()
	_ko_consuma()
	_pareggi()
	_anticipo_ritardo()
	_interruzione()
	_slancio_costo()
	_ingresso()
	_scontri_interi()
	if fails == 0:
		print("test_v3_timeline: OK")
	else:
		print("test_v3_timeline: %d FALLITI" % fails)
	quit(1 if fails > 0 else 0)
