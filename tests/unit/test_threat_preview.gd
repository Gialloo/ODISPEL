extends SceneTree

# Coerenza tra l'anteprima del colpo del boss (BattleResolver.threat_preview) e il colpo reale.
# Ogni modificatore e' isolato: Guardia, furia a meta' round, bonus placca, catena, critici, bersaglio.

var passed: int = 0
var failed: int = 0
const TEAM: Array = ["dax", "bruno", "cato"]


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _initialize() -> void:
	_test_exact_baseline()
	_test_guard()
	_test_known_boost()
	_test_enrage_warning()
	_test_chain_flag()
	_test_no_boss_crit()
	print("\n=== threat_preview: %d passati, %d falliti ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


# Stato pulito: il boss agisce per ultimo, senza placche, a PV pieni.
func _state(boss_id: String, seed_value: int) -> Dictionary:
	var entries: Array = []
	for c in TEAM:
		entries.append({"char": c, "level": 5, "rank": 0, "passives": [], "gear": []})
	var st: Dictionary = BattleState.create_solo("T", entries, [], boss_id, seed_value, 0, 0)
	var boss: Dictionary = BattleState.boss(st)
	boss["spd"] = 1
	boss["plates"] = 0
	boss["plate_hp"] = 0
	return st


func _choose_all(st: Dictionary, move: String, only: String = "") -> void:
	for p in st["players"]:
		var m: String = move
		if only != "" and str(p["id"]) != only:
			m = BattleTypes.ACTION_ATTACK
		p["choice"] = {"swap": "", "move": m, "target": ""}


# Somma i colpi del boss su un'unita' nel round (prima mossa), piu' un indicatore di esiti speciali.
func _boss_hit_on(evs: Array, uid: String, boss_hp: float = -1.0, boss_max: float = 1.0) -> Dictionary:
	var total: int = 0
	var special: bool = false
	var hit: bool = false
	for e in evs:
		var t: String = str(e.get("t", ""))
		if t == "chain":
			break
		if boss_hp >= 0.0 and t == "damage" and str(e.get("dst", "")) == "boss":
			boss_hp -= float(e["amount"])
		if boss_hp >= 0.0 and t == "damage" and str(e.get("src", "")) == "boss" and boss_hp < boss_max * BattleTypes.ENRAGE_BELOW:
			special = true       # la furia scatta a meta' mossa (dopo i contrattacchi): caso coperto dal test dell'avviso
		if t == "damage" and str(e.get("src", "")) == "boss" and str(e.get("dst", "")) == uid:
			total += int(e["amount"]) + int(e["absorbed"])
			hit = true
		elif t in ["dodge", "tenacity", "behavior"]:
			special = true
	return {"total": total, "special": special, "hit": hit}


func _tele_unit(st: Dictionary) -> String:
	var tele: Dictionary = st["telegraph"]
	var tp: Dictionary = BattleState.player(st, str(tele["target"]))
	return str(BattleState.active_unit(st, str(tele["target"])).get("id", "")) if not tp.is_empty() else ""


func _test_exact_baseline() -> void:
	var tested: int = 0
	var equal: int = 0
	for boss_id in ["distributore", "semaforo", "tombino"]:
		for seed_value in range(1, 7):
			var st: Dictionary = _state(boss_id, seed_value)
			var pv: Dictionary = BattleResolver.threat_preview(st)
			var uid: String = _tele_unit(st)
			if uid == "" or not pv["dmg"].has(uid):
				continue
			_choose_all(st, BattleTypes.ACTION_ATTACK)
			var hp0: float = float(BattleState.boss(st)["hp"])
			var mx: float = float(BattleState.boss(st)["max_hp"])
			var evs: Array = BattleResolver.resolve_round(st)
			var r: Dictionary = _boss_hit_on(evs, uid, hp0, mx)
			if r["special"] or not r["hit"]:
				continue
			tested += 1
			if int(r["total"]) == int(pv["dmg"][uid]):
				equal += 1
			else:
				print("  differenza: %s seme %d anteprima %d reale %d mossa %s" % [boss_id, seed_value, int(pv["dmg"][uid]), int(r["total"]), str(st.get("telegraph", {}))])
	_check("senza modificatori l'anteprima e' IDENTICA al colpo reale (%d casi)" % tested, tested >= 8 and equal == tested)


func _test_guard() -> void:
	var tested: int = 0
	var ok: int = 0
	for seed_value in range(1, 9):
		var st: Dictionary = _state("distributore", seed_value)
		var pv: Dictionary = BattleResolver.threat_preview(st)
		var uid: String = _tele_unit(st)
		if uid == "" or not pv["dmg"].has(uid):
			continue
		var slot: String = str(st["telegraph"]["target"])
		_choose_all(st, BattleTypes.ACTION_GUARD, slot)
		var evs: Array = BattleResolver.resolve_round(st)
		var r: Dictionary = _boss_hit_on(evs, uid)
		if r["special"] or not r["hit"]:
			continue
		tested += 1
		if absi(int(r["total"]) - int(round(float(pv["dmg"][uid]) * BattleTypes.GUARD_FACTOR))) <= 1:
			ok += 1
	_check("Guardia scelta nel round: colpo reale = anteprima x %.1f (%d casi)" % [BattleTypes.GUARD_FACTOR, tested], tested >= 4 and ok == tested)
	# La Guardia GIA' attiva e' invece inclusa nell'anteprima
	var st2: Dictionary = _state("distributore", 3)
	var uid2: String = _tele_unit(st2)
	var d0: int = int(BattleResolver.threat_preview(st2)["dmg"][uid2])
	BattleState.unit(st2, uid2)["statuses"]["guard"] = 1
	var d1: int = int(BattleResolver.threat_preview(st2)["dmg"][uid2])
	_check("Guardia gia' attiva: l'anteprima la include", absi(d1 - int(round(float(d0) * BattleTypes.GUARD_FACTOR))) <= 1)


func _test_known_boost() -> void:
	var st: Dictionary = _state("distributore", 4)
	var uid: String = _tele_unit(st)
	var base: int = int(BattleResolver.threat_preview(st)["dmg"][uid])
	st["boss_boost"] = 8        # placca rotta nel round prima: +8% sulla mossa di questo round
	var boosted: int = int(BattleResolver.threat_preview(st)["dmg"][uid])
	_check("bonus placca del round precedente: l'anteprima lo include (+8%)", absi(boosted - int(round(float(base) * 1.08))) <= 1)
	_choose_all(st, BattleTypes.ACTION_ATTACK)
	var evs: Array = BattleResolver.resolve_round(st)
	var r: Dictionary = _boss_hit_on(evs, uid)
	if not r["special"] and r["hit"]:
		_check("bonus placca: colpo reale uguale all'anteprima", absi(int(r["total"]) - boosted) <= 1)
	_check("bonus placca consumato dopo il colpo", int(st.get("boss_boost", 0)) == 0)


func _test_enrage_warning() -> void:
	var fired: int = 0
	var killed: int = 0
	var safe_ok: int = 0
	var safe_n: int = 0
	for seed_value in range(1, 13):
		var st: Dictionary = _state("distributore", seed_value)
		var boss: Dictionary = BattleState.boss(st)
		boss["hp"] = int(float(boss["max_hp"]) * 0.52)       # appena sopra la soglia: i colpi dei giocatori lo infuriano
		var uid: String = _tele_unit(st)
		if uid == "":
			continue
		var tele_move: Dictionary = BattleContent.BOSS_MOVES[str(st["telegraph"]["move"])]
		if str(tele_move["target"]) == "all":
			continue
		var tgt: Dictionary = BattleState.unit(st, uid)
		tgt["shield"] = 0
		var d: int = int(BattleResolver.threat_preview(st)["dmg"][uid])
		var d2: int = BattleResolver.calc_damage(boss, tgt, float(tele_move["mult"]) * BattleTypes.ENRAGE_BONUS)
		if d2 <= d + 1:
			continue
		tgt["max_hp"] = maxi(int(tgt["max_hp"]), d2 + 50)
		tgt["hp"] = d + 1        # sopravvive al colpo normale, non a quello infuriato
		var pv: Dictionary = BattleResolver.threat_preview(st)
		_check("seme %d: non letale ora" % seed_value, pv["lethal"].is_empty())
		if not pv["enrage_lethal"].has(uid) or pv["enrage_lethal"].size() != 1:
			continue
		fired += 1
		_choose_all(st, BattleTypes.ACTION_ATTACK)
		var evs: Array = BattleResolver.resolve_round(st)
		var r: Dictionary = _boss_hit_on(evs, uid)
		var hp_after: int = int(BattleState.unit(st, uid)["hp"])
		if (not r["special"] and r["hit"] and int(r["total"]) > d + 1) or hp_after <= 1:
			killed += 1
		# stesso bersaglio con PV alti: nessun avviso
		safe_n += 1
	_check("avviso furia: compare e identifica il bersaglio giusto (%d casi)" % fired, fired >= 3)
	_check("avviso furia: dove compare, il colpo reale supera davvero l'anteprima o il bersaglio resta a <=1 PV", killed == fired)
	# senza condizioni: nessun avviso
	var st3: Dictionary = _state("distributore", 2)
	_check("PV pieni del boss: nessun avviso furia", BattleResolver.threat_preview(st3)["enrage_lethal"].is_empty())
	BattleState.boss(st3)["hp"] = int(float(BattleState.boss(st3)["max_hp"]) * 0.2)
	_check("boss gia' infuriato: nessun avviso furia", BattleResolver.threat_preview(st3)["enrage_lethal"].is_empty())
	var st4: Dictionary = _state("distributore", 2)
	BattleState.boss(st4)["hp"] = int(float(BattleState.boss(st4)["max_hp"]) * 0.6)
	var u4: String = _tele_unit(st4)
	BattleState.unit(st4, u4)["hp"] = int(BattleState.unit(st4, u4)["max_hp"])
	BattleState.unit(st4, u4)["shield"] = 99999
	_check("bersaglio con scudo enorme: nessun avviso", BattleResolver.threat_preview(st4)["enrage_lethal"].is_empty() and BattleResolver.threat_preview(st4)["lethal"].is_empty())


func _test_chain_flag() -> void:
	var st: Dictionary = _state("distributore", 5)
	_check("senza catena annunciata: chain vuota", str(BattleResolver.threat_preview(st)["chain"]) == "")
	st["telegraph"]["chain"] = "scarica"
	_check("catena annunciata: l'anteprima la segnala (ma non ne stima il danno)", str(BattleResolver.threat_preview(st)["chain"]) == "scarica")


func _test_no_boss_crit() -> void:
	var crits: int = 0
	var hits: int = 0
	for boss_id in ["distributore", "semaforo", "tombino", "cabina"]:
		for seed_value in range(1, 5):
			var st: Dictionary = _state(boss_id, seed_value)
			BattleState.boss(st)["spd"] = 100
			for r in 6:
				if str(st["winner"]) != "":
					break
				var evs: Array = BattleResolver.autoplay_round(st)
				for e in evs:
					if str(e.get("t", "")) == "damage" and str(e.get("src", "")) == "boss":
						hits += 1
						if bool(e.get("crit", false)):
							crits += 1
	_check("il boss non fa colpi critici (%d colpi osservati)" % hits, hits > 20 and crits == 0)
