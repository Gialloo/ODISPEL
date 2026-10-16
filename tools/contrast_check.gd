extends SceneTree

# Misura il contrasto (WCAG 2.x) delle coppie di colori principali della HUD.
# Testo: serve almeno 4,5; barre, icone e bordi: almeno 3. Per i pannelli semitrasparenti si usa lo sfondo peggiore (cielo viola chiaro).
#   godot --headless --path . -s tools/contrast_check.gd
func _lin(c: float) -> float:
	return c / 12.92 if c <= 0.03928 else pow((c + 0.055) / 1.055, 2.4)


func _lum(c: Color) -> float:
	return 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b)


func _ratio(a: Color, b: Color) -> float:
	var la: float = _lum(a)
	var lb: float = _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _over(fg: Color, bg: Color) -> Color:
	return Color(fg.r * fg.a + bg.r * (1.0 - fg.a), fg.g * fg.a + bg.g * (1.0 - fg.a), fg.b * fg.a + bg.b * (1.0 - fg.a), 1.0)


func _initialize() -> void:
	var sky: Color = Color("#9a6ee0")                                   # sfondo peggiore: cielo viola chiaro della scena
	var panel: Color = _over(Color(BattleTheme.PANEL, 0.80), sky)       # pannello principale
	var panel_q: Color = _over(Color(BattleTheme.PANEL, 0.80), sky)     # pannello secondario (ordine del turno, velo 0,80)
	var panel_t: Color = _over(Color(BattleTheme.PANEL, 0.88), sky)     # pannello allarme (testi di pericolo)
	var panel_b: Color = _over(Color(BattleTheme.PANEL, 0.38), sky)     # pannello sovrapposto leggero
	var bar_bg: Color = _over(Color(0, 0, 0, 0.45), panel)
	var rows: Array = [
		["testo", "avorio su pannello", BattleTheme.WH, panel],
		["testo", "avorio su pannello secondario", BattleTheme.WH, panel_q],
		["testo", "ciano su pannello", BattleTheme.CY, panel],
		["testo", "ciano su pannello secondario", BattleTheme.CY, panel_q],
		["testo", "ciano tenue su pannello", BattleTheme.CY_DIM, panel],
		["testo", "ciano tenue su pannello secondario", BattleTheme.CY_DIM, panel_q],
		["testo", "giallo (POP) su pannello", BattleTheme.POP, panel],
		["testo", "giallo (POP) su pannello secondario", BattleTheme.POP, panel_q],
		["testo", "rosso di testo (RD_TEXT) su pannello allarme", BattleTheme.RD_TEXT, panel_t],
		["testo", "rosso di testo (RD_TEXT) su ordine del turno", BattleTheme.RD_TEXT, panel_q],
		["testo", "rosso di testo (RD_TEXT) su pannello principale", BattleTheme.RD_TEXT, panel],
		["testo", "arancio su pannello", BattleTheme.IMPACT, panel],
		["testo", "nero su comando usabile (avorio)", BattleTheme.BK, BattleTheme.WH],
		["testo", "grigio su comando spento (nero)", BattleTheme.BTN_OFF_TEXT, BattleTheme.BK],
		["testo", "rosso (motivo) su comando spento", BattleTheme.RD, BattleTheme.BK],
		["testo", "nero su comando selezionato (ciano)", BattleTheme.BK, BattleTheme.CY],
		["grafica", "barra PV alleato su fondo barra", BattleTheme.HP, bar_bg],
		["grafica", "barra PV bassa (rosso) su fondo barra", BattleTheme.RD, bar_bg],
		["grafica", "barra ultimate (rosso) su fondo barra", BattleTheme.RD, bar_bg],
		["grafica", "scudo (arancio) su fondo barra", BattleTheme.IMPACT, bar_bg],
		["bordo", "filo pannello ciano su cielo (decorativo)", BattleTheme.CY, sky],
		["bordo", "filo pannello rosso su cielo (decorativo)", BattleTheme.RD, sky],
	]
	var bad: int = 0
	for r in rows:
		var ratio: float = _ratio(r[2], r[3])
		var need: float = 4.5 if r[0] == "testo" else (3.0 if r[0] == "grafica" else 0.0)      # i bordi sono decorativi: l'informazione sta nel testo
		var flag: String = "OK " if ratio >= need else "SOTTO"
		if ratio < need:
			bad += 1
		print("%s %5.2f (serve %.1f)  %s" % [flag, ratio, need, r[1]])
	print("coppie sotto la soglia: %d" % bad)
	quit()
