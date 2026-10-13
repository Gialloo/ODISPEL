extends SceneTree

# Motore PvP: modalita', bilanciamento, scelte, vincitore.
#   godot --headless --path . -s res://tests/unit/test_pvp.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _entry(char_id: String, level: int = 1, rank: int = 0) -> Dictionary:
	var e: Dictionary = {"char": char_id, "level": level, "rank": rank, "gear": [], "skills": [], "passives": [], "ult": ""}
	return e


func _team(ids: Array, level: int = 1) -> Array:
	var out: Array = []
	for i in ids:
		out.append(_entry(str(i), level))
	return out


func _spec(id: String, ids: Array, ai: bool = true, level: int = 1) -> Dictionary:
	return {"id": id, "name": id, "ai": ai, "team": _team(ids, level)}


func _initialize() -> void:
	var chars: Array = BattleContent.CHARACTERS.keys()
	# --- 1v1 ---
	var st: Dictionary = PvpEngine.create([_spec("a", ["kira", "dax", "elle"]), _spec("b", ["rex", "bruno", "mira"])], "duel", false, 7)
	_check("duel: 2 giocatori, 6 unita'", st["players"].size() == 2 and st["units"].size() == 6)
	_check("squadre diverse", st["players"][0]["team"] != st["players"][1]["team"])
	_check("IA sceglie da sola", st["players"][0]["choice"] != null and st["players"][1]["choice"] != null)
	var end: Dictionary = PvpEngine.simulate([_spec("a", ["kira", "dax", "elle"]), _spec("b", ["rex", "bruno", "mira"])], "duel", false, 7)
	_check("1v1 finisce con un vincitore", str(end["winner"]) != "")
	var again: Dictionary = PvpEngine.simulate([_spec("a", ["kira", "dax", "elle"]), _spec("b", ["rex", "bruno", "mira"])], "duel", false, 7)
	_check("stesso seme, stesso esito", str(again["winner"]) == str(end["winner"]) and int(again["round"]) == int(end["round"]))
	# --- 2v2 ---
	var duo: Dictionary = PvpEngine.simulate([_spec("a", ["kira"]), _spec("b", ["rex"]), _spec("c", ["dax"]), _spec("d", ["elle"])], "duo", false, 11)
	_check("2v2: finisce", str(duo["winner"]) != "")
	_check("2v2: team a e c insieme", PvpEngine.player(duo, "a")["team"] == PvpEngine.player(duo, "c")["team"])
	if str(duo["winner"]) != "draw":
		_check("2v2: vincono due giocatori", PvpEngine.winner_players(duo).size() == 2)
	# --- FFA ---
	var ffa: Dictionary = PvpEngine.simulate([_spec("a", ["kira"]), _spec("b", ["rex"]), _spec("c", ["dax"])], "ffa", false, 5)
	_check("ffa: finisce", str(ffa["winner"]) != "")
	_check("ffa: ognuno una squadra", PvpEngine.player(ffa, "a")["team"] != PvpEngine.player(ffa, "b")["team"])
	# --- bilanciamento ---
	var lo: Dictionary = PvpEngine.create([_spec("a", ["kira"], true, 1), _spec("b", ["kira"], true, 40)], "duel", true, 3)
	var ua: Dictionary = PvpEngine.unit(lo, "a:kira")
	var ub: Dictionary = PvpEngine.unit(lo, "b:kira")
	_check("bilanciato: stesse statistiche", int(ua["atk"]) == int(ub["atk"]) and int(ua["max_hp"]) == int(ub["max_hp"]))
	var pr: Dictionary = PvpEngine.create([_spec("a", ["kira"], true, 1), _spec("b", ["kira"], true, 40)], "duel", false, 3)
	_check("progressione: il livello conta", int(PvpEngine.unit(pr, "b:kira")["atk"]) > int(PvpEngine.unit(pr, "a:kira")["atk"]))
	# --- scelte ---
	var h: Dictionary = PvpEngine.create([_spec("a", ["kira", "dax"], false), _spec("b", ["rex"], false)], "duel", false, 9)
	_check("nessuno ha scelto: non si risolve", not PvpEngine.can_resolve(h))
	_check("mossa strana rifiutata", not PvpEngine.submit_choice(h, "a", {"move": "teletrasporto"}))
	_check("abilita' senza energia rifiutata", PvpEngine.validate_choice(h, "a", {"move": "skill", "target": "b"}) == "energia insufficiente" or PvpEngine.can_skill(PvpEngine.active_unit(h, PvpEngine.player(h, "a"))))
	_check("ult non pronta rifiutata", not PvpEngine.submit_choice(h, "a", {"move": "ult", "target": "b"}))
	_check("bersaglio alleato/inesistente rifiutato", not PvpEngine.submit_choice(h, "a", {"move": "attack", "target": "a"}) and not PvpEngine.submit_choice(h, "a", {"move": "attack", "target": "zzz"}))
	_check("attacco valido", PvpEngine.submit_choice(h, "a", {"move": "attack", "target": "b"}))
	_check("la scelta e' definitiva", not PvpEngine.submit_choice(h, "a", {"move": "guard"}))
	_check("cambio valido", PvpEngine.submit_choice(h, "b", {"move": "guard"}))
	var ev: Array = PvpEngine.resolve_round(h)
	_check("round risolto, eventi", ev.size() > 0 and int(h["round"]) == 2)
	_check("scelte azzerate", h["players"][0]["choice"] == null)
	var hpb: int = int(PvpEngine.unit(h, "b:rex")["hp"])
	_check("guardia: danno ricevuto", hpb < int(PvpEngine.unit(h, "b:rex")["max_hp"]))
	_check("swap valido", PvpEngine.submit_choice(h, "a", {"move": "swap", "swap": "a:dax"}))
	PvpEngine.submit_choice(h, "b", {"move": "attack", "target": "a"})
	PvpEngine.resolve_round(h)
	_check("swap eseguito", str(PvpEngine.player(h, "a")["active"]) == "a:dax")
	# --- JSON ---
	var back: Dictionary = BattleState.from_json(BattleState.to_json(h))
	_check("JSON senza perdite", back["players"].size() == 2 and str(back["mode"]) == "duel" and int(back["round"]) == int(h["round"]))
	var snap: Dictionary = BattleNet.snapshot_for(h, "a")
	_check("snapshot nasconde scelte altrui", snap["players"][1]["choice"] == null or snap["players"][1]["choice"].has("locked"))
	# --- stress: tutte le combinazioni di personaggi ---
	var wins: Dictionary = {}
	var longest: int = 0
	var bad: int = 0
	for i in chars.size():
		for j in chars.size():
			var r: Dictionary = PvpEngine.simulate([_spec("a", [chars[i]]), _spec("b", [chars[j]])], "duel", true, 100 + i * 31 + j)
			if str(r["winner"]) == "":
				bad += 1
			longest = maxi(longest, int(r["round"]))
			var wk: String = str(r["winner"])
			wins[wk] = int(wins.get(wk, 0)) + 1
	_check("stress %d duelli: tutti finiscono" % (chars.size() * chars.size()), bad == 0)
	print("INFO: round max %d, esiti %s" % [longest, str(wins)])
	_check("nessun duello oltre il limite", longest <= PvpEngine.MAX_ROUNDS + 1)
	# squadre piene 3 vs 3, 2v2 e ffa con personaggi casuali
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var bad2: int = 0
	for n in 60:
		var mode: String = ["duel", "duo", "ffa"][n % 3]
		var seats: int = 2 if mode == "duel" else (4 if mode == "duo" else 3 + n % 2)
		var specs: Array = []
		for s in seats:
			var ids: Array = []
			for k in 3:
				ids.append(chars[rng.randi() % chars.size()])
			specs.append(_spec("p%d" % s, ids, true, 1 + rng.randi() % 30))
		var res: Dictionary = PvpEngine.simulate(specs, mode, n % 2 == 0, 1000 + n)
		if str(res["winner"]) == "" or BattleState.to_json(res).length() > 60000:
			bad2 += 1
	_check("60 partite casuali (tutte le modalita'): finiscono, JSON contenuto", bad2 == 0)
	print("RESULT: %d passed, %d failed" % [passed, failed])
	print("FAIL: %d" % failed)
	quit(1 if failed > 0 else 0)
