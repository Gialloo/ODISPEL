extends SceneTree

# HUD A TRE LIVELLI (Review 01 del game director, 4/11/2026): ogni elemento ha un livello; il testo delle informazioni
# (livelli 1 e 2) non scende sotto HudLayers.MIN_TEXT nei file dell'HUD di battaglia; mentre si sceglie la telecamera tace.
# Le eccezioni sono decorazioni del livello 3 o tasti della tastiera, elencate qui sotto con il perche'.
var fails: int = 0

const FILES: Array = ["battle3d.gd", "cmd_wheel.gd", "portrait_hud.gd", "portrait_party.gd", "skill_menu.gd", "combat_hud.gd"]
# righe ammesse sotto il minimo: numero del tasto 1-4 nel cerchietto (solo tastiera) e lettere preparate in anticipo
const OK_SMALL: Array = ["str(k + 1)", "_warm_fonts"]


func _chk(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	for id in ["vite_squadra", "chi_agisce", "comandi", "vita_nemico", "prossima_mossa"]:
		_chk(HudLayers.level(id) == HudLayers.PRIORITA, "livello 1: " + id)
	for id in ["chat_diretta", "battute", "cartellino_cam", "rec"]:
		_chk(HudLayers.level(id) == HudLayers.ATMOSFERA, "livello 3: " + id)
	_chk(HudLayers.THREAT_TEXT >= HudLayers.MIN_TEXT, "la minaccia non e' piu' piccola del minimo")
	var re := RegEx.new()
	# Ui.label("...", N  |  font_size", N  |  draw_string(..., -1, N, ...)
	re.compile("(Ui\\.label\\((?:\"[^\"]*\"|[^,\"]*), |Ui\\.plate_label\\((?:\"[^\"]*\"|[^,\"]*), |font_size\", |ALIGNMENT_LEFT, -1, |ALIGNMENT_CENTER, -1, )(\\d+)\\b")
	for f in FILES:
		var txt: String = FileAccess.get_file_as_string("res://scripts/v3/" + f)
		var n: int = 0
		for line in txt.split("\n"):
			n += 1
			var skip: bool = false
			for s in OK_SMALL:
				if line.contains(s):
					skip = true
			if skip:
				continue
			for m in re.search_all(line):
				var v: int = int(m.get_string(2))
				_chk(v >= HudLayers.MIN_TEXT, "%s:%d testo da %d sotto il minimo %d" % [f, n, v, HudLayers.MIN_TEXT])
	var ch := CamHud.new()
	ch.set_live(60)
	ch.quiet = true
	ch.call("_chat_tick", 2.0)
	_chk((ch.get("_chat") as Array).is_empty(), "la chat della diretta tace mentre si sceglie")
	ch.quiet = false
	ch.call("_chat_tick", 2.0)
	_chk(not (ch.get("_chat") as Array).is_empty(), "la chat torna durante la mossa")
	ch.free()
	print("test_v3_livelli: ", "OK" if fails == 0 else "%d FALLITI" % fails)
	quit(1 if fails > 0 else 0)
