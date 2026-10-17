extends SceneTree

# Squadra e ultimate nel Test V2: dati mostrati dal pannello, stato PRONTA, alone fermo con effetti ridotti.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tests/unit/test_battle_v2_squadra.gd

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


func _run() -> void:
	Settings.tutorial_done = true
	var scn: BattleV2 = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate() as BattleV2
	root.add_child(scn)
	await create_timer(1.3).timeout
	var b: Dictionary = scn._battle()
	var u0: Dictionary = BattleState.unit(b, str(scn._slot_unit(0)["id"]))
	var u1: Dictionary = BattleState.unit(b, str(scn._slot_unit(1)["id"]))
	var u2: Dictionary = BattleState.unit(b, str(scn._slot_unit(2)["id"]))
	# ultimate pronta / non pronta
	u0["gauge"] = BattleTypes.GAUGE_MAX
	scn._refresh()
	_check("ultimate carica: scritta PRONTA", str(BattleV2._G.cmds[2]["cost"]) == "PRONTA")
	u0["gauge"] = 40
	scn.ult_sempre = false
	scn._refresh()
	_check("ultimate al 40%: mostra 40%", str(BattleV2._G.cmds[2]["cost"]) == "40%")
	# dati squadra: PV, K.O., ultimate pronta per riga
	u1["hp"] = int(float(u1["max_hp"]) * 0.2)
	u2["hp"] = 0
	u1["gauge"] = BattleTypes.GAUGE_MAX
	scn._refresh()
	var party: Array = BattleV2._G.party
	_check("squadra: 3 righe", party.size() == 3)
	_check("riga con PV bassi: vivo", bool(party[1]["alive"]) and int(party[1]["hp"]) < int(party[1]["max_hp"]) * 0.3)
	_check("riga a terra: non vivo", not bool(party[2]["alive"]))
	_check("riga con ultimate carica: flag ult", bool(party[1]["ult"]))
	_check("riga con ultimate al 40%: flag ult spento", not bool(party[0]["ult"]))
	# alone fermo con lampi disattivati
	Settings.flash = 0.0
	scn.fx_t = 0.0
	scn._process(0.016)
	var m1: float = scn.halo.modulate.a
	scn.fx_t = 0.3
	scn._process(0.016)
	var m2: float = scn.halo.modulate.a
	_check("lampi 0: alone non pulsa", is_equal_approx(m1, m2))
	Settings.flash = 1.0
	scn.fx_t = 0.0
	scn._process(0.016)
	m1 = scn.halo.modulate.a
	scn.fx_t = 0.3
	scn._process(0.016)
	m2 = scn.halo.modulate.a
	_check("lampi 1: alone pulsa", not is_equal_approx(m1, m2) or not scn.halo.visible)
	print("RISULTATO: ", passed, " ok, ", failed, " falliti")
	print("FAIL: ", failed)
	quit(1 if failed > 0 else 0)
