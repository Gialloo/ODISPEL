extends SceneTree

# Grafiche sostituibili (ArtLibrary), ritratti, copioni di dialogo, scena di dialogo,
# cut-in ed effetti fumetto.
#   godot --headless --path . -s res://tests/unit/test_art_dialogue.gd

var passed: int = 0
var failed: int = 0
const FIX: String = "user://test_art_fixture"


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _png(rel: String, w: int, h: int, col: Color) -> void:
	var path: String = ProjectSettings.globalize_path(FIX).path_join(rel)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(col)
	img.save_png(path)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame

	# --- ArtLibrary
	ArtLibrary.extra_roots = [ProjectSettings.globalize_path(FIX)]
	ArtLibrary.refresh()
	_check("senza file: nessun ritratto", ArtLibrary.portrait("dax", "angry") == null)
	var rep0: Dictionary = ArtLibrary.report()
	_check("rapporto: totale = trovati + mancanti", int(rep0["total"]) == rep0["found"].size() + rep0["missing"].size())
	_check("rapporto: gli slot sono molti", int(rep0["total"]) > 40)
	var base_found: int = rep0["found"].size()

	_png("characters/kira/neutral.png", 40, 80, Color.RED)
	_png("characters/kira/angry.png", 40, 80, Color.BLUE)
	_png("characters/kira/battle.png", 30, 60, Color.GREEN)
	_png("bosses/distributore/battle.png", 100, 100, Color.WHITE)
	_png("backgrounds/battle/layer_1.png", 64, 36, Color.BLACK)
	_png("backgrounds/battle/layer_3.png", 64, 36, Color.BLACK)
	_png("backgrounds/distributore/layer_2.png", 64, 36, Color.BLACK)
	ArtLibrary.refresh()
	_check("ritratto con espressione trovato", ArtLibrary.portrait("kira", "angry") != null)
	_check("espressione mancante ripiega su neutral", ArtLibrary.portrait("kira", "sad") != null)
	_check("espressioni diverse = immagini diverse", ArtLibrary.portrait("kira", "angry") != ArtLibrary.portrait("kira", "sad"))
	_check("personaggio senza file: null", ArtLibrary.portrait("dax", "happy") == null)
	_check("splash ripiega su neutral", ArtLibrary.splash("kira") != null)
	_check("cutin ripiega su neutral", ArtLibrary.cutin("kira") != null)
	_check("icona mancante: null", ArtLibrary.icon("dax") == null)
	_check("sprite di battaglia", ArtLibrary.battle_sprite("kira") != null)
	_check("boss in battaglia", ArtLibrary.boss_image("distributore", "battle") != null)
	_check("boss hurt mancante: null", ArtLibrary.boss_image("distributore", "hurt") == null)
	_check("ritratto boss ripiega su battle", ArtLibrary.boss_image("distributore", "portrait") != null)
	_check("strati sfondo generici (1 e 3)", ArtLibrary.background_layers("semaforo").size() == 2)
	_check("strato del boss ha la precedenza e si aggiunge", ArtLibrary.background_layers("distributore").size() == 3)
	_check("rapporto: trovati aumentati", ArtLibrary.report()["found"].size() > base_found)

	_png("characters/kira/neutral.png", 40, 80, Color.YELLOW)
	var before: Texture2D = ArtLibrary.portrait("kira", "neutral")
	ArtLibrary.refresh()
	_check("reload rilegge il disco", ArtLibrary.portrait("kira", "neutral") != before)

	# --- PortraitView
	var pv := PortraitView.new().setup("kira", "bust")
	pv.size = Vector2(300, 400)
	root.add_child(pv)
	await process_frame
	_check("PortraitView: ha grafica", pv.has_art())
	pv.set_expression("angry")
	await process_frame
	_check("PortraitView: cambia espressione", pv.expression == "angry")
	var pv2 := PortraitView.new().setup("dax", "bust")
	pv2.size = Vector2(300, 400)
	root.add_child(pv2)
	await process_frame
	_check("PortraitView: segnaposto senza grafica", not pv2.has_art())
	pv2.dimmed = true
	pv2.flip = true
	pv2.queue_redraw()
	await process_frame
	pv.queue_free()
	pv2.queue_free()

	# --- DialogueScript
	var sc: DialogueScript = DialogueScript.parse("# commento\n@bg strada\nkira [angry] L: Ciao.\ndax R: Hey.\nkira: Ancora io.\n*: Narrazione.\n> Si -> a\n> No -> b\n:a\ndax [happy]: Bene.\n@goto fine\n:b\nkira [sad]: Peccato.\n:fine\n@end")
	_check("copione valido", sc.is_valid())
	_check("copione: passi", sc.steps.size() == 10)
	_check("copione: bg", str(sc.steps[0]["type"]) == "bg" and str(sc.steps[0]["name"]) == "strada")
	_check("copione: espressione e lato", str(sc.steps[1]["expr"]) == "angry" and str(sc.steps[1]["side"]) == "L")
	_check("copione: lato R", str(sc.steps[2]["side"]) == "R")
	_check("copione: ricorda lato ed espressione", str(sc.steps[3]["side"]) == "L" and str(sc.steps[3]["expr"]) == "angry")
	_check("copione: narrazione senza ritratto", str(sc.steps[4]["speaker"]) == "")
	_check("copione: scelta con due opzioni", str(sc.steps[5]["type"]) == "choice" and sc.steps[5]["options"].size() == 2)
	_check("copione: etichette", sc.labels.has("a") and sc.labels.has("b") and sc.labels.has("fine"))
	var bad: DialogueScript = DialogueScript.parse("pippo: Boh.\nkira [furioso]: Ehi.\n@goto nulla\n@volo\nsenza due punti\n> a senza freccia")
	_check("copione errato: errori rilevati", not bad.is_valid() and bad.errors.size() >= 5)
	_check("copione vuoto non valido", not DialogueScript.parse("").is_valid())

	# --- Storie incluse
	var all_ok: bool = true
	for boss in BattleContent.BOSS_ORDER:
		for kind in ["pre", "post"]:
			var sid: String = Story.scene_id(boss, kind)
			if not StoryData.has_scene(sid) or not DialogueScript.parse(StoryData.text(sid)).is_valid():
				all_ok = false
				print("  scena non valida: ", sid)
	_check("tutte le scene incluse sono valide", all_ok)
	_check("senza schermo la storia e' disattivata", not Story.enabled())

	# --- DialogueView
	var host := Control.new()
	root.add_child(host)
	var view: DialogueView = DialogueView.play(host, "kira [angry] L: Prima riga lunga.\ndax R: Seconda.\n> Uno -> x\n> Due -> y\n:x\nkira: Scelto uno.\n@end\n:y\nkira: Scelto due.")
	var done: Array = [false]
	view.finished.connect(func() -> void: done[0] = true)
	await process_frame
	await process_frame
	_check("dialogo: parte dalla prima battuta", view.index == 0 and view.typing)
	view.advance()
	_check("dialogo: primo avanti completa il testo", not view.typing and view.index == 0)
	view.advance()
	_check("dialogo: secondo avanti passa alla riga dopo", view.index == 1)
	view.advance()
	view.advance()
	_check("dialogo: arriva alla scelta", view.index == 2)
	view.advance()
	_check("dialogo: durante la scelta 'avanti' non fa nulla", view.index == 2)
	view.choose(5)
	_check("dialogo: scelta fuori limite ignorata", view.index == 2)
	view.choose(1)
	await process_frame
	_check("dialogo: la scelta salta all'etichetta", str(view.current_step().get("text", "")) == "Scelto due.")
	view.advance()
	view.advance()
	await process_frame
	await process_frame
	_check("dialogo: segnale finished", done[0])
	_check("dialogo: si rimuove da solo", not is_instance_valid(view))

	var view2: DialogueView = DialogueView.play(host, "kira: A.\nkira: B.")
	var done2: Array = [false]
	view2.finished.connect(func() -> void: done2[0] = true)
	await process_frame
	view2.skip_all()
	await process_frame
	_check("dialogo: salta tutta la scena", done2[0])

	# --- Cut-in ed effetti fumetto
	var secs: float = CutIn.play(host, "kira", "TEMPESTA", Color.RED)
	_check("cut-in: durata positiva", secs > 0.5)
	for i in 5:
		await process_frame
	var pop: Node = ComicFx.pop(host, "-57", Vector2(300, 300), Color.RED)
	ComicFx.speed_lines(host, Vector2(300, 300), Color.WHITE, 0.2)
	ComicFx.flash(host, Color.WHITE, 0.1)
	ComicFx.caption(host, "RAFFICA", Vector2(200, 200), Color.RED)
	await process_frame
	_check("fumetto: pop creato", pop != null)
	_check("fumetto: poligono a scoppio valido", ComicFx.burst_polygon(60.0, 12, 0.3, 2).size() >= 12)
	var sb: StyleBox = SlantBox.make(Color.RED, Color.WHITE, 12.0, Color.BLACK, 3.0)
	_check("SlantBox creato", sb != null)

	# --- Stage con grafiche
	var stage_scene: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(stage_scene)
	for i in 8:
		await process_frame
	_check("battaglia con grafiche: nessun crash", is_instance_valid(stage_scene))
	stage_scene.queue_free()
	await process_frame

	# pulizia
	ArtLibrary.extra_roots = []
	ArtLibrary.refresh()
	_clean(ProjectSettings.globalize_path(FIX))

	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _clean(dir: String) -> void:
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_clean(dir.path_join(d))
	DirAccess.remove_absolute(dir)
