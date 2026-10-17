extends SceneTree

# Feedback degli eventi nel Test V2: ogni evento importante del motore produce una scritta con parole chiare.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tests/unit/test_battle_v2_feedback.gd

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
	Settings.shake = 1.0
	Settings.flash = 1.0
	var hero: String = str(scn._slot_unit(0)["id"])
	var boss: String = BattleState.BOSS_ID
	var cases: Array = [
		[{"t": "damage", "src": hero, "dst": boss, "amount": 120, "absorbed": 0, "crit": false}, "-120"],
		[{"t": "damage", "src": hero, "dst": boss, "amount": 300, "absorbed": 0, "crit": true}, "CRITICO"],
		[{"t": "damage", "src": boss, "dst": hero, "amount": 0, "absorbed": 40}, "ASSORBITO"],
		[{"t": "heal", "src": hero, "dst": hero, "amount": 55}, "+55"],
		[{"t": "shield", "src": hero, "dst": hero, "amount": 80}, "SCUDO"],
		[{"t": "dodge", "unit": hero}, "SCHIVATA"],
		[{"t": "down", "unit": hero}, "K.O."],
		[{"t": "break", "src": hero}, "ROTTURA"],
		[{"t": "boss_stunned", "move": "scarica"}, "STORDITO"],
		[{"t": "phase", "phase": 2}, "FASE 2"],
		[{"t": "status", "unit": hero, "status": "bleed", "turns": 3}, "SANGUINA"],
		[{"t": "buff", "unit": hero}, "POTENZIATO"],
		[{"t": "debuff", "unit": hero, "stat": "atk"}, "INDEBOLITO"],
		[{"t": "counter", "unit": hero}, "CONTRATTACCO"],
		[{"t": "marks", "unit": boss, "n": 2, "added": 2}, "MARCHIO x2"],
	]
	for c in cases:
		var it: Dictionary = scn._fb_item(c[0])
		_check("evento %s -> '%s'" % [c[0]["t"], c[1]], not it.is_empty() and str(it["text"]).contains(c[1]))
	# niente scritte vuote o inventate
	_check("danno zero senza assorbito: nessuna scritta", scn._fb_item({"t": "damage", "src": hero, "dst": boss, "amount": 0, "absorbed": 0}).is_empty())
	_check("cura zero: nessuna scritta", scn._fb_item({"t": "heal", "src": hero, "dst": hero, "amount": 0}).is_empty())
	_check("evento sconosciuto: nessuna scritta", scn._fb_item({"t": "inventato", "unit": hero}).is_empty())
	_check("unita' non in campo: nessuna scritta", scn._fb_item({"t": "dodge", "unit": "fantasma"}).is_empty())
	_check("marchio tolto: nessuna scritta", scn._fb_item({"t": "marks", "unit": boss, "n": 0, "added": -2}).is_empty())
	# tanti eventi: il limite taglia i meno importanti, restano quelli importanti
	var many: Array = []
	for i in 30:
		many.append({"t": "damage", "src": hero, "dst": boss, "amount": 10 + i, "absorbed": 0})
	many.append({"t": "damage", "src": hero, "dst": boss, "amount": 500, "absorbed": 0, "crit": true})
	many.append({"t": "break", "src": hero})
	scn._fb_queue.clear()
	scn._fb_busy = true          # blocca la riproduzione: si guarda solo la coda
	scn._on_events(many)
	_check("coda limitata a %d" % BattleV2.FB_MAX, scn._fb_queue.size() == BattleV2.FB_MAX)
	var txt: String = ""
	for it in scn._fb_queue:
		txt += str(it["text"]) + "|"
	_check("il critico resta in coda", txt.contains("CRITICO"))
	_check("la rottura resta in coda", txt.contains("ROTTURA"))
	scn._fb_queue.clear()
	scn._fb_busy = false
	# accessibilita': con scosse a 0 il critico non muove la camera
	Settings.shake = 0.0
	scn.cam_v = Vector2.ZERO
	scn.zoom_v = 0.0
	scn._fb_show(scn._fb_item(cases[1][0]))
	_check("shake 0: il critico non muove la camera", scn.cam_v == Vector2.ZERO and is_zero_approx(scn.zoom_v))
	Settings.shake = 1.0
	scn._fb_show(scn._fb_item(cases[1][0]))
	_check("shake 1: il critico muove la camera", scn.cam_v.length() > 1.0)
	# battaglia vera: dopo la conferma del round compaiono scritte
	await create_timer(1.5).timeout
	var seen: int = 0
	var guard: int = 0
	while scn.cur >= 0 and not scn.locked and guard < 10:
		guard += 1
		scn._tap(scn.wheel_front.hits[0].get_center())
		await create_timer(0.05).timeout
		scn._tap(BattleV2.CONFIRM_RECT.get_center())
		await create_timer(0.05).timeout
	for i in 12:
		await create_timer(0.1).timeout
		seen = maxi(seen, get_nodes_in_group("v2_fb").size())
	_check("round vero: compaiono scritte di feedback", seen > 0)
	await create_timer(3.0).timeout
	_check("le scritte spariscono da sole", get_nodes_in_group("v2_fb").size() == 0)
	print("RISULTATO: ", passed, " ok, ", failed, " falliti")
	print("FAIL: ", failed)
	quit(1 if failed > 0 else 0)
