extends SceneTree

# Varianti del ritratto di Rio (disegni dell'autore, 3/11/2026): file presenti, soglie della vita, skin della Replica,
# ripiego per chi non ha ancora le varianti.
#   godot --headless --path . -s res://tests/unit/test_v3_ritratto_varianti.gd

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
	# spente (autore, 3/11/2026): nel gioco solo il ritratto normale
	_check("varianti spente di serie", not RitrattoVarianti.attive)
	_check("spente: resta il ritratto hud", RitrattoVarianti.tex("zecca", "hud") != null)
	for st0 in ["ombra", "ferito", "critico", "break", "ko", "pausa", "ng", "ricordo"]:
		_check("spente: niente " + st0, RitrattoVarianti.path("zecca", st0) == "")
	Story.flags["replica"] = 1
	_check("spente: niente skin NG+", RitrattoVarianti.base("zecca") == "hud")
	Story.flags["replica"] = 0
	# i file restano: riaccese funzionano tutte
	RitrattoVarianti.attive = true
	RitrattoVarianti._cache.clear()
	for st in ["hud", "ombra", "ferito", "critico", "break", "ko", "pausa", "ng", "ricordo"]:
		_check("Rio ha la variante " + st, RitrattoVarianti.tex("zecca", st) != null)
	for st in ["volto", "volto_ko", "volto_ferito", "volto_critico", "volto_ng"]:
		_check("Rio ha il " + st, RitrattoVarianti.has("zecca", st))
	_check("varianti a 768x1024", RitrattoVarianti.tex("zecca", "ombra").get_size() == Vector2(768, 1024))
	_check("PV pieni: normale", RitrattoVarianti.per_vita(100, 100) == "")
	_check("51%: normale", RitrattoVarianti.per_vita(51, 100) == "")
	_check("50%: ferito", RitrattoVarianti.per_vita(50, 100) == "ferito")
	_check("26%: ferito", RitrattoVarianti.per_vita(26, 100) == "ferito")
	_check("25%: critico", RitrattoVarianti.per_vita(25, 100) == "critico")
	_check("1 PV: critico", RitrattoVarianti.per_vita(1, 100) == "critico")
	_check("0 PV: ko", RitrattoVarianti.per_vita(0, 100) == "ko")
	Story.flags["replica"] = 0
	_check("partita normale: ritratto hud", RitrattoVarianti.base("zecca") == "hud")
	Story.flags["replica"] = 1
	_check("Replica (NG+): skin ng", RitrattoVarianti.base("zecca") == "ng")
	_check("Replica senza disegno ng: resta hud", RitrattoVarianti.base("ferri") == "hud")
	Story.flags["replica"] = 0
	_check("Lance senza varianti: niente ombra", RitrattoVarianti.tex("ferri", "ombra") == null)
	print("RISULTATO: %d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
