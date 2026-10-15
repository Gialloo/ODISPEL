extends SceneTree

# Livello di difficolta' ABISSO: esiste, si sblocca dopo INCUBO, non cambia gli altri livelli e
# una squadra al massimo (liv. 50, rank 5, pezzi leggendari) ha uno scontro lungo e non banale.
#
#   godot --headless --path . -s res://tests/unit/test_abisso.gd

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
	_run()


func _maxed(id: String) -> Dictionary:
	var e: Dictionary = BattleContent.default_entry(id, RosterState.MAX_LEVEL, RosterState.MAX_RANK)
	var gear: Array = []
	for slot in BattleTypes.GEAR_SLOTS:
		gear.append({"slot": slot, "rarity": 3, "level": int(BattleContent.GEAR_MAX_LEVEL[3])})
	e["gear"] = gear
	return e


func _fight(boss: String, tier: int, seed_value: int) -> Dictionary:
	var team: Array = []
	for id in ["kira", "tana", "oriel"]:
		team.append(_maxed(id))
	var spare: Array = []
	for id in ["flux", "dafne", "lyra"]:
		spare.append(_maxed(id))
	var st: Dictionary = BattleState.create_solo("IO", team, spare, boss, seed_value, 2, tier)
	st["players"][0]["ai"] = true
	var guard: int = 0
	while str(st["winner"]) == "" and guard < 150:
		BattleResolver.resolve_round(st, true)
		guard += 1
	return st


func _run() -> void:
	_check("ci sono 4 livelli e l'ultimo e' ABISSO", BattleContent.TIERS.size() == 4 and str(BattleContent.TIERS[3]["id"]) == "abisso")
	_check("i primi tre livelli non cambiano", float(BattleContent.TIERS[0]["hp"]) == 1.0 and float(BattleContent.TIERS[2]["hp"]) == 2.1 and int(BattleContent.TIERS[2]["def"]) == 15 and not BattleContent.TIERS[2].has("flatten"))
	_check("ABISSO consiglia il livello 50", int(BattleContent.TIERS[3]["rec_level"]) == RosterState.MAX_LEVEL)
	_check("i dati dei contenuti sono coerenti", BattleContent.validate().is_empty())

	# sblocco: si apre battendo INCUBO
	var roster: Dictionary = RosterState.new_roster()
	_check("ABISSO e' chiuso all'inizio", not RosterState.is_tier_unlocked(roster, "distributore", 3))
	RosterState.mark_cleared(roster, "distributore", 0)
	RosterState.mark_cleared(roster, "distributore", 1)
	_check("ABISSO e' chiuso dopo DIFFICILE", not RosterState.is_tier_unlocked(roster, "distributore", 3))
	RosterState.mark_cleared(roster, "distributore", 2)
	_check("ABISSO si apre dopo INCUBO", RosterState.is_tier_unlocked(roster, "distributore", 3))
	_check("il salvataggio resta valido", RosterState.validate(roster).is_empty())
	var news: Array = RosterState.unlock_news("distributore", 2)
	_check("la notizia di sblocco nomina ABISSO", " ".join(news).find("ABISSO") >= 0)
	_check("tutte le imprese per tier hanno un nome", Feats.all().size() > 0)

	# boss "appiattiti": a ABISSO tutti i boss hanno PV vicini
	var lo: int = 1 << 30
	var hi: int = 0
	for b in BattleContent.BOSS_ORDER:
		var u: Dictionary = BattleState.make_boss(str(b), 1.0, 3)
		lo = mini(lo, int(u["max_hp"]))
		hi = maxi(hi, int(u["max_hp"]))
	_check("ABISSO: tutti i boss hanno gli stessi PV base", lo == hi)
	var normal: Dictionary = BattleState.make_boss("eclissi", 1.0, 0)
	_check("NORMALE non e' appiattito (eclissi resta il piu' duro)", int(normal["max_hp"]) == 2100)

	# Ciclo Infinito e Spedizione non arrivano ad ABISSO
	_check("Ciclo Infinito fermo a INCUBO", Endless.tier_for(9999) == 2)
	_check("Spedizione ferma a INCUBO", int(Expedition.new_run(5, "distributore", 3)["tier"]) == 2)

	# difficolta' vera: la stessa squadra al massimo
	var easy: Dictionary = _fight("distributore", 2, 41)
	var hard: Dictionary = _fight("distributore", 3, 41)
	_check("INCUBO: la squadra al massimo vince in pochi round (%d)" % int(easy["round"]), str(easy["winner"]) == "players" and int(easy["round"]) <= 6)
	_check("ABISSO: lo scontro dura molto di piu' (%d round)" % int(hard["round"]), int(hard["round"]) >= 10)
	var downs: int = 0
	for b in ["scala", "metro", "registro"]:
		var st: Dictionary = _fight(b, 3, 41)
		for u in st["units"].values():
			if str(u["side"]) == "player" and int(u["hp"]) <= 0:
				downs += 1
	_check("ABISSO: nei boss avanzati qualcuno della squadra cade (%d caduti)" % downs, downs >= 1)
	print("RISULTATO: %d ok, %d falliti" % [passed, failed])
	print("FAIL: %d" % failed)
	quit(1 if failed > 0 else 0)
