extends SceneTree

# Progressione (Progress), kit nuovi di Saul e Nox, esiti dei minigiochi delle reazioni.

var fails: int = 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: " + msg)


func _battle(skill_saul: String = "") -> Dictionary:
	var team: Array = []
	for id in Progress.CAST:
		team.append(Progress.entry_for(id))
	var b: Dictionary = BattleState.create_solo("IO", team, [], "frammento_giallo", 7)
	Progress.apply_to_battle(b)
	SeqRound.begin(b)
	return b


func _slot(b: Dictionary, c: String) -> String:
	for p in b["players"]:
		if str(BattleState.active_unit(b, str(p["id"]))["char"]) == c:
			return str(p["id"])
	return ""


func _init() -> void:
	# --- livelli e sblocchi
	Progress.reset()
	check(Progress.level("saul") == 1, "si parte dal livello 1")
	check(Progress.equipped("saul", "skill") == "u_saul_b", "Saul parte con Mano lesta")
	var rep: Array = Progress.grant(Progress.exp_need(1) + Progress.exp_need(2))
	check(Progress.level("ferri") == 3, "due livelli in una volta (livello %d)" % Progress.level("ferri"))
	var news: int = 0
	for r in rep:
		news += (r["news"] as Array).size()
	check(news >= 4, "al livello 3 ognuno sblocca un'abilita' (%d sblocchi)" % news)
	check(Progress.battle_exp(5, true) > Progress.battle_exp(5, false), "il boss vale piu' di un nemico minore")
	check(Progress.battle_exp(9, false) > Progress.battle_exp(1, false), "chi e' indietro prende di piu'")
	# tutte le mosse sbloccabili esistono nel motore
	for c in Progress.UNLOCKS:
		for u in Progress.UNLOCKS[c]:
			if str(u[1]) in ["skill", "ult"]:
				check(BattleContent.MOVES.has(str(u[2])), "manca la mossa " + str(u[2]))
			elif str(u[1]) == "trait":
				check(BattleContent.PASSIVES.has(str(u[2])), "manca il tratto " + str(u[2]))
	# sinergia: equipaggiata da uno dei due, vale per entrambi
	Progress.reset()
	for c in Progress.CAST:
		Progress.data["lv"][c] = 12
	Progress.equip("ferri", "syn", "turno_di_notte")
	var b0: Dictionary = _battle()
	var lance: Dictionary = Kits.unit_of_char(b0, "ferri")
	check(not (lance.get("mods", []) as Array).is_empty(), "la sinergia da' un bonus a Lance")

	# --- Saul: Mano lesta ruba lo scudo
	Progress.reset()
	var b: Dictionary = _battle()
	var boss: Dictionary = BattleState.boss(b)
	boss["shield"] = 120
	var saul: Dictionary = Kits.unit_of_char(b, "saul")
	saul["energy"] = 5
	var sh0: int = int(saul["shield"])
	SeqRound.player_action(b, _slot(b, "saul"), {"swap": "", "move": "u_saul_b", "target": ""})
	check(int(boss["shield"]) == 0, "lo scudo del nemico sparisce")
	check(int(saul["shield"]) >= sh0 + 120, "e passa a Saul")
	# Il trucco del mago: una mossa del nemico, una volta sola
	saul["skills"].append("u_saul_d")
	saul["energy"] = 5
	var ev: Array = SeqRound.player_action(b, _slot(b, "saul"), {"swap": "", "move": "u_saul_d", "target": ""})
	var got: String = ""
	for e in ev:
		if str(e.get("t", "")) == "steal_move":
			got = str(e.get("move", ""))
	check(got != "", "il trucco del mago ruba una mossa")
	check(Progress.add_stolen(got, "il Frammento"), "la mossa rubata si salva")
	check(BattleContent.MOVES.has(Progress.stolen_id(got)), "e diventa una mossa giocabile")
	check(not Progress.add_stolen(got, "il Frammento"), "la stessa mossa non si ruba due volte")
	# Tasche piene: esperienza in piu'
	saul["skills"].append("u_saul_c")
	saul["energy"] = 5
	SeqRound.player_action(b, _slot(b, "saul"), {"swap": "", "move": "u_saul_c", "target": ""})
	check(int(b.get("exp_bonus", 0)) == Kits.LOOT_EXP, "Tasche piene da' +25% esperienza")

	# --- Nox cura di piu' e anche il secondo ferito
	var b2: Dictionary = _battle()
	var hurt: Array = []
	for p in b2["players"]:
		var u: Dictionary = BattleState.active_unit(b2, str(p["id"]))
		if str(u["char"]) != "nox":
			u["hp"] = int(u["max_hp"]) / 3
			hurt.append(u)
	var nox: Dictionary = Kits.unit_of_char(b2, "nox")
	nox["energy"] = 5
	var ev2: Array = SeqRound.player_action(b2, _slot(b2, "nox"), {"swap": "", "move": "u_nox_a", "target": _slot(b2, "ferri")})
	var heals: int = 0
	for e in ev2:
		if str(e.get("t", "")) == "heal" and int(e.get("amount", 0)) > 0:
			heals += 1
	check(heals >= 2, "Pausa caffe' cura due compagni (%d cure)" % heals)

	# --- minigiochi: schivata sbagliata = colpo di striscio, riuscita = niente danno
	for grade in ["fail", "great"]:
		var b3: Dictionary = _battle()
		b3["telegraph"]["move"] = "scarica"
		var tslot: String = str(b3["telegraph"]["target"])
		var tu: Dictionary = BattleState.active_unit(b3, tslot)
		b3["reserve"] = 6
		SeqRound.player_action(b3, tslot, {"swap": "", "move": "schivata", "target": ""})
		(b3["react_grade"] as Dictionary)[str(tu["id"])] = grade
		var hp0: int = int(tu["hp"])
		SeqRound.boss_action(b3)
		if grade == "fail":
			check(int(tu["hp"]) < hp0, "schivata sbagliata: il colpo passa di striscio")
		else:
			check(int(tu["hp"]) == hp0, "schivata riuscita: nessun danno")

	# ABILITA' FIRMA: tutte le abilita' sbloccate in battaglia, quella equipaggiata rende di piu'
	var sk2: Dictionary = {"cost": "", "dmg": "", "shield": ""}
	for id in BattleContent.MOVES:
		if str(BattleContent.MOVES[id].get("kind", "")) == "skill":
			var sk_kind: String = BattleContent.signature_kind(str(id))
			if str(sk2[sk_kind]) == "":
				sk2[sk_kind] = str(id)
	for sk_kind in sk2:
		var mid: String = str(sk2[sk_kind])
		check(mid != "", "esiste un'abilita' firma di tipo " + sk_kind)
		var fu: Dictionary = {"equip_skill": mid}
		var c0: int = int(BattleContent.MOVES[mid]["cost"])
		check(BattleContent.move_cost(fu, mid) == (c0 - 1 if sk_kind == "cost" else c0), "costo della firma " + mid)
		check(BattleContent.move_cost({}, mid) == c0, "senza firma costa il solito " + mid)
	var b4: Dictionary = _battle()
	for p in b4["players"]:
		var pu: Dictionary = BattleState.active_unit(b4, str(p["id"]))
		for o in Progress.options(str(pu["char"]), "skill"):
			if bool(o[1]) and BattleContent.MOVES.has(str(o[0])):
				check((pu["skills"] as Array).has(str(o[0])), "abilita' sbloccata usabile in battaglia: " + str(o[0]))

	if fails == 0:
		print("test_v3_progressione: OK")
	quit(1 if fails > 0 else 0)
