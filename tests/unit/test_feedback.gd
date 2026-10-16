extends SceneTree

# Avvisi, icona di attivita', salvataggio, caricamento, router e scorciatoie di comodo.
#   godot --headless --path . -s res://tests/unit/test_feedback.gd

var passed: int = 0
var failed: int = 0
const TMP: String = "user://test_feedback_tmp.json"


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var fb: Node = root.get_node("Feedback")

	# --- avvisi
	Notify.toast("uno")
	Notify.success("due")
	_check("gli avvisi compaiono", fb.toast_count() == 2)
	for i in 6:
		Notify.warning("avviso %d" % i)
	_check("non piu' di 4 avvisi insieme", fb.toast_count() == 4)
	await create_timer(5.0).timeout
	_check("gli avvisi spariscono da soli", fb.toast_count() == 0)

	# --- attivita'
	_check("senza attivita' l'icona e' nascosta", fb.spinner_text() == "")
	Notify.busy("rete", "CONNESSIONE AL SERVER...")
	_check("l'icona mostra il testo", fb.spinner_text() == "CONNESSIONE AL SERVER...")
	Notify.busy("dati", "CARICAMENTO DATI...")
	_check("con due attivita' si vede l'ultima", fb.spinner_text() == "CARICAMENTO DATI...")
	Notify.idle("dati")
	_check("finita una, torna l'altra", fb.spinner_text() == "CONNESSIONE AL SERVER...")
	Notify.idle("rete")
	_check("finite tutte, sparisce", fb.spinner_text() == "")

	# --- salvataggio
	var r: Dictionary = RosterState.new_roster()
	_check("il salvataggio riesce", RosterStore.save(r, TMP))
	_check("dopo il salvataggio compare SALVATO", fb.spinner_text() == "SALVATO")
	var bad: Dictionary = {"x": 1}
	_check("salvataggio non valido rifiutato", not RosterStore.save(bad, TMP))
	_check("e lo dice", fb.spinner_text() == "SALVATAGGIO NON RIUSCITO")
	await create_timer(1.8).timeout
	_check("l'indicatore di salvataggio sparisce", fb.spinner_text() == "")

	# --- caricamento
	var ran: Array = []
	Notify.transition(func() -> void: ran.append(1), "PROVA", "consiglio")
	await create_timer(0.4).timeout
	_check("durante il caricamento si esegue l'azione", ran.size() == 1)
	_check("e la schermata e' attiva", fb.is_loading())
	await create_timer(1.2).timeout
	_check("poi si scopre", not fb.is_loading())
	Notify.transition(func() -> void: ran.append(2))
	Notify.transition(func() -> void: ran.append(3))
	_check("un secondo cambio durante il primo parte subito", ran.has(3))
	await create_timer(1.5).timeout

	# --- router
	_check("percorso dell'hub", SceneRouter.path_of("hub").ends_with("hub_demo.tscn"))
	_check("schermata sconosciuta", SceneRouter.path_of("boh") == "")
	SceneRouter.go("hub")
	await process_frame
	await process_frame
	_check("il router cambia scena", SceneRouter.is_current("hub"))
	_check("la scena corrente e' riconosciuta", not SceneRouter.is_current("battle"))

	# --- missione consigliata
	var fresh: Dictionary = RosterState.new_roster()
	_check("all'inizio: distributore normale", MissionConfig.suggest(fresh) == {"boss": "distributore", "tier": 0})
	RosterState.mark_cleared(fresh, "distributore", 0)
	_check("battuto: stesso boss, livello dopo", MissionConfig.suggest(fresh) == {"boss": "distributore", "tier": 1})
	RosterState.mark_cleared(fresh, "distributore", 1)
	RosterState.mark_cleared(fresh, "distributore", 2)
	_check("tutto finito: boss dopo", MissionConfig.suggest(fresh) == {"boss": "semaforo", "tier": 0})
	for id in BattleContent.BOSS_ORDER:
		for t in 3:
			RosterState.mark_cleared(fresh, str(id), t)
	_check("completato tutto: ripete l'ultima", str(MissionConfig.suggest(fresh)["boss"]) == MissionConfig.boss_id)

	# --- sblocchi
	_check("novita' dopo il primo normale", RosterState.unlock_news("distributore", 0).size() == 3)
	_check("novita' dopo il difficile: solo incubo", RosterState.unlock_news("distributore", 1).size() == 1)
	_check("dopo l'incubo si apre ABISSO", " ".join(RosterState.unlock_news("cabina", 2)).find("ABISSO") >= 0)
	_check("niente dopo ABISSO", RosterState.unlock_news("cabina", 3).is_empty())

	# --- squadra migliore
	var team_r: Dictionary = RosterState.new_roster()
	RosterState.add_character(team_r, "sera")
	RosterState.add_character(team_r, "nova")
	var best: Array = RosterState.best_team(team_r)
	_check("la squadra migliore ha fino a 6 posti", best.size() == mini(6, team_r["characters"].size()))
	_check("i piu' rari vengono prima (Kira e' leggendaria)", str(best[0]) == "kira" and best.has("sera"))
	_check("e' una squadra valida", RosterState.set_team(team_r, best))

	# --- hub
	var hub: Control = load("res://scenes/hub/hub_demo.tscn").instantiate()
	var hub_roster: Dictionary = RosterState.new_roster()
	RosterState.mark_cleared(hub_roster, "distributore", 0)
	hub.roster = hub_roster
	root.add_child(hub)
	await process_frame
	_check("l hub ha i 10 pulsanti (con TEST V2)", hub.buttons.size() == 10)
	_check("CONTINUA propone la missione giusta", hub.continue_button.text.to_upper().contains("DISTRIBUTORE") and hub.continue_button.text.to_upper().contains("DIFFICILE"))
	var overflow: bool = false
	for b in hub.buttons.values():
		var rect: Rect2 = (b as Control).get_global_rect()
		rect.position -= hub.get_global_rect().position      # la schermata e' un riquadro 1280x720 centrato nello schermo
		if rect.end.y > 720.0 or rect.end.x > 1280.0:
			overflow = true
	_check("l'hub sta nella finestra senza scorrere", not overflow)

	# --- squadra: scorciatoia e avvisi
	var rs: Control = load("res://scenes/roster/roster_screen.tscn").instantiate()
	var rr: Dictionary = RosterState.new_roster()
	RosterState.add_character(rr, "sera")
	RosterState.add_character(rr, "nova")
	rs.roster = rr
	rs.save_path = TMP
	root.add_child(rs)
	await process_frame
	_check("squadra migliore schierata", rs.auto_team() and str(rr["team"][0]) == "kira")
	_check("rifarla non cambia nulla e lo dice", rs.auto_team() and rs.status_text.contains("gia'"))
	rr["coins"] = 5000
	rs.next_seed = 77
	var before: int = fb.toast_count()
	rs.pull(10)
	_check("il reclutamento avvisa dei nuovi operatori", fb.toast_count() > before)

	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
