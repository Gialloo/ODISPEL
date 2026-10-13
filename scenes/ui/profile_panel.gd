class_name ProfilePanel
extends Control

# Finestra del profilo: nome, icona (comuni, rare, epiche, leggendarie sbloccate) e banner.
# Si apre con ProfilePanel.open(nodo). Le scelte si salvano subito.

signal closed
signal changed

var name_edit: LineEdit
var preview: ProfileCard
var caption: Label
var icon_buttons: Dictionary = {}     # id icona -> Button
var banner_buttons: Array = []
var close_button: Button
var _roster: Dictionary = {}


static func open(host: Node) -> ProfilePanel:
	var panel := ProfilePanel.new()
	host.add_child(panel)
	return panel


func _ready() -> void:
	Profile.ensure_loaded()
	_roster = RosterStore.load_or_new()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	ScreenFrame.overshoot(dim)
	add_child(dim)

	var panel := HudPanel.new().setup("PROFILO", BattleTheme.CY)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -400.0
	panel.offset_right = 400.0
	panel.offset_top = -330.0
	panel.offset_bottom = 330.0
	add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.set_content(outer)

	preview = ProfileCard.new().setup(Profile.current(), Vector2(720, 72), _subtitle())
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	outer.add_child(preview)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)

	box.add_child(BattleTheme.make_label("NOME PROFILO", 14, BattleTheme.CY_DIM))
	name_edit = LineEdit.new()
	name_edit.max_length = Profile.NAME_MAX
	name_edit.text = Profile.player_name
	name_edit.placeholder_text = Profile.DEFAULT_NAME
	name_edit.custom_minimum_size = Vector2(0, 44)
	name_edit.add_theme_font_size_override("font_size", 22)
	name_edit.text_changed.connect(_on_name)
	box.add_child(name_edit)

	box.add_child(BattleTheme.make_label("ICONA   (le rare, epiche e leggendarie si ottengono dai boss e dagli obiettivi)", 14, BattleTheme.CY_DIM))
	var ig := GridContainer.new()
	ig.columns = 9
	ig.add_theme_constant_override("h_separation", 8)
	ig.add_theme_constant_override("v_separation", 8)
	box.add_child(ig)
	var ids: Array = Profile.ICONS.keys()
	for cid in BattleContent.CHARACTERS:
		if RosterState.owns(_roster, str(cid)):
			ids.append("char:" + str(cid))
	for id in ids:
		_add_icon_button(ig, str(id))

	caption = BattleTheme.make_label("", 15, BattleTheme.WH)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.custom_minimum_size = Vector2(0, 40)
	box.add_child(caption)
	_describe(Profile.icon)

	box.add_child(BattleTheme.make_label("BANNER", 14, BattleTheme.CY_DIM))
	var bg := GridContainer.new()
	bg.columns = 4
	bg.add_theme_constant_override("h_separation", 8)
	bg.add_theme_constant_override("v_separation", 8)
	box.add_child(bg)
	for i in Profile.BANNERS.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(172, 46)
		b.toggle_mode = true
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		var sw := ProfileCard.new().setup({"name": str(Profile.BANNERS[i][0]), "icon": "c_sword", "banner": i}, Vector2(172, 46))
		sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(sw)
		b.pressed.connect(_on_banner.bind(i))
		bg.add_child(b)
		banner_buttons.append(b)
	_refresh_marks()

	close_button = Button.new()
	close_button.text = "FATTO"
	close_button.custom_minimum_size = Vector2(0, 50)
	BattleTheme.style_button(close_button, "primary", 22)
	close_button.pressed.connect(close_panel)
	outer.add_child(close_button)


func _subtitle() -> String:
	Profile.ensure_loaded()
	return "%s  ·  %s" % [Profile.icon_name(Profile.icon).to_upper(), str(Profile.BANNERS[Profile.banner][0]).to_upper()]


func _add_icon_button(parent: Control, id: String) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(68, 68)
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	var ic := ProfileCard.ProfileIcon.new().setup(id, 62.0)
	ic.position = Vector2(3, 3)
	var locked: bool = not Profile.is_unlocked(id)
	if locked:
		ic.modulate = Color(0.35, 0.38, 0.45, 0.9)
	b.add_child(ic)
	if locked:
		var lock := BattleTheme.make_label("?", 26, Color(1, 1, 1, 0.7), true)
		lock.position = Vector2(26, 16)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(lock)
	b.pressed.connect(_on_icon.bind(id))
	parent.add_child(b)
	icon_buttons[id] = b


func _on_name(text: String) -> void:
	Profile.rename_to(text)
	Profile.save()
	_update_preview()


func _on_icon(id: String) -> void:
	_describe(id)
	if Profile.select_icon(id):
		Profile.save()
		_update_preview()
		_refresh_marks()


func _on_banner(i: int) -> void:
	Profile.select_banner(i)
	Profile.save()
	_update_preview()
	_refresh_marks()


func _describe(id: String) -> void:
	if id.begins_with("char:"):
		caption.text = "%s  ·  volto dell'operatore" % Profile.icon_name(id).to_upper()
		caption.add_theme_color_override("font_color", BattleTheme.WH)
		return
	var r: int = Profile.rarity_of(id)
	var how: String = str(Profile.ICONS[id][4])
	var state: String = "" if Profile.is_unlocked(id) else "  (BLOCCATA)"
	caption.text = "%s  ·  %s%s\n%s" % [Profile.icon_name(id).to_upper(), Profile.RARITY_NAMES[r], state, how]
	caption.add_theme_color_override("font_color", Profile.RARITY_COLORS[r])


func _refresh_marks() -> void:
	for id in icon_buttons:
		var b: Button = icon_buttons[id]
		b.queue_redraw()
		var on: bool = str(id) == Profile.icon
		b.modulate = Color(1.25, 1.25, 1.25) if on else Color.WHITE
	for i in banner_buttons.size():
		(banner_buttons[i] as Button).set_pressed_no_signal(i == Profile.banner)
		(banner_buttons[i] as Button).modulate = Color(1.3, 1.3, 1.3) if i == Profile.banner else Color(0.8, 0.8, 0.8)


func _update_preview() -> void:
	preview.update_data(Profile.current(), _subtitle())
	changed.emit()


func close_panel() -> void:
	Profile.save()
	closed.emit()
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close_panel()
