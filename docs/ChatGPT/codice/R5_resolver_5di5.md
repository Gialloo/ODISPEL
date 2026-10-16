FILE battle_resolver.gd - PARTE 5 DI 5
Percorso: scripts/battle/battle_resolver.gd
(Codice GDScript, rientri con tab. Questa e' l'ultima parte: ora puoi analizzare tutto il file.)

```gdscript
static func _summon_upkeep(state: Dictionary, events: Array, shoot: bool) -> void:
	var list: Array = state["summons"]
	if list.is_empty():
		return
	var boss: Dictionary = BattleState.boss(state)
	for i in range(list.size() - 1, -1, -1):
		var s: Dictionary = list[i]
		var owner: Dictionary = BattleState.unit(state, str(s["owner"]))
		var kind: String = str(s["kind"])
		if not BattleState.is_alive(owner):
			list.remove_at(i)
			events.append({"t": "summon_end", "unit": str(s["owner"]), "kind": kind, "reason": "down"})
			continue
		if shoot and BattleState.is_alive(boss) and int(owner["ammo"]) > 0:
			events.append({"t": "summon_shot", "unit": owner["id"], "kind": kind})
			_change_ammo(owner, -1, events)
			_hit(state, owner, boss, TURRET_MULT if kind == "turret" else DRONE_MULT, events, 0, 0.0, true)
		if int(owner["ammo"]) <= 0:
			list.remove_at(i)
			events.append({"t": "summon_end", "unit": owner["id"], "kind": kind, "reason": "ammo"})
			if kind == "turret":
				if BattleState.is_alive(boss):
					_hit(state, owner, boss, TURRET_BLAST_MULT, events, 0, 0.0, true)
			else:
				var amount: int = int(round(float(owner["atk"]) * DRONE_SHIELD_MULT * Archetypes.support_mult(owner)))
				for uid in BattleState.player(state, str(owner["owner"]))["team"]:
					var mate: Dictionary = BattleState.unit(state, uid)
					if BattleState.is_alive(mate):
						mate["shield"] = int(mate["shield"]) + amount
						events.append({"t": "shield", "src": owner["id"], "dst": mate["id"], "amount": amount})
	_check_winner(state, events)


static func _boss_act(state: Dictionary, boss: Dictionary, move_id: String, target_pid: String, rng: RNGState, events: Array) -> void:
	var move: Dictionary = BattleContent.BOSS_MOVES[move_id]
	events.append({"t": "boss_move", "move": move_id})
	var targets: Array = []
	if str(move["target"]) == "all":
		for p in BattleState.alive_players(state):
			targets.append(BattleState.active_unit(state, str(p["id"])))
	else:
		var chosen: Dictionary = BattleState.player(state, target_pid)
		# la provocazione devia il colpo
		for p in BattleState.alive_players(state):
			var au: Dictionary = BattleState.active_unit(state, str(p["id"]))
			if BattleState.is_alive(au) and au["statuses"].has("taunt"):
				chosen = p
				break
		if chosen.is_empty() or not BattleState.player_alive(state, chosen):
			var alive: Array = BattleState.alive_players(state)
			if not alive.is_empty():
				chosen = alive[rng.random_index(alive.size())]
		if not chosen.is_empty():
			targets.append(BattleState.active_unit(state, str(chosen["id"])))

	if move.has("self_shield"):
		var shield: int = int(round(float(boss["max_hp"]) * float(move["self_shield"])))
		boss["shield"] = int(boss["shield"]) + shield
		events.append({"t": "shield", "src": boss["id"], "dst": boss["id"], "amount": shield})

	var beh_mult: float = Arena.boss_behavior(state, boss, events) * Tactics.boss_boost(state) * (Tactics.CHAIN_MULT if bool(state.get("in_chain", false)) else 1.0)
	var reacted: bool = not state.get("reactions", []).is_empty()
	var heavy: bool = is_heavy_boss_move(move)
	var reserve_then: int = int(state.get("reserve", 0))
	var lost_total: int = 0
	var intercepted: Dictionary = {}
	for r in state.get("reactions", []):
		if str(r["react"]) == "intercept":
			intercepted = BattleState.unit(state, str(r["unit"]))
	for t in targets:
		if not BattleState.is_alive(t):
			continue
		var evaded: bool = false
		for r in state.get("reactions", []):
			if str(r["react"]) == "dodge" and str(r["unit"]) == str(t["id"]):
				evaded = true
		if evaded:
			events.append({"t": "dodge", "unit": t["id"], "react": true})
			continue
		var hit_mult: float = float(move["mult"]) * beh_mult
		if not intercepted.is_empty() and BattleState.is_alive(intercepted) and str(intercepted["id"]) != str(t["id"]) and targets.size() == 1:
			t = intercepted
			hit_mult *= BattleTypes.INTERCEPT_FACTOR
		var hp_before: int = int(t["hp"])
		_hit(state, boss, t, hit_mult, events)
		lost_total += hp_before - int(t["hp"])
		_counter(state, boss, t, events)
		var drain: float = float(move.get("drain", 0.0)) + float(state.get("boss_drain", 0.0))
		if drain > 0.0:
			var dealt: int = hp_before - int(t["hp"])
			var before: int = int(boss["hp"])
			boss["hp"] = mini(int(boss["max_hp"]), before + int(round(float(dealt) * drain)))
			if int(boss["hp"]) > before:
				events.append({"t": "heal", "src": boss["id"], "dst": boss["id"], "amount": int(boss["hp"]) - before})
		if move.has("status") and BattleState.is_alive(t):
			for s in move["status"]:
				_add_status(t, str(s), int(move["status"][s]), events)
	if heavy:
		# resoconto: una carica e' "gestita" se qualcuno ha reagito o non ha fatto danno
		events.append({"t": "threat", "move": move_id, "handled": reacted or lost_total <= 0, "could": reserve_then >= 1, "lost": lost_total})
	if not bool(state.get("in_chain", false)):
		Tactics.chain_followup(state, boss, reacted, rng, events)


# ---------- Fine round ----------

static func _end_of_round(state: Dictionary, events: Array) -> void:
	var units: Dictionary = state["units"]
	_summon_upkeep(state, events, true)
	if str(state["winner"]) != "" or not BattleState.is_alive(BattleState.boss(state)):
		_check_winner(state, events)
		return

	# sanguinamento (ignora gli scudi)
	for uid in units:
		var u: Dictionary = units[uid]
		if BattleState.is_alive(u) and u["statuses"].has("bleed"):
			var dmg: int = maxi(1, int(float(u["max_hp"]) * BattleTypes.BLEED_FRACTION))
			u["hp"] = maxi(0, int(u["hp"]) - dmg)
			events.append({"t": "bleed", "unit": uid, "amount": dmg})
			if int(u["hp"]) <= 0:
				_on_down(u, events)

	# durata degli stati e fine degli scudi
	for uid in units:
		var u: Dictionary = units[uid]
		var expired: Array = []
		for s in u["statuses"]:
			u["statuses"][s] = int(u["statuses"][s]) - 1
			if int(u["statuses"][s]) <= 0:
				expired.append(s)
		for s in expired:
			u["statuses"].erase(s)
		u["shield"] = 0

	# passive uniche di fine round: rigenerazione, scudo che riparte, carica dell'ultimate
	for uid in units:
		var pu: Dictionary = units[uid]
		if not BattleState.is_alive(pu) or str(pu["side"]) != "player":
			continue
		var rg: float = Signatures.value(pu, "regen")
		if rg > 0.0:
			var before_hp: int = int(pu["hp"])
			pu["hp"] = mini(int(pu["max_hp"]), before_hp + int(round(float(pu["max_hp"]) * rg)))
			if int(pu["hp"]) > before_hp:
				events.append({"t": "heal", "src": uid, "dst": uid, "amount": int(pu["hp"]) - before_hp})
		var rs: float = Signatures.value(pu, "round_shield")
		if rs > 0.0:
			pu["shield"] = int(round(float(pu["max_hp"]) * rs))
		var gr: float = Signatures.value(pu, "gauge_regen")
		if gr > 0.0:
			pu["gauge"] = mini(BattleTypes.GAUGE_MAX, int(pu["gauge"]) + int(round(gr)))

	# sostegno dalla panchina: i guardiani a riposo aiutano chi combatte (un guardiano per giocatore)
	for p in state["players"]:
		var act: Dictionary = BattleState.unit(state, str(p["active"]))
		if act.is_empty() or not BattleState.is_alive(act):
			continue
		for uid in BattleState.party_of(state, p):
			var bu: Dictionary = BattleState.unit(state, str(uid))
			if str(uid) == str(p["active"]) or not BattleState.is_alive(bu) or not Signatures.has_bench(str(bu.get("char", ""))):
				continue
			events.append_array(Signatures.apply_bench(bu, act, Signatures.BENCH_PVE_FACTOR))

	Atypical.end_of_round(state, events)

	# energia: chi sta in back row recupera di piu'
	for p in state["players"]:
		for uid in p["team"]:
			var u: Dictionary = BattleState.unit(state, uid)
			if not BattleState.is_alive(u):
				continue
			var gain: int = (BattleTypes.REGEN_ACTIVE if BattleState.is_front(state, str(uid)) else BattleTypes.REGEN_BENCH) + Archetypes.round_energy(u)
			u["energy"] = mini(BattleTypes.MAX_ENERGY, int(u["energy"]) + gain)

	# se l'attivo e' caduto entra il compagno con piu' vita
	for p in state["players"]:
		_auto_replace(state, p, events)

	# Riserva di squadra: +1 a round; dalla fase 2 il boss ne divora una parte (le priorita' cambiano: non basta piu' accumulare)
	_gain_reserve(state, BattleTypes.RESERVE_PER_ROUND, "round", events)
	var bs: Dictionary = BattleState.boss(state)
	if int(state.get("phase", 1)) >= 2 and int(bs.get("stun", 0)) == 0 and int(state.get("reserve", 0)) > 0:
		_spend_reserve(state, BattleTypes.RESERVE_DRAIN_ROUND, "boss", events)

	# modifiche temporanee e aure di fazione (chi e' caduto non da' piu' aure)
	Factions.tick(state)
	Factions.refresh(state)


static func _auto_replace(state: Dictionary, p: Dictionary, events: Array) -> void:
	if BattleState.is_alive(BattleState.unit(state, str(p["active"]))):
		return
	var best: String = ""
	var best_ratio: float = -1.0
	for uid in BattleState.back_row(state, p):
		var u: Dictionary = BattleState.unit(state, uid)
		var ratio: float = float(u["hp"]) / float(u["max_hp"])
		if ratio > best_ratio:
			best_ratio = ratio
			best = uid
	if best != "":
		_do_swap(state, p, best, events)


static func _check_winner(state: Dictionary, events: Array) -> void:
	if str(state["winner"]) != "":
		return
	if not BattleState.is_alive(BattleState.boss(state)):
		state["winner"] = "players"
	elif BattleState.alive_players(state).is_empty():
		state["winner"] = "boss"
	if str(state["winner"]) != "":
		events.append({"t": "end", "winner": state["winner"]})
```
