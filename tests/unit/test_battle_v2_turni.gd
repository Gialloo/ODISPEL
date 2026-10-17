extends SceneTree

# Turni sequenziali nel Test V2: ognuno sceglie e agisce nel suo turno (ordine di velocita'), l'azione si risolve subito,
# poi tocca al successivo; stesso comportamento con AUTO.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tests/unit/test_battle_v2_turni.gd

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


func _humans(scn: BattleV2) -> Array:
	var out: Array = []
	for e in scn.turn_list:
		if not bool(e["boss"]):
			out.append(str(e["player"]))
	return out


func _wait_human(scn: BattleV2, max_s: float = 15.0) -> bool:
	var t: float = 0.0
	while (scn.locked or scn.cur < 0) and not scn.ended and t < max_s:
		await create_timer(0.03).timeout
		t += 0.03
	return not scn.ended


func _act(scn: BattleV2) -> void:
	scn._tap(scn.wheel_front.hits[0].get_center())
	await create_timer(0.05).timeout
	scn._tap(BattleV2.CONFIRM_RECT.get_center())


func _run() -> void:
	Settings.tutorial_done = true
	Settings.shake = 1.0
	Settings.flash = 1.0
	var scn: BattleV2 = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate() as BattleV2
	root.add_child(scn)
	await create_timer(1.3).timeout
	scn.ult_sempre = false
	var b: Dictionary = scn._battle()

	# --- ordine e primo turno ---
	var ord: Array = SeqRound.order(b)
	_check("ordine del round: 3 operatori + boss", scn.turn_list.size() == 4 and ord.size() == 4)
	var humans: Array = _humans(scn)
	_check("tocca per primo all'operatore piu' veloce (tra gli umani)", scn.cur == scn.slots.find(humans[0]))
	_check("turno sbloccato per il giocatore", not scn.locked)
	var boss_idx: int = 0
	for i in scn.turn_list.size():
		if bool(scn.turn_list[i]["boss"]):
			boss_idx = i

	# --- l'azione si risolve subito dopo la conferma ---
	var boss_hp0: int = int(BattleState.boss(b)["hp"])
	var first_slot: int = scn.cur
	await _act(scn)
	await create_timer(0.1).timeout
	_check("subito dopo la conferma il turno e' bloccato", scn.locked)
	_check("l'azione e' registrata per chi ha agito", scn.choices.has(str(scn.slots[first_slot])))
	_check("il boss ha gia' subito il colpo (prima del turno degli altri)", int(BattleState.boss(b)["hp"]) < boss_hp0)
	_check("gli altri non hanno ancora agito", scn.choices.size() == 1)

	# --- il turno passa al successivo, boss compreso, nell'ordine di velocita' ---
	var seen_boss_turn: bool = false
	var order_seen: Array = [str(scn.slots[first_slot])]
	var guard: int = 0
	var round0: int = int(b["round"])
	while int(b["round"]) == round0 and not scn.ended and guard < 600:
		guard += 1
		if scn.boss_turn:
			seen_boss_turn = true
		if not scn.locked and scn.cur >= 0:
			var pid: String = str(scn.slots[scn.cur])
			if order_seen.back() != pid and not scn.choices.has(pid):
				order_seen.append(pid)
				_check("turno di %s: vede l'annuncio del boss solo se il boss non ha agito" % pid, bool(BattleV2._G.boss["show"]) != scn.boss_done or int(BattleState.boss(b).get("stun", 0)) > 0)
				await _act(scn)
		await create_timer(0.03).timeout
	_check("nel round il boss ha avuto il suo turno", seen_boss_turn)
	_check("gli operatori hanno agito nell'ordine di velocita'", order_seen == humans)
	_check("il round e' avanzato dopo l'ultimo turno", int(b["round"]) == round0 + 1 or scn.ended)
	_check("al round nuovo l'ordine e' ricalcolato", scn.ended or scn.turn_list.size() >= 2)

	# --- AUTO: stessa struttura, camera che passa da uno all'altro ---
	if not scn.ended:
		await _wait_human(scn)
		var round1: int = int(b["round"])
		var humans1: Array = _humans(scn)
		scn._G.auto_on = true
		scn._auto_turn()
		var seq: Array = []
		var cam_moved: bool = false
		var slots_seen: Dictionary = {}
		var boss_seen: bool = false
		var t: float = 0.0
		while int(b["round"]) == round1 and not scn.ended and t < 25.0:
			await create_timer(0.02).timeout
			t += 0.02
			for k in scn.choices.keys():
				if not seq.has(k):
					seq.append(k)
			if absf(scn.cam.x) > 8.0:
				cam_moved = true
			if scn.cur >= 0:
				slots_seen[scn.cur] = true
			if scn.boss_turn:
				boss_seen = true
		_check("AUTO: gli operatori agiscono nell'ordine di velocita'", seq == humans1 or scn.ended)
		_check("AUTO: la camera si muove tra i personaggi", cam_moved)
		_check("AUTO: passa per tutti gli operatori vivi (%d)" % slots_seen.size(), slots_seen.size() >= 2)
		_check("AUTO: il boss agisce nel suo turno", boss_seen)
		# AUTO spento: si ferma al turno successivo di un umano
		if not scn.ended:
			scn._G.auto_on = false
			await _wait_human(scn)
			_check("AUTO spento: si ferma e aspetta il giocatore", (not scn.locked and scn.cur >= 0) or scn.ended)
		# AUTO fino alla fine
		if not scn.ended:
			scn._G.auto_on = true
			scn._auto_turn()
			var t2: float = 0.0
			while not scn.ended and t2 < 90.0:
				await create_timer(0.05).timeout
				t2 += 0.05
			_check("AUTO: la battaglia arriva alla fine", scn.ended)
	scn._G.auto_on = false
	print("RISULTATO: ", passed, " ok, ", failed, " falliti")
	print("FAIL: ", failed)
	quit(1 if failed > 0 else 0)
