extends SceneTree

# Screenshot dei chip e delle schede informative in battaglia.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/hint_shots.gd -- cartella [1 = touch]


func _shot(dir: String, name: String) -> void:
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])


func _find_chip(node: Node, pred: Callable) -> InfoChip:
	if node is InfoChip and pred.call(node):
		return node
	for c in node.get_children():
		var r: InfoChip = _find_chip(c, pred)
		if r != null:
			return r
	return null


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "/tmp"
	TouchUi.force = args.size() > 1 and args[1] == "1"
	Settings.tutorial_done = true
	var scene: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.4).timeout
	await _shot(dir, "h1_hud")
	# due round per far scattare contrattacco e Protocollo
	for i in 2:
		var choice: Dictionary = BattleAI.choose(scene.source.battle, "p1")
		scene._on_order_pressed(str(choice["move"]))
		while scene.animating:
			await create_timer(0.1).timeout
	await _shot(dir, "h2_dopo")
	var ammo: InfoChip = _find_chip(scene, func(c): return c.kind == "ammo")
	if ammo != null:
		HintCard.show_for(scene, ammo, Hints.ammo_card(scene.shown["units"][scene.shown["players"][0]["team"][0]]))
		await _shot(dir, "h3_munizioni")
	var aura: InfoChip = _find_chip(scene, func(c): return c.kind == "text" and c.text.find("%") >= 0)
	if aura != null:
		var uid: String = str(scene.shown["players"][0]["team"][0])
		HintCard.show_for(scene, aura, Hints.aura_card(scene.shown, scene.shown["units"][uid]))
		await _shot(dir, "h4_aura")
	var btn: Button = scene._order_buttons[2] if scene._order_buttons.size() > 2 else null
	if btn != null:
		var u: Dictionary = BattleState.active_unit(scene.shown, "p1")
		HintCard.show_for(scene, btn, Hints.move_card(u, "ricarica", ""))
		await _shot(dir, "h5_mossa")
	quit()
