class_name SeqRound
extends RefCounted

# ROUND A TURNI SEQUENZIALI (solo Test V2).
# Il motore classico risolve il round tutto insieme (BattleResolver.resolve_round): prima si scelgono tutte le azioni, poi si
# eseguono in ordine di priorita' e velocita'. Qui lo stesso round e' spezzato in passi: ogni personaggio (e il boss) agisce
# nel suo turno, in ordine di velocita', e la sua azione si risolve subito. Si riusano le funzioni di azione del motore
# (_player_act, _boss_act, fine round), SENZA modificare BattleResolver: la battaglia classica, il PvP e il multiplayer restano come prima.
#
# Uso: begin(state) -> order(state) -> per ogni voce: player_action(...) oppure boss_action(...) -> finish(state).
#
# Differenze volute rispetto al motore classico (da conoscere):
#  - l'ordine dipende SOLO dalla velocita' (la priorita' della mossa scelta non si conosce prima della scelta);
#  - per non rendere inutili le difese scelte da chi agisce dopo il boss, gli stati e gli scudi ottenuti DOPO la mossa del boss
#    (Guardia, scudi, potenziamenti) non scadono a fine round ma valgono per il round successivo.


static func begin(state: Dictionary) -> void:
	state["link"] = {"n": 0, "last": ""}
	state["tags"] = []
	state["combo_n"] = 0
	state["combo_used"] = []
	state["reactions"] = []
	state["combo_reserve"] = false
	state["acts"] = {}
	var ev: Array = []
	state["events"] = ev
	state["seq"] = {"events": [], "claimed": {}, "boss_acted": false, "snap": {}}
	for p in state["players"]:
		p["choice"] = null
	Tactics.begin_resolution(state, ev)
	_log(state, ev)


static func active(state: Dictionary) -> bool:
	return state.has("seq") and str(state.get("winner", "")) == ""


# Ordine dei turni: velocita' decrescente, parita' per id (come il motore). Il boss ha la sua velocita' (con i marchi).
static func order(state: Dictionary) -> Array:
	var list: Array = []
	for p in state["players"]:
		if not BattleState.player_alive(state, p):
			continue
		var u: Dictionary = BattleState.active_unit(state, str(p["id"]))
		if not BattleState.is_alive(u):
			continue
		list.append({"unit": str(u["id"]), "player": str(p["id"]), "boss": false, "spd": int(u["spd"])})
	var boss: Dictionary = BattleState.boss(state)
	list.append({"unit": str(boss["id"]), "player": "", "boss": true, "spd": int(round(float(boss["spd"]) * Marks.boss_mult(boss, "spd")))})
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["spd"]) != int(b["spd"]):
			return int(a["spd"]) > int(b["spd"])
		return str(a["unit"]) < str(b["unit"]))
	return list


# Azione di un giocatore (slot): `choice` come in BattleResolver.submit_choice. Ritorna gli eventi del solo passo.
static func player_action(state: Dictionary, pid: String, choice: Dictionary) -> Array:
	var events: Array = []
	if str(state["winner"]) != "":
		return events
	state["events"] = events
	var p: Dictionary = BattleState.player(state, pid)
	if p.is_empty() or not BattleState.player_alive(state, p):
		return events
	if BattleResolver.validate_choice(state, pid, choice) != "":
		choice = {"swap": "", "move": BattleTypes.ACTION_ATTACK, "target": ""}
	p["choice"] = {
		"swap": str(choice.get("swap", "")),
		"move": str(choice.get("move", "")),
		"target": str(choice.get("target", "")),
		"order": "",
		"push": "",
	}
	# cambio (gratuito, subito prima dell'azione); due slot non possono chiamare in campo lo stesso personaggio
	var swap: String = str(p["choice"]["swap"])
	if swap != "" and swap != str(p["active"]):
		var claimed: Dictionary = state["seq"]["claimed"]
		if claimed.has(swap):
			p["choice"] = {"swap": "", "move": BattleTypes.ACTION_ATTACK, "target": "", "order": "", "push": ""}
		else:
			claimed[swap] = true
			BattleResolver._do_swap(state, p, swap, events)
	var actor: Dictionary = BattleState.active_unit(state, pid)
	if BattleState.is_alive(actor):
		BattleResolver._player_act(state, actor, str(p["choice"]["move"]), str(p["choice"]["target"]), events)
		BattleResolver._summon_upkeep(state, events, false)
		BattleResolver._check_winner(state, events)
	p["choice"] = null
	_log(state, events)
	return events


# Turno del boss: la mossa e' quella annunciata (telegraph) all'inizio del round.
static func boss_action(state: Dictionary) -> Array:
	var events: Array = []
	if str(state["winner"]) != "":
		return events
	state["events"] = events
	var boss: Dictionary = BattleState.boss(state)
	if BattleState.is_alive(boss):
		var tele: Dictionary = state["telegraph"]
		BattleResolver._break_link(state, events)
		if int(boss.get("stun", 0)) > 0:
			boss["stun"] = int(boss["stun"]) - 1
			events.append({"t": "boss_stunned", "move": str(tele["move"])})
		else:
			var rng: RNGState = BattleResolver._load_rng(state)
			BattleResolver._boss_act(state, boss, str(tele["move"]), str(tele["target"]), rng, events)
			BattleResolver._save_rng(state, rng)
		BattleResolver._check_winner(state, events)
	state["seq"]["boss_acted"] = true
	state["seq"]["snap"] = _snapshot(state)
	_log(state, events)
	return events


# Fine round: arena, fine round del motore, statistiche, nuovo round (stessi passi di resolve_round dopo le azioni).
static func finish(state: Dictionary) -> Array:
	var events: Array = []
	state["events"] = events
	var carry: Array = _carry(state)
	if str(state["winner"]) == "":
		Arena.resolve(state, events)
		BattleResolver._check_winner(state, events)
	if str(state["winner"]) == "":
		BattleResolver._end_of_round(state, events)
	BattleResolver._check_winner(state, events)
	_log(state, events)
	var all: Array = state["seq"]["events"]
	Tactics.track(state, all)
	Tactics.end_round(state, all)
	BattleResolver._tally(state, all)
	for p in state["players"]:
		p["choice"] = null
	if str(state["winner"]) == "":
		state["round"] = int(state["round"]) + 1
		state["cycle_index"] = int(state["cycle_index"]) + 1
		BattleResolver._recover_balance(state, events)
		BattleResolver._check_phase(state, events)
		BattleResolver.begin_round(state)
		_apply_carry(state, carry, events)
	state.erase("seq")
	return events


# ---------- interni ----------

static func _log(state: Dictionary, events: Array) -> void:
	if state.has("seq"):
		(state["seq"]["events"] as Array).append_array(events)


# Stato dei personaggi dei giocatori subito dopo la mossa del boss
static func _snapshot(state: Dictionary) -> Dictionary:
	var snap: Dictionary = {}
	for uid in state["units"]:
		var u: Dictionary = state["units"][uid]
		if str(u["side"]) == "player":
			snap[uid] = {"statuses": (u["statuses"] as Dictionary).duplicate(), "shield": int(u["shield"])}
	return snap


# Cio' che e' stato guadagnato DOPO la mossa del boss (stati nuovi o piu' lunghi, scudo in piu'): sarebbe scaduto senza servire
static func _carry(state: Dictionary) -> Array:
	var out: Array = []
	var snap: Dictionary = state["seq"].get("snap", {})
	if not bool(state["seq"].get("boss_acted", false)) or snap.is_empty():
		return out
	for uid in snap:
		var u: Dictionary = state["units"][uid]
		if not BattleState.is_alive(u):
			continue
		var before: Dictionary = snap[uid]
		var gained: Dictionary = {}
		for s in u["statuses"]:
			var b: int = int((before["statuses"] as Dictionary).get(s, 0))
			if int(u["statuses"][s]) > b:
				gained[s] = int(u["statuses"][s])
		var sh: int = int(u["shield"]) - int(before["shield"])
		if not gained.is_empty() or sh > 0:
			out.append({"unit": uid, "statuses": gained, "shield": maxi(0, sh)})
	return out


static func _apply_carry(state: Dictionary, carry: Array, events: Array) -> void:
	for c in carry:
		var u: Dictionary = state["units"][str(c["unit"])]
		if not BattleState.is_alive(u):
			continue
		for s in c["statuses"]:
			u["statuses"][s] = maxi(int(u["statuses"].get(s, 0)), int(c["statuses"][s]))
		if int(c["shield"]) > 0:
			u["shield"] = int(u["shield"]) + int(c["shield"])
