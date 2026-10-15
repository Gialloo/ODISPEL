extends SceneTree

# LIGHT PAINTING: ogni mano (fazione) x colore x forma si costruisce senza errori, ha un percorso
# valido, il tetto di tratti vivi regge e le fazioni sconosciute non disegnano niente.
#
#   godot --headless --path . -s res://tests/unit/test_light_paint.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _run() -> void:
	var host := Control.new()
	root.add_child(host)
	LightPaint.max_live = 14
	var bad: int = 0
	var made: int = 0
	for hand in LightPaint.HANDS:
		for hue in BattleTheme.UNIT_COLORS.keys():
			for shape in LightPaint.SHAPES:
				var p: LightPaint = LightPaint.play(host, hand, str(hue), shape, Vector2(100, 300), Vector2(900, 250), 1.0, 0.0, "kira")
				if p == null:
					# il tetto puo' scattare: libero i tratti vivi e riprovo
					for c in host.get_children():
						c.queue_free()
					await process_frame
					await process_frame
					p = LightPaint.play(host, hand, str(hue), shape, Vector2(100, 300), Vector2(900, 250), 1.0, 0.0, "kira")
				if p == null or p._path.size() < 3 or p._widths.size() != p._path.size():
					bad += 1
				else:
					made += 1
				# un fotogramma di animazione e di disegno non deve rompere niente
				if p != null:
					p._process(0.1)
	_check("tutte le combinazioni mano x colore x forma (7 forme) si costruiscono", bad == 0 and made == 4 * 5 * LightPaint.SHAPES.size())
	_check("fazione sconosciuta: nessun tratto", LightPaint.play(host, "nessuna", "rosso", "line", Vector2.ZERO, Vector2(50, 0)) == null)
	_check("hand_for: personaggio con fazione", LightPaint.hand_for({"faction": "kairos"}) == "kairos")
	_check("hand_for: senza fazione", LightPaint.hand_for({}) == "")
	for c in host.get_children():
		c.queue_free()
	await process_frame
	await process_frame
	LightPaint.max_live = 3
	var n: int = 0
	for i in 8:
		if LightPaint.play(host, "rondini", "blu", "line", Vector2.ZERO, Vector2(200, 0)) != null:
			n += 1
	_check("il tetto dei tratti vivi vale", n <= 3)
	var a: LightPaint = null
	for c in host.get_children():
		if c is LightPaint:
			a = c
	var b: LightPaint = LightPaint.new()
	b.hand = "magabondi"
	b.hue_name = "viola"
	b.from_pt = Vector2(10, 10)
	b.to_pt = Vector2(300, 90)
	b._rng.seed = 5
	b._setup()
	var b2: LightPaint = LightPaint.new()
	b2.hand = "magabondi"
	b2.hue_name = "viola"
	b2.from_pt = Vector2(10, 10)
	b2.to_pt = Vector2(300, 90)
	b2._rng.seed = 5
	b2._setup()
	_check("stesso seme = stesso tratto", b._path == b2._path and a != null)
	b.free()
	b2.free()
	# ogni personaggio ha la sua firma, mai uguale a un altro
	var seen: Dictionary = {}
	for id in BattleContent.CHARACTERS:
		var sp: Dictionary = LightPaint.sigil_spec(str(id))
		seen["%d/%d/%d" % [sp["n"], sp["k"], sp["variant"]]] = true
	_check("24 personaggi = 24 firme diverse", seen.size() == BattleContent.CHARACTERS.size())
	# il velo scuro e' uno solo e rientra a zero
	var dimhost := Control.new()
	root.add_child(dimhost)
	LightPaint.dim(dimhost, 0.3, 0.05)
	LightPaint.dim(dimhost, 0.3, 0.05)
	var veils: int = 0
	for c in dimhost.get_children():
		if c is ColorRect:
			veils += 1
	_check("il velo scuro e' uno solo anche con tratti ripetuti", veils == 1)
	print("RISULTATO: %d ok, %d falliti" % [passed, failed])
	print("FAIL: %d" % failed)
	quit(1 if failed > 0 else 0)
