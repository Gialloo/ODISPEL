FILE battle_resolver.gd - PARTE 1 DI 5
Percorso: scripts/battle/battle_resolver.gd
(Codice GDScript, rientri con tab. Non rispondere finche' non scrivo FINE FILE.)

```gdscript
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
	Factions.ronda_tick(state, state["events"])
	var boss: Dictionary = BattleState.boss(state)
	var def: Dictionary = BattleContent.BOSSES[str(boss["char"])]
	var cycle: Array = BattleContent.cycle_for(str(boss["char"]), int(state.get("phase", 1)))
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
	Tactics.roll_chain(state, cycle)
	Arena.roll(state)
	# L'IA decide subito, cosi' le sue intenzioni si vedono durante la pianificazione (non dipendono dalla scelta degli umani).
	for p in state["players"]:
		if bool(p["ai"]) and p["choice"] == null and BattleState.player_alive(state, p):
			p["choice"] = BattleAI.choose(state, str(p["id"]))


# Fa giocare l'IA al posto di tutti gli slot ancora senza ordine (AUTOPLAY, test), poi risolve il round.
static func autoplay_round(state: Dictionary) -> Array:
	for p in state["players"]:
		if p["choice"] == null and BattleState.player_alive(state, p):
			p["choice"] = BattleAI.choose(state, str(p["id"]))
	return resolve_round(state)


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
		if not BattleState.party_of(state, p).has(swap):
			return "personaggio non in squadra"
		if not BattleState.is_alive(BattleState.unit(state, swap)):
			return "personaggio sconfitto"
		if swap != uid and BattleState.is_front(state, swap):
			return "personaggio gia' in front row"
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
			if not u["skills"].has(move_id):
				return "mossa non equipaggiata"
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
		"reaction", "rescue":
			var why: String = reaction_error(state, p, move_id)
			if why != "":
				return why
	return ""


# REAZIONI: solo contro una CARICA (mossa pesante) non ancora fermata; costano Riserva di squadra.
static func reaction_cost(state: Dictionary, move_id: String) -> int:
	return maxi(0, int(BattleContent.MOVES[move_id].get("reserve", 0)) - int(state.get("react_discount", 0)))


# Un caduto della squadra del giocatore che puo' ancora essere soccorso (una sola volta a testa).
static func fallen_of(state: Dictionary, p: Dictionary) -> String:
	for uid in BattleState.party_of(state, p):
		var u: Dictionary = BattleState.unit(state, str(uid))
		if not u.is_empty() and int(u["hp"]) <= 0 and not bool(u.get("rescued", false)):
			return str(uid)
	return ""


static func reaction_error(state: Dictionary, p: Dictionary, move_id: String) -> String:
	var move: Dictionary = BattleContent.MOVES[move_id]
	if int(state.get("reserve", 0)) < reaction_cost(state, move_id):
		return "Riserva insufficiente"
	if Tactics.reaction_locked(state, p):
		return "esausto per il prezzo pagato"
	if str(move["kind"]) == "rescue":
		return "" if fallen_of(state, p) != "" else "nessun caduto da soccorrere"
	var tele: Dictionary = state.get("telegraph", {})
	var bm: Dictionary = BattleContent.BOSS_MOVES.get(str(tele.get("move", "")), {})
	if bm.is_empty() or int(BattleState.boss(state).get("stun", 0)) > 0 or not is_heavy_boss_move(bm):
		return "nessuna carica da fermare"
	if str(move["react"]) == "intercept":
		if str(bm["target"]) == "all":
			return "serve una carica su un solo bersaglio"
		if str(tele.get("target", "")) == str(p["id"]):
			return "la carica e' su di te"
	return ""


# Reazioni disponibili adesso per questo slot: [{id, err}] (vuoto se non c'e' nessuna carica).
static func reactions_for(state: Dictionary, slot_id: String) -> Array:
	var out: Array = []
	var p: Dictionary = BattleState.player(state, slot_id)
	if p.is_empty() or str(state["winner"]) != "" or not BattleState.player_alive(state, p):
		return out
	var tele: Dictionary = state.get("telegraph", {})
	var bm: Dictionary = BattleContent.BOSS_MOVES.get(str(tele.get("move", "")), {})
	if not (bm.is_empty() or int(BattleState.boss(state).get("stun", 0)) > 0 or not is_heavy_boss_move(bm)):
		for rid in BattleContent.REACTIONS:
			out.append({"id": rid, "err": reaction_error(state, p, rid)})
	if fallen_of(state, p) != "":
		out.append({"id": "soccorso", "err": reaction_error(state, p, "soccorso")})
	return out


static func submit_choice(state: Dictionary, pid: String, choice: Dictionary) -> bool:
	if validate_choice(state, pid, choice) != "":
		return false
	var p: Dictionary = BattleState.player(state, pid)
	p["choice"] = {
		"swap": str(choice.get("swap", "")),
		"move": str(choice.get("move", "")),
		"target": str(choice.get("target", "")),
		"order": Tactics.clean_order(choice.get("order", "")),
		"push": Tactics.clean_push(choice.get("push", "")),
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
	state["link"] = {"n": 0, "last": ""}
	state["tags"] = []
	state["combo_n"] = 0
	state["combo_used"] = []
	state["reactions"] = []
	state["combo_reserve"] = false
	state["acts"] = {}

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

	# 2. cambi (gratuiti, prima di tutto). Due slot non possono chiamare in campo lo stesso personaggio.
	var claimed: Dictionary = {}
	for p in state["players"]:
		if p["choice"] == null:
			continue
		var swap: String = str(p["choice"]["swap"])
		if swap != "" and swap != str(p["active"]):
			if claimed.has(swap):
				p["choice"] = {"swap": "", "move": BattleTypes.ACTION_ATTACK, "target": ""}
				continue
			claimed[swap] = true
			_do_swap(state, p, swap, events)

	Tactics.begin_resolution(state, events)

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
	actions.append({"actor": boss["id"], "move": str(state["telegraph"]["move"]), "target": str(state["telegraph"]["target"]), "prio": 0, "spd": int(round(float(boss["spd"]) * Marks.boss_mult(boss, "spd"))), "boss": true})
	actions.sort_custom(_action_before)

	for a in actions:
		if str(state["winner"]) != "":
			break
		var actor: Dictionary = BattleState.unit(state, str(a["actor"]))
		if not BattleState.is_alive(actor):
			continue
		if bool(a["boss"]):
			_break_link(state, events)
			if int(actor.get("stun", 0)) > 0:
				actor["stun"] = int(actor["stun"]) - 1
				events.append({"t": "boss_stunned", "move": str(a["move"])})
				continue
			_boss_act(state, actor, str(a["move"]), str(a["target"]), rng, events)
		else:
			_player_act(state, actor, str(a["move"]), str(a["target"]), events)
			_summon_upkeep(state, events, false)
		_check_winner(state, events)

	# 4. fine round: prima l'evento dell'arena, poi il resto
	if str(state["winner"]) == "":
		Arena.resolve(state, events)
		_check_winner(state, events)
	if str(state["winner"]) == "":
		_end_of_round(state, events)
	_check_winner(state, events)

	Tactics.track(state, events)
	Tactics.end_round(state, events)
	_tally(state, events)
	for p in state["players"]:
		p["choice"] = null
	if str(state["winner"]) == "":
		state["round"] = int(state["round"]) + 1
		state["cycle_index"] = int(state["cycle_index"]) + 1
		_recover_balance(state, events)
		_check_phase(state, events)
		_save_rng(state, rng)
		begin_round(state)
	else:
		_save_rng(state, rng)
	return events
```
