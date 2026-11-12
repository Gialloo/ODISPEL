extends SceneTree
## Prova 0.15: all'ondata 5 arriva il COLOSSO, la barra in alto si vede, l'onda d'urto colpisce chi sta a terra, abbatterlo cura.
var main
var t := 0.0
var run
var pl
var phase := 0
var mark := 0.0
var boss
var log := []
var _last_hp := 100.0
var shots := ""

func _initialize():
	shots = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	main = load("res://scenes/main.tscn").instantiate()
	main.set_meta("bot", true)
	root.add_child(main)

func _process(d) -> bool:
	t += d
	if run == null:
		run = root.get_node("Run")
		pl = main.player
		return false
	if run.choosing:
		run.choose(0)
	match phase:
		0:
			if t > 1.0:
				run.wave = 4
				run.force_next_wave()
				mark = t
				phase = 1
		1:
			boss = main.get_tree().get_first_node_in_group("boss")
			if boss:
				log.append("ondata %d tema %s: colosso vita %d, postura %d" % [run.wave, run.theme, boss.max_hp, boss.max_poise])
				mark = t
				phase = 2
			elif t - mark > 6.0:
				log.append("NESSUN colosso (ondata %d, tema %s)" % [run.wave, run.theme])
				phase = 9
		2:
			pl.hp = pl.max_hp
			if t - mark > 2.5:
				log.append("barra boss visibile: %s" % main.hud._boss_box.visible)
				for e in main.get_tree().get_nodes_in_group("enemies"):
					if e != boss:
						e.remove_from_group("enemies")
						e.queue_free()
				pl.global_position = boss.global_position + Vector3(0, 0, 7)
				mark = t
				phase = 3
		3:
			if pl.hp < _last_hp:
				log.append("  colpo da %d a %.1f s" % [int(_last_hp - pl.hp), t - mark])
			_last_hp = pl.hp
			# lasciamolo attaccare: il giocatore resta fermo a 6 m
			pl.velocity = Vector3.ZERO
			if shots != "" and t - mark > 1.2 and t - mark < 1.25 + d:
				root.get_viewport().get_texture().get_image().save_png(shots)
			if t - mark > 6.0:
				log.append("vita persa restando a terra in 6 s: %d" % int(pl.max_hp - pl.hp))
				pl.hp = 40.0
				var s0: int = run.score
				mark = s0
				for i in 60:
					if boss.is_dead():
						break
					boss.receive_hit({"dmg": 60.0, "poise": 5.0, "dir": Vector3.FORWARD, "knock": 0.0, "launch": 0.0, "form": 0, "move": "test"})
				phase = 4
				t = 0.0
		4:
			if t > 1.5:
				log.append("abbattuto: %s, vita dopo %d, punti +%d" % [boss == null or not is_instance_valid(boss) or boss.is_dead(), int(pl.hp), run.score - int(mark)])
				phase = 9
		9:
			for l in log:
				print("RISULTATO ", l)
			return true
	return t > 60.0
