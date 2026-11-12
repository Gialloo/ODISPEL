extends SceneTree
## Prova 0.16: barre di vita dei nemici. Il rosso segue i danni, il bianco resta durante i colpi di fila e poi scende.
var main
var t := 0.0
var run
var e
var phase := 0
var mark := 0.0
var shots := ""
var log := []

func _initialize():
	shots = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	main = load("res://scenes/main.tscn").instantiate()
	main.set_meta("bot", true)
	root.add_child(main)

func _hit():
	e.receive_hit({"dmg": 9.0, "poise": 1.0, "dir": Vector3.FORWARD, "knock": 0.0, "launch": 0.0, "form": 0, "move": "test"})

func _process(d) -> bool:
	t += d
	if run == null:
		run = root.get_node("Run")
		return false
	if run.choosing:
		run.choose(0)
	main.player.hp = main.player.max_hp
	match phase:
		0:
			if t > 2.0:
				for x in main.get_tree().get_nodes_in_group("enemies"):
					if e == null:
						e = x
				if e:
					e.tune = e.tune.duplicate()
					e.tune["damage"] = 0.0
					main.player.global_position = e.global_position + Vector3(0, 0, 5)
					phase = 1
					mark = t
		1:
			# 4 colpi a 0,25 s l'uno dall'altro
			var n := int((t - mark) / 0.25)
			if n < 4 and e.get_meta("n", 0) <= n:
				e.set_meta("n", n + 1)
				_hit()
			if t - mark > 0.95 and phase == 1:
				log.append("dopo 4 colpi di fila: rosso %.0f  bianco %.0f  (max %.0f)" % [e.hp, e.hp_white, e.max_hp])
				if shots != "":
					root.get_viewport().get_texture().get_image().save_png(shots + "/barre_colpi.png")
				phase = 2
				mark = t
		2:
			if t - mark > 1.6:
				log.append("1,6 s dopo: rosso %.0f  bianco %.0f" % [e.hp, e.hp_white])
				log.append("barre disegnate: %s" % (main.hud.enemy_bars != null))
				if shots != "":
					root.get_viewport().get_texture().get_image().save_png(shots + "/barre_dopo.png")
				for l in log:
					print("RISULTATO ", l)
				return true
	return t > 30.0
