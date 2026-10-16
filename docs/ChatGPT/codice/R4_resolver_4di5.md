FILE battle_resolver.gd - PARTE 4 DI 5
Percorso: scripts/battle/battle_resolver.gd
(Codice GDScript, rientri con tab. Non rispondere finche' non scrivo FINE FILE.)

```gdscript
static func _spend_reserve(state: Dictionary, n: int, why: String, events: Array) -> void:
	var after: int = maxi(0, int(state.get("reserve", 0)) - n)
	events.append({"t": "reserve", "delta": after - int(state.get("reserve", 0)), "value": after, "why": why, "wasted": 0})
	state["reserve"] = after


# SOCCORSO: rimette in piedi un compagno caduto della propria squadra (25% PV). Una sola volta a testa: la sconfitta resta possibile.
static func _rescue(state: Dictionary, actor: Dictionary, move_id: String, events: Array) -> bool:
	var owner: Dictionary = BattleState.player(state, str(actor["owner"]))
	if owner.is_empty() or reaction_error(state, owner, move_id) != "":
		return false
	var who: String = fallen_of(state, owner)
	var u: Dictionary = BattleState.unit(state, who)
	_spend_reserve(state, reaction_cost(state, move_id), "react", events)
	events.append({"t": "act", "unit": actor["id"], "move": move_id})
	var hp: int = maxi(1, int(round(float(u["max_hp"]) * BattleTypes.RESCUE_HP)))
	u["hp"] = hp
	u["rescued"] = true
	u["statuses"] = {}
	events.append({"t": "rescue", "unit": actor["id"], "who": who, "hp": hp})
	return true


# Esegue una reazione. Falso se non e' piu' possibile (Riserva finita per colpa di un compagno, carica gia' fermata).
static func _react(state: Dictionary, actor: Dictionary, move_id: String, events: Array) -> bool:
	var move: Dictionary = BattleContent.MOVES[move_id]
	var owner: Dictionary = BattleState.player(state, str(actor["owner"]))
	if owner.is_empty() or reaction_error(state, owner, move_id) != "":
		return false
	for r in state.get("reactions", []):
		if str(r["react"]) == "interrupt" and str(move["react"]) == "interrupt":
			return false             # una sola Interruzione a round
	_spend_reserve(state, reaction_cost(state, move_id), "react", events)
	events.append({"t": "act", "unit": actor["id"], "move": move_id})
	var list: Array = state.get("reactions", [])
	list.append({"unit": str(actor["id"]), "react": str(move["react"])})
	state["reactions"] = list
	var boss: Dictionary = BattleState.boss(state)
	events.append({"t": "react", "unit": actor["id"], "kind": str(move["react"]), "move": str(state["telegraph"]["move"])})
	if str(move["react"]) == "interrupt":
		_drain_balance(boss, BattleTypes.INTERRUPT_PTS + (1 if str(state.get("order", "")) == "interrompi" else 0), actor, events)
		actor["gauge"] = mini(BattleTypes.GAUGE_MAX, int(actor["gauge"]) + 10)
	return true


static func _player_act(state: Dictionary, actor: Dictionary, move_id: String, target_pid: String, events: Array) -> void:
	var move: Dictionary = BattleContent.MOVES[move_id]
	var kind: String = str(move["kind"])
	if kind == "reaction" or kind == "rescue":
		if not (_rescue(state, actor, move_id, events) if kind == "rescue" else _react(state, actor, move_id, events)):
			move_id = BattleTypes.ACTION_GUARD
			move = BattleContent.MOVES[move_id]
			kind = "basic"
		else:
			return
	# controlli al momento dell'esecuzione
	if kind == "ult" and int(actor["gauge"]) < BattleTypes.GAUGE_MAX:
		move_id = BattleTypes.ACTION_ATTACK
		move = BattleContent.MOVES[move_id]
		kind = "basic"
	elif kind == "skill" and (int(actor["energy"]) < int(move["cost"]) or int(actor["ammo"]) < int(move.get("ammo", 0))):
		move_id = BattleTypes.ACTION_ATTACK
		move = BattleContent.MOVES[move_id]
		kind = "basic"

	if kind == "ult":
		actor["gauge"] = 0
	elif kind == "skill":
		actor["energy"] = int(actor["energy"]) - int(move["cost"])
	events.append({"t": "act", "unit": actor["id"], "move": move_id})
	var acts: Dictionary = state.get("acts", {})
	acts[str(actor["id"])] = move_id
	state["acts"] = acts
	if move.has("self_cost_hp"):
		# il prezzo del salvataggio: l'operatore paga con i propri PV (ne resta sempre almeno 1)
		var paid: int = mini(int(actor["hp"]) - 1, int(round(float(actor["max_hp"]) * float(move["self_cost_hp"]))))
		if paid > 0:
			actor["hp"] = int(actor["hp"]) - paid
			events.append({"t": "damage", "src": actor["id"], "dst": actor["id"], "amount": paid, "absorbed": 0, "cost": true})
	Combos.record(state, actor, move)
	var link_n: int = _chain_link(state, actor, events)
	var link_gain: float = BattleTypes.LINK_BONUS + Signatures.value(actor, "link_boost")
	var awake_mult: float = Signatures.upgrade_mult(actor, move_id, kind) * Tactics.mastery_mult(actor, move_id)
	# RITMO: cambiare mossa rispetto al round prima da' un po' di danno in piu' (chi ripete sempre lo stesso colpo non ne gode)
	var last_move: String = str(actor.get("last_move", ""))
	if move.has("mult") and last_move != "" and last_move != move_id and str(move["target"]) == "enemy":
		awake_mult *= BattleTypes.RHYTHM_BONUS
		events.append({"t": "rhythm", "unit": actor["id"]})
	var rep: int = int(actor.get("repeat", 0)) + 1 if last_move == move_id else 0
	actor["repeat"] = rep
	if rep >= 2 and move.has("mult") and str(move["target"]) == "enemy":
		awake_mult *= BattleTypes.ADAPT_MULT
		events.append({"t": "adapt", "unit": actor["id"], "move": move_id})
	actor["last_move"] = move_id
	if move_id == "attack":
		awake_mult *= BattleContent.basic_factor(actor)
	_change_ammo(actor, int(move.get("ammo_gain", 0)) - int(move.get("ammo", 0)), events)

	var gsh: float = Signatures.value(actor, "guard_shield")
	if gsh > 0.0 and move_id == BattleTypes.ACTION_GUARD:
		var gs_amount: int = int(round(float(actor["max_hp"]) * gsh))
		actor["shield"] = int(actor["shield"]) + gs_amount
		events.append({"t": "shield", "src": actor["id"], "dst": actor["id"], "amount": gs_amount})
	if move.has("energy"):
		actor["energy"] = mini(BattleTypes.MAX_ENERGY, int(actor["energy"]) + int(move["energy"]))
	if move.has("self_status"):
		for s in move["self_status"]:
			_add_status(actor, str(s), int(move["self_status"][s]), events)

	var targets: Array = []
	match str(move["target"]):
		"enemy":
			targets = [BattleState.boss(state)]
		"self":
			targets = [actor]
		"ally":
			var t: Dictionary = BattleState.active_unit(state, target_pid)
			if not BattleState.is_alive(t) or str(t["side"]) != "player":
				t = actor
			targets = [t]
		"allies":
			for p in state["players"]:
				var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
				if BattleState.is_alive(u):
					targets.append(u)

	var bonus: float = BattleContent.move_bonus(actor, move)
	# forma potenziata delle Rondini: la carica dell'aura si spende sul prossimo attacco
	var empowered: bool = move.has("mult") and Factions.ronda_ready(actor)
	var emp_mult: float = 1.0
	var emp_crit: int = 0
	if empowered:
		emp_mult = Factions.RONDA_MULT * (Factions.RONDA_UNIQUE_MULT if (kind == "ult" or move.has("unique")) else 1.0)
		emp_crit = Factions.RONDA_CRIT_PM
	var ammo_hit: bool = int(move.get("ammo", 0)) > 0
	for t in targets:
		if not BattleState.is_alive(t):
			continue
		# i marchi si applicano PRIMA del colpo (cosi' il colpo ne beneficia)
		if move.has("status") and str(t["side"]) == "boss" and move["status"].has("mark"):
			Marks.add(state, t, int(move["status"]["mark"]) + Archetypes.status_extra(actor, "mark"), events)
			t["marked_by"] = str(actor["id"])
		if move.has("mult"):
			var m_total: float = float(move["mult"]) * (1.0 + link_gain * float(link_n)) * awake_mult * emp_mult
			if str(t["side"]) == "boss":
				m_total *= _synergies(state, actor, t, events, move)
			if move.has("consume_marks"):
				# Orbital Strike: ogni marchio sul bersaglio vale danno in piu', poi i marchi spariscono
				m_total *= 1.0 + float(move["consume_marks"]) * float(Marks.count(t))
			var boost: int = 0
			if move.has("crit_dmg_per_mark"):
				boost = mini(int(move.get("crit_dmg_cap", 650)), int(move["crit_dmg_per_mark"]) * Marks.count(t))
			for _i in int(move.get("hits", 1)):
				if BattleState.is_alive(t):
					_hit(state, actor, t, m_total, events, int(move.get("pierce", 0)), bonus, ammo_hit, int(move.get("crit_pm", 0)) + emp_crit, boost)
			if move.has("consume_marks"):
				Marks.consume(t, events)
		if move.has("heal"):
			var heal_crit: float = Archetypes.support_crit_mult(state, actor, t, events.size())
			var amount: int = int(round((float(actor["atk"]) * float(move["heal"]) + bonus) * Archetypes.support_mult(actor) * awake_mult * heal_crit))
			var before: int = int(t["hp"])
			t["hp"] = mini(int(t["max_hp"]), before + amount)
			var heal_event: Dictionary = {"t": "heal", "src": actor["id"], "dst": t["id"], "amount": int(t["hp"]) - before}
			if heal_crit > 1.0:
				heal_event["crit"] = true
			events.append(heal_event)
			var hs: float = Signatures.value(actor, "heal_shield")
			if hs > 0.0:
				var extra: int = int(round(float(amount) * hs))
				t["shield"] = int(t["shield"]) + extra
				events.append({"t": "shield", "src": actor["id"], "dst": t["id"], "amount": extra})
		if move.has("shield") and str(move["target"]) != "enemy":
			var shield_crit: float = Archetypes.support_crit_mult(state, actor, t, events.size())
			var sh: int = int(round((float(actor["atk"]) * float(move["shield"]) + bonus) * Archetypes.support_mult(actor) * awake_mult * shield_crit))
			t["shield"] = int(t["shield"]) + sh
			var shield_event: Dictionary = {"t": "shield", "src": actor["id"], "dst": t["id"], "amount": sh}
			if shield_crit > 1.0:
				shield_event["crit"] = true
			events.append(shield_event)
		if bool(move.get("cleanse", false)):
			t["statuses"].erase("bleed")
			events.append({"t": "cleanse", "unit": t["id"]})
		if move.has("status") and BattleState.is_alive(t):
			for s in move["status"]:
				if str(s) == "mark" and str(t["side"]) == "boss":
					continue       # gia' applicato sopra come pila di marchi
				_add_status(t, str(s), int(move["status"][s]) + Archetypes.status_extra(actor, str(s)), events)
		if move.has("debuff") and BattleState.is_alive(t) and str(t["side"]) == "boss":
			for st in move["debuff"]:
				Marks.debuff(t, str(st), int(move["debuff"][st]), events)

	if empowered:
		actor["statuses"].erase("ronda")
		actor["ronda_cd"] = Factions.RONDA_RECHARGE
		events.append({"t": "ronda", "unit": actor["id"], "on": 0, "move": move_id})
		Factions.refresh(state)

	# effetti di squadra, evocazioni
	if move.has("team_ammo"):
		for uid in BattleState.player(state, str(actor["owner"]))["team"]:
			var mate: Dictionary = BattleState.unit(state, uid)
			if BattleState.is_alive(mate) and int(mate["ammo_max"]) > 0:
				_change_ammo(mate, int(move["team_ammo"]) + Signatures.upgrade_grade(actor, move_id, kind), events)
	if move.has("ally_buff"):
		for p in state["players"]:
			for uid in p["team"]:
				var ally: Dictionary = BattleState.unit(state, uid)
				if not BattleState.is_alive(ally):
					continue
				for st in move["ally_buff"]:
					Factions.add_mod(ally, "buff_" + str(st), str(st), Marks.GRADE_PM * int(move["ally_buff"][st]), Marks.DEBUFF_TURNS)
		Factions.refresh(state)
		events.append({"t": "buff", "unit": actor["id"]})
	if move.has("summon"):
		_summon(state, actor, str(move["summon"]), events)


# EVOCAZIONI: torretta e drone seguono chi li ha evocati, sparano da soli a fine round (1 munizione a colpo)
# e finiscono a 0 munizioni: la torretta esplode sul boss, il drone dona scudi a tutta la squadra.
const TURRET_MULT: float = 0.8
const DRONE_MULT: float = 0.35
const TURRET_BLAST_MULT: float = 2.5
const DRONE_SHIELD_MULT: float = 1.0


static func _summon(state: Dictionary, actor: Dictionary, kind: String, events: Array) -> void:
	var list: Array = state["summons"]
	for i in range(list.size() - 1, -1, -1):
		if str(list[i]["owner"]) == str(actor["id"]) and str(list[i]["kind"]) == kind:
			list.remove_at(i)
	list.append({"id": "%s:%s" % [kind, actor["id"]], "owner": str(actor["id"]), "kind": kind})
	events.append({"t": "summon", "unit": actor["id"], "kind": kind})
```
