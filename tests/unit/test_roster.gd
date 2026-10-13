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


func _init() -> void:
	_test_new_roster()
	_test_team()
	_test_equip()
	_test_drops_and_copies()
	_test_validation()
	_test_json_and_store()
	_test_solo_battle()
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _test_new_roster() -> void:
	var r: Dictionary = RosterState.new_roster()
	_check("collezione iniziale valida", RosterState.validate(r) == "")
	_check("4 personaggi di partenza", r["characters"].size() == 4 and RosterState.spare_entries(r).size() == 1)
	_check("squadra iniziale di 3", r["team"] == ["kira", "dax", "elle"])
	_check("mosse innate in inventario", r["moves"].get("colpo_caricato", 0) == 1 and r["moves"].get("spezzatutto", 0) == 1)
	_check("passive innate in inventario", r["passives"].get("p_hp", 0) == 2)
	_check("personaggio sconosciuto non aggiungibile", RosterState.add_character(r, "drago") == "")


func _test_team() -> void:
	var r: Dictionary = _full()
	_check("squadra valida", RosterState.set_team(r, ["nova", "bruno"]))
	_check("squadra salvata in ordine", r["team"] == ["nova", "bruno"])
	_check("squadra vuota rifiutata", not RosterState.set_team(r, []))
	_check("squadra da 4 rifiutata", not RosterState.set_team(r, ["kira", "dax", "elle", "nova"]))
	_check("duplicati rifiutati", not RosterState.set_team(r, ["kira", "kira"]))
	_check("personaggio non posseduto rifiutato", not RosterState.set_team(r, ["kira", "drago"]))
	_check("squadra invariata dopo un rifiuto", r["team"] == ["nova", "bruno"])
	_check("compagni IA = posseduti fuori squadra", RosterState.spare_entries(r).size() == 4)
	var small: Dictionary = _full()
	small["characters"].erase("mira")
	_check("spare non include chi non si possiede", RosterState.spare_entries(small).size() == 2)


func _test_equip() -> void:
	var r: Dictionary = _full()
	_check("seconda skill non posseduta rifiutata", not RosterState.equip_skill(r, "kira", 1, "cura"))
	RosterState.add_drop(r, {"kind": "move", "id": "marchio"})
	# marchio e' gia' posseduto da Nova (1 copia, equipaggiata): il drop ne da' una seconda
	_check("skill posseduta equipaggiabile", RosterState.equip_skill(r, "kira", 1, "marchio"))
	_check("la skill compare nei dati", r["characters"]["kira"]["skills"] == ["colpo_caricato", "marchio"])
	_check("slot oltre il limite rifiutato", not RosterState.equip_skill(r, "kira", 2, "cura"))
	_check("terza copia non esiste", not RosterState.equip_skill(r, "dax", 1, "marchio"))
	_check("skill duplicata sullo stesso personaggio rifiutata", not RosterState.equip_skill(r, "kira", 0, "marchio"))
	_check("un'ultimate non va in uno slot skill", not RosterState.equip_skill(r, "dax", 1, "spezzatutto"))
	_check("svuotare lo slot funziona", RosterState.equip_skill(r, "kira", 1, "") and r["characters"]["kira"]["skills"] == ["colpo_caricato"])
	_check("collezione ancora valida", RosterState.validate(r) == "")

	# ultimate: Kira e Nova hanno spezzatutto (2 copie, entrambe in uso)
	_check("ultimate senza copie libere rifiutata", not RosterState.equip_ult(r, "dax", "spezzatutto"))
	var r2: Dictionary = _full()
	_check("ultimate senza copia libera rifiutata", not RosterState.equip_ult(r2, "kira", "bastione"))
	RosterState.add_drop(r2, {"kind": "move", "id": "bastione"})
	_check("ultimate libera equipaggiabile", RosterState.equip_ult(r2, "kira", "bastione"))
	_check("ultimate nel posto sbagliato rifiutata", not RosterState.equip_ult(r2, "kira", "cura"))
	_check("rinascita: Elle e Mira la usano entrambe", not RosterState.equip_ult(r2, "dax", "rinascita"))
	RosterState.add_drop(r2, {"kind": "move", "id": "rinascita"})
	_check("dopo il drop si equipaggia", RosterState.equip_ult(r2, "dax", "rinascita"))
	_check("collezione ancora valida (2)", RosterState.validate(r2) == "")

	# passive
	var r3: Dictionary = _full()
	_check("seconda passiva non posseduta rifiutata", not RosterState.equip_passive(r3, "kira", 1, "p_hunter"))
	RosterState.add_drop(r3, {"kind": "passive", "id": "p_atk"})
	_check("passiva posseduta equipaggiabile", RosterState.equip_passive(r3, "dax", 1, "p_atk"))
	_check("passiva duplicata rifiutata", not RosterState.equip_passive(r3, "dax", 0, "p_atk"))
	_check("slot passiva oltre il limite", not RosterState.equip_passive(r3, "dax", 2, "p_hp"))
	_check("passiva sconosciuta rifiutata", not RosterState.equip_passive(r3, "dax", 1, "p_boh"))
	_check("collezione ancora valida (3)", RosterState.validate(r3) == "")


func _test_drops_and_copies() -> void:
	var r: Dictionary = _full()
	_check("copia: si conserva, il rank non sale da solo", RosterState.add_character(r, "kira") == "copy" and r["characters"]["kira"]["rank"] == 0 and RosterState.copies(r, "kira") == 1)
	for i in 8:
		RosterState.add_character(r, "kira")
	while RosterState.rank_up(r, "kira"):
		pass
	_check("rank massimo raggiunto spendendo le copie", r["characters"]["kira"]["rank"] == RosterState.MAX_RANK)
	_check("oltre il massimo: nessun effetto", RosterState.add_character(r, "kira") == "max" and r["characters"]["kira"]["rank"] == RosterState.MAX_RANK)
	var empty: Dictionary = _full()
	empty["characters"].erase("bruno")
	_check("nuovo personaggio aggiunto", RosterState.add_character(empty, "bruno") == "new" and RosterState.owns(empty, "bruno"))
	_check("drop sconosciuto rifiutato", not RosterState.add_drop(r, {"kind": "move", "id": "fulmine"}))
	_check("drop di un'azione base rifiutato", not RosterState.add_drop(r, {"kind": "move", "id": "attack"}))
	_check("drop con tipo errato rifiutato", not RosterState.add_drop(r, {"kind": "arma", "id": "marchio"}))
	var rng: RNGState = RNGState.new()
	rng.setup(8)
	var ok: bool = true
	for d in BattleContent.roll_drops("distributore", rng):
		ok = ok and RosterState.add_drop(r, d)
	_check("i premi del boss entrano nell'inventario", ok and RosterState.validate(r) == "")


func _test_validation() -> void:
	var e: Dictionary = BattleContent.default_entry("kira")
	_check("voce valida", RosterState.validate_entry(e) == "")
	var bad: Dictionary = e.duplicate(true)
	bad["char"] = "drago"
	_check("personaggio sconosciuto", RosterState.validate_entry(bad) != "")
	bad = e.duplicate(true)
	bad["level"] = 999
	_check("livello fuori scala", RosterState.validate_entry(bad) != "")
	bad = e.duplicate(true)
	bad["rank"] = 9
	_check("rank fuori scala", RosterState.validate_entry(bad) != "")
	bad = e.duplicate(true)
	bad["skills"] = ["colpo_caricato", "marchio", "cura"]
	_check("troppe skill", RosterState.validate_entry(bad) != "")
	bad = e.duplicate(true)
	bad["skills"] = ["spezzatutto"]
	_check("ultimate in slot skill", RosterState.validate_entry(bad) != "")
	bad = e.duplicate(true)
	bad["ult"] = "colpo_caricato"
	_check("skill in slot ultimate", RosterState.validate_entry(bad) != "")
	bad = e.duplicate(true)
	bad["passives"] = ["p_atk", "p_atk"]
	_check("passiva doppia", RosterState.validate_entry(bad) != "")
	bad = e.duplicate(true)
	bad["gear"] = [{"slot": "elmo", "rarity": 0, "level": 1}]
	_check("pezzo di slot sconosciuto", RosterState.validate_entry(bad) != "")
	bad = e.duplicate(true)
	bad["gear"] = [{"slot": "arma", "rarity": 7, "level": 1}]
	_check("pezzo con rarita' inesistente", RosterState.validate_entry(bad) != "")
	_check("squadra valida", RosterState.validate_team([e, BattleContent.default_entry("dax")]) == "")
	_check("squadra con duplicato", RosterState.validate_team([e, e]) != "")
	_check("squadra vuota", RosterState.validate_team([]) != "")
	_check("squadra da 4", RosterState.validate_team([e, BattleContent.default_entry("dax"), BattleContent.default_entry("elle"), BattleContent.default_entry("nova")]) != "")


func _test_json_and_store() -> void:
	var r: Dictionary = _full()
	RosterState.add_character(r, "kira")
	r["characters"]["dax"]["gear"] = [{"slot": "petto", "rarity": 2, "level": 3}]
	r["coins"] = 250
	var back: Dictionary = RosterState.from_json(RosterState.to_json(r))
	_check("JSON conserva la collezione", back == r)
	_check("i numeri tornano interi", back["coins"] is int and back["characters"]["kira"]["rank"] is int)
	_check("JSON rovinato rifiutato", RosterState.from_json("{ non json").is_empty())
	var broken: Dictionary = r.duplicate(true)
	broken["team"] = ["drago"]
	_check("squadra non valida rifiutata dal JSON", RosterState.from_json(RosterState.to_json(broken)).is_empty())

	var path: String = "user://test_roster_tmp.json"
	_check("salvataggio su disco", RosterStore.save(r, path))
	_check("rilettura da disco", RosterStore.load_or_new(path) == r)
	_check("secondo salvataggio sovrascrive", RosterStore.save(_full(), path) and RosterStore.load_or_new(path)["coins"] == 0)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{ rovinato")
	f.close()
	_check("file rovinato: parte una collezione nuova", RosterStore.load_or_new(path) == RosterState.new_roster())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_check("file mancante: collezione nuova", RosterStore.load_or_new(path) == RosterState.new_roster())
	_check("non si salva una collezione non valida", not RosterStore.save(broken, path))


func _test_solo_battle() -> void:
	var r: Dictionary = _full()
	var s: Dictionary = RosterState.create_solo_battle(r, "Io", "distributore", 21)
	_check("solo: squadra e 2 compagni IA", s["players"].size() == 3 and s["players"][0]["team"].size() == 3)
	_check("solo: i compagni sono i personaggi fuori squadra", BattleState.unit(s, "ai1:bruno").size() > 0 and BattleState.unit(s, "ai1:nova").size() > 0 and BattleState.unit(s, "ai2:mira").size() > 0)
	var guard: int = 0
	while s["winner"] == "" and guard < 100:
		BattleResolver.submit_choice(s, "p1", BattleAI.choose(s, "p1"))
		BattleResolver.resolve_round(s)
		guard += 1
	_check("la partita solo si conclude", s["winner"] != "")

	# l'equipaggiamento influisce sulla battaglia
	var r2: Dictionary = _full()
	r2["characters"]["kira"]["gear"] = [{"slot": "arma", "rarity": 3, "level": 5}]
	var a: Dictionary = RosterState.create_solo_battle(r, "Io", "distributore", 1)
	var b: Dictionary = RosterState.create_solo_battle(r2, "Io", "distributore", 1)
	_check("l'arma aumenta l'ATK in battaglia", BattleState.unit(b, "p1:kira")["atk"] > BattleState.unit(a, "p1:kira")["atk"])
	var low: Dictionary = _full()
	low["team"] = ["kira"]
	_check("squadra da 1: gli altri 5 sono compagni IA", RosterState.create_solo_battle(low, "Io", "distributore", 1)["players"].size() == 3)


# Collezione con i 6 personaggi originali (i test non dipendono dal roster iniziale).
func _full() -> Dictionary:
	var r: Dictionary = RosterState.new_roster()
	for id in ["kira", "dax", "elle", "bruno", "nova", "mira"]:
		RosterState.add_character(r, id) if not RosterState.owns(r, id) else null
	return r
