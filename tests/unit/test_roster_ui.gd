extends SceneTree

# Schermata squadra e reclutamento. Usa un file temporaneo, non il salvataggio vero.
#
#   godot --headless --path . -s res://tests/unit/test_roster_ui.gd

var passed: int = 0
var failed: int = 0
const TMP: String = "user://test_roster_ui_tmp.json"


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _make(coins: int = 0) -> Control:
	var r: Dictionary = RosterState.new_roster()
	r["coins"] = coins
	r["materials"] = {"nucleo": 20, "lega": 5}
	var scene: Control = load("res://scenes/roster/roster_screen.tscn").instantiate()
	scene.roster = r
	scene.save_path = TMP
	root.add_child(scene)
	return scene


func _run() -> void:
	var s: Control = _make(500)
	await process_frame

	_check("parte sulla scheda della squadra", s.tab == "squadra")
	_check("e' scelto il primo della squadra", s.selected == "kira")
	_check("13 righe nella collezione", s._list_box.get_child_count() == 13)
	var enabled: int = 0
	for b in s._list_box.get_children():
		if not b.disabled:
			enabled += 1
	_check("si possono scegliere solo i 4 posseduti", enabled == 4)
	_check("3 posti in squadra", s._slots_box.get_child_count() == 3)
	_check("la scheda mostra il nome", s._detail_title.text == "KIRA")
	_check("la scheda mostra le statistiche", s._detail_label.text.contains("ATK"))
	_check("monete mostrate", s._coins_label.text.contains("500"))

	# selezione
	s.select("bruno")
	_check("selezione cambiata", s.selected == "bruno" and s._detail_title.text == "BRUNO")
	s.select("tana")
	_check("un non posseduto non si sceglie", s.selected == "bruno")

	# squadra piena: bruno prende il posto del terzo
	_check("squadra piena: sostituzione riuscita", s.toggle_team("bruno"))
	_check("bruno e' entrato al terzo posto", s.roster["team"] == ["kira", "dax", "bruno"])
	_check("la squadra e' valida", RosterState.validate(s.roster) == "")
	s.select_slot(0)
	_check("scegliere un posto sceglie chi c'e'", s.selected == "kira" and s.slot_target == 0)
	s.toggle_team("elle")
	_check("sostituzione nel posto scelto", s.roster["team"] == ["elle", "dax", "bruno"])

	# togliere
	s.select("dax")
	_check("tolto dalla squadra", s.toggle_team("dax") and s.roster["team"].size() == 2)
	_check("rimesso in squadra", s.toggle_team("dax") and s.roster["team"].size() == 3)
	_check("non posseduto rifiutato", not s.toggle_team("tana"))
	var one: Control = _make(0)
	one.roster["team"] = ["kira"]
	_check("l'ultimo operatore non si toglie", not one.toggle_team("kira") and one.roster["team"] == ["kira"])
	one.queue_free()

	# salvataggio
	var saved: Dictionary = RosterStore.load_or_new(TMP)
	_check("la squadra e' stata salvata", saved["team"] == s.roster["team"])

	# potenziamento
	var lv0: int = int(s.roster["characters"]["kira"]["level"])
	var coins0: int = int(s.roster["coins"])
	_check("potenziamento riuscito", s.upgrade("kira"))
	_check("livello salito", int(s.roster["characters"]["kira"]["level"]) == lv0 + 1)
	_check("monete pagate", int(s.roster["coins"]) < coins0)
	s.roster["coins"] = 0
	_check("senza monete il potenziamento e' rifiutato", not s.upgrade("kira"))
	_check("il messaggio dice perche'", s.status_text.contains("Monete"))
	_check("potenziare un non posseduto fallisce", not s.upgrade("tana"))

	# reclutamento
	s.show_tab("reclutamento")
	_check("pagina reclutamento", s._recruit_page.visible and not s._team_page.visible)
	_check("senza monete i pulsanti sono bloccati", s._pull_buttons[0][0].disabled)
	_check("reclutare senza monete e' rifiutato", not s.pull(1) and s.last_results.is_empty())
	s.roster["coins"] = 3000
	s.next_seed = 7
	await process_frame
	s.refresh()
	_check("con le monete i pulsanti si sbloccano", not s._pull_buttons[0][0].disabled and not s._pull_buttons[1][0].disabled)
	_check("reclutamento singolo", s.pull(1) and s.last_results.size() == 1)
	_check("monete scalate", int(s.roster["coins"]) == 3000 - 300 + int(s.last_results[0]["refund"]))
	_check("una riga di esito", s._results_box.get_child_count() == 1)
	s.roster["coins"] = 2700
	_check("reclutamento x10", s.pull(10) and s.last_results.size() == 10)
	_check("dieci righe di esito", s._results_box.get_child_count() == 10)
	_check("collezione valida dopo il reclutamento", RosterState.validate(s.roster) == "")
	_check("pagina reclutamento senza errori dopo il x10", s._pity_label.text.contains("Epico"))
	var back: Dictionary = RosterStore.load_or_new(TMP)
	_check("il reclutamento e' salvato", int(back["pulls"]) == 11)

	# tornando alla squadra le righe riflettono i nuovi personaggi
	s.show_tab("squadra")
	var en2: int = 0
	for b in s._list_box.get_children():
		if not b.disabled:
			en2 += 1
	_check("la collezione mostra i nuovi", en2 >= 4)

	s.queue_free()
	if FileAccess.file_exists(ProjectSettings.globalize_path(TMP)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
