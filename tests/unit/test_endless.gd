extends SceneTree

# Ciclo infinito: piani, scala, modificatori, premi, record, sblocco.
#   godot --headless --path . -s res://tests/unit/test_endless.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	var roster: Dictionary = RosterState.new_roster()
	_check("bloccato all'inizio", not Endless.available(roster))
	for id in ["distributore", "semaforo", "tombino"]:
		RosterState.mark_cleared(roster, str(id), 0)
	_check("si apre con 3 bersagli battuti", Endless.available(roster))
	_check("piano 1 = distributore", Endless.boss_for(1) == "distributore")
	var seen: Dictionary = {}
	for f in range(1, 60):
		_check("boss valido al piano %d" % f, BattleContent.BOSSES.has(Endless.boss_for(f)))
		seen[Endless.boss_for(f)] = true
	_check("ruotano tutti i boss", seen.size() == BattleContent.BOSS_ORDER.size())
	_check("il secondo giro cambia ordine", Endless.boss_for(8) != Endless.boss_for(1))
	_check("tier sale ogni 5 piani", Endless.tier_for(1) == 0 and Endless.tier_for(6) == 1 and Endless.tier_for(11) == 2 and Endless.tier_for(99) == 2)
	_check("nessun modificatore ai primi piani", Endless.mod_for(1).is_empty() and Endless.mod_for(2).is_empty())
	_check("modificatore dal piano 3", not Endless.mod_for(3).is_empty())
	var s1: Dictionary = BattleState.create([{"id": "a", "name": "a", "ai": false, "team": [BattleContent.default_entry("kira", 1, 0)]}], "distributore", 5, 0)
	var hp1: int = int(BattleState.boss(s1)["max_hp"])
	var atk1: int = int(BattleState.boss(s1)["atk"])
	Endless.apply(s1, 10)
	_check("PV crescono col piano", int(BattleState.boss(s1)["max_hp"]) > hp1 and int(BattleState.boss(s1)["hp"]) == int(BattleState.boss(s1)["max_hp"]))
	_check("attacco cresce col piano", int(BattleState.boss(s1)["atk"]) > atk1)
	_check("lo stato resta JSON-pulito", JSON.stringify(BattleState.from_json(BattleState.to_json(s1))) == JSON.stringify(s1))
	var r: Dictionary = {"coins": 100, "materials": {"nucleo": 2}, "drops": []}
	_check("premi crescono", int(Endless.scale_rewards(r, 5)["coins"]) > 100)
	_check("bonus ogni 5 piani", int(Endless.scale_rewards(r, 5)["materials"]["lega"]) >= 2 and not Endless.scale_rewards(r, 4)["materials"].has("lega"))
	_check("l'originale non cambia", int(r["coins"]) == 100)
	_check("record al primo successo", Endless.record(roster, 1, true))
	_check("niente record se sconfitto", not Endless.record(roster, 2, false))
	_check("record piu' alto", Endless.record(roster, 5, true) and Endless.best(roster) == 5)
	_check("non c'e' record a parita'", not Endless.record(roster, 5, true))
	MissionConfig.set_endless(7)
	_check("MissionConfig segue il piano", MissionConfig.endless_floor == 7 and MissionConfig.boss_id == Endless.boss_for(7))
	MissionConfig.set_mission("distributore", 0)
	_check("missione normale azzera il piano", MissionConfig.endless_floor == 0)
	_check("salvataggio valido col record", RosterState.validate(roster) == "")
	var s2: Dictionary = BattleState.create([{"id": "a", "name": "a", "ai": false, "team": [BattleContent.default_entry("kira", 1, 0), BattleContent.default_entry("dax", 1, 0)]}], "distributore", 5, 0)
	var ka: Dictionary = BattleState.unit(s2, "a:kira")
	var da: Dictionary = BattleState.unit(s2, "a:dax")
	ka["hp"] = 10
	da["hp"] = 0
	var carry: Dictionary = Endless.carry_from(s2)
	_check("carry registra i PV", int(carry["a:kira"]) == 10 and int(carry["a:dax"]) == 0)
	var s3: Dictionary = BattleState.create([{"id": "a", "name": "a", "ai": false, "team": [BattleContent.default_entry("kira", 1, 0), BattleContent.default_entry("dax", 1, 0)]}], "distributore", 6, 0)
	Endless.apply_carry(s3, carry)
	var k3: Dictionary = BattleState.unit(s3, "a:kira")
	var d3: Dictionary = BattleState.unit(s3, "a:dax")
	_check("PV riportati con un po' di recupero", int(k3["hp"]) > 10 and int(k3["hp"]) < int(k3["max_hp"]))
	_check("il caduto torna a ~30%", int(d3["hp"]) >= 1 and int(d3["hp"]) < int(d3["max_hp"]) / 2)
	MissionConfig.endless_carry = carry
	MissionConfig.set_endless(1)
	_check("al piano 1 il riporto si azzera", MissionConfig.endless_carry.is_empty())
	var rt: Dictionary = {}
	for f in [4, 9, 2, 7, 12, 5, 1]:
		Endless.finish_run(rt, f, "2026-10-13")
	_check("classifica: massimo 5 voci", Endless.top(rt).size() == 5)
	_check("classifica ordinata dal migliore", int(Endless.top(rt)[0]["floor"]) == 12 and int(Endless.top(rt)[4]["floor"]) == 4)
	Endless.finish_run(rt, 0)
	_check("serie a zero piani non conta", Endless.top(rt).size() == 5)
	_check("salvataggio valido con la classifica", RosterState.validate(RosterState.from_json(RosterState.to_json(rt))) != "x")
	_check("offerta: 3 potenziamenti diversi", Endless.offer(4).size() == 3 and Endless.offer(4)[0] != Endless.offer(4)[1] and Endless.offer(4) == Endless.offer(4))
	_check("offerta cambia col piano", Endless.offer(4) != Endless.offer(5) or Endless.offer(5) != Endless.offer(6))
	var sb: Dictionary = BattleState.create([{"id": "a", "name": "a", "ai": false, "team": [BattleContent.default_entry("kira", 1, 0)]}], "distributore", 9, 0)
	var kb: Dictionary = BattleState.unit(sb, "a:kira")
	var atk0: int = int(kb["atk"])
	var hp0: int = int(kb["max_hp"])
	var en0: int = int(kb["energy"])
	Endless.apply_boons(sb, ["furia", "furia", "tempra", "scorta", "carica", "scudo"])
	_check("furia x2 alza l'attacco del 16%", absi(int(kb["atk"]) - int(round(float(atk0) * 1.16))) <= 2)
	_check("tempra alza PV massimi e attuali", int(kb["max_hp"]) > hp0 and int(kb["hp"]) == int(kb["max_hp"]))
	_check("scorta, carica e scudo", int(kb["energy"]) == mini(BattleTypes.MAX_ENERGY, en0 + 2) and int(kb["gauge"]) >= 30 and int(kb["shield"]) > 0)
	_check("lo stato con potenziamenti resta JSON-pulito", JSON.stringify(BattleState.from_json(BattleState.to_json(sb))) == JSON.stringify(sb))
	MissionConfig.endless_boons = ["furia"]
	MissionConfig.set_endless(3)
	_check("i potenziamenti restano ai piani successivi", MissionConfig.endless_boons == ["furia"])
	MissionConfig.set_endless(1)
	_check("nuova serie: potenziamenti azzerati", MissionConfig.endless_boons.is_empty())
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
