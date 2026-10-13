class_name PvpEngine
extends RefCounted

# PvP: giocatore contro giocatore. Motore a parte, tutto dati (si serializza in JSON come BattleState).
# Ogni giocatore porta fino a 3 operatori, ne ha uno in campo e a ogni ciclo sceglie UNA mossa:
#   attack  attacco base          guard   guardia (danno dimezzato nel ciclo, +1 energia)
#   skill   abilita' (2 energia)  ult     ultimate (barra al 100)
#   swap    cambia operatore in campo (il turno e' quello)
# Modalita': duel (1v1), duo (2v2, due squadre da due), ffa (tutti contro tutti, 3-4 giocatori).
# Bilanciato: tutti gli operatori a livello/rank fissi e senza equipaggiamento. Altrimenti conta la progressione.
#
# {pvp, mode, balanced, round, winner ("" | id squadra | "draw"), players: [{id,name,ai,team,units,active,choice}],
#  units: {id: unit}, events, rng_seed, rng_state}

const MODES: Array = ["duel", "duo", "ffa"]
const MODE_NAMES: Dictionary = {"duel": "1 CONTRO 1", "duo": "2 CONTRO 2", "ffa": "TUTTI CONTRO TUTTI"}
const BALANCED_LEVEL: int = 20
const BALANCED_RANK: int = 2
const MAX_ROUNDS: int = 40
const SKILL_COST: int = 2
const SKILL_MULT: float = 1.8
const ULT_MULT: float = 3.0
const HEAL_FRACTION: float = 0.30
const ULT_HEAL_FRACTION: float = 0.40
const ENERGY_REGEN: int = 1
const SHIELD_FRACTION: float = 0.15
const MOVES: Array = ["attack", "skill", "guard", "ult", "swap"]


# Quanti giocatori servono (min, max) per modalita'.
static func seats(mode: String) -> Vector2i:
	match mode:
		"duel":
			return Vector2i(2, 2)
		"duo":
			return Vector2i(4, 4)
		"ffa":
			return Vector2i(3, 4)
	return Vector2i(2, 2)


static func team_of_seat(mode: String, index: int) -> String:
	if mode == "duo":
		return "t%d" % (index % 2 + 1)      # 0,2 contro 1,3: due umani si trovano su squadre opposte
	return "t%d" % (index + 1)


static func balanced_entry(entry: Dictionary) -> Dictionary:
	var e: Dictionary = entry.duplicate(true)
	e["level"] = BALANCED_LEVEL
	e["rank"] = BALANCED_RANK
	e["gear"] = []
	return e


# specs: [{id, name, ai, team:[entry]}] gia' nell'ordine dei posti.
static func create(specs: Array, mode: String, balanced: bool, seed_value: int) -> Dictionary:
	var state: Dictionary = {
		"pvp": true,
		"mode": mode if MODES.has(mode) else "duel",
		"balanced": balanced,
		"round": 1,
		"winner": "",
		"players": [],
		"units": {},
		"events": [],
		"rng_seed": str(seed_value),
		"rng_state": str(seed_value),
	}
	var index: int = 0
	for spec in specs:
		var pid: String = str(spec["id"])
		var ids: Array = []
		for entry in (spec["team"] as Array).slice(0, BattleTypes.NET_TEAM_SIZE):
			var e: Dictionary = balanced_entry(entry) if balanced else entry
			var u: Dictionary = BattleState.make_unit(pid, e)
			u["team"] = team_of_seat(state["mode"], index)
			state["units"][u["id"]] = u
			ids.append(u["id"])
		state["players"].append({
			"id": pid,
			"name": str(spec.get("name", pid)),
			"ai": bool(spec.get("ai", false)),
			"team": team_of_seat(state["mode"], index),
			"units": ids,
			"active": ids[0] if not ids.is_empty() else "",
			"choice": null,
		})
		index += 1
	_fill_ai_choices(state)
	return state


# ---------- Accesso ----------

static func unit(state: Dictionary, uid: String) -> Dictionary:
	return state["units"].get(uid, {})


static func player(state: Dictionary, pid: String) -> Dictionary:
	for p in state["players"]:
		if str(p["id"]) == pid:
			return p
	return {}


static func alive(u: Dictionary) -> bool:
	return not u.is_empty() and int(u["hp"]) > 0


static func player_alive(state: Dictionary, p: Dictionary) -> bool:
	for uid in p["units"]:
		if alive(unit(state, str(uid))):
			return true
	return false


static func active_unit(state: Dictionary, p: Dictionary) -> Dictionary:
	return unit(state, str(p["active"]))


static func enemies_of(state: Dictionary, pid: String) -> Array:
	var me: Dictionary = player(state, pid)
	var out: Array = []
	for p in state["players"]:
		if str(p["team"]) != str(me.get("team", "")) and player_alive(state, p):
			out.append(p)
	return out


static func allies_of(state: Dictionary, pid: String) -> Array:
	var me: Dictionary = player(state, pid)
	var out: Array = []
	for p in state["players"]:
		if str(p["team"]) == str(me.get("team", "")) and player_alive(state, p):
			out.append(p)
	return out


static func swap_options(state: Dictionary, p: Dictionary) -> Array:
	var out: Array = []
	for uid in p["units"]:
		if str(uid) != str(p["active"]) and alive(unit(state, str(uid))):
			out.append(str(uid))
	return out


static func can_ult(u: Dictionary) -> bool:
	return int(u["gauge"]) >= BattleTypes.GAUGE_MAX


static func can_skill(u: Dictionary) -> bool:
	return int(u["energy"]) >= SKILL_COST


# La mossa colpisce un nemico? (serve il bersaglio)
static func needs_target(move: String, cls: String) -> bool:
	match move:
		"attack":
			return true
		"skill", "ult":
			return cls != "warden"
	return false


# ---------- Scelte ----------

static func validate_choice(state: Dictionary, pid: String, choice: Dictionary) -> String:
	if str(state["winner"]) != "":
		return "partita finita"
	var p: Dictionary = player(state, pid)
	if p.is_empty() or not player_alive(state, p):
		return "giocatore non in gioco"
	var move: String = str(choice.get("move", ""))
	if not MOVES.has(move):
		return "mossa sconosciuta"
	var u: Dictionary = active_unit(state, p)
	if move == "swap":
		return "" if swap_options(state, p).has(str(choice.get("swap", ""))) else "cambio non valido"
	if not alive(u):
		return "devi cambiare operatore"
	if move == "skill" and not can_skill(u):
		return "energia insufficiente"
	if move == "ult" and not can_ult(u):
		return "ultimate non pronta"
	if needs_target(move, str(u["cls"])):
		var ok: bool = false
		for e in enemies_of(state, pid):
			if str(e["id"]) == str(choice.get("target", "")):
				ok = true
		if not ok:
			return "bersaglio non valido"
	return ""


static func submit_choice(state: Dictionary, pid: String, choice: Dictionary) -> bool:
	if validate_choice(state, pid, choice) != "":
		return false
	var p: Dictionary = player(state, pid)
	if p["choice"] != null and not bool(p.get("ai", false)):
		return false         # una scelta data e' definitiva
	p["choice"] = {
		"move": str(choice["move"]),
		"target": str(choice.get("target", "")),
		"swap": str(choice.get("swap", "")),
	}
	return true


static func can_resolve(state: Dictionary) -> bool:
	if str(state["winner"]) != "":
		return false
	for p in state["players"]:
		if player_alive(state, p) and p["choice"] == null:
			return false
	return true


# Chi non ha scelto: l'IA sceglie per lui (usato allo scadere del tempo).
static func _fill_ai_choices(state: Dictionary) -> void:
	for p in state["players"]:
		if bool(p["ai"]) and p["choice"] == null and player_alive(state, p):
			p["choice"] = choose_ai(state, str(p["id"]))


static func choose_ai(state: Dictionary, pid: String) -> Dictionary:
	var p: Dictionary = player(state, pid)
	var u: Dictionary = active_unit(state, p)
	var foes: Array = enemies_of(state, pid)
	if not alive(u):
		var opts: Array = swap_options(state, p)
		return {"move": "swap", "swap": opts[0] if not opts.is_empty() else "", "target": ""}
	if foes.is_empty():
		return {"move": "guard", "target": "", "swap": ""}
	# bersaglio: il nemico con meno PV in proporzione
	var target: Dictionary = foes[0]
	var best: float = 2.0
	for f in foes:
		var fu: Dictionary = active_unit(state, f)
		var r: float = float(fu.get("hp", 0)) / maxf(1.0, float(fu.get("max_hp", 1)))
		if r < best and alive(fu):
			best = r
			target = f
	var cls: String = str(u["cls"])
	var ratio: float = float(u["hp"]) / maxf(1.0, float(u["max_hp"]))
	var move: String = "attack"
	if can_ult(u):
		move = "ult"
	elif can_skill(u):
		move = "skill"
		if cls == "warden" and _weakest_ratio(state, pid) > 0.7:
			move = "attack"
	elif ratio < 0.3 and (int(state["round"]) + pid.length()) % 2 == 0:
		move = "guard"
	if move == "attack" and ratio < 0.25:
		var sw: Array = swap_options(state, p)
		if not sw.is_empty() and (int(state["round"]) % 3 == 0):
			return {"move": "swap", "swap": str(sw[0]), "target": ""}
	return {"move": move, "target": str(target["id"]), "swap": ""}


static func _weakest_ratio(state: Dictionary, pid: String) -> float:
	var worst: float = 1.0
	for a in allies_of(state, pid):
		var au: Dictionary = active_unit(state, a)
		if alive(au):
			worst = minf(worst, float(au["hp"]) / maxf(1.0, float(au["max_hp"])))
	return worst


# ---------- Risoluzione ----------

static func _rng(state: Dictionary) -> RandomNumberGenerator:
	var g := RandomNumberGenerator.new()
	g.seed = int(str(state["rng_state"]).to_int())
	return g


static func _save_rng(state: Dictionary, g: RandomNumberGenerator) -> void:
	state["rng_state"] = str(g.randi() | 1)


static func _order(state: Dictionary) -> Array:
	var acts: Array = []
	for p in state["players"]:
		if p["choice"] == null or not player_alive(state, p):
			continue
		var u: Dictionary = active_unit(state, p)
		var ch: Dictionary = p["choice"]
		var prio: int = 2 if str(ch["move"]) == "swap" else (1 if str(ch["move"]) == "guard" else 0)
		acts.append({"pid": str(p["id"]), "prio": prio, "spd": int(u.get("spd", 0)) if alive(u) else 0})
	acts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["prio"] != b["prio"]:
			return a["prio"] > b["prio"]
		if a["spd"] != b["spd"]:
			return a["spd"] > b["spd"]
		return str(a["pid"]) < str(b["pid"]))
	return acts


static func resolve_round(state: Dictionary, force: bool = false) -> Array:
	var events: Array = []
	if str(state["winner"]) != "":
		return events
	if force:
		for p in state["players"]:
			if p["choice"] == null and player_alive(state, p):
				p["choice"] = choose_ai(state, str(p["id"]))
	elif not can_resolve(state):
		return events
	var g: RandomNumberGenerator = _rng(state)
	events.append({"t": "round", "n": int(state["round"])})
	for a in _order(state):
		var p: Dictionary = player(state, str(a["pid"]))
		if not player_alive(state, p):
			continue
		_act(state, p, g, events)
	_end_of_round(state, events)
	_save_rng(state, g)
	_check_winner(state, events)
	state["events"] = events
	if str(state["winner"]) == "":
		state["round"] = int(state["round"]) + 1
		for p in state["players"]:
			p["choice"] = null
		_fill_ai_choices(state)
	return events


static func _act(state: Dictionary, p: Dictionary, g: RandomNumberGenerator, events: Array) -> void:
	var ch: Dictionary = p["choice"]
	var move: String = str(ch["move"])
	var u: Dictionary = active_unit(state, p)
	if move == "swap":
		var to: String = str(ch["swap"])
		if alive(unit(state, to)):
			events.append({"t": "swap", "player": p["id"], "from": p["active"], "to": to})
			p["active"] = to
		return
	if not alive(u):
		# l'operatore e' caduto prima di agire: il turno salta
		events.append({"t": "skip", "unit": u.get("id", ""), "player": p["id"]})
		return
	var cls: String = str(u["cls"])
	match move:
		"guard":
			u["statuses"]["guard"] = 1
			u["energy"] = mini(BattleTypes.MAX_ENERGY, int(u["energy"]) + 1)
			u["gauge"] = mini(BattleTypes.GAUGE_MAX, int(u["gauge"]) + 10)
			events.append({"t": "guard", "unit": u["id"], "player": p["id"]})
		"attack":
			events.append({"t": "act", "unit": u["id"], "move": "attack", "player": p["id"]})
			_strike(state, p, u, str(ch["target"]), 1.0, 0, g, events)
		"skill":
			if not can_skill(u):
				return
			u["energy"] = int(u["energy"]) - SKILL_COST
			events.append({"t": "act", "unit": u["id"], "move": "skill", "player": p["id"]})
			match cls:
				"striker":
					_strike(state, p, u, str(ch["target"]), SKILL_MULT, 0, g, events)
				"vanguard":
					_strike(state, p, u, str(ch["target"]), 1.0, 0, g, events)
					u["statuses"]["guard"] = 1
					events.append({"t": "guard", "unit": u["id"], "player": p["id"]})
				_:
					_heal_weakest(state, p, HEAL_FRACTION, events)
		"ult":
			if not can_ult(u):
				return
			u["gauge"] = 0
			events.append({"t": "act", "unit": u["id"], "move": "ult", "player": p["id"]})
			match cls:
				"striker":
					_strike(state, p, u, str(ch["target"]), ULT_MULT, 40, g, events)
				"vanguard":
					for e in enemies_of(state, str(p["id"])):
						_strike(state, p, u, str(e["id"]), 1.4, 0, g, events)
					u["statuses"]["guard"] = 1
					events.append({"t": "guard", "unit": u["id"], "player": p["id"]})
				_:
					for a in allies_of(state, str(p["id"])):
						var au: Dictionary = active_unit(state, a)
						if alive(au):
							_heal(au, int(round(float(au["max_hp"]) * ULT_HEAL_FRACTION)), events)
							var sh: int = int(round(float(au["max_hp"]) * SHIELD_FRACTION))
							au["shield"] = int(au["shield"]) + sh
							events.append({"t": "shield", "dst": au["id"], "amount": sh})


# Colpisce l'operatore in campo del giocatore bersaglio; se e' caduto o fuori gioco passa a un altro nemico.
static func _strike(state: Dictionary, p: Dictionary, u: Dictionary, target_pid: String, mult: float, pierce: int, g: RandomNumberGenerator, events: Array) -> void:
	var tp: Dictionary = player(state, target_pid)
	if tp.is_empty() or str(tp["team"]) == str(p["team"]) or not alive(active_unit(state, tp)):
		var foes: Array = []
		for f in enemies_of(state, str(p["id"])):
			if alive(active_unit(state, f)):
				foes.append(f)
		if foes.is_empty():
			return
		tp = foes[g.randi() % foes.size()]
	var tu: Dictionary = active_unit(state, tp)
	var dmg: int = BattleResolver.calc_damage(u, tu, mult, pierce)
	var crit: bool = g.randi() % 100 < 10
	if crit:
		dmg = int(round(float(dmg) * 1.5))
	var absorbed: int = mini(dmg, int(tu["shield"]))
	tu["shield"] = int(tu["shield"]) - absorbed
	var real: int = dmg - absorbed
	tu["hp"] = maxi(0, int(tu["hp"]) - real)
	u["gauge"] = mini(BattleTypes.GAUGE_MAX, int(u["gauge"]) + BattleTypes.GAUGE_ON_HIT)
	tu["gauge"] = mini(BattleTypes.GAUGE_MAX, int(tu["gauge"]) + BattleTypes.GAUGE_ON_DAMAGED)
	events.append({"t": "damage", "src": u["id"], "dst": tu["id"], "amount": real, "absorbed": absorbed, "crit": crit,
		"guard": tu["statuses"].has("guard")})
	if int(tu["hp"]) <= 0:
		tu["statuses"] = {}
		events.append({"t": "down", "unit": tu["id"]})


static func _heal(u: Dictionary, amount: int, events: Array) -> void:
	var real: int = mini(amount, int(u["max_hp"]) - int(u["hp"]))
	u["hp"] = int(u["hp"]) + maxi(0, real)
	events.append({"t": "heal", "dst": u["id"], "amount": maxi(0, real)})


static func _heal_weakest(state: Dictionary, p: Dictionary, fraction: float, events: Array) -> void:
	var best: Dictionary = {}
	var worst: float = 2.0
	for a in allies_of(state, str(p["id"])):
		var au: Dictionary = active_unit(state, a)
		if not alive(au):
			continue
		var r: float = float(au["hp"]) / maxf(1.0, float(au["max_hp"]))
		if r < worst:
			worst = r
			best = au
	if not best.is_empty():
		_heal(best, int(round(float(best["max_hp"]) * fraction)), events)


static func _end_of_round(state: Dictionary, events: Array) -> void:
	for p in state["players"]:
		var u: Dictionary = active_unit(state, p)
		# chi e' caduto in campo viene sostituito dal primo compagno vivo
		if not alive(u):
			var opts: Array = swap_options(state, p)
			if not opts.is_empty():
				events.append({"t": "swap", "player": p["id"], "from": p["active"], "to": opts[0], "forced": true})
				p["active"] = opts[0]
		for uid in p["units"]:
			var x: Dictionary = unit(state, str(uid))
			if not alive(x):
				continue
			x["statuses"].erase("guard")
			if str(uid) == str(p["active"]):
				x["energy"] = mini(BattleTypes.MAX_ENERGY, int(x["energy"]) + ENERGY_REGEN)
			else:
				x["energy"] = mini(BattleTypes.MAX_ENERGY, int(x["energy"]) + BattleTypes.REGEN_BENCH)


static func _check_winner(state: Dictionary, events: Array) -> void:
	var teams: Dictionary = {}
	for p in state["players"]:
		if player_alive(state, p):
			teams[str(p["team"])] = true
	var winner: String = ""
	if teams.size() == 1:
		winner = str(teams.keys()[0])
	elif teams.is_empty():
		winner = "draw"
	elif int(state["round"]) >= MAX_ROUNDS:
		# tempo scaduto: vince la squadra con piu' PV rimasti (in proporzione)
		var score: Dictionary = {}
		for uid in state["units"]:
			var u: Dictionary = state["units"][uid]
			score[str(u["team"])] = float(score.get(str(u["team"]), 0.0)) + float(u["hp"]) / maxf(1.0, float(u["max_hp"]))
		var top: float = -1.0
		var tie: bool = false
		for t in score:
			if float(score[t]) > top + 0.0001:
				top = float(score[t])
				winner = str(t)
				tie = false
			elif absf(float(score[t]) - top) <= 0.0001:
				tie = true
		if tie:
			winner = "draw"
	if winner != "":
		state["winner"] = winner
		events.append({"t": "end", "winner": winner})


static func winner_players(state: Dictionary) -> Array:
	var out: Array = []
	for p in state["players"]:
		if str(p["team"]) == str(state["winner"]):
			out.append(str(p["id"]))
	return out


# Una partita intera di sole IA: serve ai test e a capire se il gioco e' equilibrato.
static func simulate(specs: Array, mode: String, balanced: bool, seed_value: int) -> Dictionary:
	var st: Dictionary = create(specs, mode, balanced, seed_value)
	var guard: int = 0
	while str(st["winner"]) == "" and guard < MAX_ROUNDS + 5:
		resolve_round(st, true)
		guard += 1
	return st
