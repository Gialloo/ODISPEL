class_name SettingsPanel
extends PanelContainer

# Pannello impostazioni (menu e pausa): scosse, lampi, sequenza ultimate, effetti ridotti, vibrazione, FPS.

signal closed

var _rows: GridContainer


func _ready() -> void:
	add_theme_stylebox_override("panel", Ui.box(Color(0.08, 0.05, 0.14, 0.97), Ui.CREAM, 4, 6, 8))
	set_anchors_preset(Control.PRESET_CENTER)
	# Due colonne: sul telefono l'altezza logica resta 720 e otto righe in colonna uscivano dallo schermo.
	custom_minimum_size = Vector2(1120, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	add_child(vb)
	var t := Ui.label("IMPOSTAZIONI", 32, Ui.YELLOW, Ui.display())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	_rows = GridContainer.new()
	_rows.columns = 2
	_rows.add_theme_constant_override("h_separation", 28)
	_rows.add_theme_constant_override("v_separation", 8)
	vb.add_child(_rows)
	var ok := Ui.button("CHIUDI", Ui.YELLOW, 24)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.custom_minimum_size.x = 320
	ok.pressed.connect(func() -> void:
		Settings.save()
		closed.emit()
		queue_free())
	vb.add_child(ok)
	var pad := Control.new()
	pad.custom_minimum_size.y = 6
	vb.add_child(pad)
	_build()
	_fit()


# Sempre al centro e sempre tutto dentro lo schermo: sul telefono (e in pausa) il pannello finiva in basso a destra,
# mezzo fuori, con le etichette staccate dai tasti. Ora si ricentra a ogni fotogramma e, se non ci sta, si rimpicciolisce.
func _process(_delta: float) -> void:
	_fit()


func _fit() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var sz: Vector2 = get_combined_minimum_size().max(size)
	if sz.x < 1.0 or vp.x < 1.0:
		return
	var k: float = minf(1.0, minf((vp.x - 24.0) / sz.x, (vp.y - 24.0) / sz.y))
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size = sz
	pivot_offset = Vector2.ZERO
	scale = Vector2(k, k)
	position = ((vp - sz * k) * 0.5).max(Vector2.ZERO)


func _build() -> void:
	for c in _rows.get_children():
		c.queue_free()
	_row("Scosse della camera", Settings.level_text(Settings.shake), func() -> void: Settings.shake = Settings.next_level(Settings.shake))
	_row("Lampi", Settings.level_text(Settings.flash), func() -> void: Settings.flash = Settings.next_level(Settings.flash))
	# tre scelte: sempre, solo la prima volta per personaggio (le ripetute si saltano), mai
	_row("Sequenza ultimate", "SALTA" if Settings.skip_cutin else ("SOLO LA PRIMA" if Settings.cutin_once else "MOSTRA"), func() -> void:
		if Settings.skip_cutin:
			Settings.skip_cutin = false
			Settings.cutin_once = false
		elif Settings.cutin_once:
			Settings.skip_cutin = true
		else:
			Settings.cutin_once = true)
	_row("Telecamera rotta (PV bassi)", "SÌ" if Settings.broken_cam else "NO", func() -> void: Settings.broken_cam = not Settings.broken_cam)
	_row("Effetti ridotti", "SÌ" if Settings.light_fx else "NO", func() -> void: Settings.light_fx = not Settings.light_fx)
	_row("Vibrazione", "SÌ" if Settings.vibration else "NO", func() -> void: Settings.vibration = not Settings.vibration)
	_row("Velocità del testo", str(Settings.TEXT_SPEEDS[Settings.text_speed]), func() -> void:
		Settings.text_speed = (Settings.text_speed + 1) % Settings.TEXT_SPEEDS.size())
	_row("Dialoghi automatici", "SÌ" if Settings.auto_text else "NO", func() -> void: Settings.auto_text = not Settings.auto_text)
	_row("Finestra di parata", "AMPIA" if Settings.parry_wide else "NORMALE", func() -> void: Settings.parry_wide = not Settings.parry_wide)
	_row("Attacco a sorpresa (prova A/B)", "SÌ" if Settings.surprise else "NO", func() -> void: Settings.surprise = not Settings.surprise)
	_row("Limite FPS", "%d" % Settings.fps_value(), func() -> void:
		Settings.next_fps()
		Settings.apply_fps())
	_row("Contatore FPS", "SÌ" if Settings.show_fps else "NO", func() -> void: Settings.show_fps = not Settings.show_fps)


func _row(text: String, value: String, change: Callable) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l := Ui.label(text, 22, Ui.CREAM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(l)
	var b := Ui.button(value, Ui.CYAN, 20, 170)
	b.pressed.connect(func() -> void:
		change.call()
		Settings.save()
		_build())
	hb.add_child(b)
	_rows.add_child(hb)
