extends SceneTree
## Prova del parry 0.8: colpo BLADE al momento giusto contro l'affondo di uno Scout,
## lo schianto di un Brute e la sfera di un Conduit.
var main
var t := 0.0
var pl
var fx
var pad
var e
var phase := 0
var log := []
var hp0 := 0.0
var fired := false

func _initialize():
	main = load("res://scenes/main.tscn").instantiate()
	main.set_meta("bot", true)
	root.add_child(main)

func _spawn(arch: String, at: Vector3):
	e = load("res://scripts/enemies/enemy.gd").new()
	e.setup(arch, 1)
	e.player = pl
	e.tune = main.enemy_tune
	e.position = at
	main.enemies.add_child(e)
	fired = false
	hp0 = pl.hp

func _process(d) -> bool:
	t += d
	if fx == null:
		fx = root.get_node("FX")
		pad = root.get_node("Pad")
		root.get_node("Run").running = false
		pl = main.player
		return false
	pad.release("attack")
	match phase:
		0:
			_spawn("scout", pl.global_position + Vector3(0, 0, -3))
			phase = 1
		1, 3:
			# premi ATTACCO poco prima che l'attacco arrivi
			var close: bool = e.state == 3
			if e.arch == "brute":
				close = e.state == 2 and e._t >= e._tv("windup") - 0.1
			if e.state == 1:
				fired = false
			if not fired and close:
				pl.facing = (e.global_position - pl.global_position).normalized()
				pad.press("attack")
				fired = true
			if fired and e.state == 7:
				log.append("%s: parry ok, vita persa %.0f" % [e.arch, hp0 - pl.hp])
				e.queue_free()
				phase += 1
			elif t > 12.0 * (phase + 1) / 2.0 + 6.0:
				log.append("%s: parry NON riuscito (stato %d)" % [e.arch, e.state])
				e.queue_free()
				phase += 1
		2:
			_spawn("brute", pl.global_position + Vector3(0, 0, -2.5))
			phase = 3
		4:
			_spawn("conduit", pl.global_position + Vector3(0, 0, -8))
			phase = 5
		5:
			for o in get_nodes_in_group("orbs"):
				if not o.reflected and not fired and o.global_position.distance_to(pl.global_position + Vector3(0, 0.9, 0)) < 2.2:
					pl.facing = (o.global_position - pl.global_position).normalized()
					pl.facing.y = 0
					pl.facing = pl.facing.normalized()
					pad.press("attack")
					fired = true
			if fx.stats.get("orbs_reflected", 0) > 0 and fired:
				log.append("conduit: sfera rimandata, vita persa %.0f" % (hp0 - pl.hp))
				phase = 6
			elif t > 40.0:
				log.append("conduit: parry della sfera NON riuscito")
				phase = 6
		6:
			log.append("parries=%s" % fx.stats.get("parries", 0))
			print("PARRY08 " + " | ".join(log))
			return true
	return false
