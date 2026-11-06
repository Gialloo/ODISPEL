extends SceneTree

# FASE 2 DEL COMBATTIMENTO: SLANCIO PER PERSONAGGIO (handoff 5, Slancio in slancio.gd).
# Si prova: uno SLANCIO per eroe per round (piu' eroi nello stesso round), mai due per lo stesso eroe, ripristino a round nuovo,
# secondo punto debole e Scheggia, l'azione rapida non ne genera un altro, KO e rianimazione conservano lo stato,
# SLANCIO protetto (si conserva, uno solo, toglie il +15 una volta, decade se il bersaglio cade) e scontri interi ripetibili.
var fails: int = 0


func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _team() -> Array:
	var t: Array = []
	for id in ["lance", "nox", "rio", "saul"]:
		t.append(BattleContent.default_entry(id))
	return t


func _fresh(boss: String, seed_value: int, greg: String = "") -> Dictionary:
	var s: Dictionary = BattleState.create_solo("IO", _team(), [], boss, seed_value)
	if greg != "":
		Gregario.add(s, greg)
	return s


func _units(s: Dictionary) -> Array:
	var out: Array = []
	for p in s["players"]:
		out.append(BattleState.active_unit(s, str(p["id"])))
	return out


# Un colpo finto di `u` su `dst` (il danno vero non serve: Slancio legge gli eventi)
func _hit(s: Dictionary, u: Dictionary, dst: String) -> Array:
	var ev: Array = [{"t": "damage", "src": str(u["id"]), "dst": dst, "amount": 10}]
	Slancio.check(s, u, ev)
	return ev


func _count(ev: Array, t: String) -> int:
	var n: int = 0
	for x in ev:
		if str(x.get("t", "")) == t:
			n += 1
	return n


func _per_eroe() -> void:
	var s: Dictionary = _fresh("semaforo", 1)
	BattleFlow.start_round(s)
	var boss: Dictionary = BattleState.boss(s)
	boss["color"] = "verde"
	var us: Array = _units(s)
	for u in us:
		u["color"] = "rosso"           # rosso batte verde
	var got: int = 0
	for u in us:
		got += _count(_hit(s, u, BattleState.BOSS_ID), "slancio")
	check(got == 4, "uno SLANCIO per ognuno dei quattro eroi nello stesso round (%d)" % got)
	check(_count(_hit(s, us[0], BattleState.BOSS_ID), "slancio") == 0, "lo stesso eroe non ne prende un secondo nello stesso round")
	var ev: Array = [{"t": "damage", "src": str(us[0]["id"]), "dst": BattleState.BOSS_ID, "amount": 10}]
	check(_count(ev, "slancio") == 0, "colpo senza Slancio.check: niente evento")
	# il dato del round sta in seq: un round nuovo lo ripristina
	BattleFlow.finish(s)
	BattleFlow.start_round(s)
	check(_count(_hit(s, us[0], BattleState.BOSS_ID), "slancio") == 1, "a round nuovo lo SLANCIO torna disponibile")
	# niente debolezza = niente SLANCIO
	us[1]["color"] = "blu"
	check(_count(_hit(s, us[1], BattleState.BOSS_ID), "slancio") == 0, "colore non vincente: niente SLANCIO")
	# il perche' per la UI
	var e2: Array = _hit(s, us[2], BattleState.BOSS_ID)
	check(e2.size() == 2 and str(e2[1].get("why", "")) == "colore" and str(e2[1].get("dst", "")) == BattleState.BOSS_ID, "l'evento dice perche' (colore) e su chi")


func _weak2_e_scheggia() -> void:
	var s: Dictionary = _fresh("autovelox", 2, "frammento_giallo")
	BattleFlow.start_round(s)
	var boss: Dictionary = BattleState.boss(s)
	var us: Array = _units(s)
	# secondo punto debole del boss (Autovelox: weak2 blu, colore giallo)
	us[0]["color"] = str(boss["weak2"])
	var ev: Array = _hit(s, us[0], BattleState.BOSS_ID)
	check(_count(ev, "slancio") == 1 and str(ev[1].get("why", "")) == "weak2", "il secondo punto debole da' SLANCIO (why = weak2)")
	# debolezza della Scheggia
	var g: Dictionary = Gregario.unit(s)
	check(not g.is_empty(), "la Scheggia c'e'")
	us[1]["color"] = ""
	for c in BattleTypes.BEATS:
		if BattleTypes.color_multiplier(str(c), str(g["color"])) > 1.0:
			us[1]["color"] = str(c)
	check(_count(_hit(s, us[1], Gregario.ID), "slancio") == 1, "la debolezza della Scheggia da' SLANCIO (colore %s)" % str(us[1]["color"]))


func _rapida_e_ko() -> void:
	var s: Dictionary = _fresh("semaforo", 3)
	BattleFlow.start_round(s)
	var boss: Dictionary = BattleState.boss(s)
	boss["color"] = "verde"
	var us: Array = _units(s)
	for u in us:
		u["color"] = "rosso"
	# l'azione rapida non genera un altro SLANCIO (SeqRound chiama Slancio.check solo se non quick)
	var pid0: String = BattleState.slot_of(s, str(us[0]["id"]))
	var ev: Array = SeqRound.player_action(s, pid0, {"swap": "", "move": BattleTypes.ACTION_ATTACK, "target": ""}, true)
	check(_count(ev, "slancio") == 0 and not Slancio.used(s, str(us[0]["id"])), "l'azione rapida non da' SLANCIO e non lo consuma")
	# KO e rianimazione: chi l'aveva usato resta usato, chi no resta disponibile
	_hit(s, us[1], BattleState.BOSS_ID)
	for i in [1, 2]:
		us[i]["hp"] = 0
	for i in [1, 2]:
		us[i]["hp"] = 10
	check(Slancio.used(s, str(us[1]["id"])), "KO e rianimazione: lo SLANCIO usato resta usato")
	check(_count(_hit(s, us[2], BattleState.BOSS_ID), "slancio") == 1, "KO e rianimazione: lo SLANCIO disponibile resta disponibile")
	# un eroe KO non prende SLANCIO
	us[3]["hp"] = 0
	check(_count(_hit(s, us[3], BattleState.BOSS_ID), "slancio") == 0, "un eroe KO non prende SLANCIO")


func _protetto() -> void:
	var s: Dictionary = _fresh("semaforo", 4)
	BattleFlow.start_round(s)
	var tl: Dictionary = s["tl"]
	var boss: Dictionary = BattleState.boss(s)
	boss["color"] = "verde"
	var us: Array = _units(s)
	for u in us:
		u["color"] = "rosso"
	var uid: String = str(us[0]["id"])
	var pid: String = BattleState.slot_of(s, uid)
	boss["invuln"] = 1                 # impedimento obbligatorio (la scheda boss della Fase 5 lo dichiarera')
	var ev: Array = _hit(s, us[0], BattleState.BOSS_ID)
	check(_count(ev, "slancio") == 0 and _count(ev, "slancio_kept") == 1, "bersaglio invulnerabile: lo SLANCIO si protegge")
	check(Slancio.ready_kept(s).is_empty(), "finche' il boss e' invulnerabile non si usa")
	# round nuovo, ancora invulnerabile: un altro colpo non ne accumula un secondo
	BattleFlow.finish(s)
	BattleFlow.start_round(s)
	ev = _hit(s, us[0], BattleState.BOSS_ID)
	check(_count(ev, "slancio_kept") == 0 and Slancio.kept(s).size() == 1, "al massimo uno SLANCIO protetto per eroe (attraversa il round)")
	# il protetto sopravvive al KO
	us[0]["hp"] = 0
	boss["invuln"] = 0
	check(Slancio.ready_kept(s).is_empty() and Slancio.kept(s).has(uid), "KO: lo SLANCIO protetto resta, ma non si usa da KO")
	us[0]["hp"] = 10
	# torna vulnerabile: la prossima voce e' l'azione rapida, senza +15 la prima volta
	var q: Dictionary = BattleFlow.next(s)
	check(bool(q.get("quick", false)) and bool(q.get("kept", false)) and str(q["player"]) == pid, "boss vulnerabile: subito l'azione rapida dello SLANCIO protetto")
	var at0: int = int(tl["slots"][pid]["at"])
	BattleFlow.player_action(s, pid, {"swap": "", "move": BattleTypes.ACTION_ATTACK, "target": ""}, true)
	check(int(tl["slots"][pid]["at"]) == at0, "la prima protezione toglie il +15 (%d -> %d)" % [at0, int(tl["slots"][pid]["at"])])
	check(Slancio.kept(s).is_empty(), "usato, lo SLANCIO protetto non c'e' piu'")
	# bersaglio sconfitto: decade
	var s2: Dictionary = _fresh("autovelox", 5, "frammento_giallo")
	BattleFlow.start_round(s2)
	var g: Dictionary = Gregario.unit(s2)
	var u2: Dictionary = _units(s2)[0]
	for c in BattleTypes.BEATS:
		if BattleTypes.color_multiplier(str(c), str(g["color"])) > 1.0:
			u2["color"] = str(c)
	g["invuln"] = 1
	_hit(s2, u2, Gregario.ID)
	check(Slancio.kept(s2).size() == 1, "protetto anche sulla Scheggia")
	g["hp"] = 0
	check(Slancio.ready_kept(s2).is_empty() and Slancio.kept(s2).is_empty(), "bersaglio sconfitto: lo SLANCIO protetto decade, non passa ad altri")


# Scontri interi in AUTO: stesso seme = stessi eventi; e nessun eroe ha due SLANCI nello stesso round
func _scontri() -> void:
	for boss_id in ["distributore", "cassaforte", "autovelox"]:
		var a: Array = _auto(boss_id, 77)
		var b: Array = _auto(boss_id, 77)
		check(a[0] == b[0], "%s: stesso seme, stessi eventi" % boss_id)
		check(int(a[1]) == 0, "%s: mai due SLANCI per lo stesso eroe in un round (%d)" % [boss_id, int(a[1])])


func _auto(boss_id: String, seed_value: int) -> Array:
	var s: Dictionary = _fresh(boss_id, seed_value)
	var log: Array = []
	var doppi: int = 0
	var rounds: int = 0
	while str(s["winner"]) == "" and rounds < 30:
		rounds += 1
		BattleFlow.start_round(s)
		var seen: Dictionary = {}
		var guard: int = 0
		while guard < 60 and str(s["winner"]) == "":
			guard += 1
			var e: Dictionary = BattleFlow.next(s)
			if bool(e.get("end", false)):
				break
			var ev: Array
			if bool(e.get("greg", false)):
				ev = BattleFlow.boss_action(s, Gregario.ID)
			elif bool(e["boss"]):
				ev = BattleFlow.boss_action(s)
			else:
				var pid: String = str(e["player"])
				var q: bool = bool(e.get("quick", false))
				ev = BattleFlow.player_action(s, pid, BattleAI.choose_quick(s, pid) if q else BattleAI.choose(s, pid), q)
			for x in ev:
				log.append(str(x.get("t", "")))
				if str(x.get("t", "")) == "slancio":
					if seen.has(str(x["unit"])):
						doppi += 1
					seen[str(x["unit"])] = true
		BattleFlow.finish(s)
	return [log, doppi]


func _init() -> void:
	BattleFlow.timeline = true
	_per_eroe()
	_weak2_e_scheggia()
	_rapida_e_ko()
	_protetto()
	_scontri()
	if fails == 0:
		print("test_v3_slancio: OK")
	else:
		print("test_v3_slancio: %d FALLITI" % fails)
	quit(1 if fails > 0 else 0)
