extends SceneTree

# Stress test del motore: squadre al massimo (livello 50, rank 5, equip leggendario), 6 giocatori, tutti i boss/difficolta'.
# Misura: danno e cura massimi, eventi per round, stati contemporanei, peso dello stato in rete, tempo per round.
#   godot --headless --path . -s res://tools/stress_battle.gd

func _gear() -> Array:
	var out: Array = []
	for slot in BattleTypes.GEAR_SLOTS:
		out.append({"slot": slot, "rarity": 3, "level": int(BattleContent.GEAR_MAX_LEVEL[3])})
	return out


func _entry(id: String, level: int, rank: int, gear: bool) -> Dictionary:
	var e: Dictionary = BattleContent.default_entry(id, level, rank)
	if gear:
		e["gear"] = _gear()
	return e


func _run_battle(boss: String, tier: int, players: int, level: int, rank: int, gear: bool, seed_value: int, stats: Dictionary) -> void:
	var ids: Array = BattleContent.CHARACTERS.keys()
	var specs: Array = []
	for i in players:
		var team: Array = []
		for k in 3:
			team.append(_entry(str(ids[(i * 3 + k) % ids.size()]), level, rank, gear))
		specs.append({"id": "p%d" % (i + 1), "name": "P%d" % (i + 1), "ai": true, "team": team})
	var state: Dictionary = BattleState.create(specs, boss, seed_value, tier)
	var guard: int = 0
	while str(state["winner"]) == "" and guard < 200:
		var t0: int = Time.get_ticks_usec()
		var events: Array = BattleResolver.resolve_round(state, true)
		var dt: int = Time.get_ticks_usec() - t0
		stats["round_us_max"] = maxi(int(stats["round_us_max"]), dt)
		stats["round_us_sum"] = int(stats["round_us_sum"]) + dt
		stats["rounds"] = int(stats["rounds"]) + 1
		stats["events_max"] = maxi(int(stats["events_max"]), events.size())
		var round_dmg: Dictionary = {}
		for ev in events:
			match str(ev.get("t", "")):
				"damage":
					var a: int = int(ev["amount"]) + int(ev.get("absorbed", 0))
					stats["dmg_max"] = maxi(int(stats["dmg_max"]), a)
					if str(ev["dst"]).begins_with("boss"):
						stats["dmg_vs_boss_max"] = maxi(int(stats["dmg_vs_boss_max"]), a)
					round_dmg[ev["dst"]] = int(round_dmg.get(ev["dst"], 0)) + a
				"heal":
					stats["heal_max"] = maxi(int(stats["heal_max"]), int(ev["amount"]))
				"bleed":
					stats["bleed_max"] = maxi(int(stats["bleed_max"]), int(ev["amount"]))
		for v in round_dmg.values():
			stats["dmg_one_unit_one_round_max"] = maxi(int(stats["dmg_one_unit_one_round_max"]), int(v))
		for u in state["units"].values():
			stats["statuses_max"] = maxi(int(stats["statuses_max"]), (u["statuses"] as Dictionary).size())
			stats["mods_max"] = maxi(int(stats["mods_max"]), (u.get("mods", []) as Array).size())
		var js: int = JSON.stringify(state).length()
		stats["json_max"] = maxi(int(stats["json_max"]), js)
		stats["units_max"] = maxi(int(stats["units_max"]), (state["units"] as Dictionary).size())
		guard += 1
	if str(state["winner"]) == "":
		stats["stalled"] = int(stats["stalled"]) + 1
	stats["battles"] = int(stats["battles"]) + 1


func _init() -> void:
	var stats: Dictionary = {}
	for k in ["round_us_max", "round_us_sum", "rounds", "events_max", "dmg_max", "dmg_vs_boss_max", "heal_max", "bleed_max",
			"dmg_one_unit_one_round_max", "statuses_max", "mods_max", "json_max", "units_max", "stalled", "battles"]:
		stats[k] = 0
	var seed_value: int = 1
	for boss in BattleContent.BOSS_ORDER:
		for tier in BattleContent.TIERS.size():
			for players in [1, 3, 6]:
				for cfg in [[1, 0, false], [50, 5, true]]:
					seed_value += 1
					_run_battle(str(boss), tier, players, int(cfg[0]), int(cfg[1]), bool(cfg[2]), seed_value, stats)
	for k in stats:
		print("STAT %s = %s" % [k, str(stats[k])])
	print("round medio: %d us" % [int(stats["round_us_sum"]) / maxi(1, int(stats["rounds"]))])
	quit()
