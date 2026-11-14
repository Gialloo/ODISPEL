extends Node
## Flusso della demo (senza combattimenti, per ora):
## titolo → vicolo con Lance (percezioni, incontro con Rio, il boato)
## → rifugio nella lavanderia (quattro sconosciuti, si parla con ognuno, la porta)
## → quartiere trasformato e chiuso (gruppo, cambio guida, percezioni) → finale.
## Il raccordo tra queste parti è una PROPOSTA, approvato dall'autore il 14/11/2026 (il canone non lo documenta, Manuale §14).

var dati: Dictionary
var mondo: Node3D
var ui: CanvasLayer
var punto_vicino = null
var occupato := false
var finita := false
var _hud: Control
var _chip_luogo: Label
var _chip_guida: Label
var _bottone_esamina: Button
var _bottone_cambia: Button
var _stick: Control
var _timer_chiacchiere := 0.0
var _chiacchiera_i := 0

func _ready() -> void:
	var f := FileAccess.open("res://data/capitolo1.json", FileAccess.READ)
	dati = JSON.parse_string(f.get_as_text())
	mondo = preload("res://scripts/mondo.gd").new()
	add_child(mondo)
	ui = preload("res://scripts/persona_ui.gd").new()
	add_child(ui)
	_costruisci_hud()
	mondo.avviso.connect(_su_avviso)
	mondo.esamina_cambiato.connect(_su_esamina_cambiato)
	mondo.innesco.connect(_su_innesco)
	if OS.get_cmdline_user_args().has("prova"):
		return   # lo script di prova parte da sé
	avvia()

func _zona(nome: String, membri: Array) -> void:
	var z: Dictionary = dati["zone"][nome]
	mondo.carica_zona(nome, membri, z.get("comparse", {}), z.get("punti", []))
	_chip_luogo.text = z.get("luogo", "")

func avvia() -> void:
	_zona("vicolo", ["lance"])
	await _titolo()
	await ui.cartello("11 NOVEMBRE  ·  NOTTE", "Lance  ·  ricognizione, per conto suo")
	_hud.visible = true
	await esegui("intro")
	_libera()

func _libera() -> void:
	mondo.camera_libera()
	_aggiorna_hud()
	mondo.controllo = true

# ---------------------------------------------------------------- scene

func esegui(nome: String) -> void:
	occupato = true
	mondo.controllo = false
	_bottone_esamina.visible = false
	var hud_prima := _hud.visible
	_hud.visible = false   # durante le scene parla solo la scena
	ui.togli_balloon()
	await _righe(dati["scene"].get(nome, []))
	ui.chiudi()
	if ui._barre[0].visible and ui._barre[0].position.y > -40.0:
		ui.barre(false)   # in esplorazione niente barre da film
	_hud.visible = hud_prima
	occupato = false

func _righe(righe: Array) -> void:
	for r in righe:
		# "se": la riga c'è solo se quella cosa è già successa (es. il reperto di Rio)
		if r.has("se") and not mondo.fatti.has(r["se"]):
			continue
		if r.has("scelta"):
			var opzioni: Array = r["scelta"]
			var i: int = await ui.scegli(opzioni.map(func(o): return o["testo"]))
			var vai: String = opzioni[i].get("vai", "")
			if vai != "":
				await _righe(dati["scene"][vai])
			return
		elif r.has("vai"):
			await _righe(dati["scene"][r["vai"]])
			return
		elif r.has("regia"):
			await _regia(r)
		elif r.has("balloon"):
			var chi: String = r["balloon"]
			if mondo.corpi.has(chi):
				var s := float(r.get("s", 2.4))
				ui.balloon(chi, r["testo"], mondo.testa.bind(chi), mondo.camera, s)
				await get_tree().create_timer(s + 0.25).timeout
		else:
			await ui.di(r)

func _regia(r: Dictionary) -> void:
	match r["regia"]:
		"barre":
			ui.chiudi()
			await ui.barre(r.get("on", true))
		"camera":
			ui.nascondi_box()
			await mondo.camera_a(r["a"], float(r.get("s", 1.0)))
		"attesa":
			await get_tree().create_timer(float(r.get("s", 0.5))).timeout
		"onomato":
			ui.onomato(r["testo"])
			await get_tree().create_timer(0.35).timeout
		"lampo":
			ui.lampo(Color(r.get("colore", "#ffffff")))
		"muovi":
			ui.nascondi_box()
			var a: Array = r["a"]
			if r.get("aspetta", true):
				await mondo.muovi(r["chi"], a[0], a[1], float(r.get("s", 1.0)))
			else:
				mondo.muovi(r["chi"], a[0], a[1], float(r.get("s", 1.0)))
		"gira":
			await mondo.gira(r["chi"], float(r["gradi"]))
		"posa":
			mondo.posa(r["chi"], r.get("posa", ""))
		"salta":
			var a: Array = r["a"]
			await mondo.salta(r["chi"], a[0], a[1], a[2])
		"luce_rio":
			mondo.luce_rio()
			ui.lampo(Color.WHITE)
		"boato":
			mondo.boato()
			ui.lampo(Color("#ff2bd6"))
			ui.onomato(r.get("testo", "BOOM"))
			await get_tree().create_timer(1.2).timeout
		"nome":
			ui.nomi[r["chi"]] = r["nome"]
			ui.nascondi_box()
			await ui.vignetta(r["chi"], r.get("faccia", "serio"), r["nome"])
		"vignetta":
			ui.nascondi_box()
			await ui.vignetta(r["chi"], r.get("faccia", "serio"), r.get("nome", ""), float(r.get("s", 1.5)))
		"trittico":
			ui.nascondi_box()
			await ui.trittico(r["chi"], float(r.get("s", 2.0)))
		"fatto":
			mondo.fatti[r["id"]] = true
		"scontro":
			ui.nascondi_box()
			await _scontro(r)

## SCONTRO (13/11/2026): il combat della prova grezza 3 dentro la storia. Il mondo esce dalla scena finché si combatte
## (così non si vede sotto l'arena), poi rientra com'era. Se perdi riprovi; si va avanti solo vincendo.
func _scontro(r: Dictionary) -> void:
	var hud_prima: bool = _hud.visible
	_hud.visible = false
	remove_child(mondo)
	var vinto := false
	while not vinto:
		var sc: Node3D = preload("res://scripts/scontro/scontro.gd").new()
		sc.configure({"squadra": r.get("squadra", mondo.gruppo.duplicate()), "nemico": r.get("nemico", "ANOMALIA"), "forza": r.get("forza", 1.0),
			"prova": OS.get_cmdline_user_args().has("prova")})
		var esito: Array = [null]
		sc.finito.connect(func(v: bool) -> void: esito[0] = v)
		sc.riprova.connect(func() -> void: esito[0] = "riprova")
		add_child(sc)
		while esito[0] == null:
			await get_tree().process_frame
		sc.queue_free()
		await get_tree().process_frame
		vinto = esito[0] is bool and esito[0]
	add_child(mondo)
	mondo.camera.current = true
	print("SCONTRO: vinto contro ", r.get("nemico", "ANOMALIA"))
	_hud.visible = hud_prima

# ---------------------------------------------------------------- eventi del mondo

func _su_avviso(chi: String, punto: Dictionary) -> void:
	var testi: Dictionary = punto.get("avviso", {})
	if testi.has(chi):
		ui.balloon(chi, testi[chi], mondo.testa.bind(chi), mondo.camera, 3.0)

func _su_esamina_cambiato(p) -> void:
	punto_vicino = p
	if p != null:
		_bottone_esamina.text = "PARLA" if p.get("tipo", "") == "parla" else "ESAMINA"
	_bottone_esamina.visible = p != null and not occupato

func esamina() -> void:
	if punto_vicino == null or occupato:
		return
	var p: Dictionary = punto_vicino
	var nome: String = p["scena"]
	var per_chi: String = nome + "_" + str(mondo.gruppo[0])
	if dati["scene"].has(per_chi):
		nome = per_chi
	await esegui(nome)
	mondo.segna_fatto(p["id"])
	if p.has("preso"):
		_toast("PRESO  ·  " + p["preso"])
	if p.get("tipo", "") == "traccia":
		var tt := tracce()
		_toast("TRACCIA %d/%d  ·  %s" % [tt.x, tt.y, p.get("nome", "")])
	match p.get("dopo", ""):
		"quartiere":
			await ui.cartello("FUORI", "Il quartiere")
			await vai_al_quartiere()
			return
		"nido":
			await ui.cartello("DENTRO IL VARCO", "Il nido")
			_zona("nido", mondo.gruppo.duplicate())
			_hud.visible = true
			await get_tree().create_timer(0.3).timeout
			await esegui("nido")
		"fine":
			if not finita:
				finita = true
				var tt := tracce()
				await ui.cartello("TRACCE TROVATE", "%d su %d" % [tt.x, tt.y])
				await ui.cartello("FINE DELLA DEMO", "La vera avventura comincia nel Capitolo 1")
				await esegui("dopo_fine")
	_libera()

## 0.6: tracce trovate e totali, contate su tutte le zone (oggetti che raccontano, U20).
func tracce() -> Vector2i:
	var tot := 0
	var trovate := 0
	for z in dati["zone"]:
		for p in dati["zone"][z]["punti"]:
			if p.get("tipo", "") == "traccia":
				tot += 1
				if mondo.fatti.has(p["id"]):
					trovate += 1
	return Vector2i(trovate, tot)

func _su_innesco(id: String) -> void:
	match id:
		"sciame":
			await esegui("sciame")
			_libera()
		"ingordo", "covata":   # 0.7, PROPOSTA approvato dall'autore il 14/11/2026: le due ali del nido
			await esegui(id)
			mondo.fatti[id] = true
			_libera()
		"sagoma":
			_righe(dati["scene"]["sagoma"])
		"rio":
			_hud.visible = false
			await esegui("rio")
			await ui.cartello("POCO DOPO", "Seminterrato di una lavanderia a gettoni")
			_zona("rifugio", ["lance"])
			_hud.visible = true
			await esegui("rifugio")
			_libera()

func vai_al_quartiere() -> void:
	_zona("quartiere", ["lance", "nox", "saul", "rio"])
	_hud.visible = true
	_bottone_cambia.visible = true
	await get_tree().create_timer(0.3).timeout
	await esegui("quartiere")
	_libera()

func cambia_guida() -> void:
	if occupato or mondo.gruppo.size() < 2:
		return
	mondo.cambia_guida()
	_aggiorna_hud()

func _process(delta: float) -> void:
	if dati["zone"].get(mondo.zona, {}).has("chiacchiere") and mondo.controllo and not occupato:
		_timer_chiacchiere += delta
		if _timer_chiacchiere > 24.0:
			_timer_chiacchiere = 0.0
			var lista: Array = dati["zone"][mondo.zona]["chiacchiere"]
			_righe(lista[_chiacchiera_i % lista.size()])
			_chiacchiera_i += 1

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode in [KEY_E, KEY_ENTER, KEY_SPACE]:
			esamina()
		elif e.keycode in [KEY_Q, KEY_TAB]:
			cambia_guida()

# ---------------------------------------------------------------- HUD

func _titolo() -> void:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(c)
	var s := get_viewport().get_visible_rect().size
	var fondo := ColorRect.new()
	fondo.color = Color(0.01, 0.0, 0.01, 0.6)
	fondo.size = s
	c.add_child(fondo)
	var r := Rect2(-40, s.y * 0.16, s.x * 0.86, s.y * 0.5)
	var bianco := Polygon2D.new()
	bianco.polygon = Fumetto.fulmine(r.grow(16), 50.0, 36.0, 21)
	bianco.color = Fumetto.BIANCO
	c.add_child(bianco)
	var rosso := Polygon2D.new()
	rosso.polygon = Fumetto.fulmine(r, 50.0, 26.0, 22)
	rosso.color = Fumetto.ROSSO
	c.add_child(rosso)
	var punti := Polygon2D.new()
	punti.polygon = rosso.polygon
	punti.material = Fumetto.retino(Color(0.3, 0.0, 0.05, 0.9), Color(0, 0, 0, 0), 14.0, Vector2(r.end.x, r.position.y), Vector2(r.position.x + r.size.x * 0.4, r.end.y), 0.5, 0.0)
	c.add_child(punti)
	var t := Fumetto.ritagli("ODISPEL", Fumetto.BIANCO, 128.0, 5)
	t.rotation_degrees = -6.0
	t.position = Vector2(s.x * 0.08, s.y * 0.2)
	c.add_child(t)
	var st := Label.new()
	st.text = "  DEMO  ·  CAPITOLO 1  "
	st.add_theme_font_override("font", ui.font_dialogo)
	st.add_theme_font_size_override("font_size", 44)
	st.add_theme_color_override("font_color", Fumetto.BIANCO)
	var sbt := StyleBoxFlat.new()
	sbt.bg_color = Fumetto.NERO
	sbt.skew = Vector2(0.3, 0)
	st.add_theme_stylebox_override("normal", sbt)
	st.rotation_degrees = -6.0
	st.position = Vector2(s.x * 0.14, s.y * 0.52)
	c.add_child(st)
	var pr := Label.new()
	pr.text = "Tocca per iniziare"
	pr.add_theme_font_override("font", ui.font_dialogo)
	pr.add_theme_font_size_override("font_size", 34)
	pr.add_theme_color_override("font_outline_color", Fumetto.NERO)
	pr.add_theme_constant_override("outline_size", 8)
	pr.position = Vector2(s.x * 0.5 - 130, s.y * 0.78)
	c.add_child(pr)
	var tw := create_tween().set_loops()
	tw.tween_property(pr, "modulate:a", 0.25, 0.6)
	tw.tween_property(pr, "modulate:a", 1.0, 0.6)
	mondo.camera_a("alto", 0.0)
	ui.attivo = true
	await ui.avanti
	ui.attivo = false
	tw.kill()
	c.queue_free()

func _chip(testo: String, col: Color) -> Label:
	var l := Label.new()
	l.text = testo
	l.add_theme_font_override("font", ui.font_dialogo)
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", Fumetto.BIANCO)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Fumetto.NERO
	sb.border_color = col
	sb.border_width_bottom = 5
	sb.border_width_left = 12
	sb.skew = Vector2(0.3, 0)
	sb.shadow_color = col
	sb.shadow_offset = Vector2(5, 5)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	l.add_theme_stylebox_override("normal", sb)
	return l

func _bottone(testo: String, col: Color) -> Button:
	var b := Button.new()
	b.text = testo
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", ui.font_dialogo)
	b.add_theme_font_size_override("font_size", 40)
	b.custom_minimum_size = Vector2(230, 96)
	for stato in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col if stato != "normal" else Fumetto.NERO
		sb.border_color = Fumetto.BIANCO
		sb.set_border_width_all(4)
		sb.skew = Vector2(0.32, 0)
		sb.shadow_color = col
		sb.shadow_offset = Vector2(8, 8)
		b.add_theme_stylebox_override(stato, sb)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.BLACK)
	return b

func _costruisci_hud() -> void:
	var livello := CanvasLayer.new()
	livello.layer = 5
	add_child(livello)
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.visible = false
	livello.add_child(_hud)
	_chip_luogo = _chip("", Fumetto.ROSSO)
	_chip_luogo.position = Vector2(28, 22)
	_hud.add_child(_chip_luogo)
	_chip_guida = _chip("", Color("#ff2340"))
	_chip_guida.position = Vector2(28, 74)
	_hud.add_child(_chip_guida)
	_bottone_esamina = _bottone("ESAMINA", Fumetto.ROSSO)
	_bottone_esamina.visible = false
	_bottone_esamina.pressed.connect(esamina)
	_hud.add_child(_bottone_esamina)
	_bottone_cambia = _bottone("CAMBIA", Fumetto.BIANCO)
	_bottone_cambia.custom_minimum_size = Vector2(230, 86)
	_bottone_cambia.visible = false
	_bottone_cambia.pressed.connect(cambia_guida)
	_hud.add_child(_bottone_cambia)
	_stick = preload("res://scripts/stick.gd").new()
	_stick.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stick.mondo = mondo
	_hud.add_child(_stick)
	_hud.move_child(_stick, 0)
	get_viewport().size_changed.connect(_impagina_hud)
	_impagina_hud()

## Posizioni a mano: con lo schermo largo del telefono il lato destro si sposta.
func _impagina_hud() -> void:
	var s := get_viewport().get_visible_rect().size
	_bottone_esamina.position = Vector2(s.x - 290, s.y - 150)
	_bottone_cambia.position = Vector2(s.x - 290, s.y - 262)

func _aggiorna_hud() -> void:
	var chi: String = mondo.gruppo[0] if not mondo.gruppo.is_empty() else "lance"
	_chip_guida.text = "GUIDA  " + ui.nomi.get(chi, chi.to_upper())
	var sb: StyleBoxFlat = _chip_guida.get_theme_stylebox("normal")
	sb.border_color = ui.COLORE.get(chi, Color.WHITE)
	_chip_guida.visible = mondo.gruppo.size() > 1

func _toast(testo: String) -> void:
	var l := _chip(testo, Color("#2ef2ff"))
	var s := get_viewport().get_visible_rect().size
	l.position = Vector2(s.x * 0.5 - 200, -60)
	_hud.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", 130.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)
