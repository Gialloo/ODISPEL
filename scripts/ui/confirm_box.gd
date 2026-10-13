class_name ConfirmBox
extends Control

# Domanda con due risposte (SI' / NO), sopra a tutto il resto. Esempio:
#   ConfirmBox.ask(self, "Luca non ha sbloccato questo livello.\nProcedere lo stesso?", func() -> void: avvia())

signal answered(yes: bool)

var message: String = ""
var yes_text: String = "SI', PROCEDI"
var no_text: String = "NO, ANNULLA"
var yes_button: Button
var no_button: Button


static func ask(host: Node, text: String, on_yes: Callable, yes_label: String = "SI', PROCEDI", no_label: String = "NO, ANNULLA") -> ConfirmBox:
	var c := ConfirmBox.new()
	c.message = text
	c.yes_text = yes_label
	c.no_text = no_label
	c.answered.connect(func(yes: bool) -> void:
		if yes and on_yes.is_valid():
			on_yes.call())
	host.add_child(c)
	return c


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var panel := HudPanel.new().setup("ATTENZIONE", BattleTheme.RD)
	panel.position = Vector2(306, 190)
	panel.size = Vector2(600, 320)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.set_content(box)
	var label := BattleTheme.make_label(message, 22, BattleTheme.WH)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(540, 120)
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(label)
	yes_button = _button(box, yes_text, "primary", 58, 24)
	yes_button.pressed.connect(func() -> void: _answer(true))
	no_button = _button(box, no_text, "normal", 50, 20)
	no_button.pressed.connect(func() -> void: _answer(false))


func _button(box: Control, text: String, kind: String, h: float, fs: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, h)
	b.focus_mode = Control.FOCUS_NONE
	BattleTheme.style_button(b, kind, fs)
	box.add_child(b)
	return b


func _answer(yes: bool) -> void:
	answered.emit(yes)
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_answer(false)
