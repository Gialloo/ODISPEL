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


# Statistiche della battaglia (per obiettivi e resoconto): rotture, sinergie, ultime volonta', KO subiti.
static func _tally(state: Dictionary, events: Array) -> void:
	var st: Dictionary = state.get("stats", {"breaks": 0, "synergies": 0, "wills": 0, "downs": 0, "phases": 0})
	for e in events:
		match str(e.get("t", "")):
			"break":
				st["breaks"] = int(st["breaks"]) + 1
				if not st.has("break_round"):
					st["break_round"] = int(state["round"])
			"plate":
				if bool(e.get("broke", false)):
					st["plates"] = int(st.get("plates", 0)) + 1
			"push":
				st["pushes"] = int(st.get("pushes", 0)) + 1
				if str(e["id"]) == "proibita":
					st["forbidden"] = int(st.get("forbidden", 0)) + 1
			"order":
				st["orders"] = int(st.get("orders", 0)) + 1
			"chain":
				if not bool(e["ok"]):
					st["chains_broken"] = int(st.get("chains_broken", 0)) + 1
			"act":
				var au: Dictionary = BattleState.unit(state, str(e.get("unit", "")))
				if not au.is_empty() and str(au["side"]) == "player":
					var uses: Dictionary = st.get("uses", {})
					var per: Dictionary = uses.get(str(au["char"]), {})
					per[str(e["move"])] = int(per.get(str(e["move"]), 0)) + 1
					uses[str(au["char"])] = per
					st["uses"] = uses
			"synergy":
				st["synergies"] = int(st["synergies"]) + 1
				_note_seen(st, "seen_combos", str(e.get("id", "")))
			"arena":
				_note_seen(st, "seen_arena", str(e.get("id", "")))
			"behavior":
				_note_seen(st, "seen_behavior", str(e.get("id", "")))
			"rescue":
				st["rescues"] = int(st.get("rescues", 0)) + 1
			"tenacity":
				st["wills"] = int(st["wills"]) + 1
			"phase":
				st["phases"] = int(st["phases"]) + 1
			"adapt":
				st["adapts"] = int(st.get("adapts", 0)) + 1
			"react":
				st["reactions"] = int(st.get("reactions", 0)) + 1
			"reserve":
				if str(e["why"]) == "react":
					st["spent"] = int(st.get("spent", 0)) - int(e["delta"])
				st["wasted"] = int(st.get("wasted", 0)) + int(e.get("wasted", 0))
			"threat":
				if not bool(e["handled"]):
					st["unhandled"] = int(st.get("unhandled", 0)) + 1
					if bool(e["could"]):
						st["missed"] = int(st.get("missed", 0)) + 1
					if int(e["lost"]) > int(st.get("worst_lost", 0)):
						st["worst_lost"] = int(e["lost"])
						st["worst_move"] = str(e["move"])
			"down":
				if str(e["unit"]) != BattleState.BOSS_ID:
					st["downs"] = int(st["downs"]) + 1
	# COMBO DECISIVA: l'ultima sinergia del round in cui il boss si rompe o cade
	var last_syn: String = ""
	var turning: bool = false
	for e in events:
		if str(e.get("t", "")) == "synergy":
			last_syn = str(e["name"])
		elif str(e.get("t", "")) == "break" or (str(e.get("t", "")) == "down" and str(e["unit"]) == BattleState.BOSS_ID):
			turning = true
	if last_syn != "" and turning:
		st["decisive"] = last_syn
		st["decisive_round"] = int(state["round"])
	state["stats"] = st


# Registro comune delle scoperte della battaglia (elenco senza doppioni, in ordine di comparsa).
static func _note_seen(st: Dictionary, key: String, id: String) -> void:
	if id == "":
		return
	var arr: Array = st.get(key, [])
	if not arr.has(id):
		arr.append(id)
	st[key] = arr


# MINACCIA: quanto fara' la mossa annunciata del boss e se sarebbe letale (senza critico). {lethal: [unit id], dmg: {unit id: n}}
static func threat_preview(state: Dictionary) -> Dictionary:
	# "enrage_lethal": chi morirebbe SOLO se il boss si infuria durante il round (i colpi dei giocatori lo portano sotto meta' PV: +25%).
	# Misurato con tools/preview_check.gd: e' l'unica causa per cui il colpo reale supera l'anteprima senza Guardia.
	var out: Dictionary = {"lethal": [], "dmg": {}, "enrage_lethal": []}
	var tele: Dictionary = state.get("telegraph", {})
	if tele.is_empty() or str(state["winner"]) != "":
		return out
	var boss: Dictionary = BattleState.boss(state)
	if int(boss.get("stun", 0)) > 0:
		return out
	var move: Dictionary = BattleContent.BOSS_MOVES.get(str(tele["move"]), {})
	if move.is_empty():
		return out
	var targets: Array = []
	if str(move["target"]) == "all":
		for p in BattleState.alive_players(state):
			targets.append(BattleState.active_unit(state, str(p["id"])))
	else:
		var tp: Dictionary = BattleState.player(state, str(tele.get("target", "")))
		if not tp.is_empty() and BattleState.player_alive(state, tp):
			targets.append(BattleState.active_unit(state, str(tp["id"])))
	for t in targets:
		if not BattleState.is_alive(t):
			continue
		var d: int = calc_damage(boss, t, float(move["mult"]))
		out["dmg"][str(t["id"])] = d
		if d >= int(t["hp"]) + int(t["shield"]):
			out["lethal"].append(str(t["id"]))
		elif _enrage_possible(boss):
			var d2: int = calc_damage(boss, t, float(move["mult"]) * BattleTypes.ENRAGE_BONUS)
			if d2 >= int(t["hp"]) + int(t["shield"]):
				out["enrage_lethal"].append(str(t["id"]))
	return out


# Il boss non e' ancora infuriato ma e' abbastanza vicino alla soglia da poterci arrivare in questo round.
const ENRAGE_WARN_MARGIN: float = 0.25

static func _enrage_possible(boss: Dictionary) -> bool:
	var frac: float = float(boss["hp"]) / float(maxi(1, int(boss["max_hp"])))
	return frac >= BattleTypes.ENRAGE_BELOW and frac < BattleTypes.ENRAGE_BELOW + ENRAGE_WARN_MARGIN


# Una mossa del boss e' una CARICA se colpisce forte uno solo o tutti con molta potenza: si puo' interrompere con la rottura.
static func is_heavy_boss_move(m: Dictionary) -> bool:
	return float(m.get("mult", 0.0)) >= 1.7 or (str(m.get("target", "")) == "all" and float(m.get("mult", 0.0)) >= 0.95)


# SUGGERIMENTI di pianificazione per chi sta per attaccare: quali sinergie sono gia' pronte con le scelte dei compagni.
static func plan_hints(state: Dictionary, slot_id: String) -> Array:
	var hints: Array = []
	var p: Dictionary = BattleState.player(state, slot_id)
	if p.is_empty() or str(state["winner"]) != "":
		return hints
	var me: Dictionary = BattleState.unit(state, str(p["active"]))
	var boss: Dictionary = BattleState.boss(state)
	if me.is_empty() or not BattleState.is_alive(boss):
		return hints
	# combo gia' pronte: cosa hanno scelto i compagni che agiscono prima di te
	var fake: Dictionary = {"tags": [], "combo_n": 0}
	for entry in action_order(state):
		if bool(entry["boss"]) or str(entry["unit"]) == str(me["id"]) or str(entry["move"]) == "":
			continue
		if int(entry["prio"]) > 0 or int(entry["spd"]) > int(me["spd"]):
			fake["tags"].append({"unit": str(entry["unit"]), "tags": Combos.tags_of(BattleContent.MOVES.get(str(entry["move"]), {}))})
	fake["units"] = state["units"]
	var shown_rules: Dictionary = {}
	for tags in [["ATTACK"], ["ATTACK", "HEAVY"], ["ATTACK", "PIERCE"]]:
		for m in Combos.matching(fake, me, boss, tags):
			var r: Dictionary = m["rule"]
			if not shown_rules.has(str(r["id"])):
				shown_rules[str(r["id"])] = true
				hints.append("%s PRONTA con %s: %s" % [str(r["name"]), str(BattleState.unit(state, str(m["with"])).get("name", "")).to_upper(), str(r["desc"])])
	hints.append_array(Arena.hint_lines(state))
	if not bool(boss.get("exposed", false)) and int(boss.get("balance", 99)) <= 6:
		hints.append("ROTTURA VICINA: equilibrio %d, colpisci col colore vantaggioso" % int(boss["balance"]))
	var tele: Dictionary = state.get("telegraph", {})
	var bm: Dictionary = BattleContent.BOSS_MOVES.get(str(tele.get("move", "")), {})
	if not bm.is_empty() and int(boss.get("stun", 0)) == 0 and is_heavy_boss_move(bm):
		hints.append("CARICA IN CORSO: la ROTTURA la interrompe (equilibrio %d)" % int(boss.get("balance", 0)))
	if float(me["hp"]) < float(me["max_hp"]) * BattleTypes.ARDOR_BELOW:
		hints.append("ARDORE: sotto il %d%% PV colpisci +%d%%" % [int(BattleTypes.ARDOR_BELOW * 100.0), int(round((BattleTypes.ARDOR_BONUS - 1.0) * 100.0))])
	var lm: String = str(me.get("last_move", ""))
	if lm != "" and BattleContent.MOVES.has(lm) and BattleContent.MOVES[lm].has("mult"):
		hints.append("RITMO: cambia mossa (ora %s) per +%d%%" % [BattleText.move_name(lm).to_upper(), int(round((BattleTypes.RHYTHM_BONUS - 1.0) * 100.0))])
	return hints


# Quando lo stordimento e' passato il boss si riprende: equilibrio di nuovo pieno.
static func _recover_balance(state: Dictionary, events: Array) -> void:
	var boss: Dictionary = BattleState.boss(state)
	if bool(boss.get("exposed", false)) and int(boss.get("stun", 0)) == 0:
		boss["exposed"] = false
		boss["balance"] = int(boss["balance_max"])
		events.append({"t": "recover"})


# FASI DEL BOSS: a meta' e a un quarto dei PV cambia ciclo, si copre con uno scudo e toglie 1 energia alla squadra,
# che in cambio riceve carica dell'ultimate (la rimonta e' possibile). Succede a fine round, prima di annunciare la mossa.
static func _phase_of(boss: Dictionary) -> int:
	var ratio: float = float(boss["hp"]) / float(maxi(1, int(boss["max_hp"])))
	if ratio < BattleTypes.PHASE_3_BELOW:
		return 3
	if ratio < BattleTypes.PHASE_2_BELOW:
		return 2
	return 1


static func _check_phase(state: Dictionary, events: Array) -> void:
	var boss: Dictionary = BattleState.boss(state)
	if not BattleState.is_alive(boss):
		return
	var ph: int = _phase_of(boss)
	if ph <= int(state.get("phase", 1)):
		return
	state["phase"] = ph
	state["cycle_index"] = 0
	boss["balance_max"] = int(boss["balance_max"]) + BattleTypes.BREAK_PER_PHASE
	if not bool(boss.get("exposed", false)):
		boss["balance"] = int(boss["balance_max"])
	events.append({"t": "phase", "phase": ph})
	if ph == 2 and int(state.get("reserve", 0)) > 0:
		_spend_reserve(state, BattleTypes.RESERVE_DRAIN_PHASE, "boss", events)
	var sh: int = int(round(float(boss["max_hp"]) * BattleTypes.PHASE_SHIELD))
	boss["shield"] = int(boss["shield"]) + sh
	events.append({"t": "shield", "src": boss["id"], "dst": boss["id"], "amount": sh})
	for uid in state["units"]:
		var u: Dictionary = state["units"][uid]
		if str(u["side"]) != "player" or not BattleState.is_alive(u):
			continue
		u["energy"] = maxi(0, int(u["energy"]) - 1)
		u["gauge"] = mini(BattleTypes.GAUGE_MAX, int(u["gauge"]) + BattleTypes.PHASE_GAUGE)


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
static func calc_damage(attacker: Dictionary, defender: Dictionary, mult: float, pierce: int = 0, flat: float = 0.0, ammo_hit: bool = false) -> int:
	var dmg: float = float(attacker["atk"]) * Marks.boss_mult(attacker, "atk") * mult + flat
	dmg *= BattleTypes.color_multiplier(str(attacker["color"]), str(defender["color"]))
	dmg *= Marks.bonus_mult(defender, ammo_hit)
	dmg *= Archetypes.damage_mult(attacker, defender)
	dmg *= Signatures.damage_mult(attacker, defender)
	dmg *= Tactics.damage_mult(attacker)
	if str(attacker["side"]) == "boss" and float(attacker["hp"]) < float(attacker["max_hp"]) * BattleTypes.ENRAGE_BELOW:
		dmg *= BattleTypes.ENRAGE_BONUS
	if str(defender["side"]) == "boss" and bool(defender.get("exposed", false)):
		dmg *= BattleTypes.BREAK_DAMAGE
	if str(attacker["side"]) == "player" and float(attacker["hp"]) < float(attacker["max_hp"]) * BattleTypes.ARDOR_BELOW:
		dmg *= BattleTypes.ARDOR_BONUS
	if float(defender["hp"]) < float(defender["max_hp"]) * BattleTypes.ENRAGE_BELOW:
		for pass_id in attacker["passives"]:
			if bool(BattleContent.PASSIVES.get(str(pass_id), {}).get("hunter", false)):
				dmg *= BattleTypes.HUNTER_BONUS
	dmg = dmg * 100.0 / (100.0 + float(defender["def"]) * Marks.boss_mult(defender, "def") * float(100 - clampi(pierce, 0, 100)) / 100.0)
	if defender["statuses"].has("guard"):
		dmg *= BattleTypes.GUARD_FACTOR
	return maxi(1, int(round(dmg)))


# LEGAMI: se due compagni agiscono di fila nello stesso round (senza che il boss si intrometta) nasce un LINK.
# Ogni anello aggiunge danno a chi attacca; fazioni diverse (CROSS) caricano l'ultimate di entrambi,
# la stessa fazione o lo stesso colore (UNISONO) rende il colpo ancora piu' forte.
static func _chain_link(state: Dictionary, actor: Dictionary, events: Array) -> int:
	var link: Dictionary = state.get("link", {"n": 0, "last": ""})
	var last: Dictionary = BattleState.unit(state, str(link.get("last", "")))
	var n: int = 0
	if not last.is_empty() and str(last["id"]) != str(actor["id"]):
		n = mini(int(link.get("n", 0)) + 1, BattleTypes.LINK_MAX)
		var fa: String = BattleContent.faction_of(str(actor["char"]), actor)
		var fl: String = BattleContent.faction_of(str(last["char"]), last)
		var kind: String = "cross"
		if fa == fl or str(actor["color"]) == str(last["color"]):
			kind = "unison"
			n = mini(n + 1, BattleTypes.LINK_MAX)
		else:
			actor["gauge"] = mini(BattleTypes.GAUGE_MAX, int(actor["gauge"]) + BattleTypes.LINK_GAUGE)
			last["gauge"] = mini(BattleTypes.GAUGE_MAX, int(last["gauge"]) + BattleTypes.LINK_GAUGE)
		events.append({"t": "link", "unit": actor["id"], "with": last["id"], "n": n, "kind": kind})
	state["link"] = {"n": n, "last": str(actor["id"])}
	return n


static func _break_link(state: Dictionary, events: Array) -> void:
	var link: Dictionary = state.get("link", {})
	if int(link.get("n", 0)) > 0:
		events.append({"t": "link_break", "n": int(link["n"])})
	state["link"] = {"n": 0, "last": ""}


# Applica un colpo: prima lo scudo, poi i PV. Carica le barre ultimate.
static func _hit(state: Dictionary, attacker: Dictionary, defender: Dictionary, mult: float, events: Array, pierce: int = 0, flat: float = 0.0, ammo_hit: bool = false, crit_pm: int = 0, crit_dmg_boost: int = 0) -> void:
	if Marks.dodges(state, defender, attacker, events.size()):
		events.append({"t": "dodge", "unit": defender["id"]})
		return
	var dmg: int = calc_damage(attacker, defender, mult, pierce, flat, ammo_hit)
	var crit: bool = Factions.rolls_crit(state, attacker, defender, events.size(), crit_pm)
	if crit:
		var cd: float = float(attacker.get("crit_dmg", Factions.CRIT_DMG_PM)) * (1.0 + float(crit_dmg_boost) / 1000.0)
		dmg = maxi(1, int(round(float(dmg) * cd / 1000.0)))
	if str(defender["side"]) == "boss" and str(attacker["side"]) == "player":
		dmg = Tactics.plate_hit(state, defender, dmg, pierce, events)
	var absorbed: int = mini(int(defender["shield"]), dmg)
	defender["shield"] = int(defender["shield"]) - absorbed
	var lost: int = dmg - absorbed
	var tenacious: bool = false
	if lost >= int(defender["hp"]) and str(defender["side"]) == "player" and str(attacker["side"]) == "boss" and not bool(defender.get("tenacity_used", false)):
		# TENACIA: la prima volta che un colpo sarebbe mortale, l'operatore resta in piedi con 1 PV e la barra piena
		tenacious = true
		defender["tenacity_used"] = true
		lost = maxi(0, int(defender["hp"]) - 1)
		defender["gauge"] = BattleTypes.GAUGE_MAX
	defender["hp"] = maxi(0, int(defender["hp"]) - lost)
	var hit_event: Dictionary = {"t": "damage", "src": attacker["id"], "dst": defender["id"], "amount": lost, "absorbed": absorbed}
	if crit:
		hit_event["crit"] = true
	events.append(hit_event)
	if tenacious:
		events.append({"t": "tenacity", "unit": defender["id"]})
	Tactics.on_damaged(defender, events)
	if str(defender["side"]) == "boss" and str(attacker["side"]) == "player" and int(defender["hp"]) > 0:
		_chip_balance(defender, attacker, mult, events)
	if crit and Atypical.fx(attacker, "crit_ammo") > 0:
		_change_ammo(attacker, Atypical.fx(attacker, "crit_ammo"), events)
	var reflect: int = Atypical.fx(defender, "reflect_shield")
	if reflect > 0 and absorbed > 0 and str(attacker["side"]) == "boss" and str(defender["side"]) == "player":
		var returned: int = maxi(1, int(round(float(absorbed) * float(reflect) / 1000.0)))
		attacker["hp"] = maxi(0, int(attacker["hp"]) - returned)
		events.append({"t": "damage", "src": defender["id"], "dst": attacker["id"], "amount": returned, "absorbed": 0, "thorns": true})
		if int(attacker["hp"]) <= 0:
			_on_down(attacker, events)
		events.append({"t": "trait", "trait": "atipico", "unit": defender["id"], "name": Atypical.trait_name(str(defender["char"]))})
	if str(attacker["side"]) == "player":
		attacker["gauge"] = mini(BattleTypes.GAUGE_MAX, int(attacker["gauge"]) + Archetypes.gauge_on_hit(attacker))
		Archetypes.after_hit(attacker, crit)
	if str(defender["side"]) == "player":
		defender["gauge"] = mini(BattleTypes.GAUGE_MAX, int(defender["gauge"]) + BattleTypes.GAUGE_ON_DAMAGED)
	var steal: float = Signatures.value(attacker, "lifesteal")
	if steal > 0.0 and lost > 0 and BattleState.is_alive(attacker):
		var got: int = mini(int(attacker["max_hp"]) - int(attacker["hp"]), int(round(float(lost) * steal)))
		if got > 0:
			attacker["hp"] = int(attacker["hp"]) + got
			events.append({"t": "heal", "src": attacker["id"], "dst": attacker["id"], "amount": got})
	if int(defender["hp"]) <= 0:
		_on_down(defender, events)
	else:
		Factions.on_hit_taken(state, defender, events)
		var thorn: float = Signatures.value(defender, "thorns")
		if thorn > 0.0 and str(attacker["side"]) == "boss" and str(defender["side"]) == "player":
			var back: int = maxi(1, int(round(float(defender["atk"]) * thorn)))
			attacker["hp"] = maxi(0, int(attacker["hp"]) - back)
			events.append({"t": "damage", "src": defender["id"], "dst": attacker["id"], "amount": back, "absorbed": 0, "thorns": true})
			if int(attacker["hp"]) <= 0:
				_on_down(attacker, events)


# COMBO (vedi Combos): quello che hanno fatto i compagni nello stesso round cambia il tuo colpo.
# Ritorna il moltiplicatore di danno; applica ultimate e rottura e registra gli eventi "synergy" (con tier di presentazione).
static func _synergies(state: Dictionary, actor: Dictionary, boss: Dictionary, events: Array, move: Dictionary = {}) -> float:
	var my_tags: Array = Combos.tags_of(move) if not move.is_empty() else ["ATTACK"]
	var found: Array = Combos.matching(state, actor, boss, my_tags)
	var mult: float = 1.0
	for m in found:
		var r: Dictionary = m["rule"]
		var n: int = int(state.get("combo_n", 0))
		state["combo_n"] = n + 1
		var used: Array = state.get("combo_used", [])
		used.append("%s|%s" % [str(r["id"]), str(m["with"])])
		state["combo_used"] = used
		mult *= float(r["mult"]) * (1.0 + Combos.CHAIN_BONUS * float(mini(n, Combos.CHAIN_MAX)))
		if int(r["gauge"]) > 0:
			actor["gauge"] = mini(BattleTypes.GAUGE_MAX, int(actor["gauge"]) + int(r["gauge"]))
			var mk: Dictionary = BattleState.unit(state, str(m["with"]))
			mk["gauge"] = mini(BattleTypes.GAUGE_MAX, int(mk["gauge"]) + int(r["gauge"]) / 2)
		if int(r["brk"]) > 0:
			_drain_balance(boss, int(r["brk"]), actor, events)
		events.append({"t": "synergy", "id": str(r["id"]), "name": str(r["name"]), "unit": actor["id"], "with": str(m["with"]), "tier": mini(n, 2), "fx": str(r["fx"]), "col": str(r["col"])})
		if not bool(state.get("combo_reserve", false)):
			state["combo_reserve"] = true
			_gain_reserve(state, BattleTypes.RESERVE_PER_COMBO, "combo", events)
	return mult


# Equilibrio del boss: ogni colpo lo consuma (di piu' col vantaggio di colore, sui marchiati e coi colpi pesanti).
static func _chip_balance(boss: Dictionary, attacker: Dictionary, mult: float, events: Array) -> void:
	if int(boss.get("stun", 0)) > 0 or bool(boss.get("exposed", false)):
		return
	var cm: float = BattleTypes.color_multiplier(str(attacker["color"]), str(boss["color"]))
	var pts: int = BattleTypes.BREAK_ADV if cm > 1.0 else (BattleTypes.BREAK_DISADV if cm < 1.0 else BattleTypes.BREAK_NEUTRAL)
	if Marks.count(boss) > 0:
		pts += BattleTypes.BREAK_MARKED
	if mult >= 2.0:
		pts += BattleTypes.BREAK_HEAVY
	_drain_balance(boss, pts, attacker, events)


# Toglie punti di equilibrio al boss; a zero scatta la rottura.
static func _drain_balance(boss: Dictionary, pts: int, attacker: Dictionary, events: Array) -> void:
	if int(boss.get("stun", 0)) > 0 or bool(boss.get("exposed", false)):
		return
	boss["balance"] = maxi(0, int(boss["balance"]) - pts)
	events.append({"t": "balance", "src": attacker["id"], "amount": pts, "left": int(boss["balance"])})
	if int(boss["balance"]) <= 0:
		boss["stun"] = 1
		boss["exposed"] = true
		events.append({"t": "break", "src": attacker["id"]})


# Munizioni: positivo = ricarica, negativo = si spendono. Resta tra 0 e il massimo dell'unita'.
static func _change_ammo(u: Dictionary, delta: int, events: Array) -> void:
	if delta == 0 or int(u["ammo_max"]) <= 0:
		return
	var now: int = clampi(int(u["ammo"]) + delta, 0, int(u["ammo_max"]))
	if now < int(u["ammo"]):
		Atypical.on_ammo_spent(u, int(u["ammo"]) - now)
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

# Riserva di squadra: guadagno (con tetto) e spesa. L'evento porta il valore finale, cosi' lo schermo resta coerente.
static func _gain_reserve(state: Dictionary, n: int, why: String, events: Array) -> void:
	var before: int = int(state.get("reserve", 0))
	var after: int = mini(BattleTypes.RESERVE_MAX, before + n)
	state["reserve"] = after
	events.append({"t": "reserve", "delta": after - before, "value": after, "why": why, "wasted": n - (after - before)})


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
			# VOLUTO: lo scudo si calcola sulla cura TEORICA (amount), non su quella reale: la cura in eccesso diventa scudo.
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
