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
	# --- abilita' uniche e passive ---
	var ku: Dictionary = PvpEngine.create([{"id": "a", "name": "a", "ai": false, "team": [BattleContent.default_entry("kira")]}, {"id": "b", "name": "b", "ai": false, "team": [BattleContent.default_entry("dax")]}], "duel", false, 21)
	var kk: Dictionary = PvpEngine.active_unit(ku, PvpEngine.player(ku, "a"))
	_check("skill uniche tra le abilita'", PvpEngine.skills_of(kk).has("u_kira_a"))
	_check("ult dell'operatore", PvpEngine.ult_of(kk) == "spezzatutto")
	_check("abilita' sbagliata rifiutata", not PvpEngine.submit_choice(ku, "a", {"move": "skill", "skill": "u_elle_a", "target": "b"}))
	_check("abilita' unica accettata", PvpEngine.submit_choice(ku, "a", {"move": "skill", "skill": "u_kira_a", "target": "b"}))
	PvpEngine.submit_choice(ku, "b", {"move": "skill", "skill": "u_dax_a", "target": "a"})
	var ev2: Array = PvpEngine.resolve_round(ku)
	var dax: Dictionary = PvpEngine.unit(ku, "b:dax")
	var names: Array = []
	for e in ev2:
		if str(e["t"]) == "act":
			names.append(str(e["move"]))
	_check("eseguite le mosse uniche", names.has("u_kira_a") and names.has("u_dax_a"))
	_check("Kira marchia (stato mark) o Dax e' in guardia", dax["statuses"].has("mark") or int(dax["hp"]) < int(dax["max_hp"]))
	_check("energia spesa", int(PvpEngine.unit(ku, "a:kira")["energy"]) < 4)
	# cura su alleato in 2v2
	var duo2: Dictionary = PvpEngine.create([_spec("a", ["mira"]), _spec("b", ["rex"]), _spec("c", ["kira"]), _spec("d", ["dax"])], "duo", false, 3)
	PvpEngine.unit(duo2, "c:kira")["hp"] = 100
	PvpEngine.active_unit(duo2, PvpEngine.player(duo2, "a"))["energy"] = 6
	PvpEngine.player(duo2, "a")["choice"] = null
	_check("cura: alleato valido", PvpEngine.validate_choice(duo2, "a", {"move": "skill", "skill": "u_mira_a", "target": "c"}) == "")
	_check("cura: un nemico non vale", PvpEngine.validate_choice(duo2, "a", {"move": "skill", "skill": "u_mira_a", "target": "b"}) == "alleato non valido")
	# Angela: torretta
	var an: Dictionary = PvpEngine.create([_spec("a", ["angela"]), _spec("b", ["rex"])], "duel", false, 4)
	var au: Dictionary = PvpEngine.active_unit(an, PvpEngine.player(an, "a"))
	au["energy"] = 6
	PvpEngine.player(an, "a")["choice"] = null
	PvpEngine.player(an, "b")["choice"] = null
	PvpEngine.submit_choice(an, "a", {"move": "skill", "skill": "u_angela_b", "target": "b"})
	PvpEngine.submit_choice(an, "b", {"move": "guard"})
	PvpEngine.resolve_round(an)
	_check("drone evocato", PvpEngine.player(an, "a") != {} and an["summons"].size() == 1)
	# malus a tempo: la difesa torna normale
	var dm: Dictionary = PvpEngine.create([_spec("a", ["kira"]), _spec("b", ["rex"])], "duel", false, 8)
	var tgt: Dictionary = PvpEngine.unit(dm, "b:rex")
	var d0: int = int(tgt["def"])
	PvpEngine._mod(tgt, "def", -300, [])
	_check("malus abbassa la difesa", int(tgt["def"]) < d0)
	for i in 3:
		PvpEngine.resolve_round(dm, true)
	_check("malus finito: difesa ripristinata", int(PvpEngine.unit(dm, "b:rex")["def"]) == d0)
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
	# --- premi, imprese, badge ---
	var win_bag: Dictionary = PvpRewards.for_player(123, 0, "win")
	var loss_bag: Dictionary = PvpRewards.for_player(123, 0, "loss")
	_check("borsa: chi vince prende di piu'", int(win_bag["coins"]) > int(loss_bag["coins"]) and int(win_bag["coins"]) >= PvpRewards.WIN_COINS[0])
	_check("borsa deterministica", str(PvpRewards.for_player(123, 0, "win")) == str(win_bag))
	_check("allenamento: solo una parte, niente drop", PvpRewards.for_player(123, 0, "win", true)["drops"].is_empty() and int(PvpRewards.for_player(123, 0, "win", true)["coins"]) < int(win_bag["coins"]))
	var fin: Dictionary = PvpEngine.simulate([_spec("a", ["kira"], false), _spec("ia_1", ["rex"])], "duel", true, 9)
	var bags: Dictionary = PvpRewards.for_battle(fin, 9)
	_check("borse solo per gli umani", bags.has("a") and not bags.has("ia_1"))
	var all_ok: bool = true
	for i in 200:
		var bg: Dictionary = PvpRewards.for_player(i, i % 4, "win")
		var r: Dictionary = RosterState.new_roster()
		RosterState.apply_rewards(r, bg)
		if int(r["coins"]) < 450:
			all_ok = false
		for d in bg["drops"]:
			if str(d.get("id", "")) == "l_duello":
				all_ok = false
	_check("200 borse: applicabili, l'icona esclusiva non cade mai", all_ok)
	var ids: Array = []
	for f in Feats.all():
		if str(f["group"]) == "PVP":
			ids.append(f["goal"])
	_check("imprese PvP 1/3/5/10/15/20/25 + campione", ids.has(1) and ids.has(3) and ids.has(10) and ids.has(15) and ids.has(20) and ids.has(25) and Feats.by_id("pvp_wins_5").has("reward"))
	var rost: Dictionary = RosterState.new_roster()
	Profile.path = "user://test_pvp_profile.cfg"
	Profile.badges = []
	Profile.unlocked = []
	Profile._loaded = true
	for i in 5:
		Feats.record_pvp(rost, true)
	_check("5 vittorie: impresa campione pronta", Feats.can_claim(rost, Feats.by_id("pvp_wins_5")))
	_check("5 partecipazioni: impresa pronta", Feats.can_claim(rost, Feats.by_id("pvp_plays_5")))
	Feats.claim(rost, "pvp_wins_5")
	_check("badge ottenuto", Profile.has_badge("duellante") and Profile.shown_badge() == "duellante")
	_check("icona leggendaria esclusiva sbloccata", Profile.is_unlocked("l_duello") and Profile.rarity_of("l_duello") == 3)
	_check("badge viaggia nel profilo pubblico", Profile.clean_public(Profile.current())["badge"] == "duellante" and Profile.clean_public({"badge": "falso"})["badge"] == "")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_pvp_profile.cfg"))
	print("RESULT: %d passed, %d failed" % [passed, failed])
	print("FAIL: %d" % failed)
	quit(1 if failed > 0 else 0)
