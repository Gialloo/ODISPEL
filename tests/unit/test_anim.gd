extends SceneTree

# Respiro e scatto d'attacco dei personaggi in battaglia.
#   godot --headless --path . -s res://tests/unit/test_anim.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var st := BattleStage.new()
	root.add_child(st)
	st._anim_on = true
	st._lunge_t = 1.0
	_check("fermo: nessuno scatto", st._lunge_pose(70.0) == Vector4.ZERO)
	st._lunge_t = 0.1
	_check("carica: si arretra", st._lunge_pose(70.0).x < 0.0)
	st._lunge_t = 0.42
	_check("affondo: arriva al bersaglio", absf(st._lunge_pose(70.0).x - 70.0) < 1.0)
	st._lunge_t = 0.3
	_check("durante l'affondo c'e' la scia", st._lunge_pose(70.0).w > 0.5)
	st._lunge_t = 0.99
	_check("a fine scatto si e' tornati al posto", absf(st._lunge_pose(70.0).x) < 1.0)
	var monotonic: bool = true
	var last: float = -100.0
	for i in range(20, 43):
		st._lunge_t = float(i) / 100.0
		var x: float = st._lunge_pose(70.0).x
		monotonic = monotonic and x >= last - 0.001
		last = x
	_check("l'affondo avanza senza tornare indietro", monotonic)
	st._anim_on = false
	st._lunge_t = 0.5
	_check("qualita' bassa: scatto semplice, senza deformazioni", st._lunge_pose(70.0).y == 0.0 and st._lunge_pose(70.0).z == 0.0)
	st._anim_on = true
	var u: Dictionary = BattleState.make_unit("p1", BattleContent.default_entry("kira"))
	var calm: Vector3 = st._idle_pose(u, 0.0)
	_check("respiro: scala vicina a 1", absf(calm.x - 1.0) < 0.03 and absf(calm.y - 1.0) < 0.03)
	var varies: bool = false
	for k in 40:
		st._t = float(k) * 0.1
		if absf(st._idle_pose(u, 0.0).y - 1.0) > 0.005:
			varies = true
	_check("il respiro cambia nel tempo", varies)
	_check("fasi diverse: non respirano all'unisono", st._idle_pose(u, 0.0).y != st._idle_pose(u, 2.0).y)
	u["hp"] = 100
	st._t = 0.3
	_check("pochi PV: postura piegata", st._idle_pose(u, 0.0).z != st._idle_pose({"hp": 1000, "max_hp": 1000, "gauge": 0}, 0.0).z)
	st.free()
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
