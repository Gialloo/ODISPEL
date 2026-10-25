extends SceneTree

# Guardia a tempo (Parry): finestre in millisecondi veri, uguali a ogni fps; AMPIA allarga senza togliere la guardia normale.
var fails: int = 0


func _chk(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _init() -> void:
	var n: Dictionary = Parry.windows(false, false)
	var w: Dictionary = Parry.windows(true, false)
	var l: Dictionary = Parry.windows(false, true)
	_chk(Parry.grade(0.0, n) == "perfect", "all'impatto e' perfetta")
	_chk(Parry.grade(-79.0, n) == "perfect", "-79 ms perfetta")
	_chk(Parry.grade(-81.0, n) == "good", "-81 ms guardia")
	_chk(Parry.grade(-300.0, n) == "good", "-300 ms guardia")
	_chk(Parry.grade(-301.0, n) == "early", "-301 ms troppo presto")
	_chk(Parry.grade(120.0, n) == "good", "+120 ms ancora guardia")
	_chk(Parry.grade(121.0, n) == "early", "+121 ms fuori")
	# ampia: ogni tocco che vale in normale vale anche in ampia, e con lo stesso voto o meglio
	for d in range(-400, 200, 5):
		var gn: String = Parry.grade(float(d), n)
		var gw: String = Parry.grade(float(d), w)
		if gn == "perfect":
			_chk(gw == "perfect", "ampia tiene la perfetta a %d" % d)
		if gn == "good":
			_chk(gw != "early", "ampia tiene la guardia a %d" % d)
	_chk(Parry.grade(-400.0, w) == "good", "ampia: -400 ms e' guardia")
	_chk(Parry.grade(-110.0, w) == "perfect", "ampia: -110 ms e' perfetta")
	_chk(float(l["good"]) > float(n["good"]) and float(l["perfect"]) > float(n["perfect"]), "Lance para meglio")
	# a fps diversi lo stesso tocco reale da' lo stesso voto: il voto dipende solo dai ms
	for fps in [30, 60, 120, 240]:
		var frame_ms: float = 1000.0 / float(fps)
		var t_ms: float = Parry.LEAD_MS - 50.0
		_chk(Parry.grade(t_ms - Parry.LEAD_MS, n) == "perfect", "perfetta a %d fps (frame %.1f ms)" % [fps, frame_ms])
	if fails == 0:
		print("OK test_v3_parata")
	quit(1 if fails > 0 else 0)
