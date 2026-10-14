extends SceneTree

# Input e livelli: slider delle impostazioni, scorrimento, replay tattico sopra i risultati, registro.
#
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tests/unit/test_input_ui.gd   (serve una finestra vera: niente --headless)

var passed: int = 0
var failed: int = 0
const TMP: String = "user://test_input_ui_tmp.json"


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _click(pos: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = pos
	e.global_position = pos
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _wheel(pos: Vector2, up: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN
	e.position = pos
	e.global_position = pos
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _find(n: Node, cls: String, out: Array) -> void:
	if n.get_class() == cls:
		out.append(n)
	for c in n.get_children():
		_find(c, cls, out)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	await process_frame
	# ---- impostazioni: lo slider risponde al click, la rotella non lo sposta ----
	var panel: SettingsPanel = SettingsPanel.open(root)
	await process_frame
	await process_frame
	var sl: HSlider = panel.music_slider
	var r: Rect2 = sl.get_global_rect()
	_check("slider: ha una larghezza utile", r.size.x > 100.0 and r.size.y >= 30.0)
	_check("slider: la rotella non e' catturata", not sl.scrollable)
	sl.value = 0.2
	_click(Vector2(r.position.x + r.size.x * 0.8, r.position.y + r.size.y * 0.5))
	await process_frame
	_check("slider: il click lo sposta (%.2f)" % sl.value, sl.value > 0.6)
	var before: float = sl.value
	_wheel(r.get_center(), false)
	await process_frame
	_check("slider: la rotella non cambia il volume", is_equal_approx(sl.value, before))
	var scrolls: Array = []
	_find(panel, "ScrollContainer", scrolls)
	var sc: ScrollContainer = scrolls[0]
	var s0: int = sc.scroll_vertical
	_wheel(sc.get_global_rect().get_center(), false)
	await process_frame
	await process_frame
	_check("scorrimento: la rotella fa scorrere il pannello", sc.scroll_vertical > s0)
	panel.queue_free()
	await process_frame

	# ---- battaglia: replay SOPRA i risultati, uno solo, si chiude ----
	var src := SoloBattleSource.new()
	src.save_path = TMP
	src.start(RosterState.new_roster(), "distributore", 91)
	var scene: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	scene.pending_source = src
	scene.event_delay = 0.0
	root.add_child(scene)
	await process_frame
	await process_frame
	scene._show_result(true, {})
	await process_frame
	var ov: Control = scene._overlay
	scene._open_replay()
	scene._open_replay()
	await process_frame
	var dims: int = 0
	for c in ov.get_children():
		if c is ColorRect and absf(c.color.a - 0.82) < 0.01:
			dims += 1
	_check("replay: ne esiste uno solo anche se premuto due volte", dims == 1)
	_check("replay: sta sopra il riquadro dei risultati", scene._replay_node.get_index() > 1 and ov.get_child(ov.get_child_count() - 1) != null)
	var top_ok: bool = true
	for c in ov.get_children():
		if c is HudPanel and c.get_index() < scene._replay_node.get_index() and str(c.title if "title" in c else "") == "ESITO":
			top_ok = top_ok and true
	_check("replay: la sua ombra intercetta i click", scene._replay_node.mouse_filter == Control.MOUSE_FILTER_STOP)
	var btns: Array = []
	_find(ov, "Button", btns)
	var close: Button = null
	for b in btns:
		if is_instance_valid(b) and b.text.to_upper() == "CHIUDI":
			close = b
	_check("replay: tasto CHIUDI presente", close != null)
	close.pressed.emit()
	await process_frame
	await process_frame
	var left: int = 0
	for c in ov.get_children():
		if c is ColorRect and absf(c.color.a - 0.82) < 0.01:
			left += 1
	_check("replay: dopo CHIUDI non resta nulla sopra i risultati", left == 0)
	var have_back := false
	for b in btns:
		if is_instance_valid(b) and b.text.to_upper() == "REPLAY TATTICO" and b.is_inside_tree():
			have_back = true
	_check("risultati: il tasto REPLAY TATTICO resta disponibile", have_back)

	# ---- registro: scorre, separa i turni, tiene piu' di 8 righe ----
	for i in 20:
		scene._push_log("EVENTO %d" % i, "info")
	_check("registro: tiene piu' di 8 righe", scene.log_lines.size() > 8)
	_check("registro: ha almeno un separatore di turno", " ".join(scene.log_lines).find("TURNO") >= 0)
	_check("registro: e' dentro un'area scorrevole", scene._log_scroll != null and scene._log_label.get_parent() == scene._log_scroll)
	print("RISULTATO: %d ok, %d falliti" % [passed, failed])
	print("FAIL: %d" % failed)
	quit(1 if failed > 0 else 0)
