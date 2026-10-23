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
	# reazione con la Riserva: solo se serve davvero (regola semplice, vedi _reaction)
	var react: String = _reaction(state, pid, me, tele, tele_move)
	if react != "":
		choice["move"] = react
		return choice
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


# REAZIONE dell'IA (AUTO): contro una carica annunciata, e solo una a round, costa il turno e la Riserva di squadra, quindi
# si usa solo se la squadra rischia davvero:
#  1. Soccorso: c'e' un caduto (ricomprare un compagno vale piu' di un colpo);
#  2. Schivata: la carica e' su di me (o su tutti) e sono sotto il 50% PV;
#  3. Intercettazione: la carica e' su un compagno sotto il 50% PV e io sto sopra il 60%;
#  4. Interruzione: all'equilibrio del boss mancano al massimo i punti che toglie (la rottura annulla la carica).

static func _reaction(state: Dictionary, pid: String, me: Dictionary, tele: Dictionary, tele_move: Dictionary) -> String:
	if not BattleState.is_alive(me) or not (state.get("reactions", []) as Array).is_empty():
		return ""
	var ok: Dictionary = {}
	for r in BattleResolver.reactions_for(state, pid):
		if str(r["err"]) == "":
			ok[str(r["id"])] = true
	if ok.is_empty():
		return ""
	if ok.has("soccorso"):
		return "soccorso"
	var tgt: String = str(tele.get("target", ""))
	var all: bool = str(tele_move.get("target", "")) == "all"
	var on_me: bool = tgt == pid or all
	if ok.has("schivata") and on_me and _ratio(me) < 0.5:
		return "schivata"
	if ok.has("intercettazione") and not all and tgt != "" and tgt != pid and _ratio(me) > 0.6:
		var victim: Dictionary = BattleState.active_unit(state, tgt)
		if BattleState.is_alive(victim) and _ratio(victim) < 0.5:
			return "intercettazione"
	if ok.has("interruzione"):
		var boss: Dictionary = BattleState.boss(state)
		if not bool(boss.get("exposed", false)) and int(boss.get("balance", 99)) <= BattleTypes.INTERRUPT_PTS:
			return "interruzione"
	return ""


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
		var kit_ult: int = Kits.ai_wants(state, u, ult, umove)
		if kit_ult == 1:
			return ult
		if kit_ult == -1 and umove.has("mult"):
			return ult
		if kit_ult == -1 and umove.has("heal") and not lowest.is_empty() and _ratio(lowest) < 0.6:
			return ult
		if kit_ult == -1 and umove.has("shield") and heavy:
			return ult

	var skills: Array = u["skills"]
	for sid in skills:
		var m: Dictionary = BattleContent.MOVES[str(sid)]
		if str(m["kind"]) == "basic":
			continue
		if energy < int(m["cost"]):
			continue
		var kit_say: int = Kits.ai_wants(state, u, str(sid), m)
		if kit_say == 0:
			continue
		if kit_say == 1:
			if str(m["target"]) == "ally" and not lowest.is_empty():
				choice["target"] = BattleState.slot_of(state, str(lowest["id"]))
			return str(sid)
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
