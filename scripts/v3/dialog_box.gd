class_name DialogBox
extends Control

# Box di dialogo in basso: nome colorato, testo che scorre, tocco/clic/E per andare avanti, SALTA per chiudere tutto.

signal finished

var _lines: Array = []
var _i: int = -1
var _shown: float = 0.0
var _panel: PanelContainer
var _name: Label
var _text: Label
var _hint: Label
var _skip: Button
const CPS: float = 45.0           # caratteri al secondo


func _ready() -> void:
	Ui.place(self, 0, 0, 1, 1)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", Ui.box(Color(0.07, 0.04, 0.12, 0.94), Ui.CREAM, 4, 4, 8))
	Ui.place(_panel, 0.08, 1.0, 0.92, 1.0, 0, -230, 0, -28)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(vb)
	_name = Ui.label("", 26, Ui.YELLOW, Ui.display())
	vb.add_child(_name)
	_text = Ui.label("", 30 if Ui.is_touch() else 26, Ui.CREAM)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_text)
	_hint = Ui.label("tocca per continuare" if Ui.is_touch() else "[E] / clic per continuare", 18, Color(1, 1, 1, 0.55))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(_hint)
	_skip = Ui.button("SALTA", Ui.CREAM, 20)
	Ui.place(_skip, 1.0, 0, 1.0, 0, -170, 24, -24, 84)
	_skip.pressed.connect(_close)
	add_child(_skip)
	visible = false


func play(lines: Array) -> void:
	_lines = lines
	_i = -1
	visible = true
	Breadcrumb.mark("dialogo")
	_next()


func _next() -> void:
	_i += 1
	if _i >= _lines.size():
		_close()
		return
	var ln: Dictionary = _lines[_i]
	_name.text = str(ln.get("chi", ""))
	_name.add_theme_color_override("font_color", Color(str(ln.get("col", "#ffd23f"))))
	_text.text = str(ln.get("testo", ""))
	_shown = 0.0
	_text.visible_characters = 0


func _close() -> void:
	if not visible:
		return
	visible = false
	finished.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	_shown += delta * CPS
	_text.visible_characters = int(_shown)
	_hint.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006) if _done() else 0.0


func _done() -> bool:
	return _text.visible_characters >= _text.text.length() or _text.visible_characters < 0


func advance() -> void:
	if not visible:
		return
	if not _done():
		_shown = float(_text.text.length())
		_text.visible_characters = -1
	else:
		_next()


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		advance()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = (event as InputEventKey).physical_keycode
		if k in [KEY_E, KEY_ENTER, KEY_SPACE, KEY_KP_ENTER]:
			advance()
			get_viewport().set_input_as_handled()
		elif k == KEY_ESCAPE:
			_close()
			get_viewport().set_input_as_handled()
