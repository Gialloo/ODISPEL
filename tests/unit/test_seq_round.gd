extends SceneTree

# Round a turni sequenziali (SeqRound, solo Test V2): con sole mosse a priorita' 0 deve dare lo stesso risultato del motore classico.
#   xvfb-run -a godot --path . --resolution 1280x720 -s res://tests/unit/test_seq_round.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _src(seed_v: int) -> SoloBattleSource:
	var s := SoloBattleSource.new()
	s.training = true
	s.start(RosterStore.load_or_new(), "distributore", seed_v, 0)
	return s


func _sig(b: Dictionary) -> String:
	var parts: Array = [str(b["winner"]), str(b["round"]), str(b.get("phase", 1))]
	var ids: Array = (b["units"] as Dictionary).keys()
	ids.sort()
	for id in ids:
		var u: Dictionary = b["units"][id]
		parts.append("%s:%d:%d:%d:%d" % [id, int(u["hp"]), int(u["energy"]), int(u["gauge"]), int(u.get("balance", 0))])
	return "|".join(parts)


func _init() -> void:
	var atk: Dictionary = {"swap": "", "move": "attack", "target": ""}
	var same: int = 0
	var total: int = 0
	for seed_v in [3, 7, 11, 99, 1234]:
		var a: SoloBattleSource = _src(seed_v)
		var b: SoloBattleSource = _src(seed_v)
		var rounds: int = 0
		while str(a.battle["winner"]) == "" and rounds < 12:
			rounds += 1
			for sid in a.my_slots():
				BattleState.player(a.battle, sid)["choice"] = atk.duplicate()
			BattleResolver.resolve_round(a.battle)
			SeqRound.begin(b.battle)
			for e in SeqRound.order(b.battle):
				if bool(e["boss"]):
					SeqRound.boss_action(b.battle)
				else:
					SeqRound.player_action(b.battle, str(e["player"]), atk)
			SeqRound.finish(b.battle)
			total += 1
			if _sig(a.battle) == _sig(b.battle):
				same += 1
		_check("seed %d: stesso esito del motore classico dopo %d round" % [seed_v, rounds], _sig(a.battle) == _sig(b.battle))
	_check("tutti i round identici (%d/%d)" % [same, total], same == total and total > 0)

	# ordine: per velocita', boss incluso, solo vivi
	var s: SoloBattleSource = _src(5)
	SeqRound.begin(s.battle)
	var ord: Array = SeqRound.order(s.battle)
	_check("ordine: 3 operatori + boss", ord.size() == 4)
	var sorted_ok: bool = true
	for i in range(1, ord.size()):
		if int(ord[i - 1]["spd"]) < int(ord[i]["spd"]):
			sorted_ok = false
	_check("ordine: velocita' decrescente", sorted_ok)
	_check("ordine: c'e' il boss una volta sola", ord.filter(func(e): return bool(e["boss"])).size() == 1)
	# un K.O. esce dall'ordine
	var victim: Dictionary = BattleState.active_unit(s.battle, "p1_f2")
	victim["hp"] = 0
	_check("ordine: chi e' a terra non agisce", SeqRound.order(s.battle).size() == 3)
	victim["hp"] = 50

	# gli eventi di ogni passo sono separati e in ordine
	var s2: SoloBattleSource = _src(8)
	SeqRound.begin(s2.battle)
	var first: Dictionary = SeqRound.order(s2.battle)[0]
	var ev1: Array = SeqRound.boss_action(s2.battle) if bool(first["boss"]) else SeqRound.player_action(s2.battle, str(first["player"]), atk)
	_check("passo: produce eventi", ev1.size() > 0)
	_check("passo: contiene l'evento act o boss_move", ev1.any(func(e): return str(e.get("t", "")) in ["act", "boss_move", "boss_stunned"]))

	# difesa dopo il boss: la Guardia presa DOPO la mossa del boss vale per il round dopo
	var s3: SoloBattleSource = _src(21)
	SeqRound.begin(s3.battle)
	var boss_done: bool = false
	var late_pid: String = ""
	for e in SeqRound.order(s3.battle):
		if bool(e["boss"]):
			SeqRound.boss_action(s3.battle)
			boss_done = true
		elif boss_done:
			late_pid = str(e["player"])
			SeqRound.player_action(s3.battle, late_pid, {"swap": "", "move": "guard", "target": ""})
		else:
			SeqRound.player_action(s3.battle, str(e["player"]), atk)
	if late_pid != "":
		SeqRound.finish(s3.battle)
		var late_u: Dictionary = BattleState.active_unit(s3.battle, late_pid)
		_check("guardia dopo il boss: resta per il round successivo", int((late_u["statuses"] as Dictionary).get("guard", 0)) > 0)
	else:
		print("NOTA: nessun operatore dopo il boss con questo seme, controllo guardia saltato")
	print("RISULTATO: ", passed, " ok, ", failed, " falliti")
	print("FAIL: ", failed)
	quit(1 if failed > 0 else 0)
