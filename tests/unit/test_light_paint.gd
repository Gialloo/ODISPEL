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
			for shape in ["line", "ring", "spiral"]:
				var p: LightPaint = LightPaint.play(host, hand, str(hue), shape, Vector2(100, 300), Vector2(900, 250), 1.0)
				if p == null:
					# il tetto puo' scattare: libero i tratti vivi e riprovo
					for c in host.get_children():
						c.queue_free()
					await process_frame
					await process_frame
					p = LightPaint.play(host, hand, str(hue), shape, Vector2(100, 300), Vector2(900, 250), 1.0)
				if p == null or p._path.size() < 3 or p._widths.size() != p._path.size():
					bad += 1
				else:
					made += 1
				# un fotogramma di animazione e di disegno non deve rompere niente
				if p != null:
					p._process(0.1)
	_check("tutte le 60 combinazioni mano x colore x forma si costruiscono", bad == 0 and made == 60)
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
	print("RISULTATO: %d ok, %d falliti" % [passed, failed])
	print("FAIL: %d" % failed)
	quit(1 if failed > 0 else 0)
