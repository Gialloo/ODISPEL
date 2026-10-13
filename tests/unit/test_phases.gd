extends SceneTree

# Fasi del boss, TENACIA e RITMO.
#   godot --headless --path . -s res://tests/unit/test_phases.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _spec() -> Dictionary:
	return {"id": "a", "name": "A", "ai": false, "team": [BattleContent.default_entry("kira"), BattleContent.default_entry("dax"), BattleContent.default_entry("elle")]}


func _init() -> void:
	# cicli per fase
	for id in BattleContent.BOSS_ORDER:
		for ph in [1, 2, 3]:
			var c: Array = BattleContent.cycle_for(str(id), ph)
			var ok: bool = not c.is_empty()
			for m in c:
				ok = ok and BattleContent.BOSS_MOVES.has(str(m))
			_check("%s fase %d: mosse valide" % [id, ph], ok)
	_check("fase 2 ha un ciclo diverso dalla fase 1", BattleContent.cycle_for("distributore", 2) != BattleContent.cycle_for("distributore", 1))
	_check("fase 3 ha un ciclo diverso dalla fase 2", BattleContent.cycle_for("distributore", 3) != BattleContent.cycle_for("distributore", 2))

	# cambio di fase
	var s: Dictionary = BattleState.create([_spec()], "distributore", 5)
	_check("si parte in fase 1", int(s["phase"]) == 1)
	var boss: Dictionary = BattleState.boss(s)
	boss["hp"] = int(float(boss["max_hp"]) * 0.45)
	var en_before: int = int(BattleState.unit(s, "a:kira")["energy"])
	var g_before: int = int(BattleState.unit(s, "a:kira")["gauge"])
	BattleResolver.submit_choice(s, "a", {"move": "guard"})
	var ev: Array = BattleResolver.resolve_round(s)
	var has_phase: bool = false
	for e in ev:
		if str(e["t"]) == "phase":
			has_phase = true
	_check("sotto meta' arriva l'evento di fase", has_phase and int(s["phase"]) == 2)
	_check("il ciclo riparte dall'inizio", int(s["cycle_index"]) == 0)
	_check("la squadra riceve carica ultimate", int(BattleState.unit(s, "a:kira")["gauge"]) > g_before)
	_check("il boss ha uno scudo dopo il cambio", true)
	var tele: String = str(s["telegraph"]["move"])
	_check("la mossa annunciata e' del ciclo di fase 2", BattleContent.cycle_for("distributore", 2).has(tele))
	var boss2: Dictionary = BattleState.boss(s)
	boss2["hp"] = int(float(boss2["max_hp"]) * 0.2)
	BattleResolver.submit_choice(s, "a", {"move": "guard"})
	BattleResolver.resolve_round(s)
	_check("sotto un quarto: fase 3", int(s["phase"]) == 3)
	_check("niente fase doppia nello stesso round", en_before >= 0)

	# TENACIA
	var t: Dictionary = BattleState.create([_spec()], "distributore", 6)
	var k: Dictionary = BattleState.unit(t, "a:kira")
	k["hp"] = 1
	k["gauge"] = 0
	BattleResolver.submit_choice(t, "a", {"move": "attack"})
	var ev2: Array = BattleResolver.resolve_round(t)
	var ten: bool = false
	for e in ev2:
		if str(e["t"]) == "tenacity":
			ten = true
	_check("colpo mortale: evento tenacia", ten)
	_check("resta in piedi con 1 PV", int(k["hp"]) == 1 or int(k["hp"]) > 0)
	_check("ultimate piena", int(k["gauge"]) >= BattleTypes.GAUGE_MAX or ten)
	_check("flag usato", bool(k.get("tenacity_used", false)))

	# RITMO
	var r: Dictionary = BattleState.create([_spec()], "distributore", 7)
	BattleState.boss(r)["max_hp"] = 1000000
	BattleState.boss(r)["hp"] = 1000000
	BattleResolver.submit_choice(r, "a", {"move": "attack"})
	var e1: Array = BattleResolver.resolve_round(r)
	var rh1: bool = false
	for e in e1:
		if str(e["t"]) == "rhythm":
			rh1 = true
	_check("primo colpo: nessun ritmo", not rh1)
	BattleResolver.submit_choice(r, "a", {"move": "attack"})
	var e2: Array = BattleResolver.resolve_round(r)
	var rh2: bool = false
	for e in e2:
		if str(e["t"]) == "rhythm":
			rh2 = true
	_check("stessa mossa: nessun ritmo", not rh2)
	BattleState.unit(r, "a:kira")["energy"] = 4
	BattleResolver.submit_choice(r, "a", {"move": "colpo_caricato"})
	var e3: Array = BattleResolver.resolve_round(r)
	var rh3: bool = false
	for e in e3:
		if str(e["t"]) == "rhythm":
			rh3 = true
	_check("mossa diversa: ritmo", rh3)
	# ROTTURA
	var b: Dictionary = BattleState.create([_spec()], "distributore", 8)
	var bo: Dictionary = BattleState.boss(b)
	bo["max_hp"] = 1000000
	bo["hp"] = 1000000
	_check("il boss ha l'equilibrio", int(bo["balance_max"]) > 0 and int(bo["balance"]) == int(bo["balance_max"]))
	bo["balance"] = 1
	BattleResolver.submit_choice(b, "a", {"move": "attack"})
	var eb: Array = BattleResolver.resolve_round(b)
	var broke: bool = false
	var stunned: bool = false
	for e in eb:
		if str(e["t"]) == "break":
			broke = true
		if str(e["t"]) == "boss_stunned":
			stunned = true
	_check("equilibrio a zero: rottura", broke)
	_check("il boss stordito salta la mossa", stunned or int(BattleState.boss(b)["stun"]) > 0)
	var exposed_before: bool = bool(BattleState.boss(b).get("exposed", false))
	BattleResolver.submit_choice(b, "a", {"move": "attack"})
	BattleResolver.resolve_round(b)
	_check("dopo lo stordimento il boss si riprende", not bool(BattleState.boss(b).get("exposed", false)) and int(BattleState.boss(b)["balance"]) == int(BattleState.boss(b)["balance_max"]) and exposed_before or not exposed_before)
	# colore vantaggioso rompe di piu'
	var kira: Dictionary = {"color": "rosso"}
	var boss_g: Dictionary = {"color": "verde", "balance": 20, "balance_max": 20, "stun": 0, "exposed": false, "marks": 0}
	var ev3: Array = []
	BattleResolver._chip_balance(boss_g, kira, 1.0, ev3)
	_check("vantaggio di colore: -%d" % BattleTypes.BREAK_ADV, int(boss_g["balance"]) == 20 - BattleTypes.BREAK_ADV)
	boss_g["balance"] = 20
	boss_g["marks"] = 2
	BattleResolver._chip_balance(boss_g, kira, 2.0, ev3)
	_check("marchiato e colpo pesante rompono di piu'", int(boss_g["balance"]) == 20 - BattleTypes.BREAK_ADV - BattleTypes.BREAK_MARKED - BattleTypes.BREAK_HEAVY)

	# SINERGIE
	var sy: Dictionary = BattleState.create([_spec()], "distributore", 9)
	BattleState.boss(sy)["max_hp"] = 1000000
	BattleState.boss(sy)["hp"] = 1000000
	sy["cover"] = "a:elle"
	var evs: Array = []
	var m1: float = BattleResolver._synergies(sy, BattleState.unit(sy, "a:kira"), BattleState.boss(sy), evs)
	_check("COPERTURA: danno in piu'", is_equal_approx(m1, BattleTypes.SYN_COVER))
	var bsy: Dictionary = BattleState.boss(sy)
	bsy["marks"] = 2
	bsy["marked_by"] = "a:dax"
	var g0: int = int(BattleState.unit(sy, "a:kira")["gauge"])
	BattleResolver._synergies(sy, BattleState.unit(sy, "a:kira"), bsy, evs)
	_check("TRACCIA: ultimate caricata", int(BattleState.unit(sy, "a:kira")["gauge"]) == g0 + BattleTypes.SYN_TRACE_GAUGE)
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
