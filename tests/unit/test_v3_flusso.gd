extends SceneTree

# FASE 0 DEL COMBATTIMENTO: il giro dei turni passa dalla battaglia (battle3d._advance) al motore (BattleFlow).
# Le regole non devono cambiare: qui si gioca lo stesso scontro (AUTO, stesso seme) col giro VECCHIO (ricopiato sotto
# da battle3d 0.52) e col giro NUOVO, e gli eventi devono essere identici. Piu' i casi singoli: vantaggio/agguato,
# azione rapida dello SLANCIO subito dopo, turno saltato da chi ha dato il turno alla tecnica a due.
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


func _fresh(boss: String, seed_value: int, greg: String) -> Dictionary:
	var s: Dictionary = BattleState.create_solo("IO", _team(), [], boss, seed_value)
	if greg != "":
		Gregario.add(s, greg)
	return s


# Il giro della 0.52, ricopiato da battle3d._start_round/_advance/_do_action (con AUTO acceso)
func _old_battle(b: Dictionary, ingresso: String) -> Array:
	var log: Array = []
	var first: bool = true
	var guard: int = 0
	while str(b["winner"]) == "" and guard < 60:
		guard += 1
		SeqRound.begin(b)
		var turn_list: Array = SeqRound.order(b)
		if first:
			first = false
			var boss_e: Array = turn_list.filter(func(e: Dictionary) -> bool: return bool(e["boss"]))
			var rest: Array = turn_list.filter(func(e: Dictionary) -> bool: return not bool(e["boss"]))
			if ingresso == "vantaggio":
				turn_list = rest + boss_e
			elif ingresso == "agguato":
				turn_list = boss_e + rest
		var turn_i: int = -1
		while true:
			turn_i += 1
			if str(b["winner"]) != "":
				return log
			if turn_i >= turn_list.size():
				log.append_array(SeqRound.finish(b))
				break
			var e: Dictionary = turn_list[turn_i]
			if bool(e.get("greg", false)):
				log.append_array(SeqRound.boss_action(b, Gregario.ID))
				continue
			if bool(e["boss"]):
				log.append_array(SeqRound.boss_action(b))
				continue
			var pid: String = str(e["player"])
			var pl: Dictionary = BattleState.player(b, pid)
			if pl.is_empty() or not BattleState.player_alive(b, pl):
				continue
			if not bool(e.get("quick", false)) and DuoTechs.spent(b, str(BattleState.active_unit(b, pid).get("id", ""))):
				continue
			var quick: bool = bool(e.get("quick", false))
			var ev: Array = SeqRound.player_action(b, pid, BattleAI.choose_quick(b, pid) if quick else BattleAI.choose(b, pid), quick)
			log.append_array(ev)
			for x in ev:
				if str(x.get("t", "")) == "slancio":
					turn_list.insert(turn_i + 1, {"unit": str(x["unit"]), "player": str(x["player"]), "boss": false, "spd": -1, "extra": true, "quick": true})
	return log


# Lo stesso scontro col giro nel motore
func _new_battle(b: Dictionary, ingresso: String) -> Array:
	var log: Array = []
	var first: bool = true
	var guard: int = 0
	while str(b["winner"]) == "" and guard < 60:
		guard += 1
		BattleFlow.start_round(b, ingresso if first else "")
		first = false
		while true:
			var e: Dictionary = BattleFlow.next(b)
			if str(b["winner"]) != "":
				return log
			if bool(e.get("end", false)):
				log.append_array(SeqRound.finish(b))
				break
			if bool(e.get("greg", false)):
				log.append_array(SeqRound.boss_action(b, Gregario.ID))
			elif bool(e["boss"]):
				log.append_array(SeqRound.boss_action(b))
			else:
				var pid: String = str(e["player"])
				var quick: bool = bool(e.get("quick", false))
				log.append_array(BattleFlow.player_action(b, pid, BattleAI.choose_quick(b, pid) if quick else BattleAI.choose(b, pid), quick))
	return log


func _same_battle() -> void:
	var cases: int = 0
	var slanci: int = 0
	var duo: int = 0
	for boss in ["semaforo", "cabina", "manichino", "cassaforte", "autovelox", "distributore"]:
		for greg in ["", "frammento_blu"]:
			for ing in ["normale", "vantaggio", "agguato"]:
				for sd in [1, 2, 3, 4, 5]:
					var a: Dictionary = _fresh(boss, sd, greg)
					var c: Dictionary = _fresh(boss, sd, greg)
					var la: Array = _old_battle(a, ing)
					var lc: Array = _new_battle(c, ing)
					cases += 1
					for x in la:
						if str(x.get("t", "")) == "slancio":
							slanci += 1
						if str(x.get("t", "")) == "duo_rest" or str(x.get("t", "")).begins_with("duo"):
							duo += 1
					var same: bool = JSON.stringify(la) == JSON.stringify(lc) and str(a["winner"]) == str(c["winner"]) and int(a["round"]) == int(c["round"])
					check(same, "stessi eventi col giro vecchio e nuovo: %s %s %s seme %d" % [boss, greg, ing, sd])
	check(cases == 180, "casi provati: %d" % cases)
	check(slanci > 0, "nelle prove c'e' almeno uno SLANCIO (%d)" % slanci)
	print("giro vecchio = giro nuovo su %d scontri (SLANCI visti: %d, eventi di tecniche a due: %d)" % [cases, slanci, duo])


func _ingresso() -> void:
	for ing in ["vantaggio", "agguato"]:
		var b: Dictionary = _fresh("semaforo", 3, "frammento_blu")
		BattleFlow.start_round(b, ing)
		var l: Array = BattleFlow.turns(b)
		var foes_last: bool = bool(l[l.size() - 1]["boss"]) and bool(l[l.size() - 2]["boss"])
		var foes_first: bool = bool(l[0]["boss"]) and bool(l[1]["boss"])
		check(foes_last if ing == "vantaggio" else foes_first, "ingresso %s: nemici %s" % [ing, "per ultimi" if ing == "vantaggio" else "per primi"])
	var n: Dictionary = _fresh("semaforo", 3, "")
	BattleFlow.start_round(n)
	check(JSON.stringify(BattleFlow.turns(n)) == JSON.stringify(SeqRound.order(n)), "senza ingresso: l'ordine e' quello per velocita'")
	check(BattleFlow.index(n) == -1, "prima del primo turno l'indice e' -1")


func _slancio_e_duo() -> void:
	# SLANCIO: l'azione rapida entra subito dopo nella lista
	var b: Dictionary = _fresh("semaforo", 1, "")
	BattleFlow.start_round(b)
	var before: int = BattleFlow.turns(b).size()
	var e: Dictionary = BattleFlow.next(b)
	while bool(e.get("boss", false)):
		SeqRound.boss_action(b)
		e = BattleFlow.next(b)
	b["seq"]["slancio"] = false
	var ev: Array = BattleFlow.player_action(b, str(e["player"]), {"swap": "", "move": BattleTypes.ACTION_ATTACK, "target": ""})
	var got: bool = false
	for x in ev:
		if str(x.get("t", "")) == "slancio":
			got = true
	if got:
		var nx: Dictionary = BattleFlow.next(b)
		check(bool(nx.get("quick", false)) and str(nx["player"]) == str(e["player"]), "SLANCIO: l'azione rapida e' il turno subito dopo, dello stesso eroe")
		check(BattleFlow.turns(b).size() == before + 1, "SLANCIO: una voce in piu' nella lista")
	else:
		check(BattleFlow.turns(b).size() == before, "senza SLANCIO la lista non cambia")
	# turno vuoto: chi e' caduto viene saltato
	var k: Dictionary = _fresh("semaforo", 2, "")
	BattleFlow.start_round(k)
	var first_hero: String = ""
	for t in BattleFlow.turns(k):
		if not bool(t["boss"]):
			first_hero = str(t["player"])
			break
	BattleState.active_unit(k, first_hero)["hp"] = 0
	var seen: bool = false
	while true:
		var t2: Dictionary = BattleFlow.next(k)
		if bool(t2.get("end", false)):
			break
		if not bool(t2["boss"]) and str(t2["player"]) == first_hero:
			seen = true
		if bool(t2["boss"]):
			continue
	check(not seen, "chi e' caduto non riceve il turno")


func _init() -> void:
	BattleFlow.timeline = false      # Fase 1: la prova di equivalenza riguarda il giro a round (la Timeline ha test_v3_timeline)
	_same_battle()
	_ingresso()
	_slancio_e_duo()
	if fails == 0:
		print("test_v3_flusso: OK")
	else:
		print("test_v3_flusso: %d FALLITI" % fails)
	quit(1 if fails > 0 else 0)
