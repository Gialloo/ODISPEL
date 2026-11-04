extends SceneTree

# RITMO DI SQUADRA, fase R1 (Ritmo + BattleTypes.RITMO_*; handoff integrativo 2.1-2.8, 3.6, 5.1, 5.10).
# Si prova: Ardore e livello separati, soglia senza condizione che non fa salire, condizioni persistenti / di mantenimento /
# a finestra, nessun salto di livello, perdita senza discesa, discesa di piu' livelli, discesa diretta, livello tenuto,
# azzeramento, tetto ed eccedenza, anti-farming per round, cure utili, il +10% che non genera Ardore, KO, salvataggio JSON,
# e scontri interi in AUTO ripetibili. I numeri sono quelli di prova (soglie 25/50/75, tetto 100, margine 15).
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


func _fresh(boss: String = "semaforo", seed_value: int = 1) -> Dictionary:
	return BattleState.create_solo("IO", _team(), [], boss, seed_value)


func _hero(s: Dictionary, advantage: bool) -> Dictionary:
	var boss: Dictionary = BattleState.boss(s)
	for p in s["players"]:
		var u: Dictionary = BattleState.active_unit(s, str(p["id"]))
		if (BattleTypes.color_multiplier(str(u["color"]), str(boss["color"])) > 1.0) == advantage and not BattleTypes.hits_weak2(u, boss):
			return u
	return {}


func _heroes(s: Dictionary) -> Array:
	var out: Array = []
	for p in s["players"]:
		out.append(BattleState.active_unit(s, str(p["id"])))
	return out


func _feed(s: Dictionary, evs: Array) -> Array:
	Ritmo.after_events(s, evs)
	return evs


func _has(evs: Array, t: String) -> bool:
	for e in evs:
		if str(e.get("t", "")) == t:
			return true
	return false


func _put(s: Dictionary, ardore: int) -> void:
	Ritmo.st(s)["ardore"] = ardore


func _base() -> void:
	var s: Dictionary = _fresh()
	check(Ritmo.ardore(s) == 0 and Ritmo.level(s) == Ritmo.CALMO, "si parte da 0 Ardore e CALMO")
	check(Ritmo.threshold(Ritmo.ACCESO) == 25 and Ritmo.threshold(Ritmo.APICE) == 75, "soglie di prova 25/50/75")
	check(Ritmo.level_name(Ritmo.APICE) == "APICE", "nomi dei livelli")


func _soglia_senza_condizione() -> void:
	var s: Dictionary = _fresh()
	var ev: Array = []
	Ritmo.gain(s, 60, "prova", "", ev)
	_feed(s, ev)
	check(Ritmo.level(s) == Ritmo.CALMO, "soglia raggiunta senza condizione: resta CALMO")
	check(Ritmo.ardore(s) == 25 + BattleTypes.RITMO_MARGIN, "con l'avanzamento in attesa l'Ardore si ferma a soglia + margine (%d)" % Ritmo.ardore(s))
	check(_has(ev, "ritmo_ready") and bool(Ritmo.st(s)["ready"]), "evento di avanzamento disponibile")
	# la condizione arriva: sale da solo e l'Ardore resta
	var h: Dictionary = _hero(s, true)
	var boss: Dictionary = BattleState.boss(s)
	var ev2: Array = _feed(s, [{"t": "damage", "src": h["id"], "dst": boss["id"], "amount": 50}])
	check(Ritmo.level(s) == Ritmo.ACCESO, "colpo alla debolezza: CALMO -> ACCESO")
	check(Ritmo.ardore(s) >= 40, "l'Ardore accumulato si conserva alla salita")
	check(_has(ev2, "ritmo_level") and _has(ev2, "ritmo_cond"), "eventi di condizione e di livello")


func _alternativa() -> void:
	var s: Dictionary = _fresh()
	_put(s, 25)
	_feed(s, [{"t": "timed_guard", "unit": str(_heroes(s)[0]["id"]), "grade": "good"}])
	check(Ritmo.level(s) == Ritmo.ACCESO, "condizione alternativa (parata a tempo): sale anche senza debolezza")


func _nessun_salto() -> void:
	var s: Dictionary = _fresh()
	_put(s, 25)
	# una parata perfetta fa salire ad ACCESO, ma non vale gia' per APICE
	_feed(s, [{"t": "timed_guard", "unit": str(_heroes(s)[0]["id"]), "grade": "perfect"}])
	check(Ritmo.level(s) == Ritmo.ACCESO, "parata perfetta: ACCESO")
	check(not (Ritmo.st(s)["done"] as Dictionary).has("parata_perfetta"), "la condizione di APICE non si porta avanti da CALMO")
	# Ardore oltre due soglie: si sale di uno solo, poi servono le condizioni nuove
	_put(s, 80)
	_feed(s, [])
	check(Ritmo.level(s) == Ritmo.ACCESO, "Ardore alto ma nessuna condizione nuova: niente salto")
	var boss: Dictionary = BattleState.boss(s)
	_feed(s, [{"t": "break", "src": str(_heroes(s)[0]["id"])}])
	check(Ritmo.level(s) == Ritmo.INCANDESCENTE, "BREAK: ACCESO -> INCANDESCENTE (uno solo)")
	check(boss.has("id"), "boss presente")


func _persistente() -> void:
	var s: Dictionary = _fresh()
	Ritmo.st(s)["level"] = Ritmo.ACCESO
	_put(s, 30)
	_feed(s, [{"t": "break", "src": str(_heroes(s)[0]["id"])}])      # +15 = 45, condizione fatta, soglia 50 non ancora
	check(Ritmo.level(s) == Ritmo.ACCESO and (Ritmo.st(s)["done"] as Dictionary).has("break"), "condizione fatta prima della soglia")
	var ev: Array = []
	Ritmo.drain(s, 15, "prova", ev)                                    # 30: resta ACCESO
	check(Ritmo.level(s) == Ritmo.ACCESO and (Ritmo.st(s)["done"] as Dictionary).has("break"), "persistente: sopravvive alla perdita di Ardore")
	ev = []
	Ritmo.gain(s, 20, "prova", "", ev)
	_feed(s, ev)
	check(Ritmo.level(s) == Ritmo.INCANDESCENTE, "soglia raggiunta dopo: sale con la condizione gia' fatta")


func _mantenimento() -> void:
	var s: Dictionary = _fresh()
	var boss: Dictionary = BattleState.boss(s)
	Ritmo.st(s)["level"] = Ritmo.ACCESO
	_put(s, 50)
	boss["marks"] = 0
	_feed(s, [])
	check(Ritmo.level(s) == Ritmo.ACCESO, "mantenimento: senza marchio non sale")
	boss["marks"] = 2
	_feed(s, [])
	check(Ritmo.level(s) == Ritmo.INCANDESCENTE, "mantenimento: col boss marchiato sale")
	check(not (Ritmo.st(s)["done"] as Dictionary).has("marchio"), "il mantenimento non si ricorda come fatto")


func _finestra() -> void:
	var s: Dictionary = _fresh()
	var boss: Dictionary = BattleState.boss(s)
	var h: Dictionary = _hero(s, false)
	Ritmo.st(s)["level"] = Ritmo.INCANDESCENTE
	_put(s, 75)
	boss["exposed"] = false
	_feed(s, [{"t": "damage", "src": h["id"], "dst": boss["id"], "amount": 30}])
	check(Ritmo.level(s) == Ritmo.INCANDESCENTE, "finestra: colpo fuori dal BREAK non vale")
	boss["exposed"] = true
	_feed(s, [{"t": "damage", "src": h["id"], "dst": boss["id"], "amount": 30}])
	check(Ritmo.level(s) == Ritmo.APICE, "finestra: colpo durante il BREAK -> APICE")
	boss["exposed"] = false


func _perdite() -> void:
	var s: Dictionary = _fresh()
	Ritmo.st(s)["level"] = Ritmo.APICE
	_put(s, 90)
	var ev: Array = []
	Ritmo.drain(s, 10, "prova", ev)
	check(Ritmo.level(s) == Ritmo.APICE, "perdere Ardore sopra la soglia non toglie APICE")
	Ritmo.drain(s, 10, "prova", ev)
	check(Ritmo.level(s) == Ritmo.INCANDESCENTE, "sotto 75 APICE si perde (5.1)")
	Ritmo.st(s)["level"] = Ritmo.APICE
	_put(s, 80)
	Ritmo.drain(s, 60, "prova", ev)
	check(Ritmo.level(s) == Ritmo.CALMO and Ritmo.ardore(s) == 20, "una perdita grande attraversa piu' soglie (APICE -> CALMO)")
	Ritmo.st(s)["level"] = Ritmo.INCANDESCENTE
	_put(s, 60)
	Ritmo.drop_level(s, 1, "prova", ev)
	check(Ritmo.level(s) == Ritmo.ACCESO and Ritmo.ardore(s) == 60, "abbassare il livello lascia l'Ardore com'e'")
	Ritmo.drop_level(s, 5, "prova", ev)
	check(Ritmo.level(s) == Ritmo.CALMO, "non si scende sotto CALMO")


func _livello_tenuto() -> void:
	var s: Dictionary = _fresh()
	Ritmo.st(s)["level"] = Ritmo.APICE
	_put(s, 90)
	var ev: Array = []
	Ritmo.drain(s, 90, "prova", ev, true)
	check(Ritmo.ardore(s) == 0 and Ritmo.level(s) == Ritmo.APICE, "azzerare l'Ardore tenendo il livello (secondo l'effetto)")
	_feed(s, [])
	check(Ritmo.level(s) == Ritmo.APICE, "il livello tenuto resta finche' non arriva un guadagno")
	ev = []
	Ritmo.gain(s, 5, "prova", "", ev)
	_feed(s, ev)
	check(Ritmo.level(s) == Ritmo.CALMO, "al primo guadagno il livello si riallinea all'Ardore")


func _azzeramento() -> void:
	var s: Dictionary = _fresh()
	Ritmo.st(s)["level"] = Ritmo.INCANDESCENTE
	_put(s, 60)
	var ev: Array = []
	Ritmo.reset(s, "prova", ev)
	check(Ritmo.ardore(s) == 0 and Ritmo.level(s) == Ritmo.CALMO, "azzeramento totale: 0 e CALMO")
	check(_has(ev, "ritmo_level") and _has(ev, "ritmo_loss"), "eventi dell'azzeramento")


func _tetto() -> void:
	var s: Dictionary = _fresh()
	Ritmo.st(s)["level"] = Ritmo.APICE
	_put(s, 95)
	var ev: Array = []
	var got: int = Ritmo.gain(s, 20, "prova", "", ev)
	check(got == 5 and Ritmo.ardore(s) == 100 and int(ev[0]["wasted"]) == 15, "ad APICE l'eccedenza oltre il tetto si perde (5.10)")
	Ritmo.set_cap(s, 120, "taglia", ev)
	check(Ritmo.ardore(s) == 100, "alzare il tetto non da' Ardore (3.6)")
	Ritmo.set_cap(s, 90, "blocca", ev)
	check(Ritmo.ardore(s) == 100, "tetto giu' con «blocca»: il valore resta")
	check(Ritmo.gain(s, 5, "prova", "", ev) == 0, "tetto giu' con «blocca»: niente nuovi guadagni")
	Ritmo.set_cap(s, 80, "taglia", ev)
	check(Ritmo.ardore(s) == 80 and Ritmo.level(s) == Ritmo.APICE, "tetto giu' con «taglia»: eccedenza tolta subito")


func _anti_farming() -> void:
	var s: Dictionary = _fresh()
	var boss: Dictionary = BattleState.boss(s)
	var h: Dictionary = _hero(s, true)
	for i in 4:
		_feed(s, [{"t": "damage", "src": h["id"], "dst": boss["id"], "amount": 10}])
	check(Ritmo.ardore(s) == 2 * int(BattleTypes.RITMO_GAIN["debolezza"]), "la stessa fonte conta al massimo 2 volte per round (%d)" % Ritmo.ardore(s))
	s["round"] = int(s["round"]) + 1
	_feed(s, [{"t": "damage", "src": h["id"], "dst": boss["id"], "amount": 10}])
	check(Ritmo.ardore(s) == 3 * int(BattleTypes.RITMO_GAIN["debolezza"]), "al round nuovo la fonte riparte")
	# colpo senza debolezza: niente Ardore
	var s2: Dictionary = _fresh()
	_feed(s2, [{"t": "damage", "src": _hero(s2, false)["id"], "dst": BattleState.boss(s2)["id"], "amount": 10}])
	check(Ritmo.ardore(s2) == 0, "un colpo qualsiasi non genera Ardore")


func _cure() -> void:
	var s: Dictionary = _fresh()
	var u: Dictionary = _heroes(s)[1]
	u["hp"] = int(u["max_hp"])
	_feed(s, [{"t": "heal", "src": u["id"], "dst": u["id"], "amount": 50}])
	check(Ritmo.ardore(s) == 0, "una cura a chi sta bene non genera Ardore")
	u["hp"] = int(float(u["max_hp"]) * 0.5)
	_feed(s, [{"t": "heal", "src": u["id"], "dst": u["id"], "amount": int(float(u["max_hp"]) * 0.3)}])
	check(Ritmo.ardore(s) == int(BattleTypes.RITMO_GAIN["cura"]), "una cura che salva (era sotto il 40%%) genera Ardore")


func _ritmo_bonus_a_parte() -> void:
	var s: Dictionary = _fresh()
	_feed(s, [{"t": "rhythm", "unit": str(_heroes(s)[0]["id"]), "from": "attacco", "to": "guardia"}])
	check(Ritmo.ardore(s) == 0, "il +10% al cambio di categoria resta un bonus a parte (K2): niente Ardore")


func _ko() -> void:
	var s: Dictionary = _fresh()
	_put(s, 30)
	Ritmo.st(s)["level"] = Ritmo.ACCESO
	_feed(s, [{"t": "down", "unit": str(_heroes(s)[0]["id"])}])
	check(Ritmo.ardore(s) == 30 - BattleTypes.RITMO_LOSS_KO and Ritmo.level(s) == Ritmo.CALMO, "KO di un compagno: -10, sotto la soglia si scende")


func _collaborazione() -> void:
	var s: Dictionary = _fresh()
	Ritmo.st(s)["level"] = Ritmo.ACCESO
	_put(s, 30)
	var hs: Array = _heroes(s)
	for i in 3:
		var ev: Array = []
		Ritmo.gain(s, 3, "prova", str(hs[i]["id"]), ev)
		_feed(s, ev)
	check((Ritmo.st(s)["done"] as Dictionary).has("collaborazione"), "tre compagni diversi: condizione di collaborazione fatta")
	check(Ritmo.level(s) == Ritmo.ACCESO, "ma senza soglia non sale (39 < 50)")


func _salvataggio_json() -> void:
	var s: Dictionary = _fresh()
	Ritmo.st(s)["level"] = Ritmo.ACCESO
	_put(s, 33)
	var back: Dictionary = BattleState.from_json(BattleState.to_json(s))
	check(BattleState.validate(back) == "", "lo stato col RITMO resta un salvataggio valido")
	check(Ritmo.ardore(back) == 33 and Ritmo.level(back) == Ritmo.ACCESO, "Ardore e livello tornano uguali dal JSON")
	var old: Dictionary = _fresh()
	old.erase("ritmo")
	check(Ritmo.level(old) == Ritmo.CALMO, "un salvataggio di prima (senza RITMO) parte da CALMO")


func _auto(s: Dictionary) -> Array:
	var log: Array = []
	var guard: int = 0
	var top: int = 0
	while str(s["winner"]) == "" and guard < 80:
		guard += 1
		BattleFlow.start_round(s, "")
		while true:
			var e: Dictionary = BattleFlow.next(s)
			if str(s["winner"]) != "":
				break
			if bool(e.get("end", false)):
				log.append_array(BattleFlow.finish(s))
				break
			if bool(e.get("greg", false)):
				log.append_array(BattleFlow.boss_action(s, Gregario.ID))
			elif bool(e["boss"]):
				log.append_array(BattleFlow.boss_action(s))
			else:
				var pid: String = str(e["player"])
				var quick: bool = bool(e.get("quick", false))
				log.append_array(BattleFlow.player_action(s, pid, BattleAI.choose_quick(s, pid) if quick else BattleAI.choose(s, pid), quick))
			top = maxi(top, Ritmo.level(s))
	return [log, str(s["winner"]), top]


func _scontri_interi() -> void:
	var tops: Array = []
	for boss in ["semaforo", "cabina", "manichino", "cassaforte", "autovelox"]:
		var a: Array = _auto(_fresh(boss, 7))
		var b: Array = _auto(_fresh(boss, 7))
		check(JSON.stringify(a[0]) == JSON.stringify(b[0]), "%s: stesso seme = stessi eventi, RITMO compreso" % boss)
		var gains: int = 0
		for e in a[0]:
			if str(e.get("t", "")) == "ritmo_gain":
				gains += 1
		check(gains > 0, "%s: in uno scontro vero il RITMO si muove" % boss)
		tops.append("%s %s" % [boss, Ritmo.level_name(int(a[2]))])
	print("livello massimo raggiunto in AUTO (seme 7): " + ", ".join(tops))


func _init() -> void:
	BattleFlow.timeline = true
	_base()
	_soglia_senza_condizione()
	_alternativa()
	_nessun_salto()
	_persistente()
	_mantenimento()
	_finestra()
	_perdite()
	_livello_tenuto()
	_azzeramento()
	_tetto()
	_anti_farming()
	_cure()
	_ritmo_bonus_a_parte()
	_ko()
	_collaborazione()
	_salvataggio_json()
	_scontri_interi()
	if fails == 0:
		print("test_v3_ritmo: OK")
	else:
		print("test_v3_ritmo: %d FALLITI" % fails)
	quit(1 if fails > 0 else 0)
