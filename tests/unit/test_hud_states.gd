extends SceneTree

# Stati dell'interfaccia (0.24.35): cosa e' visibile in scelta / pericolo / risoluzione + registro delle icone.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tests/unit/test_hud_states.gd

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
	# registro: ogni simbolo ha icona disegnata, famiglia, nome e descrizione
	var ok_reg: bool = true
	for k in GameIcon.SYMBOLS.keys():
		var d: Dictionary = GameIcon.SYMBOLS[k]
		ok_reg = ok_reg and GameIcon.KEYS.has(k) and str(d.get("family", "")) != "" and str(d.get("name", "")) != "" and str(d.get("desc", "")) != ""
	_check("registro icone coerente", ok_reg)
	for k in ["hp", "balance", "danger", "ko", "shield"]:
		_check("icona %s nel registro" % k, GameIcon.SYMBOLS.has(k) and GameIcon.describe(k) != "")
	Settings.tutorial_done = true
	for touch in [false, true]:
		TouchUi.force = touch
		var tag: String = "touch" if touch else "pc"
		var s: Node = load("res://scenes/battle/battle_screen.tscn").instantiate()
		root.add_child(s)
		await create_timer(0.8).timeout
		for c in s.get_children():
			if c is TutorialOverlay:
				c.queue_free()
		await process_frame
		_check("%s: stato iniziale = scelta (o pericolo)" % tag, s.hud_mode() in ["scelta", "pericolo"])
		# pericolo: bersaglio a 5 PV
		var st: Dictionary = s.source.battle
		var tu: Dictionary = BattleState.active_unit(st, str(st["telegraph"]["target"]))
		tu["hp"] = 5
		s.source.battle_updated.emit()
		await create_timer(0.4).timeout
		_check("%s: pericolo riconosciuto" % tag, s.hud_mode() == "pericolo")
		_check("%s: pericolo: icona visibile" % tag, s._tele_icon.visible)
		_check("%s: pericolo: niente suggerimenti" % tag, not s._plan_label.visible)
		_check("%s: pericolo: testo esplicito LETALE" % tag, s._tele_target.text.begins_with("LETALE"))
		_check("%s: pericolo: l'icona non copre il nome della mossa" % tag, not s._tele_icon.get_global_rect().intersects(s._tele_label.get_global_rect().grow(-4.0)) or s._tele_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER)
		# risoluzione
		for i in 4:
			if s.locked or s.animating:
				break
			s._on_order_pressed("attack")
			await create_timer(0.3).timeout
		await create_timer(0.3).timeout
		_check("%s: risoluzione riconosciuta" % tag, s.hud_mode() == "risoluzione")
		_check("%s: risoluzione: riserva nascosta" % tag, not s._reserve_label.visible)
		_check("%s: risoluzione: ORD/COSTO nascosti" % tag, not s._tact_row.visible)
		_check("%s: risoluzione: suggerimenti nascosti" % tag, not s._plan_label.visible)
		_check("%s: risoluzione: ALLARME ancora presente" % tag, s._tele_panel.visible)
		var guard: int = 0
		while s.animating and guard < 200:
			await create_timer(0.1).timeout
			guard += 1
	print("---")
	print("PASS: %d  FAIL: %d" % [passed, failed])
	quit(1 if failed > 0 else 0)
