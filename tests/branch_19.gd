extends SceneTree
## 0.19 Combat System v2, fasi 0-2: tabella delle diramazioni, pesante nella catena,
## IMPACT -> VECTOR (recupero a 9 m), limite di 2 ripetizioni, stick avanti = lama in scatto,
## e l'Allenamento con i manichini. Condizioni preparate a mano, sistemi veri.
var main
var t := 0.0
var step := -1
var pl
var e
var pad
var fx
var ok := true
var log := []

func _initialize():
	main = load("res://scenes/main.tscn").instantiate()
	main.set_meta("bot", true)
	root.add_child(main)

func _check(name: String, got, want) -> void:
	var pass_: bool = got == want
	if not pass_:
		ok = false
	log.append("%s %s=%s" % ["OK" if pass_ else "NO", name, str(got)])

func _enemy(at: Vector3):
	if e and is_instance_valid(e):
		e.queue_free()
	e = load("res://scripts/enemies/enemy.gd").new()
	e.setup("scout", 1)
	e.player = pl
	e.tune = main.enemy_tune
	e.max_hp = 9999
	e.hp = 9999
	e.dummy = true
	e.home = at
	e.position = at
	main.enemies.add_child(e)
	pl.lock_target = e

## Stick che punta in una direzione del mondo, tenendo conto della telecamera.
func _stick(dir: Vector3) -> Vector2:
	dir.y = 0
	dir = dir.normalized()
	var yaw: float = main.cam.get_yaw()
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	return Vector2(dir.dot(right), dir.dot(fwd))

func _to_e() -> Vector3:
	var v: Vector3 = e.global_position - pl.global_position
	v.y = 0
	return v

## Mette il giocatore dentro una mossa, a fine colpo (finestra di catena aperta).
func _in_move(id: String) -> void:
	pl._start_move(id, Time.get_ticks_msec())
	pl.move_t = pl._chain_t()

func _process(d) -> bool:
	t += d
	if fx == null:
		fx = root.get_node("FX")
		pad = root.get_node("Pad")
		root.get_node("Run").running = false
		pl = main.player
	var s := int(t / 0.25)
	if s == step:
		return false
	step = s
	var p0: Vector3 = Vector3(0, 0.2, 6)
	match step:
		4:
			pl.global_position = p0
			pl.velocity = Vector3.ZERO
			_enemy(p0 + Vector3(0, 0, -2))
			# regressione: le varianti di sempre ora vengono dalla tabella
			_in_move("blade_1")
			pad.move = _stick(Vector3(1, 0, 0))
			_check("blade_1+lato", pl._pick_move("light", true), "blade_spin")
			_in_move("blade_3")
			_check("blade_3+lato", pl._pick_move("light", true), "impact_breaker")
			pad.move = Vector2.ZERO
			_in_move("blade_2")
			_check("blade_2+L", pl._pick_move("light", true), "blade_3")
			_in_move("blade_3")
			_check("blade_3+L", pl._pick_move("light", true), "impact_finisher")
			# pesante nella catena: IMPACT che resta nella catena
			pl._chain_ids.clear()
			_in_move("blade_2")
			var h: String = pl._pick_move("heavy")
			_check("blade_2+pesante", h, "impact_launcher")
			pl._start_move(h, Time.get_ticks_msec())
			_check("catena", str(pl._chain_ids), str(["blade_2", "impact_launcher"]))
			_check("da_ramo", pl._from_branch, true)
		6:
			# IMPACT -> VECTOR: il nemico è volato a 8 m, stick indietro + leggero
			pl.state = pl.S.MOVE
			pl._chain_ids.clear()
			pl.global_position = p0
			_enemy(p0 + Vector3(0, 0, -8))
			_in_move("impact_finisher")
			pad.move = _stick(-_to_e())
			var r: String = pl._pick_move("light")
			_check("finale+indietro", r, "vector_reel")
			pl._start_move(r, Time.get_ticks_msec())
			pad.move = Vector2.ZERO
			_check("reel_da_ramo", pl._from_branch, true)
		9:
			# dopo il recupero il nemico è a portata di lama
			var dist: float = _to_e().length()
			log.append("distanza dopo il recupero %.1f" % dist)
			if dist > 2.5:
				ok = false
				log.append("NO recupero")
			# senza ramo (stick neutro) a 8 m resta la frusta automatica
			pl.state = pl.S.MOVE
			pl._last_move_id = ""
			pl.global_position = p0
			_enemy(p0 + Vector3(0, 0, -8))
			_in_move("impact_finisher")
			_check("finale+neutro", pl._pick_move("light", true), "vector_lash")
			# limite: la terza volta lo stesso ramo non scatta
			pl._chain_ids = ["vector_reel", "vector_reel", "impact_finisher"]
			pad.move = _stick(-_to_e())
			_check("terzo_recupero", pl._pick_move("light", true) != "vector_reel", true)
			pad.move = Vector2.ZERO
			# stick avanti verso un nemico lontano: lama in scatto invece della frusta
			pl.state = pl.S.MOVE
			pl._last_move_id = ""
			pl._last_move_end = -100000
			pl._chain_ids.clear()
			pl.velocity = Vector3.ZERO
			_check("lontano+neutro", pl._pick_move("light", true), "vector_lash")
			pad.move = _stick(_to_e())
			_check("lontano+avanti", pl._pick_move("light", true), "blade_dash")
			pad.move = Vector2.ZERO
		11:
			# ALLENAMENTO: tre manichini, non attaccano, tornano quando cadono
			main.restart(true)
			pad.move = Vector2.ZERO
		12:
			var run = root.get_node("Run")
			_check("allenamento", run.training, true)
			_check("manichini", get_nodes_in_group("enemies").size(), 3)
		20:
			_check("vita_piena", main.player.hp >= main.player.max_hp - 0.5, true)
			for en in get_nodes_in_group("enemies"):
				if en.arch == "scout":
					en.receive_hit({"dmg": 9999.0, "poise": 999.0, "dir": Vector3.FORWARD, "knock": 1.0, "launch": 0.0, "form": 0, "move": "test"})
		22:
			_check("caduto", get_nodes_in_group("enemies").size(), 2)
		30:
			_check("tornato", get_nodes_in_group("enemies").size(), 3)
			var keys := ["branch_impact_launcher", "branch_vector_reel", "player_hits_taken", "spawn_scout"]
			for k in keys:
				log.append("%s=%s" % [k, fx.stats.get(k, 0)])
			print(("BRANCH19 PASS " if ok else "BRANCH19 FAIL ") + " | ".join(log))
			return true
	return false
