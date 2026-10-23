extends SceneTree

# Schermate delle novita' 0.35 senza giocare: menu SQUADRA, minigiochi delle reazioni, attacco di squadra,
# esperienza a fine scontro, tutorial, inquadratura di lato nel vicolo.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 --rendering-driver opengl3 -s tools/v3_novita.gd -- /tmp/novita

var main: Node
var out: String = "/tmp/novita"


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("/"):
			out = str(a)
	DirAccess.make_dir_recursive_absolute(out)
	Story.save_path = "user://salvataggio_prova.cfg"
	Settings.ensure_loaded()
	Progress.reset()
	for c in Progress.CAST:
		Progress.data["lv"][c] = 7
	Progress.add_stolen("scarica", "il Frammento")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run()


func _secs(s: float) -> void:
	await create_timer(s).timeout


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png(out + "/" + name + ".png")
	print("SHOT ", name)


func _battle(args: Dictionary) -> Node:
	main.go("battle", args)
	while main.get("_busy"):
		await process_frame
	return main.current


func _run() -> void:
	await _secs(1.0)
	# 1. tutorial: la prima spiegazione
	var bt: Node = await _battle({"tutorial": true, "boss": "frammento_giallo", "visual": "frammento_giallo", "arena": "strada", "minore": true})
	await _secs(3.0)
	await _shot("01_tutorial_intro")
	# 2. minigiochi
	bt = await _battle({"boss": "frammento_giallo", "visual": "frammento_giallo", "arena": "vicolo", "minore": true})
	await _secs(1.5)
	var lay: Control = bt.get("_fx_layer")
	var saul: Dictionary = Kits.unit_of_char(bt.get("b"), "saul")
	for m in ["arrow", "hold", "mash", "beat"]:
		bt.call("_react_game", m, saul)          # come in partita: sotto il minigioco i comandi spariscono
		await _secs(0.45)
		await _shot("02_reazione_" + m)
		for g in lay.get_children():
			if g is ReactGame:
				(g as ReactGame)._finish("great")
		await _secs(0.9)
	# 3. vicolo: inquadratura di lato su chi attacca (prima finiva dietro il muro)
	var home: Dictionary = bt.get("home")
	for uid in home:
		if str(uid) != BattleState.BOSS_ID and float((home[uid] as Vector3).x) < -1.5:
			bt.call("_cam_side", home[uid], bt.get("ENEMY_POS"))
	await _secs(1.2)
	await _shot("03_vicolo_di_lato")
	# 4. attacco di squadra: rottura vicina, AUTO, foto durante la sequenza
	var b: Dictionary = bt.get("b")
	BattleState.boss(b)["balance"] = 1
	bt.call("_toggle_auto")
	var t: float = 0.0
	var shots: int = 0
	while t < 40.0 and shots < 3 and not bool(bt.get("ended")):
		await process_frame
		t += 0.016
		if bt.get("_team_on") == true:
			await _secs(0.5 + 0.6 * shots)
			await _shot("04_squadra_%d" % shots)
			shots += 1
	# 5. esperienza a fine scontro (storia: si torna all'area)
	bt = await _battle({"boss": "frammento_giallo", "visual": "frammento_giallo", "arena": "strada", "minore": true, "livello": 7,
		"ritorno": {"tipo": "area", "area": "strada", "vinto": {}, "perso": {}}})
	await _secs(1.0)
	BattleState.boss(bt.get("b"))["hp"] = 1
	bt.call("_toggle_auto")
	t = 0.0
	while not bool(bt.get("ended")) and t < 60.0:
		await _secs(0.5)
		t += 0.5
	await _secs(3.0)
	await _shot("05_esperienza")
	# 6. menu SQUADRA
	var layer := CanvasLayer.new()
	layer.layer = 50
	root.add_child(layer)
	var sm := SquadMenu.new(false, false)
	layer.add_child(sm)
	await _secs(0.5)
	await _shot("06_squadra")
	sm.set("_sel", "saul")
	sm.call("_refresh")
	await _secs(0.3)
	await _shot("07_squadra_saul")
	sm.call("_open_picker", "saul", "skill")
	await _secs(0.3)
	await _shot("08_squadra_scegli")
	quit()
