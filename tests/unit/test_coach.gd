extends SceneTree

# Prima partita guidata: passi, avanzamento, salvataggio.
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
	Settings.path = "user://test_coach_settings.cfg"
	Settings.coach_step = 0
	var kinds: Array = []
	for s in BattleCoach.STEPS:
		kinds.append(str(s["kind"]))
		_check("passo '%s' completo" % str(s["title"]), str(s["text"]).length() > 20 and str(s["target"]) != "")
	_check("ci sono azioni e spiegazioni", kinds.has("pick_attack") and kinds.has("pick_guard") and kinds.has("pick_skill") and kinds.has("swap") and kinds.has("info"))
	_check("in headless la guida non parte da sola", not BattleCoach.active())

	var host := Control.new()
	root.add_child(host)
	var coach: BattleCoach = BattleCoach.new().setup(host)
	host.add_child(coach)
	await process_frame
	await process_frame
	_check("parte dal primo passo", coach.index == 0 and str(coach._step()["kind"]) == "pick_attack")
	coach.note("pick", "guard")
	_check("la mossa sbagliata non fa avanzare", coach.index == 0 and not coach._wait_round)
	coach.note("pick", "attack")
	_check("attacco scelto: aspetta la fine del round", coach._wait_round and coach.index == 0)
	coach.note("round")
	_check("round finito: passo 2 (spiegazione)", coach.index == 1 and str(coach._step()["kind"]) == "info" and coach.next_button.visible)
	_check("il progresso e' salvato", Settings.coach_step == 1)
	coach.advance()
	_check("passo 3: guardia", str(coach._step()["kind"]) == "pick_guard")
	coach.note("pick", "guard")
	coach.note("round")
	_check("passo 4: abilita'", str(coach._step()["kind"]) == "pick_skill")
	coach.note("pick", "attack")
	_check("un attacco semplice non conta come abilita'", not coach._wait_round)
	coach.note("pick", "barriera")
	coach.note("round")
	coach.advance()
	_check("passo 6: cambio operatore", str(coach._step()["kind"]) == "swap")
	coach.note("swap")
	_check("il cambio fa avanzare subito", str(coach._step()["kind"]) == "info" and Settings.coach_step == 6)
	coach.skip_all()
	_check("SALTA chiude per sempre", Settings.coach_step >= BattleCoach.STEPS.size())
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_coach_settings.cfg"))
	print("RESULT: %d passed, %d failed" % [passed, failed])
	print("FAIL: %d" % failed)
	quit(1 if failed > 0 else 0)
