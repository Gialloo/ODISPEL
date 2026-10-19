extends SceneTree

# Prova i KIT DEI QUATTRO nella battaglia vera, giocando a mano: ognuno usa l'Ultimate appena pronta, altrimenti
# l'Abilita' se puo', altrimenti Attacco; sui colpi del boss para perfetto. Screenshot del turno di ognuno (con la riga
# che spiega abilita' e tratto) e di cosa succede dopo ogni abilita' o ultimate. Stampa le mosse.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_kit.gd -- <cartella>

var out: String = "/tmp/v3kit"
var main: Node
var n: int = 0


func _init() -> void:
	Story.save_path = "user://salvataggio_prova.cfg"     # mai il salvataggio vero
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	Settings.ensure_loaded()
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run()


func _secs(s: float) -> void:
	await create_timer(s, true, false, true).timeout


func _shot(name: String) -> void:
	await process_frame
	n += 1
	root.get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, name])


func _run() -> void:
	await _secs(1.0)
	main.go("battle", {"from": "menu"})
	await _secs(1.5)
	var sc: Node = main.get("current")
	var seen: Dictionary = {}
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 150000:
		await process_frame
		if not is_instance_valid(sc) or bool(sc.get("ended")):
			break
		if bool(sc.get("waiting")):
			var u: Dictionary = sc.call("_unit_of", str(sc.get("cur_pid")))
			var who: String = str(u.get("name", "?"))
			if not seen.has(who):
				seen[who] = true
				await _shot("turno_" + who)
			var kind: String = "attack"
			if bool(sc.call("_usable", str(u.get("ult", "")))):
				kind = "ult"
			elif bool(sc.call("_usable", str(sc.call("_skill_of", u)))):
				kind = "skill"
			print("TURNO %s: %s" % [who, kind])
			sc.call("_command", kind)
			if kind != "attack":
				await _secs(0.9)
				await _shot("%s_%s" % [who, kind])
			continue
		if sc.get("_qte_on") == true:
			while bool(sc.get("_qte_on")):
				if float(sc.get("_qte_t")) + 1.2 / maxf(1.0, Engine.get_frames_per_second()) >= float(sc.get("_qte_lead")):
					sc.call("_qte_tap")
					break
				await process_frame
	var b2: Dictionary = sc.get("b")
	print("vincitore: ", b2.get("winner", ""), "  round ", b2.get("round", 0))
	quit(0)
