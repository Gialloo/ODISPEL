class_name DialogueView
extends Control

# Scena di dialogo alla Persona: ritratti grandi ai lati (chi parla e' acceso, l'altro
# scuro), casella di testo inclinata con la targhetta del nome, scrittura lettera per
# lettera e scelte. Click / INVIO / SPAZIO = avanti, ESC o SALTA = salta la scena.

signal finished

const CHARS_PER_SECOND: float = 48.0
const PORTRAIT_SIZE: Vector2 = Vector2(560, 690)

var copione: DialogueScript
var index: int = -1
var finished_flag: bool = false
var typing: bool = false
var shown_chars: float = 0.0

var _bg_name: String = ""
var _left: PortraitView = null
var _right: PortraitView = null
var _box: PanelContainer
var _name_tag: PanelContainer
var _name_label: Label
var _text_label: Label
var _prompt: Label
var _choices_box: VBoxContainer
var _skip_button: Button
var _t: float = 0.0
var _talk_gate: int = 0
var _waiting_choice: bool = false


static func play(host: Node, text: String) -> DialogueView:
	var v := DialogueView.new()
	v.copione = DialogueScript.parse(text)
	host.add_child(v)
	return v


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	advance()


func _build() -> void:
	_left = PortraitView.new()
	_left.card = true
	_left.size = PORTRAIT_SIZE
	_left.position = Vector2(30, 40)
	_left.visible = false
	add_child(_left)
	_right = PortraitView.new()
	_right.card = true
	_right.size = PORTRAIT_SIZE
	_right.position = Vector2(690, 40)
	_right.flip = true
	_right.visible = false
	add_child(_right)

	# casella di testo: parallelogramma nero con filo rosso
	_box = PanelContainer.new()
	_box.add_theme_stylebox_override("panel", SlantBox.make(Color(0.02, 0.03, 0.04, 0.94), BattleTheme.WH, 34.0, BattleTheme.RD, 3.0))
	_box.position = Vector2(60, 500)
	_box.size = Vector2(1160, 190)
	add_child(_box)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	_box.add_child(inner)
	_text_label = BattleTheme.make_label("", 26, BattleTheme.WH)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(1060, 110)
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(_text_label)
	_prompt = BattleTheme.make_label("▼", 22, BattleTheme.RD, true)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	inner.add_child(_prompt)

	_name_tag = PanelContainer.new()
	_name_tag.add_theme_stylebox_override("panel", SlantBox.make(BattleTheme.RD, BattleTheme.WH, 22.0, BattleTheme.BK, 3.0))
	_name_tag.position = Vector2(90, 458)
	add_child(_name_tag)
	_name_label = BattleTheme.make_label("", 28, BattleTheme.WH, true)
	_name_tag.add_child(_name_label)

	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 10)
	_choices_box.position = Vector2(560, 250)
	_choices_box.size = Vector2(600, 200)
	_choices_box.visible = false
	add_child(_choices_box)

	_skip_button = Button.new()
	_skip_button.text = "SALTA  [ESC]"
	_skip_button.position = Vector2(1060, 16)
	_skip_button.size = Vector2(190, 40)
	BattleTheme.style_button(_skip_button, "normal", 16)
	_skip_button.pressed.connect(skip_all)
	add_child(_skip_button)


func _process(delta: float) -> void:
	_t += delta
	if typing and _text_label != null:
		shown_chars += delta * CHARS_PER_SECOND
		var total: int = _text_label.text.length()
		_text_label.visible_characters = int(shown_chars)
		var gate: int = int(shown_chars / 2.0)
		if gate != _talk_gate:
			_talk_gate = gate
			var c: int = clampi(int(shown_chars) - 1, 0, maxi(total - 1, 0))
			if total > 0 and _text_label.text[c] != " ":
				Snd.play("talk", randf_range(0.9, 1.15), -6.0)
		if int(shown_chars) >= total:
			_finish_typing()
	if _prompt != null:
		_prompt.visible = not typing and not _waiting_choice and int(_t * 2.0) % 2 == 0
	queue_redraw()


func _draw() -> void:
	var view: Vector2 = size
	var bg: Texture2D = ArtLibrary.background(_bg_name) if _bg_name != "" else null
	if bg != null:
		draw_texture_rect(bg, Rect2(Vector2.ZERO, view), false)
		draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, 0.35))
		return
	# senza sfondo: fondo nero con grandi bande diagonali, come un menu di Persona
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.01, 0.02, 0.03, 0.96))
	var drift: float = fmod(_t * 14.0, 200.0)
	for i in 9:
		var x: float = -300.0 + float(i) * 200.0 + drift
		draw_colored_polygon(PackedVector2Array([Vector2(x + 260.0, 0.0), Vector2(x + 380.0, 0.0), Vector2(x + 120.0, view.y), Vector2(x, view.y)]), Color(BattleTheme.RD, 0.10 if i % 2 == 0 else 0.05))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 410), Vector2(view.x, 360), Vector2(view.x, 420), Vector2(0, 470)]), Color(BattleTheme.CY, 0.08))


# ---------- Avanzamento ----------

func current_step() -> Dictionary:
	return copione.steps[index] if index >= 0 and index < copione.steps.size() else {}


func advance() -> void:
	if finished_flag or _waiting_choice:
		return
	if typing:
		_finish_typing(true)
		return
	index += 1
	while index < copione.steps.size():
		var step: Dictionary = copione.steps[index]
		match str(step["type"]):
			"bg":
				_bg_name = str(step["name"])
				index += 1
				continue
			"goto":
				index = int(copione.labels.get(str(step["label"]), copione.steps.size()))
				continue
			"end":
				_end()
				return
			"choice":
				_show_choice(step)
				return
			"line":
				_show_line(step)
				return
		index += 1
	_end()


func _show_line(step: Dictionary) -> void:
	var speaker: String = str(step["speaker"])
	_choices_box.visible = false
	_box.visible = true
	_name_tag.visible = speaker != ""
	if speaker != "":
		_name_label.text = _display_name(speaker)
		var portrait: PortraitView = _right if str(step["side"]) == "R" else _left
		var other: PortraitView = _left if portrait == _right else _right
		var boss: bool = BattleContent.BOSSES.has(speaker)
		if portrait.char_id != speaker or not portrait.visible:
			portrait.setup(speaker, "bust", boss)
			portrait.visible = true
			_slide_in(portrait, -120.0 if portrait == _left else 120.0)
		portrait.set_expression(str(step["expr"]))
		portrait.dimmed = false
		other.dimmed = true
	else:
		_left.dimmed = true
		_right.dimmed = true
	_text_label.text = str(step["text"])
	_text_label.visible_characters = 0
	shown_chars = 0.0
	typing = true


func _slide_in(node: Control, dx: float) -> void:
	var target: float = node.position.x
	node.position.x = target + dx
	node.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "position:x", target, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:a", 1.0, 0.15)


func _display_name(speaker: String) -> String:
	if BattleContent.CHARACTERS.has(speaker):
		return str(BattleContent.CHARACTERS[speaker]["name"]).to_upper()
	if BattleContent.BOSSES.has(speaker):
		return str(BattleContent.BOSSES[speaker]["name"]).to_upper()
	return speaker.to_upper()


func _finish_typing(play_sound: bool = false) -> void:
	typing = false
	_text_label.visible_characters = -1


func _show_choice(step: Dictionary) -> void:
	_waiting_choice = true
	_box.visible = true
	_prompt.visible = false
	for c in _choices_box.get_children():
		_choices_box.remove_child(c)
		c.queue_free()
	var options: Array = step["options"]
	for i in options.size():
		var b := Button.new()
		b.text = "%d  %s" % [i + 1, str(options[i]["text"])]
		b.custom_minimum_size = Vector2(0, 54)
		BattleTheme.style_button(b, "primary" if i == 0 else "normal", 22)
		b.pressed.connect(choose.bind(i))
		_choices_box.add_child(b)
	_choices_box.visible = true


func choose(option: int) -> void:
	if not _waiting_choice:
		return
	var options: Array = current_step()["options"]
	if option < 0 or option >= options.size():
		return
	_waiting_choice = false
	_choices_box.visible = false
	index = int(copione.labels.get(str(options[option]["goto"]), copione.steps.size()))
	index -= 1
	advance()


func skip_all() -> void:
	_end()


func _end() -> void:
	if finished_flag:
		return
	finished_flag = true
	finished.emit()
	queue_free()


# ---------- Comandi ----------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()


func _input(event: InputEvent) -> void:
	if finished_flag or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			advance()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			skip_all()
			get_viewport().set_input_as_handled()
		KEY_1, KEY_2, KEY_3:
			if _waiting_choice:
				choose(int(event.keycode) - int(KEY_1))
				get_viewport().set_input_as_handled()
		_:
			get_viewport().set_input_as_handled()
