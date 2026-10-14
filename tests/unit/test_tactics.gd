extends SceneTree

# Tattiche: ordini, prezzo, placche, catene, eco, determinazione, sfide, sinergie.
#   godot --headless --path . -s res://tests/unit/test_tactics.gd

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


func _state(tier: int, seed_value: int = 5) -> Dictionary:
	return BattleState.create([_spec("a"), _spec("b")], "distributore", seed_value, tier)


func _init() -> void:
	_check("ordini noti", Tactics.clean_order("concentra") == "concentra" and Tactics.clean_order("boh") == "" and Tactics.clean_order(null) == "")
	_check("prezzi noti", Tactics.clean_push("prezzo") == "prezzo" and Tactics.clean_push("x") == "")
	for o in Tactics.ORDER_ORDER:
		_check("ordine definito " + str(o), Tactics.ORDERS.has(o))
	for p in Tactics.PUSH_ORDER:
		_check("prezzo definito " + str(p), Tactics.PUSH.has(p))

	# placche solo da DIFFICILE
	var easy: Dictionary = _state(0)
	_check("normale: niente placche", int(BattleState.boss(easy).get("plates", 0)) == 0)
	var hard: Dictionary = _state(1)
	var boss: Dictionary = BattleState.boss(hard)
	_check("difficile: placche", int(boss["plates"]) == Tactics.PLATES and int(boss["plate_hp"]) > 0)
	var ev: Array = []
	var left: int = Tactics.plate_hit(hard, boss, 100, 0, ev)
	_check("la placca assorbe il 40%", left == 60 and int(boss["plate_hp"]) < int(boss["plate_max"]))
	_check("perforante ignora la placca", Tactics.plate_hit(hard, boss, 100, 5, []) == 100)
	var def0: int = int(boss["def"])
	boss["plate_hp"] = 1
	var ev2: Array = []
	Tactics.plate_hit(hard, boss, 100, 0, ev2)
	_check("placca rotta: difesa giu', potere liberato", int(boss["plates"]) == Tactics.PLATES - 1 and int(boss["def"]) < def0 and float(hard["boss_boost"]) > 0.0 and bool(ev2[0]["broke"]))
	_check("boost si consuma una volta", Tactics.boss_boost(hard) > 1.0 and Tactics.boss_boost(hard) == 1.0)

	# determinazione
	var hero: Dictionary = BattleState.unit(hard, "a:kira")
	var evr: Array = []
	hero["hp"] = int(hero["max_hp"]) - 1
	Tactics.on_damaged(hero, evr)
	_check("determinazione non scatta con PV alti", evr.is_empty())
	hero["hp"] = int(float(hero["max_hp"]) * 0.2)
	Tactics.on_damaged(hero, evr)
	_check("determinazione scatta sotto il 30%", evr.size() == 1 and Tactics.damage_mult(hero) > 1.0)
	var evr2: Array = []
	Tactics.on_damaged(hero, evr2)
	_check("determinazione una sola volta", evr2.is_empty())

	# maestria
	_check("maestria: livelli e tetto", Tactics.mastery_mult({"mastery": {"x": 2}}, "x") > 1.0 and Tactics.mastery_mult({"mastery": {"x": 99}}, "x") <= 1.0 + Tactics.MASTERY_BONUS * float(Tactics.MASTERY_MAX) + 0.0001)
	_check("senza maestria 1.0", Tactics.mastery_mult({}, "x") == 1.0)

	# sfide: deterministiche a parita' di seme
	var a: Dictionary = _state(0, 11)
	var b: Dictionary = _state(0, 11)
	_check("sfida stabile", Tactics.challenge_id(a) == Tactics.challenge_id(b) and Tactics.CHALLENGES.has(Tactics.challenge_id(a)))
	_check("sfida non riuscita se non si vince", not Tactics.challenge_done(a))
	var seen: Dictionary = {}
	for sd in range(1, 40):
		seen[Tactics.challenge_id(_state(0, sd))] = true
	_check("tutte le sfide possono uscire", seen.size() == Tactics.CHALLENGE_ORDER.size())
	var c: Dictionary = _state(0, 3)
	c["winner"] = "players"
	c["challenge"] = {"id": "nessun_caduto"}
	c["stats"] = {"downs": 0}
	_check("nessun caduto riuscita", Tactics.challenge_done(c))
	c["stats"] = {"downs": 1}
	_check("nessun caduto fallita", not Tactics.challenge_done(c))
	c["challenge"] = {"id": "riserva_viva"}
	c["reserve"] = 3
	_check("riserva viva riuscita", Tactics.challenge_done(c))

	# eco
	var e: Dictionary = _state(0)
	Tactics.track(e, [{"t": "damage", "src": "a:kira", "dst": BattleState.BOSS_ID, "amount": 40}, {"t": "damage", "src": "a:dax", "dst": BattleState.BOSS_ID, "amount": 70}, {"t": "damage", "src": BattleState.BOSS_ID, "dst": "a:kira", "amount": 999}])
	_check("eco: il colpo piu' forte ai danni del boss", int(e["echo"]) == 70)

	# fine round pulisce i bonus temporanei
	var f: Dictionary = _state(0)
	var u: Dictionary = BattleState.unit(f, "a:dax")
	u["order_mult"] = 1.05
	u["push_mult"] = 1.4
	u["resolve_turns"] = 2
	Tactics.end_round(f, [])
	_check("bonus temporanei azzerati", not u.has("order_mult") and not u.has("push_mult") and int(u["resolve_turns"]) == 1)

	# anteprima sinergie: squadra e voce vuota
	var team: Array = [BattleContent.default_entry("kira"), BattleContent.default_entry("dax"), BattleContent.default_entry("elle")]
	var combos: Array = Tactics.possible_combos(team)
	for cb in combos:
		_check("sinergia con nomi " + str(cb["id"]), str(cb["a"]) != "" and str(cb["b"]) != "" and str(cb["a"]) != str(cb["b"]))
	_check("squadra da sola: nessuna sinergia", Tactics.possible_combos([BattleContent.default_entry("kira")]).is_empty())

	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
