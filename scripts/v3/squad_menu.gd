class_name SquadMenu
extends ColorRect

# MENU SQUADRA (pausa > SQUADRA), alla Persona 5: a sinistra la fila dei quattro (livello, barra dell'esperienza),
# a destra chi hai scelto: ritratto, statistiche e i cinque slot da equipaggiare (abilita', Ultimate, reazione personale,
# tratto, sinergia). Tocchi uno slot e scegli tra quello che hai sbloccato; il resto si vede col livello che serve.
# Funziona anche in battaglia con il gioco fermo (Engine.time_scale = 0): niente animazioni legate al tempo del gioco.

signal closed

const KINDS: Array = ["skill", "ult", "react", "trait", "syn"]
const KIND_NAMES: Dictionary = {"skill": "Abilità", "ult": "Ultimate", "react": "Reazione", "trait": "Tratto", "syn": "Sinergia"}
const PORTRAIT_DIR: String = "res://assets/portraits/"

var _sel: String = "ferri"
var _in_battle: bool = false
var _list: VBoxContainer
var _detail: Control
var _picker: Control = null
var _can_save: bool = true            # la demo dal menu non tocca il salvataggio


func _init(in_battle: bool = false, can_save: bool = true) -> void:
	_in_battle = in_battle
	_can_save = can_save
	color = Color(0.03, 0.01, 0.06, 0.96)
	Ui.place(self, 0, 0, 1, 1)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Progress.ensure()
	_build()


func _col(c: String) -> Color:
	return Ui.BATTLE_COLORS.get(str(BattleContent.CHARACTERS[c].get("color", "")), Ui.CREAM)


func _build() -> void:
	# fascia diagonale di fondo, del colore di chi e' selezionato (si rifa' in _refresh)
	var title := Ui.label("SQUADRA", 64, Ui.CREAM, Ui.display(), 12)
	title.rotation_degrees = -4.0
	Ui.place(title, 0, 0, 0, 0, 34, 14, 500, 100)
	add_child(title)
	var cam := Ui.label("CAM 07 · ● REC", 20, Color("#ff4630"), Ui.display(), 5)
	Ui.place(cam, 0, 0, 0, 0, 40, 96, 400, 124)
	add_child(cam)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 12)
	Ui.place(_list, 0, 0, 0, 1, 30, 140, 410, -100)
	add_child(_list)
	_detail = Control.new()
	Ui.place(_detail, 0, 0, 1, 1, 440, 20, -24, -100)
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_detail)
	var back := Ui.button("INDIETRO", Ui.CREAM, 26, 240)
	Ui.place(back, 0, 1, 0, 1, 30, -86, 270, -20)
	back.pressed.connect(_close)
	add_child(back)
	if _in_battle:
		var note := Ui.label("Le modifiche valgono dal prossimo scontro", 20, Color(1, 1, 1, 0.8))
		Ui.place(note, 0, 1, 1, 1, 300, -70, -20, -30)
		add_child(note)
	_refresh()


func _refresh() -> void:
	for ch in _list.get_children():
		ch.queue_free()
	for c in Progress.CAST:
		_list.add_child(_member_card(c))
	for ch in _detail.get_children():
		ch.queue_free()
	_build_detail()


func _member_card(c: String) -> Control:
	var on: bool = c == _sel
	var col: Color = _col(c)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(370, 104)
	b.add_theme_stylebox_override("normal", Ui.box(col.darkened(0.45) if on else Color(0.09, 0.06, 0.15, 0.95), col if on else Ui.INK, 5 if on else 3, 4, 6))
	b.add_theme_stylebox_override("hover", Ui.box(col.darkened(0.35), col, 4, 4, 6))
	b.add_theme_stylebox_override("pressed", Ui.box(col.darkened(0.3), col, 4, 4, 2))
	b.pressed.connect(func() -> void:
		_sel = c
		Settings.buzz(10)
		_refresh())
	b.rotation_degrees = -2.0 if on else 0.0
	var pic := TextureRect.new()
	var path: String = PORTRAIT_DIR + "%s_neutro.png" % c
	if ResourceLoader.exists(path):
		pic.texture = load(path)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.position = Vector2(8, 8)
	pic.size = Vector2(88, 88)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pic)
	var nm := Ui.label(str(BattleContent.CHARACTERS[c]["name"]).to_upper(), 28, col.lightened(0.35), Ui.display(), 6)
	nm.position = Vector2(108, 6)
	b.add_child(nm)
	var lv := Ui.label("LV %d" % Progress.level(c), 26, Ui.YELLOW, Ui.display(), 6)
	lv.position = Vector2(268, 8)
	b.add_child(lv)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 1000
	bar.value = Progress.exp_ratio(c) * 1000.0
	bar.position = Vector2(108, 56)
	bar.size = Vector2(248, 14)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	var fg := StyleBoxFlat.new()
	fg.bg_color = Ui.CYAN
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(bar)
	var ex := Ui.label("EXP · mancano %d" % (Progress.exp_need(Progress.level(c)) - int(Progress.data["exp"].get(c, 0))), 18, Color(1, 1, 1, 0.85))
	ex.position = Vector2(108, 72)
	b.add_child(ex)
	for ch in b.get_children():
		(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _build_detail() -> void:
	var c: String = _sel
	var col: Color = _col(c)
	# ritratto grande sul fondo a destra, tagliato, come nei menu di Persona
	var big := TextureRect.new()
	var path: String = PORTRAIT_DIR + "%s_felice.png" % c
	if not ResourceLoader.exists(path):
		path = PORTRAIT_DIR + "%s_neutro.png" % c
	if ResourceLoader.exists(path):
		big.texture = load(path)
	big.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	big.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	Ui.place(big, 1, 0, 1, 1, -330, 10, 20, -10)
	big.modulate = Color(1, 1, 1, 0.9)
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.add_child(big)
	var stripe := ColorRect.new()
	stripe.color = Color(col.r, col.g, col.b, 0.85)
	stripe.rotation_degrees = -3.0
	Ui.place(stripe, 0, 0, 0, 0, 0, 10, 520, 70)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.add_child(stripe)
	var nm := Ui.label("%s · LV %d" % [str(BattleContent.CHARACTERS[c]["name"]).to_upper(), Progress.level(c)], 40, Ui.INK, Ui.display())
	nm.rotation_degrees = -3.0
	Ui.place(nm, 0, 0, 0, 0, 16, 14, 520, 70)
	_detail.add_child(nm)
	var st: Dictionary = BattleContent.compute_stats(Progress.entry_for(c))
	var stats := Ui.label("PV %d   ATK %d   DIF %d   VEL %d" % [int(st["hp"]), int(st["atk"]), int(st["def"]), int(st["spd"])], 24, Ui.CREAM, Ui.display(), 6)
	Ui.place(stats, 0, 0, 0, 0, 8, 84, 620, 120)
	_detail.add_child(stats)
	var slots := VBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	Ui.place(slots, 0, 0, 0, 0, 8, 128, 560, 560)
	_detail.add_child(slots)
	for k in KINDS:
		slots.add_child(_slot_button(c, k))
	# prossimo sblocco
	var nxt: String = ""
	for u in Progress.UNLOCKS[c]:
		if int(u[0]) > Progress.level(c):
			nxt = "PROSSIMO SBLOCCO · LV %d · %s: %s" % [int(u[0]), str(KIND_NAMES[str(u[1])]), Progress.item_name(str(u[1]), str(u[2]))]
			break
	if c == "saul" and Progress.level(c) >= 7:
		nxt += ("\n" if nxt != "" else "") + "Mosse rubate: %d (si equipaggiano come ABILITÀ da tutti)" % (Progress.data.get("stolen", []) as Array).size()
	var nl := Ui.label(nxt, 20, Ui.YELLOW, null, 5)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ui.place(nl, 0, 1, 0, 1, 8, -70, 600, 0)
	_detail.add_child(nl)


func _slot_button(c: String, kind: String) -> Control:
	var id: String = Progress.equipped(c, kind)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(560, 70 if Ui.is_touch() else 62)
	b.add_theme_stylebox_override("normal", Ui.box(Color(0.1, 0.07, 0.17, 0.95), Ui.CREAM, 3, 4, 5))
	b.add_theme_stylebox_override("hover", Ui.box(Color(0.16, 0.11, 0.26, 0.95), Ui.YELLOW, 3, 4, 5))
	b.add_theme_stylebox_override("pressed", Ui.box(Color(0.2, 0.14, 0.3, 0.95), Ui.YELLOW, 3, 4, 2))
	b.pressed.connect(func() -> void: _open_picker(c, kind))
	var k := Ui.label(str(KIND_NAMES[kind]).to_upper(), 18, _col(c).lightened(0.3), Ui.display(), 4)
	k.position = Vector2(14, 4)
	b.add_child(k)
	var v := Ui.label(Progress.item_name(kind, id), 26, Ui.CREAM, Ui.display(), 5)
	v.position = Vector2(14, 26)
	b.add_child(v)
	for ch in b.get_children():
		(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _open_picker(c: String, kind: String) -> void:
	if _picker != null:
		_picker.queue_free()
	Settings.buzz(10)
	var veil := ColorRect.new()
	veil.color = Color(0, 0, 0, 0.7)
	Ui.place(veil, 0, 0, 1, 1)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(veil)
	_picker = veil
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Ui.box(Color(0.07, 0.04, 0.12, 0.98), _col(c), 4, 6, 8))
	Ui.place(panel, 0.5, 0.5, 0.5, 0.5, -440, -300, 440, 300)
	veil.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var t := Ui.label("%s · %s" % [str(BattleContent.CHARACTERS[c]["name"]).to_upper(), str(KIND_NAMES[kind]).to_upper()], 30, Ui.CREAM, Ui.display(), 6)
	vb.add_child(t)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(840, 430)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	var cur: String = Progress.equipped(c, kind)
	for o in Progress.options(c, kind):
		var id: String = str(o[0])
		var open: bool = bool(o[1])
		var ob := Button.new()
		ob.focus_mode = Control.FOCUS_NONE
		ob.custom_minimum_size = Vector2(820, 96)
		ob.disabled = not open
		var on: bool = id == cur
		ob.add_theme_stylebox_override("normal", Ui.box(_col(c).darkened(0.5) if on else Color(0.12, 0.09, 0.2, 0.95), Ui.YELLOW if on else Ui.INK, 3, 4, 4))
		ob.add_theme_stylebox_override("hover", Ui.box(Color(0.18, 0.13, 0.28, 0.95), Ui.YELLOW, 3, 4, 4))
		ob.add_theme_stylebox_override("pressed", Ui.box(Color(0.2, 0.14, 0.3, 0.95), Ui.YELLOW, 3, 4, 2))
		ob.add_theme_stylebox_override("disabled", Ui.box(Color(0.06, 0.05, 0.09, 0.95), Ui.INK, 3, 4, 4))
		var nm := Ui.label(Progress.item_name(kind, id) + ("  ✓" if on else "") + ("" if open else "   · LV %d" % int(o[2])), 24, Ui.CREAM if open else Color(1, 1, 1, 0.45), Ui.display(), 4)
		nm.position = Vector2(12, 4)
		ob.add_child(nm)
		var ds := Ui.label(Progress.item_desc(kind, id), 18, Color(1, 1, 1, 0.85 if open else 0.4))
		ds.position = Vector2(12, 38)
		ds.size = Vector2(796, 54)
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART      # due righe: la descrizione e il costo si leggono interi
		ds.clip_text = true
		ob.add_child(ds)
		for ch in ob.get_children():
			(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		ob.pressed.connect(func() -> void:
			Progress.equip(c, kind, id)
			Settings.buzz(25)
			_picker.queue_free()
			_picker = null
			_refresh())
		list.add_child(ob)
	var x := Ui.button("CHIUDI", Ui.CREAM, 22, 200)
	x.pressed.connect(func() -> void:
		_picker.queue_free()
		_picker = null)
	vb.add_child(x)


func _close() -> void:
	if _can_save:
		Story.save()
	closed.emit()
	queue_free()
