extends SceneTree

# COMBO D'ATTACCO (13/11): colpo×3 + verso = SFONDAMENTO; colpo + giù = FALCIATA, poi su = lancio dal nemico a terra.
const E = preload("res://scripts/prova_grezza/pg_engine.gd")

var fails: int = 0


func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _steps(e: PgEngine, n: int) -> void:
	for _i in n:
		e.step(E.TICK)


func _initialize() -> void:
	for ps in [1, 4]:
		# SFONDAMENTO
		var e := E.new(3, ps)
		e.px = 5.6
		e.idle_wait = 99.0
		for _k in 3:
			e.input("tocco")
			_steps(e, 9)
		e.take_events()
		e.input("verso")
		_steps(e, 20)
		var ids: Array = []
		for x in e.take_events():
			if x["type"] == "mossa":
				ids.append(x["id"])
		check(ids.has("sfondamento"), "party %d: colpo×3 + verso = SFONDAMENTO %s" % [ps, ids])
		check(e.found.has("sfondamento"), "party %d: Registro SFONDAMENTO" % ps)
		# con un solo colpo il verso resta un AFFONDO
		e = E.new(3, ps)
		e.px = 5.6
		e.idle_wait = 99.0
		e.input("tocco")
		_steps(e, 9)
		e.input("verso")
		_steps(e, 20)
		check(not e.found.has("sfondamento"), "party %d: un colpo solo non basta per lo SFONDAMENTO" % ps)
		# FALCIATA e lancio
		e = E.new(3, ps)
		e.px = 5.6
		e.idle_wait = 99.0
		e.input("tocco")
		_steps(e, 9)
		e.input("giu")
		_steps(e, 14)
		check(e.found.has("falciata") and e.est == "down", "party %d: colpo + giù = FALCIATA, nemico a terra (%s)" % [ps, e.est])
		e.px = e.ex - 1.2
		_steps(e, 12)
		e.input("su")
		_steps(e, 14)
		check(e.est == "air", "party %d: dalla FALCIATA il lancio (%s)" % [ps, e.est])
	print("pg_combo: " + ("OK" if fails == 0 else "%d FAIL" % fails))
	quit(0 if fails == 0 else 1)
