extends SceneTree

# Schermata di scelta missione e configurazione della missione.
#   godot --headless --path . -s res://tests/unit/test_missions.gd

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


func _run() -> void:
	var r: Dictionary = RosterState.new_roster()
	var s: Control = load("res://scenes/missions/mission_screen.tscn").instantiate()
	s.roster = r
	root.add_child(s)
	await process_frame

	_check("parte dal primo boss", s.selected_boss == "distributore")
	_check("livello normale", s.selected_tier == 0)
	_check("8 pulsanti boss", s.boss_buttons.size() == 8)
	_check("3 pulsanti livello", s.tier_buttons.size() == 3)
	_check("semaforo bloccato", s.boss_buttons["semaforo"].disabled)
	_check("il bloccato non si sceglie", not s.select_boss("semaforo"))
	_check("difficile bloccato", s.tier_buttons[1].disabled)
	_check("il livello bloccato non si sceglie", not s.select_tier(1))
	_check("normale scelto", s.tier_buttons[0].disabled == false)

	RosterState.mark_cleared(r, "distributore", 0)
	s._refresh()
	_check("semaforo si sblocca", not s.boss_buttons["semaforo"].disabled)
	_check("difficile si sblocca", not s.tier_buttons[1].disabled)
	_check("tombino ancora bloccato", s.boss_buttons["tombino"].disabled)
	_check("scelgo il semaforo", s.select_boss("semaforo"))
	_check("semaforo scelto", s.selected_boss == "semaforo")
	_check("il dossier mostra il nome", s._boss_title.text == "SEMAFORO")
	_check("scelgo il difficile al distributore", s.select_boss("distributore") and s.select_tier(1))
	_check("cambiando boss se il livello e' chiuso si torna a normale", s.select_boss("semaforo") and s.selected_tier == 0)

	# configurazione
	s.select_boss("distributore")
	s.select_tier(1)
	MissionConfig.set_mission("tombino", 2)
	_check("config boss", MissionConfig.boss_id == "tombino")
	_check("config livello", MissionConfig.tier == 2)
	MissionConfig.set_mission("inesistente", 9)
	_check("boss sconosciuto ignorato", MissionConfig.boss_id == "tombino")
	_check("livello limitato", MissionConfig.tier == 2)

	# battaglia solitaria con la missione scelta
	MissionConfig.set_mission("semaforo", 1)
	var b: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(b)
	await process_frame
	await process_frame
	_check("la battaglia usa il boss scelto", str(BattleState.boss(b.source.battle)["char"]) == "semaforo")
	_check("la battaglia usa il livello scelto", int(b.source.battle["tier"]) == 1)
	_check("il banner nomina il boss", b._boss_name.text.contains("SEMAFORO") and b._boss_name.text.contains("DIFFICILE"))

	MissionConfig.set_mission("distributore", 0)
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
