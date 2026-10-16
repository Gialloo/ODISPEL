extends SceneTree

# Misura quanto l'anteprima del colpo del boss (threat_preview) si discosta dal colpo reale. Uso:
#   godot --headless --path . -s tools/preview_check.gd
func _initialize() -> void:
	var teams: Array = [["dax", "nami", "bruno"], ["dax", "cato", "bruno"], ["nami", "moro", "cato"]]
	var bosses: Array = ["distributore", "semaforo", "tombino"]
	var total: int = 0
	var exact: int = 0
	var lower: int = 0
	var higher: int = 0
	var causes: Dictionary = {}
	var worst_hi: float = 1.0
	var worst_lo: float = 1.0
	for boss in bosses:
		for team in teams:
			for seed_value in range(1, 21):
				var entries: Array = []
				for c in team:
					entries.append({"char": c, "level": 5, "rank": 0, "passives": [], "gear": []})
				var st: Dictionary = BattleState.create_solo("T", entries, [], boss, seed_value, 0, 0)
				for r in 12:
					if str(st["winner"]) != "":
						break
					var pv: Dictionary = BattleResolver.threat_preview(st)
					var snap_boss: Dictionary = (BattleState.boss(st) as Dictionary).duplicate(true)
					var snap_units: Dictionary = (st["units"] as Dictionary).duplicate(true)
					var dmg: Dictionary = pv["dmg"]
					var evs: Array = BattleResolver.autoplay_round(st)
					var real: Dictionary = {}
					var odd: Dictionary = {}
					var flags: Dictionary = {}
					for e in evs:
						var tt: String = str(e.get("t", ""))
						if tt == "damage" and str(e.get("src", "")) == "boss" and bool(e.get("crit", false)):
							flags["crit"] = true
						elif tt in ["behavior", "chain", "plate", "tactic"]:
							flags[tt] = true
					for e in evs:
						if str(e.get("t", "")) == "damage" and str(e.get("src", "")) == "boss":
							real[str(e["dst"])] = int(real.get(str(e["dst"]), 0)) + int(e["amount"]) + int(e["absorbed"])
						elif str(e.get("t", "")) in ["dodge", "tenacity"]:
							odd[str(e.get("unit", ""))] = true
					for uid in dmg:
						if not real.has(uid) or odd.has(uid):
							continue
						total += 1
						var ratio: float = float(real[uid]) / float(maxi(1, int(dmg[uid])))
						if real[uid] == dmg[uid]:
							exact += 1
						elif real[uid] > dmg[uid]:
							higher += 1
							if int(causes.get("_n", 0)) < 8:
								causes["_n"] = int(causes.get("_n", 0)) + 1
								var b2: Dictionary = BattleState.boss(st)
								var u0: Dictionary = snap_units[uid]
								var u1: Dictionary = st["units"][uid]
								print("DBG x%.2f boss atk %d->%d hp %d->%d | dif def %d->%d st %s->%s | move %s" % [ratio, int(snap_boss["atk"]), int(b2["atk"]), int(snap_boss["hp"]), int(b2["hp"]), int(u0["def"]), int(u1["def"]), str(u0["statuses"].keys()), str(u1["statuses"].keys()), str(st.get("telegraph", {}))])
							var key: String = ",".join(PackedStringArray(flags.keys())) if not flags.is_empty() else "nessuno"
							causes[key] = int(causes.get(key, 0)) + 1
							worst_hi = maxf(worst_hi, ratio)
						else:
							lower += 1
							worst_lo = minf(worst_lo, ratio)
	print("confronti=%d  uguali=%d  reale>anteprima=%d (max x%.2f)  reale<anteprima=%d (min x%.2f)" % [total, exact, higher, worst_hi, lower, worst_lo])
	print("cause quando il reale e' maggiore: ", causes)
	quit()
