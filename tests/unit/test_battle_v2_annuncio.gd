extends SceneTree

# Annuncio della mossa del boss nel Test V2: ogni mossa viene annunciata, con i dati veri del motore.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tests/unit/test_battle_v2_annuncio.gd

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


func _expected(scn: BattleV2) -> Dictionary:
	var b: Dictionary = scn._battle()
	var mid: String = str(b["telegraph"]["move"])
	var mdef: Dictionary = BattleContent.BOSS_MOVES[mid]
	return {"id": mid, "name": str(mdef["name"]), "heavy": BattleResolver.is_heavy_boss_move(mdef), "all": str(mdef["target"]) == "all"}


func _pick_and_confirm(scn: BattleV2) -> void:
	var guard: int = 0
	while scn.cur >= 0 and not scn.locked and guard < 10:
		guard += 1
		scn._tap(scn.wheel_front.hits[0].get_center())
		await create_timer(0.05).timeout
		scn._tap(BattleV2.CONFIRM_RECT.get_center())
		await create_timer(0.05).timeout


func _run() -> void:
	Settings.tutorial_done = true
	var scn: BattleV2 = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate() as BattleV2
	root.add_child(scn)
	await create_timer(1.2).timeout
	scn.ult_sempre = false      # battaglia piu' lunga: si vedono piu' mosse del boss
	var seen_heavy: bool = false
	var seen_normal: bool = false
	var seen_phase: int = 1
	var rounds: int = 0
	var seen_boss_turn: bool = false
	var last_round: int = -1
	while not scn.ended and rounds < 40:
		# attende il turno di un operatore (il boss agisce da solo nel suo turno)
		var wt: int = 0
		while (scn.locked or scn.cur < 0) and not scn.ended and wt < 400:
			if scn.boss_turn and not seen_boss_turn:
				seen_boss_turn = true
				_check("turno del boss: annuncio visibile", bool(BattleV2._G.boss["show"]) or int(BattleState.boss(scn._battle()).get("stun", 0)) > 0)
			await create_timer(0.03).timeout
			wt += 1
		if scn.ended:
			break
		var new_round: bool = int(scn._battle()["round"]) != last_round
		last_round = int(scn._battle()["round"])
		if new_round:
			seen_boss_turn = false
		var e: Dictionary = _expected(scn)
		var g: Dictionary = BattleV2._G.boss
		var stunned: bool = int(BattleState.boss(scn._battle()).get("stun", 0)) > 0
		if scn.boss_done:
			_check("round %d: dopo la mossa del boss nessun annuncio" % rounds, not bool(g["show"]))
		elif not stunned:
			_check("round %d: annuncio visibile (%s)" % [rounds, e["id"]], bool(g["show"]))
			_check("round %d: nome = mossa del motore" % rounds, str(g["move"]) == str(e["name"]))
			_check("round %d: pesante/normale = regola del motore" % rounds, bool(g["heavy"]) == bool(e["heavy"]))
			var tgt: String = str(g["target"])
			if bool(e["all"]):
				_check("round %d: bersaglio TUTTI" % rounds, tgt == "TUTTI")
			else:
				var pid: String = str(scn._battle()["telegraph"]["target"])
				var unit: Dictionary = BattleState.unit(scn._battle(), str(BattleState.player(scn._battle(), pid)["active"]))
				_check("round %d: bersaglio = unita' scelta dal motore" % rounds, tgt == str(unit["name"]).to_upper())
			if bool(e["heavy"]):
				seen_heavy = true
			else:
				seen_normal = true
			# l'annuncio resta anche dopo aver selezionato un comando
			scn._tap(scn.wheel_front.hits[0].get_center())
			await create_timer(0.1).timeout
			_check("round %d: annuncio resta con comando selezionato" % rounds, bool(BattleV2._G.boss["show"]))
			scn._cancel()
		seen_phase = maxi(seen_phase, int(scn._battle().get("phase", 1)))
		await _pick_and_confirm(scn)
		_check("turno %d: durante l'azione nessun annuncio" % rounds, not bool(BattleV2._G.boss["show"]) or scn.boss_turn)
		rounds += 1
	_check("visto almeno un round con mossa normale", seen_normal)
	print("round naturali con mossa pesante: ", seen_heavy)
	if scn.ended:
		_check("a fine battaglia nessun annuncio", not bool(BattleV2._G.boss["show"]))
	print("fasi viste: ", seen_phase, " round: ", rounds, " ended: ", scn.ended)
	# riavvio: scena nuova, annuncio coerente con il nuovo round 1
	scn.queue_free()
	await process_frame
	var scn2: BattleV2 = (load("res://scenes/battle_v2/battle_v2.tscn") as PackedScene).instantiate() as BattleV2
	root.add_child(scn2)
	await create_timer(1.0).timeout
	var e2: Dictionary = _expected(scn2)
	_check("riavvio: annuncio del nuovo round", bool(BattleV2._G.boss["show"]) and str(BattleV2._G.boss["move"]) == str(e2["name"]))
	# tutte le mosse del boss: ognuna, messa come annuncio del motore, compare con nome e tipo giusti
	var all_ok: bool = true
	var n_heavy: int = 0
	for mid in BattleContent.BOSS_MOVES:
		var md: Dictionary = BattleContent.BOSS_MOVES[mid]
		scn2._battle()["telegraph"]["move"] = mid
		scn2._refresh()
		var gg: Dictionary = BattleV2._G.boss
		if BattleResolver.is_heavy_boss_move(md):
			n_heavy += 1
		if not (bool(gg["show"]) and str(gg["move"]) == str(md["name"]) and bool(gg["heavy"]) == BattleResolver.is_heavy_boss_move(md)):
			all_ok = false
			print("  mossa non annunciata bene: ", mid)
	_check("tutte le %d mosse del boss annunciate con dati veri" % BattleContent.BOSS_MOVES.size(), all_ok)
	_check("esistono mosse pesanti e normali tra quelle provate", n_heavy > 0 and n_heavy < BattleContent.BOSS_MOVES.size())
	scn2._battle()["telegraph"]["move"] = "nessuna_mossa"
	scn2._refresh()
	_check("mossa sconosciuta: nessun annuncio inventato", not bool(BattleV2._G.boss["show"]))
	print("RISULTATO: ", passed, " ok, ", failed, " falliti")
	print("FAIL: ", failed)
	quit(1 if failed > 0 else 0)
