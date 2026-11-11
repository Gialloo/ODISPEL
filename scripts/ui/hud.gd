extends CanvasLayer
## HUD minimo + pannello LAB per regolare il feeling dal vivo.

const M = preload("res://scripts/player/moves.gd")

var player: Node
var cam: Node
var touch: Control
var enemy_tune: Dictionary
var power: Node

var _font: Font
var _hp_bar: ColorRect
var _hp_back: ColorRect
var _forms: Array[Label] = []
var _info: Label
var _flash: ColorRect
var _panel: PanelContainer
var _center_msg: Label

func _ready() -> void:
	_font = load("res://assets/fonts/ArchivoBlack-Regular.ttf")
	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0.5, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_hp_back = ColorRect.new()
	_hp_back.position = Vector2(24, 22)
	_hp_back.size = Vector2(320, 18)
	_hp_back.color = Color(0, 0, 0, 0.5)
	add_child(_hp_back)
	_hp_bar = ColorRect.new()
	_hp_bar.position = Vector2(26, 24)
	_hp_bar.size = Vector2(316, 14)
	_hp_bar.color = Color(0.35, 1.0, 0.6)
	add_child(_hp_bar)
	for i in 3:
		var l := _label(M.FORM_NAME[i], 18)
		l.position = Vector2(24 + i * 112, 48)
		add_child(l)
		_forms.append(l)
	_info = _label("", 14)
	_info.position = Vector2(24, 84)
	_info.modulate.a = 0.6
	add_child(_info)
	_center_msg = _label("", 40)
	_center_msg.set_anchors_preset(Control.PRESET_CENTER)
	_center_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_msg.position = Vector2(-300, -120)
	_center_msg.size = Vector2(600, 60)
	add_child(_center_msg)
	_set_form(0)

func _label(t: String, size: int) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func bind() -> void:
	player.hp_changed.connect(_on_hp)
	player.form_changed.connect(_set_form)
	player.perfect_dodge.connect(_on_perfect)
	if touch:
		touch.gear_pressed.connect(toggle_panel)

func _on_hp(hp: float, max_hp: float) -> void:
	_hp_bar.size.x = 316.0 * clamp(hp / max_hp, 0.0, 1.0)
	_hp_bar.color = Color(0.35, 1.0, 0.6) if hp > max_hp * 0.3 else Color(1, 0.35, 0.3)

func _set_form(f: int) -> void:
	for i in 3:
		var on := i == f
		_forms[i].add_theme_color_override("font_color", M.FORM_COLOR[i] if on else Color(1, 1, 1, 0.3))
		_forms[i].scale = Vector2.ONE * (1.15 if on else 1.0)

func _on_perfect() -> void:
	_flash.color = Color(0.5, 1, 1, 0.22)
	var t := create_tween().set_ignore_time_scale(true)
	t.tween_property(_flash, "color:a", 0.0, 0.5)
	message("SCHIVATA PERFETTA", 0.7)

func message(t: String, secs := 1.2) -> void:
	_center_msg.text = t
	_center_msg.modulate.a = 1.0
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_interval(secs)
	tw.tween_property(_center_msg, "modulate:a", 0.0, 0.3)

func _process(_d: float) -> void:
	var s: Dictionary = FX.stats
	_info.text = "%d fps   colpi %d   abbattuti %d   perfette %d" % [Engine.get_frames_per_second(), s.get("hits", 0), s.get("kills", 0), s.get("perfect_dodges", 0)]

# ------------------------------------------------------------ pannello LAB

func toggle_panel() -> void:
	if _panel:
		_panel.queue_free()
		_panel = null
		return
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.08, 0.92)
	sb.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.position = Vector2(get_viewport().get_visible_rect().size.x - 560, 80)
	_panel.custom_minimum_size = Vector2(540, 0)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, get_viewport().get_visible_rect().size.y - 120)
	_panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	box.add_child(_label("LAB · regola dal vivo", 20))
	var rows := [
		["Velocità corsa", player.tune, "run_speed", 4.0, 14.0],
		["Accelerazione", player.tune, "accel", 15.0, 120.0],
		["Salto", player.tune, "jump", 6.0, 16.0],
		["Gravità", player.tune, "gravity", 15.0, 45.0],
		["Velocità schivata", player.tune, "dodge_speed", 8.0, 30.0],
		["Durata schivata", player.tune, "dodge_time", 0.1, 0.45],
		["Finestra schivata perfetta", player.tune, "perfect_window", 0.05, 0.4],
		["Aiuto mira (raggio)", player.tune, "assist_range", 0.0, 12.0],
		["Arresto all'impatto", FX.tune, "hitstop_scale", 0.0, 2.5],
		["Scossa telecamera", FX.tune, "shake_scale", 0.0, 2.5],
		["Sensibilità visuale", touch, "look_scale", 0.5, 4.0],
		["Distanza telecamera", cam.tune, "distance", 2.5, 7.0],
		["Velocità nemico", enemy_tune, "speed", 2.0, 12.0],
		["Carica attacco nemico", enemy_tune, "windup", 0.25, 1.2],
		["Danno nemico", enemy_tune, "damage", 0.0, 40.0],
		["Stadio del potere (1-3)", power, "stage", 1.0, 3.0],
		["Forza spinta", power.tune, "push_speed", 8.0, 40.0],
		["Ricarica spinta", power.tune, "push_cd", 0.1, 2.0],
		["Ricarica attira", power.tune, "pull_cd", 0.1, 2.0],
	]
	for r in rows:
		box.add_child(_slider_row(r[0], r[1], r[2], r[3], r[4]))
	var close := Button.new()
	close.text = "Chiudi"
	close.add_theme_font_size_override("font_size", 22)
	close.custom_minimum_size = Vector2(0, 56)
	close.pressed.connect(toggle_panel)
	box.add_child(close)
	add_child(_panel)

func _slider_row(title: String, obj, key: String, lo: float, hi: float) -> Control:
	var v := VBoxContainer.new()
	var cur = obj[key] if obj is Dictionary else obj.get(key)
	var l := _label("%s: %.2f" % [title, cur], 16)
	v.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 1.0 if key == "stage" else (hi - lo) / 100.0
	s.value = cur
	s.custom_minimum_size = Vector2(480, 40)
	s.value_changed.connect(func(val):
		if obj is Dictionary:
			obj[key] = val
		elif key == "stage":
			obj.set(key, int(val))
		else:
			obj.set(key, val)
		l.text = "%s: %.2f" % [title, val])
	v.add_child(s)
	return v
