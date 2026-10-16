FILE battle_resolver.gd - PARTE 2 DI 5
Percorso: scripts/battle/battle_resolver.gd
(Codice GDScript, rientri con tab. Non rispondere finche' non scrivo FINE FILE.)

```gdscript
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
	var out: Dictionary = {"lethal": [], "dmg": {}}
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
	return out


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
```
