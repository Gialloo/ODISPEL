extends SceneTree

# PROVA DI CARICO DEL COMBATTIMENTO: gioca da solo (AUTO) alcune battaglie coi boss e misura, fotogramma per fotogramma,
# il tempo di elaborazione (script, tween, effetti) e il tempo totale. Segnala i picchi e dove cadono
# (attacco di squadra / fermo immagine, ultimate, turno normale). Non e' un telefono vero: i numeri si confrontano tra versioni.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_stress_battaglia.gd [-- semi=3]

var main: Node
const CASES: Array = [
	{"boss": "autovelox", "arena": "tangenziale", "livello": 11},
	{"boss": "cassaforte", "arena": "caveau", "livello": 9},
	{"boss": "cabina", "arena": "anomalia_blu", "livello": 5},
]


func _init() -> void:
	Story.save_path = "user://salvataggio_prova.cfg"
	Settings.ensure_loaded()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run()


func _run() -> void:
	var semi: int = 2
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("semi="):
			semi = int(str(a).substr(5))
	for i in 10:
		await process_frame
	for c in CASES:
		for s in semi:
			await _one(c)
	quit()


func _one(c: Dictionary) -> void:
	main.go("battle", {"boss": c["boss"], "visual": c["boss"], "arena": c["arena"], "livello": c["livello"]})
	while main.get("_busy"):
		await process_frame
	var bt: Node = main.current
	bt.set("auto_on", true)
	Engine.max_fps = 0
	var proc: Array = []
	var tot: Array = []
	var tags: Dictionary = {"squadra": [], "ultimate": [], "normale": []}
	var peak_nodes: int = 0
	var t_prev: int = Time.get_ticks_usec()
	var guard: int = 0
	while is_instance_valid(bt) and not bool(bt.get("ended")) and guard < 20000:
		await process_frame
		guard += 1
		var now: int = Time.get_ticks_usec()
		var ft: float = float(now - t_prev) / 1000.0
		t_prev = now
		var pt: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		proc.append(pt)
		tot.append(ft)
		var tag: String = "normale"
		if bt.get("_freeze_on") == true or bt.get("_team_on") == true:
			tag = "squadra"
		elif bt.get("_cutin_on") == true:
			tag = "ultimate"
		(tags[tag] as Array).append(pt)
		peak_nodes = maxi(peak_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	Engine.max_fps = GameConfig.MAX_FPS
	print("STRESS %-11s fotogrammi %5d | processo medio %.2f ms p95 %.2f max %.2f | totale medio %.2f p95 %.2f | squadra max %.2f (%d fot.) | ultimate max %.2f | nodi max %d" % [
		c["boss"], proc.size(), _avg(proc), _pct(proc, 0.95), _max(proc), _avg(tot), _pct(tot, 0.95),
		_max(tags["squadra"]), (tags["squadra"] as Array).size(), _max(tags["ultimate"]), peak_nodes])


func _avg(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var s: float = 0.0
	for x in a:
		s += float(x)
	return s / float(a.size())


func _max(a: Array) -> float:
	var m: float = 0.0
	for x in a:
		m = maxf(m, float(x))
	return m


func _pct(a: Array, p: float) -> float:
	if a.is_empty():
		return 0.0
	var s: Array = a.duplicate()
	s.sort()
	return float(s[mini(s.size() - 1, int(float(s.size()) * p))])
