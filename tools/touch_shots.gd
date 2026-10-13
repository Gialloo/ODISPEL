extends SceneTree

# Immagini di tutte le schermate, anche in modalita' touch (telefono):
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/touch_shots.gd -- cartella 1
# il secondo argomento: 1 = modalita' touch, 0 = normale.

var _out: String = "user://"


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	TouchUi.force = args.size() > 1 and args[1] == "1"
	if args.size() > 2:
		var v: PackedStringArray = args[2].split(",")
		ScreenFrame.test_insets = Vector4(float(v[0]), float(v[1]), float(v[2]), float(v[3]))      # notch simulato
	_run()


func _shot(name: String) -> void:
	await create_timer(0.7).timeout
	root.get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
	print("salvata ", name)


func _show(path: String) -> Node:
	var s: Node = load(path).instantiate()
	root.add_child(s)
	return s


func _run() -> void:
	Objectives.enabled = true
	Settings.tutorial_done = true
	var s: Node = _show("res://scenes/hub/hub_demo.tscn")
	await _shot("hub")
	s.queue_free()

	s = _show("res://scenes/missions/mission_screen.tscn")
	await _shot("missioni")
	s.queue_free()

	s = _show("res://scenes/roster/roster_screen.tscn")
	await _shot("squadra")
	s.show_tab("equip")
	await _shot("equip")
	Settings.gacha_guide_seen = true
	s.show_tab("reclutamento")
	await _shot("recluta")
	var g: GachaGuide = s.open_gacha_guide()
	for i in 4:
		g.show_page(i, false)
		await _shot("guida%d" % (i + 1))
	g.queue_free()
	s.queue_free()

	s = _show("res://scenes/lobby/lobby_demo.tscn")
	await _shot("lobby")
	s.queue_free()

	s = _show("res://scenes/battle/battle_screen.tscn")
	await create_timer(0.5).timeout
	for c in s.get_children():
		if c is TutorialOverlay:
			c.queue_free()
	await _shot("battaglia")
	for i in 3:
		if not s.animating and not s.locked:
			s._on_order_pressed("attack")
	await create_timer(0.6).timeout
	await _shot("battaglia_azione")
	while s.animating:
		await create_timer(0.1).timeout
	var guard: int = 0
	while str(s.source.battle["winner"]) == "" and guard < 80:
		var c2: Dictionary = BattleAI.choose(s.source.battle, "p1")
		s.pending_swap = str(c2["swap"])
		s._on_order_pressed(str(c2["move"]))
		while s.animating:
			await create_timer(0.1).timeout
		guard += 1
	await create_timer(1.5).timeout
	await _shot("fine")
	quit(0)
