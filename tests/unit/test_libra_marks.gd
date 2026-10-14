extends SceneTree

# Marchi a pile, malus a gradi, nascosto, torretta e drone, Dafne e Angela.
#   godot --headless --path . -s res://tests/unit/test_libra_marks.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _state(team: Array, rank: int = 0, boss: String = "distributore") -> Dictionary:
	var entries: Array = []
	for id in team:
		entries.append(BattleContent.default_entry(str(id), 1, rank))
	return BattleState.create([{"id": "a", "name": "a", "ai": false, "team": entries}], boss, 5)


func _act(s: Dictionary, uid: String, move_id: String, ev: Array) -> void:
	BattleResolver._player_act(s, BattleState.unit(s, uid), move_id, "", ev)


func _init() -> void:
	_check("contenuti validi", BattleContent.validate().is_empty())
	var s: Dictionary = _state(["dafne", "angela", "dax"])
	var dafne: Dictionary = BattleState.unit(s, "a:dafne")
	var angela: Dictionary = BattleState.unit(s, "a:angela")
	var boss: Dictionary = BattleState.boss(s)
	_check("capacita' munizioni per personaggio", int(angela["ammo_max"]) == 12 and int(dafne["ammo_max"]) == 6 and int(BattleState.unit(s, "a:dax")["ammo_max"]) == BattleTypes.AMMO_MAX)
	_check("Angela e' un glass cannon", int(angela["max_hp"]) < int(BattleState.unit(s, "a:dax")["max_hp"]) * 0.7)
	_check("Dafne: 3 skill + ricarica", (dafne["skills"] as Array).has("u_dafne_a") and (dafne["skills"] as Array).has("ricarica") and Signatures.skills_for("dafne", 0).has("u_dafne_b"))
	# marchi
	var ev: Array = []
	dafne["energy"] = 6
	_act(s, "a:dafne", "u_dafne_a", ev)
	_check("il Marchio mette una pila", Marks.count(boss) == 1 and boss["statuses"].has("mark"))
	var base: int = BattleResolver.calc_damage(angela, boss, 1.0)
	boss["marks"] = 0
	var no_mark: int = BattleResolver.calc_damage(angela, boss, 1.0)
	boss["marks"] = 4
	var four: int = BattleResolver.calc_damage(angela, boss, 1.0)
	var four_ammo: int = BattleResolver.calc_damage(angela, boss, 1.0, 0, 0.0, true)
	_check("+10% a marchio, di piu' con le munizioni", four > no_mark and four_ammo > four)
	_check("tetto di 6 marchi", _cap(s))
	# malus e buff a gradi
	boss["marks"] = 0
	var def_before: int = BattleResolver.calc_damage(angela, boss, 1.0)
	var ev2: Array = []
	Marks.debuff(boss, "def", 1, ev2)
	_check("DEF giu': piu' danno al boss", BattleResolver.calc_damage(angela, boss, 1.0) > def_before)
	Marks.debuff(boss, "atk", 1, ev2)
	_check("ATK del boss giu'", Marks.boss_mult(boss, "atk") < 1.0 and Marks.boss_mult(angela, "atk") == 1.0)
	# ultimate di Dafne
	var s2: Dictionary = _state(["dafne", "dax", "elle"])
	var d2: Dictionary = BattleState.unit(s2, "a:dafne")
	d2["gauge"] = 100
	BattleState.boss(s2)["hp"] = 1000000
	BattleState.boss(s2)["max_hp"] = 1000000
	var atk_before: int = int(BattleState.unit(s2, "a:dax")["atk"])
	var ev3: Array = []
	_act(s2, "a:dafne", "coordinated_shot", ev3)
	_check("Colpo coordinato: +3 marchi", Marks.count(BattleState.boss(s2)) == 3)
	_check("Colpo coordinato: malus al boss", Marks.boss_mult(BattleState.boss(s2), "def") < 1.0 and Marks.boss_mult(BattleState.boss(s2), "spd") < 1.0)
	_check("Colpo coordinato: alleati potenziati", int(BattleState.unit(s2, "a:dax")["atk"]) > atk_before)
	_check("Colpo coordinato spende 1 munizione", int(d2["ammo"]) == int(d2["ammo_max"]) - 1)
	# passiva di Dafne: crit per marchi applicati
	var crit_no: int = Signatures.crit_bonus({"marks_applied": 0}, d2, BattleState.boss(s2))
	var crit_yes: int = Signatures.crit_bonus({"marks_applied": 4}, d2, BattleState.boss(s2))
	_check("Occhio del cecchino: +critico per marchio", crit_yes > crit_no and crit_yes >= 100)
	# nascosto
	var s3: Dictionary = _state(["dafne", "dax"])
	var d3: Dictionary = BattleState.unit(s3, "a:dafne")
	var ev4: Array = []
	d3["ammo"] = 1
	_act(s3, "a:dafne", "u_dafne_c", ev4)
	_check("Copertura: nascosto, scudo, +2 munizioni", d3["statuses"].has("hidden") and int(d3["shield"]) > 0 and int(d3["ammo"]) == 3)
	var dodged := 0
	var hit := 0
	for sd in 60:
		var t: Dictionary = _state(["dafne", "dax"])
		t["rng_seed"] = str(sd)
		var tu: Dictionary = BattleState.unit(t, "a:dafne")
		tu["statuses"]["hidden"] = 1
		var e5: Array = []
		BattleResolver._hit(t, BattleState.boss(t), tu, 1.0, e5)
		if e5[0]["t"] == "dodge":
			dodged += 1
		else:
			hit += 1
	_check("il nascosto schiva una parte dei colpi (non tutti, non nessuno)", dodged > 5 and hit > 5)
	# Angela
	var s4: Dictionary = _state(["angela", "dafne", "dax"])
	var a4: Dictionary = BattleState.unit(s4, "a:angela")
	var dd4: Dictionary = BattleState.unit(s4, "a:dafne")
	a4["energy"] = 6
	dd4["ammo"] = 0
	var ev6: Array = []
	_act(s4, "a:angela", "u_angela_b", ev6)
	_check("Drone: 3 marchi e munizioni a tutta la squadra", Marks.count(BattleState.boss(s4)) == 3 and int(dd4["ammo"]) >= 3)
	_check("il drone e' evocato", (s4["summons"] as Array).size() == 1 and str(s4["summons"][0]["kind"]) == "drone")
	_check("passiva: i marchi ricaricano i LibraCorp", int(dd4["ammo"]) >= 3 + 3 or int(dd4["ammo"]) == int(dd4["ammo_max"]))
	var ev7: Array = []
	a4["ammo"] = 2
	var bhp: int = int(BattleState.boss(s4)["hp"])
	BattleResolver._summon_upkeep(s4, ev7, true)
	_check("il drone spara e a 0 munizioni finisce con scudi", int(BattleState.boss(s4)["hp"]) < bhp and (s4["summons"] as Array).size() == 1)
	BattleResolver._summon_upkeep(s4, ev7, true)
	var shielded: bool = int(BattleState.unit(s4, "a:dax")["shield"]) > 0
	_check("drone esaurito: scudi alla squadra", (s4["summons"] as Array).is_empty() and shielded)
	# torretta: a 0 munizioni esplode
	var s5: Dictionary = _state(["angela", "dax"])
	var a5: Dictionary = BattleState.unit(s5, "a:angela")
	a5["energy"] = 6
	var ev8: Array = []
	_act(s5, "a:angela", "u_angela_a", ev8)
	_check("Torretta evocata (+1 marchio)", (s5["summons"] as Array).size() == 1 and Marks.count(BattleState.boss(s5)) == 1)
	a5["ammo"] = 1
	var hp5: int = int(BattleState.boss(s5)["hp"])
	var ev9: Array = []
	BattleResolver._summon_upkeep(s5, ev9, true)
	var kinds: Array = []
	for x in ev9:
		kinds.append(str(x["t"]))
	_check("torretta: ultimo colpo, poi esplode", kinds.has("summon_shot") and kinds.has("summon_end") and int(BattleState.boss(s5)["hp"]) < hp5)
	# mitragliatrice: 3 colpi
	var s6: Dictionary = _state(["angela", "dax"])
	var a6: Dictionary = BattleState.unit(s6, "a:angela")
	a6["energy"] = 6
	var ev10: Array = []
	_act(s6, "a:angela", "u_angela_c", ev10)
	var hits := 0
	for x in ev10:
		if str(x["t"]) == "damage" and str(x["dst"]) == BattleState.BOSS_ID:
			hits += 1
	_check("Mitragliatrice: 3 colpi, 3 munizioni", hits == 3 and int(a6["ammo"]) == int(a6["ammo_max"]) - 3)
	# Orbital Strike
	var s7: Dictionary = _state(["angela", "dax"])
	var a7: Dictionary = BattleState.unit(s7, "a:angela")
	var b7: Dictionary = BattleState.boss(s7)
	a7["gauge"] = 100
	b7["hp"] = 1000000
	b7["max_hp"] = 1000000
	var ev11: Array = []
	_act(s7, "a:angela", "orbital_strike", ev11)
	var s8: Dictionary = _state(["angela", "dax"])
	var a8: Dictionary = BattleState.unit(s8, "a:angela")
	a8["gauge"] = 100
	BattleState.boss(s8)["hp"] = 1000000
	BattleState.boss(s8)["max_hp"] = 1000000
	BattleState.boss(s8)["marks"] = 5
	BattleState.boss(s8)["statuses"]["mark"] = 99
	var ev12: Array = []
	_act(s8, "a:angela", "orbital_strike", ev12)
	var lost7: int = int(b7["max_hp"]) - int(b7["hp"])
	var lost8: int = int(BattleState.boss(s8)["max_hp"]) - int(BattleState.boss(s8)["hp"])
	_check("Raggio orbitale: piu' marchi, piu' danno", lost8 > lost7 * 2)
	_check("Raggio orbitale consuma i marchi", Marks.count(BattleState.boss(s8)) == 0 and not BattleState.boss(s8)["statuses"].has("mark"))
	# JSON e determinismo
	var s9: Dictionary = _state(["dafne", "angela", "dax"], 3)
	for i in 4:
		BattleResolver.resolve_round(s9, true)
	_check("JSON identico con evocazioni e marchi", BattleState.to_json(s9) == BattleState.to_json(BattleState.from_json(BattleState.to_json(s9))))
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _cap(s: Dictionary) -> bool:
	var b: Dictionary = BattleState.boss(s)
	b["marks"] = 0
	var ev: Array = []
	Marks.add(s, b, 20, ev)
	return Marks.count(b) == Marks.MAX
