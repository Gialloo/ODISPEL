extends SceneTree

# Fase 3: ogni boss ha la sua strada verso il BREAK (BreakRules), la fase 2 non toglie piu' la Riserva, frammenti diversi.
var fails: int = 0


func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _team() -> Array:
	var t: Array = []
	for id in ["ferri", "nox", "zecca", "saul"]:
		t.append(BattleContent.default_entry(id))
	return t


func _fresh(boss_id: String) -> Dictionary:
	var s: Dictionary = BattleState.create_solo("IO", _team(), [], boss_id, 7)
	SeqRound.begin(s)
	return s


func _heavy_move(boss_id: String) -> String:
	for m in BattleContent.BOSSES[boss_id]["cycle"]:
		if BattleResolver.is_heavy_boss_move(BattleContent.BOSS_MOVES[m]):
			return str(m)
	return ""


func _init() -> void:
	var s: Dictionary = _fresh("semaforo")
	var boss: Dictionary = BattleState.boss(s)
	var hero: Dictionary = BattleState.active_unit(s, str(s["players"][0]["id"]))
	s["telegraph"] = {"move": _heavy_move("semaforo"), "target": str(s["players"][1]["id"])}
	check(_heavy_move("semaforo") != "", "il Semaforo ha una carica")
	check(BreakRules.balance_mult(s, boss, hero) == 2.0, "Semaforo: x2 mentre carica")
	s["telegraph"] = {"move": "lampeggio", "target": ""}
	check(BreakRules.balance_mult(s, boss, hero) == 1.0 or BattleResolver.is_heavy_boss_move(BattleContent.BOSS_MOVES["lampeggio"]), "Semaforo: normale senza carica")
	# Cabina: chi e' chiamato toglie il doppio
	s = _fresh("cabina")
	boss = BattleState.boss(s)
	var pid: String = str(s["players"][2]["id"])
	s["telegraph"] = {"move": "squillo", "target": pid}
	check(BreakRules.balance_mult(s, boss, BattleState.active_unit(s, pid)) == 2.0, "Cabina: il chiamato x2")
	check(BreakRules.balance_mult(s, boss, BattleState.active_unit(s, str(s["players"][0]["id"]))) <= 1.5, "Cabina: gli altri no")
	# Cassaforte: con lo scudo meta', senza 1,5
	s = _fresh("cassaforte")
	boss = BattleState.boss(s)
	hero = BattleState.active_unit(s, str(s["players"][0]["id"]))
	s["telegraph"] = {"move": "serratura", "target": ""}
	boss["shield"] = 100
	check(BreakRules.balance_mult(s, boss, hero) == 0.5, "Cassaforte chiusa: x0,5")
	boss["shield"] = 0
	check(BreakRules.balance_mult(s, boss, hero) == 1.5, "Cassaforte aperta: x1,5")
	# Autovelox: la parata perfetta apre, il colpo dopo la consuma
	s = _fresh("autovelox")
	boss = BattleState.boss(s)
	hero = BattleState.active_unit(s, str(s["players"][0]["id"]))
	s["telegraph"] = {"move": "flash", "target": ""}
	BreakRules.on_perfect(s)
	check(BreakRules.balance_mult(s, boss, hero) == 2.0, "Autovelox: dopo la parata x2")
	check(BreakRules.balance_mult(s, boss, hero) == 1.0, "Autovelox: solo il colpo dopo")
	# Manichino: stessa categoria del compagno prima = meta'
	s = _fresh("manichino")
	boss = BattleState.boss(s)
	BreakRules.on_act(s, hero, "attacco")
	BreakRules.on_act(s, hero, "attacco")
	check(float(boss["mirror_mult"]) == 0.5, "Manichino: copiato x0,5")
	BreakRules.on_act(s, hero, "abilita")
	check(float(boss["mirror_mult"]) == 1.5, "Manichino: cambiato x1,5")
	# Distributore: nessuna regola (tutorial)
	check(BreakRules.of(BattleState.boss(_fresh("distributore"))).is_empty(), "Distributore senza regola")
	# Fase 2: niente Riserva divorata, carica x1,5 per tutti
	s = _fresh("distributore")
	boss = BattleState.boss(s)
	s["reserve"] = 3
	boss["hp"] = int(boss["max_hp"] * 0.4)
	var ev: Array = []
	BattleResolver._check_phase(s, ev)
	check(int(s["phase"]) == 2 and int(s["reserve"]) == 3, "fase 2: la Riserva resta")
	s["telegraph"] = {"move": _heavy_move("distributore"), "target": ""}
	check(BreakRules.balance_mult(s, boss, BattleState.active_unit(s, str(s["players"][0]["id"]))) == 1.5, "fase 2: carica x1,5")
	# Frammenti: corazza e radici
	s = _fresh("frammento_rosso")
	boss = BattleState.boss(s)
	var dummy_blu: Dictionary = {"color": "blu"}
	var dummy_giallo: Dictionary = {"color": "giallo"}
	check(BreakRules.dmg_mult(boss, dummy_blu) == 1.0 and BreakRules.dmg_mult(boss, dummy_giallo) == 0.5, "Corazza: pieno solo col colore vincente")
	s = _fresh("frammento_verde")
	boss = BattleState.boss(s)
	boss["hp"] = int(boss["max_hp"]) / 2
	var hp0: int = int(boss["hp"])
	ev = []
	BreakRules.round_end(s, ev)
	check(int(boss["hp"]) > hp0, "Radici: ricresce")
	boss["stun"] = 1
	hp0 = int(boss["hp"])
	BreakRules.round_end(s, ev)
	check(int(boss["hp"]) == hp0, "Radici: rotto non ricresce")
	_fase_saltate()
	_fase3()
	_fase3_scontro()
	if fails == 0:
		print("OK test_v3_break")
	quit(1 if fails > 0 else 0)


# ---------- FASE 3 DEL COMBATTIMENTO (04/11/2026): stabilita', finestra, recupero, pressione latente, tipologie ----------

func _broken(boss_id: String) -> Dictionary:
	var s: Dictionary = _fresh(boss_id)
	Stability.mark(s)
	return s


func _has(ev: Array, t: String) -> bool:
	for e in ev:
		if str(e.get("t", "")) == t:
			return true
	return false


func _fase_saltate() -> void:
	var s: Dictionary = _fresh("distributore")
	var boss: Dictionary = BattleState.boss(s)
	var old_balance_max: int = int(boss["balance_max"])
	var old_shield: int = int(boss["shield"])
	var alive: Array = BattleState.alive_players(s)
	var energy_before: Dictionary = {}
	for p in alive:
		var u: Dictionary = BattleState.active_unit(s, str(p["id"]))
		energy_before[str(u["id"])] = int(u["energy"])
		# Evita che il limite della barra nasconda il secondo premio di fase.
		u["gauge"] = 0
	boss["hp"] = int(ceil(float(boss["max_hp"]) * 0.20))
	var events: Array = []
	BattleResolver._check_phase(s, events)
	var phase_events: Array = []
	var shield_events: int = 0
	for e in events:
		if str(e.get("t", "")) == "phase":
			phase_events.append(int(e.get("phase", 0)))
		elif str(e.get("t", "")) == "shield" and str(e.get("dst", "")) == BattleState.BOSS_ID:
			shield_events += 1
	check(int(s["phase"]) == 3, "salto soglie: il boss raggiunge la fase 3")
	check(phase_events == [2, 3], "salto soglie: vengono registrate entrambe le transizioni in ordine")
	check(int(boss["balance_max"]) == old_balance_max + BattleTypes.BREAK_PER_PHASE * 2, "salto soglie: la barra BREAK cresce per entrambe le fasi")
	var expected_shield: int = int(round(float(boss["max_hp"]) * BattleTypes.PHASE_SHIELD)) * 2
	check(shield_events == 2 and int(boss["shield"]) == old_shield + expected_shield, "salto soglie: entrambi gli scudi di fase vengono applicati")
	for p in alive:
		var u: Dictionary = BattleState.active_unit(s, str(p["id"]))
		check(int(u["gauge"]) == mini(BattleTypes.GAUGE_MAX, BattleTypes.PHASE_GAUGE * 2), "salto soglie: premio Ultimate per ogni fase")
		check(int(u["energy"]) == maxi(0, int(energy_before[str(u["id"])]) - 2), "salto soglie: costo EN per ogni fase")


func _fase3() -> void:
	var s: Dictionary = _broken("semaforo")
	var boss: Dictionary = BattleState.boss(s)
	var hero: Dictionary = BattleState.active_unit(s, str(s["players"][0]["id"]))
	check(Stability.on(boss), "fase 3: il nemico di BattleFlow ha la stabilita'")
	var enabled_before: bool = Stability.enabled
	Stability.enabled = false
	check(not Stability.on(boss), "selettore runtime disattiva davvero la stabilita' su uno stato gia' marcato")
	Stability.enabled = enabled_before
	check(Stability.on(boss), "riattivando il selettore runtime la stabilita' torna attiva")
	check(Stability.category(boss) == "boss" and Stability.category(BattleState.boss(_fresh("frammento_rosso"))) == "comune", "categorie: boss e frammento comune")
	var mx: int = int(boss["balance_max"])
	var ev: Array = []
	Stability.drain(boss, mx, hero, ev)
	check(bool(boss["exposed"]) and int(boss["stun"]) == 1 and int(boss["brk_left"]) == 3, "boss rotto: vulnerabile, perde l'azione, finestra di 3")
	var be: Dictionary = {}
	for e in ev:
		if str(e["t"]) == "break":
			be = e
	check(str(be.get("cat", "")) == "boss" and int(be.get("window", 0)) == 3, "evento break con categoria e finestra")
	# anti-catena e pressione latente con limite
	ev = []
	Stability.drain(boss, 4, hero, ev)
	check(int(boss["balance"]) == 0 and int(boss["latent"]) == 4 and _has(ev, "latent") and not _has(ev, "break"), "durante il BREAK la pressione diventa latente, niente nuovo BREAK")
	Stability.drain(boss, 999, hero, ev)
	check(int(boss["latent"]) == Stability.latent_cap(boss), "latente fino al limite")
	# la finestra: l'azione che rompe non conta
	Stability.on_ally_action(s, [{"t": "break"}])
	check(int(boss["brk_left"]) == 3, "l'azione che rompe non consuma la finestra")
	Stability.on_ally_action(s, [{"t": "duo_rest"}])
	check(int(boss["brk_left"]) == 3, "il turno dato alla tecnica a due non consuma la finestra")
	check(Stability.round_end(s, []) and bool(boss["exposed"]), "a fine round il BREAK non finisce piu'")
	Stability.on_ally_action(s, [])
	Stability.on_ally_action(s, [])
	check(int(boss["brk_left"]) == 1 and bool(boss["exposed"]), "due azioni alleate: resta 1")
	ev = []
	Stability.on_ally_action(s, ev)
	check(not bool(boss["exposed"]) and Stability.recovering(boss) and int(boss["balance"]) == 0 and _has(ev, "break_end"), "terza azione: fine del BREAK, recupero da 0")
	var lat: int = int(boss["latent"])
	ev = []
	Stability.drain(boss, 50, hero, ev)
	check(not _has(ev, "break") and int(boss["latent"]) == lat, "in recupero non si rompe (latente gia' al limite)")
	# recupero: 33,3% a ogni azione del boss, tre azioni = piena
	boss["stun"] = 0
	Stability.on_enemy_action(s, [])
	check(int(boss["balance"]) == int(ceil(float(mx) * 0.334 - 0.0001)) and Stability.recovering(boss), "prima azione del boss: un terzo")
	Stability.on_enemy_action(s, [])
	ev = []
	Stability.on_enemy_action(s, ev)
	check(not Stability.recovering(boss) and int(boss["balance"]) == maxi(1, mx - lat) and int(boss["latent"]) == 0 and _has(ev, "stab_full"), "tre azioni: piena, meno la pressione latente")
	ev = []
	Stability.drain(boss, int(boss["balance"]), hero, ev)
	check(_has(ev, "break"), "dopo il ripristino si puo' rompere di nuovo")
	# latente che arriverebbe a zero: niente BREAK automatico, la prossima pressione lo fa
	s = _broken("cabina")
	boss = BattleState.boss(s)
	boss["stab_rec"] = true
	boss["balance"] = 0
	boss["latent"] = int(boss["balance_max"]) + 5
	ev = []
	Stability.on_phase(boss, ev)
	check(int(boss["balance"]) == 1 and not bool(boss["exposed"]) and not _has(ev, "break"), "soglia raggiunta in recupero: il BREAK non scatta da solo (e la fase completa il recupero)")
	Stability.drain(boss, 1, hero, ev)
	check(bool(boss["exposed"]), "la prossima pressione provoca il collasso")
	# limite che scende: l'eccedenza resta
	boss["latent"] = Stability.latent_cap(boss) + 3
	var before: int = int(boss["latent"])
	Stability.drain(boss, 2, hero, [])
	check(int(boss["latent"]) == before, "limite sceso: l'eccedenza non si cancella e non cresce")
	# comune: perde l'azione, recupero rapido
	s = _broken("frammento_rosso")
	boss = BattleState.boss(s)
	Stability.drain(boss, int(boss["balance_max"]), hero, [])
	check(int(boss["stun"]) == 1 and int(boss["brk_left"]) == int(BattleTypes.STAB_WINDOW["comune"]), "comune: perde la prossima azione")
	for i in int(BattleTypes.STAB_WINDOW["comune"]):
		Stability.on_ally_action(s, [])
	check(not bool(boss["exposed"]) and not Stability.recovering(boss) and int(boss["balance"]) == int(boss["balance_max"]), "comune: recupero rapido, subito pieno")
	# elite: niente azione persa, ritardata e indebolita
	s = _broken("semaforo")
	boss = BattleState.boss(s)
	boss["elite"] = true
	Stability.drain(boss, int(boss["balance_max"]), hero, [])
	check(int(boss["stun"]) == 0 and bool(boss["brk_weak"]) and bool(boss["brk_delay"]), "elite: ritardo e indebolimento invece dell'azione persa")
	check(absf(Stability.damage_mult(boss, hero) - BattleTypes.STAB_ELITE_WEAK) < 0.001, "elite: il prossimo colpo e' indebolito")
	Stability.on_enemy_action(s, [])
	check(not boss.has("brk_weak"), "elite: indebolito solo per un'azione")
	# SBILANCIAMENTO
	s = _broken("semaforo")
	boss = BattleState.boss(s)
	ev = []
	Stability.unbalance(boss, hero, ev)
	check(int(boss["sbil"]) == 2 and _has(ev, "sbil"), "Interruzione: boss sbilanciato per 2 colpi")
	check(absf(Stability.damage_mult(hero, boss) - BattleTypes.SBIL_DMG) < 0.001, "sbilanciato: +10% danno")
	var p1: float = Stability.pressure_mult(boss)
	var p2: float = Stability.pressure_mult(boss)
	check(absf(p1 - 1.2) < 0.001 and absf(p2 - 1.2) < 0.001 and Stability.pressure_mult(boss) == 1.0, "sbilanciato: +20% pressione per due colpi, poi basta")
	# fuori da BattleFlow: BREAK del 0.54 (motore classico, PvP)
	s = _fresh("semaforo")
	boss = BattleState.boss(s)
	BattleResolver._drain_balance(boss, int(boss["balance_max"]), hero, [])
	BattleResolver._drain_balance(boss, 3, hero, [])
	check(not Stability.on(boss) and bool(boss["exposed"]) and not boss.has("latent"), "senza BattleFlow il BREAK resta quello di prima")


# Scontro vero con la Timeline: la finestra conta solo i turni ordinari degli eroi (non SLANCIO, non il boss).
func _fase3_scontro() -> void:
	BattleFlow.timeline = true
	var opened: int = 0
	var bad: int = 0
	for sd in range(1, 9):
		var s: Dictionary = BattleState.create_solo("IO", _team(), [], "semaforo", sd)
		var rounds: int = 0
		while str(s["winner"]) == "" and rounds < 30:
			rounds += 1
			BattleFlow.start_round(s)
			var guard: int = 0
			while guard < 60 and str(s["winner"]) == "":
				guard += 1
				var e: Dictionary = BattleFlow.next(s)
				if bool(e.get("end", false)):
					break
				var boss: Dictionary = BattleState.boss(s)
				var left0: int = int(boss.get("brk_left", 0))
				var open0: bool = bool(boss.get("exposed", false))
				var ev: Array
				if bool(e.get("greg", false)):
					ev = BattleFlow.boss_action(s, Gregario.ID)
				elif bool(e["boss"]):
					ev = BattleFlow.boss_action(s)
				else:
					var pid: String = str(e["player"])
					var q: bool = bool(e.get("quick", false))
					ev = BattleFlow.player_action(s, pid, BattleAI.choose_quick(s, pid) if q else BattleAI.choose(s, pid), q)
					if open0 and not q and not _has(ev, "duo_rest") and str(s["winner"]) == "":
						if int(boss.get("brk_left", 0)) != left0 - 1:
							bad += 1
					if open0 and q and int(boss.get("brk_left", 0)) != left0:
						bad += 1
				if bool(e["boss"]) and open0 and int(boss.get("brk_left", 0)) != left0:
					bad += 1
				if _has(ev, "break"):
					opened += 1
			BattleFlow.finish(s)
	check(opened > 0, "negli scontri veri il BREAK si apre (%d)" % opened)
	check(bad == 0, "finestra: un turno ordinario la consuma, SLANCIO e boss no (%d errori)" % bad)
