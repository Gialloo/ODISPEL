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
	Objectives.enabled = false
	var r: Dictionary = RosterState.new_roster()
	var w1: int = Weekly.week_id("2026-10-12")   # lunedi'
	_check("lunedi e domenica sono la stessa settimana", Weekly.week_id("2026-10-18") == w1)
	_check("il lunedi dopo e' un'altra", Weekly.week_id("2026-10-19") == w1 + 1)
	_check("stesso boss in tutta la settimana", Weekly.boss_for(r, w1) == Weekly.boss_for(r, Weekly.week_id("2026-10-16")))
	_check("boss tra quelli aperti", RosterState.is_boss_unlocked(r, Weekly.boss_for(r, w1)))
	_check("senza serie premio x8", is_equal_approx(Weekly.reward_mult(r, w1), 8.0))
	_check("prima vittoria paga", Weekly.record_event(r, w1))
	_check("seconda no", not Weekly.record_event(r, w1))
	_check("serie 1", Weekly.streak(r, w1) == 1 and Weekly.event_done(r, w1))
	_check("settimana dopo la serie vive", Weekly.streak(r, w1 + 1) == 1)
	_check("e sale a 2", Weekly.record_event(r, w1 + 1) and Weekly.streak(r, w1 + 1) == 2)
	_check("bonus serie", is_equal_approx(Weekly.reward_mult(r, w1 + 1), 8.0 * 1.2))
	_check("saltando una settimana si azzera", Weekly.streak(r, w1 + 3) == 0)
	_check("record serie conservato", int(r["weekly"]["best_streak"]) == 2 or int(Weekly.ensure_week(r, w1 + 3)["best_streak"]) == 2)
	# missioni
	var m: Dictionary = RosterState.new_roster()
	var coins0: int = int(m["coins"])
	var notes: Array = []
	for i in 6:
		notes.append_array(Weekly.record_win(m, false, w1))
	_check("6 vittorie completano la missione", notes.size() == 1 and int(m["coins"]) - coins0 == 300)
	notes = Weekly.record_win(m, false, w1)
	_check("la missione paga una volta sola", notes.is_empty() and int(m["coins"]) - coins0 == 300)
	for i in 3:
		Weekly.record_win(m, true, w1)
	_check("3 sfide del giorno pagano", int(m["coins"]) - coins0 == 700)
	var back: Dictionary = RosterState.from_json(RosterState.to_json(m))
	_check("il salvataggio conserva la settimana", int(back["weekly"]["wins"]) == 10 and (back["weekly"]["claimed"] as Array).size() == 2)
	var nxt: Dictionary = Weekly.ensure_week(m, w1 + 1)
	_check("nuova settimana azzera i progressi", int(nxt["wins"]) == 0 and (nxt["claimed"] as Array).is_empty())
	_check("testi ok", Weekly.missions_text(m).length() > 10 and Weekly.records_text(m).begins_with("RECORD"))
	# battaglia
	var src: SoloBattleSource = SoloBattleSource.new()
	src.save_path = "user://test_weekly_tmp.json"
	src.daily_mod = "furioso"
	src.weekly = true
	var rr: Dictionary = RosterState.new_roster()
	src.start(rr, "distributore", 11, 0)
	_check("evento piu' duro della sfida", int(BattleState.boss(src.battle)["max_hp"]) > 0 and int(src.battle.get("endless", 0)) == Weekly.FLOOR)
	src.battle["winner"] = "players"
	src.finish()
	_check("evento segnato", src.daily_first and Weekly.event_done(rr))
	_check("la sfida del giorno non e' toccata", not Daily.done_today(rr))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_weekly_tmp.json"))
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
