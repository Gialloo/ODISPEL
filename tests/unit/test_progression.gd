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
	_test_gear()
	_test_level_up()
	_test_rewards()
	_test_apply_rewards()
	_test_persistence()
	_test_in_battle()
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _test_gear() -> void:
	var r: Dictionary = _full()
	_check("nuova collezione senza pezzi", r["gear"].is_empty() and r["materials"].is_empty())
	var a: String = RosterState.new_gear(r, "arma", 1)
	var b: String = RosterState.new_gear(r, "arma", 2)
	var c: String = RosterState.new_gear(r, "petto", 0)
	_check("id dei pezzi unici", a == "g1" and b == "g2" and c == "g3")
	_check("slot sconosciuto rifiutato", RosterState.new_gear(r, "elmo", 0) == "")
	_check("rarita' inesistente rifiutata", RosterState.new_gear(r, "arma", 9) == "")
	_check("livello oltre il massimo della rarita' rifiutato", RosterState.new_gear(r, "arma", 0, 11) == "")

	_check("equipaggiare un pezzo", RosterState.equip_gear(r, "kira", a))
	_check("il pezzo compare nei dati del personaggio", r["characters"]["kira"]["gear"].size() == 1 and r["characters"]["kira"]["gear"][0]["id"] == a)
	_check("pezzo inesistente rifiutato", not RosterState.equip_gear(r, "kira", "g99"))
	_check("personaggio inesistente rifiutato", not RosterState.equip_gear(r, "drago", a))

	_check("stesso slot: il nuovo sostituisce il vecchio", RosterState.equip_gear(r, "kira", b))
	_check("solo il nuovo e' equipaggiato", r["characters"]["kira"]["gear"].size() == 1 and r["characters"]["kira"]["gear"][0]["id"] == b and r["gear"][a]["equipped_by"] == "")
	_check("slot diversi si sommano", RosterState.equip_gear(r, "kira", c) and r["characters"]["kira"]["gear"].size() == 2)

	_check("un pezzo passa da un personaggio all'altro", RosterState.equip_gear(r, "dax", b))
	_check("e sparisce dal precedente", r["characters"]["kira"]["gear"].size() == 1 and r["characters"]["dax"]["gear"].size() == 1)
	_check("toglierlo lo riporta in inventario", RosterState.unequip_gear(r, b) and r["characters"]["dax"]["gear"].is_empty() and r["gear"][b]["equipped_by"] == "")
	_check("collezione valida", RosterState.validate(r) == "")

	# le statistiche in battaglia crescono
	var base: Dictionary = BattleContent.compute_stats(BattleContent.default_entry("kira"))
	var geared: Dictionary = BattleContent.compute_stats(r["characters"]["kira"])
	_check("il pezzo equipaggiato aumenta le statistiche", geared["hp"] > base["hp"])

	# collezione truccata
	var bad: Dictionary = r.duplicate(true)
	bad["gear"][a]["equipped_by"] = "kira"
	bad["gear"][c]["equipped_by"] = "kira"
	bad["gear"][b]["equipped_by"] = "kira"
	_check("due pezzi nello stesso slot: non valida", RosterState.validate(bad) != "")
	bad = r.duplicate(true)
	bad["gear"][a]["level"] = 50
	_check("pezzo oltre il livello massimo: non valida", RosterState.validate(bad) != "")
	bad = r.duplicate(true)
	bad["coins"] = -5
	_check("monete negative: non valida", RosterState.validate(bad) != "")
	bad = r.duplicate(true)
	bad["materials"]["oro"] = 3
	_check("materiale sconosciuto: non valida", RosterState.validate(bad) != "")


func _test_level_up() -> void:
	var r: Dictionary = _full()
	_check("senza monete e materiali non si sale", RosterState.level_up_character(r, "kira") == "monete")
	r["coins"] = 1000
	_check("senza nucleo non si sale", RosterState.level_up_character(r, "kira") == "nucleo")
	r["materials"]["nucleo"] = 5
	var cost: Dictionary = BattleContent.character_upgrade_cost(1)
	_check("livello salito", RosterState.level_up_character(r, "kira") == "" and r["characters"]["kira"]["level"] == 2)
	_check("il costo viene pagato", r["coins"] == 1000 - int(cost["coins"]) and r["materials"]["nucleo"] == 5 - int(cost["nucleo"]))
	_check("il livello aumenta le statistiche", BattleContent.compute_stats(r["characters"]["kira"])["hp"] > BattleContent.compute_stats(BattleContent.default_entry("kira"))["hp"])
	_check("personaggio sconosciuto", RosterState.level_up_character(r, "drago") == "sconosciuto")
	r["characters"]["dax"]["level"] = RosterState.MAX_LEVEL
	_check("livello massimo", RosterState.level_up_character(r, "dax") == "max")
	_check("i costi crescono col livello", int(BattleContent.character_upgrade_cost(20)["coins"]) > int(BattleContent.character_upgrade_cost(2)["coins"]) and int(BattleContent.character_upgrade_cost(30)["nucleo"]) > int(BattleContent.character_upgrade_cost(1)["nucleo"]))

	var g: String = RosterState.new_gear(r, "arma", 2)
	RosterState.equip_gear(r, "kira", g)
	r["coins"] = 5000
	r["materials"] = {}
	_check("senza lega non si potenzia il pezzo", RosterState.level_up_gear(r, g) == "lega")
	r["materials"]["lega"] = 10
	_check("pezzo potenziato", RosterState.level_up_gear(r, g) == "" and r["gear"][g]["level"] == 2)
	_check("il personaggio vede il pezzo potenziato", r["characters"]["kira"]["gear"][0]["level"] == 2)
	r["gear"][g]["level"] = int(BattleContent.GEAR_MAX_LEVEL[2])
	_check("pezzo al massimo", RosterState.level_up_gear(r, g) == "max")
	_check("pezzo sconosciuto", RosterState.level_up_gear(r, "g99") == "sconosciuto")
	_check("i pezzi rari costano di piu'", int(BattleContent.gear_upgrade_cost(3, 5)["coins"]) > int(BattleContent.gear_upgrade_cost(0, 5)["coins"]))
	_check("collezione valida dopo i potenziamenti", RosterState.validate(r) == "")


func _test_rewards() -> void:
	var win: Dictionary = BattleRewards.for_player("distributore", 123, 0, true)
	_check("la vittoria da' monete e materiali", win["coins"] == 600 and win["materials"].size() > 0)
	_check("la vittoria da' mosse o passive", win["drops"].size() >= 2)
	_check("premi deterministici", BattleRewards.for_player("distributore", 123, 0, true) == win)
	_check("giocatori diversi, premi diversi", BattleRewards.for_player("distributore", 123, 1, true) != win or BattleRewards.for_player("distributore", 123, 2, true) != win)
	var lose: Dictionary = BattleRewards.for_player("distributore", 123, 0, false)
	_check("la sconfitta da' solo un po' di monete", lose["coins"] == 200 and lose["materials"].is_empty() and lose["drops"].is_empty())
	_check("boss sconosciuto: nessun premio", BattleRewards.for_player("drago", 1, 0, true)["coins"] == 0)

	var gear_seen: bool = false
	var in_range: bool = true
	for i in 200:
		var rw: Dictionary = BattleRewards.for_player("distributore", 1000 + i, 0, true)
		for d in rw["drops"]:
			if d["kind"] == "gear":
				gear_seen = true
				if not BattleContent.GEAR_BASE.has(d["slot"]) or d["rarity"] < 0 or d["rarity"] > 3:
					in_range = false
		var n: int = int(rw["materials"].get("nucleo", 0))
		if n < 4 or n > 8:
			in_range = false
	_check("ogni tanto il boss lascia un pezzo", gear_seen)
	_check("pezzi e materiali nei limiti", in_range)

	var s: Dictionary = BattleState.create([{"id": "a", "name": "A", "ai": false, "team": [BattleContent.default_entry("kira")]}, {"id": "b", "name": "B", "ai": false, "team": [BattleContent.default_entry("nova")]}], "distributore", 5)
	_check("niente premi a battaglia in corso", BattleRewards.for_battle(s, "distributore", 5).is_empty())
	s["winner"] = "players"
	var all: Dictionary = BattleRewards.for_battle(s, "distributore", 5)
	_check("premi per ogni giocatore", all.size() == 2 and all["a"]["coins"] == 600 and all["b"]["coins"] == 600)
	s["winner"] = "boss"
	_check("sconfitta: premio ridotto", BattleRewards.for_battle(s, "distributore", 5)["a"]["coins"] == 200)


func _test_apply_rewards() -> void:
	var r: Dictionary = _full()
	var rw: Dictionary = {"coins": 300, "materials": {"nucleo": 3, "lega": 2}, "drops": [
		{"kind": "move", "id": "cura", "rarity": 1},
		{"kind": "passive", "id": "p_atk", "rarity": 0},
		{"kind": "gear", "slot": "stivali", "rarity": 2}]}
	_check("premi applicati", RosterState.apply_rewards(r, rw) == 6)
	_check("monete e materiali aggiunti", r["coins"] == 300 and r["materials"]["nucleo"] == 3 and r["materials"]["lega"] == 2)
	_check("mossa e passiva in inventario", r["moves"]["cura"] == 2 and r["passives"]["p_atk"] == 2)
	_check("il pezzo e' nuovo e unico", r["gear"].size() == 1 and r["gear"]["g1"]["slot"] == "stivali" and r["gear"]["g1"]["rarity"] == 2)
	RosterState.apply_rewards(r, rw)
	_check("secondo premio: altro pezzo, id diverso", r["gear"].size() == 2 and r["gear"].has("g2"))
	_check("una mossa in piu' si puo' equipaggiare", RosterState.equip_skill(r, "dax", 1, "cura"))
	var junk: Dictionary = {"coins": -9, "materials": {"oro": 4, "nucleo": -1}, "drops": [{"kind": "gear", "slot": "elmo", "rarity": 0}, {"kind": "move", "id": "attack"}, "boh"]}
	var before: Dictionary = r.duplicate(true)
	_check("premi non validi ignorati", RosterState.apply_rewards(r, junk) == 0 and r == before)
	_check("collezione valida dopo i premi", RosterState.validate(r) == "")

	# una battaglia intera: i premi finiscono davvero in collezione
	var team: Array = RosterState.team_entries(r)
	var st: Dictionary = RosterState.create_solo_battle(r, "Io", "distributore", 77)
	var guard: int = 0
	while st["winner"] == "" and guard < 100:
		BattleResolver.submit_choice(st, "p1", BattleAI.choose(st, "p1"))
		BattleResolver.resolve_round(st)
		guard += 1
	var rewards: Dictionary = BattleRewards.for_battle(st, "distributore", 77)
	var coins_before: int = r["coins"]
	RosterState.apply_rewards(r, rewards["p1"])
	_check("dopo la battaglia le monete aumentano", team.size() == 3 and r["coins"] > coins_before)
	_check("collezione ancora valida", RosterState.validate(r) == "")


func _test_persistence() -> void:
	var r: Dictionary = _full()
	var g: String = RosterState.new_gear(r, "petto", 3, 4)
	RosterState.equip_gear(r, "elle", g)
	r["coins"] = 42
	r["materials"] = {"nucleo": 7, "lega": 1}
	var back: Dictionary = RosterState.from_json(RosterState.to_json(r))
	_check("pezzi e materiali sopravvivono al JSON", back == r)
	_check("interi dopo il JSON", back["gear"][g]["level"] is int and back["next_gear"] is int and back["materials"]["nucleo"] is int)
	var path: String = "user://test_prog_tmp.json"
	_check("salvataggio su disco", RosterStore.save(r, path) and RosterStore.load_or_new(path) == r)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	# salvataggio vecchio senza pezzi/materiali
	var old: Dictionary = _full()
	old.erase("materials")
	old.erase("gear")
	old.erase("next_gear")
	var loaded: Dictionary = RosterState.from_json(JSON.stringify(old))
	_check("salvataggio precedente ancora leggibile", not loaded.is_empty() and loaded["gear"].is_empty() and loaded["next_gear"] == 1)


func _test_in_battle() -> void:
	var r: Dictionary = _full()
	var a: Dictionary = RosterState.create_solo_battle(r, "Io", "distributore", 3)
	var g: String = RosterState.new_gear(r, "arma", 3, 10)
	RosterState.equip_gear(r, "kira", g)
	var b: Dictionary = RosterState.create_solo_battle(r, "Io", "distributore", 3)
	_check("arma leggendaria al massimo: ATK molto piu' alto in battaglia", BattleState.unit(b, "p1:kira")["atk"] > BattleState.unit(a, "p1:kira")["atk"] + 20)
	var s: String = RosterState.new_gear(r, "stivali", 3, 10)
	RosterState.equip_gear(r, "kira", s)
	var c: Dictionary = RosterState.create_solo_battle(r, "Io", "distributore", 3)
	_check("gli stivali aumentano la velocita'", BattleState.unit(c, "p1:kira")["spd"] > BattleState.unit(b, "p1:kira")["spd"])
	_check("la squadra con pezzi supera la validazione di rete", RosterState.validate_team(RosterState.team_entries(r)) == "")


# Collezione con i 6 personaggi originali (i test non dipendono dal roster iniziale).
func _full() -> Dictionary:
	var r: Dictionary = RosterState.new_roster()
	for id in ["kira", "dax", "elle", "bruno", "nova", "mira"]:
		RosterState.add_character(r, id) if not RosterState.owns(r, id) else null
	return r
