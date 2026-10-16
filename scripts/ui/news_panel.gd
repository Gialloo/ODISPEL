class_name NewsPanel
extends Control

# Finestra "NOVITA'": elenca cosa e' cambiato nella versione appena installata. Si chiude con OK o con ESC.

signal closed

var entry: Dictionary = {}


static func open(host: Node, news: Dictionary) -> NewsPanel:
	var p := NewsPanel.new()
	p.entry = news
	host.add_child(p)
	return p


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	ScreenFrame.overshoot(dim)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var panel := HudPanel.new().setup("NOVITA' · v" + str(entry.get("v", "")), BattleTheme.CY)
	panel.position = Vector2(256, 90)
	panel.size = Vector2(700, 540)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.set_content(box)
	# le novita' scorrono: con tante voci il tasto OK resta sempre visibile in fondo
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var items := VBoxContainer.new()
	items.add_theme_constant_override("separation", 10)
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(items)
	for item in entry.get("items", []):
		var label := BattleTheme.make_label("•  " + str(item), 19, BattleTheme.WH)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(620, 0)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.set_meta("keep_case", true)      # CREDITI e TEAM restano scritti come nel testo
		items.add_child(label)
	var ok := Button.new()
	ok.text = "OK, GIOCHIAMO"
	ok.custom_minimum_size = Vector2(0, 58)
	ok.focus_mode = Control.FOCUS_NONE
	BattleTheme.style_button(ok, "primary", 24)
	ok.pressed.connect(_close)
	box.add_child(ok)


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		get_viewport().set_input_as_handled()
		_close()
