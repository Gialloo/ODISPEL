extends SceneTree
## Prova delle mosse 0.7 e del triplo salto: condizioni preparate, sistemi veri.
var main
var t := 0.0
var step := 0
var pl
var e
var fx
var pad
var log := []

func _initialize():
	main = load("res://scenes/main.tscn").instantiate()
	main.set_meta("bot", true)
	root.add_child(main)

func _enemy(at: Vector3):
	if e and is_instance_valid(e):
		e.queue_free()
	e = load("res://scripts/enemies/enemy.gd").new()
	e.setup("scout", 1)
	e.player = pl
	e.tune = main.enemy_tune
	e.max_hp = 9999
	e.position = at
	main.enemies.add_child(e)

## Stick che punta di lato rispetto al nemico, tenendo conto della telecamera.
func _side_stick() -> Vector2:
	var to: Vector3 = e.global_position - pl.global_position
	to.y = 0
	var dir := Vector3(-to.z, 0, to.x).normalized()
	var yaw: float = main.cam.get_yaw()
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	return Vector2(dir.dot(right), dir.dot(fwd))

func _process(d) -> bool:
	t += d
	if fx == null:
		fx = root.get_node("FX")
		pad = root.get_node("Pad")
		root.get_node("Run").running = false
		pl = main.player
	var s = int(t / 0.3)
	if s != step:
		step = s
		var p0: Vector3 = pl.global_position
		match step:
			3, 4:
				pad.press("jump"); pad.release("jump")
			5:
				pad.press("jump"); pad.release("jump")
			6:
				log.append("salti=%d" % pl._jumps)
			12:
				# corsa + leggero = blade_dash
				_enemy(p0 + Vector3(0, 0, -3))
				pl.facing = Vector3(0, 0, -1)
				pl.velocity = Vector3(0, 0, -pl.tune.run_speed)
				log.append("corsa leggero -> " + pl._pick_move("light", true))
				log.append("corsa pesante -> " + pl._pick_move("heavy", true))
				pl._start_move("impact_hammer", Time.get_ticks_msec())
			16:
				_enemy(p0 + Vector3(0, 0, -2))
				pl._start_move("blade_1", Time.get_ticks_msec())
				pad.move = _side_stick()
				pl.move_t = pl.move.cancel
				log.append("combo + stick di lato -> " + pl._pick_move("light", true))
				pl._start_move("blade_spin", Time.get_ticks_msec())
			19:
				_enemy(pl.global_position + pl.facing * 2.0)
				pl._start_move("blade_3", Time.get_ticks_msec())
				pad.move = _side_stick()
				pl.move_t = pl.move.cancel
				log.append("dopo blade_3 + lato -> " + pl._pick_move("light", true))
				pl._start_move("impact_breaker", Time.get_ticks_msec())
				pad.move = Vector2.ZERO
			22:
				_enemy(p0 + Vector3(0, 0, -2))
				pl._start_move("vector_sweep", Time.get_ticks_msec())
				pl.move_t = pl.move.cancel
				log.append("dopo spazzata -> " + pl._pick_move("light", true))
				pl._start_move("vector_whirl", Time.get_ticks_msec())
			25:
				_enemy(p0 + Vector3(0, 2.5, -7))
				pl.velocity.y = 9.0
			26:
				log.append("in aria, nemico a %.1f -> %s" % [pl.global_position.distance_to(e.global_position), pl._pick_move("light", true)])
				pl._start_move("vector_zip", Time.get_ticks_msec())
			30:
				var keys := ["triple_jumps", "double_jumps", "move_blade_dash", "move_blade_spin", "move_impact_breaker", "move_impact_hammer", "move_vector_whirl", "move_vector_zip", "hits"]
				for k in keys:
					log.append("%s=%s" % [k, fx.stats.get(k, 0)])
				print("MOVES07 " + " | ".join(log))
				return true
	return false
