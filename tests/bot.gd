extends SceneTree
## Bot che gioca da solo: controlla che non ci siano errori, che tutte le mosse
## e le tre forme vengano usate, misura gli fps e salva qualche schermata.
## Uso: godot --path . -s tests/bot.gd -- [secondi] [cartella_schermate]

var main: Node
var pad: Node
var fx: Node
var secs := 40.0
var shots_dir := ""
var t := 0.0
var _phase := 0.0
var _plan := "approach"
var _plan_t := 0.0
var _frames := 0
var _slow_frames := 0
var _fps_samples: Array = []
var _next_shot := 3.0
var _shot_n := 0
var _scene_i := 0
const SCENES := [10.0, 22.0, 34.0, 46.0]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		secs = float(args[0])
	if args.size() > 1:
		shots_dir = args[1]
	main = load("res://scenes/main.tscn").instantiate()
	main.set_meta("bot", true)
	root.add_child(main)

func _process(delta: float) -> bool:
	if pad == null:
		pad = root.get_node_or_null("Pad")
		fx = root.get_node_or_null("FX")
		if pad == null:
			return false
	t += delta
	_frames += 1
	if t > 2.0:
		var fps := Engine.get_frames_per_second()
		_fps_samples.append(fps)
	_drive(delta)
	if _scene_i < SCENES.size() and t >= SCENES[_scene_i]:
		if _scenario(_scene_i):
			_scene_i += 1
	if shots_dir != "" and t >= _next_shot:
		_next_shot += 5.0
		_shot_n += 1
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("%s/bot_%02d.png" % [shots_dir, _shot_n])
	if t >= secs:
		_report()
		return true
	return false

## Scenari della Fase 3: preparano la situazione e lasciano agire i sistemi veri.
func _scenario(i: int) -> bool:
	var es: Array = main.enemies.get_children().filter(func(e): return not e.is_dead())
	if es.is_empty():
		return false
	var e = es[0]
	var props: Array = root.get_tree().get_nodes_in_group("props")
	var of_kind := func(k: String) -> Array:
		return props.filter(func(p): return p.kind == k and not p.is_dead())
	match i:
		0:
			# nemico nella pozza, il giocatore colpisce la bobina
			var coil = of_kind.call("coil")[0]
			e.global_position = Vector3(9, 0.2, -5)
			coil.receive_hit({"dmg": 10.0, "poise": 0.0, "dir": Vector3.FORWARD, "knock": 1.0, "launch": 0.0, "form": 0, "move": "bot"})
			print("SCENA bobina+pozza")
		1:
			# bidone vicino al nemico: un colpo lo accende
			var b = of_kind.call("barrel")[0]
			e.global_position = b.global_position + Vector3(1.5, 0.2, 0)
			b.receive_hit({"dmg": 12.0, "poise": 0.0, "dir": Vector3.RIGHT, "knock": 0.5, "launch": 0.0, "form": 1, "move": "bot"})
			print("SCENA bidone")
		2:
			# muretto sfondato a colpi pesanti
			var c = of_kind.call("cover")[0]
			for k in 3:
				c.receive_hit({"dmg": 22.0, "poise": 0.0, "dir": Vector3.FORWARD, "knock": 2.0, "launch": 0.0, "form": 1, "move": "bot"})
			print("SCENA muretto")
		3:
			# cassa accesa lanciata contro il nemico
			var cr = of_kind.call("light")[0]
			cr.ignite()
			cr.global_position = e.global_position + Vector3(0, 1.0, 4.0)
			cr.launch(Vector3(0, 2.0, -20.0), main.player)
			print("SCENA cassa in fiamme state=%d burning=%.1f dist=%.1f" % [cr.state, cr.burning, cr.global_position.distance_to(e.global_position)])

	return true

func _press(a: String) -> void:
	pad.press(a)

func _release(a: String) -> void:
	pad.release(a)

func _drive(delta: float) -> void:
	var p = main.player
	var cam = main.cam
	var es: Array = main.enemies.get_children().filter(func(e): return not e.is_dead())
	for a in ["attack", "jump", "dodge", "lock"]:
		if a != "attack" or (_plan != "heavy" and not (_plan == "air" and fmod(_phase, 1.6) >= 0.9)):
			_release(a)
	if es.is_empty():
		pad.move = Vector2.ZERO
		return
	var e = es[0]
	var to: Vector3 = e.global_position - p.global_position
	to.y = 0
	var dist := to.length()
	# la telecamera guarda verso il nemico (come farebbe un giocatore)
	var want := atan2(-to.x, -to.z)
	cam.yaw = lerp_angle(cam.yaw, want, 0.15)
	# schivata quando il nemico sta per colpire
	if e.state == 2 and e._t >= e.tune.windup - 0.12 and dist < 4.0 and randf() < 0.6:
		pad.move = Vector2(1, 0)
		_press("dodge")
		return
	_plan_t -= delta
	if _plan_t <= 0:
		var r := randf()
		if dist > 6.0 and r < 0.25:
			_plan = "power"
		elif dist > 6.0 and r < 0.5:
			_plan = "lash"
		elif r < 0.45:
			_plan = "combo"
		elif r < 0.65:
			_plan = "heavy"
		elif r < 0.85:
			_plan = "air"
		elif r < 0.9:
			_plan = "reel"
		elif r < 0.99 or dist > 4.0:
			_plan = "power"
		else:
			_plan = "approach"
		_plan_t = 3.0 if _plan == "power" else randf_range(1.0, 2.2)
		_phase = 0.0
	_phase += delta
	match _plan:
		"power":
			pad.move = Vector2.ZERO
			var k := int(_phase / 0.5)
			if fmod(_phase, 0.5) < delta * 1.5:
				match k % 6:
					0: pad.tap("alter")
					1: pad.tap("pull")
					2: _press("attack")
					3: pad.tap("push")
					4: pad.tap("pull")
					5: pad.tap("push")
		"reel":
			pad.move = Vector2(0, -1)
			if dist > 2.6 and dist < 6.5 and fmod(_phase, 0.4) < delta * 1.5:
				_press("attack")
		"approach":
			pad.move = Vector2(0, 1) if dist > 2.0 else Vector2.ZERO
		"lash":
			if p.lock_target == null:
				_press("lock")
			pad.move = Vector2.ZERO
			if fmod(_phase, 0.3) < delta * 1.5:
				_press("attack")
		"combo":
			pad.move = Vector2(0, 1) if dist > 2.2 else Vector2.ZERO
			if dist < 3.5 and fmod(_phase, 0.2) < delta * 1.5:
				_press("attack")
		"heavy":
			pad.move = Vector2(0, 1) if dist > 2.4 else Vector2.ZERO
			if dist < 3.0:
				if _phase < 0.75:
					_press("attack")
				else:
					_release("attack")
					_phase = 0.0
		"air":
			pad.move = Vector2(0, 1) if dist > 2.0 else Vector2.ZERO
			if dist < 3.0 or _phase > 0.6:
				if p.is_on_floor() and fmod(_phase, 1.6) < 0.1:
					_press("jump")
				elif not p.is_on_floor() and fmod(_phase, 1.6) < 0.9 and fmod(_phase, 0.2) < delta * 1.5:
					_press("attack")
				elif not p.is_on_floor() and fmod(_phase, 1.6) >= 0.9:
					_press("attack")   # tenuto: schianto

func _report() -> void:
	var s: Dictionary = fx.stats
	var avg := 0.0
	var mn := 9999.0
	for f in _fps_samples:
		avg += f
		mn = min(mn, f)
	if _fps_samples.size() > 0:
		avg /= _fps_samples.size()
	print("OVERLOAD meter=%.0f livello=%d picco=%.0f" % [root.get_node("OV").meter, root.get_node("OV").level, root.get_node("OV")._peak])
	print("BOT_REPORT secs=%.0f fps_avg=%.1f fps_min=%.0f" % [t, avg, mn])
	var keys := s.keys()
	keys.sort()
	for k in keys:
		print("  %s = %s" % [k, s[k]])
	var need := ["form_impact", "form_vector", "hits", "kills", "dodges", "move_blade_1", "move_impact_launcher", "move_vector_lash", "jumps", "move_blade_air_1", "move_impact_slam", "move_vector_reel", "launch_follow", "power_push", "power_pull", "power_alter", "enemy_pushed", "overcharge_blasts", "shocks", "puddle_shocks", "coil_discharges", "barrels_exploded", "enemies_burned", "structures_broken", "fire_throws", "overload_level_1", "overload_level_2", "overload_bursts"]
	var missing := []
	for n in need:
		if s.get(n, 0) == 0:
			missing.append(n)
	print("BOT_MISSING " + (", ".join(missing) if missing.size() > 0 else "nessuno"))
