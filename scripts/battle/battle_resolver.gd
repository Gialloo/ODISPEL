class_name BattleResolver
extends RefCounted

# Risoluzione dei round. Funziona solo su Dictionary (vedi BattleState) e usa
# RNGState per le scelte casuali, quindi e' deterministica a parita' di seed.
#
# Scelta di un giocatore: {"swap": unit_id | "", "move": move_id, "target": player_id | ""}


# ---------- RNG ----------

static func _load_rng(state: Dictionary) -> RNGState:
	var rng: RNGState = RNGState.new()
	rng.seed_value = RNGState.read_int64(state["rng_seed"], 1)
	rng.state_value = RNGState.read_int64(state["rng_state"], 0)
	rng.restore()
	return rng


static func _save_rng(state: Dictionary, rng: RNGState) -> void:
	state["rng_state"] = str(rng.state_value)


# ---------- Inizio round / annuncio mossa del boss ----------

static func begin_round(state: Dictionary) -> void:
	var boss: Dictionary = BattleState.boss(state)
	var def: Dictionary = BattleContent.BOSSES[str(boss["char"])]
	var cycle: Array = def["cycle"]
	var move_id: String = str(cycle[int(state["cycle_index"]) % cycle.size()])
	var alive: Array = BattleState.alive_players(state)
	var target: String = ""
	if not alive.is_empty():
		if str(BattleContent.BOSS_MOVES[move_id]["target"]) == "weakest":
			target = _weakest_player(state, alive)
		else:
			var rng: RNGState = _load_rng(state)
			target = str(alive[rng.random_index(alive.size())]["id"])
			_save_rng(state, rng)
	state["telegraph"] = {"move": move_id, "target": target}
	# L'IA decide subito, cosi' le sue intenzioni si vedono durante la pianificazione (non dipendono dalla scelta degli umani).
	for p in state["players"]:
		if bool(p["ai"]) and p["choice"] == null and BattleState.player_alive(state, p):
			p["choice"] = BattleAI.choose(state, str(p["id"]))


# Il giocatore il cui personaggio attivo ha la frazione di PV piu' bassa
# (a parita', il primo nell'ordine dei giocatori).
static func _weakest_player(state: Dictionary, alive: Array) -> String:
	var best: String = ""
	var best_ratio: float = 2.0
	for p in alive:
		var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
		if u.is_empty():
			continue
		var ratio: float = float(u["hp"]) / float(u["max_hp"])
		if ratio < best_ratio:
			best_ratio = ratio
			best = str(p["id"])
	return best


# ---------- Scelte ----------

# Ritorna "" se la scelta e' valida, altrimenti il motivo.
static func validate_choice(state: Dictionary, pid: String, choice: Dictionary) -> String:
	var p: Dictionary = BattleState.player(state, pid)
	if p.is_empty():
		return "giocatore sconosciuto"
	if not BattleState.player_alive(state, p):
		return "giocatore sconfitto"
	if str(state["winner"]) != "":
		return "battaglia finita"

	var uid: String = str(p["active"])
	var swap: String = str(choice.get("swap", ""))
	if swap != "":
		if not p["team"].has(swap):
			return "personaggio non in squadra"
		if not BattleState.is_alive(BattleState.unit(state, swap)):
			return "personaggio sconfitto"
		uid = swap
	var u: Dictionary = BattleState.unit(state, uid)
	if not BattleState.is_alive(u):
		return "personaggio attivo sconfitto"

	var move_id: String = str(choice.get("move", ""))
	if not BattleContent.MOVES.has(move_id):
		return "mossa sconosciuta"
	var move: Dictionary = BattleContent.MOVES[move_id]
	match str(move["kind"]):
		"basic":
			pass
		"skill":
			if not u["skills"].has(move_id):
				return "mossa non equipaggiata"
			if int(u["energy"]) < int(move["cost"]):
				return "energia insufficiente"
			if int(u["ammo"]) < int(move.get("ammo", 0)):
				return "munizioni insufficienti"
			if move.has("ammo_gain") and int(u["ammo_max"]) <= 0:
				return "niente da ricaricare"
		"ult":
			if str(u["ult"]) != move_id:
				return "ultimate non equipaggiata"
			if int(u["gauge"]) < BattleTypes.GAUGE_MAX:
				return "barra non piena"
	return ""


static func submit_choice(state: Dictionary, pid: String, choice: Dictionary) -> bool:
	if validate_choice(state, pid, choice) != "":
		return false
	var p: Dictionary = BattleState.player(state, pid)
	p["choice"] = {
		"swap": str(choice.get("swap", "")),
		"move": str(choice.get("move", "")),
		"target": str(choice.get("target", "")),
	}
	return true


# Tutti i giocatori umani vivi hanno scelto (l'IA sceglie da sola).
static func can_resolve(state: Dictionary) -> bool:
	if str(state["winner"]) != "":
		return false
	for p in state["players"]:
		if bool(p["ai"]) or not BattleState.player_alive(state, p):
			continue
		if p["choice"] == null:
			return false
	return true


# ---------- Risoluzione ----------

static func resolve_round(state: Dictionary, force: bool = false) -> Array:
	var events: Array = []
	state["events"] = events
	if str(state["winner"]) != "":
		return events
	if not force and not can_resolve(state):
		return events

	var rng: RNGState = _load_rng(state)

	# 1. scelte mancanti: IA, oppure attacco standard se forzato
	for p in state["players"]:
		if not BattleState.player_alive(state, p):
			continue
		if p["choice"] == null:
			if bool(p["ai"]):
				p["choice"] = BattleAI.choose(state, str(p["id"]))
			else:
				p["choice"] = {"swap": "", "move": BattleTypes.ACTION_ATTACK, "target": ""}
		elif validate_choice(state, str(p["id"]), p["choice"]) != "":
			p["choice"] = {"swap": "", "move": BattleTypes.ACTION_ATTACK, "target": ""}

	# 2. cambi (gratuiti, prima di tutto)
	for p in state["players"]:
		if p["choice"] == null:
			continue
		var swap: String = str(p["choice"]["swap"])
		if swap != "" and swap != str(p["active"]):
			_do_swap(state, p, swap, events)

	# 3. azioni ordinate per priorita', velocita', id
	var actions: Array = []
	for p in state["players"]:
		if p["choice"] == null:
			continue
		var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
		if not BattleState.is_alive(u):
			continue
		var move_id: String = str(p["choice"]["move"])
		var move: Dictionary = BattleContent.MOVES[move_id]
		actions.append({"actor": u["id"], "move": move_id, "target": str(p["choice"]["target"]), "prio": int(move["priority"]), "spd": int(u["spd"]), "boss": false})
	var boss: Dictionary = BattleState.boss(state)
	actions.append({"actor": boss["id"], "move": str(state["telegraph"]["move"]), "target": str(state["telegraph"]["target"]), "prio": 0, "spd": int(boss["spd"]), "boss": true})
	actions.sort_custom(_action_before)

	for a in actions:
		if str(state["winner"]) != "":
			break
		var actor: Dictionary = BattleState.unit(state, str(a["actor"]))
		if not BattleState.is_alive(actor):
			continue
		if bool(a["boss"]):
			_boss_act(state, actor, str(a["move"]), str(a["target"]), rng, events)
		else:
			_player_act(state, actor, str(a["move"]), str(a["target"]), events)
		_check_winner(state, events)

	# 4. fine round
	if str(state["winner"]) == "":
		_end_of_round(state, events)
	_check_winner(state, events)

	for p in state["players"]:
		p["choice"] = null
	if str(state["winner"]) == "":
		state["round"] = int(state["round"]) + 1
		state["cycle_index"] = int(state["cycle_index"]) + 1
		_save_rng(state, rng)
		begin_round(state)
	else:
		_save_rng(state, rng)
	return events


# Ordine in cui agiranno le unita' in questo round, anche prima che tutti abbiano scelto (per mostrarlo al giocatore).
# Voce: {unit, player, move, swap, prio, spd, boss, chosen}. Chi non ha ancora scelto conta con priorita' 0.
static func action_order(state: Dictionary) -> Array:
	var list: Array = []
	for p in state["players"]:
		if not BattleState.player_alive(state, p):
			continue
		var choice: Variant = p["choice"]
		var uid: String = str(p["active"])
		var move_id: String = ""
		var swap: String = ""
		var prio: int = 0
		if choice is Dictionary and choice.has("move"):
			swap = str(choice.get("swap", ""))
			if swap != "" and BattleState.is_alive(BattleState.unit(state, swap)):
				uid = swap
			move_id = str(choice["move"])
			if BattleContent.MOVES.has(move_id):
				prio = int(BattleContent.MOVES[move_id]["priority"])
		var u: Dictionary = BattleState.unit(state, uid)
		list.append({"unit": uid, "player": str(p["id"]), "move": move_id, "swap": swap, "prio": prio, "spd": int(u.get("spd", 0)), "boss": false, "chosen": move_id != ""})
	var boss: Dictionary = BattleState.boss(state)
	list.append({"unit": str(boss["id"]), "player": "", "move": str(state["telegraph"].get("move", "")), "swap": "", "prio": 0, "spd": int(boss["spd"]), "boss": true, "chosen": true})
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["prio"]) != int(b["prio"]):
			return int(a["prio"]) > int(b["prio"])
		if int(a["spd"]) != int(b["spd"]):
			return int(a["spd"]) > int(b["spd"])
		return str(a["unit"]) < str(b["unit"]))
	return list


static func _action_before(a: Dictionary, b: Dictionary) -> bool:
	if a["prio"] != b["prio"]:
		return a["prio"] > b["prio"]
	if a["spd"] != b["spd"]:
		return a["spd"] > b["spd"]
	return str(a["actor"]) < str(b["actor"])


static func _do_swap(state: Dictionary, p: Dictionary, new_id: String, events: Array) -> void:
	var old_id: String = str(p["active"])
	p["active"] = new_id
	events.append({"t": "swap", "player": p["id"], "from": old_id, "to": new_id})
	var u: Dictionary = BattleState.unit(state, new_id)
	for pass_id in u["passives"]:
		var pdef: Dictionary = BattleContent.PASSIVES.get(str(pass_id), {})
		if pdef.has("on_enter_shield"):
			var amount: int = int(round(float(u["atk"]) * float(pdef["on_enter_shield"])))
			u["shield"] = int(u["shield"]) + amount
			events.append({"t": "shield", "src": new_id, "dst": new_id, "amount": amount})


# ---------- Danni ----------

# pierce: percentuale di difesa ignorata (colpi mirati).
static func calc_damage(attacker: Dictionary, defender: Dictionary, mult: float, pierce: int = 0, flat: float = 0.0) -> int:
	var dmg: float = float(attacker["atk"]) * mult + flat
	dmg *= BattleTypes.color_multiplier(str(attacker["color"]), str(defender["color"]))
	if defender["statuses"].has("mark"):
		dmg *= BattleTypes.MARK_BONUS
	if str(attacker["side"]) == "boss" and float(attacker["hp"]) < float(attacker["max_hp"]) * BattleTypes.ENRAGE_BELOW:
		dmg *= BattleTypes.ENRAGE_BONUS
	if float(defender["hp"]) < float(defender["max_hp"]) * BattleTypes.ENRAGE_BELOW:
		for pass_id in attacker["passives"]:
			if bool(BattleContent.PASSIVES.get(str(pass_id), {}).get("hunter", false)):
				dmg *= BattleTypes.HUNTER_BONUS
	dmg = dmg * 100.0 / (100.0 + float(defender["def"]) * float(100 - clampi(pierce, 0, 100)) / 100.0)
	if defender["statuses"].has("guard"):
		dmg *= BattleTypes.GUARD_FACTOR
	return maxi(1, int(round(dmg)))


# Applica un colpo: prima lo scudo, poi i PV. Carica le barre ultimate.
static func _hit(state: Dictionary, attacker: Dictionary, defender: Dictionary, mult: float, events: Array, pierce: int = 0, flat: float = 0.0) -> void:
	var dmg: int = calc_damage(attacker, defender, mult, pierce, flat)
	var crit: bool = Factions.rolls_crit(state, attacker, defender, events.size())
	if crit:
		dmg = maxi(1, int(round(float(dmg) * float(attacker.get("crit_dmg", Factions.CRIT_DMG_PM)) / 1000.0)))
	var absorbed: int = mini(int(defender["shield"]), dmg)
	defender["shield"] = int(defender["shield"]) - absorbed
	var lost: int = dmg - absorbed
	defender["hp"] = maxi(0, int(defender["hp"]) - lost)
	var hit_event: Dictionary = {"t": "damage", "src": attacker["id"], "dst": defender["id"], "amount": lost, "absorbed": absorbed}
	if crit:
		hit_event["crit"] = true
	events.append(hit_event)
	if str(attacker["side"]) == "player":
		attacker["gauge"] = mini(BattleTypes.GAUGE_MAX, int(attacker["gauge"]) + BattleTypes.GAUGE_ON_HIT)
	if str(defender["side"]) == "player":
		defender["gauge"] = mini(BattleTypes.GAUGE_MAX, int(defender["gauge"]) + BattleTypes.GAUGE_ON_DAMAGED)
	if int(defender["hp"]) <= 0:
		_on_down(defender, events)
	else:
		Factions.on_hit_taken(state, defender, events)


# Munizioni: positivo = ricarica, negativo = si spendono. Resta tra 0 e il massimo dell'unita'.
static func _change_ammo(u: Dictionary, delta: int, events: Array) -> void:
	if delta == 0 or int(u["ammo_max"]) <= 0:
		return
	var now: int = clampi(int(u["ammo"]) + delta, 0, int(u["ammo_max"]))
	if now != int(u["ammo"]):
		u["ammo"] = now
		events.append({"t": "ammo", "unit": u["id"], "value": now})


# Protocollo (LibraCorp): chi viene colpito dal boss e resta in piedi, con una munizione, risponde al fuoco.
static func _counter(state: Dictionary, boss: Dictionary, target: Dictionary, events: Array) -> void:
	if str(state["winner"]) != "" or not BattleState.is_alive(target) or not BattleState.is_alive(boss):
		return
	if str(target.get("faction", "")) != "libracorp" or str(target.get("style", "ortodosso")) != "ortodosso":
		return
	if int(target["ammo"]) < 1 or Factions.is_suppressed(state, "libracorp"):
		return
	_change_ammo(target, -1, events)
	events.append({"t": "counter", "unit": target["id"]})
	_hit(state, target, boss, BattleTypes.COUNTER_MULT, events)


static func _on_down(u: Dictionary, events: Array) -> void:
	u["statuses"] = {}
	u["shield"] = 0
	events.append({"t": "down", "unit": u["id"]})


static func _add_status(u: Dictionary, status: String, turns: int, events: Array) -> void:
	var current: int = int(u["statuses"].get(status, 0))
	u["statuses"][status] = maxi(current, turns)
	events.append({"t": "status", "unit": u["id"], "status": status, "turns": turns})


# ---------- Azioni ----------

static func _player_act(state: Dictionary, actor: Dictionary, move_id: String, target_pid: String, events: Array) -> void:
	var move: Dictionary = BattleContent.MOVES[move_id]
	var kind: String = str(move["kind"])
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
	_change_ammo(actor, int(move.get("ammo_gain", 0)) - int(move.get("ammo", 0)), events)

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
	for t in targets:
		if not BattleState.is_alive(t):
			continue
		if move.has("mult"):
			_hit(state, actor, t, float(move["mult"]), events, int(move.get("pierce", 0)), bonus)
		if move.has("heal"):
			var amount: int = int(round(float(actor["atk"]) * float(move["heal"]) + bonus))
			var before: int = int(t["hp"])
			t["hp"] = mini(int(t["max_hp"]), before + amount)
			events.append({"t": "heal", "src": actor["id"], "dst": t["id"], "amount": int(t["hp"]) - before})
		if move.has("shield") and str(move["target"]) != "enemy":
			var sh: int = int(round(float(actor["atk"]) * float(move["shield"]) + bonus))
			t["shield"] = int(t["shield"]) + sh
			events.append({"t": "shield", "src": actor["id"], "dst": t["id"], "amount": sh})
		if bool(move.get("cleanse", false)):
			t["statuses"].erase("bleed")
			events.append({"t": "cleanse", "unit": t["id"]})
		if move.has("status") and BattleState.is_alive(t):
			for s in move["status"]:
				_add_status(t, str(s), int(move["status"][s]), events)


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

	for t in targets:
		if not BattleState.is_alive(t):
			continue
		var hp_before: int = int(t["hp"])
		_hit(state, boss, t, float(move["mult"]), events)
		_counter(state, boss, t, events)
		if move.has("drain"):
			var dealt: int = hp_before - int(t["hp"])
			var before: int = int(boss["hp"])
			boss["hp"] = mini(int(boss["max_hp"]), before + int(round(float(dealt) * float(move["drain"]))))
			if int(boss["hp"]) > before:
				events.append({"t": "heal", "src": boss["id"], "dst": boss["id"], "amount": int(boss["hp"]) - before})
		if move.has("status") and BattleState.is_alive(t):
			for s in move["status"]:
				_add_status(t, str(s), int(move["status"][s]), events)


# ---------- Fine round ----------

static func _end_of_round(state: Dictionary, events: Array) -> void:
	var units: Dictionary = state["units"]

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

	# energia: chi sta in panchina recupera di piu'
	for p in state["players"]:
		for uid in p["team"]:
			var u: Dictionary = BattleState.unit(state, uid)
			if not BattleState.is_alive(u):
				continue
			var gain: int = BattleTypes.REGEN_ACTIVE if uid == p["active"] else BattleTypes.REGEN_BENCH
			u["energy"] = mini(BattleTypes.MAX_ENERGY, int(u["energy"]) + gain)

	# se l'attivo e' caduto entra il compagno con piu' vita
	for p in state["players"]:
		_auto_replace(state, p, events)

	# modifiche temporanee e aure di fazione (chi e' caduto non da' piu' aure)
	Factions.tick(state)
	Factions.refresh(state)


static func _auto_replace(state: Dictionary, p: Dictionary, events: Array) -> void:
	if BattleState.is_alive(BattleState.unit(state, str(p["active"]))):
		return
	var best: String = ""
	var best_ratio: float = -1.0
	for uid in p["team"]:
		var u: Dictionary = BattleState.unit(state, uid)
		if not BattleState.is_alive(u):
			continue
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
