extends SceneTree

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
	var r: Dictionary = RosterState.new_roster()
	var d1: String = "2026-10-13"
	var d2: String = "2026-10-14"
	_check("stesso giorno, stesso boss", Daily.boss_for(r, d1) == Daily.boss_for(r, d1))
	_check("il boss e' tra quelli aperti", RosterState.is_boss_unlocked(r, Daily.boss_for(r, d1)))
	_check("modificatore valido", not Daily.mod_for(d1).is_empty() and Daily.mod_for(d1) == Daily.mod_for(d1))
	_check("senza serie il premio e' x3", is_equal_approx(Daily.reward_mult(r, d1), 3.0))
	_check("non fatta oggi", not Daily.done_today(r, d1))
	_check("prima vittoria paga", Daily.record_win(r, d1))
	_check("seconda vittoria no", not Daily.record_win(r, d1))
	_check("serie 1", Daily.streak(r, d1) == 1 and Daily.done_today(r, d1))
	_check("giorno dopo la serie vive", Daily.streak(r, d2) == 1)
	_check("e sale a 2", Daily.record_win(r, d2) and Daily.streak(r, d2) == 2)
	_check("bonus serie", is_equal_approx(Daily.reward_mult(r, d2), 3.0 * 1.2))
	_check("saltando un giorno si azzera", Daily.streak(r, "2026-10-17") == 0)
	_check("record serie", int(r["daily"]["best"]) == 2)
	var back: Dictionary = RosterState.from_json(RosterState.to_json(r))
	_check("il salvataggio conserva la sfida", not back.is_empty() and int(back["daily"]["streak"]) == 2 and Daily.done_today(back, d2))
	var rw: Dictionary = Daily.scale_rewards({"coins": 100, "materials": {"nucleo": 2}}, 3.0)
	_check("premi scalati", int(rw["coins"]) == 300 and int(rw["materials"]["nucleo"]) == 6)
	var st: Dictionary = RosterState.create_solo_battle(r, "Io", "distributore", 5, 2, 0)
	var hp: int = int(BattleState.boss(st)["max_hp"])
	Endless.apply(st, Daily.FLOOR, "resistente")
	_check("la sfida scala il boss", int(BattleState.boss(st)["max_hp"]) > hp * 1.5)
	MissionConfig.set_daily("semaforo", 0, Daily.mod_for(d1))
	_check("MissionConfig riconosce la sfida", MissionConfig.daily_mod != "" and MissionConfig.endless_floor == 0)
	MissionConfig.set_mission("distributore", 0)
	_check("missione normale la spegne", MissionConfig.daily_mod == "")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
