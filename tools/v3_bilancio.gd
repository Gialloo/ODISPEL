extends SceneTree

# BILANCIO DELLA BATTAGLIA: simula gli scontri dell'atto 1 con l'IA automatica (BattleAI) e stampa le metriche del piano combat.
# Serve a tarare le costanti del motore (equilibrio, Riserva, ...) senza giocare: ripetibile, deterministica (semi fissi).
# Uso: godot --headless --path . --script tools/v3_bilancio.gd -- [semi=40] [minori] [dettaglio] [replica=N] [solo=distributore]
#   semi=N      quanti semi per scontro (default 40)
#   replica=N   Replica della diretta: nemici +15% PV e attacco per giro
#   dettaglio   sotto ogni scontro la quota di danno di tutti e quattro
#   minori      include anche i frammenti (nemici minori), compresi quelli con la scheggia (due nemici, Gregario)
#   solo=ID     un solo scontro
#   ng=N        New Game+ N: nemici al livello di BattleTypes.replica_level, squadra da Progress (sblocchi migliori equipaggiati)
#   scarto=K    con ng: la squadra ha K livelli in meno del nemico (default 0; negativo = piu' alta)
#   kit         anche senza ng, la squadra usa Progress (sblocchi del livello) invece del kit base
#   giro        senza Timeline: il giro a round della Fase 0 (per confrontare)  · vel  tabella VEL / ΔT / azioni ai livelli (Fase 1)
# Gli scontri e le scale PV/attacco replicano battle3d.gd (pv_k, atk_k, livello); la squadra e' quella dell'atto 1 con ultimate al 60%.
# Metriche: esito, KO, turni boss, danno diretto/indiretto, cure effettive, scudi, reazioni e timeout.
# Le occasioni sono conteggiate solo quando un eroe ha un turno prima della carica e una reazione difensiva valida.

const PARTY: Array = ["ferri", "nox", "zecca", "saul"]
# (boss, livello, pv, atk, minore)
const ENC: Array = [
	["frammento_giallo", 1, 1.0, 1.0, true], ["frammento_rosso", 3, 1.0, 1.0, true], ["frammento_blu", 5, 1.0, 1.0, true], ["frammento_verde", 7, 1.0, 1.0, true],
	["distributore", 1, 1.0, 0.8, false], ["semaforo", 3, 0.9, 0.9, false], ["cabina", 5, 0.8, 0.9, false],
	["manichino", 7, 0.8, 0.85, false], ["cassaforte", 9, 0.6, 0.75, false], ["autovelox", 11, 0.65, 0.8, false],
	# due nemici (Gregario): frammento + scheggia, come in data/atto1.json
	["frammento_blu", 5, 1.0, 1.0, true, "frammento_rosso"], ["frammento_verde", 7, 1.0, 1.0, true, "frammento_blu"],
	["frammento_verde", 9, 1.0, 1.0, true, "frammento_rosso"], ["frammento_giallo", 10, 1.0, 1.0, true, "frammento_verde"],
	["frammento_rosso", 10, 1.0, 1.0, true, "frammento_blu"]]


var replica: int = 0
var ng: int = -1
var scarto: int = 0
var use_kit: bool = false


# Squadra di Progress al livello dato, con l'ultimo sblocco di ogni tipo equipaggiato
func _kit_team(lvl: int) -> Array:
	Progress.reset()
	var team: Array = []
	for c in PARTY:
		Progress.data["lv"][c] = clampi(lvl, 1, Progress.MAX_LEVEL)
		for u in Progress.UNLOCKS[c]:
			if int(u[0]) <= int(Progress.data["lv"][c]):
				Progress.equip(c, str(u[1]), str(u[2]))
		team.append(Progress.entry_for(c))
	return team


func _setup(boss: String, lvl: int, pv: float, atk: float, minore: bool, seed_value: int, greg: String = "") -> Dictionary:
	var team: Array = []
	if ng >= 0:
		lvl = BattleTypes.replica_level(lvl, ng)
	if ng >= 0 or use_kit:
		team = _kit_team(lvl - scarto)
	else:
		for id in PARTY:
			team.append(BattleContent.default_entry(id, lvl))
	var b: Dictionary = BattleState.create_solo("IO", team, [], boss, seed_value)
	var bu: Dictionary = BattleState.boss(b)
	var grow: float = BattleTypes.story_hp_grow(lvl)
	var rk: float = BattleTypes.replica_hard(replica)
	pv *= rk
	atk *= rk
	var pk: float = pv * (BattleTypes.STORY_HP_MINOR if minore else BattleTypes.STORY_HP_BOSS) * grow
	var ak: float = atk * BattleTypes.STORY_ATK_K * BattleTypes.story_atk_grow(lvl)
	bu["max_hp"] = maxi(1, int(round(float(bu["max_hp"]) * pk)))
	bu["hp"] = bu["max_hp"]
	bu["atk"] = maxi(1, int(round(float(bu["atk"]) * ak)))
	bu["spd"] = BattleContent.enemy_spd_at(int(bu["spd"]), lvl)     # D5, come battle3d
	Gregario.add(b, greg)
	if ng >= 0 or use_kit:
		Progress.apply_to_battle(b)
	for uid in b["units"]:
		if not Gregario.is_enemy(b, str(uid)):
			b["units"][uid]["gauge"] = mini(BattleTypes.GAUGE_MAX, 60 + int(b["units"][uid].get("syn_gauge", 0)))
	return b


# TIMELINE (Fase 1): VEL vere della squadra e dei boss a vari livelli, ΔT dell'ATTACCO e azioni di ogni eroe
# per ogni azione del boss (1,00 = come nel giro a round). Serve per la decisione D5 (VEL di riferimento fissa o normalizzata).
func _vel_table() -> void:
	print("Timeline: ΔT ATTACCO = 100 × 100 / (100 + 0,3 × (VEL − 100)); 'x boss' = azioni dell'eroe per ogni azione del boss")
	for lvl in [1, 5, 11, 30, 100]:
		var line: String = "liv %3d |" % lvl
		var b: Dictionary = _setup("semaforo", lvl, 1.0, 1.0, false, 1)
		var bs: int = int(BattleState.boss(b)["spd"])
		var bdt: int = BattleFlow.delta_t(BattleTypes.TL_ENEMY_COST, bs)
		for p in b["players"]:
			var u: Dictionary = BattleState.active_unit(b, str(p["id"]))
			var dt: int = BattleFlow.delta_t(100, int(u["spd"]))
			line += " %s VEL %d ΔT %.1f x boss %.2f |" % [str(u["char"]), int(u["spd"]), dt / 100.0, float(bdt) / float(dt)]
		var bl: String = ""
		for boss in ["distributore", "semaforo", "cabina", "manichino", "cassaforte", "autovelox"]:
			var bb: Dictionary = _setup(boss, lvl, 1.0, 1.0, false, 1)
			bl += " %s %d" % [boss, int(BattleState.boss(bb)["spd"])]
		print(line)
		print("        | VEL boss:" + bl + "  (semaforo ΔT %.1f)" % (bdt / 100.0))


func _char_of(uid: String) -> String:
	var parts: PackedStringArray = uid.split(":")
	return parts[parts.size() - 1]


func _add(st: Dictionary, key: String, amount: float) -> void:
	st[key] = float(st.get(key, 0.0)) + amount


func _scan(ev: Array, st: Dictionary, state: Dictionary) -> void:
	for e in ev:
		var t: String = str(e.get("t", ""))
		match t:
			"damage":
				if bool(e.get("cost", false)):
					continue
				var src: String = str(e.get("src", ""))
				var dst: String = str(e.get("dst", ""))
				var amount: float = float(e.get("amount", 0))
				var absorbed: float = float(e.get("absorbed", 0))
				var source_unit: Dictionary = state.get("units", {}).get(src, {})
				var target_unit: Dictionary = state.get("units", {}).get(dst, {})
				var source_player: bool = str(source_unit.get("side", "")) == "player"
				var target_player: bool = str(target_unit.get("side", "")) == "player"
				if source_player and dst == BattleState.BOSS_ID:
					if bool(e.get("thorns", false)):
						_add(st, "dmg_reflected_boss", amount)
						_add(st, "dmg_boss_absorbed", absorbed)
						_add(st, "dmg_boss_pressure", amount + absorbed)
					else:
						var attacker: String = _char_of(src)
						_add(st, "dmg_" + attacker, amount)
						_add(st, "dmg_tot", amount)
						_add(st, "dmg_boss_direct_hp", amount)
						_add(st, "dmg_boss_absorbed", absorbed)
						_add(st, "dmg_boss_pressure", amount + absorbed)
				elif source_player and dst == Gregario.ID:
					_add(st, "dmg_gregario_hp", amount)
					_add(st, "dmg_gregario_absorbed", absorbed)
					_add(st, "dmg_gregario_pressure", amount + absorbed)
				elif target_player:
					_add(st, "dmg_party_hp", amount)
					_add(st, "dmg_party_absorbed", absorbed)
					if bool(e.get("thorns", false)):
						_add(st, "dmg_reflected_party", amount)
				if source_player and str(target_unit.get("side", "")) == "boss":
					_add(st, "dmg_enemy_other_hp", amount)
			"bleed":
				var target_id: String = str(e.get("unit", ""))
				var bleed_target: Dictionary = state.get("units", {}).get(target_id, {})
				var bleed_amount: float = float(e.get("amount", 0))
				if str(bleed_target.get("side", "")) == "boss":
					if target_id == BattleState.BOSS_ID:
						_add(st, "dmg_boss_indirect_hp", bleed_amount)
						_add(st, "dmg_boss_pressure", bleed_amount)
					elif target_id == Gregario.ID:
						_add(st, "dmg_gregario_indirect_hp", bleed_amount)
					else:
						_add(st, "dmg_indirect_enemy_hp", bleed_amount)
				elif str(bleed_target.get("side", "")) == "player":
					_add(st, "dmg_party_bleed_hp", bleed_amount)
			"arena":
				var arena_id: String = str(e.get("id", ""))
				if arena_id == "eco":
					var eco_hp: float = float(e.get("hp_lost", 0))
					var eco_abs: float = float(e.get("absorbed", 0))
					_add(st, "dmg_arena_boss_hp", eco_hp)
					_add(st, "dmg_boss_absorbed", eco_abs)
					_add(st, "dmg_boss_pressure", eco_hp + eco_abs)
				elif arena_id == "contaminazione":
					_add(st, "dmg_party_arena_hp", float(e.get("hp_lost", e.get("amount", 0))))
			"plate":
				var plate_hit: float = float(e.get("hit", 0))
				_add(st, "dmg_boss_plate", plate_hit)
				_add(st, "dmg_boss_pressure", plate_hit)
			"heal":
				var healer: String = str(e.get("src", ""))
				var recipient: String = str(e.get("dst", ""))
				var healed: float = float(e.get("amount", 0))
				var recipient_unit: Dictionary = state.get("units", {}).get(recipient, {})
				if str(recipient_unit.get("side", "")) == "player" and healer != BattleState.BOSS_ID:
					_add(st, "heal_" + _char_of(healer), healed)
					_add(st, "heal_total_hp", healed)
					_add(st, "heal_events", 1.0)
			"rescue":
				_add(st, "rescue_count", 1.0)
				_add(st, "rescue_hp", float(e.get("hp", 0)))
			"rest":
				_add(st, "rest_nox", 1.0)
				_add(st, "heal_nox", 1.0)
			"shield":
				var shield_src: String = str(e.get("src", ""))
				var shield_dst: String = str(e.get("dst", ""))
				var shield_target: Dictionary = state.get("units", {}).get(shield_dst, {})
				var shield_amount: float = float(e.get("amount", 0))
				if str(shield_target.get("side", "")) == "player":
					_add(st, "shield_created_party", shield_amount)
					_add(st, "shield_created_events", 1.0)
					var shield_owner: Dictionary = state.get("units", {}).get(shield_src, {})
					if str(shield_owner.get("side", "")) == "player":
						_add(st, "shield_" + _char_of(shield_src), shield_amount)
				elif str(shield_target.get("side", "")) == "boss":
					_add(st, "shield_created_enemy", shield_amount)
			"shield_expire":
				var expired_unit: Dictionary = state.get("units", {}).get(str(e.get("unit", "")), {})
				if str(expired_unit.get("side", "")) == "player":
					_add(st, "shield_expired_party_raw", float(e.get("amount", 0)))
			"shield_carry":
				var carried_unit: Dictionary = state.get("units", {}).get(str(e.get("unit", "")), {})
				if str(carried_unit.get("side", "")) == "player":
					_add(st, "shield_carried_party", float(e.get("amount", 0)))
			"kit_trait":
				if str(e.get("trait", "")) == "veglia":
					_add(st, "veglia", 1.0)
			"react":
				_add(st, "react", 1.0)
				_add(st, "react_" + str(e.get("kind", "unknown")), 1.0)
			"resource_delta":
				var resource: String = str(e.get("resource", ""))
				var resource_unit: String = str(e.get("unit", ""))
				var resource_char: String = str(e.get("char", _char_of(resource_unit)))
				var delta: float = float(e.get("delta", 0))
				if resource != "" and resource != "ammo":
					_add(st, "res_" + resource + "_net", delta)
					_add(st, "res_" + resource + "_net_" + resource_char, delta)
					if delta > 0.0:
						_add(st, "res_" + resource + "_gain_net", delta)
						_add(st, "res_" + resource + "_gain_net_" + resource_char, delta)
					elif delta < 0.0:
						_add(st, "res_" + resource + "_spend_net", -delta)
						_add(st, "res_" + resource + "_spend_net_" + resource_char, -delta)
			"resource_change":
				var changed_resource: String = str(e.get("resource", ""))
				var changed_unit: String = str(e.get("unit", ""))
				var changed_char: String = _char_of(changed_unit)
				var changed_delta: float = float(e.get("delta", 0))
				_add(st, "res_" + changed_resource + "_requested", float(e.get("requested", 0)))
				_add(st, "res_" + changed_resource + "_effective", float(e.get("effective", 0)))
				_add(st, "res_" + changed_resource + "_wasted", float(e.get("wasted", 0)))
				var change_source: String = str(e.get("source", "unknown"))
				_add(st, "res_" + changed_resource + "_source_" + change_source + "_net", changed_delta)
				if changed_delta > 0.0:
					_add(st, "res_" + changed_resource + "_gain_gross", changed_delta)
					_add(st, "res_" + changed_resource + "_gain_gross_" + changed_char, changed_delta)
					_add(st, "res_" + changed_resource + "_source_" + change_source + "_gain", changed_delta)
				elif changed_delta < 0.0:
					_add(st, "res_" + changed_resource + "_spend_gross", -changed_delta)
					_add(st, "res_" + changed_resource + "_spend_gross_" + changed_char, -changed_delta)
					_add(st, "res_" + changed_resource + "_source_" + change_source + "_spend", -changed_delta)
			"resource_cost":
				var cost_resource: String = str(e.get("resource", ""))
				var cost_unit: String = str(e.get("unit", ""))
				var cost_char: String = _char_of(cost_unit)
				var cost_amount: float = float(e.get("amount", 0))
				_add(st, "res_" + cost_resource + "_cost", cost_amount)
				_add(st, "res_" + cost_resource + "_cost_" + cost_char, cost_amount)
			"ammo":
				var ammo_char: String = _char_of(str(e.get("unit", "")))
				_add(st, "res_ammo_requested", float(e.get("requested", 0)))
				_add(st, "res_ammo_effective", float(e.get("effective", 0)))
				_add(st, "res_ammo_wasted", float(e.get("wasted", 0)))
				var ammo_effective: float = float(e.get("effective", 0))
				_add(st, "res_ammo_net_" + ammo_char, ammo_effective)
				var ammo_source: String = str(e.get("source", "unknown"))
				_add(st, "res_ammo_source_" + ammo_source + "_net", ammo_effective)
				if ammo_effective > 0.0:
					_add(st, "res_ammo_gain_gross", ammo_effective)
					_add(st, "res_ammo_gain_gross_" + ammo_char, ammo_effective)
					_add(st, "res_ammo_source_" + ammo_source + "_gain", ammo_effective)
				elif ammo_effective < 0.0:
					_add(st, "res_ammo_spend_gross", -ammo_effective)
					_add(st, "res_ammo_spend_gross_" + ammo_char, -ammo_effective)
					_add(st, "res_ammo_source_" + ammo_source + "_spend", -ammo_effective)
			"reserve":
				var reserve_delta: float = float(e.get("delta", 0))
				_add(st, "res_reserve_net", reserve_delta)
				_add(st, "res_reserve_wasted", float(e.get("wasted", 0)))
				var reserve_source: String = str(e.get("why", "unknown"))
				_add(st, "res_reserve_source_" + reserve_source + "_net", reserve_delta)
				if reserve_delta > 0.0:
					_add(st, "res_reserve_gain", reserve_delta)
					_add(st, "res_reserve_source_" + reserve_source + "_gain", reserve_delta)
				elif reserve_delta < 0.0:
					_add(st, "res_reserve_spend", -reserve_delta)
					_add(st, "res_reserve_source_" + reserve_source + "_spend", -reserve_delta)
			"ritmo_gain":
				var ardore_gain: float = float(e.get("effective", e.get("amount", 0)))
				var ardore_source: String = str(e.get("src", "unknown"))
				_add(st, "res_ardore_gain", ardore_gain)
				_add(st, "res_ardore_wasted", float(e.get("wasted", 0)))
				_add(st, "res_ardore_source_" + ardore_source + "_gain", ardore_gain)
			"ritmo_loss":
				var ardore_spend: float = float(e.get("effective", e.get("amount", 0)))
				var ardore_why: String = str(e.get("why", "unknown"))
				_add(st, "res_ardore_spend", ardore_spend)
				_add(st, "res_ardore_wasted", float(e.get("wasted", 0)))
				_add(st, "res_ardore_source_" + ardore_why + "_spend", ardore_spend)
			"hype":
				var hype_unit: String = str(e.get("unit", ""))
				var hype_char: String = _char_of(hype_unit)
				var hype_effective: float = float(e.get("effective", e.get("amount", 0)))
				_add(st, "res_hype_requested", float(e.get("requested", e.get("amount", 0))))
				_add(st, "res_hype_effective", hype_effective)
				_add(st, "res_hype_wasted", float(e.get("wasted", 0)))
				_add(st, "res_hype_gain_gross", hype_effective)
				_add(st, "res_hype_gain_gross_" + hype_char, hype_effective)
				_add(st, "res_hype_source_" + str(e.get("why", "unknown")) + "_gain", hype_effective)
			"break":
				_add(st, "break", 1.0)


func _count_reaction_opportunity(state: Dictionary, st: Dictionary, seen: Dictionary, pid: String) -> void:
	var boss: Dictionary = BattleState.boss(state)
	var tele: Dictionary = state.get("telegraph", {})
	var move_id: String = str(tele.get("move", ""))
	var move: Dictionary = BattleContent.BOSS_MOVES.get(move_id, {})
	if move.is_empty() or not BattleResolver.is_heavy_boss_move(move):
		return
	var key: String = "%d|%d|%s|%s" % [int(state.get("phase", 1)), int(state.get("cycle_index", 0)), move_id, str(tele.get("target", ""))]
	if not bool(seen.get(key + "|heavy", false)):
		_add(st, "occasioni_carica", 1.0)
		seen[key + "|heavy"] = true
	if pid == "" or int(boss.get("stun", 0)) > 0 or bool(seen.get(key + "|valid", false)):
		return
	for reaction in BattleResolver.reactions_for(state, pid):
		var rid: String = str(reaction.get("id", ""))
		if str(reaction.get("err", "")) != "" or rid == "soccorso":
			continue
		if rid == "interruzione":
			var already_interrupted: bool = false
			for used in state.get("reactions", []):
				if str(used.get("react", "")) == "interrupt":
					already_interrupted = true
					break
			if already_interrupted:
				continue
		if rid == "schivata" and str(tele.get("target", "")) != pid and str(move.get("target", "")) != "all":
			continue
		_add(st, "occasioni", 1.0)
		seen[key + "|valid"] = true
		return


func _run(boss: String, lvl: int, pv: float, atk: float, minore: bool, seeds: int, greg: String = "") -> Dictionary:
	var st: Dictionary = {}
	for sd in range(1, seeds + 1):
		var b: Dictionary = _setup(boss, lvl, pv, atk, minore, sd, greg)
		var resource_start: Dictionary = ResourceTelemetry.snapshot(b)
		var guard: int = 0
		var minhp: float = 1.0
		var seen_reaction: Dictionary = {}
		st["runs"] = float(st.get("runs", 0.0)) + 1.0
		while str(b["winner"]) == "" and guard < 80:
			guard += 1
			BattleFlow.start_round(b)      # lo stesso giro dei turni della battaglia vera (Fase 0: sta nel motore)
			while true:
				var e: Dictionary = BattleFlow.next(b)
				if bool(e.get("end", false)) or str(b["winner"]) != "":
					break
				if bool(e.get("greg", false)):
					_scan(BattleFlow.boss_action(b, Gregario.ID), st, b)
				elif bool(e["boss"]):
					if not bool(e.get("greg", false)):
						_count_reaction_opportunity(b, st, seen_reaction, "")
					if int(BattleState.boss(b).get("stun", 0)) > 0:
						st["boss_persi"] = float(st.get("boss_persi", 0.0)) + 1.0
					else:
						st["boss_giocati"] = float(st.get("boss_giocati", 0.0)) + 1.0
					_scan(BattleFlow.boss_action(b), st, b)
				else:
					var pid: String = str(e["player"])
					var quick: bool = bool(e.get("quick", false))
					if not quick:
						_count_reaction_opportunity(b, st, seen_reaction, pid)
					var evp: Array = BattleFlow.player_action(b, pid, BattleAI.choose_quick(b, pid) if quick else BattleAI.choose(b, pid), quick)
					_scan(evp, st, b)
					for x in evp:
						if str(x.get("t", "")) == "slancio":
							st["slancio"] = float(st.get("slancio", 0.0)) + 1.0
			_scan(BattleFlow.finish(b), st, b)
			for uid in b["units"]:
				if not Gregario.is_enemy(b, str(uid)):
					minhp = minf(minhp, float(b["units"][uid]["hp"]) / float(maxi(1, int(b["units"][uid]["max_hp"]))))
		st["rounds"] = float(st.get("rounds", 0.0)) + float(guard)
		st["minhp"] = float(st.get("minhp", 0.0)) + minhp
		if str(b["winner"]) == "players":
			_add(st, "wins", 1.0)
		elif str(b["winner"]) == "boss":
			_add(st, "losses", 1.0)
		else:
			_add(st, "timeouts", 1.0)
		for uid in b["units"]:
			if not Gregario.is_enemy(b, str(uid)) and int(b["units"][uid]["hp"]) <= 0:
				st["ko"] = float(st.get("ko", 0.0)) + 1.0
		var resource_end: Dictionary = ResourceTelemetry.snapshot(b)
		for uid in resource_start:
			var start_unit: Dictionary = resource_start[uid]
			var end_unit: Dictionary = resource_end.get(uid, {})
			if end_unit.is_empty():
				continue
			var char_id: String = str(start_unit.get("char", ""))
			for resource in ["energy", "gauge", "hype", "ammo"]:
				_add(st, "res_" + resource + "_start", float(start_unit.get(resource, 0)))
				_add(st, "res_" + resource + "_final", float(end_unit.get(resource, 0)))
				_add(st, "res_" + resource + "_final_" + char_id, float(end_unit.get(resource, 0)))
	return st


func _init() -> void:
	var seeds: int = 40
	var minori: bool = false
	var solo: String = ""
	var dettaglio: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("semi="):
			seeds = int(a.substr(5))
		elif a.begins_with("replica="):
			replica = int(a.substr(8))
		elif a.begins_with("ng="):
			ng = int(a.substr(3))
			replica = ng
		elif a.begins_with("scarto="):
			scarto = int(a.substr(7))
		elif a == "kit":
			use_kit = true
		elif a == "dettaglio":
			dettaglio = true
		elif a == "minori":
			minori = true
		elif a.begins_with("solo="):
			solo = a.substr(5)
		elif a == "giro":
			BattleFlow.timeline = false
		elif a == "nostab":
			Stability.enabled = false     # Fase 3 spenta: BREAK del 0.54 (per il confronto prima/dopo)
		elif a == "vel":
			_vel_table()
			quit()
			return
	print("%-18s %3s %5s %5s %5s %6s %6s %5s %5s %6s %6s %6s %5s %6s %5s" % ["scontro", "liv", "vitt%", "KO", "round", "bossG", "bossP", "ross", "slan", "Saul%", "Nox%", "NoxCP", "vegl", "occas", "reaz"])
	var tot: Dictionary = {}
	var n_boss: int = 0
	for enc in ENC:
		if bool(enc[4]) and not minori and solo == "":
			continue
		if solo != "" and str(enc[0]) != solo:
			continue
		var greg: String = str(enc[5]) if enc.size() > 5 else ""
		var st: Dictionary = _run(str(enc[0]), int(enc[1]), float(enc[2]), float(enc[3]), bool(enc[4]), seeds, greg)
		var r: float = float(st["runs"])
		var tot_dmg: float = maxf(1.0, float(st.get("dmg_tot", 0.0)))
		var label: String = str(enc[0]) if greg == "" else "%s+%s" % [str(enc[0]).trim_prefix("frammento_"), str(greg).trim_prefix("frammento_")]
		print("%-18s %3d %5.0f %5.2f %5.1f %6.2f %6.2f %5.2f %5.2f %6.0f %6.0f %6.2f %5.2f %6.2f %5.2f" % [
			label, BattleTypes.replica_level(int(enc[1]), ng) if ng >= 0 else int(enc[1]), 100.0 * float(st.get("wins", 0.0)) / r, float(st.get("ko", 0.0)) / r, float(st.get("rounds", 0.0)) / r,
			float(st.get("boss_giocati", 0.0)) / r, float(st.get("boss_persi", 0.0)) / r, float(st.get("break", 0.0)) / r, float(st.get("slancio", 0.0)) / r,
			100.0 * float(st.get("dmg_saul", 0.0)) / tot_dmg, 100.0 * float(st.get("dmg_nox", 0.0)) / tot_dmg,
			float(st.get("heal_nox", 0.0)) / r, float(st.get("veglia", 0.0)) / r,
			float(st.get("occasioni", 0.0)) / r, float(st.get("react", 0.0)) / r])
		print("     ESITO · vittorie %d | sconfitte %d | timeout %d" % [int(st.get("wins", 0.0)), int(st.get("losses", 0.0)), int(st.get("timeouts", 0.0))])
		print("     DANNI · boss PV %.0f | assorbiti %.0f | pressione %.0f | Eco PV %.0f | indiretti %.0f | Scheggia PV %.0f | riflessi %.0f" % [
			float(st.get("dmg_boss_direct_hp", 0.0)), float(st.get("dmg_boss_absorbed", 0.0)), float(st.get("dmg_boss_pressure", 0.0)),
			float(st.get("dmg_arena_boss_hp", 0.0)), float(st.get("dmg_boss_indirect_hp", 0.0)) + float(st.get("dmg_indirect_enemy_hp", 0.0)), float(st.get("dmg_gregario_hp", 0.0)) + float(st.get("dmg_gregario_indirect_hp", 0.0)), float(st.get("dmg_reflected_boss", 0.0))])
		print("     PLACCHE · danno assorbito dalle placche %.0f" % float(st.get("dmg_boss_plate", 0.0)))
		var shield_expired: float = maxf(0.0, float(st.get("shield_expired_party_raw", 0.0)) - float(st.get("shield_carried_party", 0.0)))
		print("     SOSTEGNO · cure PV %.0f (%d eventi) | soccorsi %d / PV %.0f | scudi creati %.0f | assorbiti %.0f | scaduti %.0f | danni squadra PV %.0f" % [
			float(st.get("heal_total_hp", 0.0)), int(st.get("heal_events", 0.0)), int(st.get("rescue_count", 0.0)), float(st.get("rescue_hp", 0.0)),
			float(st.get("shield_created_party", 0.0)), float(st.get("dmg_party_absorbed", 0.0)), shield_expired,
			float(st.get("dmg_party_hp", 0.0)) + float(st.get("dmg_party_bleed_hp", 0.0)) + float(st.get("dmg_party_arena_hp", 0.0))])
		print("     REAZIONI · cariche pesanti %d | occasioni valide %d | usate %d | schivate %d | intercettazioni %d | interruzioni %d | soccorsi %d | timeout %d" % [
			int(st.get("occasioni_carica", 0.0)), int(st.get("occasioni", 0.0)), int(st.get("react", 0.0)) + int(st.get("rescue_count", 0.0)),
			int(st.get("react_dodge", 0.0)), int(st.get("react_intercept", 0.0)), int(st.get("react_interrupt", 0.0)), int(st.get("rescue_count", 0.0)), int(st.get("timeouts", 0.0))])
		print("     RISORSE · EN +%.1f / -%.1f | netto %+.1f | spreco %.1f | saldo iniziale/finale %.1f / %.1f" % [
			float(st.get("res_energy_gain_gross", 0.0)) / r, float(st.get("res_energy_spend_gross", 0.0)) / r, float(st.get("res_energy_net", 0.0)) / r,
			float(st.get("res_energy_wasted", 0.0)) / r, float(st.get("res_energy_start", 0.0)) / r, float(st.get("res_energy_final", 0.0)) / r])
		print("                GAUGE +%.1f / -%.1f | netto %+.1f | spreco %.1f | saldo iniziale/finale %.1f / %.1f" % [
			float(st.get("res_gauge_gain_gross", 0.0)) / r, float(st.get("res_gauge_spend_gross", 0.0)) / r, float(st.get("res_gauge_net", 0.0)) / r,
			float(st.get("res_gauge_wasted", 0.0)) / r, float(st.get("res_gauge_start", 0.0)) / r, float(st.get("res_gauge_final", 0.0)) / r])
		print("                HYPE +%.1f / -%.1f | netto %+.1f | spreco %.1f | saldo iniziale/finale %.1f / %.1f" % [
			float(st.get("res_hype_gain_gross", 0.0)) / r, float(st.get("res_hype_spend_gross", 0.0)) / r, float(st.get("res_hype_net", 0.0)) / r,
			float(st.get("res_hype_wasted", 0.0)) / r, float(st.get("res_hype_start", 0.0)) / r, float(st.get("res_hype_final", 0.0)) / r])
		print("                MUNIZIONI +%.1f / -%.1f | netto %+.1f | spreco %.1f | saldo iniziale/finale %.1f / %.1f" % [
			float(st.get("res_ammo_gain_gross", 0.0)) / r, float(st.get("res_ammo_spend_gross", 0.0)) / r,
			float(st.get("res_ammo_net_ferri", 0.0) + st.get("res_ammo_net_nox", 0.0) + st.get("res_ammo_net_zecca", 0.0) + st.get("res_ammo_net_saul", 0.0)) / r,
			float(st.get("res_ammo_wasted", 0.0)) / r, float(st.get("res_ammo_start", 0.0)) / r, float(st.get("res_ammo_final", 0.0)) / r])
		print("                RISERVA +%.1f / -%.1f | spreco %.1f | saldo netto %+.1f" % [
			float(st.get("res_reserve_gain", 0.0)) / r, float(st.get("res_reserve_spend", 0.0)) / r,
			float(st.get("res_reserve_wasted", 0.0)) / r, float(st.get("res_reserve_net", 0.0)) / r])
		print("                ARDORE +%.1f / -%.1f | spreco %.1f" % [
			float(st.get("res_ardore_gain", 0.0)) / r, float(st.get("res_ardore_spend", 0.0)) / r, float(st.get("res_ardore_wasted", 0.0)) / r])
		if dettaglio:
			var parts: String = "     quota danno diretto ai PV del boss:"
			for c in PARTY:
				parts += "  %s %.0f%%" % [c, 100.0 * float(st.get("dmg_" + c, 0.0)) / tot_dmg]
			parts += "   | PV minimo raggiunto (media) %.0f%%" % (100.0 * float(st.get("minhp", 0.0)) / r)
			print(parts)
			var support: String = "     cure PV per fonte:"
			for c in PARTY:
				support += "  %s %.0f" % [c, float(st.get("heal_" + c, 0.0))]
			support += "   | scudi generati per fonte:"
			for c in PARTY:
				support += "  %s %.0f" % [c, float(st.get("shield_" + c, 0.0))]
			print(support)
			var resources: String = "     EN per personaggio (guadagno/spesa lordi):"
			for c in PARTY:
				resources += "  %s +%.0f/−%.0f" % [c, float(st.get("res_energy_gain_gross_" + c, 0.0)), float(st.get("res_energy_spend_gross_" + c, 0.0))]
			print(resources)
			resources = "     GAUGE per personaggio (guadagno/spesa lordi):"
			for c in PARTY:
				resources += "  %s +%.0f/−%.0f" % [c, float(st.get("res_gauge_gain_gross_" + c, 0.0)), float(st.get("res_gauge_spend_gross_" + c, 0.0))]
			print(resources)
			resources = "     HYPE per personaggio (guadagno/consumo):"
			for c in PARTY:
				resources += "  %s +%.0f/−%.0f" % [c, float(st.get("res_hype_gain_gross_" + c, 0.0)), float(st.get("res_hype_spend_gross_" + c, 0.0))]
			print(resources)
			resources = "     MUNIZIONI per personaggio (ricarica/spesa):"
			for c in PARTY:
				resources += "  %s +%.0f/−%.0f" % [c, float(st.get("res_ammo_gain_gross_" + c, 0.0)), float(st.get("res_ammo_spend_gross_" + c, 0.0))]
			print(resources)
			for resource in ["energy", "gauge", "hype", "ammo", "reserve", "ardore"]:
				var source_line: String = "     FONTI " + resource + ":"
				var prefix: String = "res_" + resource + "_source_"
				for metric in st:
					var metric_name: String = str(metric)
					if metric_name.begins_with(prefix):
						source_line += "  %s=%+.0f" % [metric_name.trim_prefix(prefix), float(st[metric])]
				print(source_line)
		if not bool(enc[4]):
			n_boss += 1
			for k in st:
				tot[k] = float(tot.get(k, 0.0)) + float(st[k])
	if n_boss > 0:
		var r2: float = float(tot["runs"])
		var d2: float = maxf(1.0, float(tot.get("dmg_tot", 0.0)))
		print("%-18s %3s %5.0f %5.2f %5.1f %6.2f %6.2f %5.2f %5.2f %6.0f %6.0f %6.2f %5.2f %6.2f %5.2f" % [
			"MEDIA BOSS", "", 100.0 * float(tot.get("wins", 0.0)) / r2, float(tot.get("ko", 0.0)) / r2, float(tot.get("rounds", 0.0)) / r2,
			float(tot.get("boss_giocati", 0.0)) / r2, float(tot.get("boss_persi", 0.0)) / r2, float(tot.get("break", 0.0)) / r2, float(tot.get("slancio", 0.0)) / r2,
			100.0 * float(tot.get("dmg_saul", 0.0)) / d2, 100.0 * float(tot.get("dmg_nox", 0.0)) / d2,
			float(tot.get("heal_nox", 0.0)) / r2, float(tot.get("veglia", 0.0)) / r2,
			float(tot.get("occasioni", 0.0)) / r2, float(tot.get("react", 0.0)) / r2])
	quit()
