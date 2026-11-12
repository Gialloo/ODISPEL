extends SceneTree
## Prova 0.17: TRALICCIO. Sfera rimandata = gran colpo all'equilibrio; addosso troppo a lungo = impulso e sparisce.
var main
var t := 0.0
var run
var pl
var boss
var phase := 0
var mark := 0.0
var p0 := 0.0
var log := []

func _initialize():
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
				run.wave = 9
				run.force_next_wave()
				phase = 1
		1:
			boss = main.get_tree().get_first_node_in_group("boss")
			if boss:
				for e in main.get_tree().get_nodes_in_group("enemies"):
					if e != boss:
						e.remove_from_group("enemies")
						e.queue_free()
				p0 = boss.poise
				var o = load("res://scripts/enemies/orb.gd").new()
				main.add_child(o)
				o.fire(boss.global_position + Vector3(0, 0.9, 6), boss.global_position + Vector3(0, 0.9, 0), boss, 10.0)
				o.reflect(pl)
				mark = t
				phase = 2
		2:
			if t - mark > 1.2:
				log.append("sfera rimandata: postura %.0f -> %.0f, stato %d (7 = barcolla), colpi di ritorno %d" % [p0, boss.poise, boss.state, root.get_node("FX").stats.get("boss_backfires", 0)])
				mark = t
				phase = 3
		3:
			pl.hp = pl.max_hp
			pl.global_position = boss.global_position + Vector3(0, 0, 2.0)
			pl.velocity = Vector3.ZERO
			if root.get_node("FX").stats.get("boss_blinks", 0) > 0 or t - mark > 9.0:
				log.append("impulso e sparizione dopo %.1f s: %d, distanza ora %.1f m" % [t - mark, root.get_node("FX").stats.get("boss_blinks", 0), boss.global_position.distance_to(pl.global_position)])
				for l in log:
					print("RISULTATO ", l)
				return true
	return t > 40.0
