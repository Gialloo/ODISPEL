class_name PvpEngine
extends RefCounted

# PvP: giocatore contro giocatore. Motore a parte, tutto dati (si serializza in JSON come BattleState).
# Ogni giocatore porta fino a 3 operatori, ne ha uno in campo e a ogni ciclo sceglie UNA mossa:
#   attack  attacco base          guard   guardia (danno dimezzato nel ciclo, +1 energia)
#   skill   una delle sue abilita' (comprese quelle UNICHE del personaggio)  ult  ultimate (barra al 100)
#   swap    cambia operatore in campo (il turno e' quello)
# Le mosse sono quelle vere del gioco (BattleContent.MOVES): stesso danno, cure, scudi, stati e potenziamenti dal rank,
# e valgono le passive uniche. Non valgono le aure di fazione e i LINK, che sono cose da squadra contro il boss.
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
const HIDDEN_DODGE_PM: int = 400
const SUMMON_TURRET_MULT: float = 0.8
const SUMMON_DRONE_MULT: float = 0.35
const SUMMON_BLAST_MULT: float = 2.5
const SUMMON_DRONE_SHIELD: float = 1.0
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
	e["flat_rarity"] = true       # bilanciato davvero: anche la rarita' dell'operatore non da' statistiche in piu'
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
		"summons": [],
		"marks_applied": 0,
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
			u["pvp_unit"] = true       # i marchi qui sono pile (+10% l'una) come contro il boss, non il +25% fisso dei giocatori
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


# ---------- Mosse dell'operatore ----------

# Le abilita' dell'operatore: quelle scelte + le uniche; se non ne ha, la sua di base.
static func skills_of(u: Dictionary) -> Array:
	var out: Array = []
	for sid in u.get("skills", []):
		var m: Dictionary = BattleContent.MOVES.get(str(sid), {})
		if str(m.get("kind", "")) == "skill" and not out.has(str(sid)):
			out.append(str(sid))
	if out.is_empty():
		var base: String = str(BattleContent.CHARACTERS.get(str(u.get("char", "")), {}).get("skill", ""))
		if BattleContent.MOVES.has(base):
			out.append(base)
	return out


static func ult_of(u: Dictionary) -> String:
	var id: String = str(u.get("ult", ""))
	if id == "" or not BattleContent.MOVES.has(id):
		id = str(BattleContent.CHARACTERS.get(str(u.get("char", "")), {}).get("ult", ""))
	return id if BattleContent.MOVES.has(id) else ""


# L'id della mossa che una scelta attiva per quell'operatore ("" se non valida).
static func move_id_for(u: Dictionary, choice: Dictionary) -> String:
	match str(choice.get("move", "")):
		"attack":
			return "attack"
		"guard":
			return "guard"
		"ult":
			return ult_of(u)
		"skill":
			var want: String = str(choice.get("skill", ""))
			var list: Array = skills_of(u)
			if want == "" and not list.is_empty():
				return str(list[0])
			return want if list.has(want) else ""
	return ""


static func can_use(u: Dictionary, move_id: String) -> bool:
	var m: Dictionary = BattleContent.MOVES.get(move_id, {})
	if m.is_empty():
		return false
	match str(m["kind"]):
		"ult":
			return int(u["gauge"]) >= BattleTypes.GAUGE_MAX
		"skill":
			return int(u["energy"]) >= int(m["cost"]) and int(u["ammo"]) >= int(m.get("ammo", 0))
	return true


static func can_ult(u: Dictionary) -> bool:
	var id: String = ult_of(u)
	return id != "" and can_use(u, id)


static func can_skill(u: Dictionary) -> bool:
	for sid in skills_of(u):
		if can_use(u, str(sid)):
			return true
	return false


# Che bersaglio chiede la mossa: "enemy", "ally" o "" (nessuno da scegliere).
static func target_kind(move_id: String) -> String:
	var t: String = str(BattleContent.MOVES.get(move_id, {}).get("target", ""))
	return t if (t == "enemy" or t == "ally") else ""


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
	var mid: String = move_id_for(u, choice)
	if mid == "":
		return "mossa non disponibile"
	if not can_use(u, mid):
		return "ultimate non pronta" if move == "ult" else "risorse insufficienti"
	var tk: String = target_kind(mid)
	if tk == "enemy":
		for e in enemies_of(state, pid):
			if str(e["id"]) == str(choice.get("target", "")):
				return ""
		return "bersaglio non valido"
	if tk == "ally":
		var t: String = str(choice.get("target", ""))
		if t == "":
			return ""
		for a in allies_of(state, pid):
			if str(a["id"]) == t:
				return ""
		return "alleato non valido"
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
		"skill": str(choice.get("skill", "")),
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


static func _ratio(u: Dictionary) -> float:
	return float(u.get("hp", 0)) / maxf(1.0, float(u.get("max_hp", 1)))


static func choose_ai(state: Dictionary, pid: String) -> Dictionary:
	var p: Dictionary = player(state, pid)
	var u: Dictionary = active_unit(state, p)
	var foes: Array = enemies_of(state, pid)
	if not alive(u):
		var opts: Array = swap_options(state, p)
		return {"move": "swap", "swap": str(opts[0]) if not opts.is_empty() else "", "target": "", "skill": ""}
	if foes.is_empty():
		return {"move": "guard", "target": "", "swap": "", "skill": ""}
	# bersaglio: il nemico con meno PV in proporzione
	var target: Dictionary = foes[0]
	var best: float = 9.0
	for f in foes:
		var fu: Dictionary = active_unit(state, f)
		if alive(fu) and _ratio(fu) < best:
			best = _ratio(fu)
			target = f
	# alleato da aiutare: il piu' ferito
	var ally_id: String = pid
	var worst: float = 9.0
	for a in allies_of(state, pid):
		var au: Dictionary = active_unit(state, a)
		if alive(au) and _ratio(au) < worst:
			worst = _ratio(au)
			ally_id = str(a["id"])
	var choice: Dictionary = {"move": "attack", "target": str(target["id"]), "swap": "", "skill": ""}
	var ult: String = ult_of(u)
	var ult_now: bool = ult != "" and can_use(u, ult)
	if ult_now:
		var um: Dictionary = BattleContent.MOVES[ult]
		if not um.has("mult"):          # ultimate di cura o scudo: non si sprecano a vita piena
			if um.has("heal"):
				ult_now = worst < 0.6
			elif um.has("shield"):
				ult_now = worst < 0.8 or int(state["round"]) % 3 == 0
	if ult_now:
		choice["move"] = "ult"
	else:
		# la miglior abilita' che si puo' usare: prima le offensive, le cure solo se servono
		var pick: String = ""
		var pick_score: float = 0.0
		for sid in skills_of(u):
			if not can_use(u, str(sid)):
				continue
			var m: Dictionary = BattleContent.MOVES[str(sid)]
			var sc: float = float(m.get("mult", 0.0)) * float(m.get("hits", 1)) + 0.2 * float(m.get("status", {}).size())
			if m.has("heal"):
				sc = 2.5 if worst < 0.6 else 0.0
			elif m.has("shield") and str(m.get("target", "")) != "enemy":
				sc = 1.2 if worst < 0.8 or int(state["round"]) % 3 == 0 else 0.3
			if sc > pick_score:
				pick_score = sc
				pick = str(sid)
		if pick != "" and pick_score > 0.5:
			choice["move"] = "skill"
			choice["skill"] = pick
		elif _ratio(u) < 0.3 and (int(state["round"]) + pid.length()) % 2 == 0:
			choice["move"] = "guard"
	var mid: String = move_id_for(u, choice)
	if target_kind(mid) == "ally":
		choice["target"] = ally_id
	if str(choice["move"]) == "attack" and _ratio(u) < 0.25 and int(state["round"]) % 3 == 0:
		var sw: Array = swap_options(state, p)
		if not sw.is_empty():
			return {"move": "swap", "swap": str(sw[0]), "target": "", "skill": ""}
	return choice


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
		var prio: int = 3 if str(ch["move"]) == "swap" else 0
		if alive(u) and prio == 0:
			var mid: String = move_id_for(u, ch)
			prio = int(BattleContent.MOVES.get(mid, {}).get("priority", 0))
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
		if _teams_alive(state) <= 1:
			break
	if _teams_alive(state) > 1:
		_end_of_round(state, g, events)
	_save_rng(state, g)
	_check_winner(state, events)
	state["events"] = events
	if str(state["winner"]) == "":
		state["round"] = int(state["round"]) + 1
		for p in state["players"]:
			p["choice"] = null
		_fill_ai_choices(state)
	return events


static func _teams_alive(state: Dictionary) -> int:
	var teams: Dictionary = {}
	for p in state["players"]:
		if player_alive(state, p):
			teams[str(p["team"])] = true
	return teams.size()


static func _act(state: Dictionary, p: Dictionary, g: RandomNumberGenerator, events: Array) -> void:
	var ch: Dictionary = p["choice"]
	var u: Dictionary = active_unit(state, p)
	if str(ch["move"]) == "swap":
		var to: String = str(ch["swap"])
		if alive(unit(state, to)):
			events.append({"t": "swap", "player": p["id"], "from": p["active"], "to": to})
			p["active"] = to
		return
	if not alive(u):
		events.append({"t": "skip", "unit": u.get("id", ""), "player": p["id"]})
		return
	var mid: String = move_id_for(u, ch)
	if mid == "" or not can_use(u, mid):
		mid = "attack"            # la situazione e' cambiata (es. energia): ripiega sull'attacco
	_cast(state, p, u, mid, str(ch["target"]), g, events)


# Sceglie chi colpisce davvero: il bersaglio voluto, o un altro nemico se e' caduto; la PROVOCA attira i colpi.
static func _enemy_unit(state: Dictionary, p: Dictionary, target_pid: String, g: RandomNumberGenerator) -> Dictionary:
	var tp: Dictionary = player(state, target_pid)
	if tp.is_empty() or str(tp["team"]) == str(p["team"]) or not alive(active_unit(state, tp)):
		var foes: Array = []
		for f in enemies_of(state, str(p["id"])):
			if alive(active_unit(state, f)):
				foes.append(f)
		if foes.is_empty():
			return {}
		tp = foes[g.randi() % foes.size()]
	for q in state["players"]:
		if str(q["team"]) == str(tp["team"]) and str(q["id"]) != str(tp["id"]):
			var qu: Dictionary = active_unit(state, q)
			if alive(qu) and qu["statuses"].has("taunt") and not active_unit(state, tp)["statuses"].has("taunt"):
				return qu
	return active_unit(state, tp)


static func _cast(state: Dictionary, p: Dictionary, u: Dictionary, move_id: String, target_pid: String, g: RandomNumberGenerator, events: Array) -> void:
	var move: Dictionary = BattleContent.MOVES[move_id]
	var kind: String = str(move["kind"])
	if kind == "ult":
		u["gauge"] = 0
	elif kind == "skill":
		u["energy"] = int(u["energy"]) - int(move["cost"])
	events.append({"t": "act", "unit": u["id"], "move": move_id, "kind": kind, "player": p["id"]})
	var awake: float = Signatures.upgrade_mult(u, move_id, kind)
	if move_id == "attack":
		awake *= BattleContent.basic_factor(u)
	BattleResolver._change_ammo(u, int(move.get("ammo_gain", 0)) - int(move.get("ammo", 0)), events)
	if move_id == "guard":
		var gsh: float = Signatures.value(u, "guard_shield")
		if gsh > 0.0:
			var gs: int = int(round(float(u["max_hp"]) * gsh))
			u["shield"] = int(u["shield"]) + gs
			events.append({"t": "shield", "src": u["id"], "dst": u["id"], "amount": gs})
		u["gauge"] = mini(BattleTypes.GAUGE_MAX, int(u["gauge"]) + 10)
	if move.has("energy"):
		u["energy"] = mini(BattleTypes.MAX_ENERGY, int(u["energy"]) + int(move["energy"]))
	if move.has("self_status"):
		for st in move["self_status"]:
			_status(u, str(st), int(move["self_status"][st]), events)
	var bonus: float = BattleContent.move_bonus(u, move)
	var targets: Array = []
	match str(move["target"]):
		"enemy":
			var e: Dictionary = _enemy_unit(state, p, target_pid, g)
			if not e.is_empty():
				targets = [e]
		"self":
			targets = [u]
		"ally":
			var ap: Dictionary = player(state, target_pid)
			var au: Dictionary = active_unit(state, ap) if not ap.is_empty() and str(ap["team"]) == str(p["team"]) else u
			targets = [au if alive(au) else u]
		"allies":
			for a in allies_of(state, str(p["id"])):
				var au2: Dictionary = active_unit(state, a)
				if alive(au2):
					targets.append(au2)
	var ammo_hit: bool = int(move.get("ammo", 0)) > 0
	for t in targets:
		if not alive(t):
			continue
		if move.has("status") and str(move["target"]) == "enemy" and move["status"].has("mark"):
			_status(t, "mark", int(move["status"]["mark"]) + Archetypes.status_extra(u, "mark") + 1, events)
			t["marks"] = mini(Marks.MAX, int(t.get("marks", 0)) + 1)   # pile reali, come in co-op
			state["marks_applied"] = int(state.get("marks_applied", 0)) + 1
		if move.has("mult"):
			var total: float = float(move["mult"]) * awake
			var boost: int = 0
			var n_marks: int = int(t.get("marks", 0)) if t["statuses"].has("mark") else 0
			if move.has("consume_marks") and n_marks > 0:
				total *= 1.0 + float(move["consume_marks"]) * float(n_marks)
				t["statuses"].erase("mark")
				t["marks"] = 0
			elif move.has("crit_dmg_per_mark") and n_marks > 0:
				boost = mini(int(move.get("crit_dmg_cap", 650)), int(move["crit_dmg_per_mark"]) * n_marks)
			for _i in int(move.get("hits", 1)):
				if alive(t):
					_hit(state, u, t, total, int(move.get("pierce", 0)), bonus, ammo_hit, int(move.get("crit_pm", 0)), boost, events)
		if move.has("heal"):
			var amount: int = int(round((float(u["atk"]) * float(move["heal"]) + bonus) * Archetypes.support_mult(u) * awake))
			var before: int = int(t["hp"])
			t["hp"] = mini(int(t["max_hp"]), before + amount)
			events.append({"t": "heal", "src": u["id"], "dst": t["id"], "amount": int(t["hp"]) - before})
			var hs: float = Signatures.value(u, "heal_shield")
			if hs > 0.0:
				var extra: int = int(round(float(amount) * hs))
				t["shield"] = int(t["shield"]) + extra
				events.append({"t": "shield", "src": u["id"], "dst": t["id"], "amount": extra})
		if move.has("shield") and str(move["target"]) != "enemy":
			var sh: int = int(round((float(u["atk"]) * float(move["shield"]) + bonus) * Archetypes.support_mult(u) * awake))
			t["shield"] = int(t["shield"]) + sh
			events.append({"t": "shield", "src": u["id"], "dst": t["id"], "amount": sh})
		if bool(move.get("cleanse", false)):
			t["statuses"].erase("bleed")
			t["statuses"].erase("mark")
			t["marks"] = 0
			events.append({"t": "cleanse", "unit": t["id"]})
		if move.has("status") and alive(t):
			for st in move["status"]:
				if str(st) != "mark":
					_status(t, str(st), int(move["status"][st]) + Archetypes.status_extra(u, str(st)), events)
		if move.has("debuff") and alive(t) and str(move["target"]) == "enemy":
			for stat in move["debuff"]:
				_mod(t, str(stat), -Marks.GRADE_PM * int(move["debuff"][stat]), events)
	if move.has("team_ammo"):
		for q in allies_of(state, str(p["id"])):
			var mate: Dictionary = unit(state, str(q["active"]))
			if alive(mate) and int(mate["ammo_max"]) > 0:
				BattleResolver._change_ammo(mate, int(move["team_ammo"]), events)
	if move.has("ally_buff"):
		for q in allies_of(state, str(p["id"])):
			var ally: Dictionary = unit(state, str(q["active"]))
			if alive(ally):
				for stat in move["ally_buff"]:
					_mod(ally, str(stat), Marks.GRADE_PM * int(move["ally_buff"][stat]), events)
		events.append({"t": "buff", "unit": u["id"]})
	if move.has("summon"):
		var list: Array = state.get("summons", [])
		for i in range(list.size() - 1, -1, -1):
			if str(list[i]["owner"]) == str(u["id"]) and str(list[i]["kind"]) == str(move["summon"]):
				list.remove_at(i)
		list.append({"owner": str(u["id"]), "kind": str(move["summon"])})
		state["summons"] = list
		events.append({"t": "summon", "unit": u["id"], "kind": str(move["summon"])})


static func _status(u: Dictionary, status: String, turns: int, events: Array) -> void:
	u["statuses"][status] = maxi(int(u["statuses"].get(status, 0)), turns)
	events.append({"t": "status", "unit": u["id"], "status": status, "turns": turns})


# Bonus/malus temporaneo a una statistica (per mille), a tempo.
static func _mod(u: Dictionary, stat: String, pm: int, events: Array) -> void:
	if not (u["base"] as Dictionary).has(stat) or stat == "crit":
		return
	if not u.has("pvp_mods"):
		u["pvp_mods"] = []
	u["pvp_mods"].append({"stat": stat, "pm": pm, "turns": Marks.DEBUFF_TURNS})
	_recalc(u)
	events.append({"t": "debuff" if pm < 0 else "buff", "unit": u["id"], "stat": stat})


static func _recalc(u: Dictionary) -> void:
	for stat in ["atk", "def", "spd"]:
		var pm: int = 0
		for m in u.get("pvp_mods", []):
			if str(m["stat"]) == stat:
				pm += int(m["pm"])
		u[stat] = int(round(float(u["base"][stat]) * maxf(0.3, 1.0 + float(pm) / 1000.0)))


static func _hit(state: Dictionary, atk: Dictionary, dfn: Dictionary, mult: float, pierce: int, flat: float, ammo_hit: bool, crit_pm: int, crit_boost: int, events: Array) -> void:
	if dfn["statuses"].has("hidden") and (events.size() * 7919 + int(state["round"]) * 31) % 1000 < HIDDEN_DODGE_PM:
		events.append({"t": "dodge", "unit": dfn["id"]})
		return
	var dmg: int = BattleResolver.calc_damage(atk, dfn, mult, pierce, flat, ammo_hit)
	var crit: bool = Factions.rolls_crit(state, atk, dfn, events.size(), crit_pm)
	if crit:
		var cd: float = float(atk.get("crit_dmg", Factions.CRIT_DMG_PM)) * (1.0 + float(crit_boost) / 1000.0)
		dmg = maxi(1, int(round(float(dmg) * cd / 1000.0)))
	var absorbed: int = mini(int(dfn["shield"]), dmg)
	dfn["shield"] = int(dfn["shield"]) - absorbed
	var lost: int = dmg - absorbed
	dfn["hp"] = maxi(0, int(dfn["hp"]) - lost)
	events.append({"t": "damage", "src": atk["id"], "dst": dfn["id"], "amount": lost, "absorbed": absorbed, "crit": crit,
		"guard": dfn["statuses"].has("guard")})
	atk["gauge"] = mini(BattleTypes.GAUGE_MAX, int(atk["gauge"]) + Archetypes.gauge_on_hit(atk))
	Archetypes.after_hit(atk, crit)
	dfn["gauge"] = mini(BattleTypes.GAUGE_MAX, int(dfn["gauge"]) + BattleTypes.GAUGE_ON_DAMAGED)
	var steal: float = Signatures.value(atk, "lifesteal")
	if steal > 0.0 and lost > 0 and alive(atk):
		var got: int = mini(int(atk["max_hp"]) - int(atk["hp"]), int(round(float(lost) * steal)))
		if got > 0:
			atk["hp"] = int(atk["hp"]) + got
			events.append({"t": "heal", "src": atk["id"], "dst": atk["id"], "amount": got})
	if int(dfn["hp"]) <= 0:
		dfn["statuses"] = {}
		dfn["shield"] = 0
		events.append({"t": "down", "unit": dfn["id"]})
		return
	var thorn: float = Signatures.value(dfn, "thorns")
	if thorn > 0.0 and alive(atk) and str(atk["id"]) != str(dfn["id"]):
		var back: int = maxi(1, int(round(float(dfn["atk"]) * thorn)))
		atk["hp"] = maxi(0, int(atk["hp"]) - back)
		events.append({"t": "damage", "src": dfn["id"], "dst": atk["id"], "amount": back, "absorbed": 0, "thorns": true, "crit": false, "guard": false})
		if int(atk["hp"]) <= 0:
			atk["statuses"] = {}
			atk["shield"] = 0
			events.append({"t": "down", "unit": atk["id"]})


static func _random_enemy_unit(state: Dictionary, owner: Dictionary, g: RandomNumberGenerator) -> Dictionary:
	var foes: Array = []
	for f in enemies_of(state, str(owner["owner"])):
		if alive(active_unit(state, f)):
			foes.append(active_unit(state, f))
	return foes[g.randi() % foes.size()] if not foes.is_empty() else {}


static func _end_of_round(state: Dictionary, g: RandomNumberGenerator, events: Array) -> void:
	# torrette e droni: sparano da soli e a fine munizioni esplodono / danno scudi
	var list: Array = state.get("summons", [])
	for i in range(list.size() - 1, -1, -1):
		var sm: Dictionary = list[i]
		var owner: Dictionary = unit(state, str(sm["owner"]))
		if not alive(owner):
			list.remove_at(i)
			continue
		var kind: String = str(sm["kind"])
		var foe: Dictionary = _random_enemy_unit(state, owner, g)
		if int(owner["ammo"]) > 0 and not foe.is_empty():
			events.append({"t": "summon_shot", "unit": owner["id"], "kind": kind})
			BattleResolver._change_ammo(owner, -1, events)
			_hit(state, owner, foe, SUMMON_TURRET_MULT if kind == "turret" else SUMMON_DRONE_MULT, 0, 0.0, true, 0, 0, events)
		if int(owner["ammo"]) <= 0:
			list.remove_at(i)
			events.append({"t": "summon_end", "unit": owner["id"], "kind": kind, "reason": "ammo"})
			if kind == "turret":
				var f2: Dictionary = _random_enemy_unit(state, owner, g)
				if not f2.is_empty():
					_hit(state, owner, f2, SUMMON_BLAST_MULT, 0, 0.0, true, 0, 0, events)
			else:
				var amount: int = int(round(float(owner["atk"]) * SUMMON_DRONE_SHIELD * Archetypes.support_mult(owner)))
				for q in allies_of(state, str(owner["owner"])):
					var mate: Dictionary = active_unit(state, q)
					if alive(mate):
						mate["shield"] = int(mate["shield"]) + amount
						events.append({"t": "shield", "src": owner["id"], "dst": mate["id"], "amount": amount})
	state["summons"] = list
	# sanguinamento (ignora gli scudi)
	for uid in state["units"]:
		var u: Dictionary = state["units"][uid]
		if alive(u) and u["statuses"].has("bleed"):
			var dmg: int = maxi(1, int(float(u["max_hp"]) * BattleTypes.BLEED_FRACTION))
			u["hp"] = maxi(0, int(u["hp"]) - dmg)
			events.append({"t": "bleed", "unit": uid, "amount": dmg})
			if int(u["hp"]) <= 0:
				u["statuses"] = {}
				u["shield"] = 0
				events.append({"t": "down", "unit": uid})
	# durata di stati, bonus e malus; gli scudi finiscono
	for uid in state["units"]:
		var u2: Dictionary = state["units"][uid]
		var expired: Array = []
		for s in u2["statuses"]:
			u2["statuses"][s] = int(u2["statuses"][s]) - 1
			if int(u2["statuses"][s]) <= 0:
				expired.append(s)
		for s in expired:
			u2["statuses"].erase(s)
			if str(s) == "mark":
				u2["marks"] = 0
		if u2.has("pvp_mods"):
			var keep: Array = []
			for m in u2["pvp_mods"]:
				m["turns"] = int(m["turns"]) - 1
				if int(m["turns"]) > 0:
					keep.append(m)
			u2["pvp_mods"] = keep
			_recalc(u2)
		u2["shield"] = 0
	# passive uniche di fine round
	for uid in state["units"]:
		var pu: Dictionary = state["units"][uid]
		if not alive(pu):
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
	# sostegno dalla panchina (meta' del valore del co-op)
	for p in state["players"]:
		var fa: Dictionary = active_unit(state, p)
		if not alive(fa):
			continue
		for uid in p["units"]:
			var bu: Dictionary = unit(state, str(uid))
			if str(uid) == str(p["active"]) or not alive(bu) or not Signatures.has_bench(str(bu.get("char", ""))):
				continue
			events.append_array(Signatures.apply_bench(bu, fa, Signatures.BENCH_PVP_FACTOR))
	for p in state["players"]:
		var act: Dictionary = active_unit(state, p)
		# chi e' caduto in campo viene sostituito dal primo compagno vivo
		if not alive(act):
			var opts: Array = swap_options(state, p)
			if not opts.is_empty():
				events.append({"t": "swap", "player": p["id"], "from": p["active"], "to": opts[0], "forced": true})
				p["active"] = opts[0]
		for uid in p["units"]:
			var x: Dictionary = unit(state, str(uid))
			if not alive(x):
				continue
			var gain: int = BattleTypes.REGEN_ACTIVE if str(uid) == str(p["active"]) else BattleTypes.REGEN_BENCH
			x["energy"] = mini(BattleTypes.MAX_ENERGY, int(x["energy"]) + gain + Archetypes.round_energy(x))


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
