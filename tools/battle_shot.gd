extends SceneTree

# Genera immagini della schermata di battaglia per controllarne l'aspetto.
# Uso (serve un display, anche virtuale):
#   godot --path . --resolution 1280x720 -s res://tools/battle_shot.gd -- cartella_uscita

var _out: String = "user://"


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_run()


func _shot(name: String) -> void:
	await create_timer(0.25).timeout
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(_out.path_join(name + ".png"))
	print("salvata ", name, " ", img.get_size())


func _run() -> void:
	var scene: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.3).timeout
	if scene._tutorial != null:
		scene._tutorial.queue_free()
	await _shot("1_inizio")

	# qualche round giocato con l'IA, poi lo stato a meta' battaglia
	var guard: int = 0
	while guard < 5 and str(scene.source.battle["winner"]) == "":
		var choice: Dictionary = BattleAI.choose(scene.source.battle, "p1")
		scene.pending_swap = str(choice["swap"])
		scene._on_order_pressed(str(choice["move"]))
		while scene.animating:
			await create_timer(0.1).timeout
		guard += 1
	await _shot("2_meta")

	# cambio in preparazione: clic su un compagno in panchina
	var me: Dictionary = BattleState.player(scene.shown, "p1")
	for uid in me["team"]:
		if uid != me["active"] and BattleState.is_alive(BattleState.unit(scene.shown, uid)):
			scene._on_unit_pressed(uid)
			break
	await _shot("2b_cambio")
	scene.pending_swap = ""

	while str(scene.source.battle["winner"]) == "" and guard < 80:
		var c2: Dictionary = BattleAI.choose(scene.source.battle, "p1")
		scene.pending_swap = str(c2["swap"])
		scene._on_order_pressed(str(c2["move"]))
		while scene.animating:
			await create_timer(0.1).timeout
		await create_timer(0.05).timeout
		guard += 1
	await create_timer(1.0).timeout
	await _shot("3_fine")
	quit(0)
