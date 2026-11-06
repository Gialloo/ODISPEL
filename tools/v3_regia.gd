extends SceneTree

# PROVA DELLA REGIA (6/11/2026, feedback dei tester: «cambi di camera drastici, alto-basso-lato, mal di testa se giochi veloce»).
# Gioca da solo (AUTO, che sceglie subito come chi gioca veloce) la stessa battaglia con la regia MORBIDA e con quella
# DINAMICA e misura, fotogramma per fotogramma, quanto ruota la telecamera, quanto sale e scende e quanto si inclina.
# Gli stacchi voluti (un solo fotogramma oltre 30 gradi: parata, primo piano) si contano a parte.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 --fixed-fps 60 -s tools/v3_regia.gd [-- boss=autovelox arena=tangenziale]

var main: Node
var boss: String = "autovelox"
var arena: String = "tangenziale"


func _init() -> void:
	Story.save_path = "user://salvataggio_prova.cfg"
	Settings.ensure_loaded()
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("boss="):
			boss = str(a).substr(5)
		elif str(a).begins_with("arena="):
			arena = str(a).substr(6)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run()


func _run() -> void:
	for i in 10:
		await process_frame
	var calm_was: bool = Settings.cam_calm
	var res: Dictionary = {}
	for calm in [false, true]:
		Settings.cam_calm = calm
		res[calm] = await _one()
	Settings.cam_calm = calm_was
	var w: Dictionary = res[false]
	var c: Dictionary = res[true]
	print("REGIA DINAMICA %s" % _line(w))
	print("REGIA MORBIDA  %s" % _line(c))
	var ok: bool = c["p99"] <= w["p99"] and c["fast"] <= w["fast"] and c["y_max"] <= 5.6 and c["down"] <= 50.0 and c["up"] <= 24.0
	print("REGIA ESITO: " + ("OK, la morbida e' piu' calma della dinamica" if ok else "DA RIVEDERE"))
	quit(0 if ok else 1)


func _line(r: Dictionary) -> String:
	return "fotogrammi %5d | rotazione p95 %5.0f p99 %5.0f gradi/s | oltre 200 gradi/s %4d fot. | stacchi %3d | altezza %.2f-%.2f m | in giu' max %2.0f | in su max %2.0f" % [
		r["n"], r["p95"], r["p99"], r["fast"], r["cuts"], r["y_min"], r["y_max"], r["down"], r["up"]]


func _one() -> Dictionary:
	main.go("battle", {"boss": boss, "visual": boss, "arena": arena, "livello": 11})
	while main.get("_busy"):
		await process_frame
	var bt: Node = main.current
	bt.set("auto_on", true)
	var cam: Camera3D = bt.get("cam")
	var speeds: Array = []
	var cuts: int = 0
	var fast: int = 0
	var y_min: float = 99.0
	var y_max: float = -99.0
	var down: float = 0.0
	var up: float = 0.0
	var prev: Vector3 = Vector3.ZERO
	var guard: int = 0
	var dt: float = 1.0 / 60.0
	while is_instance_valid(bt) and not bool(bt.get("ended")) and guard < 30000:
		await process_frame
		guard += 1
		if not is_instance_valid(cam):
			break
		var f: Vector3 = -cam.global_transform.basis.z
		var p: Vector3 = cam.global_position
		y_min = minf(y_min, p.y)
		y_max = maxf(y_max, p.y)
		var pitch: float = rad_to_deg(asin(clampf(f.y, -1.0, 1.0)))
		down = maxf(down, -pitch)
		if OS.get_environment("REGIA_DEBUG") != "" and Settings.cam_calm and pitch < -52.0:
			print("DEBUG giu' %.0f pos %s want %s look %s glide %s/%s" % [-pitch, p, bt.get("_cam_want_pos"), bt.get("_cam_want_look"), bt.get("_glide_t"), bt.get("_glide_len")])
		up = maxf(up, pitch)
		if prev != Vector3.ZERO:
			var ang: float = rad_to_deg(prev.angle_to(f))
			if ang > 30.0:
				cuts += 1           # stacco voluto in un fotogramma: non e' una rotazione
			else:
				var sp: float = ang / dt
				speeds.append(sp)
				if sp > 200.0:
					fast += 1
		prev = f
	speeds.sort()
	return {"n": speeds.size(), "p95": _pct(speeds, 0.95), "p99": _pct(speeds, 0.99), "fast": fast, "cuts": cuts,
		"y_min": y_min, "y_max": y_max, "down": down, "up": up}


func _pct(a: Array, q: float) -> float:
	if a.is_empty():
		return 0.0
	return float(a[clampi(int(float(a.size() - 1) * q), 0, a.size() - 1)])
