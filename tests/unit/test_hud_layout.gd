extends SceneTree

# Disposizione della HUD di battaglia (PC e telefono): niente elementi sovrapposti.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tests/unit/test_hud_layout.gd

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
		# TURNO sta sotto i tasti AUTO / velocita'
		var round_r: Rect2 = s._round_label.get_global_rect()
		_check("%s: TURNO non e' coperto da AUTO" % tag, not round_r.intersects(s._auto_button.get_global_rect().grow(-1.0)))
		_check("%s: TURNO non e' coperto dalla velocita'" % tag, not round_r.intersects(s.speed_button.get_global_rect().grow(-1.0)))
		# pannello turno: sotto TURNO, non oltre il centro
		var tp: Control = s._turn_box.get_parent()
		_check("%s: pannello turno sotto TURNO" % tag, tp.get_global_rect().position.y >= round_r.end.y - 1.0)
		_check("%s: pannello turno non arriva al blocco centrale" % tag, tp.get_global_rect().end.x <= s._tele_panel.get_global_rect().position.x + 2.0)
		# nessun nome tagliato: ogni etichetta delle righe entra nel suo spazio
		var cut: int = 0
		for line in s._turn_box.get_children():
			for l in line.get_children():
				if l is Label and l.clip_text and l.size.x > 4.0:
					var w: float = l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x
					if w > l.size.x + 3.0:
						cut += 1
		_check("%s: nomi del pannello turno interi" % tag, cut == 0)
		# avvisi: in alto a destra, sotto il blocco del boss
		Notify.toast("prova")
		await create_timer(0.3).timeout
		var fb: Node = root.get_node("Feedback")
		var tr: Rect2 = fb._toasts.get_global_rect()
		_check("%s: avvisi a destra" % tag, tr.position.x > 640.0)
		_check("%s: avvisi sotto il blocco del boss" % tag, tr.position.y >= s._boss_panel.get_global_rect().end.y - 1.0)
		# la freccia di chi sceglie non entra nel pannello turno
		var arrow: Control = s._select_arrow
		if arrow != null and arrow.visible:
			_check("%s: freccia fuori dal pannello turno" % tag, not arrow.get_global_rect().grow(-8.0).intersects(tp.get_global_rect()))
		# il ventaglio dei comandi non finisce sotto la scheda GUIDA (x >= 944) ne' fuori dallo schermo
		var fan_r: Rect2 = s._fan_anchor.get_global_rect()
		_check("%s: ventaglio comandi a sinistra della scheda GUIDA (fine a x=%d)" % [tag, int(fan_r.end.x)], fan_r.end.x - 28.0 <= 944.0 or not touch)
		_check("%s: ventaglio comandi dentro lo schermo" % tag, fan_r.position.x >= 0.0 and fan_r.end.x <= 1280.0)
		s.queue_free()
		await process_frame
		await process_frame
	# uscendo dalla battaglia gli avvisi tornano al centro
	var fb2: Node = root.get_node("Feedback")
	_check("avvisi di nuovo al centro dopo la battaglia", is_equal_approx(fb2._toasts.anchor_left, 0.5))
	# testi dei pulsanti: costo, motivo, carica
	var bs: Node = load("res://scenes/battle/battle_screen.tscn").instantiate()
	var skill: Dictionary = {"kind": "skill", "cost": 2}
	_check("nota: costo", bs._order_note(skill, "", 0, false) == "2E")
	_check("nota: manca energia", bs._order_note(skill, "energia insufficiente", 0, false) == "SERVE 2E")
	_check("nota: senza colpi", bs._order_note(skill, "munizioni insufficienti", 0, false) == "SENZA COLPI")
	_check("nota: ultimate carica", bs._order_note({"kind": "ult", "cost": 0}, "barra non piena", 40, false) == "40%")
	_check("nota: ultimate pronta", bs._order_note({"kind": "ult", "cost": 0}, "", 100, true) == "PRONTA")
	_check("nota: attacco senza costo", bs._order_note({"kind": "attack", "cost": 0}, "", 0, false) == "")
	bs.free()
	# Caption (annunci in alto): anche con le descrizioni piu' lunghe devono stare nello schermo
	TouchUi.force = true
	var longest_desc: String = ""
	for bid in Arena.BEHAVIORS:
		var d: String = "COMPORTAMENTO  //  %s\n%s" % [str(Arena.BEHAVIORS[bid]["name"]), str(Arena.BEHAVIORS[bid]["desc"])]
		if d.length() > longest_desc.length():
			longest_desc = d
	var cap: Node = ComicFx.caption(root, longest_desc, Vector2(220.0, 330.0), BattleTheme.CY, 3.0)
	await create_timer(0.5).timeout
	var cap_rect: Rect2 = (cap.get_child(0) as Control).get_global_rect()
	_check("caption lunga: dentro lo schermo (fine a x=%d)" % int(cap_rect.end.x), cap_rect.end.x <= 1280.0 and cap_rect.position.x >= 0.0)
	cap.queue_free()
	# stile dei comandi condiviso fra PvE e PvP
	var tb := Button.new()
	BattleTheme.style_move_button(tb, true, 0.0)
	_check("comando usabile: testo scuro", tb.get_theme_color("font_color") == BattleTheme.BK)
	BattleTheme.style_move_button(tb, false, 0.0)
	_check("comando spento: testo grigio", tb.get_theme_color("font_color") == BattleTheme.BTN_OFF_TEXT)
	BattleTheme.style_move_button(tb, true, 0.0, true, Vector2(62.0, 80.0))
	_check("ultimate pronta: sfondo arancio", (tb.get_theme_stylebox("normal") as SlantBox).fill == BattleTheme.IMPACT)
	tb.free()
	print("---")
	print("PASS: %d  FAIL: %d" % [passed, failed])
	quit(1 if failed > 0 else 0)
