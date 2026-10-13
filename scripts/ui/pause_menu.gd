class_name PauseMenu
extends Control

# Pausa in battaglia (tasto ESC o "indietro" di Android): riprendere, impostazioni o uscire.
# In solitaria la battaglia e' a turni, quindi basta coprire i comandi; in rete la partita continua.

signal resumed
signal quit_requested

var networked: bool = false
var resume_button: Button


static func open(host: Node, is_networked: bool = false) -> PauseMenu:
	var m := PauseMenu.new()
	m.networked = is_networked
	host.add_child(m)
	return m


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var panel := HudPanel.new().setup("PAUSA", BattleTheme.CY)
	panel.position = Vector2(440, 190)
	panel.size = Vector2(400, 340)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.set_content(box)
	var title := BattleTheme.make_label("PAUSA", 36, BattleTheme.CY, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	if networked:
		var note := BattleTheme.make_label("IN RETE LA BATTAGLIA CONTINUA", 13, BattleTheme.CY_DIM)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(note)
	resume_button = _button(box, "RIPRENDI", "primary", 64, 28)
	resume_button.pressed.connect(close)
	var settings: Button = _button(box, "IMPOSTAZIONI", "normal", 50, 22)
	settings.pressed.connect(func() -> void: SettingsPanel.open(self))
	var leave: Button = _button(box, "ESCI DALLA PARTITA" if networked else "ESCI DALLA BATTAGLIA", "normal", 50, 20)
	leave.pressed.connect(func() -> void:
		quit_requested.emit()
		queue_free())


func _button(box: Control, text: String, kind: String, h: float, fs: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, h)
	b.focus_mode = Control.FOCUS_NONE
	BattleTheme.style_button(b, kind, fs)
	box.add_child(b)
	return b


func close() -> void:
	resumed.emit()
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		for c in get_children():
			if c is SettingsPanel:
				return          # ESC chiude prima le impostazioni (le gestisce il pannello)
		get_viewport().set_input_as_handled()
		close()
