class_name BattleAI
extends RefCounted

# IA dei giocatori controllati dal computer. Non usa numeri casuali: a parita'
# di stato sceglie sempre la stessa mossa.


static func _ratio(u: Dictionary) -> float:
	return float(u["hp"]) / float(u["max_hp"])


static func choose(state: Dictionary, pid: String) -> Dictionary:
	var p: Dictionary = BattleState.player(state, pid)
	var choice: Dictionary = {"swap": "", "move": BattleTypes.ACTION_ATTACK, "target": ""}
	var me: Dictionary = BattleState.active_unit(state, pid)
	if p.is_empty():
		return choice

	var tele: Dictionary = state["telegraph"]
	var tele_move: Dictionary = BattleContent.BOSS_MOVES.get(str(tele.get("move", "")), {})
	var targeted: bool = str(tele.get("target", "")) == pid or str(tele_move.get("target", "")) == "all"

	# cambio: se sono quasi a terra e il boss mi colpira', entra chi sta meglio
	var current: Dictionary = me
	if BattleState.is_alive(me) and _ratio(me) < 0.35 and targeted:
		var best: String = ""
		var best_ratio: float = _ratio(me) + 0.25
		var taken: Dictionary = {}
		for q in state["players"]:
			if q["choice"] is Dictionary and str(q["choice"].get("swap", "")) != "":
				taken[str(q["choice"]["swap"])] = true
		for uid in BattleState.back_row(state, p):
			var u: Dictionary = BattleState.unit(state, uid)
			if not taken.has(uid) and _ratio(u) > best_ratio:
				best_ratio = _ratio(u)
				best = uid
		if best != "":
			choice["swap"] = best
			current = BattleState.unit(state, best)
	if not BattleState.is_alive(current):
		return choice

	var move_id: String = _pick_move(state, p, current, tele_move, str(tele.get("target", "")), choice)
	choice["move"] = move_id
	if BattleResolver.validate_choice(state, pid, choice) != "":
		choice["move"] = _basic_for(current)
	return choice


# Mossa di ripiego: Attacco se e' nel kit, altrimenti Guardia, altrimenti la prima mossa.
static func _basic_for(u: Dictionary) -> String:
	var sk: Array = u.get("skills", [])
	if sk.has(BattleTypes.ACTION_ATTACK) or sk.is_empty():
		return BattleTypes.ACTION_ATTACK
	if sk.has(BattleTypes.ACTION_GUARD):
		return BattleTypes.ACTION_GUARD
	return str(sk[0])


static func _team_buffed(state: Dictionary, stat: String) -> bool:
	for q in state["players"]:
		var u: Dictionary = BattleState.active_unit(state, str(q["id"]))
		for m in u.get("mods", []):
			if str(m.get("id", "")) == "buff_" + stat and int(m.get("turns", 0)) > 0:
				return true
	return false


static func _lowest_ally(state: Dictionary) -> Dictionary:
	var worst: Dictionary = {}
	var worst_ratio: float = 2.0
	for q in state["players"]:
		var u: Dictionary = BattleState.active_unit(state, str(q["id"]))
		if BattleState.is_alive(u) and _ratio(u) < worst_ratio:
			worst_ratio = _ratio(u)
			worst = u
	return worst


static func _pick_move(state: Dictionary, p: Dictionary, u: Dictionary, tele_move: Dictionary, tele_target: String, choice: Dictionary) -> String:
	var pid: String = str(p["id"])
	var energy: int = int(u["energy"])
	var boss: Dictionary = BattleState.boss(state)
	var lowest: Dictionary = _lowest_ally(state)
	var heavy: bool = float(tele_move.get("mult", 0.0)) >= 1.2 or str(tele_move.get("target", "")) == "all"

	# ultimate: attacchi sempre, supporto quando serve
	var ult: String = str(u["ult"])
	if ult != "" and int(u["gauge"]) >= BattleTypes.GAUGE_MAX:
		var umove: Dictionary = BattleContent.MOVES[ult]
		if umove.has("mult"):
			return ult
		if umove.has("heal") and not lowest.is_empty() and _ratio(lowest) < 0.6:
			return ult
		if umove.has("shield") and heavy:
			return ult

	var skills: Array = u["skills"]
	for sid in skills:
		var m: Dictionary = BattleContent.MOVES[str(sid)]
		if str(m["kind"]) == "basic":
			continue
		if energy < int(m["cost"]):
			continue
		# i supporti tengono acceso il bonus di attacco della squadra (dura 2 turni: lo rinnovano quando scade)
		if m.has("ally_buff") and not _team_buffed(state, "atk") and not lowest.is_empty():
			if str(m["target"]) == "ally":
				choice["target"] = BattleState.slot_of(state, str(lowest["id"]))
			return str(sid)
		if m.has("heal") and not lowest.is_empty() and (_ratio(lowest) < 0.55 or (bool(m.get("cleanse", false)) and lowest["statuses"].has("bleed"))):
			choice["target"] = BattleState.slot_of(state, str(lowest["id"]))
			return str(sid)
		if m.has("shield") and str(m["target"]) == "allies" and heavy:
			return str(sid)
		if m.has("self_status") and m["self_status"].has("taunt") and tele_target != str(p["id"]) and tele_target != "" and str(tele_move.get("target", "")) == "one":
			var victim: Dictionary = BattleState.active_unit(state, tele_target)
			if BattleState.is_alive(victim) and _ratio(victim) < _ratio(u):
				return str(sid)
		# LibraCorp: ricarica a secco; i colpi con munizioni lasciano sempre una carica per il contrattacco
		if m.has("ammo_gain") and int(u["ammo_max"]) > 0 and int(u["ammo"]) == 0:
			return str(sid)
		if m.has("ammo") and int(u["ammo"]) - int(m["ammo"]) >= 1:
			return str(sid)
		if m.has("status") and m["status"].has("mark") and Marks.count(boss) < 3:
			return str(sid)
		if m.has("mult") and float(m["mult"]) >= 2.0 and energy >= int(m["cost"]) + 1:
			return str(sid)

	if _ratio(u) < 0.3 and tele_target == pid and str(tele_move.get("target", "")) == "one" and skills.has(BattleTypes.ACTION_GUARD):
		return BattleTypes.ACTION_GUARD
	return _basic_for(u)
