extends SceneTree

# HUD COMBAT 2.0 · fondamenta (7/11/2026): la tabella dei quattro livelli informativi in HudLayers.
# - ogni elemento ha livello, ruolo e intensita' validi; nessun testo dei livelli 1-3 sotto il minimo di 16;
# - con l'interruttore spento ogni misura e ogni valore sono quelli della 0.63.0;
# - l'intensita' non cambia mai i colori semantici e lo stato critico la riporta sempre a PIENA;
# - dopo l'intensita' il testo resta leggibile (contrasto >= 4,5:1 sulla lastra o sul suo contorno d'inchiostro);
# - la colonna ORDINE dichiara la sua larghezza vera.
var fails: int = 0


func _chk(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _init() -> void:
	var prima: bool = Settings.hud_gerarchia
	for id in HudLayers.ELEMENTI_INFO:
		var e: Array = HudLayers.ELEMENTI_INFO[id]
		_chk(e.size() == 6, "%s: sei campi" % id)
		_chk(int(e[0]) >= HudLayers.DECORAZIONE and int(e[0]) <= HudLayers.L4, "%s: livello valido" % id)
		_chk(HudLayers.RUOLO.has(str(e[1])), "%s: ruolo valido" % id)
		_chk(HudLayers.MISCELA.has(str(e[2])), "%s: intensita' valida" % id)
		# importanza e misura sono distinte: il ruolo GRAFICO non ha misura di testo
		_chk((str(e[1]) == "GRAFICO") == (int(e[3]) == 0), "%s: misura 0.63 presente solo per i testi" % id)

	# acceso: misure dai ruoli, mai sotto il minimo per i livelli 1-3
	Settings.hud_gerarchia = true
	for id in HudLayers.ELEMENTI_INFO:
		if HudLayers.ruolo(id) == "GRAFICO":
			continue
		var fs: int = HudLayers.font_size(id)
		_chk(fs == int(HudLayers.RUOLO[HudLayers.ruolo(id)]), "%s: misura dal ruolo" % id)
		_chk(fs >= HudLayers.MIN_TEXT, "%s: almeno %d px (ha %d)" % [id, HudLayers.MIN_TEXT, fs])
	_chk(HudLayers.RUOLO["COMANDO"] == 30, "i comandi restano a 30 (eccezione approvata)")
	_chk(HudLayers.RUOLO["DISEGNO"] == 40, "il nome sul ritratto resta a 40 (decisione 2)")
	_chk(HudLayers.font_size("vita_nemico") == 22 and HudLayers.info("vita_nemico") == HudLayers.L1, "vita del nemico: L1 ma NUMERO_L1, non TITOLO")

	# intensita': colori semantici intatti, critico sempre PIENA, contrasto verificato
	var cream: Color = Color("#fff4dc")
	for id in HudLayers.ELEMENTI_INFO:
		var e: Array = HudLayers.ELEMENTI_INFO[id]
		_chk(HudLayers.intensity(id, true) == HudLayers.PIENA, "%s: lo stato critico porta a PIENA" % id)
		if bool(e[4]):
			for c in [Color("#62f08c"), Color("#3fe0ff"), Color("#ff3b4e"), Color("#ffd23f")]:
				_chk(HudLayers.tone(id, c) == c, "%s: colore semantico intatto" % id)
		if HudLayers.ruolo(id) == "GRAFICO":
			continue
		var t: Color = HudLayers.tone(id, cream)
		var fondo: Color = HudLayers.INK if bool(e[5]) else HudLayers.LASTRA
		var k: float = HudLayers.contrasto(t, fondo)
		_chk(k >= HudLayers.CONTRASTO_TESTO, "%s: contrasto %.1f:1 dopo l'intensita' (minimo %.1f)" % [id, k, HudLayers.CONTRASTO_TESTO])
	_chk(HudLayers.tone("descrizione", cream) != cream, "l'intensita' QUIETA cambia davvero il testo non semantico")
	_chk(absf(HudLayers.contrasto(Color.WHITE, Color.BLACK) - 21.0) < 0.01, "il calcolo del contrasto e' quello delle WCAG")

	# spento: identico alla 0.63.0
	Settings.hud_gerarchia = false
	for id in HudLayers.ELEMENTI_INFO:
		var e: Array = HudLayers.ELEMENTI_INFO[id]
		if str(e[1]) != "GRAFICO":
			_chk(HudLayers.font_size(id) == int(e[3]), "%s: spento torna a %d" % [id, int(e[3])])
		_chk(HudLayers.intensity(id) == HudLayers.PIENA, "%s: spento nessuna intensita'" % id)
		_chk(HudLayers.tone(id, cream) == cream, "%s: spento colore invariato" % id)
	for key in HudLayers.VAL:
		var p: Array = HudLayers.VAL[key]
		_chk(p.size() == 2, "%s: valore nuovo e valore 0.63" % key)
		_chk(HudLayers.v(key) == p[1], "%s: spento vale quello della 0.63" % key)
	Settings.hud_gerarchia = true
	for key in HudLayers.VAL:
		_chk(HudLayers.v(key) == (HudLayers.VAL[key] as Array)[0], "%s: acceso vale quello nuovo" % key)
	Settings.hud_gerarchia = prima

	# i tre livelli di prima non cambiano
	_chk(HudLayers.level("vita_nemico") == HudLayers.PRIORITA and HudLayers.level("rec") == HudLayers.ATMOSFERA, "i tre livelli di HudLayers restano")
	# colonna ORDINE: 10 di margine + lastrina 92 + freccia 40
	_chk(is_equal_approx(PortraitParty.order_width(), 142.0), "la colonna ORDINE e' larga 142")
	# zona A: il pannello del nemico lascia all'ORDINE la sua larghezza vera piu' 8 di aria; spento i 120 della 0.63
	Settings.hud_gerarchia = true
	_chk(is_equal_approx(HudLayers.riserva_ordine(), 150.0), "acceso: riserva per l'ORDINE 142 + 8")
	Settings.hud_gerarchia = false
	_chk(is_equal_approx(HudLayers.riserva_ordine(), 120.0), "spento: riserva della 0.63 (120)")
	Settings.hud_gerarchia = prima

	print("test_v3_gerarchia: ", "OK" if fails == 0 else "%d FALLITI" % fails)
	quit(1 if fails > 0 else 0)
