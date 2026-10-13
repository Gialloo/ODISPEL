extends SceneTree

# Tutorial: elenco, premio una sola volta, imprese "Studioso".
#   godot --headless --path . -s res://tests/unit/test_tutorials.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	var all: Array = Tutorials.all()
	_check("ci sono almeno 10 tutorial", all.size() >= 10)
	var ids: Dictionary = {}
	for t in all:
		ids[str(t["id"])] = true
		_check("%s: ha pagine" % t["id"], not (t["pages"] as Array).is_empty())
		_check("%s: icona valida" % t["id"], GameIcon.KEYS.has(str(t["icon"])))
		for pg in t["pages"]:
			_check("%s: pagina con testo" % t["id"], not (pg["lines"] as Array).is_empty() and str(pg["title"]) != "")
			for l in pg["lines"]:
				_check("%s: riga non vuota / glossario trovato" % t["id"], str(l["text"]) != "" and not str(l["text"]).strip_edges().is_empty())
	_check("id unici", ids.size() == all.size())
	# nessun termine del glossario mancante: la riga non deve essere solo il nome del termine
	var gl: Dictionary = {}
	for e in Lore.glossary():
		gl[str(e[0])] = true
	for t in all:
		for pg in t["pages"]:
			for l in pg["lines"]:
				var tx: String = str(l["text"])
				if gl.has(tx):
					_check("termine '%s' presente nel glossario con spiegazione" % tx, false)

	var r: Dictionary = RosterState.new_roster()
	var coins0: int = int(r["coins"])
	var gear0: int = (r["gear"] as Dictionary).size()
	_check("all'inizio nessuno fatto", Tutorials.done_count(r) == 0)
	var rw: Dictionary = Tutorials.complete(r, "basi")
	_check("premio crediti", int(r["coins"]) == coins0 + 300 and int(rw["coins"]) == 300)
	_check("premio equipaggiamento base", (r["gear"] as Dictionary).size() == gear0 + 1 and int(r["gear"][rw["gear"]]["rarity"]) == 0)
	_check("segnato come fatto", Tutorials.is_done(r, "basi") and Tutorials.done_count(r) == 1)
	_check("il premio si prende una sola volta", Tutorials.complete(r, "basi").is_empty() and int(r["coins"]) == coins0 + 300)
	_check("tutorial sconosciuto: niente", Tutorials.complete(r, "boh").is_empty())

	# imprese Studioso
	_check("impresa 'Supera 1 tutorial' pronta", Feats.can_claim(r, Feats.by_id("tutorials_1")))
	_check("impresa 3 non ancora", not Feats.can_claim(r, Feats.by_id("tutorials_3")))
	for t in all:
		Tutorials.complete(r, str(t["id"]))
	_check("tutti fatti", Tutorials.done_count(r) == Tutorials.total())
	var st: Dictionary = Feats.by_id("tutorials_all")
	_check("impresa Studioso esiste, icona epica", not st.is_empty() and str(st["reward"]["icon"]) == "e_studioso" and Profile.rarity_of("e_studioso") == 2)
	_check("Studioso pronta", Feats.can_claim(r, st))
	Profile.unlocked = []
	var got: Dictionary = Feats.claim(r, "tutorials_all")
	_check("riscossa", not got.is_empty())
	_check("l'icona non cade dai boss", Profile.EXCLUSIVE_ICONS.has("e_studioso"))
	for g in Feats.GROUPS:
		pass
	_check("gruppo TUTORIAL", Feats.GROUPS.has("TUTORIAL"))

	# salvataggio
	var tmp: String = "user://test_tutorials.json"
	_check("si salva e ricarica", RosterStore.save(r, tmp) and Tutorials.is_done(RosterStore.load_or_new(tmp), "basi"))
	if FileAccess.file_exists(ProjectSettings.globalize_path(tmp)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))

	# schermata
	await process_frame
	var scr: Control = load("res://scenes/tutorial/tutorial_screen.tscn").instantiate()
	var r2: Dictionary = RosterState.new_roster()
	scr.roster = r2
	scr.save_path = tmp
	root.add_child(scr)
	await process_frame
	await process_frame
	scr.open_tutorial("colori")
	await process_frame
	var g: GachaGuide = scr._guide
	_check("si apre la guida", g != null)
	g.show_page(1, true)
	_check("ultima pagina raggiunta", g.reached_end)
	g._close()
	await process_frame
	_check("premio dato dalla schermata", Tutorials.is_done(r2, "colori") and int(r2["coins"]) >= 300)
	scr.open_tutorial("boss")
	await process_frame
	scr._guide._close()      # chiuso subito: nessun premio
	await process_frame
	_check("chiuso a meta': nessun premio", not Tutorials.is_done(r2, "boss"))
	if FileAccess.file_exists(ProjectSettings.globalize_path(tmp)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	print("test_tutorials: %d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
