extends SceneTree

# Dialoghi alla Persona: velocita' del testo, AUTO e REGISTRO (le battute lette restano rileggibili).
var fails: int = 0


func _chk(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _init() -> void:
	Settings.path = "user://settings_prova_registro.cfg"
	Settings.ensure_loaded()
	_run()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	var lines: Array = [
		{"chi": "ferri", "testo": "Prima."},
		{"chi": "nox", "testo": "Seconda."},
		{"chi": "saul", "testo": "Terza."},
	]
	var dlg := DialogBox.new()
	root.add_child(dlg)
	await _frames(2)
	DialogBox.history.clear()

	# ISTANTANEO: la battuta e' scritta tutta subito
	Settings.text_speed = 2
	Settings.auto_text = false
	dlg.play(lines, "riassunto")
	await _frames(1)
	_chk(dlg.call("_done"), "istantaneo: battuta scritta subito")
	_chk(DialogBox.history.size() == 1, "registro: una battuta dopo l'apertura (%d)" % DialogBox.history.size())
	_chk(str(DialogBox.history[0]["testo"]) == "Prima.", "registro: testo della prima battuta")
	_chk(str(DialogBox.history[0]["nome"]) == "LANCE", "registro: nome canonico, non l'id (%s)" % DialogBox.history[0]["nome"])

	# REGISTRO aperto: niente va avanti, i tasti lo chiudono soltanto
	dlg.open_log()
	await _frames(2)
	_chk(dlg.is_log_open(), "registro aperto")
	dlg.close_log()
	_chk(not dlg.is_log_open(), "registro chiuso")

	# NORMALE: la battuta si scrive a poco a poco
	dlg.advance()
	await _frames(1)
	Settings.text_speed = 0
	dlg.advance()
	await _frames(1)
	_chk(str(DialogBox.history[-1]["testo"]) == "Terza.", "registro: tre battute in ordine")
	_chk(dlg.is_open(), "scena ancora aperta")

	# AUTO: senza toccare, la scena finisce da sola
	Settings.auto_text = true
	var t0: int = Time.get_ticks_msec()
	while dlg.is_open() and Time.get_ticks_msec() - t0 < 8000:
		await process_frame
	_chk(not dlg.is_open(), "auto: la scena si chiude da sola")
	_chk(not dlg.is_log_open(), "chiudendo la scena si chiude anche il registro")

	# il registro tiene al massimo LOG_MAX battute
	for i in DialogBox.LOG_MAX + 10:
		DialogBox.history.append({"nome": "X", "col": "ffffff", "testo": str(i)})
	Settings.auto_text = false
	Settings.text_speed = 2
	dlg.play([{"chi": "zecca", "testo": "Ultima."}])
	await _frames(1)
	_chk(DialogBox.history.size() == DialogBox.LOG_MAX, "registro con tetto (%d)" % DialogBox.history.size())
	_chk(str(DialogBox.history[-1]["nome"]) == "RIO", "id zecca mostrato come Rio")
	dlg.skip()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	print("test_v3_registro: " + ("OK" if fails == 0 else "%d FALLITI" % fails))
	quit(1 if fails > 0 else 0)
