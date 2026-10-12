class_name TutorialOverlay
extends Control

# Tutorial guidato del primo combattimento: oscura lo schermo, mette in luce una
# parte dell'interfaccia alla volta e la spiega. INVIO/SPAZIO = avanti, ESC = salta.
# steps: [{title, text, target: Control o null}]

signal finished(skipped: bool)

var steps: Array = []
var index: int = 0
var panel: HudPanel
var title_label: Label
var text_label: Label
var step_label: Label
var next_button: Button
var _t: float = 0.0
var _done: bool = false


func setup(new_steps: Array) -> TutorialOverlay:
	steps = new_steps
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	panel = HudPanel.new().setup("TUTORIAL", BattleTheme.RD)
	panel.size = Vector2(520, 280)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.set_content(box)
	step_label = BattleTheme.make_label("", 13, BattleTheme.CY_DIM)
	box.add_child(step_label)
	title_label = BattleTheme.make_label("", 26, BattleTheme.WH, true)
	box.add_child(title_label)
	text_label = BattleTheme.make_label("", 15, BattleTheme.CY)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(480, 120)
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(text_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var skip := Button.new()
	skip.text = "SALTA"
	skip.custom_minimum_size = Vector2(110, 40)
	BattleTheme.style_button(skip, "normal", 16)
	skip.pressed.connect(skip_tutorial)
	row.add_child(skip)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	next_button = Button.new()
	next_button.custom_minimum_size = Vector2(190, 40)
	BattleTheme.style_button(next_button, "primary", 18)
	next_button.pressed.connect(next)
	row.add_child(next_button)
	_show_step()


func _show_step() -> void:
	var s: Dictionary = steps[index]
	step_label.text = "%d / %d" % [index + 1, steps.size()]
	title_label.text = str(s["title"])
	text_label.text = str(s["text"])
	next_button.text = "INIZIA!" if index == steps.size() - 1 else "AVANTI"
	next_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place_panel()
	queue_redraw()


func target_rect() -> Rect2:
	var target: Variant = steps[index].get("target", null)
	if target is Control and is_instance_valid(target) and (target as Control).is_inside_tree():
		return (target as Control).get_global_rect().grow(8.0)
	return Rect2()


func _place_panel() -> void:
	var view: Vector2 = get_viewport_rect().size
	var r: Rect2 = target_rect()
	var pos: Vector2 = (view - panel.size) * 0.5
	if r.size != Vector2.ZERO:
		# sotto l'elemento se sta in alto, sopra se sta in basso; sempre dentro lo schermo
		if r.get_center().y < view.y * 0.5:
			pos.y = r.end.y + 18.0
		else:
			pos.y = r.position.y - panel.size.y - 18.0
		pos.x = clampf(r.get_center().x - panel.size.x * 0.5, 16.0, view.x - panel.size.x - 16.0)
		pos.y = clampf(pos.y, 16.0, view.y - panel.size.y - 16.0)
	panel.position = pos


func _draw() -> void:
	var view: Vector2 = get_viewport_rect().size
	var dim := Color(0.0, 0.02, 0.03, 0.78)
	var r: Rect2 = target_rect()
	if r.size == Vector2.ZERO:
		draw_rect(Rect2(Vector2.ZERO, view), dim)
		return
	draw_rect(Rect2(0, 0, view.x, r.position.y), dim)
	draw_rect(Rect2(0, r.end.y, view.x, view.y - r.end.y), dim)
	draw_rect(Rect2(0, r.position.y, r.position.x, r.size.y), dim)
	draw_rect(Rect2(r.end.x, r.position.y, view.x - r.end.x, r.size.y), dim)
	var pulse: float = 0.6 + 0.4 * sin(_t * 5.0)
	draw_rect(r, Color(BattleTheme.RD, pulse), false, 3.0)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func next() -> void:
	if _done:
		return
	if index >= steps.size() - 1:
		_finish(false)
		return
	index += 1
	_show_step()


func skip_tutorial() -> void:
	_finish(true)


func _finish(skipped: bool) -> void:
	if _done:
		return
	_done = true
	finished.emit(skipped)
	queue_free()


func _input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			next()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			skip_tutorial()
			get_viewport().set_input_as_handled()
		_:
			get_viewport().set_input_as_handled()   # niente ordini mentre si spiega
