extends SceneTree

# Il pannello impostazioni non cambia misura quando si preme un tasto (feedback degli amici su PC, 6/11/2026:
# «cliccando volume o FPS la finestra diventa piccola/diversa»). Ogni tasto ricostruiva le righe e per un fotogramma
# le vecchie (in coda di cancellazione) restavano nella griglia: altezza doppia, pannello rimpicciolito e mai piu' rimesso.
var fails: int = 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: " + msg)


func _row_button(panel: SettingsPanel, i: int) -> Button:
	var hb: Node = panel._rows.get_child(i)
	return hb.get_child(1) as Button


func _init() -> void:
	await process_frame
	root.size = Vector2i(1280, 720) # come la finestra del gioco su PC
	var panel := SettingsPanel.new()
	root.add_child(panel)
	for _i in 3:
		await process_frame
	print("viewport %s, scala %s, misura %s" % [panel.get_viewport_rect().size, panel.scale, panel.size])
	var scale0: Vector2 = panel.scale
	var size0: Vector2 = panel.size
	var rows0: int = panel._rows.get_child_count()
	check(rows0 > 0, "il pannello ha le sue righe")
	# premo piu' volte Musica (riga 0), Effetti sonori (riga 1) e Limite FPS (penultima riga)
	for idx in [0, 1, rows0 - 2, 0, rows0 - 2]:
		_row_button(panel, idx).pressed.emit()
		check(panel._rows.get_child_count() == rows0, "dopo il tasto le righe restano %d (sono %d)" % [rows0, panel._rows.get_child_count()])
		for _i in 3:
			await process_frame
		check(panel.scale.is_equal_approx(scale0), "la scala resta %s (e' %s)" % [scale0, panel.scale])
		check(absf(panel.size.y - size0.y) < 2.0, "l'altezza resta %.0f (e' %.0f)" % [size0.y, panel.size.y])
	print("settings_panel: %s" % ("OK" if fails == 0 else "%d FALLITI" % fails))
	quit(1 if fails > 0 else 0)
