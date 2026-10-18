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
	print("test_v3_engine: " + ("OK" if fails == 0 else "%d errori" % fails))
	quit(1 if fails > 0 else 0)
