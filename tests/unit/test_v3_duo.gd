extends SceneTree

# Fase 5: tecniche combinate (DuoTechs). Costano energia a tutti e due e il compagno salta il suo turno.
var fails: int = 0


func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _fresh() -> Dictionary:
	var t: Array = []
	for id in ["ferri", "nox", "zecca", "saul"]:
		t.append(BattleContent.default_entry(id))
	var s: Dictionary = BattleState.create_solo("IO", t, [], "distributore", 3)
	SeqRound.begin(s)
	return s


func _pid(s: Dictionary, c: String) -> String:
	for p in s["players"]:
		if str(BattleState.active_unit(s, str(p["id"]))["char"]) == c:
			return str(p["id"])
	return ""


func _u(s: Dictionary, c: String) -> Dictionary:
	return BattleState.active_unit(s, _pid(s, c))


func _has(ev: Array, t: String) -> bool:
	for e in ev:
		if str(e.get("t", "")) == t:
			return true
	return false


func _init() -> void:
	check(DuoTechs.DUOS.size() == 6, "sei coppie per quattro personaggi")
	for id in DuoTechs.DUOS:
		check(BattleContent.MOVES.has(id) and str(BattleContent.MOVES[id]["kind"]) == "duo", "mossa %s registrata" % id)
	check(DuoTechs.of_char("ferri").size() == 3, "Lance ha tre tecniche")
	# Primo piano (Lance + Rio): danno, hype, energia e turno di Rio speso
	var s: Dictionary = _fresh()
	_u(s, "ferri")["energy"] = 3
	_u(s, "zecca")["energy"] = 3
	var hype0: int = int(_u(s, "zecca").get("hype", 0))
	check(BattleResolver.validate_choice(s, _pid(s, "ferri"), {"swap": "", "move": "duo_ferri_zecca", "target": ""}) == "", "Primo piano valido")
	var ev: Array = SeqRound.player_action(s, _pid(s, "ferri"), {"swap": "", "move": "duo_ferri_zecca", "target": ""})
	check(_has(ev, "duo"), "evento duo")
	check(int(BattleState.boss(s)["hp"]) < int(BattleState.boss(s)["max_hp"]), "il nemico prende danno")
	check(int(_u(s, "ferri")["energy"]) == 1 and int(_u(s, "zecca")["energy"]) == 1, "2 EN a testa")
	check(int(_u(s, "zecca").get("hype", 0)) > hype0, "Rio guadagna Hype")
	ev = SeqRound.player_action(s, _pid(s, "zecca"), {"swap": "", "move": "attack", "target": ""})
	check(_has(ev, "duo_rest") and not _has(ev, "act"), "Rio ha dato il suo turno")
	# il compagno che ha gia' agito non puo' unirsi
	s = _fresh()
	_u(s, "nox")["energy"] = 3
	_u(s, "saul")["energy"] = 3
	SeqRound.player_action(s, _pid(s, "saul"), {"swap": "", "move": "attack", "target": ""})
	check(BattleResolver.validate_choice(s, _pid(s, "nox"), {"swap": "", "move": "duo_nox_saul", "target": ""}) != "", "Saul ha gia' agito: niente tecnica")
	# energia insufficiente
	s = _fresh()
	_u(s, "nox")["energy"] = 1
	_u(s, "zecca")["energy"] = 3
	check(BattleResolver.validate_choice(s, _pid(s, "zecca"), {"swap": "", "move": "duo_nox_zecca", "target": ""}) != "", "serve energia a tutti e due")
	# Turno di notte: scudo e cura a tutti
	s = _fresh()
	_u(s, "ferri")["energy"] = 2
	_u(s, "nox")["energy"] = 2
	_u(s, "saul")["hp"] = int(_u(s, "saul")["max_hp"]) / 2
	var hp0: int = int(_u(s, "saul")["hp"])
	ev = SeqRound.player_action(s, _pid(s, "nox"), {"swap": "", "move": "duo_ferri_nox", "target": ""})
	check(int(_u(s, "saul")["hp"]) > hp0 and int(_u(s, "saul")["shield"]) > 0, "Turno di notte: cura e scudo a Saul")
	# l'IA la usa quando serve
	s = _fresh()
	_u(s, "ferri")["energy"] = 3
	_u(s, "nox")["energy"] = 3
	_u(s, "saul")["hp"] = int(_u(s, "saul")["max_hp"]) / 3
	check(DuoTechs.ai_pick(s, _u(s, "nox")) in ["duo_ferri_nox", "duo_nox_zecca"], "IA: tecnica di supporto con un ferito")
	if fails == 0:
		print("OK test_v3_duo")
	quit(1 if fails > 0 else 0)
