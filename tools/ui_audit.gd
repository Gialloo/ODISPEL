extends SceneTree

# Controllo automatico dei tasti di ogni schermata: dentro lo schermo, non tagliati, abbastanza grandi, non sovrapposti.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/ui_audit.gd -- touch(0/1) "l,t,r,b" [cartella foto]
# Scrive "PROBLEMA: ..." per ogni difetto e "OK schermata (N tasti)" per le altre.

var problems: int = 0
var shots: String = ""


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	TouchUi.force = args.size() > 0 and args[0] == "1"
	if args.size() > 1 and args[1] != "":
		var v: PackedStringArray = args[1].split(",")
		ScreenFrame.test_insets = Vector4(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
	if args.size() > 2:
		shots = args[2]
	_run()


func _rect(c: Control) -> Rect2:
	return c.get_global_rect()


# Parte di un controllo che si vede davvero (tagliata dai ScrollContainer genitori).
func _visible_rect(c: Control) -> Rect2:
	var r: Rect2 = _rect(c)
	var n: Node = c.get_parent()
	while n != null:
		if n is ScrollContainer or (n is Control and (n as Control).clip_contents):
			r = r.intersection(_rect(n as Control))
		n = n.get_parent()
	return r


func _all_buttons(node: Node, out: Array) -> void:
	if node is BaseButton and (node as Control).is_visible_in_tree():
		out.append(node)
	for c in node.get_children():
		_all_buttons(c, out)


func _is_descendant(a: Node, b: Node) -> bool:
	return a.is_ancestor_of(b) or b.is_ancestor_of(a)


func _audit(name: String, scope: Node) -> void:
	var buttons: Array = []
	_all_buttons(scope, buttons)
	var view: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var ins: Vector4 = ScreenFrame.test_insets
	var safe: Rect2 = Rect2(Vector2(ins.x, ins.y), view.size - Vector2(ins.x + ins.z, ins.y + ins.w))
	var issues: Array = []
	var live: Array = []
	for b in buttons:
		var c: Control = b
		if c.modulate.a < 0.05 or c.get_global_rect().size == Vector2.ZERO:
			continue
		var vr: Rect2 = _visible_rect(c)
		if vr.size.x <= 1.0 or vr.size.y <= 1.0:
			continue           # fuori dall'area scorrevole: si raggiunge scorrendo
		var full: Rect2 = _rect(c)
		var label: String = (c.text if c is Button else c.name)
		if c is Button and (c as Button).text.strip_edges() == "" and c.get_child_count() == 0 and (c as Button).icon == null:
			continue           # pulsante trasparente di servizio
		# 1) fuori dallo schermo o dentro la zona del notch
		if not safe.grow(2.0).encloses(vr) and not c.has_meta("bleed"):
			if c.get_parent() is ScrollContainer or _in_scroll(c):
				pass
			else:
				issues.append("fuori dall'area sicura: '%s' %s" % [label, str(full)])
		# 2) testo tagliato
		if c is Button and not (c as Button).clip_text and (c as Button).text != "":
			var need: float = c.get_minimum_size().x
			if need > c.size.x + 3.0 and (c as Button).text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING:
				issues.append("testo piu' largo del tasto: '%s' (serve %d, c'e' %d)" % [label, int(need), int(c.size.x)])
		# 3) troppo piccolo per un dito (solo se touch): lato minimo 30 px nel riquadro 1280x720
		if TouchUi.force and min(full.size.x, full.size.y) < 28.0 and not (c is CheckBox):
			issues.append("tasto piccolo (%dx%d): '%s'" % [int(full.size.x), int(full.size.y), label])
		live.append(c)
	# 4) sovrapposizioni tra tasti (ignora genitore/figlio)
	for i in live.size():
		for j in range(i + 1, live.size()):
			var a: Control = live[i]
			var b: Control = live[j]
			if _is_descendant(a, b):
				continue
			var ra: Rect2 = _visible_rect(a)
			var rb: Rect2 = _visible_rect(b)
			var inter: Rect2 = ra.intersection(rb)
			if inter.size.x <= 0 or inter.size.y <= 0:
				continue
			var small: float = minf(ra.get_area(), rb.get_area())
			if small > 0.0 and inter.get_area() / small > 0.25:
				issues.append("tasti sovrapposti: '%s' e '%s'" % [_name(a), _name(b)])
	if issues.is_empty():
		print("OK %s (%d tasti)" % [name, live.size()])
	else:
		for s in issues:
			problems += 1
			print("PROBLEMA [%s]: %s" % [name, s])


func _name(c: Control) -> String:
	if c is Button and (c as Button).text != "":
		return (c as Button).text
	return str(c.name)


func _in_scroll(c: Node) -> bool:
	var n: Node = c.get_parent()
	while n != null:
		if n is ScrollContainer:
			return true
		n = n.get_parent()
	return false


func _shot(name: String) -> void:
	if shots == "":
		return
	root.get_viewport().get_texture().get_image().save_png(shots.path_join(name + ".png"))


func _show(path: String) -> Node:
	var s: Node = load(path).instantiate()
	root.add_child(s)
	await create_timer(0.9).timeout
	return s


func _run() -> void:
	Objectives.enabled = true
	Settings.tutorial_done = true
	Settings.gacha_guide_seen = true
	Profile.ensure_loaded()
	Profile.unlocked = ["l_striker", "e_kairos", "r_burst"]

	var s: Node = await _show("res://scenes/hub/hub_demo.tscn")
	_audit("hub", s)
	_shot("hub")
	var p: Node = SettingsPanel.open(s)
	await create_timer(0.5).timeout
	_audit("impostazioni", p)
	_shot("impostazioni")
	var ng: ConfirmBox = NewGame.ask(p)
	await create_timer(0.4).timeout
	_audit("nuovo gioco", ng)
	ng.queue_free()
	p.queue_free()
	var pp: Node = ProfilePanel.open(s)
	await create_timer(0.5).timeout
	_audit("profilo", pp)
	_shot("profilo")
	pp.queue_free()
	var ex: ConfirmBox = ExitGuard.ask(s)
	await create_timer(0.4).timeout
	_audit("vuoi uscire", ex)
	_shot("uscita")
	ex.queue_free()
	s.queue_free()

	s = await _show("res://scenes/missions/mission_screen.tscn")
	_audit("missioni", s)
	_shot("missioni")
	s.queue_free()

	s = await _show("res://scenes/feats/feats_screen.tscn")
	_audit("obiettivi", s)
	_shot("obiettivi")
	s.queue_free()

	s = await _show("res://scenes/tutorial/tutorial_screen.tscn")
	_audit("tutorial", s)
	_shot("tutorial")
	s.queue_free()

	s = await _show("res://scenes/roster/roster_screen.tscn")
	_audit("squadra", s)
	_shot("squadra")
	s.show_tab("equip")
	await create_timer(0.5).timeout
	_audit("equip", s)
	_shot("equip")
	s.show_tab("reclutamento")
	await create_timer(0.5).timeout
	_audit("reclutamento", s)
	_shot("reclutamento")
	var g: GachaGuide = s.open_gacha_guide()
	for i in 4:
		g.show_page(i, false)
		await create_timer(0.4).timeout
		_audit("guida %d" % (i + 1), g)
	g.queue_free()
	s.queue_free()

	s = await _show("res://scenes/lobby/lobby_demo.tscn")
	_audit("lobby (modulo)", s)
	_shot("lobby")
	s.queue_free()

	s = await _show("res://scenes/battle/battle_screen.tscn")
	for c in s.get_children():
		if c is TutorialOverlay:
			c.queue_free()
	await create_timer(0.5).timeout
	_audit("battaglia", s)
	_shot("battaglia")
	s._open_pause()
	await create_timer(0.5).timeout
	_audit("pausa", s._pause)
	_shot("pausa")
	s._pause.queue_free()
	s._pause = null
	# una battaglia intera fino ai premi
	var guard: int = 0
	while str(s.source.battle["winner"]) == "" and guard < 90:
		while s.animating:
			await create_timer(0.1).timeout
		var c2: Dictionary = BattleAI.choose(s.source.battle, "p1")
		s.pending_swap = str(c2["swap"])
		s._on_order_pressed(str(c2["move"]))
		guard += 1
		await create_timer(0.05).timeout
	while s.animating:
		await create_timer(0.1).timeout
	await create_timer(1.5).timeout
	_audit("risultato battaglia", s)
	_shot("risultato")
	s.queue_free()

	print("TOTALE PROBLEMI: %d" % problems)
	quit()
