class_name SettingsPanel
extends Control

# Finestra delle impostazioni: volumi, muto, schermo intero, rivedi il tutorial.
# Si apre sopra la schermata corrente con SettingsPanel.open(nodo).

signal closed

var music_slider: HSlider
var sfx_slider: HSlider
var mute_box: Button
var full_box: Button
var vsync_box: Button
var fps_button: Button
var light_box: Button
var banter_box: Button
var tutorial_button: Button
var art_folder_button: Button
var art_reload_button: Button
var art_label: Label
var _music_value: Label
var _sfx_value: Label


static func open(host: Node) -> SettingsPanel:
	var panel := SettingsPanel.new()
	host.add_child(panel)
	return panel


func _ready() -> void:
	Settings.ensure_loaded()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := HudPanel.new().setup("IMPOSTAZIONI", BattleTheme.CY)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -300.0
	panel.offset_right = 300.0
	panel.offset_top = -300.0
	panel.offset_bottom = 300.0
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.set_content(box)

	music_slider = _slider_row(box, "MUSICA", Settings.music, true)
	sfx_slider = _slider_row(box, "EFFETTI", Settings.sfx, false)

	mute_box = _toggle(box, Settings.muted, _on_mute, "AUDIO: MUTO  (tasto M)", "AUDIO: ATTIVO  (tasto M)")
	full_box = _toggle(box, Settings.fullscreen, _on_fullscreen, "SCHERMO INTERO: SI", "SCHERMO INTERO: NO")
	vsync_box = _toggle(box, Settings.vsync, _on_vsync, "V-SYNC: SI", "V-SYNC: NO")
	light_box = _toggle(box, Settings.light_fx, _on_light_fx, "EFFETTI RIDOTTI: SI (piu' fluido)", "EFFETTI RIDOTTI: NO")
	banter_box = _toggle(box, Settings.banter, _on_banter, "BATTUTE IN BATTAGLIA: SI", "BATTUTE IN BATTAGLIA: NO")
	fps_button = Button.new()
	fps_button.text = Settings.fps_text()
	fps_button.custom_minimum_size = Vector2(0, 40)
	BattleTheme.style_button(fps_button, "normal", 20)
	fps_button.pressed.connect(_on_fps)
	box.add_child(fps_button)

	box.add_child(HSeparator.new())

	tutorial_button = Button.new()
	tutorial_button.text = "RIVEDI TUTORIAL E STORIA"
	tutorial_button.custom_minimum_size = Vector2(0, 40)
	BattleTheme.style_button(tutorial_button, "normal", 20)
	tutorial_button.pressed.connect(_on_tutorial)
	box.add_child(tutorial_button)

	art_label = BattleTheme.make_label("", 15, BattleTheme.CY_DIM)
	box.add_child(art_label)
	var art_row := HBoxContainer.new()
	art_row.add_theme_constant_override("separation", 10)
	box.add_child(art_row)
	art_folder_button = Button.new()
	art_folder_button.text = "APRI CARTELLA GRAFICHE"
	art_folder_button.custom_minimum_size = Vector2(0, 40)
	art_folder_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	BattleTheme.style_button(art_folder_button, "normal", 16)
	art_folder_button.pressed.connect(func() -> void: ArtLibrary.open_folder())
	art_row.add_child(art_folder_button)
	art_reload_button = Button.new()
	art_reload_button.text = "RICARICA GRAFICHE"
	art_reload_button.custom_minimum_size = Vector2(0, 40)
	art_reload_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	BattleTheme.style_button(art_reload_button, "normal", 16)
	art_reload_button.pressed.connect(_on_art_reload)
	art_row.add_child(art_reload_button)
	_update_art_label()

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var close := Button.new()
	close.text = "CHIUDI"
	close.custom_minimum_size = Vector2(0, 46)
	BattleTheme.style_button(close, "primary", 22)
	close.pressed.connect(close_panel)
	box.add_child(close)


# Interruttore a pulsante: pieno (rosso) = acceso. Il testo dice lo stato.
func _toggle(parent: Control, value: bool, handler: Callable, on_text: String, off_text: String) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(0, 36)
	b.set_pressed_no_signal(value)
	var refresh := func(on: bool) -> void:
		b.text = on_text if on else off_text
		BattleTheme.style_button(b, "primary" if on else "normal", 17)
	refresh.call(value)
	b.toggled.connect(refresh)
	b.toggled.connect(handler)
	parent.add_child(b)
	return b


func _slider_row(parent: Control, caption: String, value: float, is_music: bool) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var label := BattleTheme.make_label(caption, 16, BattleTheme.CY)
	label.custom_minimum_size = Vector2(110, 0)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 28)
	row.add_child(slider)
	var shown := BattleTheme.make_label("%d%%" % int(round(value * 100.0)), 16, BattleTheme.WH)
	shown.custom_minimum_size = Vector2(60, 0)
	row.add_child(shown)
	if is_music:
		_music_value = shown
		slider.value_changed.connect(_on_music)
	else:
		_sfx_value = shown
		slider.value_changed.connect(_on_sfx)
		# ssentire l'effetto di quanto e' forte appena si rilascia
		slider.drag_ended.connect(func(_changed: bool) -> void: Snd.play("hit"))
	return slider


func _apply() -> void:
	var m: Node = get_node_or_null("/root/Sfx")
	if m != null:
		m.apply_settings()


func _on_music(v: float) -> void:
	Settings.music = v
	_music_value.text = "%d%%" % int(round(v * 100.0))
	_apply()


func _on_sfx(v: float) -> void:
	Settings.sfx = v
	_sfx_value.text = "%d%%" % int(round(v * 100.0))
	_apply()


func _on_mute(on: bool) -> void:
	Settings.muted = on
	_apply()


func _on_vsync(on: bool) -> void:
	Settings.vsync = on
	_apply()


func _on_banter(on: bool) -> void:
	Settings.banter = on
	_apply()


func _on_light_fx(on: bool) -> void:
	Settings.light_fx = on
	_apply()


func _on_fps() -> void:
	Settings.fps_limit = Settings.next_fps_limit()
	fps_button.text = Settings.fps_text()
	_apply()


func _on_fullscreen(on: bool) -> void:
	Settings.fullscreen = on
	_apply()


func _on_tutorial() -> void:
	Settings.tutorial_done = false
	Settings.seen_scenes = []
	Settings.save()
	Notify.success("Tutorial e scene di storia ripartiranno dal prossimo combattimento.")


func _update_art_label() -> void:
	var rep: Dictionary = ArtLibrary.report()
	art_label.text = "GRAFICHE TROVATE: %d / %d  (le mancanti usano il segnaposto)" % [rep["found"].size(), int(rep["total"])]


func _on_art_reload() -> void:
	ArtLibrary.refresh()
	_update_art_label()
	Notify.success("Grafiche ricaricate.")


func close_panel() -> void:
	Settings.save()
	closed.emit()
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close_panel()
