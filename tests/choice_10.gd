extends SceneTree
## Prova 0.10: la schermata dei potenziamenti si chiude sempre dopo la scelta,
## anche se si apre due volte di fila; 24 potenziamenti caricati.
var main
var t := 0.0
var run
var phase := 0
var log := []

func _initialize():
	main = load("res://scenes/main.tscn").instantiate()
	main.set_meta("bot", true)
	root.add_child(main)

func _process(d) -> bool:
	t += d
	if run == null:
		run = root.get_node("Run")
		return false
	match phase:
		0:
			if t > 1.0:
				log.append("potenziamenti %d" % run.defs.size())
				run._open_choice()
				run.choice_open.emit(run.options)   # seconda apertura di fila (il caso del blocco)
				phase = 1
		1:
			if t > 1.5:
				main.hud._pick(1)
				phase = 2
		2:
			if t > 2.0:
				var left: int = 0
				for c in main.hud.get_children():
					if c is Control and c.process_mode == Node.PROCESS_MODE_ALWAYS and c != main.hud.touch and c.get_child_count() > 1 and c.get_child(0) is ColorRect:
						left += 1
				log.append("schermate rimaste %d, pausa %s, scelta aperta %s" % [left, str(paused), str(run.choosing)])
				for l in log:
					print("RISULTATO ", l)
				return true
	return t > 10.0
