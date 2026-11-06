extends SceneTree

# Prova la PRESENTAZIONE DEL QTE (QteIntro) nella battaglia vera, giocando a mano: a ogni turno prova una reazione
# (FERMA, SCHIVA, COPRI) se si puo', altrimenti attacca; a ogni presentazione salva una schermata a meta' e misura quanto
# dura (la prima di ogni tipo e' lunga, le altre brevi). Alla guardia a tempo non tocca (conta solo la presentazione).
# Uso: xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_qte_intro.gd -- <cartella>

var out: String = "/tmp/v3qteintro"
var main: Node
var n: int = 0
const TRY: Array = ["interruzione", "schivata", "intercettazione"]


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


func _find_intro(node: Node) -> QteIntro:
	for c in node.find_children("*", "QteIntro", true, false):
		return c as QteIntro
	return null


func _run() -> void:
	await _secs(1.0)
	main.go("battle", {"from": "menu"})
	await _secs(1.5)
	var sc: Node = main.get("current")
	var intros: int = 0
	var turn: int = 0
	var t0: int = Time.get_ticks_msec()
	var seen: Dictionary = {}
	while intros < 3 and Time.get_ticks_msec() - t0 < 150000:
		await process_frame
		if not is_instance_valid(sc) or bool(sc.get("ended")):
			break
		if bool(sc.get("waiting")):
			var rid: String = str(TRY[turn % TRY.size()])
			turn += 1
			if bool(sc.call("_usable", rid)):
				print("TURNO %d: reazione %s" % [turn, rid])
				sc.call("_react_cmd", rid)
			else:
				sc.call("_command", "attack")
			continue
		var q: QteIntro = _find_intro(sc)
		if q != null:
			var mode: String = q.mode
			var start: int = Time.get_ticks_msec()
			var planned: float = q.dur
			await _secs(0.9)
			if is_instance_valid(q):
				await _shot("intro_%s_%s" % [mode, "lunga" if not seen.has(mode) else "breve"])
			while is_instance_valid(q):
				await process_frame
			var ms: int = Time.get_ticks_msec() - start
			print("PRESENTAZIONE %s: prevista %.1f s, durata %d ms, battuta: %s" % [mode, planned, ms, "-" if mode == "guard" else "si"])
			seen[mode] = true
			intros += 1
	# le altre reazioni, lanciate a mano sulla stessa battaglia: una schermata per tipo, con personaggi diversi
	if is_instance_valid(sc) and not bool(sc.get("ended")):
		var units: Dictionary = (sc.get("b") as Dictionary)["units"]
		for pair in [["arrow", "saul"], ["hold", "lance"], ["beat", "nox"]]:
			var u: Dictionary = {}
			for id in units:
				if str((units[id] as Dictionary).get("char", "")) == str(pair[1]):
					u = units[id]
			if u.is_empty():
				continue
			sc.call("_qte_intro_react", pair[0], u)
			await _secs(0.9)
			await _shot("intro_%s_%s" % [pair[0], pair[1]])
			while _find_intro(sc) != null:
				await process_frame
			intros += 1
	print("FINE prova presentazioni: %d" % intros)
	quit(0)
