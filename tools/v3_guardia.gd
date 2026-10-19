extends SceneTree

# Prova la GUARDIA A TEMPO nella battaglia vera, giocando a mano (niente AUTO): a ogni colpo del boss manda un tocco
# vero sullo schermo (passa da tutto l'input di Godot) in un momento diverso: perfetto, in tempo, troppo presto, nessuno.
# Stampa l'esito di ogni colpo e salva screenshot del cerchio e dei risultati.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_guardia.gd -- <cartella> [x2]

var out: String = "/tmp/v3guardia"
var main: Node
var n: int = 0
const PLAN: Array = ["none", "perfect", "good", "early"]


func _init() -> void:
	Story.save_path = "user://salvataggio_prova.cfg"     # mai il salvataggio vero
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	Settings.ensure_loaded()
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run(args.has("x2"))


func _secs(s: float) -> void:
	await create_timer(s, true, false, true).timeout


func _shot(name: String) -> void:
	await process_frame
	n += 1
	root.get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, name])


func _tap() -> void:
	var t := InputEventScreenTouch.new()
	t.position = Vector2(640, 420)
	t.pressed = true
	Input.parse_input_event(t)
	var r := InputEventScreenTouch.new()
	r.position = t.position
	r.pressed = false
	Input.parse_input_event(r)


func _run(x2: bool) -> void:
	await _secs(1.0)
	main.go("battle", {"from": "menu"})
	await _secs(1.5)
	var sc: Node = main.get("current")
	if x2:
		sc.call("_toggle_fast")
	var hits: int = 0
	var t0: int = Time.get_ticks_msec()
	var last_choice: int = t0
	var waits: Array = []
	while hits < 8 and Time.get_ticks_msec() - t0 < 120000:
		await process_frame
		if not is_instance_valid(sc) or bool(sc.get("ended")):
			break
		if bool(sc.get("waiting")):
			waits.append(Time.get_ticks_msec() - last_choice)
			sc.call("_command", "attack")
			last_choice = Time.get_ticks_msec()
			continue
		if sc.get("_qte_on") == true:
			var want: String = PLAN[hits % PLAN.size()]
			var lead: float = float(sc.get("_qte_lead"))
			var at: float = {"perfect": lead, "good": lead - 0.2, "early": lead - 0.6, "none": 99.0}[want]
			var shot_taken: bool = false
			while bool(sc.get("_qte_on")):
				if not shot_taken and float(sc.get("_qte_t")) > lead * 0.6:
					shot_taken = true
					await _shot("cerchio_%d" % hits)
				# il tocco arriva al gioco il frame dopo: si anticipa di un frame (con xvfb gli fps sono bassi)
				if float(sc.get("_qte_t")) + 1.2 / maxf(1.0, Engine.get_frames_per_second()) >= at:
					_tap()
					await process_frame
					break
				await process_frame
			while bool(sc.get("_qte_on")):
				await process_frame
			var got: String = str(sc.get("_qte_grade"))
			print("COLPO %d: voluto %s, ottenuto %s" % [hits, want, got if got != "" else "none"])
			await _secs(0.35)
			await _shot("esito_%d_%s" % [hits, got if got != "" else "none"])
			hits += 1
	waits.remove_at(0)
	print("attese tra due scelte (ms): ", waits)
	print("fps: ", Engine.get_frames_per_second())
	print("FINE prova guardia: %d colpi" % hits)
	quit(0)
