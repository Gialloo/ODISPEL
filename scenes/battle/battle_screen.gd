extends Control

# Schermata di battaglia (nuovo motore). Funziona con qualsiasi "sorgente" che
# offra: battle, local_player_id, battle_time_left, battle_updated,
# battle_events_received e submit_choice() - SoloBattleSource o NetworkManager.

const HUB_SCENE: String = "res://scenes/hub/hub_demo.tscn"

var source: Variant = null
var pending_source: Variant = null    # sorgente da collegare appena la scena e' pronta
var event_delay: float = 0.42
var shown: Dictionary = {}          # copia dello stato come lo vede il giocatore ora
var animating: bool = false
var locked: bool = false            # ordine inviato, si aspetta il round
var pending_swap: String = ""       # personaggio scelto per il cambio
var log_lines: Array = []
var _ended_shown: bool = false

var _stage: BattleStage
var _fx: Control
var _boss_name: Label
var _boss_bar: SegBar
var _boss_hp: Label
var _round_label: Label
var _timer_label: Label
var _clock_label: Label
var _tele_panel: HudPanel
var _tele_label: Label
var _tele_target: Label
var _ops_box: VBoxContainer
var _orders_box: VBoxContainer
var _log_label: RichTextLabel
var _overlay: Control
var _rec_dot: ColorRect
var _t: float = 0.0
var _order_buttons: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# L'interfaccia e' disegnata per 1280x720: la finestra si adatta a quella base.
	var window: Window = get_window()
	if window != null:
		window.content_scale_size = Vector2i(1280, 720)
	_build()
	if pending_source != null:
		bind_source(pending_source)
	elif source == null:
		_start_solo()


# ---------- Avvio ----------

func _start_solo() -> void:
	var s := SoloBattleSource.new()
	bind_source(s)
	s.start(RosterStore.load_or_new(), "distributore", int(randi()) | 1)


func bind_source(src: Variant) -> void:
	source = src
	src.battle_updated.connect(_on_updated)
	src.battle_events_received.connect(_on_events)
	if not src.battle.is_empty():
		_on_updated()


func _on_updated() -> void:
	if animating:
		return
	_sync()


func _sync() -> void:
	if log_lines.is_empty():
		_push_log("CICLO 01 AVVIATO", "info")
		_push_log("SEGNALE STABILE", "info")
	shown = (source.battle as Dictionary).duplicate(true)
	locked = false
	pending_swap = ""
	_refresh_all()
	_check_end()


# ---------- Costruzione dell'interfaccia ----------

func _anchor(c: Control, a: Vector4, o: Vector4) -> void:
	c.anchor_left = a.x
	c.anchor_top = a.y
	c.anchor_right = a.z
	c.anchor_bottom = a.w
	c.offset_left = o.x
	c.offset_top = o.y
	c.offset_right = o.z
	c.offset_bottom = o.w


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = BattleTheme.BK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_stage = BattleStage.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	# velatura ciano e rumore di telecamera
	var tint := ColorRect.new()
	tint.color = Color(0.1, 0.6, 0.7, 0.08)
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)
	var cctv := ColorRect.new()
	cctv.set_anchors_preset(Control.PRESET_FULL_RECT)
	cctv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/cctv_overlay.gdshader")
	cctv.material = mat
	add_child(cctv)

	_fx = Control.new()
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_camera_info()
	_build_boss_banner()
	_build_telegraph()
	_build_operators()
	_build_orders()
	_build_log()
	add_child(_fx)
	_fx.move_to_front()

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)


func _build_camera_info() -> void:
	_rec_dot = ColorRect.new()
	_rec_dot.color = BattleTheme.RD
	_rec_dot.size = Vector2(20, 20)
	_rec_dot.position = Vector2(28, 28)
	_rec_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rec_dot)
	var rec := BattleTheme.make_label("REC", 30, BattleTheme.WH, true)
	rec.position = Vector2(56, 18)
	add_child(rec)
	var cam := BattleTheme.make_label("CAM-07 · VIA S. GIORGIO · PARK 3", 14, BattleTheme.CY)
	cam.position = Vector2(28, 70)
	add_child(cam)
	_clock_label = BattleTheme.make_label("", 15, BattleTheme.CY)
	_clock_label.position = Vector2(28, 92)
	add_child(_clock_label)
	_round_label = BattleTheme.make_label("CICLO 01", 22, BattleTheme.WH, true)
	_round_label.position = Vector2(28, 118)
	add_child(_round_label)


func _build_boss_banner() -> void:
	var panel := HudPanel.new().setup("SOGGETTO N.07", BattleTheme.RD)
	add_child(panel)
	_anchor(panel, Vector4(0.5, 0.0, 0.5, 0.0), Vector4(-268, 34, 252, 124))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.set_content(box)
	_boss_name = BattleTheme.make_label("DISTRIBUTORE · CLASSE ANOMALIA · MINACCIA ALTA", 13, BattleTheme.RD)
	box.add_child(_boss_name)
	_boss_bar = SegBar.new().setup(30, BattleTheme.RD, Vector2(0, 18))
	_boss_bar.color_off = BattleTheme.RD_DARK
	box.add_child(_boss_bar)
	_boss_hp = BattleTheme.make_label("INTEGRITA'", 15, BattleTheme.WH)
	box.add_child(_boss_hp)

	var timer_panel := HudPanel.new().setup("ORDINE ENTRO", BattleTheme.RD)
	add_child(timer_panel)
	_anchor(timer_panel, Vector4(1.0, 0.0, 1.0, 0.0), Vector4(-250, 34, -22, 102))
	_timer_label = BattleTheme.make_label("LIBERO", 34, BattleTheme.CY, true)
	timer_panel.set_content(_timer_label)


func _build_telegraph() -> void:
	_tele_panel = HudPanel.new().setup("ALLARME", BattleTheme.RD)
	add_child(_tele_panel)
	_anchor(_tele_panel, Vector4(1.0, 0.0, 1.0, 0.0), Vector4(-380, 124, -22, 206))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	_tele_panel.set_content(box)
	_tele_label = BattleTheme.make_label("PROSSIMA MOSSA", 28, BattleTheme.WH, true)
	box.add_child(_tele_label)
	_tele_target = BattleTheme.make_label("", 15, BattleTheme.RD)
	box.add_child(_tele_target)


func _build_operators() -> void:
	var panel := HudPanel.new().setup("OPERATORI", BattleTheme.CY)
	add_child(panel)
	_anchor(panel, Vector4(0.0, 1.0, 0.0, 1.0), Vector4(20, -224, 420, -18))
	_ops_box = VBoxContainer.new()
	_ops_box.add_theme_constant_override("separation", 3)
	panel.set_content(_ops_box)


func _build_orders() -> void:
	var panel := HudPanel.new().setup("TERMINALE ORDINI", BattleTheme.RD)
	panel.cut = 20.0
	add_child(panel)
	_anchor(panel, Vector4(1.0, 1.0, 1.0, 1.0), Vector4(-420, -224, -20, -18))
	_orders_box = VBoxContainer.new()
	_orders_box.add_theme_constant_override("separation", 5)
	panel.set_content(_orders_box)


func _build_log() -> void:
	var panel := HudPanel.new().setup("REGISTRO", BattleTheme.CY_DIM)
	panel.margins = Vector4(12, 30, 12, 8)
	add_child(panel)
	_anchor(panel, Vector4(0.0, 1.0, 1.0, 1.0), Vector4(436, -224, -436, -18))
	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.scroll_active = false
	_log_label.fit_content = false
	_log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log_label.add_theme_font_override("normal_font", BattleTheme.mono())
	_log_label.add_theme_font_size_override("normal_font_size", 14)
	panel.set_content(_log_label)


# ---------- Aggiornamento ----------

func _process(delta: float) -> void:
	_t += delta
	if _rec_dot != null:
		_rec_dot.visible = int(_t * 1.6) % 2 == 0
	if _clock_label != null:
		var d: Dictionary = Time.get_datetime_dict_from_system()
		_clock_label.text = "%02d.%02d.%04d  %02d:%02d:%02d" % [d["day"], d["month"], d["year"], d["hour"], d["minute"], d["second"]]
	if source != null and _timer_label != null:
		var left: float = float(source.battle_time_left)
		if left < 0.0:
			_timer_label.text = "LIBERO"
			_timer_label.add_theme_color_override("font_color", BattleTheme.CY)
		else:
			var secs: int = int(ceil(left))
			_timer_label.text = "%02d:%02d" % [secs / 60, secs % 60]
			_timer_label.add_theme_color_override("font_color", BattleTheme.RD if secs <= 10 else BattleTheme.WH)


func _refresh_all() -> void:
	if shown.is_empty():
		return
	_stage.set_state(shown)
	_refresh_boss()
	_refresh_telegraph()
	_refresh_operators()
	_refresh_orders()
	_refresh_log()
	_round_label.text = "CICLO %02d" % int(shown["round"])


func _refresh_boss() -> void:
	var boss: Dictionary = BattleState.boss(shown)
	_boss_bar.set_ratio(float(boss["hp"]) / float(boss["max_hp"]))
	var tags: String = ""
	for s in boss["statuses"]:
		tags += "  [%s]" % BattleText.status_name(str(s))
	_boss_hp.text = "INTEGRITA'  %d / %d%s" % [int(boss["hp"]), int(boss["max_hp"]), tags]


func _local_player() -> Dictionary:
	return BattleState.player(shown, str(source.local_player_id))


func _refresh_telegraph() -> void:
	var tele: Dictionary = shown.get("telegraph", {})
	if tele.is_empty() or str(shown["winner"]) != "":
		_tele_label.text = "—"
		_tele_target.text = ""
		return
	var move_id: String = str(tele["move"])
	var def: Dictionary = BattleContent.BOSS_MOVES[move_id]
	_tele_label.text = "» %s" % BattleText.move_name(move_id)
	if str(def["target"]) == "all":
		_tele_target.text = "COLPISCE TUTTI GLI OPERATORI"
	else:
		var tp: Dictionary = BattleState.player(shown, str(tele["target"]))
		var who: String = "?"
		if not tp.is_empty():
			var au: Dictionary = BattleState.unit(shown, str(tp["active"]))
			who = str(au.get("name", "?")).to_upper()
		var mine: bool = str(tele["target"]) == str(source.local_player_id)
		_tele_target.text = "BERSAGLIO: %s%s" % [who, "  ◄ TU" if mine else ""]


func _bar_row(label: String, ratio: float, color: Color, segs: int, width: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := BattleTheme.make_label(label, 12, color)
	l.custom_minimum_size = Vector2(26, 0)
	row.add_child(l)
	var bar := SegBar.new().setup(segs, color, Vector2(width, 9))
	bar.set_ratio(ratio)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	return row


func _refresh_operators() -> void:
	for c in _ops_box.get_children():
		_ops_box.remove_child(c)
		c.queue_free()
	var me: Dictionary = _local_player()
	if me.is_empty():
		return
	var active_id: String = pending_swap if pending_swap != "" else str(me["active"])
	for uid in me["team"]:
		var u: Dictionary = BattleState.unit(shown, uid)
		_ops_box.add_child(_unit_row(u, uid == active_id, uid == str(me["active"])))
	# compagni IA / altri giocatori: solo l'unita' attiva, tutti su una riga
	var allies := HBoxContainer.new()
	allies.add_theme_constant_override("separation", 14)
	allies.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for p in shown["players"]:
		if p["id"] == me["id"]:
			continue
		var a: Dictionary = BattleState.unit(shown, str(p["active"]))
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 5)
		cell.add_child(BattleTheme.make_label(str(a.get("name", "?")).to_upper(), 12, BattleTheme.CY_DIM))
		var bar := SegBar.new().setup(8, BattleTheme.CY_DIM, Vector2(60, 7))
		bar.set_ratio(float(a["hp"]) / float(a["max_hp"]))
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cell.add_child(bar)
		allies.add_child(cell)
	if allies.get_child_count() > 0:
		_ops_box.add_child(allies)


func _unit_row(u: Dictionary, selected: bool, is_active: bool) -> Control:
	var alive: bool = BattleState.is_alive(u)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 44)
	btn.flat = true
	btn.disabled = not alive
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	btn.pressed.connect(_on_unit_pressed.bind(str(u["id"])))

	var bgc := ColorRect.new()
	bgc.set_anchors_preset(Control.PRESET_FULL_RECT)
	bgc.color = BattleTheme.CY if selected else Color(0.04, 0.12, 0.15)
	bgc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(bgc)
	var key := ColorRect.new()
	key.color = BattleTheme.unit_color(str(u["color"]))
	key.size = Vector2(6, 44)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(key)

	var fg: Color = BattleTheme.BK if selected else (BattleTheme.CY if alive else BattleTheme.CY_DARK)
	var title: String = str(u["name"]).to_upper()
	if is_active:
		title += "  ▶"
	var name_l := BattleTheme.make_label(title, 17, fg, true)
	name_l.position = Vector2(16, -2)
	btn.add_child(name_l)
	var cls_l := BattleTheme.make_label("%s · LV%d" % [str(u["cls"]).to_upper(), int(u["level"])], 11, fg)
	cls_l.position = Vector2(180, 3)
	btn.add_child(cls_l)

	var hp_ratio: float = float(u["hp"]) / float(u["max_hp"])
	var hp := SegBar.new().setup(16, BattleTheme.BK if selected else (BattleTheme.RD if hp_ratio < 0.3 else BattleTheme.CY), Vector2(250, 8))
	hp.color_off = Color(0, 0, 0, 0.35) if selected else BattleTheme.CY_DARK
	hp.set_ratio(hp_ratio)
	hp.position = Vector2(16, 22)
	btn.add_child(hp)
	var hp_t := BattleTheme.make_label("%d" % int(u["hp"]), 13, fg)
	hp_t.position = Vector2(274, 15)
	btn.add_child(hp_t)

	var en := SegBar.new().setup(BattleTypes.MAX_ENERGY, BattleTheme.BK if selected else BattleTheme.WH, Vector2(78, 6))
	en.color_off = Color(0, 0, 0, 0.35) if selected else BattleTheme.CY_DARK
	en.set_ratio(float(u["energy"]) / float(BattleTypes.MAX_ENERGY))
	en.position = Vector2(16, 34)
	btn.add_child(en)
	var gauge := SegBar.new().setup(10, BattleTheme.BK if selected else BattleTheme.RD, Vector2(96, 6))
	gauge.color_off = Color(0, 0, 0, 0.35) if selected else BattleTheme.RD_DARK
	gauge.set_ratio(float(u["gauge"]) / float(BattleTypes.GAUGE_MAX))
	gauge.position = Vector2(104, 34)
	btn.add_child(gauge)
	if int(u["gauge"]) >= BattleTypes.GAUGE_MAX and alive:
		var ult_l := BattleTheme.make_label("ULT", 12, BattleTheme.BK if selected else BattleTheme.RD, true)
		ult_l.position = Vector2(210, 28)
		btn.add_child(ult_l)
	return btn


func _on_unit_pressed(uid: String) -> void:
	if animating or locked or str(shown.get("winner", "")) != "":
		return
	var me: Dictionary = _local_player()
	if uid == str(me["active"]):
		pending_swap = ""
	else:
		pending_swap = uid if pending_swap != uid else ""
	_refresh_operators()
	_refresh_orders()


# Ordini: attacco, guardia, skill e ultimate dell'unita' che agira'.
func _refresh_orders() -> void:
	for c in _orders_box.get_children():
		_orders_box.remove_child(c)
		c.queue_free()
	_order_buttons.clear()
	var me: Dictionary = _local_player()
	if me.is_empty() or str(shown["winner"]) != "":
		return
	var uid: String = pending_swap if pending_swap != "" else str(me["active"])
	var u: Dictionary = BattleState.unit(shown, uid)
	if pending_swap != "":
		var info := BattleTheme.make_label("CAMBIO » %s (GRATIS)" % str(u["name"]).to_upper(), 13, BattleTheme.WH)
		_orders_box.add_child(info)
	var entries: Array = [{"id": "attack", "kind": "primary"}, {"id": "guard", "kind": "normal"}]
	for s in u["skills"]:
		entries.append({"id": str(s), "kind": "normal"})
	if str(u["ult"]) != "":
		entries.append({"id": str(u["ult"]), "kind": "ultimate"})
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 5)
	var n: int = 1
	for e in entries:
		var move_id: String = str(e["id"])
		var move: Dictionary = BattleContent.MOVES[move_id]
		var choice: Dictionary = _make_choice(move_id)
		var err: String = BattleResolver.validate_choice(shown, str(source.local_player_id), choice)
		var b := Button.new()
		var suffix: String = ""
		if str(move["kind"]) == "skill":
			suffix = " ·%dE" % int(move["cost"])
		elif str(move["kind"]) == "ult":
			suffix = " ·%d%%" % int(u["gauge"])
		b.text = "%d %s%s" % [n, BattleText.move_name(move_id), suffix]
		b.tooltip_text = BattleText.move_hint(move_id)
		var primary: bool = str(e["kind"]) == "primary"
		b.custom_minimum_size = Vector2(0, 46 if primary else 38)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		BattleTheme.style_button(b, str(e["kind"]), 26 if primary else 13)
		if not primary:
			for st in ["normal", "hover", "pressed", "disabled"]:
				var sb: StyleBoxFlat = b.get_theme_stylebox(st) as StyleBoxFlat
				if sb != null:
					sb.content_margin_left = 8.0
					sb.content_margin_right = 6.0
		b.disabled = err != "" or locked or animating
		b.pressed.connect(_on_order_pressed.bind(move_id))
		b.focus_mode = Control.FOCUS_NONE
		if primary:
			_orders_box.add_child(b)
		else:
			grid.add_child(b)
		_order_buttons.append(b)
		n += 1
	_orders_box.add_child(grid)
	var hint := BattleTheme.make_label("TASTI 1-%d · CLICCA UN OPERATORE PER IL CAMBIO" % (n - 1), 11, BattleTheme.CY_DIM)
	_orders_box.add_child(hint)


func _make_choice(move_id: String) -> Dictionary:
	var choice: Dictionary = {"swap": pending_swap, "move": move_id, "target": ""}
	var move: Dictionary = BattleContent.MOVES[move_id]
	if str(move["target"]) == "ally":
		choice["target"] = _most_hurt_ally()
	return choice


# Per cura e purifica: il giocatore con l'unita' attiva piu' ferita.
func _most_hurt_ally() -> String:
	var best: String = str(source.local_player_id)
	var worst: float = 2.0
	for p in shown["players"]:
		var a: Dictionary = BattleState.unit(shown, str(p["active"]))
		if BattleState.is_alive(a):
			var r: float = float(a["hp"]) / float(a["max_hp"])
			if r < worst:
				worst = r
				best = str(p["id"])
	return best


func _on_order_pressed(move_id: String) -> void:
	if animating or locked or source == null:
		return
	var choice: Dictionary = _make_choice(move_id)
	if BattleResolver.validate_choice(shown, str(source.local_player_id), choice) != "":
		return
	locked = true
	_refresh_orders()
	if not source.submit_choice(choice):
		locked = false
		_refresh_orders()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var idx: int = int(event.keycode) - int(KEY_1)
	if idx >= 0 and idx < _order_buttons.size():
		var b: Button = _order_buttons[idx]
		if not b.disabled:
			b.pressed.emit()


# ---------- Eventi del round ----------

func _on_events(events: Array) -> void:
	_play_events(events)


func _play_events(events: Array) -> void:
	animating = true
	_refresh_orders()
	for e in events:
		if not is_inside_tree():
			return
		var line: Dictionary = BattleText.describe(shown, e)
		_push_log(str(line["text"]), str(line["kind"]))
		_event_fx(e)
		BattleText.apply_to_display(shown, e)
		_stage.set_state(shown)
		_refresh_boss()
		_refresh_operators()
		await get_tree().create_timer(event_delay).timeout
	animating = false
	if not is_inside_tree():
		return
	_sync()


func _event_fx(e: Dictionary) -> void:
	match str(e.get("t", "")):
		"damage":
			var dst: String = str(e["dst"])
			_stage.flash(dst)
			_float_text("-%d" % int(e["amount"]) if int(e["amount"]) > 0 else "SCUDO", dst, BattleTheme.WH, 46 if dst == BattleState.BOSS_ID else 38)
		"bleed":
			_float_text("-%d" % int(e["amount"]), str(e["unit"]), BattleTheme.RD, 28)
		"heal":
			_float_text("+%d" % int(e["amount"]), str(e["dst"]), Color("#6bffb0"), 34)
		"shield":
			_float_text("+%d" % int(e["amount"]), str(e["dst"]), BattleTheme.CY, 26)
		"down":
			_float_text("K.O.", str(e["unit"]), BattleTheme.RD, 44)


func _float_text(text: String, uid: String, color: Color, size: int) -> void:
	var pos: Vector2 = _stage.anchor_of(uid) + Vector2(randf_range(-20.0, 20.0), -60.0)
	var l := BattleTheme.make_label(text, size, color, true)
	l.add_theme_color_override("font_outline_color", BattleTheme.BK)
	l.add_theme_constant_override("outline_size", 8)
	l.position = pos
	_fx.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", pos.y - 70.0, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.35)
	tw.chain().tween_callback(l.queue_free)


func _push_log(text: String, kind: String) -> void:
	if text == "":
		return
	var color: String = "#7cf0ff"
	match kind:
		"hit":
			color = "#f2fdff"
		"boss":
			color = "#ff2d55"
		"heal":
			color = "#6bffb0"
		"down", "end":
			color = "#ff2d55"
	log_lines.append("[color=%s]> %s[/color]" % [color, text])
	while log_lines.size() > 8:
		log_lines.pop_front()
	_refresh_log()


func _refresh_log() -> void:
	if _log_label != null:
		_log_label.text = "\n".join(log_lines)


# ---------- Fine battaglia ----------

func _check_end() -> void:
	if _ended_shown or shown.is_empty() or str(shown["winner"]) == "":
		return
	_ended_shown = true
	var rewards: Dictionary = {}
	if source.has_method("finish"):
		rewards = source.finish()
	_show_result(str(shown["winner"]) == "players", rewards)


func _show_result(victory: bool, rewards: Dictionary) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel := HudPanel.new().setup("ESITO", BattleTheme.CY if victory else BattleTheme.RD)
	panel.cut = 24.0
	_overlay.add_child(panel)
	_anchor(panel, Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-300, -230, 300, 230))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.set_content(box)
	var title := BattleTheme.make_label("OPERAZIONE RIUSCITA" if victory else "OPERAZIONE FALLITA", 40, BattleTheme.CY if victory else BattleTheme.RD, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(BattleTheme.make_label("PREMI", 16, BattleTheme.WH))
	for line in _reward_lines(rewards):
		box.add_child(BattleTheme.make_label(line, 17, BattleTheme.CY))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var again := Button.new()
	again.text = "RIGIOCA"
	again.custom_minimum_size = Vector2(0, 50)
	BattleTheme.style_button(again, "primary", 26)
	again.pressed.connect(_on_again)
	box.add_child(again)
	var hub := Button.new()
	hub.text = "TORNA ALL'HUB"
	hub.custom_minimum_size = Vector2(0, 44)
	BattleTheme.style_button(hub, "normal", 20)
	hub.pressed.connect(_on_hub)
	box.add_child(hub)


func _reward_lines(rewards: Dictionary) -> Array:
	var lines: Array = []
	if rewards.is_empty():
		return ["—"]
	if int(rewards.get("coins", 0)) > 0:
		lines.append("+%d MONETE" % int(rewards["coins"]))
	for mat in rewards.get("materials", {}):
		lines.append("+%d %s" % [int(rewards["materials"][mat]), str(BattleContent.MATERIALS.get(mat, mat)).to_upper()])
	for d in rewards.get("drops", []):
		match str(d["kind"]):
			"gear":
				lines.append("PEZZO: %s %s" % [str(d["slot"]).to_upper(), str(BattleTypes.RARITIES[int(d["rarity"])]).to_upper()])
			"move":
				lines.append("MOSSA: %s (%s)" % [BattleText.move_name(str(d["id"])), str(BattleTypes.RARITIES[int(d["rarity"])]).to_upper()])
			"passive":
				lines.append("PASSIVA: %s (%s)" % [str(BattleContent.PASSIVES[str(d["id"])]["name"]).to_upper(), str(BattleTypes.RARITIES[int(d["rarity"])]).to_upper()])
	if lines.is_empty():
		lines.append("—")
	return lines


func _on_again() -> void:
	get_tree().reload_current_scene()


func _on_hub() -> void:
	get_tree().change_scene_to_file(HUB_SCENE)
