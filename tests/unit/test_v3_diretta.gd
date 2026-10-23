extends SceneTree

# ULTIMATE IN DIRETTA, SLANCIO e ATTACCO DI SQUADRA: le regole nuove del giro 2 sul combattimento (SeqRound).

var fails: int = 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: " + msg)


func _battle() -> Dictionary:
	var team: Array = []
	for id in ["ferri", "nox", "zecca", "saul"]:
		team.append(BattleContent.default_entry(id))
	return BattleState.create_solo("IO", team, [], "distributore", 3)


func _init() -> void:
	var b: Dictionary = _battle()
	SeqRound.begin(b)
	var nox_pid: String = ""
	for p in b["players"]:
		if str(BattleState.active_unit(b, str(p["id"]))["char"]) == "nox":
			nox_pid = str(p["id"])
	var other: String = str(b["players"][0]["id"]) if str(b["players"][0]["id"]) != nox_pid else str(b["players"][1]["id"])
	# senza carica o senza barra piena: nessuna Ultimate in diretta
	b["telegraph"] = {"move": "scarica", "target": other}
	for p in b["players"]:
		BattleState.active_unit(b, str(p["id"]))["gauge"] = 0
	check(SeqRound.live_ults(b, other).is_empty(), "barre vuote: niente Ultimate in diretta")
	BattleState.active_unit(b, nox_pid)["gauge"] = 100
	var l: Array = SeqRound.live_ults(b, other)
	check(l.size() == 1 and str(l[0]) == nox_pid, "carica + barra piena: Nox puo' lanciare in diretta")
	check(not SeqRound.live_ults(b, nox_pid).has(nox_pid), "chi sta scegliendo non e' in elenco")
	b["telegraph"] = {"move": "flash", "target": other}
	b["telegraph"]["move"] = "scarica"
	var reserve: int = int(b["reserve"])
	SeqRound.player_action(b, nox_pid, {"swap": "", "move": str(BattleState.active_unit(b, nox_pid)["ult"]), "target": ""})
	check(int(b["reserve"]) == reserve, "l'Ultimate in diretta non costa Riserva")
	check(int(BattleState.active_unit(b, nox_pid)["gauge"]) < 100, "l'Ultimate in diretta spende la barra")
	# SLANCIO: al massimo uno a round
	var b2: Dictionary = _battle()
	SeqRound.begin(b2)
	var slanci: int = 0
	for p in b2["players"]:
		var ev: Array = SeqRound.player_action(b2, str(p["id"]), {"swap": "", "move": "attack", "target": ""})
		for e in ev:
			if str(e.get("t", "")) == "slancio":
				slanci += 1
	check(slanci <= 1, "SLANCIO al massimo una volta a round (%d)" % slanci)
	# azione rapida: solo Attacco o Guardia
	var b3: Dictionary = _battle()
	SeqRound.begin(b3)
	var pid3: String = str(b3["players"][0]["id"])
	var u3: Dictionary = BattleState.active_unit(b3, pid3)
	u3["gauge"] = 100
	var ev3: Array = SeqRound.player_action(b3, pid3, {"swap": "", "move": str(u3["ult"]), "target": ""}, true)
	var used_ult: bool = false
	for e in ev3:
		if str(e.get("t", "")) == "act" and str(e.get("move", "")) == str(u3["ult"]):
			used_ult = true
	check(not used_ult, "azione rapida: l'Ultimate non e' ammessa")
	if fails == 0:
		print("OK test_v3_diretta")
	quit(1 if fails > 0 else 0)
