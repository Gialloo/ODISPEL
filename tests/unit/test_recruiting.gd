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
	_test_content()
	_test_costs()
	_test_pull()
	_test_duplicates()
	_test_guarantees()
	_test_rates()
	_test_persistence()
	_test_play_flow()
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _rich(coins: int = 100000) -> Dictionary:
	var r: Dictionary = RosterState.new_roster()
	r["coins"] = coins
	return r


func _test_content() -> void:
	_check("contenuti coerenti (con rarita')", BattleContent.validate().is_empty())
	_check("24 personaggi in totale (23 reclutabili + Nico)", BattleContent.CHARACTERS.size() == 24)
	var per_rarity: Array = [0, 0, 0, 0]
	for id in BattleContent.CHARACTERS:
		per_rarity[BattleContent.CHARACTERS[id]["rarity"]] += 1
	_check("esiste almeno un personaggio per rarita'", per_rarity.min() >= 1)
	var r: Dictionary = RosterState.new_roster()
	_check("si parte con 4 personaggi e squadra di 3", r["characters"].size() == 4 and r["team"].size() == 4)
	_check("il roster iniziale e' valido", RosterState.validate(r) == "")


func _test_costs() -> void:
	_check("costo singolo", Recruiting.cost_for(1) == 300)
	_check("costo dieci con sconto", Recruiting.cost_for(10) == 2700 and Recruiting.cost_for(10) < 10 * Recruiting.cost_for(1))
	_check("quantita' strane rifiutate", Recruiting.cost_for(0) < 0 and Recruiting.cost_for(5) < 0 and Recruiting.cost_for(-1) < 0)
	var r: Dictionary = _rich(299)
	var res: Dictionary = Recruiting.pull(r, 1, 1)
	_check("monete insufficienti: rifiutato", not res["ok"] and res["error"] == "monete" and r["coins"] == 299 and r["pulls"] == 0)
	res = Recruiting.pull(_rich(), 3, 1)
	_check("quantita' non valida: rifiutato", not res["ok"])
	r = _rich(2699)
	_check("dieci con 2699 monete: rifiutato", not Recruiting.pull(r, 10, 1)["ok"] and r["coins"] == 2699)


func _test_pull() -> void:
	var r: Dictionary = _rich(1000)
	var res: Dictionary = Recruiting.pull(r, 1, 5)
	_check("reclutamento singolo riuscito", res["ok"] and res["results"].size() == 1)
	_check("le monete si pagano", r["coins"] == 700 + res["results"][0]["refund"])
	_check("il contatore avanza", r["pulls"] == 1)
	var first: Dictionary = res["results"][0]
	_check("il risultato ha tutti i campi", BattleContent.CHARACTERS.has(first["char"]) and ["new", "rank", "max"].has(first["outcome"]))
	_check("il personaggio e' in collezione", RosterState.owns(r, first["char"]))
	_check("collezione valida dopo il reclutamento", RosterState.validate(r) == "")

	var a: Dictionary = _rich()
	var b: Dictionary = _rich()
	_check("stesso seed, stessi risultati", Recruiting.pull(a, 10, 99)["results"] == Recruiting.pull(b, 10, 99)["results"])
	var c: Dictionary = _rich()
	var d: Dictionary = _rich()
	_check("seed diversi, risultati diversi", Recruiting.pull(c, 10, 1)["results"] != Recruiting.pull(d, 10, 2)["results"])
	var e: Dictionary = _rich()
	var one: Array = Recruiting.pull(e, 1, 7)["results"]
	var two: Array = Recruiting.pull(e, 1, 7)["results"]
	_check("ripetere con lo stesso seed non ripete il risultato (contatore)", one != two or e["pulls"] == 2)

	var ten: Dictionary = Recruiting.pull(_rich(), 10, 3)
	_check("dieci reclutamenti", ten["ok"] and ten["results"].size() == 10 and ten["cost"] == 2700)


func _test_duplicates() -> void:
	var r: Dictionary = _rich(1000000)   # il roster e' piu' grande: servono molti reclutamenti per vederli tutti
	# forzo un personaggio che si possiede gia': la copia sale di rank
	var owned_rank_before: int = r["characters"]["kira"]["rank"]
	var saw_rank: bool = false
	var saw_new: bool = false
	for i in 1600:
		var res: Dictionary = Recruiting.pull(r, 1, 1000 + i)
		if res["results"].is_empty():
			break
		var o: Dictionary = res["results"][0]
		if o["outcome"] == "copy":
			saw_rank = true
		if o["outcome"] == "new":
			saw_new = true
	_check("si vedono personaggi nuovi", saw_new)
	_check("si vedono copie conservate", saw_rank)
	_check("il rank NON sale da solo con le copie", _max_rank(r) == 0 or _max_rank(r) == owned_rank_before)
	var any_copies: int = 0
	for id in r["characters"]:
		any_copies += RosterState.copies(r, str(id))
	_check("le copie si accumulano nel salvataggio", any_copies > 0)
	_check("rank mai oltre il massimo", _max_rank(r) <= RosterState.MAX_RANK)
	_check("tutti e 23 i reclutabili alla fine", r["characters"].size() == 23)
	_check("collezione valida dopo 200 reclutamenti", RosterState.validate(r) == "")
	_check("il rank di Kira non e' sceso", r["characters"]["kira"]["rank"] >= owned_rank_before)

	# rank massimo -> rimborso in monete
	var m: Dictionary = _rich(300)
	for id in m["characters"]:
		m["characters"][id]["rank"] = RosterState.MAX_RANK
	var refunded: bool = false
	for i in 50:
		m["coins"] = 300
		var o: Dictionary = Recruiting.pull(m, 1, i)["results"][0]
		if o["outcome"] == "max":
			var expected: int = (o["rarity"] + 1) * Recruiting.REFUND_PER_RARITY
			refunded = o["refund"] == expected and m["coins"] == expected
			if not refunded:
				break
		elif o["outcome"] == "new":
			RosterState.add_character(m, o["char"])
			m["characters"][o["char"]]["rank"] = RosterState.MAX_RANK
	_check("a rank massimo la copia diventa monete", refunded)


func _max_rank(r: Dictionary) -> int:
	var best: int = 0
	for id in r["characters"]:
		best = maxi(best, int(r["characters"][id]["rank"]))
	return best


func _test_guarantees() -> void:
	# il decimo e' sempre almeno raro
	var ok: bool = true
	for i in 100:
		var res: Dictionary = Recruiting.pull(_rich(), 10, 5000 + i)
		var best: int = 0
		for o in res["results"]:
			best = maxi(best, int(o["rarity"]))
		if best < 1:
			ok = false
	_check("ogni dieci reclutamenti c'e' almeno un raro", ok)

	# garanzia dopo 30 senza epici
	var r: Dictionary = _rich()
	r["pity"] = Recruiting.PITY_LIMIT - 1
	var res: Dictionary = Recruiting.pull(r, 1, 1)
	_check("al limite della garanzia esce almeno un epico", res["results"][0]["rarity"] >= 2)
	_check("dopo l'epico il contatore riparte", r["pity"] == 0)

	var p: Dictionary = _rich()
	var worst: int = 0
	var streak: int = 0
	for i in 400:
		p["coins"] = 300
		var o: Dictionary = Recruiting.pull(p, 1, 9000 + i)["results"][0]
		if o["rarity"] >= 2:
			streak = 0
		else:
			streak += 1
			worst = maxi(worst, streak)
	_check("mai piu' di 29 reclutamenti di fila senza epici", worst < Recruiting.PITY_LIMIT)


func _test_rates() -> void:
	var counts: Array = [0, 0, 0, 0]
	var total: int = 0
	for i in 300:
		var r: Dictionary = _rich()
		for o in Recruiting.pull(r, 10, 20000 + i)["results"]:
			counts[o["rarity"]] += 1
			total += 1
	# la rarita' del personaggio (non del tiro) puo' scendere se non c'e' il personaggio,
	# ma con i 10 attuali ogni rarita' ha un personaggio.
	var common: float = float(counts[0]) / float(total)
	var legendary: float = float(counts[3]) / float(total)
	_check("i comuni sono i piu' frequenti (30-60%)", common > 0.30 and common < 0.60)
	_check("i leggendari sono rari (1-8%)", legendary > 0.01 and legendary < 0.08)
	_check("tutte le rarita' escono", counts.min() > 0)


func _test_persistence() -> void:
	var r: Dictionary = _rich()
	Recruiting.pull(r, 10, 4)
	var back: Dictionary = RosterState.from_json(RosterState.to_json(r))
	_check("dopo il reclutamento il JSON conserva tutto", back == r)
	_check("contatori interi", back["pulls"] is int and back["pity"] is int)
	var old: Dictionary = RosterState.new_roster()
	old.erase("pulls")
	old.erase("pity")
	var loaded: Dictionary = RosterState.from_json(JSON.stringify(old))
	_check("salvataggio precedente: contatori a zero", not loaded.is_empty() and loaded["pulls"] == 0 and loaded["pity"] == 0)
	var bad: Dictionary = r.duplicate(true)
	bad["pity"] = -1
	_check("contatori negativi: collezione non valida", RosterState.validate(bad) != "")
	var path: String = "user://test_recruit_tmp.json"
	_check("salvataggio su disco", RosterStore.save(r, path) and RosterStore.load_or_new(path) == r)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _test_play_flow() -> void:
	# vinco una battaglia, prendo i premi, recluto, ho un personaggio in piu'
	var r: Dictionary = RosterState.new_roster()
	var st: Dictionary = RosterState.create_solo_battle(r, "Io", "distributore", 55)
	var guard: int = 0
	while st["winner"] == "" and guard < 100:
		BattleResolver.autoplay_round(st)
		guard += 1
	RosterState.apply_rewards(r, BattleRewards.for_battle(st, "distributore", 55)["p1"])
	_check("con 4 nel party: 3 front + 1 back", st["players"].size() == 3 and BattleState.back_row(st, st["players"][0]).size() == 1)
	_check("la vittoria paga almeno un reclutamento", r["coins"] >= Recruiting.SINGLE_COST)
	var before: int = r["characters"].size()
	var res: Dictionary = Recruiting.pull(r, 1, 55)
	_check("reclutamento dopo la battaglia", res["ok"])
	_check("o un personaggio nuovo o una copia", r["characters"].size() == before + (1 if res["results"][0]["outcome"] == "new" else 0))
	# un personaggio nuovo si puo' mettere in squadra
	for o in res["results"]:
		if o["outcome"] == "new":
			_check("il nuovo personaggio entra in squadra", RosterState.set_team(r, [o["char"], "kira", "dax"]))
	var after: Dictionary = RosterState.create_solo_battle(r, "Io", "distributore", 56)
	_check("e la battaglia successiva parte", after["round"] == 1 and after["players"].size() >= 2)
	_check("squadra valida per la rete", RosterState.validate_team(RosterState.team_entries(r)) == "")
