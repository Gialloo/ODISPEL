extends SceneTree

# Boss nuovi, livelli di difficolta' e nuove mosse del boss.
#
#   godot --headless --path . -s res://tests/unit/test_bosses.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _team(ids: Array, level: int = 5) -> Array:
	var out: Array = []
	for id in ids:
		out.append(BattleContent.default_entry(str(id), level, 0))
	return out


func _state(boss_id: String, tier: int = 0, players: int = 2) -> Dictionary:
	var specs: Array = []
	for i in players:
		specs.append({"id": "p%d" % (i + 1), "name": "P%d" % (i + 1), "ai": false, "team": _team(["kira", "dax", "elle"])})
	return BattleState.create(specs, boss_id, 77, tier)


func _run() -> void:
	# --- dati
	_check("contenuti coerenti (con i boss nuovi)", BattleContent.validate().is_empty())
	_check("diciotto boss in ordine di sblocco (stagione 1 + stagione 2)", BattleContent.BOSS_ORDER.size() == 18 and BattleContent.BOSS_ORDER.slice(0, 8) == ["distributore", "semaforo", "tombino", "cabina", "ascensore", "manichino", "orologio", "specchio"] and BattleContent.BOSS_ORDER[8] == "sirena" and BattleContent.BOSS_ORDER[17] == "eclissi")
	_check("tre livelli di difficolta'", BattleContent.TIERS.size() == 3)
	for id in BattleContent.BOSS_ORDER:
		var b: Dictionary = BattleContent.BOSSES[id]
		_check("%s: ha descrizione e titolo" % id, str(b["desc"]) != "" and str(b["title"]) != "")
		_check("%s: ciclo di 4 mosse" % id, b["cycle"].size() == 4)
	_check("i tre boss hanno colori diversi", BattleContent.BOSSES["distributore"]["color"] != BattleContent.BOSSES["semaforo"]["color"] and BattleContent.BOSSES["semaforo"]["color"] != BattleContent.BOSSES["tombino"]["color"])
	_check("i premi crescono col boss", int(BattleContent.BOSSES["semaforo"]["reward"]["coins"]) > int(BattleContent.BOSSES["distributore"]["reward"]["coins"]) and int(BattleContent.BOSSES["tombino"]["reward"]["coins"]) > int(BattleContent.BOSSES["semaforo"]["reward"]["coins"]))
	_check("tier fuori scala ricondotto", BattleContent.tier_of(-3)["id"] == "normale" and BattleContent.tier_of(99)["id"] == "incubo")

	# --- difficolta'
	var hp: Array = []
	var atk: Array = []
	var dfn: Array = []
	for t in 3:
		var s: Dictionary = _state("distributore", t)
		hp.append(int(BattleState.boss(s)["max_hp"]))
		atk.append(int(BattleState.boss(s)["atk"]))
		dfn.append(int(BattleState.boss(s)["def"]))
		_check("tier %d registrato nello stato" % t, int(s["tier"]) == t)
	_check("i PV salgono con la difficolta'", hp[0] < hp[1] and hp[1] < hp[2])
	_check("l'ATK sale con la difficolta'", atk[0] < atk[1] and atk[1] < atk[2])
	_check("la DEF sale con la difficolta'", dfn[0] < dfn[1] and dfn[1] < dfn[2])
	_check("normale = valori di base", hp[0] == 1800 and dfn[0] == 25)
	_check("tier fuori scala nello stato", int(_state("distributore", 9)["tier"]) == 2 and int(_state("distributore", -1)["tier"]) == 0)
	var js: Dictionary = BattleState.from_json(BattleState.to_json(_state("tombino", 2)))
	_check("il tier sopravvive al JSON", js["tier"] == 2 and js["tier"] is int)
	_check("create senza tier = normale", int(BattleState.create([{"id": "p1", "name": "P", "ai": false, "team": _team(["kira"])}], "semaforo", 1)["tier"]) == 0)
	var solo: Dictionary = BattleState.create_solo("IO", _team(["kira", "dax", "elle"]), _team(["bruno"]), "tombino", 5, 2, 1)
	_check("la partita solo accetta il tier", int(solo["tier"]) == 1)

	# --- mosse nuove: bersaglio piu' ferito
	var s1: Dictionary = _state("semaforo")
	var cyc: Array = BattleContent.BOSSES["semaforo"]["cycle"]
	s1["cycle_index"] = cyc.find("giallo")
	var p2a: Dictionary = BattleState.active_unit(s1, "p2")
	p2a["hp"] = int(float(p2a["max_hp"]) * 0.3)
	BattleResolver.begin_round(s1)
	_check("giallo: il bersaglio annunciato e' il piu' ferito", s1["telegraph"]["move"] == "giallo" and s1["telegraph"]["target"] == "p2")
	var p2_unit: String = str(BattleState.active_unit(s1, "p2")["id"])
	BattleResolver.submit_choice(s1, "p1", {"move": "guard"})
	BattleResolver.submit_choice(s1, "p2", {"move": "guard"})
	var ev: Array = BattleResolver.resolve_round(s1)
	var shielded: bool = false
	var hit_p2: bool = false
	for e in ev:
		if str(e["t"]) == "shield" and str(e["dst"]) == BattleState.BOSS_ID:
			shielded = true
		if str(e["t"]) == "damage" and str(e["src"]) == BattleState.BOSS_ID and str(e["dst"]) == p2_unit:
			hit_p2 = true
	_check("giallo: il boss si fa uno scudo", shielded)
	_check("giallo: colpisce il piu' ferito", hit_p2)

	# --- lampeggio marchia tutti
	var s2: Dictionary = _state("semaforo")
	s2["cycle_index"] = cyc.find("lampeggio")
	BattleResolver.begin_round(s2)
	BattleResolver.submit_choice(s2, "p1", {"move": "attack"})
	BattleResolver.submit_choice(s2, "p2", {"move": "attack"})
	BattleResolver.resolve_round(s2)
	var marked: int = 0
	for pid in ["p1", "p2"]:
		if BattleState.active_unit(s2, pid)["statuses"].has("mark"):
			marked += 1
	_check("lampeggio marchia tutti gli operatori", marked == 2)

	# --- risucchio cura il boss
	var s3: Dictionary = _state("tombino")
	var cyc3: Array = BattleContent.BOSSES["tombino"]["cycle"]
	s3["cycle_index"] = cyc3.find("risucchio")
	BattleResolver.begin_round(s3)
	var boss3: Dictionary = BattleState.boss(s3)
	boss3["hp"] = int(boss3["max_hp"]) / 2
	var hp3: int = int(boss3["hp"])
	BattleResolver.submit_choice(s3, "p1", {"move": "guard"})
	BattleResolver.submit_choice(s3, "p2", {"move": "guard"})
	var ev3: Array = BattleResolver.resolve_round(s3)
	var healed: bool = false
	for e in ev3:
		if str(e["t"]) == "heal" and str(e["dst"]) == BattleState.BOSS_ID:
			healed = true
	_check("risucchio: il boss recupera PV", healed and int(BattleState.boss(s3)["hp"]) > hp3)
	_check("il boss non supera i PV massimi", int(BattleState.boss(s3)["hp"]) <= int(BattleState.boss(s3)["max_hp"]))

	# --- alluvione fa sanguinare tutti
	var s4: Dictionary = _state("tombino")
	s4["cycle_index"] = cyc3.find("alluvione")
	BattleResolver.begin_round(s4)
	BattleResolver.submit_choice(s4, "p1", {"move": "guard"})
	BattleResolver.submit_choice(s4, "p2", {"move": "guard"})
	BattleResolver.resolve_round(s4)
	var bleeding: int = 0
	for pid in ["p1", "p2"]:
		if BattleState.active_unit(s4, pid)["statuses"].has("bleed"):
			bleeding += 1
	_check("alluvione: tutti sanguinano", bleeding == 2)

	# --- battaglie complete con ogni boss e tier
	for id in BattleContent.BOSS_ORDER:
		for t in 3:
			var s5: Dictionary = _state(id, t, 3)
			var guard: int = 0
			while str(s5["winner"]) == "" and guard < 200:
				for p in s5["players"]:
					if BattleState.player_alive(s5, p):
						BattleResolver.submit_choice(s5, str(p["id"]), BattleAI.choose(s5, str(p["id"])))
				BattleResolver.resolve_round(s5, true)
				guard += 1
			_check("%s / tier %d: la battaglia finisce" % [id, t], str(s5["winner"]) != "" and guard < 200)

	# --- determinismo
	var da: Dictionary = _state("semaforo", 1)
	var db: Dictionary = _state("semaforo", 1)
	for i in 6:
		for st in [da, db]:
			for p in st["players"]:
				BattleResolver.submit_choice(st, str(p["id"]), BattleAI.choose(st, str(p["id"])))
			BattleResolver.resolve_round(st, true)
	_check("stesso seed e tier, stessa battaglia", BattleState.to_json(da) == BattleState.to_json(db))

	# --- premi
	var r0: Dictionary = BattleRewards.for_player("semaforo", 11, 0, true, 0)
	var r1: Dictionary = BattleRewards.for_player("semaforo", 11, 0, true, 1)
	var r2: Dictionary = BattleRewards.for_player("semaforo", 11, 0, true, 2)
	_check("monete crescono con la difficolta'", int(r0["coins"]) < int(r1["coins"]) and int(r1["coins"]) < int(r2["coins"]))
	_check("monete normale = base", int(r0["coins"]) == int(BattleContent.BOSSES["semaforo"]["reward"]["coins"]))
	_check("piu' drop ai livelli alti (almeno 4 a incubo)", r2["drops"].size() >= 4)
	_check("premi deterministici per tier", BattleRewards.for_player("tombino", 5, 1, true, 2) == BattleRewards.for_player("tombino", 5, 1, true, 2))
	_check("sconfitta: solo un terzo delle monete (con moltiplicatore)", int(BattleRewards.for_player("tombino", 5, 0, false, 2)["coins"]) == int(round(float(BattleContent.BOSSES["tombino"]["reward"]["coins"]) * float(BattleContent.tier_of(2)["reward"]))) / 3)
	_check("senza tier i premi restano quelli di prima", BattleRewards.for_player("distributore", 3, 0, true) == BattleRewards.for_player("distributore", 3, 0, true, 0))
	var fin: Dictionary = _state("tombino", 2, 2)
	fin["winner"] = "players"
	var all: Dictionary = BattleRewards.for_battle(fin, "tombino", 77)
	_check("for_battle usa il tier dello stato", int(all["p1"]["coins"]) == int(round(float(BattleContent.BOSSES["tombino"]["reward"]["coins"]) * float(BattleContent.tier_of(2)["reward"]))))
	_check("tutti i drop sono validi", _drops_valid(r2["drops"]) and _drops_valid(all["p1"]["drops"]))

	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _drops_valid(drops: Array) -> bool:
	for d in drops:
		match str(d["kind"]):
			"move":
				if not BattleContent.MOVES.has(str(d["id"])):
					return false
			"passive":
				if not BattleContent.PASSIVES.has(str(d["id"])):
					return false
			"gear":
				if not BattleTypes.GEAR_SLOTS.has(str(d["slot"])):
					return false
			_:
				return false
	return true
