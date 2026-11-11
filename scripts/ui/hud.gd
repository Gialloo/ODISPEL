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
var _menu: Control
var _score_label: Label
var _combo_label: Label
var _circle_label: Label
var _score_shown := 0.0
var _notches: Array = []
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
		_notches.append(notch)
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
	# punteggio in alto a destra (sotto l'ingranaggio), combo in corso sotto
	_score_label = _label("0", 30)
	_score_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_score_label.position = Vector2(-420, 76)
	_score_label.size = Vector2(400, 40)
	add_child(_score_label)
	_combo_label = _label("", 22)
	_combo_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_combo_label.position = Vector2(-420, 112)
	_combo_label.size = Vector2(400, 30)
	_combo_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	add_child(_combo_label)
	_circle_label = _label("", 26)
	_circle_label.set_anchors_preset(Control.PRESET_CENTER)
	_circle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_circle_label.position = Vector2(-300, 60)
	_circle_label.size = Vector2(600, 40)
	_circle_label.add_theme_color_override("font_color", Color(0.45, 0.9, 1.0))
	add_child(_circle_label)
	_set_form(0)

func _button(text: String, col: Color, w := 380.0, h := 100.0, fs := 32) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", fs)
	b.custom_minimum_size = Vector2(w, h)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(col, 0.22)
	bs.border_color = col
	bs.set_border_width_all(4)
	bs.set_corner_radius_all(12)
	b.add_theme_stylebox_override("normal", bs)
	b.add_theme_stylebox_override("hover", bs)
	var bp := bs.duplicate()
	bp.bg_color = Color(col, 0.45)
	b.add_theme_stylebox_override("pressed", bp)
	return b

func _screen(dim_a := 0.6) -> Control:
	var c := Control.new()
	c.process_mode = Node.PROCESS_MODE_ALWAYS
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, dim_a)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(dim)
	return c

func _centered_box(parent: Control, y: float, sep := 18) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.offset_top = y
	v.add_theme_constant_override("separation", sep)
	parent.add_child(v)
	return v

func _centered(n: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.add_child(n)
	return c

# ------------------------------------------------------------ menu principale

func open_menu() -> void:
	close_screens()
	_set_play_ui(false)
	_menu = _screen(0.55)
	var v := _centered_box(_menu, 0, 22)
	var t := _label("OVERLOAD", 84)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0))
	v.add_child(t)
	var rec := _label("RECORD  %d" % Run.best if Run.best > 0 else "ondate infinite · fai punti con abbattimenti e combo", 22)
	rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rec.modulate.a = 0.8
	v.add_child(rec)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	v.add_child(gap)
	var bn := _button("NUOVA PARTITA", Color(0.35, 0.95, 1.0), 440, 110, 36)
	bn.pressed.connect(func(): get_parent().start_game())
	v.add_child(_centered(bn))
	var bo := _button("OPZIONI", Color(1, 1, 1), 440, 90, 30)
	bo.pressed.connect(_open_options)
	v.add_child(_centered(bo))
	add_child(_menu)

func _open_options() -> void:
	if _menu:
		_menu.queue_free()
	_menu = _screen(0.75)
	var v := _centered_box(_menu, 0, 14)
	var t := _label("OPZIONI", 48)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var rows := [
		["Sensibilità visuale", "look", 0.4, 2.5, 0.05],
		["Distanza telecamera", "cam_dist", 3.5, 7.0, 0.1],
		["Volume", "volume", 0.0, 1.0, 0.05],
		["Scossa dello schermo", "shake", 0.0, 1.5, 0.05],
	]
	for r in rows:
		v.add_child(_centered(_opt_row(r[0], r[1], r[2], r[3], r[4])))
	var cb := CheckButton.new()
	cb.text = "Visuale libera che si gira da sola"
	cb.focus_mode = Control.FOCUS_NONE
	cb.add_theme_font_override("font", _font)
	cb.add_theme_font_size_override("font_size", 22)
	cb.add_theme_constant_override("h_separation", 18)
	cb.button_pressed = bool(Run.opt.auto_cam)
	cb.toggled.connect(func(on): Run.opt.auto_cam = on)
	v.add_child(_centered(cb))
	var bb := _button("INDIETRO", Color(0.35, 0.95, 1.0), 360, 90, 30)
	bb.pressed.connect(func():
		Run.save_cfg()
		Run.apply_opt()
		if Run.running:
			close_screens()
		else:
			open_menu())
	v.add_child(_centered(bb))
	add_child(_menu)

func _opt_row(title: String, key: String, lo: float, hi: float, step: float) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	var l := _label(title, 22)
	l.custom_minimum_size = Vector2(330, 0)
	h.add_child(l)
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = step
	sl.value = float(Run.opt[key])
	sl.custom_minimum_size = Vector2(380, 56)
	sl.focus_mode = Control.FOCUS_NONE
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(0.35, 0.95, 1.0, 0.6)
	grab.content_margin_top = 8
	grab.content_margin_bottom = 8
	sl.add_theme_stylebox_override("slider", grab)
	h.add_child(sl)
	var val := _label("%.2f" % sl.value, 22)
	val.custom_minimum_size = Vector2(80, 0)
	h.add_child(val)
	sl.value_changed.connect(func(x):
		Run.opt[key] = x
		val.text = "%.2f" % x
		Run.apply_opt())
	return h

func close_screens() -> void:
	for c in [_menu, _over, _choice]:
		if c and is_instance_valid(c):
			c.queue_free()
	_menu = null
	_over = null
	_choice = null

## Barre, punteggio e comandi touch solo mentre si gioca.
func _set_play_ui(on: bool) -> void:
	for n in [_hp_back, _hp_bar, _ov_back, _ov_bar, _ov_label, _info, _wave_label, _ups_label, _score_label, _combo_label, _circle_label]:
		n.visible = on
	for l in _forms:
		l.visible = on
	for n in _notches:
		n.visible = on
	if touch:
		touch.visible = on and get_parent()._is_touch

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
	Run.wave_started.connect(func(n, th):
		_wave_label.text = "ONDATA %d" % n + ("  ·  " + th if th != "" else "")
		message("ONDATA %d" % n + ("\n" + th if th != "" else ""), 1.2))
	Run.choice_open.connect(_open_choice)
	Run.choice_closed.connect(_refresh_ups)
	Run.run_over.connect(_open_over)
	Run.combo_banked.connect(func(hits, pts):
		_combo_label.text = "COMBO %d  +%d" % [hits, pts]
		_combo_label.modulate.a = 1.0
		var tw := create_tween()
		tw.tween_interval(1.0)
		tw.tween_property(_combo_label, "modulate:a", 0.0, 0.4))
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
	close_screens()
	if touch:
		touch.visible = false
	_over = _screen(0.6)
	var v := _centered_box(_over, 0, 14)
	var t := _label("A TERRA", 54)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var sc := _label("PUNTEGGIO  %d" % Run.score, 44)
	sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sc.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	v.add_child(sc)
	var rec := _label("NUOVO RECORD" if Run.score >= Run.best and Run.score > 0 else "record  %d" % Run.best, 24)
	rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(rec)
	var s := _label("ondata %d   ·   abbattuti %d   ·   combo %d (la più lunga %d)" % [wave, kills, Run.combos, Run.best_combo], 22)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.modulate.a = 0.85
	v.add_child(s)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	var b := _button("RICOMINCIA", Color(0.35, 0.95, 1.0), 360, 105, 32)
	b.pressed.connect(restart)
	row.add_child(b)
	var bm := _button("MENU", Color(1, 1, 1), 240, 105, 30)
	bm.pressed.connect(func(): get_parent().to_menu())
	row.add_child(bm)
	v.add_child(row)
	add_child(_over)

func restart() -> void:
	close_screens()
	_set_play_ui(true)
	_score_shown = 0.0
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
	# punteggio che sale a scatti morbidi, combo in corso, conto alla rovescia del cerchio
	_score_shown = move_toward(_score_shown, float(Run.score), max(40.0, (Run.score - _score_shown) * 8.0) * _d)
	_score_label.text = "%d" % int(_score_shown)
	if Run.combo >= 2:
		_combo_label.text = "COMBO %d" % Run.combo
		_combo_label.modulate.a = 1.0
	elif _combo_label.text.find("+") == -1:
		_combo_label.modulate.a = 0.0
	if Run.circle_t > 0.8 and Run.running:
		_circle_label.text = "RESTA NEL CERCHIO · ONDATA TRA %d" % ceili(Run.CIRCLE_TIME - Run.circle_t)
	else:
		_circle_label.text = ""
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
		["Distanza telecamera", Run.opt, "cam_dist", 2.5, 7.0],
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
