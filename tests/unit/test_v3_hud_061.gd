extends SceneTree

# HUD 0.61 (P0): avvisi uniti, barra del RITMO e lastra della minaccia leggono solo i dati del motore.
var fails: int = 0


func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _init() -> void:
	# P0-C: regola del BREAK + lettura di Echo in un avviso solo, senza perdere il numero della regola
	var m: String = CombatHud.merge_rule_reading("IL VERBALE", "dopo la parata perfetta: x2", "Il Verbale fa male: para perfetto, poi punisci")
	check(m == "IL VERBALE · para perfetto, poi punisci: x2", "avviso unito del Verbale (%s)" % m)
	var parts: Array = CombatHud.notice_parts(m, 48)
	check(str(parts[0]) == "IL VERBALE" and str(parts[1]) != "", "l'avviso unito si legge per intero (titolo + resto)")
	# tutti i boss: o l'avviso unito sta in una riga, o si torna ai due avvisi (stringa vuota), mai un testo tagliato
	for id in BreakRules.RULES:
		var r: Dictionary = BreakRules.RULES[id]
		var rd: String = EnemyArchetypes.reading(str(id))
		if rd == "":
			continue
		var mm: String = CombatHud.merge_rule_reading(str(r["name"]), str(r["short"]), rd)
		if mm != "":
			check(str(CombatHud.notice_parts(mm, 48)[1]) != "", "%s: l'avviso unito non perde il resto" % id)
	# P0-A: la barra legge il motore e mostra la condizione vera solo con la soglia raggiunta
	var s: Dictionary = BattleState.create_solo("IO", [BattleContent.default_entry("lance"), BattleContent.default_entry("rio")], [], "autovelox", 7)
	var rb := RitmoBar.new()
	rb.set_state(s)
	check(rb.level == Ritmo.CALMO and not rb.is_ready and rb.hint == "", "all'inizio CALMO e niente condizione")
	var r: Dictionary = Ritmo.st(s)
	r["level"] = Ritmo.ACCESO
	r["ardore"] = 52
	r["ready"] = true
	rb.set_state(s)
	check(rb.is_ready and rb.hint.begins_with("per INCANDESCENTE: "), "soglia raggiunta: dice cosa fare (%s)" % rb.hint)
	r["level"] = Ritmo.APICE
	rb.set_state(s)
	check(not rb.is_ready and rb.hint == "", "all'APICE non c'e' un livello dopo")
	rb.free()
	# P0-B: la lastra si spegne senza dati
	var tp := ThreatPlate.new()
	tp.set_threat({})
	check(not tp.visible, "lastra vuota = nascosta")
	tp.set_threat({"state": "forte", "name": "Verbale", "who": "LANCE", "kind": "singolo"})
	check(tp.visible, "lastra con la mossa = visibile")
	tp.free()
	print("test_v3_hud_061: %s" % ("OK" if fails == 0 else "%d FAIL" % fails))
	quit(1 if fails > 0 else 0)
