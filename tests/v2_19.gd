extends SceneTree
## 0.19 Combat System v2, fasi 3-7: finestra precisa, marche dei poteri, firme di tecnica,
## counter-hit, schiacciata, nemico bagnato, potenziamenti di stile. Condizioni preparate a mano.
var main
var t := 0.0
var step := -1
var pl
var run
var fx
var el
var ok := true
var log := []
var e
var e2
var hp0 := 0.0

func _initialize():
	main = load("res://scenes/main.tscn").instantiate()
	main.set_meta("bot", true)
	root.add_child(main)

func _check(name: String, got, want) -> void:
	var pass_: bool = got == want
	if not pass_:
		ok = false
	log.append("%s %s=%s" % ["OK" if pass_ else "NO", name, str(got)])

func _enemy(at: Vector3, arch := "scout"):
	var x = load("res://scripts/enemies/enemy.gd").new()
	x.setup(arch, 1)
	x.player = pl
	x.tune = main.enemy_tune
	x.max_hp = 9999
	x.hp = 9999
	x.dummy = true
	x.home = at
	x.position = at
	main.enemies.add_child(x)
	return x

func _hit(x, form := 0, move := "blade_1", poise := 10.0) -> void:
	x.receive_hit({"dmg": 5.0, "poise": poise, "dir": Vector3.FORWARD, "knock": 0.5, "launch": 0.0, "form": form, "move": move})

func _st(k: String) -> int:
	return int(fx.stats.get(k, 0))

func _process(d) -> bool:
	t += d
	if fx == null:
		fx = root.get_node("FX")
		run = root.get_node("Run")
		el = root.get_node("El")
		run.running = false
		pl = main.player
	var s := int(t / 0.25)
	if s == step:
		return false
	step = s
	var p0 := Vector3(0, 0.2, 6)
	match step:
		4:
			for x in main.enemies.get_children():
				x.queue_free()
			fx.stats.clear()
			pl.global_position = p0
			e = _enemy(p0 + Vector3(0, 0, -1.6))
			pl.lock_target = e
			# finestra precisa: premuto subito dopo la fine del colpo a segno -> parte subito, +10%
			pl._start_move("blade_1", Time.get_ticks_msec())
			pl._hit_any = true
			pl.move_t = pl.move.hit_to + 0.03
			pl._request("light", Time.get_ticks_msec())
			_check("preciso_parte_subito", pl.move_id, "blade_2")
			_check("preciso", pl._precise, true)
			# premuto prima della fine del colpo: resta in coda e NON è preciso
			pl._start_move("blade_1", Time.get_ticks_msec())
			pl._hit_any = true
			pl.move_t = pl.move.hit_to - 0.05
			pl._request("light", Time.get_ticks_msec())
			_check("in_anticipo_resta", pl.move_id, "blade_1")
			pl.move_t = pl._chain_t()
			pl._try_buffer(Time.get_ticks_msec())
			_check("in_anticipo_non_preciso", pl._precise, false)
			_check("stat_precise", _st("precise"), 1)
			pl.state = pl.S.MOVE
			pl._buffer = ""
		6:
			# Aggancio: ATTIRA poi colpo dell'arma entro 0,8 s
			e.power_pull(pl.global_position + Vector3(0, 0, -1.8))
			_hit(e)
			_check("aggancio", _st("catch"), 1)
			_check("scoperto_a_lungo", e._t <= -0.3, true)
			_hit(e)
			_check("aggancio_una_volta", _st("catch"), 1)
			# Rimbalzo: sbattuto, poi colpo -> postura ×2
			e._set_mark("slammed", 1200)
			var p_before: float = e.poise
			_hit(e, 0, "blade_1", 4.0)
			_check("rimbalzo", _st("rebound"), 1)
			_check("rimbalzo_postura", int(round(p_before - e.poise)), 8)
			# Counter-hit: IMPACT su un nemico che carica
			e._set_state(e.S.WINDUP)
			_hit(e, 1, "impact_launcher", 10.0)
			_check("counter_hit", _st("counter_hit"), 1)
			# Detonazione: SOVRACCARICA e colpo IMPACT
			e.charge()
			_hit(e, 1, "impact_finisher")
			_check("detonazione", _st("detonate"), 1)
		8:
			# Schiacciata: IMPACT dall'alto su un nemico in aria, onda all'arrivo
			for x in main.enemies.get_children():
				x.queue_free()
			e = _enemy(Vector3(-4, 3.0, 2))
			e2 = _enemy(Vector3(-4, 0.2, 3.5))
			e._set_state(e.S.AIR)
			e.receive_hit({"dmg": 5.0, "poise": 10.0, "dir": Vector3.FORWARD, "knock": 0.0, "launch": 4.0, "form": 1, "move": "impact_slam"})
			_check("schiacciata", _st("spikes"), 1)
		12:
			_check("onda_schiacciata", _st("spike_hits") >= 1, true)
			# Bagnato: entra nella pozza (12,0,-4), esce, la scossa lo prende più forte
			e.global_position = Vector3(12, 0.2, -4)
			e.home = e.global_position
		14:
			_check("bagnato", e.is_wet(), true)
			e.global_position = Vector3(12, 0.2, 2.0)
			e.home = e.global_position
		15:
			_check("ancora_bagnato", e.is_wet(), true)
			hp0 = e.hp
			el.shock(Vector3(12, 0.5, 5.5), null, 1.0)
			_check("scossa_bagnato", int(round(hp0 - e.hp)), int(round(el.tune.shock_dmg * 1.5)))
			_check("stat_wet_shocks", _st("wet_shocks"), 1)
			# firma CATENA D'AMBIENTE: due reazioni d'ambiente diverse entro 3 s
			var before := _st("env_chain")
			fx.stat("wall_slams")
			fx.stat("barrels_exploded")
			_check("catena_ambiente", _st("env_chain") - before, 1)
		16:
			# TRE FORME nella stessa catena: BLADE -> IMPACT (ramo pesante) -> VECTOR
			for x in main.enemies.get_children():
				x.queue_free()
			pl.state = pl.S.MOVE
			pl._last_move_id = ""
			pl._last_move_end = -100000
			pl.global_position = p0
			pl.velocity = Vector3.ZERO
			var before := _st("tri_form")
			for id in ["blade_1", "impact_launcher", "vector_reel"]:
				e = _enemy(p0 + Vector3(0, 0, -1.4))
				pl.lock_target = e
				pl._start_move(id, Time.get_ticks_msec())
				pl._do_hits(false)
				e.queue_free()
			_check("tre_forme", _st("tri_form") - before, 1)
			pl.state = pl.S.MOVE
		18:
			# Contro-presa: schivata e subito ATTIRA -> il leggero dopo è il contrattacco ridotto
			pl._last_dodge_end = Time.get_ticks_msec() - 100
			_check("contro_presa_pronta", pl.on_power_pull(), true)
			_check("contro_presa_mossa", pl._pick_move("light"), "impact_counter")
			_check("contro_presa_ogni_3s", pl.on_power_pull(), false)
			pl._grab_until = 0
			pl._grab_move = false
			# Corazza viva: colpito mentre carichi IMPACT, il colpo continua
			run.owned = ["corazza_viva"]
			pl.hp = pl.max_hp
			pl._start_move("impact_launcher", Time.get_ticks_msec())
			pl.move_t = 0.05
			pl.take_hit(pl, 10.0, Vector3.FORWARD)
			_check("corazza_viva_resta", pl.state == pl.S.ATTACK and pl.move_id == "impact_launcher", true)
			_check("corazza_viva_danno", int(pl.hp), int(pl.max_hp - 10.0))
			pl.state = pl.S.MOVE
			# Seconda guardia: dopo una parata la BLADE para il doppio
			run.owned = ["seconda_guardia"]
			pl.parry(null, 0.0, true)
			pl._start_move("blade_1", Time.get_ticks_msec())
			pl.move_t = pl.tune.parry_window * 1.6
			_check("seconda_guardia", pl.can_parry(null), true)
			pl._start_move("blade_2", Time.get_ticks_msec())
			pl.move_t = pl.tune.parry_window * 1.6
			_check("guardia_una_volta", pl.can_parry(null), false)
			pl.state = pl.S.MOVE
		20:
			# Scambio: stick verso un nemico lontano = scambi di posto, poi affondo
			run.owned = ["scambio"]
			pl.state = pl.S.MOVE
			pl._last_move_id = ""
			pl.global_position = p0
			e = _enemy(p0 + Vector3(0, 0, -7))
			pl.lock_target = e
			var yaw: float = main.cam.get_yaw()
			var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
			var right := Vector3(cos(yaw), 0, -sin(yaw))
			root.get_node("Pad").move = Vector2(Vector3(0, 0, -1).dot(right), Vector3(0, 0, -1).dot(fwd))
			var m: String = pl._pick_move("light")
			pl._start_move(m, Time.get_ticks_msec())
			root.get_node("Pad").move = Vector2.ZERO
			_check("scambio_mossa", m, "blade_dash")
			_check("scambio_posto", pl.global_position.z < 0.0 and e.global_position.z > 4.0, true)
			pl.state = pl.S.MOVE
			# Sospensione: in aria 5 colpi prima del finale
			run.owned = ["sospensione"]
			pl._air_attacks = 3
			pl.global_position = Vector3(0, 4, 6)
			pl.velocity = Vector3(0, 6, 0)
		21:
			pl.lock_target = null
			for x in main.enemies.get_children():
				x.queue_free()
			_check("sospensione", pl._pick_move("light", true), "blade_air_1")
			# scelta legata allo stile: con Sospensione presa, un'opzione «aerial» tra le tre
			run.owned = ["sospensione"]
			run._open_choice()
			var tagged := false
			for o in run.options:
				if o.get("tags", []).has("aerial"):
					tagged = true
			run.choosing = false
			paused = false
			_check("scelta_stile", tagged, true)
			_check("potenziamenti", run.defs.size(), 30)
			# Orbita: l'oggetto tenuto gira attorno al giocatore
			run.owned = ["orbita"]
			pl.state = pl.S.MOVE
			pl.global_position = p0
			pl.velocity = Vector3.ZERO
			for pr in get_nodes_in_group("props"):
				if pr.kind == "light" and not pr.is_dead():
					main.power.held = pr
					pr.hold(p0 + Vector3(0, 2, 0))
					break
		24:
			var h = main.power.held
			var dd: Vector3 = h.global_position - pl.global_position
			dd.y = 0
			_check("orbita", dd.length() > 1.2 and dd.length() < 2.6, true)
			main.power.held.release_hold()
			main.power.held = null
			run.owned = []
		25:
			print(("V2_19 PASS " if ok else "V2_19 FAIL ") + " | ".join(log))
			return true
	return false
