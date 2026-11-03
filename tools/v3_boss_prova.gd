extends SceneTree

# Prova di uno scontro col BOSS come nella storia (ritorno «storia», arena dell'Anomalia), confrontabile con un nemico base:
# schermate dell'ingresso e dei turni in AUTO, tempi dei fotogrammi dell'ingresso (calo di prestazioni) e tagli della telecamera.
# Uso: xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 -s tools/v3_boss_prova.gd -- <cartella> [boss|minore] [id] [arena]

var out: String = "/tmp/v3boss"
var kind: String = "boss"
var frames: Array = []


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1:
		kind = a[1]
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	Settings.hud_ritratto = true
	Story.set_flag("lezioni_fatte")
	var id: String = a[2] if a.size() > 2 else ("semaforo" if kind == "boss" else "frammento_rosso")
	var ar: String = a[3] if a.size() > 3 else ("anomalia_rossa" if kind == "boss" else "strada")
	_run(id, ar)


func _shot(n: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(out.path_join(n + ".png"))


func _run(id: String, ar: String) -> void:
	await process_frame
	var bt: Node = load("res://scripts/v3/battle3d.gd").new()
	var args: Dictionary = {"boss": id, "visual": id, "livello": 3, "arena": ar, "ingresso": "normale"}
	if kind == "boss":
		args["ritorno"] = {"tipo": "storia", "area": "incrocio", "perso": {}}
		args["debolezze"] = []
	else:
		args["ritorno"] = {"tipo": "area", "area": "incrocio", "vinto": {}, "perso": {}}
		args["minore"] = true
	bt.configure(args)
	root.add_child(bt)
	var t0: int = Time.get_ticks_msec()
	var last: int = Time.get_ticks_usec()
	var cams: Array = []
	var prev_cam: Vector3 = Vector3.ZERO
	var k: int = 0
	while not bool(bt.get("waiting")) and Time.get_ticks_msec() - t0 < 12000:
		await process_frame
		var now: int = Time.get_ticks_usec()
		frames.append((now - last) / 1000.0)
		if (now - last) / 1000.0 > 120.0:
			cams.append("%d ms: fotogramma lento %.0f ms" % [Time.get_ticks_msec() - t0, (now - last) / 1000.0])
		last = now
		var c: Camera3D = bt.get("cam")
		if c != null:
			if prev_cam != Vector3.ZERO and c.global_position.distance_to(prev_cam) > 0.6:
				cams.append("%d ms: salto %.1f" % [Time.get_ticks_msec() - t0, c.global_position.distance_to(prev_cam)])
			prev_cam = c.global_position
		k += 1
		if k % 12 == 0:
			await _shot("ingresso_%03d" % k)
	frames.sort()
	print("FOTOGRAMMI ingresso: n=%d peggiori=%s" % [frames.size(), str(frames.slice(frames.size() - 6))])
	print("TAGLI: ", cams)
	await _shot("primo_turno")
	# turni giocati: quando tocca a noi foto dell'HUD, poi ATTACCO (ogni terzo turno ABILITA'); tra un turno e l'altro foto ogni 0,6 s
	var turns: int = 0
	var tt: int = Time.get_ticks_msec()
	var sh: int = 0
	while turns < 14 and Time.get_ticks_msec() - tt < 90000:
		if not is_instance_valid(bt) or not bt.is_inside_tree() or bool(bt.get("ended")):
			break
		if bool(bt.get("waiting")):
			await create_timer(0.5).timeout
			await _shot("turno_%02d" % turns)
			bt.call("_command", "skill" if turns % 3 == 2 else "attack")
			turns += 1
			await create_timer(0.3).timeout
			continue
		await create_timer(0.6).timeout
		sh += 1
		await _shot("azione_%03d" % sh)
	print("turni giocati: ", turns, " finito: ", bt.get("ended") if is_instance_valid(bt) else "?")
	print("OK boss_prova")
	quit(0)
