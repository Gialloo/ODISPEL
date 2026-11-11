extends SceneTree
## Prova 0.9: nemico caduto fuori torna in campo, il cerchio centrale fa partire l'ondata
## anche con nemici bloccati lontano, le combo danno punti.
var main
var t := 0.0
var run
var pl
var phase := 0
var mark := 0.0
var w0 := 0
var log := []

func _initialize():
	main = load("res://scenes/main.tscn").instantiate()
	main.set_meta("bot", true)
	root.add_child(main)

func _enemies() -> Array:
	return main.get_tree().get_nodes_in_group("enemies")

func _process(d) -> bool:
	t += d
	if run == null:
		run = root.get_node("Run")
		pl = main.player
		return false
	pl.hp = pl.max_hp
	match phase:
		0:
			if _enemies().size() > 0:
				var e = _enemies()[0]
				e.global_position = Vector3(40, -20, 0)
				mark = t
				phase = 1
			elif t > 8.0:
				log.append("nessun nemico entrato")
				phase = 9
		1:
			if t - mark > 0.3:
				var lost := 0
				for e in _enemies():
					if e.global_position.y < -4.0 or Vector2(e.global_position.x, e.global_position.z).length() > 27.5:
						lost += 1
				log.append("recupero fuori mappa: %s" % ("ok" if lost == 0 else "NO"))
				phase = 2
		2:
			# nemici bloccati lontano: fermi, a 20 m; il giocatore resta al centro
			for e in _enemies():
				e.set_physics_process(false)
				e.global_position = Vector3(20, 0.2, 0)
			pl.global_position = Vector3(0, 0.2, 0)
			pl.velocity = Vector3.ZERO
			if mark < 100.0:
				w0 = run.wave
				mark = t + 100.0
			if run.choosing:
				run.choose(0)
			if run.wave > w0:
				log.append("cerchio: ondata %d -> %d dopo %.1f s" % [w0, run.wave, t - (mark - 100.0)])
				phase = 3
			elif t - (mark - 100.0) > 9.0:
				log.append("cerchio: NON partita (circle_t %.1f, vivi %d)" % [run.circle_t, run.alive])
				phase = 3
		3:
			var s0: int = run.score
			for i in 8:
				run.combo_hit()
			mark = t
			w0 = s0
			phase = 4
		4:
			if t - mark > 3.0:
				log.append("combo 8 colpi: +%d punti, combo incassate %d" % [run.score - w0, run.combos])
				phase = 9
		9:
			for l in log:
				print("RISULTATO ", l)
			return true
	return t > 40.0
