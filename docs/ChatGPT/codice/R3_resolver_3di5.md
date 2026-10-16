FILE battle_resolver.gd - PARTE 3 DI 5
Percorso: scripts/battle/battle_resolver.gd
(Codice GDScript, rientri con tab. Non rispondere finche' non scrivo FINE FILE.)

```gdscript
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
```
