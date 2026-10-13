extends SceneTree

# Arena, comportamenti dei boss, Soccorso, nuovi potenziamenti.
#   godot --headless --path . -s res://tests/unit/test_arena.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _spec(id: String) -> Dictionary:
	return {"id": id, "name": id, "ai": false, "team": [BattleContent.default_entry("kira"), BattleContent.default_entry("dax"), BattleContent.default_entry("elle")]}


func _state(seed_value: int = 5) -> Dictionary:
	return BattleState.create([_spec("a"), _spec("b")], "distributore", seed_value)


func _init() -> void:
	for id in BattleContent.BOSS_ORDER:
		_check("%s: comportamento valido" % id, Arena.BEHAVIORS.has(Arena.behavior_of(str(id))))
	_check("comportamento stabile", Arena.behavior_of("distributore") == Arena.behavior_of("distributore"))
	var kinds: Dictionary = {}
	for id in BattleContent.BOSS_ORDER:
		kinds[Arena.behavior_of(str(id))] = true
	_check("tutti i comportamenti usati", kinds.size() == Arena.BEHAVIOR_ORDER.size())

	# eventi: round 2 si', round 3 no, e deterministico
	var s: Dictionary = _state()
	s["round"] = 2
	Arena.roll(s)
	_check("round 2: evento", not (s["arena"] as Dictionary).is_empty())
	var s2: Dictionary = _state()
	s2["round"] = 2
	Arena.roll(s2)
	_check("evento uguale a parita' di seme", str(s["arena"]["id"]) == str(s2["arena"]["id"]) and str(s["arena"].get("unit", "")) == str(s2["arena"].get("unit", "")))
	s["round"] = 3
	Arena.roll(s)
	_check("round 3: nessun evento", (s["arena"] as Dictionary).is_empty())
	_check("round 5: evento", (func() -> bool:
		s["round"] = 5
		Arena.roll(s)
		return not (s["arena"] as Dictionary).is_empty()).call())

	# contaminazione
	var sc: Dictionary = _state()
	var u: Dictionary = BattleState.unit(sc, "a:kira")
	sc["arena"] = {"id": "contaminazione", "player": "a", "unit": "a:kira"}
	sc["acts"] = {"a:kira": "attack"}
	var hp0: int = int(u["hp"])
	var ev: Array = []
	Arena.resolve(sc, ev)
	_check("contaminazione: perde PV", int(u["hp"]) < hp0 and not bool(ev[0]["ok"]))
	sc["arena"] = {"id": "contaminazione", "player": "a", "unit": "a:kira"}
	sc["acts"] = {"a:kira": "guard"}
	hp0 = int(u["hp"])
	ev = []
	Arena.resolve(sc, ev)
	_check("contaminazione: guardia protegge", int(u["hp"]) == hp0 and bool(ev[0]["ok"]))
	_check("l'arena non uccide", (func() -> bool:
		u["hp"] = 1
		sc["arena"] = {"id": "contaminazione", "player": "a", "unit": "a:kira"}
		sc["acts"] = {}
		Arena.resolve(sc, [])
		return int(u["hp"]) >= 1).call())

	# sigillo
	var ss: Dictionary = _state()
	var bal0: int = int(BattleState.boss(ss)["balance"])
	ss["arena"] = {"id": "sigillo"}
	ss["tags"] = [{"unit": "a:kira", "tags": ["ATTACK"]}, {"unit": "b:kira", "tags": ["ATTACK"]}]
	var res0: int = int(ss["reserve"])
	ev = []
	Arena.resolve(ss, ev)
	_check("sigillo rotto: equilibrio e riserva", int(BattleState.boss(ss)["balance"]) < bal0 and int(ss["reserve"]) == res0 + 1)
	ss["arena"] = {"id": "sigillo"}
	ss["tags"] = [{"unit": "a:kira", "tags": ["ATTACK"]}]
	var sh0: int = int(BattleState.boss(ss)["shield"])
	ev = []
	Arena.resolve(ss, ev)
	_check("sigillo intatto: scudo al boss", int(BattleState.boss(ss)["shield"]) > sh0)

	# comportamenti
	var sb: Dictionary = _state()
	var boss: Dictionary = BattleState.boss(sb)
	boss["char"] = "distributore"
	var bid: String = Arena.behavior_of("distributore")
	sb["events"] = [{"t": "heal", "src": "a:kira", "dst": "a:kira", "amount": 5}, {"t": "heal", "src": "b:kira", "dst": "b:kira", "amount": 5}]
	var evb: Array = []
	var m: float = Arena.boss_behavior(sb, boss, evb)
	if bid == "punisce_cure":
		_check("punisce le cure: +20%", is_equal_approx(m, 1.2))
	else:
		_check("comportamento coerente", m >= 1.0)
	var fake: Dictionary = _state()
	var fb: Dictionary = BattleState.boss(fake)
	fb["char"] = "semaforo"
	fake["events"] = []
	_check("senza cure nessun bonus (se punisce le cure)", Arena.behavior_of("semaforo") != "punisce_cure" or is_equal_approx(Arena.boss_behavior(fake, fb, []), 1.0))

	# soccorso
	var sr: Dictionary = _state()
	var bench: Dictionary = BattleState.unit(sr, "a:dax")
	bench["hp"] = 0
	_check("soccorso offerto con un caduto", BattleResolver.reactions_for(sr, "a").any(func(r: Dictionary) -> bool: return str(r["id"]) == "soccorso"))
	_check("soccorso valido", BattleResolver.validate_choice(sr, "a", {"move": "soccorso"}) == "")
	BattleResolver.submit_choice(sr, "a", {"move": "soccorso"})
	BattleResolver.submit_choice(sr, "b", {"move": "guard"})
	var evr: Array = BattleResolver.resolve_round(sr)
	var got: bool = false
	for e in evr:
		if str(e["t"]) == "rescue":
			got = true
	_check("evento soccorso", got)
	_check("il caduto torna con il 25%", int(bench["hp"]) == int(round(float(bench["max_hp"]) * BattleTypes.RESCUE_HP)))
	_check("soccorso una sola volta a testa", BattleResolver.validate_choice(sr, "a", {"move": "soccorso"}) != "")
	bench["hp"] = 0
	_check("gia' soccorso: non di nuovo", BattleResolver.validate_choice(sr, "a", {"move": "soccorso"}) != "")
	var sn: Dictionary = _state()
	_check("senza caduti niente soccorso", BattleResolver.validate_choice(sn, "a", {"move": "soccorso"}) != "")

	# potenziamenti e anomalia
	var sbn: Dictionary = _state()
	Endless.apply_boons(sbn, ["riflessi", "riserva"])
	_check("riflessi: costo ridotto", BattleResolver.reaction_cost(sbn, "interruzione") == 1 and BattleResolver.reaction_cost(sbn, "schivata") == 0)
	_check("riserva: +2 all'inizio", int(sbn["reserve"]) == BattleTypes.RESERVE_START + 2)
	_check("i potenziamenti esistono", Endless.BOONS.has("riflessi") and Endless.BOON_ORDER.has("riserva"))
	var sv: Dictionary = _state()
	Endless.apply(sv, 5, "vampirico")
	_check("vampirico: il boss si cura", float(sv["boss_drain"]) > 0.0)

	# una battaglia intera con eventi e comportamenti: niente errori e termina
	var sim: Dictionary = _state(11)
	var n: int = 0
	while str(sim["winner"]) == "" and n < 60:
		BattleResolver.autoplay_round(sim)
		n += 1
	_check("la battaglia finisce con le nuove regole", str(sim["winner"]) != "")
	var txt_ok: bool = true
	for e in [{"t": "arena", "id": "sigillo", "ok": true, "unit": "", "amount": 0}, {"t": "arena", "id": "contaminazione", "ok": false, "unit": "a:kira", "amount": 5}, {"t": "behavior", "id": "punisce_cure", "n": 2}, {"t": "rescue", "unit": "a:kira", "who": "a:dax", "hp": 50}]:
		txt_ok = txt_ok and str(BattleText.describe(sr, e).get("text", "")) != ""
	_check("testi dei nuovi eventi", txt_ok)
	print("test_arena: %d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
