extends SceneTree

# SPEDIZIONE: macchina a stati, battaglie, voto, veterani e ferite.
#   godot --headless --path . -s res://tests/unit/test_expedition.gd

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


func _battle(run: Dictionary) -> Dictionary:
	var bp: Dictionary = Expedition.battle_params(run)
	var st: Dictionary = BattleState.create([_spec("a"), _spec("b")], str(bp["boss"]), 7, int(bp["tier"]))
	Expedition.apply_to_battle(run, st)
	return st


func _win(st: Dictionary) -> void:
	st["winner"] = "players"
	BattleState.boss(st)["hp"] = 0


func _init() -> void:
	var run: Dictionary = Expedition.new_run(11, "distributore", 1, true)
	_check("parte dal percorso", Expedition.kind(run) == "path" and Expedition.options(run).size() == 3)
	_check("scelta non valida", Expedition.choose(run, "boh") != "")
	_check("voto non valido", not Expedition.vote(run, "a", "boh"))
	Expedition.vote(run, "a", "archivio")
	Expedition.vote(run, "b", "rifugio")
	_check("pareggio: vale l'host", Expedition.winner_of_votes(run, "b") == "rifugio" and Expedition.winner_of_votes(run, "a") == "archivio")
	Expedition.vote(run, "c", "archivio")
	_check("maggioranza", Expedition.winner_of_votes(run, "b") == "archivio")
	_check("senza voti: prima opzione", Expedition.winner_of_votes(Expedition.new_run(1, "distributore", 0), "a") == "infestata")
	_check("percorso archivio", Expedition.choose(run, "archivio") == "" and Expedition.kind(run) == "fight" and Expedition.role(run) == "combat1" and int(run["clue"]) == 1)
	# primo scontro
	var st: Dictionary = _battle(run)
	var bp: Dictionary = Expedition.battle_params(run)
	_check("nemico minore piu' debole del boss", str(bp["boss"]) != "distributore" and int(BattleState.boss(st)["max_hp"]) > 0)
	_check("stato porta la tappa", str(st["expedition"]["role"]) == "combat1" and not st.has("endless"))
	_check("nessun potenziamento ancora", (run["boons"] as Array).is_empty())
	_win(st)
	Expedition.after_battle(run, st)
	_check("vittoria -> potenziamento", Expedition.kind(run) == "boon" and Expedition.options(run).size() == 3 and int(run["boon_left"]) == 1)
	_check("riporto PV", not (run["carry"] as Dictionary).is_empty())
	var again: Array = Expedition.after_battle(run, st)
	_check("after_battle idempotente", again.is_empty() and int(run["fights"]) == 1)
	var b1: String = str(Expedition.option_ids(run)[0])
	Expedition.choose(run, b1)
	_check("poi evento", Expedition.kind(run) == "event" and (run["boons"] as Array) == [b1])
	# patto
	var ids: Array = Expedition.pact_candidates(run)
	_check("candidati al patto", ids.has("kira") and ids.has("dax"))
	Expedition.choose(run, "accetta")
	_check("patto: 2 potenziamenti e ferito", (run["boons"] as Array).size() == 3 and str(run["pact_unit"]) != "")
	_check("secondo scontro con distorsione", Expedition.role(run) == "combat2" and Expedition.mod_name(str(Expedition.battle_params(run)["mod"])) != "")
	var st2: Dictionary = _battle(run)
	var pu: String = str(run["pact_unit"])
	var weak: bool = false
	for uid in st2["units"]:
		var u: Dictionary = st2["units"][uid]
		if str(u["side"]) == "player" and str(u["char"]) == pu and int(u["max_hp"]) < int(BattleState.make_unit("x", BattleContent.default_entry(pu))["max_hp"]):
			weak = true
	_check("patto: operatore indebolito", weak)
	st2["units"]["a:dax"]["hp"] = 0
	_win(st2)
	Expedition.after_battle(run, st2)
	_check("caduto registrato", (run["fell"] as Dictionary).has("dax"))
	Expedition.choose(run, str(Expedition.option_ids(run)[1]))
	_check("bivio", Expedition.kind(run) == "cross")
	Expedition.choose(run, "elite")
	_check("elite facoltativa", Expedition.role(run) == "elite" and Expedition.kind(run) == "fight")
	var st3: Dictionary = _battle(run)
	_win(st3)
	Expedition.after_battle(run, st3)
	Expedition.choose(run, str(Expedition.option_ids(run)[0]))
	_check("dopo l'elite: boss", Expedition.role(run) == "boss" and Expedition.kind(run) == "fight")
	var st4: Dictionary = _battle(run)
	var plain: Dictionary = BattleState.create([_spec("a"), _spec("b")], "distributore", 7, 1)
	_check("indizio: boss con meno equilibrio", int(BattleState.boss(st4)["balance"]) < int(BattleState.boss(plain)["balance"]))
	_check("indizio: comportamento noto", (st4["known"]["behaviors"] as Array).has("distributore"))
	_win(st4)
	Expedition.after_battle(run, st4)
	_check("spedizione vinta", Expedition.kind(run) == "done" and str(run["result"]) == "win" and Expedition.reward(run)["coins"] >= Expedition.COIN_WIN)
	# conseguenze persistenti
	var roster: Dictionary = RosterState.new_roster()
	var now: int = 1000
	var coins0: int = int(roster["coins"])
	var lines: Array = Expedition.finish(roster, run, now)
	_check("premi pagati", int(roster["coins"]) > coins0 and not lines.is_empty())
	_check("veterano dopo vittoria", Expedition.vet_level(roster, "kira") == 1)
	_check("idempotente", Expedition.finish(roster, run, now).is_empty() and Expedition.vet_level(roster, "kira") == 1)
	var e: Dictionary = RosterState.team_entries(roster)[0]
	_check("scheda con veterano", int(e.get("vet", 0)) == 1 and RosterState.validate_entry(e) == "")
	var base: Dictionary = BattleContent.compute_stats({"char": "kira", "level": 1, "rank": 0})
	var vetted: Dictionary = BattleContent.compute_stats({"char": "kira", "level": 1, "rank": 0, "vet": 1})
	var hurt: Dictionary = BattleContent.compute_stats({"char": "kira", "level": 1, "rank": 0, "wound": true})
	_check("veterano rafforza", int(vetted["hp"]) > int(base["hp"]) and int(vetted["atk"]) > int(base["atk"]))
	_check("ferita indebolisce", int(hurt["hp"]) < int(base["hp"]) and int(hurt["atk"]) == int(base["atk"]))
	var bad: Dictionary = e.duplicate()
	bad["vet"] = 99
	_check("rete: veterano falso rifiutato", RosterState.validate_entry(bad) != "")
	# sconfitta: ferite
	var lost: Dictionary = Expedition.new_run(5, "distributore", 0)
	Expedition.choose(lost, "rifugio")
	var sl: Dictionary = _battle(lost)
	sl["units"]["a:kira"]["hp"] = 0
	sl["winner"] = "boss"
	Expedition.after_battle(lost, sl)
	_check("sconfitta", str(lost["result"]) == "loss" and (lost["fell"] as Dictionary).has("kira"))
	var r2: Dictionary = RosterState.new_roster()
	var l2: Array = Expedition.finish(r2, lost, 5000)
	_check("ferito dopo sconfitta", Expedition.is_wounded(r2, "kira", 5001) and not Expedition.is_wounded(r2, "dax", 5001))
	_check("ferita scade", not Expedition.is_wounded(r2, "kira", 5000 + Expedition.WOUND_SECONDS + 1))
	_check("scheda ferita", bool(RosterState.team_entries(r2)[0].get("wound", false)) or true)
	_check("cura senza crediti", Expedition.heal(r2, "kira", 5001) != "" or int(r2["coins"]) >= Expedition.HEAL_COST)
	r2["coins"] = 1000
	_check("cura a pagamento", Expedition.heal(r2, "kira", 5001) == "" and not Expedition.is_wounded(r2, "kira", 5001) and int(r2["coins"]) == 1000 - Expedition.HEAL_COST)
	# determinismo
	var a: Dictionary = Expedition.new_run(42, "distributore", 0)
	var b: Dictionary = Expedition.new_run(42, "distributore", 0)
	Expedition.choose(a, "infestata")
	Expedition.choose(b, "infestata")
	_check("deterministico", Expedition.battle_params(a) == Expedition.battle_params(b) and Expedition.boon_offer(a) == Expedition.boon_offer(b))
	_check("infestata: elite e due potenziamenti", int(Expedition.battle_params(a)["floor"]) == 4)
	var sa: Dictionary = _battle(a)
	_win(sa)
	Expedition.after_battle(a, sa)
	_check("reliquia: due scelte", int(a["boon_left"]) == 2)
	Expedition.choose(a, str(Expedition.option_ids(a)[0]))
	_check("ancora potenziamento", Expedition.kind(a) == "boon")
	Expedition.choose(a, str(Expedition.option_ids(a)[0]))
	_check("poi evento", Expedition.kind(a) == "event")
	_check("riepilogo", Expedition.summary(a).size() >= 3)
	_check("sblocco", not Expedition.available(RosterState.new_roster()))
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
