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
	# l'avviso nomina chi verra' colpito davvero: la previsione coincide con i colpi
	var d: Dictionary = BattleState.create_solo("IO", team, [], "osservatore", 5)
	for i in 6:
		var want: Array = []
		for pk in BattleResolver.camera_targets(d):
			want.append(str((pk["unit"] as Dictionary)["id"]))
		var ev: Array = []
		BattleResolver._camera_cut(d, BattleState.boss(d), ev)
		var got: Array = []
		for e in ev:
			if str(e.get("t", "")) == "damage":
				got.append(str(e["dst"]))
		check(want == got, "avviso dell'Osservatore: previsti %s, colpiti %s" % [want, got])
	# salvataggio a meta' area: posizione, indizi e nemici battuti tornano dopo il caricamento
	Story.save_path = "user://salvataggio_test.cfg"
	Story.new_game()
	Story.area_state = {"pos": Vector3(1, 0.14, -7), "yaw": 0.5, "clues": ["scontrino"], "defeated": ["f1"], "banter_used": {}}
	Story.save()
	Story.area_state = {}
	Story.load_game()
	check((Story.area_state.get("clues", []) as Array).has("scontrino"), "indizi salvati a meta' area")
	check(Story.area_state.get("pos", Vector3.ZERO) == Vector3(1, 0.14, -7), "posizione salvata a meta' area")
	Story.advance()
	Story.load_game()
	check(Story.area_state.is_empty(), "passando al passo dopo lo stato dell'area si azzera")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Story.save_path))
	check(BrokenCam.level_for(0.9) == 0.0 and BrokenCam.level_for(0.5) > 0.0 and BrokenCam.level_for(0.25) >= 0.99, "livelli della telecamera rotta")
	# articoli dei nemici nei messaggi di battaglia
	var b3: GDScript = load("res://scripts/v3/battle3d.gd")
	for pair in [["Semaforo", "il Semaforo"], ["Cabina", "la Cabina"], ["Specchio", "lo Specchio"], ["Orologio", "l'Orologio"],
			["L'Osservatore", "l'Osservatore"], ["Sirena", "la Sirena"], ["Scala mobile", "la Scala mobile"]]:
		check(b3.article(str(pair[0])) == str(pair[1]), "articolo: %s -> %s (non %s)" % [pair[0], pair[1], b3.article(str(pair[0]))])
	_timed_guard(team)
	print("test_v3_engine: " + ("OK" if fails == 0 else "%d errori" % fails))
	quit(1 if fails > 0 else 0)


# Guardia a tempo: stesso colpo annunciato, stesso seme. La guardia riduce il danno e carica l'ultimate,
# la parata perfetta lo riduce di piu' e contrattacca il boss. Il segnale vale per un solo colpo.
func _boss_hit(team: Array, grade: String) -> Dictionary:
	var s: Dictionary = BattleState.create_solo("IO", team, [], "distributore", 11)
	SeqRound.begin(s)
	s["telegraph"] = {"move": "scarica", "target": str(s["players"][0]["id"])}
	var u: Dictionary = BattleState.active_unit(s, str(s["players"][0]["id"]))
	u["gauge"] = 0
	var boss: Dictionary = BattleState.boss(s)
	var boss_hp: int = int(boss["hp"])
	if grade != "":
		s["timed_guard"] = grade
	var ev: Array = SeqRound.boss_action(s)
	var taken: int = 0
	var parry: bool = false
	for e in ev:
		if str(e.get("t", "")) == "damage" and str(e.get("dst", "")) == str(u["id"]):
			taken += int(e["amount"])
		if str(e.get("t", "")) == "parry":
			parry = true
	return {"taken": taken, "gauge": int(u["gauge"]), "boss_lost": boss_hp - int(boss["hp"]), "parry": parry, "left": s.has("timed_guard")}


func _timed_guard(team: Array) -> void:
	var none: Dictionary = _boss_hit(team, "")
	var good: Dictionary = _boss_hit(team, "good")
	var perf: Dictionary = _boss_hit(team, "perfect")
	check(none["taken"] > 0, "senza guardia il colpo fa danno")
	check(good["taken"] < none["taken"], "la guardia a tempo riduce il danno (%d contro %d)" % [good["taken"], none["taken"]])
	check(perf["taken"] < good["taken"], "la parata perfetta riduce piu' della guardia (%d contro %d)" % [perf["taken"], good["taken"]])
	check(good["gauge"] > none["gauge"] and perf["gauge"] > good["gauge"], "parare carica l'ultimate (%d, %d, %d)" % [none["gauge"], good["gauge"], perf["gauge"]])
	check(perf["parry"] and perf["boss_lost"] > 0, "la parata perfetta contrattacca")
	check(not good["parry"] and perf["boss_lost"] > none["boss_lost"], "solo la parata perfetta aggiunge un contrattacco")
	check(not good["left"] and not perf["left"], "il segnale della guardia vale per un solo colpo")
