extends SceneTree

# Conta gli elementi della HUD visibili in ogni stato (per confrontare prima/dopo i redesign) e salva una foto per stato.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tools/hud_count.gd -- <cartella> [touch 0/1]
# Conta: testi (Label), pulsanti, pannelli (HudPanel), barre (LineBar), icone (GameIcon) visibili e con una dimensione.
var _dir: String = "/tmp"


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_dir = args[0]
	TouchUi.force = args.size() > 1 and args[1] == "1"
	_run()


func _count(n: Node, acc: Dictionary) -> void:
	for c in n.get_children():
		if c is CanvasItem and not (c as CanvasItem).is_visible_in_tree():
			continue
		if c is Control:
			var ctl := c as Control
			var seen: bool = ctl.size.x > 2.0 and ctl.size.y > 2.0 and ctl.modulate.a > 0.3
			if seen:
				if c is Label and str((c as Label).text) != "":
					acc["testi"] += 1
					if OS.get_environment("HUD_LIST") != "":
						print("  T ", str((c as Label).text).replace("\n", " | ").left(50))
				elif c is Button:
					acc["pulsanti"] += 1
				elif c is HudPanel:
					acc["pannelli"] += 1
				elif c is LineBar:
					acc["barre"] += 1
				elif c is GameIcon:
					acc["icone"] += 1
		_count(c, acc)


func _snap(s: Node, name: String) -> void:
	var acc: Dictionary = {"testi": 0, "pulsanti": 0, "pannelli": 0, "barre": 0, "icone": 0}
	_count(s, acc)
	print("STATO %-12s testi=%d pulsanti=%d pannelli=%d barre=%d icone=%d  (totale %d)" % [name, acc["testi"], acc["pulsanti"], acc["pannelli"], acc["barre"], acc["icone"], int(acc["testi"]) + int(acc["pulsanti"]) + int(acc["pannelli"]) + int(acc["barre"]) + int(acc["icone"])])
	root.get_viewport().get_texture().get_image().save_png(_dir.path_join("hud_%s.png" % name))


func _run() -> void:
	Settings.tutorial_done = true
	var s: Node = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(s)
	await create_timer(0.9).timeout
	for c in s.get_children():
		if c is TutorialOverlay:
			c.queue_free()
	if s.get("_coach") != null and is_instance_valid(s.get("_coach")):
		(s.get("_coach") as Node).queue_free()
	await create_timer(0.3).timeout
	_snap(s, "scelta")
	# pericolo: il colpo annunciato e' letale per l'operatore bersaglio
	var st: Dictionary = s.source.battle
	var tele: Dictionary = st["telegraph"]
	var tu: Dictionary = BattleState.active_unit(st, str(tele["target"]))
	if not tu.is_empty():
		tu["hp"] = 5
		s.source.battle_updated.emit()
		await create_timer(0.5).timeout
	_snap(s, "pericolo")
	# risoluzione: si sceglie e si guarda a meta' animazione
	for i in 4:
		if s.locked or s.animating:
			break
		s._on_order_pressed("attack")
		await create_timer(0.3).timeout
	await create_timer(0.4).timeout
	_snap(s, "risoluzione")
	while s.animating:
		await create_timer(0.1).timeout
	await create_timer(0.6).timeout
	quit()
