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
var _ov_back: ColorRect
var _ov_bar: ColorRect
var _ov_label: Label
var _wave_label: Label
var _ups_label: Label
var _choice: Control
var _over: Control
const FAM_COL := {"Blade": Color(0.35, 0.95, 1.0), "Impact": Color(1.0, 0.6, 0.25), "Vector": Color(0.8, 0.5, 1.0),
	"Manipolazione": Color(0.7, 0.95, 1.0), "Elementi": Color(1.0, 0.85, 0.3), "Ambiente": Color(0.75, 0.6, 0.4), "Combo": Color(0.5, 1.0, 0.7)}
const OV_W := 316.0
const OV_COL := [Color(0.85, 0.85, 0.9), Color(0.35, 0.95, 1.0), Color(0.85, 0.5, 1.0), Color(1.0, 0.82, 0.25)]

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
	# OVERLOAD: una sola barra sottile sotto la vita, con le tacche dei livelli
	_ov_back = ColorRect.new()
	_ov_back.position = Vector2(24, 44)
	_ov_back.size = Vector2(320, 10)
	_ov_back.color = Color(0, 0, 0, 0.5)
	add_child(_ov_back)
	_ov_bar = ColorRect.new()
	_ov_bar.position = Vector2(26, 46)
	_ov_bar.size = Vector2(0, 6)
	add_child(_ov_bar)
	for k in [0.34, 0.67]:
		var notch := ColorRect.new()
		notch.position = Vector2(26 + OV_W * k - 1, 42)
		notch.size = Vector2(2, 14)
		notch.color = Color(1, 1, 1, 0.7)
		add_child(notch)
	_ov_label = _label("OVERLOAD", 14)
	_ov_label.position = Vector2(352, 38)
	add_child(_ov_label)
	for i in 3:
		var l := _label(M.FORM_NAME[i], 18)
		l.position = Vector2(24 + i * 112, 60)
		add_child(l)
		_forms.append(l)
	_info = _label("", 14)
	_info.position = Vector2(24, 94)
	_info.modulate.a = 0.6
	add_child(_info)
	_wave_label = _label("", 22)
	_wave_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.position = Vector2(-150, 18)
	_wave_label.size = Vector2(300, 30)
	add_child(_wave_label)
	_ups_label = _label("", 14)
	_ups_label.position = Vector2(24, 118)
	_ups_label.modulate.a = 0.85
	add_child(_ups_label)
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
	OV.level_changed.connect(_on_ov_level)
	Run.wave_started.connect(func(n):
		_wave_label.text = "ONDATA %d" % n
		message("ONDATA %d" % n, 1.0))
	Run.choice_open.connect(_open_choice)
	Run.choice_closed.connect(_refresh_ups)
	Run.run_over.connect(_open_over)
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

# ------------------------------------------------------------ run: scelte e fine

func _refresh_ups() -> void:
	if _choice:
		_choice.queue_free()
		_choice = null
	var names := []
	for id in Run.owned:
		names.append(Run.def(id).get("name", id))
	_ups_label.text = "  ·  ".join(names)

## Tre carte grandi, comode col pollice. Il gioco resta in pausa finché non scegli.
func _open_choice(opts: Array) -> void:
	_choice = Control.new()
	_choice.process_mode = Node.PROCESS_MODE_ALWAYS
	_choice.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_choice.add_child(dim)
	var title := _label("SCEGLI UN POTENZIAMENTO", 30)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(-300, 70)
	title.size = Vector2(600, 40)
	_choice.add_child(title)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.add_theme_constant_override("separation", 24)
	var w := 340.0
	row.position = Vector2(-(w * opts.size() + 24 * (opts.size() - 1)) * 0.5, -150)
	_choice.add_child(row)
	for i in opts.size():
		var d: Dictionary = opts[i]
		var col: Color = FAM_COL.get(d.family, Color.WHITE)
		var b := Button.new()
		b.custom_minimum_size = Vector2(w, 330)
		b.focus_mode = Control.FOCUS_NONE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.06, 0.1, 0.95)
		sb.border_color = col
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(10)
		b.add_theme_stylebox_override("normal", sb)
		var sb2 := sb.duplicate()
		sb2.bg_color = Color(col, 0.25)
		b.add_theme_stylebox_override("hover", sb2)
		b.add_theme_stylebox_override("pressed", sb2)
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 20
		v.offset_right = -20
		v.offset_top = 24
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_theme_constant_override("separation", 14)
		var fam := _label(d.family.to_upper(), 16)
		fam.add_theme_color_override("font_color", col)
		v.add_child(fam)
		var nm := _label(d.name, 28)
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(nm)
		var ds := _label(d.desc, 19)
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ds.custom_minimum_size = Vector2(w - 40, 0)
		v.add_child(ds)
		var key := _label("%d" % (i + 1), 16)
		key.modulate.a = 0.5
		v.add_child(key)
		b.add_child(v)
		var sc := Shortcut.new()
		var ev := InputEventKey.new()
		ev.keycode = KEY_1 + i
		sc.events = [ev]
		b.shortcut = sc
		b.pressed.connect(func(): Run.choose(i))
		row.add_child(b)
	add_child(_choice)

func _open_over(wave: int, kills: int) -> void:
	_over = Control.new()
	_over.process_mode = Node.PROCESS_MODE_ALWAYS
	_over.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_over.add_child(dim)
	var t := _label("A TERRA", 54)
	t.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(-300, -170)
	t.size = Vector2(600, 70)
	_over.add_child(t)
	var s := _label("ondata %d   ·   abbattuti %d   ·   potenziamenti %d" % [wave, kills, Run.owned.size()], 24)
	s.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.position = Vector2(-400, -90)
	s.size = Vector2(800, 40)
	_over.add_child(s)
	var b := Button.new()
	b.text = "RICOMINCIA"
	b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", 34)
	b.custom_minimum_size = Vector2(380, 110)
	b.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	b.position = Vector2(-190, -10)
	b.size = Vector2(380, 110)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.35, 0.95, 1.0, 0.25)
	bs.border_color = Color(0.35, 0.95, 1.0)
	bs.set_border_width_all(4)
	bs.set_corner_radius_all(12)
	b.add_theme_stylebox_override("normal", bs)
	b.add_theme_stylebox_override("hover", bs)
	b.add_theme_stylebox_override("pressed", bs)
	b.pressed.connect(restart)
	_over.add_child(b)
	add_child(_over)

func restart() -> void:
	if _over:
		_over.queue_free()
		_over = null
	if _choice:
		_choice.queue_free()
		_choice = null
	_ups_label.text = ""
	_wave_label.text = ""
	_on_hp(player.max_hp, player.max_hp)
	get_parent().restart()

func _on_ov_level(l: int) -> void:
	if l == 0:
		return
	if l == 3:
		message("OVERLOAD", 1.0)
		_flash.color = Color(1, 0.85, 0.3, 0.2)
		create_tween().set_ignore_time_scale(true).tween_property(_flash, "color:a", 0.0, 0.6)
	elif l > _shown_level:
		message(["", "SINERGIA 1 · PESANTI", "SINERGIA 2 · DOPPIO BERSAGLIO"][l], 0.8)
	_shown_level = l

var _shown_level := 0

func message(t: String, secs := 1.2) -> void:
	_center_msg.text = t
	_center_msg.modulate.a = 1.0
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_interval(secs)
	tw.tween_property(_center_msg, "modulate:a", 0.0, 0.3)

func _process(_d: float) -> void:
	var lv: int = OV.level
	var col: Color = OV_COL[3] if OV.bursting > 0.0 else OV_COL[lv]
	_ov_bar.size.x = OV_W * clamp(OV.meter / 100.0, 0.0, 1.0)
	_ov_bar.color = col
	_ov_label.add_theme_color_override("font_color", col)
	_ov_label.modulate.a = 0.55 + (0.45 * absf(sin(Time.get_ticks_msec() * 0.01)) if OV.bursting > 0.0 else 0.0)
	if lv == 0:
		_shown_level = 0
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
		["Stadio base del potere (1-3)", power, "base_stage", 1.0, 3.0],
			["OVERLOAD: resa delle azioni", OV.tune, "gain", 0.1, 2.0],
			["OVERLOAD: punti persi al secondo", OV.tune, "decay", 0.0, 30.0],
			["OVERLOAD: tregua prima del calo", OV.tune, "grace", 0.5, 6.0],
			["OVERLOAD: resa delle ripetizioni", OV.tune, "repeat_mult", 0.0, 1.0],
			["OVERLOAD: durata del pieno", OV.tune, "burst_time", 2.0, 12.0],
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
	s.step = 1.0 if key == "base_stage" else (hi - lo) / 100.0
	s.value = cur
	s.custom_minimum_size = Vector2(480, 40)
	s.value_changed.connect(func(val):
		if obj is Dictionary:
			obj[key] = val
		elif key == "base_stage":
			obj.set(key, int(val))
		else:
			obj.set(key, val)
		l.text = "%s: %.2f" % [title, val])
	v.add_child(s)
	return v
