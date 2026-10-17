extends SceneTree

# Stato statico e rientro nel Test V2: ogni battaglia parte pulita (AUTO e velocita' non si portano dietro).
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tests/unit/test_battle_v2_stato.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _new_scene() -> BattleV2:
	var scn: BattleV2 = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate() as BattleV2
	root.add_child(scn)
	await create_timer(1.1).timeout
	scn.ult_sempre = false
	return scn


func _run() -> void:
	Settings.tutorial_done = true
	Settings.shake = 1.0
	Settings.flash = 1.0
	# 1. prima entrata: valori iniziali
	var a: BattleV2 = await _new_scene()
	_check("prima entrata: AUTO spento", not BattleV2._G.auto_on)
	_check("prima entrata: velocita' x1", BattleV2._G.speed == 1)
	_check("prima entrata: squadra di 3 e panchina di 3", BattleV2._G.party.size() == 3 and BattleV2._G.bench.size() == 3)
	_check("la panchina porta i dati per il disegno", BattleV2._G.bench[0].has("por") and BattleV2._G.bench[0].has("hp") and BattleV2._G.bench[0].has("support"))
	# 2. si accendono AUTO e x2, si esce e si rientra
	BattleV2._G.auto_on = true
	BattleV2._G.speed = 2
	BattleV2._G.picked = "ULTIMATE"
	a._auto_turn()
	await create_timer(0.7).timeout       # a meta' azione
	a.queue_free()                          # uscita a meta' round
	await create_timer(0.4).timeout
	_check("uscita a meta' round: nessuna scritta residua", get_nodes_in_group("v2_fb").size() == 0)
	var b: BattleV2 = await _new_scene()
	_check("rientro: AUTO spento", not BattleV2._G.auto_on)
	_check("rientro: velocita' x1", BattleV2._G.speed == 1)
	_check("rientro: nessuna selezione residua", BattleV2._G.picked == "")
	_check("rientro: round 1, nessuno ha ancora agito", int(b._battle()["round"]) == 1 and b.choices.is_empty())
	_check("rientro: turno bloccato = no, tocca al giocatore", not b.locked and b.cur >= 0)
	var boss_hp: int = int(BattleState.boss(b._battle())["hp"])
	_check("rientro: boss a piena vita", boss_hp == int(BattleState.boss(b._battle())["max_hp"]))
	# 3. vittoria, poi nuova battaglia
	BattleV2._G.auto_on = true
	b._auto_turn()
	var t: float = 0.0
	while not b.ended and t < 120.0:
		await create_timer(0.1).timeout
		t += 0.1
	_check("la battaglia finisce", b.ended)
	var won: bool = str(b._battle()["winner"]) == "players"
	b.queue_free()
	await create_timer(0.3).timeout
	var c: BattleV2 = await _new_scene()
	_check("dopo %s: AUTO spento e x1" % ("vittoria" if won else "sconfitta"), not BattleV2._G.auto_on and BattleV2._G.speed == 1)
	_check("dopo la fine: nuova battaglia pulita (non finita, round 1)", not c.ended and int(c._battle()["round"]) == 1 and str(c._battle()["winner"]) == "")
	_check("dopo la fine: nessun risultato a schermo", c._result == null)
	# 4. sconfitta forzata, poi nuova battaglia
	for uid in c._battle()["units"]:
		if str(uid) != BattleState.BOSS_ID:
			c._battle()["units"][uid]["hp"] = 0
	c._battle()["winner"] = "boss"
	c._resolve_action(str(c.slots[maxi(c.cur, 0)]), {"swap": "", "move": "attack", "target": ""})
	t = 0.0
	while not c.ended and t < 20.0:
		await create_timer(0.1).timeout
		t += 0.1
	_check("sconfitta: la battaglia si chiude", c.ended and str(c._battle()["winner"]) == "boss")
	c.queue_free()
	await create_timer(0.3).timeout
	var d: BattleV2 = await _new_scene()
	_check("dopo la sconfitta: nuova battaglia pulita", not d.ended and str(d._battle()["winner"]) == "" and int(d._battle()["round"]) == 1 and d.cur >= 0)
	_check("dopo la sconfitta: la squadra e' di nuovo viva", BattleV2._G.party.size() == 3 and bool(BattleV2._G.party[0]["alive"]))
	# 5. _G.reset riporta tutto
	BattleV2._G.auto_on = true
	BattleV2._G.speed = 2
	BattleV2._G.banner_tag = "x"
	BattleV2._G.reset()
	_check("reset: tutto ai valori iniziali", not BattleV2._G.auto_on and BattleV2._G.speed == 1 and BattleV2._G.banner_tag == "" and BattleV2._G.party.is_empty() and BattleV2._G.bench.is_empty())
	print("RISULTATO: ", passed, " ok, ", failed, " falliti")
	print("FAIL: ", failed)
	quit(1 if failed > 0 else 0)
