extends SceneTree

# I dialoghi si leggono, ogni scena ha il riassunto, ogni personaggio ha un ritratto per ogni espressione usata.

var fails: int = 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	Story.save_path = "user://salvataggio_prova.cfg"     # mai il salvataggio vero
	var data: Dictionary = DialogData.all()
	check(not data.is_empty(), "dialoghi.json si legge")
	for key in ["apertura", "telecamera", "scontrino", "distributore", "agguato", "vittoria", "sconfitta"]:
		_scene(key)
	# atto 1: ogni testo citato da data/atto1.json esiste
	check(not Story.chapters().is_empty(), "atto1.json si legge")
	for ch in Story.chapters():
		for p in ch.get("passi", []):
			match str(p.get("tipo", "")):
				"scena", "rifugio":
					_scene(str(p.get("dialogo", "")))
				"area":
					check(not Story.area(str(p.get("area", ""))).is_empty(), "area %s definita" % str(p.get("area", "")))
	for aid in Story.data().get("aree", {}):
		var a: Dictionary = Story.area(aid)
		if a.has("intro"):
			_scene(str(a["intro"]))
		for c in a.get("indizi", []):
			_scene(str(c.get("dialogo", c["id"])))
		if a.has("boss"):
			var b: Dictionary = a["boss"]
			_scene(str(b.get("dialogo", "")))
			if b.has("agguato"):
				_scene(str(b["agguato"]))
			check(BattleContent.BOSSES.has(str(b.get("id", ""))), "boss %s nel motore" % str(b.get("id", "")))
		if a.has("segreto"):
			_scene(str(a["segreto"].get("dialogo", "")))
			check(BattleContent.BOSSES.has(str(a["segreto"].get("id", ""))), "boss segreto nel motore")
		if a.has("uscita") and str((a["uscita"] as Dictionary).get("dialogo", "")) != "":
			_scene(str(a["uscita"]["dialogo"]))
		check(a.has("boss") or a.has("uscita"), "area %s ha un'uscita o un boss" % aid)
		for e in a.get("nemici", []):
			check(BattleContent.BOSSES.has(str(e.get("boss", ""))), "nemico %s nel motore" % str(e.get("boss", "")))
		check(not DialogData.banter(str(a.get("chiacchiere", aid))).is_empty(), "chiacchiere per %s" % aid)
	# il giro dell'atto arriva alla fine
	Story.new_game()
	var g: int = 0
	while str(Story.current().get("tipo", "")) != "fine" and g < 200:
		check(Story.screen_for_current().size() == 2 and str(Story.screen_for_current()[0]) != "ending", "schermata per il passo %d/%d" % [Story.chapter, Story.step])
		Story.advance()
		g += 1
	check(g > 20 and g < 200, "l'atto 1 arriva alla fine (%d passi)" % g)
	check(str(Story.screen_for_current()[0]) == "ending", "alla fine c'e' la schermata di fine")
	for id in CastVisual.ORDER:
		for expr in CastVisual.EXPR_ORDER:
			check(ResourceLoader.exists("res://assets/portraits/%s_%s.png" % [id, expr]), "ritratto %s_%s" % [id, expr])
	check(ResourceLoader.exists("res://assets/portraits/zecca_maschera.png"), "ritratto zecca_maschera")
	print("test_v3_dialoghi: " + ("OK" if fails == 0 else "%d errori" % fails))
	quit(1 if fails > 0 else 0)


var _seen: Dictionary = {}


func _scene(key: String) -> void:
	if key == "" or _seen.has(key):
		check(key != "", "dialogo senza nome")
		return
	_seen[key] = true
	var lines: Array = DialogData.lines(key)
	check(not lines.is_empty(), "scena %s con righe" % key)
	check(DialogData.recap(key) != "", "scena %s con riassunto" % key)
	for ln in lines:
		var who: String = str(ln.get("chi", ""))
		if CastVisual.CAST.has(who):
			var expr: String = str(ln.get("espr", "neutro"))
			check(CastVisual.EXPRESSIONS.has(expr) or expr == "maschera", "espressione nota: %s/%s (%s)" % [who, expr, key])
		else:
			check(ln.has("col"), "nome libero %s con colore (%s)" % [who, key])
		for opt in ln.get("scelte", []):
			if str(opt.get("vai", "")) != "":
				_scene(str(opt["vai"]))
