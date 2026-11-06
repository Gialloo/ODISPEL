extends SceneTree

# Scontri con due nemici: la SCHEGGIA (Gregario) accanto al nemico principale, bersaglio scelto, IA, Riserva, vittoria.
var fails: int = 0


func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _team() -> Array:
	var t: Array = []
	for id in ["lance", "nox", "rio", "saul"]:
		t.append(BattleContent.default_entry(id))
	return t


func _fresh(main: String, greg: String, seed_value: int = 7) -> Dictionary:
	var s: Dictionary = BattleState.create_solo("IO", _team(), [], main, seed_value)
	Gregario.add(s, greg)
	return s


func _slot_of_char(s: Dictionary, ch: String) -> String:
	for p in s["players"]:
		if str(BattleState.active_unit(s, str(p["id"]))["char"]) == ch:
			return str(p["id"])
	return ""


func _init() -> void:
	# senza scheggia: niente cambia
	var s0: Dictionary = BattleState.create_solo("IO", _team(), [], "frammento_blu", 7)
	check(not Gregario.present(s0), "senza scheggia non c'e' gregario")
	SeqRound.begin(s0)
	for e in SeqRound.order(s0):
		check(not bool(e.get("greg", false)), "senza scheggia nessun turno in piu'")

	var s: Dictionary = _fresh("frammento_blu", "frammento_rosso")
	var main: Dictionary = BattleState.boss(s)
	var g: Dictionary = Gregario.unit(s)
	check(Gregario.alive(s), "la scheggia e' in campo")
	check(int(g["max_hp"]) == int(round(float(main["max_hp"]) * Gregario.HP_K)), "PV della scheggia in proporzione")
	check(str(g["color"]) == "rosso", "la scheggia ha il suo colore")
	check(s.has("telegraph2") and str(s["telegraph2"]["target"]) != "", "la scheggia annuncia un bersaglio")
	SeqRound.begin(s)
	var n_greg: int = 0
	for e in SeqRound.order(s):
		if bool(e.get("greg", false)):
			n_greg += 1
	check(n_greg == 1, "un turno della scheggia nel round")

	# bersaglio scelto: la scheggia prende il colpo, il principale no (e il suo equilibrio non scende)
	var pid: String = _slot_of_char(s, "lance")
	var hp_main: int = int(main["hp"])
	var bal_main: int = int(main["balance"])
	var hp_g: int = int(g["hp"])
	SeqRound.player_action(s, pid, {"swap": "", "move": "attack", "target": Gregario.ID})
	check(int(g["hp"]) < hp_g, "l'attacco sulla scheggia la colpisce")
	check(int(main["hp"]) == hp_main and int(main["balance"]) == bal_main, "il principale resta intatto")
	# senza bersaglio: il principale, come prima
	var pid2: String = _slot_of_char(s, "saul")
	SeqRound.player_action(s, pid2, {"swap": "", "move": "attack", "target": ""})
	check(int(main["hp"]) < hp_main, "senza bersaglio si colpisce il principale")

	# turno della scheggia: colpisce un eroe
	var before: int = 0
	for p in BattleState.alive_players(s):
		before += int(BattleState.active_unit(s, str(p["id"]))["hp"])
	var ev: Array = SeqRound.boss_action(s, Gregario.ID)
	var after: int = 0
	for p in BattleState.alive_players(s):
		after += int(BattleState.active_unit(s, str(p["id"]))["hp"])
	var acted: bool = false
	for e in ev:
		if str(e.get("t", "")) == "gregario_act":
			acted = true
	check(acted and after <= before, "la scheggia agisce nel suo turno")

	# abbattuta: +1 Riserva, una volta sola; poi il colpo con bersaglio scheggia va sul principale
	s["reserve"] = 2
	g["hp"] = 1
	SeqRound.player_action(s, pid, {"swap": "", "move": "attack", "target": Gregario.ID})
	check(not Gregario.alive(s), "la scheggia cade")
	check(int(s["reserve"]) == 2 + Gregario.RESERVE_ON_DOWN, "abbattere la scheggia da' Riserva (%d)" % int(s["reserve"]))
	var hp2: int = int(main["hp"])
	SeqRound.player_action(s, pid2, {"swap": "", "move": "attack", "target": Gregario.ID})
	check(int(main["hp"]) < hp2, "scheggia caduta: il colpo va sul principale")
	check(int(s["reserve"]) == 2 + Gregario.RESERVE_ON_DOWN, "la Riserva della scheggia arriva una volta sola")
	SeqRound.finish(s)
	check(not s.has("telegraph2"), "scheggia caduta: niente annuncio")
	SeqRound.begin(s)
	for e in SeqRound.order(s):
		check(not bool(e.get("greg", false)), "scheggia caduta: niente turno")

	# vittoria: cade il principale, la scheggia (ancora in piedi) non conta
	var s2: Dictionary = _fresh("frammento_verde", "frammento_blu")
	SeqRound.begin(s2)
	BattleState.boss(s2)["hp"] = 1
	BattleState.boss(s2)["shield"] = 0
	SeqRound.player_action(s2, _slot_of_char(s2, "lance"), {"swap": "", "move": "attack", "target": ""})
	check(str(s2["winner"]) == "players", "cade il principale: vittoria anche con la scheggia in piedi")

	# IA: Ultimate sul principale; Lance (rosso) contro principale verde e scheggia blu: sul principale (colore vincente)
	var s3: Dictionary = _fresh("frammento_verde", "frammento_blu")
	var lance: String = _slot_of_char(s3, "lance")
	var c1: Dictionary = Gregario.with_target(s3, lance, {"swap": "", "move": "attack", "target": ""})
	check(str(c1["target"]) == "", "Lance forte sul verde: colpisce il principale")
	var nox: String = _slot_of_char(s3, "nox")
	var c2: Dictionary = Gregario.with_target(s3, nox, {"swap": "", "move": "attack", "target": ""})
	check(str(c2["target"]) == Gregario.ID, "senza vantaggio: prima la scheggia")
	var ult: String = str(BattleState.active_unit(s3, nox)["ult"])
	if ult != "" and str(BattleContent.MOVES[ult]["target"]) == "enemy":
		check(str(Gregario.with_target(s3, nox, {"swap": "", "move": ult, "target": ""})["target"]) == "", "Ultimate sul principale")
	BattleState.boss(s3)["stun"] = 1
	check(str(Gregario.with_target(s3, nox, {"swap": "", "move": "attack", "target": ""})["target"]) == "", "nemico rotto: tutti sul principale")

	# partite intere in AUTO (motore classico): finiscono sempre
	for sd in 10:
		var s4: Dictionary = _fresh("frammento_blu", "frammento_rosso", 100 + sd)
		var r: int = 0
		while str(s4["winner"]) == "" and r < 60:
			BattleResolver.autoplay_round(s4)
			r += 1
		check(str(s4["winner"]) != "", "partita AUTO %d finita" % sd)

	print("test_v3_due_nemici: " + ("OK" if fails == 0 else "%d FALLITI" % fails))
	quit(1 if fails > 0 else 0)
