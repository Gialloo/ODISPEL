extends SceneTree

# Sblocchi oltre l'atto 1 (fino al livello 100): esistono tutti, hanno nome e testo, si equipaggiano e funzionano in battaglia.
var fails: int = 0


func _chk(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _battle() -> Dictionary:
	var team: Array = []
	for c in Progress.CAST:
		team.append(Progress.entry_for(c))
	var b: Dictionary = BattleState.create_solo("IO", team, [], "distributore", 11)
	Progress.apply_to_battle(b)
	return b


func _unit(b: Dictionary, c: String) -> Dictionary:
	for uid in b["units"]:
		if str(b["units"][uid].get("char", "")) == c and str(b["units"][uid]["side"]) == "player":
			return b["units"][uid]
	return {}


func _init() -> void:
	_chk(Progress.MAX_LEVEL == 100, "si sale fino al 100")
	for c in Progress.CAST:
		var top: int = 0
		var kinds: Dictionary = {}
		for u in Progress.UNLOCKS[c]:
			var kind: String = str(u[1])
			var id: String = str(u[2])
			top = maxi(top, int(u[0]))
			kinds[kind] = int(kinds.get(kind, 0)) + 1
			_chk(Progress.item_name(kind, id) != id, "%s: %s ha un nome" % [c, id])
			_chk(Progress.item_desc(kind, id) != "", "%s: %s ha un testo" % [c, id])
			if kind in ["skill", "ult"]:
				_chk(BattleContent.MOVES.has(id) and str(BattleContent.MOVES[id]["kind"]) == kind, "%s: la mossa %s esiste" % [c, id])
			if kind == "trait":
				_chk(BattleContent.PASSIVES.has(id), "%s: il tratto %s esiste" % [c, id])
			if kind == "react":
				_chk(Progress.REACT_MODS.has(id), "%s: la reazione %s esiste" % [c, id])
			if kind == "syn":
				_chk(Progress.SYNERGIES.has(id) and (Progress.SYNERGIES[id]["pair"] as Array).has(c), "%s: la sinergia %s lo comprende" % [c, id])
		_chk(top == 100, "%s: l'ultimo sblocco e' al 100" % c)
		_chk(int(kinds.get("ult", 0)) >= 5, "%s: almeno cinque Ultimate" % c)

	# l'esperienza porta fino al 100 e poi la barra resta piena
	Progress.reset()
	for _i in 200:
		Progress.grant(5000)
	_chk(Progress.level("nox") == 100 and is_equal_approx(Progress.exp_ratio("nox"), 1.0), "al 100 ci si ferma")
	for c in Progress.CAST:
		for u in Progress.UNLOCKS[c]:
			Progress.equip(c, str(u[1]), str(u[2]))
	# il tratto del 75 conta nelle statistiche
	var base: Dictionary = BattleContent.compute_stats(BattleContent.default_entry("ferri", 100))
	var with_t: Dictionary = BattleContent.compute_stats(Progress.entry_for("ferri"))
	_chk(int(with_t["def"]) > int(base["def"]), "Veterano LibraCorp alza la difesa")
	# il rituale della notte (tutti e quattro): +15% e Ultimate piu' carica
	var b: Dictionary = _battle()
	var lance: Dictionary = _unit(b, "ferri")
	_chk(int(lance.get("syn_gauge", 0)) >= 20, "la sinergia a quattro carica l'Ultimate")
	# Ora zero: toglie equilibrio e ricarica l'Ultimate a tutti
	var nox: Dictionary = _unit(b, "nox")
	nox["gauge"] = 0
	var ev: Array = []
	Kits.extras(b, lance, BattleContent.MOVES["u_ferri_ult5"], ev)
	_chk(int(nox["gauge"]) >= 20, "Ora zero ricarica l'Ultimate della squadra")
	# Interessi composti: esperienza in piu' fino a +100%
	var saul: Dictionary = _unit(b, "saul")
	for _j in 6:
		Kits.extras(b, saul, BattleContent.MOVES["u_saul_g"], ev)
	_chk(int(b.get("exp_bonus", 0)) == 100, "Interessi composti arriva a +100%")
	# reazioni personali: il conto, prego (Saul schiva e risponde forte)
	saul["react_mod"] = "il_conto_prego"
	saul["energy"] = 0
	var boss: Dictionary = BattleState.boss(b)
	var hp0: int = int(boss["hp"])
	_chk(Kits.react_perk(b, boss, saul, "dodge", ev) and int(saul["energy"]) == 2 and int(boss["hp"]) < hp0, "Il conto, prego: energia e colpo")
	_chk(not Kits.react_perk(b, boss, saul, "intercept", ev), "una reazione personale vale solo per la sua reazione")
	lance["react_mod"] = "muro_libracorp"
	_chk(is_equal_approx(Kits.react_dmg_k(lance), 0.4), "Muro della LibraCorp: coprendo prende il 40%")
	nox["react_mod"] = "ci_penso_io"
	_chk(is_equal_approx(Kits.react_rescue_hp(nox), 0.4), "Ci penso io: soccorso con piu' PV")
	print("test_v3_sblocchi_100: " + ("OK" if fails == 0 else "FALLITO (%d)" % fails))
	quit(1 if fails > 0 else 0)
