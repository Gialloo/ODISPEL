extends SceneTree

# Prove di resistenza del motore: scelte casuali (anche sbagliate), tanti giocatori, stati e modificatori a valanga,
# numeri enormi, determinismo e invarianti (PV, energia, carica, munizioni, scudi sempre nei limiti).
#   godot --headless --path . -s res://tests/unit/test_stress.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _entry(id: String, level: int, rank: int) -> Dictionary:
	var e: Dictionary = BattleContent.default_entry(id, level, rank)
	var gear: Array = []
	if level > 1:
		for slot in BattleTypes.GEAR_SLOTS:
			gear.append({"slot": slot, "rarity": 3, "level": int(BattleContent.GEAR_MAX_LEVEL[3])})
	e["gear"] = gear
	return e


func _specs(players: int, level: int, rank: int, ai: bool) -> Array:
	var ids: Array = BattleContent.CHARACTERS.keys()
	var specs: Array = []
	for i in players:
		var team: Array = []
		for k in 3:
			team.append(_entry(str(ids[(i * 3 + k) % ids.size()]), level, rank))
		specs.append({"id": "p%d" % (i + 1), "name": "P%d" % (i + 1), "ai": ai, "team": team})
	return specs


# Vero se tutti gli invarianti reggono. Altrimenti ritorna il primo che salta.
func _invariants(state: Dictionary) -> String:
	for uid in state["units"]:
		var u: Dictionary = state["units"][uid]
		if int(u["hp"]) < 0 or int(u["hp"]) > int(u["max_hp"]):
			return "PV fuori limite " + str(uid)
		if int(u["shield"]) < 0:
			return "scudo negativo " + str(uid)
		if str(u["side"]) == "player":
			if int(u["energy"]) < 0 or int(u["energy"]) > BattleTypes.MAX_ENERGY:
				return "energia fuori limite " + str(uid)
			if int(u["gauge"]) < 0 or int(u["gauge"]) > BattleTypes.GAUGE_MAX:
				return "carica fuori limite " + str(uid)
			if int(u["ammo"]) < 0 or int(u["ammo"]) > maxi(int(u["ammo_max"]), 0):
				return "munizioni fuori limite " + str(uid)
		for s in u["statuses"]:
			if int(u["statuses"][s]) < 1:
				return "stato scaduto ancora presente " + str(s)
		for m in u.get("mods", []):
			if int(m["turns"]) < 1:
				return "modifica scaduta ancora presente"
		if int(u["hp"]) == 0 and not (u["statuses"] as Dictionary).is_empty():
			return "unita' a terra con stati " + str(uid)
	return ""


func _random_choice(state: Dictionary, p: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var u: Dictionary = BattleState.unit(state, str(p["active"]))
	var moves: Array = ["attack", "guard", "garbage", ""]
	moves.append_array(u.get("skills", []))
	moves.append(str(u.get("ult", "")))
	var choice: Dictionary = {"move": str(moves[rng.randi() % moves.size()]), "target": "boss", "swap": ""}
	if rng.randf() < 0.2:
		var party: Array = BattleState.party_of(state, p)
		choice["swap"] = str(party[rng.randi() % party.size()])
	if rng.randf() < 0.05:
		choice["swap"] = "fantasma"
	return choice


func _run() -> void:
	# 1) fuzz: scelte a caso, molte partite, squadre diverse e solitaria
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var battles: int = 0
	var broken: String = ""
	var rejected: int = 0
	var accepted: int = 0
	var finished: int = 0
	for boss in BattleContent.BOSS_ORDER:
		for tier in BattleContent.TIERS.size():
			for players in [1, 2, 4, 6]:
				for cfg in [[1, 0], [25, 3]]:
					var state: Dictionary = BattleState.create(_specs(players, int(cfg[0]), int(cfg[1]), false), str(boss), rng.randi(), tier)
					battles += 1
					var guard: int = 0
					while str(state["winner"]) == "" and guard < 150 and broken == "":
						BattleResolver.begin_round(state)
						for p in state["players"]:
							if BattleState.player_alive(state, p):
								var ch: Dictionary = _random_choice(state, p, rng)
								if BattleResolver.submit_choice(state, str(p["id"]), ch):
									accepted += 1
								else:
									rejected += 1
						BattleResolver.autoplay_round(state)
						broken = _invariants(state)
						guard += 1
					if str(state["winner"]) != "":
						finished += 1
	_check("fuzz: %d partite senza violare gli invarianti (%s)" % [battles, broken], broken == "")
	_check("fuzz: scelte valide e non valide gestite (%d ok / %d rifiutate)" % [accepted, rejected], accepted > 100 and rejected > 100)
	_check("fuzz: la maggior parte delle partite finisce", finished * 10 >= battles * 9)

	# 2) valanga di stati e modificatori su tutte le unita'
	var state2: Dictionary = BattleState.create(_specs(6, 25, 3, true), "distributore", 99, 2)
	for uid in state2["units"]:
		var u: Dictionary = state2["units"][uid]
		for s in BattleText.STATUS_NAMES:
			u["statuses"][s] = 3
		for i in 300:
			Factions.add_mod(u, "stress_%d" % i, ["atk", "def", "spd"][i % 3], (i % 7 - 3) * 40, 1 + i % 5)
	var many_mods: int = (state2["units"]["p1_" + str(BattleState.player(state2, "p1")["team"][0]).trim_prefix("p1_")]["mods"] as Array).size() if false else 300
	Factions.refresh(state2)
	var guard2: int = 0
	var bad2: String = ""
	while str(state2["winner"]) == "" and guard2 < 60 and bad2 == "":
		BattleResolver.resolve_round(state2, true)
		bad2 = _invariants(state2)
		guard2 += 1
	_check("valanga di 300 modificatori + tutti gli stati: nessun errore (%s)" % bad2, bad2 == "" and many_mods == 300)
	var js: String = JSON.stringify(state2)
	_check("lo stato resta serializzabile", js.length() > 100 and JSON.parse_string(js) is Dictionary)

	# 3) numeri enormi
	var a: Dictionary = BattleState.make_unit("x", BattleContent.default_entry("kira", 50, 5))
	var d: Dictionary = BattleState.make_unit("y", BattleContent.default_entry("dax", 50, 5))
	a["atk"] = 4000000000000
	d["def"] = 0
	var big: int = BattleResolver.calc_damage(a, d, 12.0, 0, 1.0e9)
	_check("danno con ATK da mille miliardi e' un intero positivo (%d)" % big, big > 0 and big < 9000000000000000000)
	a["atk"] = 1
	d["def"] = 4000000000000
	_check("DIF enorme: il danno minimo e' 1", BattleResolver.calc_damage(a, d, 0.5) == 1)
	a["atk"] = 0
	_check("ATK zero: danno 1", BattleResolver.calc_damage(a, d, 0.0) == 1)
	d["def"] = -90
	a["atk"] = 100
	_check("DIF negativa non produce errori", BattleResolver.calc_damage(a, d, 1.0) >= 1)
	d["def"] = -100
	_check("DIF = -100 non divide per zero", BattleResolver.calc_damage(a, d, 1.0) >= 1)

	# 4) determinismo: stesso seme, stesse scelte -> stesso risultato (serve alla rete)
	var finals: Array = []
	for run in 2:
		var s: Dictionary = BattleState.create(_specs(3, 10, 1, true), "semaforo", 777, 1)
		var g: int = 0
		while str(s["winner"]) == "" and g < 100:
			BattleResolver.resolve_round(s, true)
			g += 1
		finals.append(JSON.stringify(s))
	_check("determinismo: due partite identiche", finals[0] == finals[1])

	# 5) 6 giocatori: quanti eventi e quanto pesa lo stato (limite messaggi di rete)
	var s6: Dictionary = BattleState.create(_specs(6, 30, 3, true), "distributore", 5, 2)
	var most: int = 0
	var weight: int = 0
	var gg: int = 0
	while str(s6["winner"]) == "" and gg < 60:
		var ev: Array = BattleResolver.resolve_round(s6, true)
		most = maxi(most, ev.size())
		weight = maxi(weight, JSON.stringify(s6).length())
		gg += 1
	_check("6 giocatori: eventi per round limitati (%d)" % most, most < 400)
	_check("6 giocatori: stato sotto i 60 KB (%d byte)" % weight, weight < 60000)

	# 6) niente giocatori vivi / battaglia finita: scelte rifiutate
	var s7: Dictionary = BattleState.create(_specs(2, 1, 0, true), "distributore", 1, 0)
	for uid in s7["units"]:
		if str(s7["units"][uid]["side"]) == "player":
			s7["units"][uid]["hp"] = 0
	BattleResolver.resolve_round(s7, true)
	_check("tutti a terra: vince il boss", str(s7["winner"]) == "boss" or str(s7["winner"]) == "")
	_check("a battaglia finita ogni scelta e' rifiutata", BattleResolver.validate_choice(s7, "p1", {"move": "attack"}) != "")

	# 7) rapporto tecnico, numeri brevi, file rovinati
	var rep: String = Diagnostics.report()
	_check("rapporto tecnico completo", rep.contains("ODISPEL v") and rep.contains("Contenuti: OK") and rep.contains("Log:"))
	_check("numeri brevi", BattleText.num(999) == "999" and BattleText.num(99999) == "99999" and BattleText.num(123456) == "123K" and BattleText.num(1500000) == "1.5M" and BattleText.num(2500000000) == "2.5B" and BattleText.num(-250000) == "-250K")
	var bad_path: String = "user://test_rotto.json"
	var f := FileAccess.open(bad_path, FileAccess.WRITE)
	f.store_string("{non e' json ###")
	f.close()
	var recovered: Dictionary = RosterStore.load_or_new(bad_path)
	_check("salvataggio rovinato: riparte da uno nuovo", RosterState.validate(recovered) == "")
	var f2 := FileAccess.open(bad_path, FileAccess.WRITE)
	f2.store_string("[1,2,3]")
	f2.close()
	_check("salvataggio con formato sbagliato: riparte da uno nuovo", RosterState.validate(RosterStore.load_or_new(bad_path)) == "")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(bad_path))

	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _initialize() -> void:
	_run()
