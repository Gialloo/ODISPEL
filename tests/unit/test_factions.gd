extends SceneTree

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _entry(c: String, faction: String, rarity: int) -> Dictionary:
	var e: Dictionary = BattleContent.default_entry(c)
	e["faction"] = faction
	e["rarity"] = rarity
	return e


func _state(entries: Array) -> Dictionary:
	return BattleState.create([{"id": "a", "name": "a", "ai": false, "team": entries}], "distributore", 42)


func _u(s: Dictionary, c: String) -> Dictionary:
	return BattleState.unit(s, BattleState.unit_id("a", c))


func _init() -> void:
	# nessuna fazione: statistiche invariate
	var e1: Dictionary = BattleContent.default_entry("kira")
	e1["faction"] = ""
	var e2: Dictionary = BattleContent.default_entry("dax")
	e2["faction"] = ""
	var plain: Dictionary = _state([e1, e2])
	var k: Dictionary = _u(plain, "kira")
	_check("senza fazione: nessuna aura", k["aura"].is_empty() and k["def"] == k["base"]["def"] and k["crit"] == 0)

	# LibraCorp: leggendaria (50) + 2 comuni (10+10) = +7% DIF per tutti
	var s: Dictionary = _state([_entry("kira", "libracorp", 3), _entry("dax", "libracorp", 0), _entry("elle", "libracorp", 0)])
	var d: Dictionary = _u(s, "dax")
	_check("aura somma per rarita' (+7%)", int(d["aura"]["def"]) == 70)
	_check("def ricalcolata", d["def"] == int(round(float(d["base"]["def"]) * 1.07)))

	# tetto
	var cap: Dictionary = {}
	for i in 3:
		cap[i] = 0
	_check("tetto aura", Factions.capped(9999) == Factions.AURA_CAP_PM and Factions.capped(-9999) == -Factions.AURA_CAP_PM)

	# fonte morta: l'aura sparisce
	_u(s, "kira")["hp"] = 0
	Factions.refresh(s)
	_check("fonte morta: aura 40 (10+10)... senza la leggendaria", int(_u(s, "dax")["aura"]["def"]) == 20)

	# soppressione
	var s2: Dictionary = _state([_entry("kira", "libracorp", 3), _entry("dax", "libracorp", 0)])
	Factions.suppress(s2, "libracorp", 2)
	Factions.refresh(s2)
	_check("soppressa: nessuna aura", _u(s2, "dax")["aura"].is_empty() and _u(s2, "dax")["def"] == _u(s2, "dax")["base"]["def"])
	Factions.tick(s2)
	_check("soppressione dura 2 turni", Factions.is_suppressed(s2, "libracorp"))
	Factions.tick(s2)
	Factions.refresh(s2)
	_check("soppressione finita", not Factions.is_suppressed(s2, "libracorp") and not _u(s2, "dax")["aura"].is_empty())

	# Rondini: crit additivo
	var r: Dictionary = _state([_entry("kira", "rondini", 3), _entry("dax", "rondini", 1)])
	_check("rondini: crit 7%", _u(r, "dax")["crit"] == 70)

	# Magabondi: meta' dell'aura piu' forte
	var m: Dictionary = _state([_entry("kira", "libracorp", 3), _entry("dax", "magabondi", 0)])
	_check("magabondi: meta' aura", int(_u(m, "dax")["aura"].get("def", 0)) == 25)

	# mods: aggiunta, rinnovo senza somma, scadenza
	var mm: Dictionary = _state([BattleContent.default_entry("kira")])
	var ku: Dictionary = _u(mm, "kira")
	var base_def: int = ku["base"]["def"]
	Factions.add_mod(ku, "colpito", "def", 100, 2)
	Factions.add_mod(ku, "colpito", "def", 100, 2)
	Factions.refresh(mm)
	_check("mod non si somma", ku["mods"].size() == 1 and ku["def"] == int(round(float(base_def) * 1.1)))
	Factions.tick(mm)
	_check("mod dura ancora", ku["mods"].size() == 1)
	Factions.tick(mm)
	Factions.refresh(mm)
	_check("mod scaduto", ku["mods"].is_empty() and ku["def"] == base_def)
	Factions.add_mod(ku, "debuff", "atk", -5000, 1)
	Factions.refresh(mm)
	_check("debuff limitato al minimo 10%", ku["atk"] == int(round(float(ku["base"]["atk"]) * 0.1)))

	# critico
	var c: Dictionary = _state([BattleContent.default_entry("kira")])
	var boss: Dictionary = BattleState.boss(c)
	var atk: Dictionary = _u(c, "kira")
	atk["crit"] = 0
	_check("crit 0: mai", not Factions.rolls_crit(c, atk, boss, 0))
	atk["crit"] = 1000
	_check("crit 1000: sempre", Factions.rolls_crit(c, atk, boss, 0))
	atk["crit"] = 500
	var a1: bool = Factions.rolls_crit(c, atk, boss, 3)
	_check("crit deterministico", a1 == Factions.rolls_crit(c, atk, boss, 3))
	var hits: int = 0
	for i in 400:
		if Factions.rolls_crit(c, atk, boss, i):
			hits += 1
	_check("crit 50% circa", hits > 140 and hits < 260)

	# JSON
	var back: Dictionary = BattleState.from_json(BattleState.to_json(s))
	Factions.refresh(back)
	_check("JSON: aure identiche", JSON.stringify(back["units"]) == JSON.stringify(s["units"]))

	# stile atipico: aura dimezzata (data e ricevuta), +8% ATK e +5% VEL
	var at: Dictionary = _entry("dax", "libracorp", 0)
	at["style"] = "atipico"
	var st: Dictionary = _state([_entry("kira", "libracorp", 3), at])
	var du: Dictionary = _u(st, "dax")
	_check("atipico riceve meta' aura", int(du["aura"]["def"]) == 27)
	_check("atipico: bonus personali", du["atk"] == int(round(float(du["base"]["atk"]) * 1.08)) and du["spd"] == int(round(float(du["base"]["spd"]) * 1.05)))
	_check("atipico da' meta' aura", int(_u(st, "kira")["aura"]["def"]) == 55)

	# roster: set_style e validazione anti-truffa
	var roster: Dictionary = RosterState.new_roster()
	_check("set_style con fazione accettato", RosterState.set_style(roster, "kira", "atipico") and BattleContent.style_of("kira", roster["characters"]["kira"]) == "atipico")
	_check("set_style su operatore non posseduto rifiutato", not RosterState.set_style(roster, "tana", "atipico"))
	_check("set_style stile sconosciuto rifiutato", not RosterState.set_style(roster, "kira", "boh"))
	var good: Dictionary = BattleContent.default_entry("kira")
	_check("entry normale valida", RosterState.validate_entry(good) == "")
	var cheat: Dictionary = BattleContent.default_entry("kira")
	cheat["rarity"] = 3
	_check("rarita' truccata rifiutata", RosterState.validate_entry(cheat) != "")
	cheat = BattleContent.default_entry("kira")
	cheat["faction"] = "libracorp"
	_check("fazione truccata rifiutata", RosterState.validate_entry(cheat) != "")
	cheat = BattleContent.default_entry("kira")
	cheat["style"] = "boh"
	_check("stile non valido rifiutato", RosterState.validate_entry(cheat) != "")

	# guida alle strategie: ogni classe e ogni fazione e' spiegata
	var complete: bool = true
	for cls in BattleTypes.CLASSES:
		var ct: Dictionary = StrategyInfo.class_text(cls)
		complete = complete and not ct.is_empty() and not (ct["needs"] as Array).is_empty()
	for f in Factions.ORDER:
		var ft: Dictionary = StrategyInfo.faction_text(f)
		for key in ["idea", "win", "needs", "now", "soon"]:
			complete = complete and ft.has(key)
	_check("guida: tutte le classi e fazioni hanno i testi", complete)
	_check("guida: una pagina per classe, fazione e stile", StrategyInfo.pages().size() == BattleTypes.CLASSES.size() + Factions.ORDER.size() + 1)
	var host: Control = Control.new()
	root.add_child(host)
	var gd: GachaGuide = GachaGuide.open_pages(host, "PROVA", StrategyInfo.pages())
	await process_frame
	gd.show_page(2, false)
	_check("guida strategie: apre la pagina scelta", gd.page == 2)
	Settings.gacha_guide_seen = false
	gd._close()
	_check("guida strategie non tocca la guida reclutamento", not Settings.gacha_guide_seen)

	# legenda e archivio
	var lore_ok: bool = true
	for cid in BattleContent.CHARACTERS:
		var lt: Dictionary = Lore.character_text(str(cid))
		lore_ok = lore_ok and lt.has("tag") and lt.has("lore") and lt.has("tactic")
		lore_ok = lore_ok and (Lore.legend_page(str(cid))["lines"] as Array).size() >= 5
	_check("legenda: ogni operatore ha tag, lore e tattica", lore_ok)
	_check("legenda: nome nel titolo", Lore.legend_page("kira")["title"] == "KIRA")
	var fl: Dictionary = Lore.legend_page("kira")
	var fcount: int = (fl["lines"] as Array).size()
	var with_f: Dictionary = Lore.legend_page("kira", "atipico", "libracorp")
	var txt_f: String = ""
	for l in with_f["lines"]:
		txt_f += str(l["text"])
	_check("legenda: con fazione spiega fazione e stile", txt_f.contains("LIBRACORP") and txt_f.contains("ATIPICO") and fcount == (with_f["lines"] as Array).size())
	_check("glossario: pagine + un'ultima pagina per operatore", Lore.archive_pages().size() >= BattleContent.CHARACTERS.size() + 3)
	var gl_ok: bool = true
	for term in Lore.glossary():
		gl_ok = gl_ok and str(term[1]).length() > 10
	_check("glossario: tutte le voci spiegate", gl_ok)

	# fazioni assegnate e Protocollo
	var all_ok: bool = true
	for cid in BattleContent.CHARACTERS:
		var fac: String = BattleContent.faction_of(str(cid))
		all_ok = all_ok and Factions.FACTIONS.has(fac)
	_check("ogni operatore ha una fazione valida", all_ok)
	var pr: Dictionary = BattleState.create([{"id": "a", "name": "a", "ai": false, "team": [BattleContent.default_entry("dax"), BattleContent.default_entry("tana")]}], "distributore", 7)
	var dx: Dictionary = BattleState.unit(pr, "a:dax")
	var def0: int = dx["def"]
	var spd0: int = dx["spd"]
	BattleResolver._hit(pr, BattleState.boss(pr), dx, 0.5, [])
	_check("Protocollo: colpito, +5% DIF e VEL", dx["def"] > def0 and dx["spd"] > spd0 and dx["mods"].size() == 2)
	var def1: int = dx["def"]
	BattleResolver._hit(pr, BattleState.boss(pr), dx, 0.5, [])
	_check("Protocollo: non si somma nello stesso turno", dx["def"] == def1 and dx["mods"].size() == 2)
	Factions.tick(pr)
	Factions.refresh(pr)
	_check("Protocollo: dura il round dopo", dx["def"] == def1)
	Factions.tick(pr)
	Factions.refresh(pr)
	_check("Protocollo: poi scade", dx["mods"].is_empty() and dx["def"] == def0)
	var at2: Dictionary = BattleContent.default_entry("dax")
	at2["style"] = "atipico"
	var pa: Dictionary = BattleState.create([{"id": "a", "name": "a", "ai": false, "team": [at2]}], "distributore", 7)
	BattleResolver._hit(pa, BattleState.boss(pa), BattleState.unit(pa, "a:dax"), 0.5, [])
	_check("Protocollo: gli atipici non lo hanno", BattleState.unit(pa, "a:dax")["mods"].is_empty())
	var rf: Dictionary = BattleState.create([{"id": "a", "name": "a", "ai": false, "team": [BattleContent.default_entry("kira"), BattleContent.default_entry("elle")]}], "distributore", 7)
	_check("Magabondi in squadra con Rondini: aura dimezzata", int(BattleState.unit(rf, "a:elle")["aura"].get("crit", 0)) == 10 and int(BattleState.unit(rf, "a:kira")["aura"].get("crit", 0)) == 20)

	# LibraCorp: munizioni, contrattacco, colpi mirati
	var lb: Dictionary = BattleState.create([{"id": "a", "name": "a", "ai": false, "team": [BattleContent.default_entry("dax"), BattleContent.default_entry("tana")]}], "distributore", 11)
	var lbd: Dictionary = BattleState.unit(lb, "a:dax")
	_check("LibraCorp: munizioni piene", lbd["ammo"] == BattleTypes.AMMO_MAX and lbd["ammo_max"] == BattleTypes.AMMO_MAX)
	_check("LibraCorp: parte con Ricarica", BattleContent.default_entry("dax")["skills"].has("ricarica"))
	var nolib: Dictionary = BattleState.create([{"id": "a", "name": "a", "ai": false, "team": [BattleContent.default_entry("kira")]}], "distributore", 11)
	_check("Altre fazioni: niente munizioni", BattleState.unit(nolib, "a:kira")["ammo_max"] == 0)
	var ev: Array = []
	var bossu: Dictionary = BattleState.boss(lb)
	var bhp: int = bossu["hp"]
	BattleResolver._boss_act(lb, bossu, "scarica", "a", RNGState.new(), ev)
	var kinds: Array = []
	for x in ev:
		kinds.append(str(x["t"]))
	_check("Contrattacco: spende una munizione e colpisce il boss", kinds.has("counter") and lbd["ammo"] == BattleTypes.AMMO_MAX - 1 and bossu["hp"] < bhp)
	lbd["ammo"] = 0
	var before_hp: int = bossu["hp"]
	BattleResolver._boss_act(lb, bossu, "scarica", "a", RNGState.new(), [])
	_check("Senza munizioni non contrattacca", bossu["hp"] == before_hp)
	# ricarica e guardia
	lbd["ammo"] = 0
	lbd["energy"] = 2
	var ev2: Array = []
	BattleResolver._player_act(lb, lbd, "ricarica", "", ev2)
	_check("Ricarica: +3 munizioni e +1 energia", lbd["ammo"] == 3 and lbd["energy"] == 3)
	lbd["ammo"] = 0
	BattleResolver._player_act(lb, lbd, "guard", "", [])
	_check("Guardia: +1 munizione", lbd["ammo"] == 1)
	# colpi mirati
	lbd["skills"] = ["colpo_mirato", "colpo_alla_testa"]
	lbd["energy"] = 6
	lbd["ammo"] = 1
	_check("Colpo alla testa: serve 2 munizioni", BattleResolver.validate_choice(lb, "a", {"swap": "", "move": "colpo_alla_testa", "target": ""}) == "munizioni insufficienti")
	_check("Colpo mirato valido con 1 munizione", BattleResolver.validate_choice(lb, "a", {"swap": "", "move": "colpo_mirato", "target": ""}) == "")
	var plain_dmg: int = BattleResolver.calc_damage(lbd, bossu, 1.7)
	var pierce_dmg: int = BattleResolver.calc_damage(lbd, bossu, 1.7, 50)
	_check("Perforazione: piu' danno a parita' di moltiplicatore", pierce_dmg > plain_dmg)
	BattleResolver._player_act(lb, lbd, "colpo_mirato", "", [])
	_check("Colpo mirato spende la munizione", lbd["ammo"] == 0)
	var kd: Dictionary = BattleState.unit(nolib, "a:kira")
	kd["skills"] = ["ricarica"]
	_check("Ricarica senza armi rifiutata", BattleResolver.validate_choice(nolib, "a", {"swap": "", "move": "ricarica", "target": ""}) == "niente da ricaricare")
	# IA: ricarica a secco
	lbd["ammo"] = 0
	lbd["skills"] = ["ricarica"]
	lbd["energy"] = 3
	var ai_choice: Dictionary = BattleAI.choose(lb, "a")
	_check("IA: ricarica quando e' a secco", ai_choice["move"] == "ricarica" or ai_choice["swap"] != "")
	# salvataggio vecchio: la LibraCorp riceve Ricarica una volta sola
	var old: Dictionary = RosterState.new_roster()
	old["characters"]["dax"]["skills"] = ["provoca"]
	old["moves"]["ricarica"] = int(old["moves"]["ricarica"]) - 1
	old.erase("faction_sync")
	var migrated: Dictionary = RosterState.from_json(RosterState.to_json(old))
	_check("Migrazione: Dax riceve Ricarica", not migrated.is_empty() and migrated["characters"]["dax"]["skills"].has("ricarica") and RosterState.validate(migrated) == "")
	migrated["characters"]["dax"]["skills"] = ["provoca"]
	var again: Dictionary = RosterState.from_json(RosterState.to_json(migrated))
	_check("Migrazione: una volta sola", not again.is_empty() and not again["characters"]["dax"]["skills"].has("ricarica"))

	# schede informative
	var hu: Dictionary = BattleState.unit(lb, "a:dax")
	hu["ammo"] = 0
	var cards: Array = [Hints.faction_card(hu), Hints.aura_card(lb, hu), Hints.ammo_card(hu), Hints.mods_card(hu), Hints.class_card(hu)]
	for mid in BattleContent.MOVES:
		cards.append(Hints.move_card(hu, str(mid), "energia insufficiente"))
	var cards_ok: bool = true
	for cd in cards:
		cards_ok = cards_ok and str(cd["title"]) != "" and str(cd["body"]) != ""
	_check("schede: tutte con titolo e testo", cards_ok)
	_check("scheda munizioni: avvisa quando e' a secco", str(Hints.ammo_card(hu)["body"]).contains("A SECCO"))
	_check("scheda mossa: dice perche' non si puo' usare", str(Hints.move_card(hu, "colpo_mirato", "munizioni insufficienti")["body"]).contains("munizioni insufficienti"))
	_check("scheda aura: elenca chi la da'", str(Hints.aura_card(lb, hu)["body"]).contains("Tana"))
	_check("fonti aura: Tana (leggendaria) pesa piu' di Dax", Factions.aura_sources(lb, hu).size() == 2)
	var chip_host: Control = Control.new()
	root.add_child(chip_host)
	var chip: InfoChip = InfoChip.ammo(2, 3, Color.WHITE)
	chip_host.add_child(chip)
	await process_frame
	_check("chip munizioni: ha una dimensione", chip.size.x > 20.0 and chip.size.y > 10.0)
	var hc: HintCard = HintCard.show_for(chip_host, chip, Hints.ammo_card(hu))
	await process_frame
	_check("scheda: compare e poi sparisce", HintCard.current() == hc and hc.is_inside_tree())
	HintCard.hide_current()
	await process_frame
	_check("scheda: chiusa", HintCard.current() == null)
	var seen_trait: bool = false
	var pt: Dictionary = BattleState.create([{"id": "a", "name": "a", "ai": false, "team": [BattleContent.default_entry("dax")]}], "distributore", 3)
	var evs: Array = []
	BattleResolver._hit(pt, BattleState.boss(pt), BattleState.unit(pt, "a:dax"), 0.5, evs)
	for x in evs:
		seen_trait = seen_trait or str(x["t"]) == "trait"
	_check("Protocollo: emette l'evento 'trait'", seen_trait)

	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
