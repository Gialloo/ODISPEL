extends SceneTree

# Fase 3: ogni boss ha la sua strada verso il BREAK (BreakRules), la fase 2 non toglie piu' la Riserva, frammenti diversi.
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


func _fresh(boss_id: String) -> Dictionary:
	var s: Dictionary = BattleState.create_solo("IO", _team(), [], boss_id, 7)
	SeqRound.begin(s)
	return s


func _heavy_move(boss_id: String) -> String:
	for m in BattleContent.BOSSES[boss_id]["cycle"]:
		if BattleResolver.is_heavy_boss_move(BattleContent.BOSS_MOVES[m]):
			return str(m)
	return ""


func _init() -> void:
	var s: Dictionary = _fresh("semaforo")
	var boss: Dictionary = BattleState.boss(s)
	var hero: Dictionary = BattleState.active_unit(s, str(s["players"][0]["id"]))
	s["telegraph"] = {"move": _heavy_move("semaforo"), "target": str(s["players"][1]["id"])}
	check(_heavy_move("semaforo") != "", "il Semaforo ha una carica")
	check(BreakRules.balance_mult(s, boss, hero) == 2.0, "Semaforo: x2 mentre carica")
	s["telegraph"] = {"move": "lampeggio", "target": ""}
	check(BreakRules.balance_mult(s, boss, hero) == 1.0 or BattleResolver.is_heavy_boss_move(BattleContent.BOSS_MOVES["lampeggio"]), "Semaforo: normale senza carica")
	# Cabina: chi e' chiamato toglie il doppio
	s = _fresh("cabina")
	boss = BattleState.boss(s)
	var pid: String = str(s["players"][2]["id"])
	s["telegraph"] = {"move": "squillo", "target": pid}
	check(BreakRules.balance_mult(s, boss, BattleState.active_unit(s, pid)) == 2.0, "Cabina: il chiamato x2")
	check(BreakRules.balance_mult(s, boss, BattleState.active_unit(s, str(s["players"][0]["id"]))) <= 1.5, "Cabina: gli altri no")
	# Cassaforte: con lo scudo meta', senza 1,5
	s = _fresh("cassaforte")
	boss = BattleState.boss(s)
	hero = BattleState.active_unit(s, str(s["players"][0]["id"]))
	s["telegraph"] = {"move": "serratura", "target": ""}
	boss["shield"] = 100
	check(BreakRules.balance_mult(s, boss, hero) == 0.5, "Cassaforte chiusa: x0,5")
	boss["shield"] = 0
	check(BreakRules.balance_mult(s, boss, hero) == 1.5, "Cassaforte aperta: x1,5")
	# Autovelox: la parata perfetta apre, il colpo dopo la consuma
	s = _fresh("autovelox")
	boss = BattleState.boss(s)
	hero = BattleState.active_unit(s, str(s["players"][0]["id"]))
	s["telegraph"] = {"move": "flash", "target": ""}
	BreakRules.on_perfect(s)
	check(BreakRules.balance_mult(s, boss, hero) == 2.0, "Autovelox: dopo la parata x2")
	check(BreakRules.balance_mult(s, boss, hero) == 1.0, "Autovelox: solo il colpo dopo")
	# Manichino: stessa categoria del compagno prima = meta'
	s = _fresh("manichino")
	boss = BattleState.boss(s)
	BreakRules.on_act(s, hero, "attacco")
	BreakRules.on_act(s, hero, "attacco")
	check(float(boss["mirror_mult"]) == 0.5, "Manichino: copiato x0,5")
	BreakRules.on_act(s, hero, "abilita")
	check(float(boss["mirror_mult"]) == 1.5, "Manichino: cambiato x1,5")
	# Distributore: nessuna regola (tutorial)
	check(BreakRules.of(BattleState.boss(_fresh("distributore"))).is_empty(), "Distributore senza regola")
	# Fase 2: niente Riserva divorata, carica x1,5 per tutti
	s = _fresh("distributore")
	boss = BattleState.boss(s)
	s["reserve"] = 3
	boss["hp"] = int(boss["max_hp"] * 0.4)
	var ev: Array = []
	BattleResolver._check_phase(s, ev)
	check(int(s["phase"]) == 2 and int(s["reserve"]) == 3, "fase 2: la Riserva resta")
	s["telegraph"] = {"move": _heavy_move("distributore"), "target": ""}
	check(BreakRules.balance_mult(s, boss, BattleState.active_unit(s, str(s["players"][0]["id"]))) == 1.5, "fase 2: carica x1,5")
	# Frammenti: corazza e radici
	s = _fresh("frammento_rosso")
	boss = BattleState.boss(s)
	var dummy_blu: Dictionary = {"color": "blu"}
	var dummy_giallo: Dictionary = {"color": "giallo"}
	check(BreakRules.dmg_mult(boss, dummy_blu) == 1.0 and BreakRules.dmg_mult(boss, dummy_giallo) == 0.5, "Corazza: pieno solo col colore vincente")
	s = _fresh("frammento_verde")
	boss = BattleState.boss(s)
	boss["hp"] = int(boss["max_hp"]) / 2
	var hp0: int = int(boss["hp"])
	ev = []
	BreakRules.round_end(s, ev)
	check(int(boss["hp"]) > hp0, "Radici: ricresce")
	boss["stun"] = 1
	hp0 = int(boss["hp"])
	BreakRules.round_end(s, ev)
	check(int(boss["hp"]) == hp0, "Radici: rotto non ricresce")
	if fails == 0:
		print("OK test_v3_break")
	quit(1 if fails > 0 else 0)
