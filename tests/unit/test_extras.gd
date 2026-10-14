extends SceneTree

# Maestria che si salva, rientro, boss che impara, premio sfida, addestramento.
#   godot --headless --path . -s res://tests/unit/test_extras.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _spec(id: String) -> Dictionary:
	return {"id": id, "name": id, "ai": false, "team": [BattleContent.default_entry("kira"), BattleContent.default_entry("dax"), BattleContent.default_entry("elle")]}


func _init() -> void:
	# --- maestria
	var roster: Dictionary = RosterState.new_roster()
	_check("nessuna maestria", Extras.levels_for(roster, "kira").is_empty())
	var lines: Array = Extras.record_mastery(roster, {"uses": {"kira": {"attack": 24}}})
	_check("24 usi: ancora livello 0", lines.is_empty() and Extras.levels_for(roster, "kira").is_empty())
	lines = Extras.record_mastery(roster, {"uses": {"kira": {"attack": 1}}})
	_check("25 usi: livello 1 annunciato", lines.size() == 1 and int(Extras.levels_for(roster, "kira")["attack"]) == 1)
	Extras.record_mastery(roster, {"uses": {"kira": {"attack": 500}}})
	_check("tetto al livello 3", int(Extras.levels_for(roster, "kira")["attack"]) == Extras.MASTERY_MAX)
	_check("operatore non posseduto ignorato", Extras.record_mastery(roster, {"uses": {"tana": {"attack": 99}}}).is_empty() and Extras.levels_for(roster, "tana").is_empty())
	var team: Array = RosterState.team_entries(roster)
	var kira_e: Dictionary = {}
	for e in team:
		if str(e["char"]) == "kira":
			kira_e = e
	_check("la scheda porta la maestria", kira_e.has("mastery") and int(kira_e["mastery"]["attack"]) == 3)
	_check("scheda valida", RosterState.validate_team(team) == "")
	var st: Dictionary = BattleState.create([{"id": "a", "name": "a", "ai": false, "team": [kira_e]}], "distributore", 3)
	_check("l'unita' in battaglia ha la maestria", int(BattleState.unit(st, "a:kira")["mastery"]["attack"]) == 3 and Tactics.mastery_mult(BattleState.unit(st, "a:kira"), "attack") > 1.1)
	var bad: Dictionary = BattleContent.default_entry("kira")
	bad["mastery"] = {"attack": 99}
	_check("maestria assurda rifiutata", RosterState.validate_entry(bad) != "")
	bad["mastery"] = 4
	_check("maestria non dizionario rifiutata", RosterState.validate_entry(bad) != "")
	var tmp: String = "user://test_extras.json"
	RosterStore.save(roster, tmp)
	var loaded: Dictionary = RosterStore.load_or_new(tmp)
	_check("maestria salvata", int(Extras.levels_for(loaded, "kira")["attack"]) == 3)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))

	# --- rientro dopo 3 sconfitte
	var r2: Dictionary = RosterState.new_roster()
	_check("all'inizio nessun rientro", not Extras.comeback_ready(r2))
	Extras.record_result(r2, false)
	Extras.record_result(r2, false)
	_check("2 sconfitte: ancora no", not Extras.comeback_ready(r2))
	Extras.record_result(r2, false)
	_check("3 sconfitte: rientro pronto", Extras.comeback_ready(r2) and Extras.losses(r2) == 3)
	var s1: Dictionary = BattleState.create([_spec("a")], "distributore", 4)
	var res0: int = int(s1["reserve"])
	var sh0: int = int(BattleState.unit(s1, "a:kira")["shield"])
	Extras.apply_comeback(s1)
	_check("rientro: Riserva e scudo", int(s1["reserve"]) == res0 + Extras.COMEBACK_RESERVE and int(BattleState.unit(s1, "a:kira")["shield"]) > sh0 and int(s1["comeback"]) == 1)
	_check("il boss non prende lo scudo", int(BattleState.boss(s1)["shield"]) == 0)
	Extras.record_result(r2, true)
	_check("una vittoria azzera la serie", Extras.losses(r2) == 0 and not Extras.comeback_ready(r2))

	# --- il boss impara
	var r3: Dictionary = RosterState.new_roster()
	_check("boss mai battuto: niente", Extras.style_vs(r3, "distributore") == "")
	Extras.remember(r3, "distributore", false, {"synergies": 9})
	_check("sconfitta: niente da imparare", Extras.style_vs(r3, "distributore") == "")
	Extras.remember(r3, "distributore", true, {})
	_check("stile non chiaro: niente", Extras.style_vs(r3, "distributore") == "")
	Extras.remember(r3, "distributore", true, {"synergies": 5})
	_check("stile ricordato", Extras.style_vs(r3, "distributore") == "COORDINATO")
	var s2: Dictionary = BattleState.create([_spec("a")], "distributore", 5)
	var def0: int = int(BattleState.boss(s2)["def"])
	var txt: String = Extras.apply_learned(s2, "COORDINATO")
	_check("contromisura: difesa su e annuncio", int(BattleState.boss(s2)["def"]) > def0 and txt.contains("SINERGIE") and str(s2["learned"]["style"]) == "COORDINATO")
	var s3: Dictionary = BattleState.create([_spec("a")], "distributore", 5)
	var atk0: int = int(BattleState.boss(s3)["atk"])
	Extras.apply_learned(s3, "DIFENSIVO")
	_check("difensivo: attacco su", int(BattleState.boss(s3)["atk"]) > atk0)
	var s4: Dictionary = BattleState.create([_spec("a")], "distributore", 5)
	var bal0: int = int(BattleState.boss(s4)["balance_max"])
	Extras.apply_learned(s4, "INCISIVO")
	_check("incisivo: placca e equilibrio", int(BattleState.boss(s4)["plates"]) == 1 and int(BattleState.boss(s4)["balance_max"]) == bal0 + 1)
	_check("stile sconosciuto: niente", Extras.apply_learned(BattleState.create([_spec("a")], "distributore", 5), "boh") == "")
	_check("stato resta JSON", BattleState.to_json(s4) == BattleState.to_json(BattleState.from_json(BattleState.to_json(s4))))

	# --- premio sfida facoltativa
	var s5: Dictionary = BattleState.create([_spec("a")], "distributore", 6)
	s5["winner"] = "players"
	s5["challenge"] = {"id": "nessun_caduto"}
	s5["stats"] = {"downs": 0}
	var plain: Dictionary = BattleRewards.for_player("distributore", 6, 0, true, 0)
	var with: Dictionary = BattleRewards.for_battle(s5, "distributore", 6)["a"]
	_check("sfida riuscita: +crediti", int(with["coins"]) == int(plain["coins"]) + Tactics.CHALLENGE_COINS)
	s5["stats"] = {"downs": 2}
	var without: Dictionary = BattleRewards.for_battle(s5, "distributore", 6)["a"]
	_check("sfida fallita: premio normale", int(without["coins"]) == int(plain["coins"]))

	# --- addestramento: niente premi, niente salvataggio
	var r4: Dictionary = RosterState.new_roster()
	var coins0: int = int(r4["coins"])
	var src := SoloBattleSource.new()
	src.training = true
	src.save_path = "user://train_test.json"
	src.start(r4, "distributore", 3, 0)
	BattleState.boss(src.battle)["hp"] = 0
	BattleResolver._check_winner(src.battle, [])
	var got: Dictionary = src.finish()
	_check("addestramento: nessun premio", got.is_empty() and int(r4["coins"]) == coins0)
	_check("addestramento: nessun progresso", RosterState.cleared_tiers(r4, "distributore") == 0 and int(Feats.stats(r4).get("plays", 0)) == 0 and Extras.losses(r4) == 0)
	_check("addestramento: niente file", not FileAccess.file_exists("user://train_test.json"))
	_check("addestramento: niente rientro/imparato", not src.battle.has("comeback") and not src.battle.has("learned"))
	# battaglia vera: vince e registra tutto
	var r5: Dictionary = RosterState.new_roster()
	var real := SoloBattleSource.new()
	real.save_path = "user://train_test.json"
	real.start(r5, "distributore", 3, 0)
	BattleState.boss(real.battle)["hp"] = 0
	BattleResolver._check_winner(real.battle, [])
	real.battle["stats"] = real.battle.get("stats", {}).duplicate()
	real.battle["stats"]["uses"] = {"kira": {"attack": 30}}
	real.finish()
	_check("battaglia vera: progresso e maestria", RosterState.cleared_tiers(r5, "distributore") >= 1 and int(Extras.levels_for(r5, "kira").get("attack", 0)) == 1 and Extras.losses(r5) == 0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://train_test.json"))

	# --- codice squadra: andata e ritorno
	var entries: Array = RosterState.team_entries(RosterState.new_roster())
	var code: String = BuildCode.encode(entries)
	var back: Dictionary = BuildCode.decode(code)
	_check("codice: andata e ritorno", bool(back["ok"]) and (back["team"] as Array).size() == entries.size())
	_check("codice sbagliato rifiutato", not bool(BuildCode.decode("ciao")["ok"]))
	var scr: ExpeditionScreen = ExpeditionScreen.new()
	scr.roster = RosterState.new_roster()
	_check("importa: errore leggibile", scr.import_code("zzz").begins_with("Codice non valido"))
	_check("importa: squadra letta", scr.import_code(code).begins_with("SQUADRA:"))
	scr.free()

	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
