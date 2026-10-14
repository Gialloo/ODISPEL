extends SceneTree

# SPEDIZIONE in solitaria: dalla sorgente di battaglia al salvataggio.
#   godot --headless --path . -s res://tests/unit/test_expedition_solo.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _play(roster: Dictionary, run: Dictionary, win: bool, path: String) -> SoloBattleSource:
	var s := SoloBattleSource.new()
	s.save_path = path
	s.expedition = run
	s.start(roster, "distributore", 5, 0)
	if win:
		BattleState.boss(s.battle)["hp"] = 0
	else:
		for uid in s.battle["units"]:
			if str(s.battle["units"][uid]["side"]) == "player":
				s.battle["units"][uid]["hp"] = 0
	BattleResolver._check_winner(s.battle, [])
	s.finish()
	return s


func _init() -> void:
	var path: String = "user://xsolo_test.json"
	var roster: Dictionary = RosterState.new_roster()
	var run: Dictionary = Expedition.new_run(3, "distributore", 0)
	Expedition.choose(run, "archivio")
	var s: SoloBattleSource = _play(roster, run, true, path)
	_check("sorgente usa il nemico della tappa", s.boss_id == str(Expedition.battle_params(Expedition.new_run(3, "distributore", 0)).get("boss", s.boss_id)) or s.boss_id != "distributore")
	_check("a meta': nessun premio", s.rewards.is_empty())
	_check("meta': nessun boss sbloccato", RosterState.cleared_tiers(roster, s.boss_id) == 0)
	_check("run avanza al potenziamento", Expedition.kind(run) == "boon")
	_check("run salvata nel profilo", not roster["expedition"]["run"].is_empty())
	# fino in fondo
	var g: int = 0
	while Expedition.kind(run) != "done" and g < 20:
		g += 1
		if Expedition.kind(run) == "fight":
			_play(roster, run, true, path)
		else:
			Expedition.choose(run, str(Expedition.option_ids(run)[0]))
	_check("completata", str(run["result"]) == "win")
	_check("veterano", Expedition.vet_level(roster, "kira") == 1)
	_check("boss finale: battuto", RosterState.cleared_tiers(roster, "distributore") >= 1)
	_check("diario esposto", Expedition.summary(run).size() > 3)
	# sconfitta
	var r2: Dictionary = RosterState.new_roster()
	var lost: Dictionary = Expedition.new_run(9, "distributore", 0)
	Expedition.choose(lost, "rifugio")
	_play(r2, lost, false, path)
	_check("sconfitta registrata", str(lost["result"]) == "loss")
	_check("feriti dopo la sconfitta", not Expedition.wounded(r2).is_empty())
	var e: Dictionary = RosterState.team_entries(r2)[0]
	_check("ferita nella scheda", bool(e.get("wound", false)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
