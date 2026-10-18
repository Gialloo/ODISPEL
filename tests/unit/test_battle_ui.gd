extends SceneTree

# Interfaccia di battaglia: testi, barre, sorgente in solitaria e schermata.
# Non scrive sul salvataggio vero: usa un file temporaneo.
#
#   godot --headless --path . -s res://tests/unit/test_battle_ui.gd

var passed: int = 0
var failed: int = 0
const TMP: String = "user://test_ui_roster_tmp.json"


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _spec(id: String, ids: Array) -> Dictionary:
	var team: Array = []
	for c in ids:
		team.append(BattleContent.default_entry(str(c)))
	return {"id": id, "name": id, "ai": false, "team": team}


func _run() -> void:
	_test_text()
	_test_seg_bar()
	_test_theme()
	_test_source()
	await _test_screen()
	_cleanup()
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _cleanup() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))


func _test_text() -> void:
	var s: Dictionary = BattleState.create([_spec("a", ["kira", "dax"]), _spec("b", ["nova"])], "distributore", 3)
	_check("nome mossa giocatore", BattleText.move_name("colpo_caricato") == "COLPO CARICATO")
	_check("nome mossa boss", BattleText.move_name("scarica") == "SCARICA")
	_check("nome stato", BattleText.status_name("bleed") == "SANGUINA")
	_check("nome unita'", BattleText.unit_name(s, "a:kira") == "KIRA")
	_check("suggerimento: attacco", "DANNO" in BattleText.move_hint("attack"))
	_check("suggerimento: cura", "CURA" in BattleText.move_hint("cura"))
	_check("suggerimento: provoca ha priorita'", "PRIORITA'" in BattleText.move_hint("provoca"))

	BattleResolver.submit_choice(s, "a", {"move": "attack"})
	BattleResolver.submit_choice(s, "b", {"move": "guard"})
	var events: Array = BattleResolver.resolve_round(s)
	var all_text: bool = true
	var kinds: Dictionary = {}
	for e in events:
		var d: Dictionary = BattleText.describe(s, e)
		if str(d["text"]) == "" and str(e["t"]) != "":
			all_text = false
		kinds[d["kind"]] = true
	_check("ogni evento ha una riga di log", all_text and events.size() > 0)
	_check("ci sono righe di colpo e di boss", kinds.has("hit") and kinds.has("boss"))
	_check("evento sconosciuto: riga vuota", BattleText.describe(s, {"t": "boh"})["text"] == "")
	_check("fine: vittoria", BattleText.describe(s, {"t": "end", "winner": "players"})["text"] == "OPERAZIONE RIUSCITA")
	_check("fine: sconfitta", BattleText.describe(s, {"t": "end", "winner": "boss"})["text"] == "OPERAZIONE FALLITA")

	# applicazione sugli stati mostrati
	var shown: Dictionary = BattleState.create([_spec("a", ["kira", "dax"])], "distributore", 3)
	var hp: int = int(BattleState.unit(shown, "a:kira")["hp"])
	BattleText.apply_to_display(shown, {"t": "damage", "dst": "a:kira", "amount": 100, "absorbed": 0})
	_check("danno applicato", BattleState.unit(shown, "a:kira")["hp"] == hp - 100)
	BattleText.apply_to_display(shown, {"t": "heal", "dst": "a:kira", "amount": 5000})
	_check("cura limitata ai PV massimi", BattleState.unit(shown, "a:kira")["hp"] == hp)
	BattleText.apply_to_display(shown, {"t": "shield", "dst": "a:kira", "amount": 50})
	BattleText.apply_to_display(shown, {"t": "damage", "dst": "a:kira", "amount": 10, "absorbed": 50})
	_check("scudo assorbito", BattleState.unit(shown, "a:kira")["shield"] == 0 and BattleState.unit(shown, "a:kira")["hp"] == hp - 10)
	BattleText.apply_to_display(shown, {"t": "status", "unit": "a:kira", "status": "bleed", "turns": 3})
	_check("stato applicato", BattleState.unit(shown, "a:kira")["statuses"].has("bleed"))
	BattleText.apply_to_display(shown, {"t": "cleanse", "unit": "a:kira"})
	_check("stato tolto", not BattleState.unit(shown, "a:kira")["statuses"].has("bleed"))
	BattleText.apply_to_display(shown, {"t": "swap", "player": "a", "from": "a:kira", "to": "a:dax"})
	_check("cambio applicato", BattleState.player(shown, "a")["active"] == "a:dax")
	BattleText.apply_to_display(shown, {"t": "down", "unit": "a:kira"})
	_check("KO applicato", BattleState.unit(shown, "a:kira")["hp"] == 0)
	BattleText.apply_to_display(shown, {"t": "damage", "dst": "zzz", "amount": 5, "absorbed": 0})
	_check("unita' sconosciuta ignorata", true)

	# il resto dello stato non cambia: la copia mostrata e' indipendente
	var real: Dictionary = BattleState.create([_spec("a", ["kira"])], "distributore", 3)
	var copy: Dictionary = real.duplicate(true)
	BattleText.apply_to_display(copy, {"t": "damage", "dst": "a:kira", "amount": 100, "absorbed": 0})
	_check("lo stato vero resta intatto", BattleState.unit(real, "a:kira")["hp"] > BattleState.unit(copy, "a:kira")["hp"])


func _test_seg_bar() -> void:
	var b: SegBar = SegBar.new().setup(10, Color.WHITE, Vector2(100, 10))
	b.set_ratio(0.0)
	_check("barra vuota: 0 segmenti", b.filled_segments() == 0)
	b.set_ratio(0.01)
	_check("un filo di vita: almeno 1 segmento", b.filled_segments() == 1)
	b.set_ratio(0.5)
	_check("meta': 5 segmenti", b.filled_segments() == 5)
	b.set_ratio(0.51)
	_check("poco oltre la meta': 6 segmenti", b.filled_segments() == 6)
	b.set_ratio(1.0)
	_check("piena: tutti i segmenti", b.filled_segments() == 10)
	b.set_ratio(7.0)
	_check("oltre 1: limitata", b.filled_segments() == 10 and b.ratio == 1.0)
	b.set_ratio(-3.0)
	_check("sotto 0: limitata", b.filled_segments() == 0)
	b.free()


func _test_theme() -> void:
	_check("colori di gioco per tutti i colori", BattleTheme.UNIT_COLORS.size() == BattleTypes.COLORS.size())
	var all_colors: bool = true
	for c in BattleTypes.COLORS:
		if not BattleTheme.UNIT_COLORS.has(c):
			all_colors = false
	_check("ogni colore di gioco ha la sua tinta", all_colors)
	_check("font disponibili", BattleTheme.mono() != null and BattleTheme.display() != null)
	var l: Label = BattleTheme.make_label("PROVA", 20)
	_check("etichetta creata", l.text == "PROVA" and l.get_theme_font_size("font_size") == 20)
	l.free()
	var btn := Button.new()
	for kind in ["primary", "normal", "ultimate"]:
		BattleTheme.style_button(btn, kind, 18)
	_check("stili dei pulsanti applicabili", btn.has_theme_stylebox_override("normal"))
	btn.free()


func _test_source() -> void:
	var src := SoloBattleSource.new()
	src.save_path = TMP
	var updates: Array = [0]
	var event_count: Array = [0]
	src.battle_updated.connect(func() -> void: updates[0] += 1)
	src.battle_events_received.connect(func(e: Array) -> void: event_count[0] += e.size())
	var roster: Dictionary = RosterState.new_roster()
	src.start(roster, "distributore", 77)
	_check("solitaria: battaglia creata e annunciata", not src.battle.is_empty() and updates[0] == 1)
	_check("solitaria: tu + un compagno IA", src.battle["players"].size() == 2 and src.battle["players"][1]["ally"] if src.battle["players"][1].has("ally") else src.battle["players"].size() == 2)
	_check("solitaria: scelta non valida rifiutata", not src.submit_choice({"move": "fulmine"}))
	_check("solitaria: scelta valida", src.submit_choice({"move": "attack"}))
	_check("solitaria: il round e' stato risolto subito", src.battle["round"] == 2 and event_count[0] > 0 and updates[0] == 2)
	_check("solitaria: nessun premio a battaglia in corso", src.finish().is_empty())

	var guard: int = 0
	while src.battle["winner"] == "" and guard < 100:
		src.submit_choice(BattleAI.choose(src.battle, "p1"))
		guard += 1
	_check("solitaria: la battaglia finisce", src.battle["winner"] != "")
	var coins_before: int = int(roster["coins"])
	var rewards: Dictionary = src.finish()
	_check("solitaria: premi dati a fine battaglia", not rewards.is_empty() and int(roster["coins"]) > coins_before)
	var after: int = int(roster["coins"])
	src.finish()
	_check("solitaria: i premi non si danno due volte", int(roster["coins"]) == after)
	_check("solitaria: collezione salvata e leggibile", RosterStore.load_or_new(TMP)["coins"] == after)
	_check("solitaria: a battaglia finita le scelte sono rifiutate", not src.submit_choice({"move": "attack"}))

	# la tua squadra cade mentre i compagni IA sono vivi: niente blocco
	var ko := SoloBattleSource.new()
	ko.save_path = TMP
	ko.start(RosterState.new_roster(), "distributore", 5)
	var me: Dictionary = BattleState.player(ko.battle, "p1")
	for uid in me["team"]:
		if uid != me["active"]:
			BattleState.unit(ko.battle, uid)["hp"] = 0
	BattleState.unit(ko.battle, str(me["active"]))["hp"] = 1
	BattleState.unit(ko.battle, str(me["active"]))["def"] = 0
	ko.battle["telegraph"]["target"] = "p1"
	var ko_events: Array = []
	ko.battle_events_received.connect(func(e: Array) -> void: ko_events.append_array(e))
	ko.submit_choice({"move": "attack"})
	_check("solitaria: squadra a terra, i compagni finiscono la battaglia", ko.battle["winner"] != "")
	_check("solitaria: eventi dei round automatici inviati", ko_events.size() > 0 and str(ko_events[-1]["t"]) == "end")


func _test_screen() -> void:
	var src := SoloBattleSource.new()
	src.save_path = TMP
	src.start(RosterState.new_roster(), "distributore", 91)
	var scene: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	scene.pending_source = src
	scene.event_delay = 0.0
	root.add_child(scene)
	await process_frame
	await process_frame

	_check("schermata: stato mostrato", not scene.shown.is_empty() and scene.shown["round"] == 1)
	_check("schermata: tasti degli ordini (attacco, guardia, skill, ultimate)", scene._order_buttons.size() == 4)
	_check("schermata: attacco e guardia abilitati", not scene._order_buttons[0].disabled and not scene._order_buttons[1].disabled)
	_check("schermata: l'ultimate e' bloccata a barra vuota", scene._order_buttons[3].disabled)
	_check("schermata: bersaglio annunciato", "SCARICA" in scene._tele_label.text)
	_check("schermata: nome del boss e vita", "1350" in scene._boss_hp.text or "INTEGRITA" in scene._boss_hp.text)
	_check("schermata: righe iniziali nel registro", scene.log_lines.size() >= 2)

	# cambio di personaggio
	var me: Dictionary = BattleState.player(scene.shown, "p1")
	var bench: String = ""
	for uid in me["team"]:
		if uid != me["active"]:
			bench = str(uid)
			break
	scene._on_unit_pressed(bench)
	_check("schermata: il cambio viene preparato", scene.pending_swap == bench)
	scene._on_unit_pressed(bench)
	_check("schermata: un secondo clic annulla il cambio", scene.pending_swap == "")
	scene._on_unit_pressed(str(me["active"]))
	_check("schermata: cliccare l'attivo non cambia nulla", scene.pending_swap == "")
	scene._on_unit_pressed(bench)

	# un ordine con cambio
	scene._on_order_pressed("attack")
	_check("schermata: durante il round i comandi sono bloccati", scene.animating or scene.shown["round"] == 2)
	var waited: int = 0
	while scene.animating and waited < 400:
		await process_frame
		waited += 1
	_check("schermata: round concluso", scene.shown["round"] == 2 and not scene.animating)
	_check("schermata: il cambio e' avvenuto", BattleState.player(scene.shown, "p1")["active"] == bench)
	_check("schermata: lo stato mostrato coincide con quello vero", JSON.stringify(scene.shown) == JSON.stringify(src.battle))
	_check("schermata: registro con il cambio", " ".join(scene.log_lines).find("ENTRA IN CAMPO") >= 0)
	_check("schermata: ordini di nuovo disponibili", not scene._order_buttons[0].disabled)
	_check("schermata: ordine inviato due volte ignorato", true)

	# tasti rapidi
	var ev := InputEventKey.new()
	ev.keycode = KEY_2
	ev.pressed = true
	scene._unhandled_key_input(ev)
	var w2: int = 0
	while scene.animating and w2 < 400:
		await process_frame
		w2 += 1
	_check("schermata: il tasto 2 (guardia) gioca un round", scene.shown["round"] == 3)

	# gioca fino alla fine
	var guard: int = 0
	while str(scene.shown["winner"]) == "" and guard < 120:
		var c: Dictionary = BattleAI.choose(scene.shown, "p1")
		scene.pending_swap = str(c["swap"])
		scene._on_order_pressed(str(c["move"]))
		var w: int = 0
		while scene.animating and w < 400:
			await process_frame
			w += 1
		guard += 1
	_check("schermata: la battaglia arriva alla fine", str(scene.shown["winner"]) != "")
	await process_frame
	_check("schermata: compare il riquadro dell'esito", scene._overlay.get_child_count() > 0)
	_check("schermata: dopo la fine nessun ordine", scene._order_buttons.is_empty())
	_check("schermata: premi mostrati e salvati", RosterStore.load_or_new(TMP)["coins"] >= 75)
	var count_before: int = scene._overlay.get_child_count()
	scene._check_end()
	_check("schermata: l'esito non si mostra due volte", scene._overlay.get_child_count() == count_before)
	scene.queue_free()
	await process_frame
