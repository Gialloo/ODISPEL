extends SceneTree

# Confronta l'anteprima del colpo del boss (threat_preview) con il colpo reale, su molte partite con scelte miste
# (IA + Guardia a caso), e classifica ogni differenza con una causa nota. Non cambia nessun valore del gioco.
#   godot --headless --path . -s tools/preview_check.gd
# Ogni colpo reale viene spiegato da un modello: anteprima x Guardia(0.5) x Furia(1.25) [colpo di catena: mossa a parte x 0.7].
# "non spiegato" > 0 vuol dire che l'anteprima e le regole reali non sono coerenti.

const BOSSES: Array = ["distributore", "semaforo", "tombino", "cabina", "ascensore", "manichino", "orologio", "specchio"]
const TEAMS: Array = [["dax", "nami", "bruno"], ["dax", "cato", "bruno"], ["nami", "moro", "cato"]]
const TOL: float = 0.025


func _near(real: int, expect: float) -> bool:
	return absf(float(real) - expect) <= maxf(2.0, expect * TOL)


func _initialize() -> void:
	var cnt: Dictionary = {}
	var examples: Dictionary = {}
	var boss_crits: int = 0
	var rounds_n: int = 0
	for boss_id in BOSSES:
		if not BattleContent.BOSS_MOVES.is_empty() and not BattleContent.BOSSES.has(boss_id):
			continue
		for team in TEAMS:
			for seed_value in range(1, 9):
				var entries: Array = []
				for c in team:
					entries.append({"char": c, "level": 8, "rank": 1, "passives": [], "gear": []})
				var st: Dictionary = BattleState.create_solo("T", entries, [], boss_id, seed_value, 0, seed_value % 3)
				var rng: RandomNumberGenerator = RandomNumberGenerator.new()
				rng.seed = seed_value * 7919
				for r in 24:
					if str(st["winner"]) != "":
						break
					rounds_n += 1
					# scelte miste: IA, ma ogni tanto Guardia
					var guards: Dictionary = {}
					for p in st["players"]:
						if p["choice"] == null and BattleState.player_alive(st, p):
							var ch: Dictionary = BattleAI.choose(st, str(p["id"]))
							if rng.randf() < 0.35:
								var g: Dictionary = {"swap": "", "move": BattleTypes.ACTION_GUARD, "target": ""}
								if BattleResolver.validate_choice(st, str(p["id"]), g) == "":
									ch = g
							p["choice"] = ch
							if str(ch["move"]) == BattleTypes.ACTION_GUARD:
								guards[str(BattleState.active_unit(st, str(p["id"]))["id"])] = true
					var pv: Dictionary = BattleResolver.threat_preview(st)
					var tele: Dictionary = (st["telegraph"] as Dictionary).duplicate(true)
					var boss0: Dictionary = (BattleState.boss(st) as Dictionary).duplicate(true)
					var chain_id: String = str(tele.get("chain", ""))
					var chain_prev: int = -1
					if chain_id != "" and BattleContent.BOSS_MOVES.has(chain_id):
						var tp: Dictionary = BattleState.active_unit(st, str(tele.get("target", "")))
						if not tp.is_empty():
							chain_prev = BattleResolver.calc_damage(boss0, tp, float(BattleContent.BOSS_MOVES[chain_id]["mult"]))
					var pre_units: Dictionary = (st["units"] as Dictionary).duplicate(true)
					var boss_boost0: int = int(st.get("boss_boost", 0))
					var evs: Array = BattleResolver.resolve_round(st)
					# ricostruzione dagli eventi: per ogni azione del boss (prima mossa e catena) PV del boss, bonus placca e comportamento
					var boss_hp: float = float(boss0["hp"])
					var boost: bool = false
					var pre_boost: int = int(boss_boost0)
					var groups: Array = []
					var odd: Dictionary = {}
					var chain_ok: bool = false
					for e in evs:
						var tt: String = str(e.get("t", ""))
						if tt == "damage" and str(e.get("dst", "")) == "boss":
							boss_hp -= float(e["amount"])
						elif tt == "heal" and str(e.get("dst", "")) == "boss":
							boss_hp += float(e["amount"])
						elif tt == "plate" and bool(e.get("broke", false)):
							boost = true
						elif tt == "chain" and bool(e.get("ok", false)):
							chain_ok = true
						elif tt == "boss_move":
							groups.append({"chain": chain_ok, "hp": boss_hp, "boost": boost and groups.is_empty() and pre_boost == 0, "behav": 1.0, "hits": []})
						elif tt == "behavior" and not groups.is_empty():
							var bid: String = str(e.get("id", ""))
							if bid == "punisce_cure":
								groups[-1]["behav"] = 1.0 + Arena.RAGE_STEP * float(e.get("n", 0))
							elif bid == "punisce_guardia":
								groups[-1]["behav"] = Arena.GUARD_PUNISH
						elif tt == "damage" and str(e.get("src", "")) == "boss" and not groups.is_empty():
							if bool(e.get("crit", false)):
								boss_crits += 1
							groups[-1]["hits"].append({"dst": str(e["dst"]), "real": int(e["amount"]) + int(e["absorbed"]), "hp": boss_hp})
						elif tt in ["dodge", "tenacity"]:
							odd[str(e.get("unit", ""))] = true
					var was_enraged: bool = float(boss0["hp"]) < float(boss0["max_hp"]) * BattleTypes.ENRAGE_BELOW
					for g in groups:
						for h in g["hits"]:
							var enraged_now: bool = float(h["hp"]) < float(boss0["max_hp"]) * BattleTypes.ENRAGE_BELOW
							var fury: float = BattleTypes.ENRAGE_BONUS if enraged_now and not was_enraged else 1.0
							var uid: String = h["dst"]
							var key: String
							var base: float
							if g["chain"]:
								base = -1.0
								if chain_id != "" and pre_units.has(uid):
									base = float(BattleResolver.calc_damage(boss0, pre_units[uid], float(BattleContent.BOSS_MOVES[chain_id]["mult"]))) * 0.7
							elif pv["dmg"].has(uid):
								base = float(pv["dmg"][uid])
							else:
								base = -1.0
							if odd.has(uid):
								key = "esito speciale (schivata/tenacia)"
							elif base < 0.0:
								key = "bersaglio diverso dall'anteprima (provocazione/intercetta)"
							else:
								var f: float = fury * (1.08 if g["boost"] else 1.0) * float(g["behav"])
								var guard: bool = guards.has(uid)
								var want: float = base * f * (BattleTypes.GUARD_FACTOR if guard else 1.0)
								var label: String = "uguale all'anteprima" if absf(f - 1.0) < 0.001 and not guard else "spiegato da"
								if label != "uguale all'anteprima":
									var parts: Array = []
									if guard:
										parts.append("Guardia")
									if fury > 1.0:
										parts.append("Furia")
									if g["boost"]:
										parts.append("placca rotta")
									if float(g["behav"]) != 1.0:
										parts.append("arena")
									if g["chain"]:
										parts.append("catena")
									label = "spiegato da " + "+".join(PackedStringArray(parts))
								if g["chain"] and label == "uguale all'anteprima":
									label = "spiegato da catena"
								if _near(h["real"], want):
									key = label
								else:
									key = "NON SPIEGATO (catena)" if g["chain"] else "NON SPIEGATO (prima mossa)"
									examples[key] = examples.get(key, []) + ["%s r%d s%d: anteprima %d, reale %d, atteso %.0f (%s)" % [boss_id, r, seed_value, int(base), h["real"], want, label]]
									if (examples[key] as Array).size() <= 3:
										var compact: Array = []
										for e in evs:
											var line: String = str(e.get("t", ""))
											for kk in ["id", "n", "move", "ok", "broke", "amount", "dst", "src"]:
												if e.has(kk):
													line += " %s=%s" % [kk, str(e[kk])]
											compact.append(line)
										print("DBG ", boss_id, " r", r, " hp0=", boss0["hp"], "/", boss0["max_hp"], " phase=", boss0.get("phase", "?"), " choices=", guards.keys(), " tele=", tele)
										print("   ", " | ".join(PackedStringArray(compact)))
							cnt[key] = int(cnt.get(key, 0)) + 1
	print("round simulati: %d" % rounds_n)
	var keys: Array = cnt.keys()
	keys.sort()
	for k in keys:
		print("  %5d  %s" % [cnt[k], k])
	print("critici del boss: %d" % boss_crits)
	for k in examples:
		print(k, " -> ", (examples[k] as Array).slice(0, 5))
	quit()
