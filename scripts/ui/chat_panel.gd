class_name ChatPanel
extends Control

# Chat della stanza multiplayer, per coordinarsi. Due forme:
#  - piena (lobby): finestra sempre aperta;
#  - compatta (in battaglia): un pulsante CHAT che apre/chiude il riquadro e mostra l'ultimo messaggio.
# Usa NetworkManager.send_chat / chat_received / chat_log.

const ROWS_MAX: int = 40

var manager: NetworkManager
var compact: bool = false
var log_box: VBoxContainer
var scroll: ScrollContainer
var input: LineEdit
var send_button: Button
var toggle_button: Button
var body: Control
var preview_label: Label
var unread: int = 0
var _preview_left: float = 0.0
var _panel_size: Vector2 = Vector2(420, 260)


func setup(new_manager: NetworkManager, is_compact: bool, panel_size: Vector2 = Vector2(420, 260)) -> ChatPanel:
	manager = new_manager
	compact = is_compact
	_panel_size = panel_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	if manager != null:
		manager.chat_received.connect(_on_chat)
		for entry in manager.chat_log:
			_add_row(entry, false)
	return self


func _build() -> void:
	var y0: float = 0.0
	if compact:
		toggle_button = Button.new()
		toggle_button.custom_minimum_size = Vector2(110, 38)
		toggle_button.size = Vector2(110, 38)
		BattleTheme.style_button(toggle_button, "normal", 16)
		toggle_button.text = "CHAT"
		toggle_button.pressed.connect(toggle)
		add_child(toggle_button)
		preview_label = BattleTheme.make_label("", 15, BattleTheme.WH)
		preview_label.position = Vector2(118, 7)
		preview_label.size = Vector2(300, 24)
		preview_label.clip_text = true
		preview_label.visible = false
		preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(preview_label)
		y0 = 44.0

	var panel := HudPanel.new().setup("MESSAGGI", BattleTheme.CY)
	panel.position = Vector2(0, y0)
	panel.size = _panel_size
	body = panel
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.set_content(col)
	scroll = ArrowScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	log_box = VBoxContainer.new()
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_box.add_theme_constant_override("separation", 4)
	scroll.add_child(log_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	col.add_child(row)
	input = LineEdit.new()
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.custom_minimum_size = Vector2(0, 40)
	input.max_length = NetworkManager.CHAT_MAX_LEN
	input.placeholder_text = "Scrivi un messaggio..."
	input.add_theme_font_size_override("font_size", 18)
	input.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.45))
	input.text_submitted.connect(func(_t: String) -> void: _send())
	row.add_child(input)
	send_button = Button.new()
	send_button.text = "INVIA"
	send_button.custom_minimum_size = Vector2(84, 40)
	BattleTheme.style_button(send_button, "primary", 16)
	send_button.pressed.connect(_send)
	row.add_child(send_button)
	body.visible = not compact


func is_open() -> bool:
	return body.visible


func toggle() -> void:
	if not compact:
		return
	body.visible = not body.visible
	if body.visible:
		unread = 0
		_update_toggle()
		preview_label.visible = false
		input.grab_focus()
		_scroll_down()
	else:
		input.release_focus()


func _update_toggle() -> void:
	toggle_button.text = "CHAT" if unread == 0 else "CHAT (%d)" % unread


func _send() -> void:
	var text: String = input.text
	input.clear()
	if manager != null and manager.send_chat(text):
		_scroll_down()
	if compact:
		input.grab_focus()   # si continua a scrivere; per chiudere: tasto CHAT o indietro


func _on_chat(entry: Dictionary) -> void:
	_add_row(entry, true)
	if compact and not body.visible:
		unread += 1
		_update_toggle()
		preview_label.text = "%s: %s" % [str(entry["name"]), str(entry["text"])]
		preview_label.visible = true
		_preview_left = 6.0
		set_process(true)


func _add_row(entry: Dictionary, scroll_after: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var ic := ProfileCard.ProfileIcon.new().setup(str(entry.get("icon", "c_sword")), 26.0)
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(ic)
	var cols: Array = Profile.banner_colors(int(entry.get("banner", 0)))
	var mine: bool = manager != null and str(entry.get("id", "")) == manager.local_player_id
	var l := BattleTheme.make_label("", 16, BattleTheme.WH)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.text = "%s%s: %s" % [str(entry.get("name", "?")).to_upper(), " (TU)" if mine else "", str(entry.get("text", ""))]
	l.add_theme_color_override("font_color", BattleTheme.CY if mine else Color.WHITE.lerp(cols[1], 0.35))
	row.add_child(l)
	log_box.add_child(row)
	if scroll_after and AnimFx.enabled() and is_inside_tree():
		row.modulate.a = 0.0
		var tw: Tween = row.create_tween()
		tw.tween_property(row, "modulate:a", 1.0, 0.25)
	while log_box.get_child_count() > ROWS_MAX:
		var old: Node = log_box.get_child(0)
		log_box.remove_child(old)
		old.queue_free()
	if scroll_after:
		_scroll_down()


func _scroll_down() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if is_instance_valid(scroll):
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


func _process(delta: float) -> void:
	if _preview_left > 0.0:
		_preview_left -= delta
		if _preview_left <= 0.0 and preview_label != null:
			preview_label.visible = false
	else:
		set_process(false)


func _unhandled_key_input(event: InputEvent) -> void:
	if compact and body.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		toggle()
