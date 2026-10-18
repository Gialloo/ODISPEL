class_name SettingsPanel
extends PanelContainer

# Pannello impostazioni (menu e pausa): scosse, lampi, sequenza ultimate, effetti ridotti, vibrazione, FPS.

signal closed

var _rows: VBoxContainer


func _ready() -> void:
	add_theme_stylebox_override("panel", Ui.box(Color(0.08, 0.05, 0.14, 0.97), Ui.CREAM, 4, 6, 8))
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(620, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	add_child(vb)
	var t := Ui.label("IMPOSTAZIONI", 32, Ui.YELLOW, Ui.display())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 8)
	vb.add_child(_rows)
	var ok := Ui.button("CHIUDI", Ui.YELLOW, 24)
	ok.pressed.connect(func() -> void:
		Settings.save()
		closed.emit()
		queue_free())
	vb.add_child(ok)
	_build()
	await get_tree().process_frame
	position = (get_viewport_rect().size - size) * 0.5


func _build() -> void:
	for c in _rows.get_children():
		c.queue_free()
	_row("Scosse della camera", Settings.level_text(Settings.shake), func() -> void: Settings.shake = Settings.next_level(Settings.shake))
	_row("Lampi", Settings.level_text(Settings.flash), func() -> void: Settings.flash = Settings.next_level(Settings.flash))
	_row("Sequenza ultimate", "SALTA" if Settings.skip_cutin else "MOSTRA", func() -> void: Settings.skip_cutin = not Settings.skip_cutin)
	_row("Effetti ridotti", "SÌ" if Settings.light_fx else "NO", func() -> void: Settings.light_fx = not Settings.light_fx)
	_row("Vibrazione", "SÌ" if Settings.vibration else "NO", func() -> void: Settings.vibration = not Settings.vibration)
	_row("Contatore FPS", "SÌ" if Settings.show_fps else "NO", func() -> void: Settings.show_fps = not Settings.show_fps)


func _row(text: String, value: String, change: Callable) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	var l := Ui.label(text, 24, Ui.CREAM)
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
