extends SceneTree

# Vantaggio di colore nel Test V2: la HUD mostra il valore del motore (efficace / neutro / sfavorevole) prima della conferma.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tests/unit/test_battle_v2_colore.gd

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
	await create_timer(1.2).timeout
	var b: Dictionary = scn._battle()
	var au: Dictionary = scn._slot_unit(0)
	var boss: Dictionary = BattleState.boss(b)
	var seen: Dictionary = {}
	for pair in [["viola", "giallo"], ["rosso", "verde"], ["verde", "rosso"], ["rosso", "rosso"], ["blu", "viola"], ["giallo", "giallo"]]:
		au["color"] = pair[0]
		boss["color"] = pair[1]
		scn._refresh()
		var m: Dictionary = BattleV2._G.matchup
		var expect: float = BattleTypes.color_multiplier(pair[0], pair[1])
		_check("%s su %s: valore = motore (%s)" % [pair[0], pair[1], str(expect)], is_equal_approx(float(m["mult"]), expect) and bool(m["show"]))
		seen[snappedf(expect, 0.01)] = true
		# mossa che colpisce il boss: etichetta con parole; guardia: nessuna etichetta
		scn._select(0)
		var tag_att: String = BattleV2._G.banner_tag
		var want: String = "EFFICACE" if expect > 1.0 else ("SFAVOREVOLE" if expect < 1.0 else "NEUTRO")
		_check("%s su %s: etichetta ATTACCO contiene %s" % [pair[0], pair[1], want], tag_att.begins_with(want))
		scn._select(3)
		_check("%s su %s: GUARDIA senza etichetta di colore" % [pair[0], pair[1]], BattleV2._G.banner_tag == "")
		scn._cancel()
	_check("provati efficace, neutro e sfavorevole", seen.size() >= 3)
	# non compare durante la risoluzione ne' a fine battaglia
	scn.locked = true
	scn._refresh()
	_check("nessun esito colore durante la risoluzione", not bool(BattleV2._G.matchup["show"]))
	scn.locked = false
	scn.ended = true
	scn._refresh()
	_check("nessun esito colore a fine battaglia", not bool(BattleV2._G.matchup["show"]))
	print("RISULTATO: ", passed, " ok, ", failed, " falliti")
	print("FAIL: ", failed)
	quit(1 if failed > 0 else 0)
