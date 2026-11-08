extends SceneTree

# Cerca gli SCATTI (fotogrammi lenti) in uno scontro intero giocato in AUTO, dall'ingresso alla vittoria.
# Per ogni fotogramma oltre la soglia stampa: quando (secondi dall'inizio), quanto e' durato, la fase
# (ultimo Breadcrumb) e quali nodi sono nati in quel fotogramma, cosi' si vede cosa lo ha causato.
# Con --headless non si disegna nulla: restano solo i costi degli script e della creazione dei nodi (CPU);
# con la grafica (xvfb-run) si vedono anche i costi di disegno e di compilazione degli shader.
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_scatti.gd [-- soglia=40 ingresso=vantaggio arena=strada boss=distributore]

var main: Node
var _born: Dictionary = {}
var _soglia: float = 40.0


func _init() -> void:
	Story.save_path = "user://salvataggio_prova.cfg"
	Settings.ensure_loaded()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	node_added.connect(_on_added)
	_run()


func _on_added(n: Node) -> void:
	var s: Script = n.get_script()
	var k: String = n.get_class() if s == null else str(s.resource_path.get_file())
	_born[k] = int(_born.get(k, 0)) + 1


# script del gioco gia' caricati: quelli nuovi in un fotogramma lento sono caricamenti fatti a scontro in corso
var _known: Dictionary = {}


func _new_scripts() -> Array:
	var out: Array = []
	for dir in ["res://scripts/v3/", "res://scripts/engine/"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				var p: String = dir + f
				if not _known.has(p) and ResourceLoader.has_cached(p):
					_known[p] = true
					out.append(f)
	return out


func _phase() -> String:
	var f := FileAccess.open(Breadcrumb.PATH, FileAccess.READ)
	return f.get_as_text() if f != null else "?"


func _run() -> void:
	var args: Dictionary = {"boss": "distributore", "visual": "distributore", "arena": "strada", "ingresso": "vantaggio"}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = str(a).split("=")
		if kv.size() == 2:
			if kv[0] == "soglia":
				_soglia = float(kv[1])
			else:
				args[kv[0]] = kv[1]
	for i in 10:
		await process_frame
	var area_id: String = str((Story.data().get("aree", {}) as Dictionary).keys()[0])
	main.go("area", {"area": area_id, "resume": {"pos": Vector3(0, 0.14, 0)}})
	while main.get("_busy"):
		await process_frame
	for i in 60:
		await process_frame
	Engine.max_fps = 0
	var t0: int = Time.get_ticks_msec()
	var last: int = Time.get_ticks_usec()
	var spikes: int = 0
	var total: float = 0.0
	var frames: int = 0
	_born.clear()
	main.go("battle", args)
	var sc: Node = null
	var auto_set: bool = false
	var ended_at: int = -1
	while true:
		await process_frame
		var now: int = Time.get_ticks_usec()
		var ms: float = float(now - last) / 1000.0
		last = now
		frames += 1
		total += ms
		if ms > _soglia:
			spikes += 1
			var parts: Array = []
			for k in _born:
				parts.append("%s x%d" % [k, _born[k]])
			print("SCATTO %6.2f s | %6.1f ms | fase %-18s | caricati: %s | nati: %s" % [float(Time.get_ticks_msec() - t0) / 1000.0, ms, _phase(), ", ".join(_new_scripts()), ", ".join(parts)])
		else:
			_new_scripts()
		_born.clear()
		if sc == null and main.get("current") != null and str(main.get("current").name) == "Battle":
			sc = main.get("current")
		if sc != null and is_instance_valid(sc):
			if not auto_set and Time.get_ticks_msec() - t0 > 3000:
				var td: Variant = sc.get("_tut_dlg")
				if td != null and is_instance_valid(td):
					td.call("skip")
				elif not bool(sc.get("auto_on")):
					sc.call("_toggle_auto")
					auto_set = true
			if bool(sc.get("ended")) and ended_at < 0:
				ended_at = Time.get_ticks_msec()
			if ended_at > 0 and Time.get_ticks_msec() - ended_at > 9000:
				break
		if Time.get_ticks_msec() - t0 > 400000:
			print("TEMPO SCADUTO")
			break
	print("TOTALE %d fotogrammi, media %.2f ms, scatti oltre %.0f ms: %d, durata %.1f s" % [frames, total / frames, _soglia, spikes, float(Time.get_ticks_msec() - t0) / 1000.0])
	quit()
