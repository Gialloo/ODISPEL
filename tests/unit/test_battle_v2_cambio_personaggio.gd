extends SceneTree

# Cambio di personaggio attivo nel Test V2: la camera scivola e l'operatore entra dal lato giusto.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tests/unit/test_battle_v2_cambio_personaggio.gd

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
	Settings.shake = 1.0
	Settings.shake = 1.0
	# il primo a muoversi e' il piu' veloce (il boss agisce da solo nel suo turno)
	var first_pid: String = ""
	for e in scn.turn_list:
		if not bool(e["boss"]):
			first_pid = str(e["player"])
			break
	_check("si parte dall'operatore piu' veloce", scn.cur == scn.slots.find(first_pid))
	# direzione del movimento: da F1 a F2 la camera va verso destra (mondo a sinistra), operatore da destra
	scn.cam = Vector2.ZERO
	scn.cam_v = Vector2.ZERO
	scn.hero_off = 0.0
	scn._last_slot = 0
	scn.cur = 1
	scn._switch_feedback(0)
	_check("avanti: camera spostata verso destra (mondo a sinistra)", scn.cam.x < -10.0)
	_check("avanti: l'operatore entra da destra", scn.hero_off > 10.0)
	_check("dissolvenza di ingresso parte bassa", scn.hero_in < 0.1)
	await create_timer(1.2).timeout
	_check("la camera torna ferma", absf(scn.cam.x) < 3.0)
	_check("l'operatore e' al suo posto", absf(scn.hero_off) < 1.0 and is_equal_approx(scn.hero_in, 1.0))
	_check("l'operatore e' nella posizione prevista", absf(scn.hero.position.x - 179.0) < 1.5)
	# accessibilita': scosse a 0 -> nessun movimento di camera ne' scorrimento, solo dissolvenza
	Settings.shake = 0.0
	scn.cam = Vector2.ZERO
	scn.cam_v = Vector2.ZERO
	scn.hero_off = 0.0
	scn.cur = 2
	scn._switch_feedback(1)
	_check("scosse 0: camera ferma", scn.cam == Vector2.ZERO and scn.cam_v == Vector2.ZERO)
	_check("scosse 0: nessuno scorrimento", is_zero_approx(scn.hero_off))
	_check("scosse 0: resta la dissolvenza", scn.hero_in < 0.1)
	Settings.shake = 1.0
	# disposizione spaziale: F1->F3 sposta il doppio di F1->F2
	scn.cam = Vector2.ZERO
	scn.cam_v = Vector2.ZERO
	scn._last_slot = 0
	scn.cur = 1
	scn._switch_feedback(0)
	var one: float = absf(scn.cam.x)
	scn.cam = Vector2.ZERO
	scn.cur = 2
	scn._switch_feedback(0)
	var two: float = absf(scn.cam.x)
	_check("F1->F3 sposta il doppio di F1->F2 (%.0f vs %.0f)" % [two, one], two > one * 1.8 and two < one * 2.2)
	scn.cam = Vector2.ZERO
	scn.cur = 0
	scn._switch_feedback(2)
	_check("F3->F1: camera verso sinistra, il doppio", scn.cam.x > one * 1.8)
	scn.cam = Vector2.ZERO
	scn.cur = 1
	scn._switch_feedback(1)
	_check("stesso personaggio: la camera non si muove", is_zero_approx(scn.cam.x))
	print("RISULTATO: ", passed, " ok, ", failed, " falliti")
	print("FAIL: ", failed)
	quit(1 if failed > 0 else 0)
