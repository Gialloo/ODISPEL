extends SceneTree

# Colori OPTC (STR/PSY/INT/DEX/QCK), passive e abilita' uniche, rank.
#   godot --headless --path . -s res://tests/unit/test_archetypes.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _unit(char_id: String, rank: int = 0) -> Dictionary:
	var u: Dictionary = BattleState.make_unit("a", BattleContent.default_entry(char_id, 1, rank))
	return u


func _init() -> void:
	_check("contenuti validi", BattleContent.validate().is_empty())
	# colori
	_check("rosso e' STR", Archetypes.of_color("rosso") == "str" and Archetypes.tag_of_color("rosso") == "STR")
	_check("giallo PSY, viola INT, verde DEX, blu QCK", Archetypes.of_color("giallo") == "psy" and Archetypes.of_color("viola") == "int" and Archetypes.of_color("verde") == "dex" and Archetypes.of_color("blu") == "qck")
	var all_colors := true
	for id in BattleContent.CHARACTERS:
		if Archetypes.of_color(str(BattleContent.CHARACTERS[id]["color"])) == "":
			all_colors = false
	_check("ogni personaggio ha un archetipo", all_colors)
	# unita'
	var bruno: Dictionary = _unit("bruno")      # blu = QCK
	_check("QCK parte con ultimate carica", int(bruno["gauge"]) >= Archetypes.QCK_START_GAUGE)
	var sera: Dictionary = _unit("sera")        # verde = DEX
	_check("DEX: piu' danno critico", int(sera["crit_dmg"]) == Factions.CRIT_DMG_PM + Archetypes.DEX_CRIT_DMG_PM)
	var rex: Dictionary = _unit("rex")          # rosso = STR
	var boss: Dictionary = BattleState.make_boss("distributore", 1.0, 0)
	var d0: int = BattleResolver.calc_damage(rex, boss, 1.0)
	rex["momentum"] = 5
	var d5: int = BattleResolver.calc_damage(rex, boss, 1.0)
	_check("STR: lo slancio fa piu' danno", d5 > d0)
	var kira: Dictionary = _unit("kira")        # viola = INT
	var plain: int = BattleResolver.calc_damage(kira, boss, 1.0)
	boss["statuses"]["mark"] = 99
	boss["marks"] = 1
	_check("INT: bonus sui marchiati (e Scintilla viola)", BattleResolver.calc_damage(kira, boss, 1.0) > int(round(float(plain) * (1.0 + Marks.PCT))))
	# abilita' uniche
	var ok_skills := true
	for id in BattleContent.CHARACTERS:
		var n: int = Signatures.all_skills(str(id)).size()
		var rar: int = int(BattleContent.CHARACTERS[id]["rarity"])
		if not Signatures.has_passive(str(id)) or n < 1 or n > 2 or (rar >= 2 and n != 2) or (rar < 2 and n != 1):
			ok_skills = false
			print("  anomalia: ", id, " n=", n, " rar=", rar)
	_check("passiva unica per tutti; 1 skill (comune/rara) o 2 (epica/leggendaria)", ok_skills)
	_check("la seconda skill si sblocca a rank 3", Signatures.skills_for("sera", 0).size() == 1 and Signatures.skills_for("sera", 3).size() == 2)
	_check("l'unita' porta le skill uniche", (_unit("sera", 3)["skills"] as Array).has("u_sera_b") and not (_unit("sera", 0)["skills"] as Array).has("u_sera_b"))
	_check("le skill uniche non cadono come premio", _drops_have_no_unique())
	# rank
	var e0: Dictionary = BattleContent.compute_stats(BattleContent.default_entry("kira", 1, 0))
	var e5: Dictionary = BattleContent.compute_stats(BattleContent.default_entry("kira", 1, 5))
	_check("rank 5: +40% di statistiche", float(e5["atk"]) / float(e0["atk"]) > 1.38)
	_check("la passiva sale con il rank", Signatures.passive_value("dax", 5) > Signatures.passive_value("dax", 0) * 1.7)
	_check("risveglio a rank 5", bool(_unit("kira", 5)["awake"]) and not bool(_unit("kira", 4)["awake"]))
	_check("testo passiva leggibile", Signatures.passive_text("eco", 0).contains("ultimate") and Signatures.passive_text("dax", 2).contains("%"))
	# lo stato resta JSON
	var s: Dictionary = BattleState.create([{"id": "a", "name": "a", "ai": false, "team": [BattleContent.default_entry("dax", 1, 5), BattleContent.default_entry("elle", 1, 3)]}], "distributore", 9)
	for i in 3:
		BattleResolver.resolve_round(s, true)
	_check("JSON identico dopo 3 round", BattleState.to_json(s) == BattleState.to_json(BattleState.from_json(BattleState.to_json(s))))
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _drops_have_no_unique() -> bool:
	var rng := RNGState.new()
	rng.setup(5)
	for i in 200:
		for d in BattleContent.roll_drops("distributore", rng, 2):
			if str(d["kind"]) == "move" and BattleContent.MOVES[str(d["id"])].has("unique"):
				return false
	return true
