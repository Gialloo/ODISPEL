extends SceneTree

# Il motore copiato dalla V2 regge una battaglia completa con i quattro protagonisti V3 contro il Distributore.

var fails: int = 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	var team: Array = []
	for id in ["ferri", "nox", "zecca", "saul"]:
		check(BattleContent.CHARACTERS.has(id), "manca il personaggio " + id)
		team.append(BattleContent.default_entry(id))
	check(BattleContent.CHARACTERS.has("kira"), "i dati V2 servono ancora alle abilita' uniche")
	var wins: int = 0
	for seed_value in range(1, 21):
		var b: Dictionary = BattleState.create_solo("IO", team, [], "distributore", seed_value)
		check(b["players"].size() == 4, "quattro in campo")
		var guard: int = 0
		while str(b["winner"]) == "" and guard < 60:
			guard += 1
			SeqRound.begin(b)
			for e in SeqRound.order(b):
				if str(b["winner"]) != "":
					break
				if bool(e["boss"]):
					SeqRound.boss_action(b)
				else:
					SeqRound.player_action(b, str(e["player"]), BattleAI.choose(b, str(e["player"])))
			SeqRound.finish(b)
		check(str(b["winner"]) != "", "la battaglia finisce (seed %d)" % seed_value)
		if str(b["winner"]) == "players":
			wins += 1
	print("vittorie IA: %d/20" % wins)
	check(wins >= 10, "il mini combattimento deve essere vincibile (vittorie %d/20)" % wins)
	# boss segreto di prova: porta esattamente al 50% e al 25%, ignora scudi e difesa, non uccide mai
	var c: Dictionary = BattleState.create_solo("IO", team, [], "osservatore", 3)
	for p in BattleState.alive_players(c):
		BattleState.active_unit(c, str(p["id"]))["shield"] = 500
	var seen50: bool = false
	var seen25: bool = false
	for i in 12:
		BattleResolver._camera_cut(c, BattleState.boss(c), [])
		for p in BattleState.alive_players(c):
			var u: Dictionary = BattleState.active_unit(c, str(p["id"]))
			check(int(u["hp"]) >= 1, "l'Osservatore non uccide")
			if int(u["hp"]) == int(floor(float(u["max_hp"]) * 0.5)):
				seen50 = true
			if int(u["hp"]) == int(floor(float(u["max_hp"]) * 0.25)):
				seen25 = true
	check(seen50 and seen25, "l'Osservatore porta al 50% e al 25% esatti")
	check(BattleState.alive_players(c).size() == 4, "dopo l'Osservatore sono tutti vivi")
	check(BrokenCam.level_for(0.9) == 0.0 and BrokenCam.level_for(0.5) > 0.0 and BrokenCam.level_for(0.25) >= 0.99, "livelli della telecamera rotta")
	print("test_v3_engine: " + ("OK" if fails == 0 else "%d errori" % fails))
	quit(1 if fails > 0 else 0)
