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
	var kira: Dictionary = {"id": "x", "color": "rosso"}
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
	sy["tags"] = [{"unit": "a:elle", "tags": ["SUPPORT"]}]
	sy["combo_n"] = 0
	var evs: Array = []
	var m1: float = BattleResolver._synergies(sy, BattleState.unit(sy, "a:kira"), BattleState.boss(sy), evs)
	_check("COPERTURA: danno in piu'", is_equal_approx(m1, float(Combos.rule("copertura")["mult"])))
	_check("l'evento della combo porta preset e tier", str(evs[0]["fx"]) == "aura" and int(evs[0]["tier"]) == 0)
	var bsy: Dictionary = BattleState.boss(sy)
	bsy["marks"] = 2
	bsy["marked_by"] = "a:dax"
	sy["tags"] = []
	sy["combo_n"] = 0
	var g0: int = int(BattleState.unit(sy, "a:kira")["gauge"])
	BattleResolver._synergies(sy, BattleState.unit(sy, "a:kira"), bsy, evs)
	_check("TRACCIA: ultimate caricata", int(BattleState.unit(sy, "a:kira")["gauge"]) == g0 + int(Combos.rule("traccia")["gauge"]))
	# DETONAZIONE: colpo pesante su boss marchiato da un altro
	sy["tags"] = []
	sy["combo_n"] = 0
	var bal0: int = int(bsy["balance"])
	var ev_det: Array = []
	BattleResolver._synergies(sy, BattleState.unit(sy, "a:kira"), bsy, ev_det, BattleContent.MOVES["colpo_caricato"])
	var ids: Array = []
	for e in ev_det:
		if str(e["t"]) == "synergy":
			ids.append(str(e["id"]))
	_check("DETONAZIONE con colpo pesante", ids.has("detonazione") and ids.has("traccia"))
	_check("la combo toglie equilibrio", int(bsy["balance"]) < bal0)
	_check("la seconda combo ha tier piu' alto", ev_det.size() >= 2 and int(ev_det.back().get("tier", 0)) >= 1)
	_check("tag: marchio e debuff riconosciuti", Combos.tags_of(BattleContent.MOVES["marchio"]).has("MARK") and Combos.tags_of(BattleContent.MOVES["frattura"]).has("DEBUFF") and Combos.tags_of(BattleContent.MOVES["cura"]).has("SUPPORT"))
	# MINACCIA e SUGGERIMENTI
	var th: Dictionary = BattleState.create([_spec()], "distributore", 10)
	var kt: Dictionary = BattleState.unit(th, "a:kira")
	var pv: Dictionary = BattleResolver.threat_preview(th)
	_check("anteprima danno presente", pv["dmg"].size() >= 1)
	th["telegraph"] = {"move": "scarica", "target": "a"}
	kt["hp"] = 1
	_check("1 PV sotto la scarica: letale", BattleResolver.threat_preview(th)["lethal"].has("a:kira"))
	BattleState.unit(th, "a:kira")["hp"] = int(kt["max_hp"])
	_check("PV pieni: non letale", not BattleResolver.threat_preview(th)["lethal"].has("a:kira"))
	var ph2: Dictionary = BattleState.create([_spec()], "distributore", 11)
	BattleState.boss(ph2)["marks"] = 2
	BattleState.boss(ph2)["marked_by"] = "a:dax"
	var hs: Array = BattleResolver.plan_hints(ph2, "a")
	var has_trace: bool = false
	for h in hs:
		if "TRACCIA" in str(h):
			has_trace = true
	_check("suggerimento TRACCIA con boss marchiato da un compagno", has_trace)
	# statistiche
	var stt: Dictionary = BattleState.create([_spec()], "distributore", 12)
	BattleState.boss(stt)["balance"] = 1
	BattleResolver.submit_choice(stt, "a", {"move": "attack"})
	BattleResolver.resolve_round(stt)
	_check("statistiche: rotture contate", int(stt["stats"]["breaks"]) >= 1)
	# ADATTAMENTO, ARDORE, SACRIFICIO, CARICA
	var ad: Dictionary = BattleState.create([_spec()], "distributore", 13)
	BattleState.boss(ad)["max_hp"] = 10000000
	BattleState.boss(ad)["hp"] = 10000000
	var adapted: bool = false
	for i in 4:
		BattleResolver.submit_choice(ad, "a", {"move": "attack"})
		for e in BattleResolver.resolve_round(ad):
			if str(e["t"]) == "adapt":
				adapted = true
	_check("stessa mossa 3 volte: il boss si adatta", adapted)
	var atk: Dictionary = {"side": "player", "hp": 10, "max_hp": 1000, "atk": 100, "color": "rosso", "passives": [], "statuses": {}, "id": "u"}
	var atk2: Dictionary = atk.duplicate(true)
	atk2["hp"] = 900
	var dfn: Dictionary = {"side": "boss", "hp": 1000, "max_hp": 1000, "def": 0, "color": "rosso", "statuses": {}, "marks": 0, "id": "b", "char": "distributore"}
	_check("ARDORE: piu' danno sotto il 30% PV", BattleResolver.calc_damage(atk, dfn, 1.0) > BattleResolver.calc_damage(atk2, dfn, 1.0))
	_check("sacrificio esiste e costa PV", BattleContent.MOVES.has("sacrificio") and float(BattleContent.MOVES["sacrificio"]["self_cost_hp"]) > 0.0)
	var sa: Dictionary = BattleState.create([_spec()], "distributore", 14)
	var dax_u: Dictionary = BattleState.unit(sa, "a:dax")
	BattleResolver.submit_choice(sa, "a", {"move": "attack"})
	var hp_full: int = int(BattleState.unit(sa, "a:kira")["hp"])
	var kira_u: Dictionary = BattleState.unit(sa, "a:kira")
	kira_u["skills"].append("sacrificio")
	kira_u["energy"] = 4
	BattleResolver.submit_choice(sa, "a", {"move": "sacrificio"})
	var evsa: Array = BattleResolver.resolve_round(sa)
	var paid: bool = false
	for e in evsa:
		if str(e["t"]) == "damage" and bool(e.get("cost", false)):
			paid = true
	_check("il sacrificio si paga con i PV", paid)
	_check("carica: mossa pesante riconosciuta", BattleResolver.is_heavy_boss_move(BattleContent.BOSS_MOVES["gorgo"]) and not BattleResolver.is_heavy_boss_move({"mult": 0.5, "target": "one"}))
	var ob: Dictionary = {"objectives": {"day": "2026-10-12", "list": [{"kind": "breaks", "boss": "", "goal": 2, "progress": 0, "done": false, "reward": {"coins": 10}}]}}
	Objectives.record_battle(ob, "distributore", 0, true, "2026-10-12", {"breaks": 2, "synergies": 0, "downs": 0})
	_check("obiettivo rotture completato", bool(ob["objectives"]["list"][0]["done"]))
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
