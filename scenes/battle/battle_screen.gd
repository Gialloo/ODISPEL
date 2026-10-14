extends Control

# Schermata di battaglia (nuovo motore). Funziona con qualsiasi "sorgente" che
# offra: battle, local_player_id, battle_time_left, battle_updated,
# battle_events_received e submit_choice() - SoloBattleSource o NetworkManager.


var source: Variant = null
var pending_source: Variant = null    # sorgente da collegare appena la scena e' pronta
var event_delay: float = Settings.event_delay()
var shown: Dictionary = {}          # copia dello stato come lo vede il giocatore ora
var animating: bool = false
var locked: bool = false            # ordine inviato, si aspetta il round
var _swaps: Dictionary = {}          # slot -> personaggio di back row scelto per il cambio
var _picks: Dictionary = {}          # slot -> ordine gia' scelto in questo round
var _cur_slot: String = ""           # slot di front row di cui si scelgono gli ordini
var autoplay: bool = false           # AUTOPLAY: l'IA combatte da sola
var _auto_button: Button
var _auto_icon: GameIcon
var speed_button: Button
var _veil: ColorRect
var _perf_time: float = 0.0
var _perf_frames: int = 0
var _perf_checked: bool = false
var _ops_panel: Control
var pending_swap: String:
	get:
		return str(_swaps.get(_cur_slot_id(), ""))
	set(value):
		_swaps[_cur_slot_id()] = value
var log_lines: Array = []
var _last_won: bool = false
var _dmg_by: Dictionary = {}      # danni al boss per operatore (per l'MVP a fine battaglia)
var _best_hit: int = 0
var _boon_buttons: Array = []
var _pause: PauseMenu = null
var _ended_shown: bool = false

var _stage: BattleStage
var _reward_rows: Array = []
var _turn_box: VBoxContainer
var _turn_sig: String = ""
var _turn_acting: String = ""
var _fx: Control
var _boss_name: Label
var _boss_meta: Label
var _pending_balloon: String = ""
var _pair_arrows: Dictionary = {}      # slot -> frecce >< tra il front e il suo compagno in panchina
var _boss_bar: LineBar
var _boss_hp: Label
var _boss_bal: LineBar
var _plan_label: Label
var _reserve_label: Label
var _tact_row: HBoxContainer
var _order_btn: Button
var _push_btn: Button
var _ping_row: HBoxContainer
var _order_pick: String = ""
var _push_pick: String = ""
var _react_row: HBoxContainer
var _react_sig: String = ""
var _threat_round: int = -1
var _round_label: Label
var _timer_label: Label
var _timer_panel: Control
var _phase_label: Label
var _phase_badge: Control
var _hint_full: bool = true        # i primi combattimenti spiegano tutto; poi il comportamento ignoto diventa "???"
var _log_panel: Control
var _log_handle: Button
var _log_open: bool = false
var _log_seen: String = ""
var _clock_label: Label
var _tele_panel: HudPanel
var _boss_panel: HudPanel
var _tutorial: TutorialOverlay = null
var _coach: BattleCoach = null
var _tele_label: Label
var _tele_target: Label
var _ops_box: VBoxContainer
var _orders_box: FanMenu
var _select_arrow: SelectArrow
var _fan_key: String = ""
var _fan_anchor: Control      # riquadro invisibile attorno ai comandi (lo evidenzia il tutorial)
var _log_label: RichTextLabel
var _overlay: Control
var _rec_dot: ColorRect
var _t: float = 0.0
var _clock_sec: int = -1
var _ops_sig: String = ""
var _orders_sig: String = ""
var _timer_secs: int = -2
var _order_buttons: Array = []
var _chat: ChatPanel = null          # chat di squadra (solo in rete)


func _ready() -> void:
	ScreenFrame.setup(self)   # riquadro 1280x720 nell'area sicura dello schermo
	_build()
	_pin_corners.call_deferred()
	get_viewport().size_changed.connect(func() -> void: _pin_corners.call_deferred())
	if pending_source != null:
		bind_source(pending_source)
	elif source == null:
		_start_solo()
	if source is SoloBattleSource and Settings.should_show_tutorial():
		_start_tutorial.call_deferred()
	elif source is SoloBattleSource and BattleCoach.active():
		_start_coach.call_deferred()


# ---------- Tutorial ----------

func _panel_of(c: Control) -> Control:
	var node: Node = c
	while node != null and not (node is HudPanel):
		node = node.get_parent()
	return node as Control


func tutorial_steps() -> Array:
	return [
		{"title": "BENVENUTO, OPERATORE", "target": null,
		"text": "Una anomalia ti sta davanti: mettila a terra prima che metta K.O. la tua squadra. Si combatte a round: scegli un ordine, poi si risolve tutto insieme."},
		{"title": "IL BERSAGLIO", "target": _boss_panel,
		"text": "Qui vedi il boss e la sua integrita': a zero hai vinto. Sotto, ALLARME ti dice che mossa usera' in questo round."},
		{"title": "TI GUIDO IO", "target": null,
		"text": "Non serve ricordare tutto: ti spieghero' una cosa alla volta, mentre giochi. Quando vuoi puoi saltare la guida."},
	]


func _start_tutorial() -> void:
	if _tutorial != null or not is_inside_tree():
		return
	await get_tree().process_frame     # aspetta che i pannelli abbiano la loro posizione
	_tutorial = TutorialOverlay.new().setup(tutorial_steps())
	add_child(_tutorial)
	_tutorial.finished.connect(_on_tutorial_finished)


func _on_tutorial_finished(skipped: bool) -> void:
	_tutorial = null
	Settings.finish_tutorial()
	if skipped:
		Settings.coach_step = BattleCoach.STEPS.size()
		Settings.save()
	elif BattleCoach.active():
		_start_coach.call_deferred()


# Prima partita guidata: una cosa alla volta, aspettando che il giocatore la faccia.
func _start_coach() -> void:
	if _coach != null or not is_inside_tree() or not BattleCoach.active():
		return
	await get_tree().process_frame
	_coach = BattleCoach.new().setup(self)
	add_child(_coach)
	_coach.finished.connect(func() -> void: _coach = null)


func _coach_note(event: String, data: String = "") -> void:
	if _coach != null and is_instance_valid(_coach):
		_coach.note(event, data)


# ---------- Avvio ----------

func _start_solo() -> void:
	var s := SoloBattleSource.new()
	bind_source(s)
	s.endless_floor = MissionConfig.endless_floor
	s.daily_mod = MissionConfig.daily_mod
	s.weekly = MissionConfig.weekly
	s.training = MissionConfig.training
	if not MissionConfig.expedition.is_empty() and Expedition.kind(MissionConfig.expedition) == "fight":
		s.expedition = MissionConfig.expedition
	s.start(RosterStore.load_or_new(), MissionConfig.boss_id, int(randi()) | 1, MissionConfig.tier)
	var intro_notes: Array = []
	if s.training:
		intro_notes.append("SALA DI ADDESTRAMENTO: niente premi, niente conseguenze")
	if s.learned_text != "":
		intro_notes.append(s.learned_text)
	if s.comeback:
		intro_notes.append("RIENTRO: Riserva +%d e uno scudo, dopo %d sconfitte di fila" % [Extras.COMEBACK_RESERVE, Extras.COMEBACK_AFTER])
	if Tactics.challenge_id(s.battle) != "" and not s.training:
		intro_notes.append("SFIDA FACOLTATIVA: %s (+%d crediti)" % [Tactics.challenge_text(s.battle), Tactics.CHALLENGE_COINS])
	for note in intro_notes:
		Notify.toast(str(note))
	if DisplayServer.get_name() != "headless":
		get_tree().create_timer(1.4).timeout.connect(func() -> void:
			if is_inside_tree() and str(shown.get("winner", "")) == "":
				banter(_local_active_id(), "start", true))
	if MissionConfig.daily_mod != "" and DisplayServer.get_name() != "headless":
		var dm: Dictionary = {}
		for m in Endless.MODS:
			if str(m["id"]) == MissionConfig.daily_mod:
				dm = m
		ComicFx.caption(_fx, "%s  //  %s: %s" % ["EVENTO DELLA SETTIMANA" if MissionConfig.weekly else "SFIDA DEL GIORNO", str(dm.get("name", "")), str(dm.get("desc", ""))], Vector2(240.0, 300.0), BattleTheme.POP, 1.8)
	elif not MissionConfig.expedition.is_empty() and DisplayServer.get_name() != "headless":
		var xp: Dictionary = Expedition.battle_params(MissionConfig.expedition)
		var xcap: String = "SPEDIZIONE  //  %s" % Expedition.stage_title(MissionConfig.expedition)
		if str(xp["mod"]) != "":
			xcap += "\nDISTORSIONE: %s" % Expedition.mod_name(str(xp["mod"]))
		ComicFx.caption(_fx, xcap, Vector2(300.0, 300.0), BattleTheme.POP, 1.6)
	elif MissionConfig.endless_floor > 0 and DisplayServer.get_name() != "headless":
		var emod: Dictionary = Endless.mod_for(MissionConfig.endless_floor)
		var cap: String = "PIANO %d" % MissionConfig.endless_floor
		if not emod.is_empty():
			cap += "  //  %s: %s" % [str(emod["name"]), str(emod["desc"])]
		if not MissionConfig.endless_boons.is_empty():
			var seen_b: Dictionary = {}
			for bid in MissionConfig.endless_boons:
				seen_b[str(bid)] = int(seen_b.get(str(bid), 0)) + 1
			var parts: Array = []
			for bid in seen_b:
				parts.append("%s%s" % [str(Endless.BOONS[bid]["name"]), (" x%d" % int(seen_b[bid])) if int(seen_b[bid]) > 1 else ""])
			cap += "\n" + " · ".join(parts)
		ComicFx.caption(_fx, cap, Vector2(300.0, 300.0), BattleTheme.POP, 1.6)
	if DisplayServer.get_name() != "headless" and not shown.is_empty():
		var bdef: Dictionary = Arena.BEHAVIORS.get(Arena.behavior_of(str(BattleState.boss(shown)["char"])), {})
		get_tree().create_timer(2.4).timeout.connect(func() -> void:
			if is_inside_tree() and not bdef.is_empty():
				ComicFx.caption(_fx, "COMPORTAMENTO  //  %s\n%s" % [str(bdef["name"]), str(bdef["desc"])], Vector2(220.0, 330.0), BattleTheme.CY, 2.4))


func bind_source(src: Variant) -> void:
	source = src
	_hint_full = int(Feats.stats(RosterStore.load_or_new()).get("plays", 0)) < 4
	src.battle_updated.connect(_on_updated)
	src.battle_events_received.connect(_on_events)
	if _auto_button != null:
		_auto_button.visible = src.has_method("autoplay_round")
	if src is NetworkManager and _chat == null:
		_chat = ChatPanel.new().setup(src, true, Vector2(400, 210))
		_chat.position = Vector2(20, 304)
		_fx.add_child(_chat)
		_ping_row = HBoxContainer.new()
		_ping_row.add_theme_constant_override("separation", 4)
		_ping_row.position = Vector2(20, 276)
		for ping in ["INTERROMPI!", "PROTEGGIMI!", "HO UNA COMBO", "NON USARE RISORSE"]:
			var pb := Button.new()
			pb.text = str(ping)
			pb.custom_minimum_size = Vector2(0, 24)
			BattleTheme.style_button(pb, "normal", 11)
			pb.pressed.connect(func() -> void: src.send_chat(str(ping)))
			_ping_row.add_child(pb)
		_fx.add_child(_ping_row)
	if not src.battle.is_empty():
		_on_updated()


func _on_updated() -> void:
	if animating:
		return
	_sync()


var _banner_round: int = 0


func _sync() -> void:
	if log_lines.is_empty():
		_push_log("TURNO 01 AVVIATO", "info")
		_push_log("SEGNALE STABILE", "info")
	shown = (source.battle as Dictionary).duplicate(true)
	var rnd: int = int(shown.get("round", 0))
	if rnd > _banner_round and str(shown.get("winner", "")) == "" and AnimFx.enabled() and _fx != null:
		AnimFx.round_banner(_fx, "TURNO %d" % rnd)
	_banner_round = maxi(_banner_round, rnd)
	locked = false
	_swaps.clear()
	_picks.clear()
	_order_pick = ""
	_push_pick = ""
	_cur_slot = ""
	_cur_slot = _next_free_slot()
	_refresh_all()
	_check_end()
	_maybe_autoplay()


# Gli slot di front row vivi che il giocatore comanda (in rete: solo il suo).
func _my_slots() -> Array:
	var ids: Array = []
	if source != null and source.has_method("my_slots"):
		ids = source.my_slots()
	elif source != null:
		ids = [str(source.local_player_id)]
	var out: Array = []
	for sid in ids:
		var p: Dictionary = BattleState.player(shown, str(sid))
		if not p.is_empty() and BattleState.player_alive(shown, p):
			out.append(str(sid))
	return out


func _cur_slot_id() -> String:
	if _cur_slot != "":
		return _cur_slot
	return str(source.local_player_id) if source != null else ""


# Il primo slot vivo che non ha ancora un ordine (se tutti ce l'hanno, il primo).
func _next_free_slot() -> String:
	var slots: Array = _my_slots()
	for sid in slots:
		if not _picks.has(sid):
			return sid
	return str(slots[0]) if not slots.is_empty() else (str(source.local_player_id) if source != null else "")


func _maybe_autoplay() -> void:
	if not autoplay or source == null or not source.has_method("autoplay_round"):
		return
	if str(shown.get("winner", "")) != "" or animating or locked:
		return
	locked = true
	_refresh_orders()
	get_tree().create_timer(0.25).timeout.connect(func() -> void:
		if autoplay and is_inside_tree() and str(source.battle.get("winner", "")) == "":
			source.autoplay_round()
		else:
			locked = false
			_refresh_orders())


func set_autoplay(on: bool) -> void:
	autoplay = on
	if _auto_button != null:
		BattleTheme.style_button(_auto_button, "primary" if on else "normal", 16)
		if _auto_icon != null:
			_auto_icon.color = BattleTheme.BK if on else BattleTheme.CY
			_auto_icon.queue_redraw()
	if on:
		_maybe_autoplay()
	elif locked and not animating:
		locked = false
		_refresh_orders()


# ---------- Costruzione dell'interfaccia ----------

# Spazio in piu' (in unita' di gioco) fra il riquadro 1280x720 e i bordi dello schermo: su telefoni lunghi
# i comandi d'angolo vanno proprio nell'angolo e non restano dentro il riquadro.
var _edge_l: float = 0.0
var _edge_r: float = 0.0


func _pin_corners() -> void:
	if not is_inside_tree():
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var ins: Vector4 = ScreenFrame.view_insets(get_window(), vp)
	var box: Rect2 = ScreenFrame.box_for(vp, ins)
	_edge_l = maxf(0.0, box.position.x - ins.x)
	_edge_r = maxf(0.0, vp.x - box.position.x - box.size.x - ins.z)
	var lefts: Array = [_auto_button, speed_button, _round_label, _turn_box.get_parent() if _turn_box != null else null]
	var rights: Array = [_boss_panel, _phase_badge, _log_handle]
	for c in lefts:
		_shift_edge(c, -_edge_l)
	for c in rights:
		_shift_edge(c, _edge_r)


func _shift_edge(c: Control, dx: float) -> void:
	if c == null or not is_instance_valid(c):
		return
	if not c.has_meta("edge_base"):
		c.set_meta("edge_base", Vector2(c.offset_left, c.offset_right))
	var b: Vector2 = c.get_meta("edge_base")
	c.offset_left = b.x + dx
	c.offset_right = b.y + dx


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
	ScreenFx.solid(self, BattleTheme.BK)      # (non disegnato: lo schermo e' gia' pulito di questo colore)

	_stage = BattleStage.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.party_lift = 28.0 if TouchUi.active() else 0.0
	add_child(_stage)

	# velatura ciano, telecamera e retino da fumetto: un solo passaggio a tutto schermo
	_veil = ScreenFx.battle(self)

	_fx = Control.new()
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_camera_info()
	_build_boss_banner()
	_build_telegraph()
	_build_turn_panel()
	_build_operators()
	_build_orders()
	_build_log()
	_build_autoplay()
	add_child(_fx)
	_fx.move_to_front()

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)


# La freccia sopra chi sta scegliendo (nello strato degli effetti: sempre sopra pannelli e targhette).
func _update_select_arrow(picking: bool) -> void:
	if _select_arrow == null:
		if _fx == null:
			return
		_select_arrow = SelectArrow.new()
		_fx.add_child(_select_arrow)
	var p: Dictionary = BattleState.player(shown, _cur_slot_id()) if picking else {}
	if p.is_empty():
		_select_arrow.visible = false
		return
	var uid: String = str(p["active"])
	var idx: int = 0
	var players: Array = shown.get("players", [])
	for i in players.size():
		if str(players[i]["id"]) == str(p["id"]):
			idx = i
	var pose: Vector3 = _stage.party_pose(idx, players.size())
	var tip: Vector2 = _stage.anchor_of(uid) + Vector2(0.0, -(126.0 * pose.z) - 4.0)
	_select_arrow.visible = true
	_select_arrow.point_at(tip)


func _build_autoplay() -> void:
	_auto_button = Button.new()
	_auto_button.text = ""
	_auto_button.tooltip_text = "Gioco automatico (A)"
	_auto_icon = GameIcon.new().setup("bolt", BattleTheme.CY, 20.0)
	_auto_icon.set_anchors_preset(Control.PRESET_CENTER)
	_auto_icon.offset_left = -10.0
	_auto_icon.offset_right = 10.0
	_auto_icon.offset_top = -10.0
	_auto_icon.offset_bottom = 10.0
	_auto_button.add_child(_auto_icon)
	_auto_button.focus_mode = Control.FOCUS_NONE
	_auto_button.visible = false
	BattleTheme.style_button(_auto_button, "normal", 14)
	add_child(_auto_button)
	_anchor(_auto_button, Vector4(0.0, 0.0, 0.0, 0.0), Vector4(0, 0, 46, 34 if not TouchUi.active() else 44))
	_auto_button.pressed.connect(func() -> void: set_autoplay(not autoplay))
	# velocita' dell'animazione sempre a portata di dito: NORMALE -> VELOCE -> TURBO
	speed_button = Button.new()
	speed_button.focus_mode = Control.FOCUS_NONE
	BattleTheme.style_button(speed_button, "normal", 15)
	speed_button.text = _speed_label()
	speed_button.tooltip_text = "Velocita' della battaglia: normale, veloce, turbo"
	add_child(speed_button)
	_anchor(speed_button, Vector4(0.0, 0.0, 0.0, 0.0), Vector4(48, 0, 94, 34 if not TouchUi.active() else 44))
	speed_button.pressed.connect(func() -> void:
		Settings.next_speed()
		Settings.save()
		event_delay = Settings.event_delay()
		speed_button.text = _speed_label())


func _speed_label() -> String:
	if speed_button != null:
		speed_button.add_theme_font_size_override("font_size", [20, 16, 12][Settings.speed_level()])
	return ["▶", "▶▶", "▶▶▶"][Settings.speed_level()]


func _build_camera_info() -> void:
	# il numero del turno sta sotto i pulsanti, a sinistra (niente striscia REC: lo schermo resta pulito)
	_round_label = BattleTheme.make_label("TURNO 01", 18, BattleTheme.WH)
	_round_label.add_theme_font_override("font", BattleTheme.hud())
	_round_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_round_label)
	_anchor(_round_label, Vector4(0.0, 0.0, 0.0, 0.0), Vector4(2, 36, 150, 56))
	_clock_label = BattleTheme.make_label("", 15, BattleTheme.CY)
	_clock_label.visible = false
	add_child(_clock_label)


func _build_boss_banner() -> void:
	# nome e diciture del boss: al centro, sopra l'allarme
	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 0)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(head)
	_anchor(head, Vector4(0.5, 0.0, 0.5, 0.0), Vector4(-248, 2, 68, 50))
	_boss_name = BattleTheme.make_label("SOGGETTO", 26, BattleTheme.WH, true)
	_boss_name.clip_text = true
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_boss_name)
	_boss_meta = BattleTheme.make_label("", 12, BattleTheme.CY)
	_boss_meta.add_theme_font_override("font", BattleTheme.hud())
	_boss_meta.clip_text = true
	_boss_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_boss_meta)

	# barra vita in alto a destra con la fase nel tondo (come nei giochi di riferimento); l'equilibrio sta sul boss
	var panel := HudPanel.new().setup("", BattleTheme.RD)
	panel.bare = true
	panel.backdrop = 0.0
	_boss_panel = panel
	add_child(panel)
	panel.margins = Vector4(0.0, 0.0, 0.0, 0.0)
	_anchor(panel, Vector4(1.0, 0.0, 1.0, 0.0), Vector4(-470, 14, -74, 58))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.set_content(box)
	_boss_bar = LineBar.new().setup(BattleTheme.RD, Vector2(0, 14))
	_boss_bar.color_bg = Color(BattleTheme.RD_DARK, 0.9)
	box.add_child(_boss_bar)
	_boss_bal = LineBar.new().setup(BattleTheme.CY, Vector2(0, 6))        # equilibrio: sotto la vita, larga quanto lei
	_boss_bal.color_bg = Color(BattleTheme.CY_DARK, 0.9)
	box.add_child(_boss_bal)
	_boss_hp = BattleTheme.make_label("INTEGRITA'", 14, BattleTheme.WH)
	_boss_hp.add_theme_font_override("font", BattleTheme.hud())
	_boss_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(_boss_hp)
	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.02, 0.1, 0.12, 0.92)
	bsb.border_color = BattleTheme.CY
	bsb.set_border_width_all(3)
	bsb.set_corner_radius_all(26)
	badge.add_theme_stylebox_override("panel", bsb)
	add_child(badge)
	_anchor(badge, Vector4(1.0, 0.0, 1.0, 0.0), Vector4(-66, 8, -12, 62))
	_phase_label = BattleTheme.make_label("1", 26, BattleTheme.WH, true)
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(_phase_label)
	badge.tooltip_text = "Fase del boss"
	_phase_badge = badge

	# il tempo per scegliere compare solo quando c'e' un limite
	var timer_panel := HudPanel.new().setup("", BattleTheme.RD)
	timer_panel.bare = true
	timer_panel.backdrop = 0.0
	add_child(timer_panel)
	timer_panel.margins = Vector4(0.0, 0.0, 0.0, 0.0)
	_anchor(timer_panel, Vector4(0.0, 0.0, 0.0, 0.0), Vector4(168, 6, 270, 42))
	_timer_label = BattleTheme.make_label("", 22, BattleTheme.CY, true)
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_panel.set_content(_timer_label)
	timer_panel.visible = false
	_timer_panel = timer_panel


func _build_telegraph() -> void:
	_tele_panel = HudPanel.new().setup("ALLARME", BattleTheme.RD)
	_tele_panel.quiet = true
	add_child(_tele_panel)
	_tele_panel.margins = Vector4(12.0, 18.0, 12.0, 2.0)
	_anchor(_tele_panel, Vector4(0.5, 0.0, 0.5, 0.0), Vector4(-248, 54, 68, 116))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	_tele_panel.set_content(box)
	_tele_label = BattleTheme.make_label("PROSSIMA MOSSA", 22, BattleTheme.WH, true)
	_tele_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_tele_label)
	_tele_target = BattleTheme.make_label("", 13, BattleTheme.WH)
	_tele_target.add_theme_font_override("font", BattleTheme.hud())
	_tele_target.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_tele_target)
	_plan_label = BattleTheme.make_label("", 12, BattleTheme.POP)
	_plan_label.add_theme_font_override("font", BattleTheme.hud())
	_plan_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_plan_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plan_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_plan_label)
	_anchor(_plan_label, Vector4(0.5, 0.0, 0.5, 0.0), Vector4(-248, 118, 68, 152))
	_reserve_label = BattleTheme.make_label("", 12, BattleTheme.CY)
	_reserve_label.add_theme_font_override("font", BattleTheme.hud())
	_reserve_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reserve_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_reserve_label)
	_anchor(_reserve_label, Vector4(0.5, 0.0, 0.5, 0.0), Vector4(-248, 154, 68, 170))
	_react_row = HBoxContainer.new()
	_react_row.add_theme_constant_override("separation", 6)
	_react_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_react_row)
	_anchor(_react_row, Vector4(0.5, 0.0, 0.5, 0.0), Vector4(-248, 204, 68, 232))
	_tact_row = HBoxContainer.new()
	_tact_row.add_theme_constant_override("separation", 6)
	_tact_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_tact_row)
	_anchor(_tact_row, Vector4(0.5, 0.0, 0.5, 0.0), Vector4(-248, 172, 68, 200))
	_order_btn = Button.new()
	_order_btn.custom_minimum_size = Vector2(154, 26)
	_order_btn.clip_text = true
	BattleTheme.style_button(_order_btn, "normal", 12)
	_order_btn.pressed.connect(_cycle_order)
	_tact_row.add_child(_order_btn)
	_push_btn = Button.new()
	_push_btn.custom_minimum_size = Vector2(154, 26)
	_push_btn.clip_text = true
	BattleTheme.style_button(_push_btn, "normal", 12)
	_push_btn.pressed.connect(_cycle_push)
	_tact_row.add_child(_push_btn)
	_refresh_tactics()


# Pannello "ORDINE DEL TURNO": chi agisce, in che ordine e cosa ha scelto (le IA decidono da sole).
func _build_turn_panel() -> void:
	var panel := HudPanel.new().setup("ORDINE DEL TURNO", BattleTheme.CY_DIM)
	panel.quiet = true
	panel.margins = Vector4(10, 24, 10, 4)
	panel.backdrop = 0.4
	add_child(panel)
	_anchor(panel, Vector4(0.0, 0.0, 0.0, 0.0), Vector4(0, 58, 281, 172))
	_turn_box = VBoxContainer.new()
	_turn_box.add_theme_constant_override("separation", 1)
	_turn_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_content(_turn_box)


# Una riga per unita', nell'ordine in cui agiranno: "1 TU KIRA » COLPO CARICATO".
func turn_rows() -> Array:
	var rows: Array = []
	if shown.is_empty() or str(shown["winner"]) != "":
		return rows
	var me: Dictionary = _local_player()
	var mine_slots: Array = _my_slots()
	var n: int = 0
	for entry in BattleResolver.action_order(shown):
		n += 1
		var action: String = ""
		var row: Dictionary = {"n": n, "unit": str(entry["unit"]), "boss": bool(entry["boss"]), "mine": false, "color": BattleTheme.CY}
		if bool(entry["boss"]):
			row["who"] = "BOSS"
			row["name"] = str(BattleState.boss(shown)["name"]).to_upper()
			row["action"] = BattleText.move_name(str(entry["move"]))
			row["color"] = BattleTheme.RD
		else:
			var p: Dictionary = BattleState.player(shown, str(entry["player"]))
			var u: Dictionary = BattleState.unit(shown, str(entry["unit"]))
			var mine: bool = not me.is_empty() and mine_slots.has(str(p["id"]))
			row["mine"] = mine
			row["name"] = str(u.get("name", "?")).to_upper()
			row["who"] = "" if mine else ("IA" if bool(p["ai"]) else str(p["name"]).to_upper().left(4))
			var choice: Variant = p["choice"]
			if mine:
				var pend: String = str(_swaps.get(str(p["id"]), ""))
				if locked or autoplay or _picks.has(str(p["id"])) or (choice is Dictionary and choice.has("move")):
					action = BattleText.move_name(str(entry["move"])) if str(entry["move"]) != "" else ("AUTO" if autoplay else (BattleText.move_name(str(_picks[str(p["id"])]["move"])) if _picks.has(str(p["id"])) else "BLOCCATO"))
				else:
					action = "Scegli" + (" (cambio)" if pend != "" else "")
				row["color"] = BattleTheme.WH
				row["slot"] = str(p["id"])
			elif choice is Dictionary and choice.has("move"):
				action = BattleText.move_name(str(entry["move"]))
				if str(entry["swap"]) != "" and str(entry["swap"]) != str(p["active"]):
					action = "CAMBIO + " + action
			else:
				action = "HA SCELTO" if choice is Dictionary and bool(choice.get("locked", false)) else "SCEGLIE..."
		row["action"] = action if not bool(entry["boss"]) else str(row["action"])
		rows.append(row)
	return rows


func _refresh_turn_panel() -> void:
	if _turn_box == null:
		return
	var rows: Array = turn_rows()
	var sig: String = "%s|%d|%s|%s|%s|%s" % [_turn_acting, int(shown.get("round", 0)) if not shown.is_empty() else 0, str(locked), str(_swaps), str(_picks.keys()), _cur_slot]
	for r in rows:
		sig += "|%s,%s,%s" % [str(r["unit"]), str(r["action"]), str(r["who"])]
	if sig == _turn_sig:
		return
	_turn_sig = sig
	for c in _turn_box.get_children():
		_turn_box.remove_child(c)
		c.queue_free()
	if rows.is_empty():
		return
	var fs: int = 15 if not TouchUi.active() else 16
	var any_who: bool = false
	for r in rows:
		if str(r["who"]) != "":
			any_who = true
	# una riga = una HBox con colonne a larghezza fissa e lo stesso font (Roboto Bold, MAIUSCOLO): stessa baseline per tutti
	for r in rows:
		var acting_now: bool = str(r["unit"]) == _turn_acting
		var col: Color = BattleTheme.GOLD if acting_now else (r["color"] as Color)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(_turn_cell(("▶ " if acting_now else "") + str(int(r["n"])), fs, col, 30.0, true))
		if any_who:
			line.add_child(_turn_cell(str(r["who"]), fs, col, 42.0))
		line.add_child(_turn_cell(str(r["name"]).left(8), fs, col, 84.0))
		var act_cell: Label = _turn_cell("» " + str(r["action"]), fs, col, 0.0)
		if str(r["action"]).begins_with("Scegli"):
			act_cell.set_meta("keep_case", true)
		line.add_child(act_cell)
		_turn_box.add_child(line)


func _turn_cell(text: String, size: int, color: Color, width: float, right: bool = false) -> Label:
	var l := BattleTheme.make_label(text, size, color)
	l.add_theme_font_override("font", BattleTheme.hud())
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if width > 0.0:
		l.custom_minimum_size = Vector2(width, 0)
	else:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _build_operators() -> void:
	var panel := HudPanel.new().setup("", BattleTheme.CY)
	panel.bare = true
	panel.margins = Vector4(10.0, 10.0, 10.0, 8.0)
	add_child(panel)
	_anchor(panel, Vector4(0.0, 1.0, 0.0, 1.0), Vector4(8, -(_unit_row_height() * 2.0 + 44.0), 340, -8))
	_ops_panel = panel
	_ops_box = VBoxContainer.new()
	_ops_box.add_theme_constant_override("separation", 3)
	panel.set_content(_ops_box)


func _build_orders() -> void:
	_fan_anchor = Control.new()
	_fan_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fan_anchor.position = Vector2(300.0, 300.0)
	_fan_anchor.size = Vector2(380.0, 330.0)
	add_child(_fan_anchor)
	_orders_box = FanMenu.new()
	_orders_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_orders_box)


# Il ventaglio nasce dal torace dell'operatore del giocatore, dove lo disegna il palco.
func _fan_origin() -> Vector2:
	var idx: int = 0
	var players: Array = shown.get("players", [])
	for i in players.size():
		if str(players[i]["id"]) == _cur_slot_id():
			idx = i
	var pose: Vector3 = _stage.party_pose(idx, players.size())
	# il ventaglio si apre a destra di tutta la squadra, cosi' non copre nessun operatore
	var last: Vector3 = _stage.party_pose(maxi(0, players.size() - 1), players.size())
	return Vector2(last.x - 145.0, pose.y - 95.0 * pose.z)


func _build_log() -> void:
	var panel := HudPanel.new().setup("", BattleTheme.CY_DIM)
	panel.bare = true
	panel.margins = Vector4(12, 8, 12, 6)
	add_child(panel)
	_anchor(panel, Vector4(1.0, 1.0, 1.0, 1.0), Vector4(-370, -170, -10, -38))
	panel.visible = false
	_log_panel = panel
	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.scroll_active = false
	_log_label.fit_content = false
	_log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log_label.add_theme_font_override("normal_font", BattleTheme.hud())
	_log_label.add_theme_font_size_override("normal_font_size", 16 if TouchUi.active() else 15)
	panel.set_content(_log_label)
	# maniglia: tira su / giu' il registro degli eventi (chiuso occupa solo questo tasto)
	_log_handle = Button.new()
	_log_handle.focus_mode = Control.FOCUS_NONE
	BattleTheme.style_button(_log_handle, "normal", 13)
	_log_handle.tooltip_text = "Registro degli eventi"
	add_child(_log_handle)
	_anchor(_log_handle, Vector4(1.0, 1.0, 1.0, 1.0), Vector4(-96 if not TouchUi.active() else -130, -34 if not TouchUi.active() else -68, -10, -8 if not TouchUi.active() else -6))
	_log_handle.pressed.connect(toggle_log)
	_refresh_log_handle()


func toggle_log() -> void:
	_log_open = not _log_open
	if _log_panel != null:
		_log_panel.visible = _log_open
		if _log_open:
			_log_panel.modulate.a = 0.0
			create_tween().tween_property(_log_panel, "modulate:a", 1.0, 0.15)
			_log_seen = "\n".join(log_lines.slice(maxi(0, log_lines.size() - 4)))
	_refresh_log_handle()


func _refresh_log_handle() -> void:
	if _log_handle == null:
		return
	var fresh: bool = not _log_open and "\n".join(log_lines.slice(maxi(0, log_lines.size() - 4))) != _log_seen
	_log_handle.text = ("LOG ▼" if _log_open else "LOG ▲") + ("  •" if fresh else "")


# ---------- Aggiornamento ----------

func _process(delta: float) -> void:
	_t += delta
	_watch_performance(delta)
	if _stage != null:
		var picking: bool = not locked and not animating and not autoplay and not shown.is_empty() and str(shown.get("winner", "")) == ""
		_stage.select_slot = _cur_slot_id() if picking else ""
		_stage.hp_visible = picking          # le barre vita sotto i personaggi si vedono mentre si sceglie
		_update_select_arrow(picking)
	if _rec_dot != null:
		var on: bool = int(_t * 1.6) % 2 == 0
		if _rec_dot.visible != on:
			_rec_dot.visible = on
	# l'orologio e il timer cambiano una volta al secondo: niente testo nuovo a ogni frame
	var now_sec: int = int(Time.get_unix_time_from_system())
	if _clock_label != null and now_sec != _clock_sec:
		_clock_sec = now_sec
		var d: Dictionary = Time.get_datetime_dict_from_system()
		_clock_label.text = "%02d.%02d.%04d  %02d:%02d:%02d" % [d["day"], d["month"], d["year"], d["hour"], d["minute"], d["second"]]
	if source != null and _timer_label != null:
		var left: float = float(source.battle_time_left)
		var secs: int = -1 if left < 0.0 else int(ceil(left))
		if secs != _timer_secs:
			_timer_secs = secs
			if _timer_panel != null:
				_timer_panel.visible = secs >= 0
			if secs < 0:
				_timer_label.text = ""
			else:
				_timer_label.text = "%02d:%02d" % [secs / 60, secs % 60]
				_timer_label.add_theme_color_override("font_color", BattleTheme.RD if secs <= 10 else BattleTheme.WH)


# Se il dispositivo e' lento (meno di ~40 fps per 4 secondi di battaglia) si passa da soli agli effetti ridotti:
# stessa battaglia, meno peso grafico. Si cambia una volta sola e si puo' sempre riattivare nelle impostazioni.
func _watch_performance(delta: float) -> void:
	if _perf_checked or Settings.light_fx or not animating or DisplayServer.get_name() == "headless":
		return
	_perf_time += delta
	_perf_frames += 1
	if _perf_time < 4.0:
		return
	_perf_checked = true
	if float(_perf_frames) / _perf_time < 40.0:
		Settings.light_fx = true
		Settings.save()
		if _veil != null and is_instance_valid(_veil):
			_veil.visible = false
		Notify.toast("EFFETTI RIDOTTI AUTOMATICAMENTE (piu' fluido)", Notify.Kind.INFO)


func _refresh_all() -> void:
	if shown.is_empty():
		return
	_refresh_plan_hint()
	_stage.local_player_id = str(source.local_player_id)
	_stage.set_state(shown)
	_refresh_boss()
	_refresh_telegraph()
	_refresh_operators()
	_refresh_orders()
	_refresh_turn_panel()
	_refresh_log()
	_round_label.text = "TURNO %02d" % int(shown["round"])


func _refresh_boss() -> void:
	var boss: Dictionary = BattleState.boss(shown)
	var info: Dictionary = BattleContent.BOSSES.get(str(boss["char"]), {})
	var tier_name: String = str(BattleContent.tier_of(int(shown.get("tier", 0)))["name"])
	if int(shown.get("endless", 0)) > 0:
		var emod: Dictionary = Endless.mod_for(int(shown["endless"]))
		tier_name = "PIANO %d%s" % [int(shown["endless"]), (" · " + str(emod["name"])) if not emod.is_empty() else ""]
	_boss_name.text = str(info.get("name", "SOGGETTO")).to_upper()
	_boss_meta.text = ("%s · %s" % [str(info.get("title", "")), tier_name]).to_upper()
	_boss_bar.set_values(float(boss["hp"]) / float(boss["max_hp"]), float(boss.get("shield", 0)) / float(boss["max_hp"]))
	var stunned: bool = int(boss.get("stun", 0)) > 0 or bool(boss.get("exposed", false))
	_boss_bal.set_values(0.0 if stunned else float(boss.get("balance", 0)) / float(maxi(1, int(boss.get("balance_max", 1)))), 0.0)
	var tags: String = ""
	if int(boss.get("stun", 0)) > 0:
		tags += "  [STORDITO]"
	elif int(shown.get("phase", 1)) > 1:
		tags += "  [FASE %d]" % int(shown["phase"])
	for s in boss["statuses"]:
		if str(s) == "mark" and int(boss.get("marks", 0)) > 0:
			tags += "  [MARCHI x%d]" % int(boss["marks"])
		else:
			tags += "  [%s]" % BattleText.status_name(str(s))
	for m in boss.get("mods", []):
		if int(m["pm"]) < 0:
			tags += " ▼%s" % str(BattleContent.STAT_NAMES.get(str(m["stat"]), str(m["stat"]).to_upper()))
	_boss_hp.text = "PV  %d/%d%s" % [int(boss["hp"]), int(boss["max_hp"]), tags]
	if _phase_label != null:
		_phase_label.text = str(int(shown.get("phase", 1)))


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
	if int(BattleState.boss(shown).get("stun", 0)) > 0:
		_tele_label.text = "STORDITO"
		_tele_target.text = "SALTERA' LA MOSSA: %s" % BattleText.move_name(move_id).to_upper()
		return
	_tele_label.text = BattleText.move_name(move_id)
	var tlen: int = _tele_label.text.length()
	_tele_label.add_theme_font_size_override("font_size", 24 if tlen <= 17 else maxi(16, int(24.0 * 17.0 / float(tlen))))
	if str(def["target"]) == "all":
		_tele_target.text = "COLPISCE TUTTI GLI OPERATORI"
	else:
		var tp: Dictionary = BattleState.player(shown, str(tele["target"]))
		var who: String = "?"
		if not tp.is_empty():
			var au: Dictionary = BattleState.unit(shown, str(tp["active"]))
			who = str(au.get("name", "?")).to_upper()
		var mine: bool = _my_slots().has(str(tele["target"]))
		_tele_target.text = "BERSAGLIO: %s%s" % [who, ""]
	if BattleResolver.is_heavy_boss_move(def) and not _tele_target.text.begins_with("STORDITO"):
		_tele_label.text = "CARICA · " + _tele_label.text
		_tele_label.add_theme_font_size_override("font_size", 18)
	# MINACCIA: se la mossa annunciata e' letale per qualcuno lo si dice chiaramente
	var threat: Dictionary = BattleResolver.threat_preview(shown)
	var lethal: Array = threat["lethal"]
	if lethal.is_empty():
		_tele_target.add_theme_color_override("font_color", BattleTheme.WH)
	else:
		var names: Array = []
		for uid in lethal:
			names.append(str(BattleState.unit(shown, str(uid)).get("name", "?")).to_upper())
		_tele_target.text = "LETALE PER %s!" % ", ".join(names)
		_tele_target.add_theme_color_override("font_color", BattleTheme.RD)
		if _threat_round != int(shown.get("round", 0)) and not animating:
			_threat_round = int(shown.get("round", 0))
			Snd.play("boss_charge", 1.3)
			_buzz(60)


# Suggerimenti di pianificazione: sinergie gia' pronte con le scelte dei compagni.
# ORDINE DI SQUADRA e PREZZO: due scelte facoltative che accompagnano la mossa del round.
func _cycle_order() -> void:
	var i: int = Tactics.ORDER_ORDER.find(_order_pick)
	_order_pick = "" if i == Tactics.ORDER_ORDER.size() - 1 else str(Tactics.ORDER_ORDER[i + 1])
	_refresh_tactics()


func _cycle_push() -> void:
	var i: int = Tactics.PUSH_ORDER.find(_push_pick)
	_push_pick = "" if i == Tactics.PUSH_ORDER.size() - 1 else str(Tactics.PUSH_ORDER[i + 1])
	_refresh_tactics()


func _refresh_tactics() -> void:
	if _order_btn == null:
		return
	var busy: bool = locked or animating or autoplay or str(shown.get("winner", "")) != ""
	_tact_row.visible = not busy
	_order_btn.text = "ORD: " + (str(Tactics.ORDERS[_order_pick]["name"]) if _order_pick != "" else "NESSUNO")
	_order_btn.tooltip_text = str(Tactics.ORDERS[_order_pick]["desc"]) if _order_pick != "" else "Un ordine comune alla squadra: vale quello della maggioranza."
	_push_btn.text = "COSTO: " + (str(Tactics.PUSH[_push_pick]["name"]) if _push_pick != "" else "NO")
	_push_btn.tooltip_text = str(Tactics.PUSH[_push_pick]["desc"]) if _push_pick != "" else "Potere in cambio di PV e reazioni. Vale per il prossimo attacco."
	BattleTheme.style_button(_order_btn, "primary" if _order_pick != "" else "normal", 12)
	BattleTheme.style_button(_push_btn, "primary" if _push_pick != "" else "normal", 12)


func _refresh_plan_hint() -> void:
	if _plan_label == null:
		return
	_refresh_tactics()
	_refresh_reactions()
	if locked or animating or autoplay or str(shown.get("winner", "")) != "":
		_plan_label.text = ""
		return
	var hints: Array = BattleResolver.plan_hints(shown, _cur_slot_id())
	if not _hint_full:
		hints = hints.map(func(h: Variant) -> String: return "???" if str(h).begins_with("Questo boss reagisce") else str(h))
	_plan_label.text = "\n".join(hints.slice(0, 2))


# RISERVA DI SQUADRA + REAZIONI: i tasti compaiono solo quando il boss prepara una CARICA.
func _refresh_reactions() -> void:
	if _reserve_label == null:
		return
	var res: int = int(shown.get("reserve", 0))
	var pips: String = ""
	for i in BattleTypes.RESERVE_MAX:
		pips += "●" if i < res else "○"
	_reserve_label.text = "RISERVA DI SQUADRA  %s" % pips
	var list: Array = []
	if not (locked or animating or autoplay or str(shown.get("winner", "")) != ""):
		list = BattleResolver.reactions_for(shown, _cur_slot_id())
	var sig: String = "%d|%s" % [res, _cur_slot_id()]
	for r in list:
		sig += "|%s:%s" % [str(r["id"]), str(r["err"])]
	if sig == _react_sig:
		return
	_react_sig = sig
	for c in _react_row.get_children():
		_react_row.remove_child(c)
		c.queue_free()
	for r in list:
		var rid: String = str(r["id"])
		var b := Button.new()
		b.text = "%s · %d" % [BattleText.move_name(rid).to_upper(), BattleResolver.reaction_cost(shown, rid)]
		b.tooltip_text = str(r["err"]) if str(r["err"]) != "" else _reaction_help(rid)
		BattleTheme.style_button(b, "normal", 13)
		b.disabled = str(r["err"]) != ""
		b.pressed.connect(_on_order_pressed.bind(rid))
		_react_row.add_child(b)


func _reaction_help(rid: String) -> String:
	match rid:
		"soccorso":
			return "Rimetti in piedi un compagno caduto (25% PV). Una volta a testa."
		"schivata":
			return "Eviti del tutto la carica. Costa 1 Riserva."
		"intercettazione":
			return "Prendi tu la carica al posto del compagno (danno ridotto). Costa 2 Riserva."
		_:
			return "Colpisci l'equilibrio del boss: se si rompe, la carica salta. Costa 2 Riserva."


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
	var me: Dictionary = _local_player()
	var slots: Array = []
	if not me.is_empty():
		slots = _all_my_slots()
	# firma di cio' che si vede: se non e' cambiata nulla, i nodi restano dove sono
	var sig: String = ""
	if not me.is_empty():
		sig = "%s|%s|%s|" % [_cur_slot_id(), str(_swaps), str(_picks.keys())]
		for uid in BattleState.party_of(shown, me):
			var tu: Dictionary = BattleState.unit(shown, uid)
			sig += "%s,%s,%d,%d,%d,%d,%d,%s,%d,%d,%d;" % [uid, str(BattleState.is_front(shown, uid)), int(tu["hp"]), int(tu["max_hp"]), int(tu["energy"]), int(tu["gauge"]), int(tu["level"]), Factions.aura_text(tu), int(tu["ammo"]), (tu["mods"] as Array).size(), int(tu.get("shield", 0))]
		for p in shown["players"]:
			if p["id"] != me["id"] and not slots.has(str(p["id"])):
				var ta: Dictionary = BattleState.unit(shown, str(p["active"]))
				sig += "%s,%d,%d;" % [str(ta.get("name", "?")), int(ta.get("hp", 0)), int(ta.get("max_hp", 1))]
	_refresh_turn_panel()
	if sig == _ops_sig and _ops_box.get_child_count() > 0:
		return
	_ops_sig = sig
	for c in _ops_box.get_children():
		_ops_box.remove_child(c)
		c.queue_free()
	if me.is_empty():
		return
	# front row: un'unita' per slot (si clicca per dare gli ordini a quello slot); a destra di ognuna, il compagno in panchina che sostituisce
	var cur: String = _cur_slot_id()
	var cur_swap: String = pending_swap
	var backs: Array = []
	for uid in BattleState.party_of(shown, me):
		if not BattleState.is_front(shown, str(uid)):
			backs.append(str(uid))
	var bi: int = 0
	_pair_arrows.clear()
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 8)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for sid in slots:
		var sp: Dictionary = BattleState.player(shown, sid)
		var u: Dictionary = BattleState.unit(shown, str(sp["active"]))
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var urow: Control = _unit_row(u, sid == cur, true, sid, _picks.has(sid))
		urow.custom_minimum_size.x = 300.0
		col.add_child(urow)
		if bi < backs.size():
			# frecce fra chi sta davanti e chi lo sostituisce: si preme la casella sotto per fare lo switch
			var arrows := BattleTheme.make_label("▲▼", 11, BattleTheme.WH if str(backs[bi]) == cur_swap else BattleTheme.CY_DIM)
			arrows.add_theme_font_override("font", BattleTheme.hud())
			arrows.custom_minimum_size = Vector2(0, 13)
			arrows.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			arrows.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			arrows.mouse_filter = Control.MOUSE_FILTER_IGNORE
			arrows.set_meta("keep_case", true)
			col.add_child(arrows)
			_pair_arrows[sid] = arrows
			var bench_card: Control = _back_row(BattleState.unit(shown, str(backs[bi])), str(backs[bi]) == cur_swap)
			bench_card.custom_minimum_size.x = 300.0
			col.add_child(bench_card)
			bi += 1
		strip.add_child(col)
	_ops_box.add_child(strip)
	if bi < backs.size():
		var bench := HBoxContainer.new()
		bench.add_theme_constant_override("separation", 4)
		bench.mouse_filter = Control.MOUSE_FILTER_IGNORE
		while bi < backs.size():
			bench.add_child(_back_row(BattleState.unit(shown, str(backs[bi])), str(backs[bi]) == cur_swap))
			bi += 1
		_ops_box.add_child(bench)
	# altri giocatori (rete): solo l'unita' attiva, tutti su una riga
	var allies := HBoxContainer.new()
	allies.add_theme_constant_override("separation", 14)
	allies.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for p in shown["players"]:
		if p["id"] == me["id"] or slots.has(str(p["id"])):
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
	_fit_ops_panel(slots.size(), backs.size(), allies.get_child_count() > 0)


# Tutti gli slot di front row del giocatore (anche quelli senza personaggio vivo in campo).
func _all_my_slots() -> Array:
	var out: Array = []
	if source != null and source.has_method("my_slots"):
		for sid in source.my_slots():
			out.append(str(sid))
	else:
		out.append(str(source.local_player_id))
	return out


# Il riquadro cresce con la back row (fino a 3 front + 3 back).
func _fit_ops_panel(fronts: int, backs: int, with_allies: bool) -> void:
	if _ops_panel == null:
		return
	var rows: float = 2.0 if backs > 0 else 1.0
	var h: float = 20.0 + _unit_row_height() * rows + (13.0 if backs > 0 else 0.0) + (20.0 if with_allies else 0.0)
	if backs > fronts:
		h += _unit_row_height() + 3.0
	var right: float = 12.0 + 20.0 + 308.0 * float(maxi(fronts, 1))
	_anchor(_ops_panel, Vector4(0.0, 1.0, 0.0, 1.0), Vector4(8, -(h + 8.0), right, -8))


func _back_row_height() -> float:
	return _unit_row_height()


# Casella di chi sta in panchina, accanto alla riga di chi sostituisce: nome, barra PV e energia.
# Tocca per mandarlo in campo al posto del personaggio selezionato.
func _back_row(u: Dictionary, selected: bool) -> Control:
	var alive: bool = BattleState.is_alive(u)
	var h: float = _back_row_height()
	var w: float = 300.0
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(w, h)
	btn.flat = true
	btn.disabled = not alive
	btn.clip_contents = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st in ["normal", "hover", "pressed", "disabled"]:
		btn.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	btn.pressed.connect(_on_unit_pressed.bind(str(u["id"])))
	var bgc := ColorRect.new()
	bgc.set_anchors_preset(Control.PRESET_FULL_RECT)
	bgc.color = BattleTheme.CY if selected else Color(0.03, 0.09, 0.11)
	bgc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(bgc)
	var key := ColorRect.new()
	key.color = BattleTheme.unit_color(str(u["color"]))
	key.size = Vector2(5, h)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(key)
	var fg: Color = BattleTheme.BK if selected else (BattleTheme.CY_DIM if alive else BattleTheme.CY_DARK)
	var name_l := BattleTheme.make_label(str(u["name"]).to_upper(), 12, fg, true)
	name_l.position = Vector2(10, 2)
	name_l.size = Vector2(w - 12.0, 16)
	name_l.clip_text = true
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_l)
	var ratio: float = float(u["hp"]) / float(u["max_hp"])
	var hp := LineBar.new().setup(BattleTheme.BK if selected else (BattleTheme.RD if ratio < 0.3 else BattleTheme.OK), Vector2(w - 18.0, 6))
	hp.color_bg = Color(0, 0, 0, 0.35) if selected else Color(0, 0, 0, 0.5)
	hp.set_values(ratio)
	hp.position = Vector2(10, 20)
	btn.add_child(hp)
	var info: String = "K.O." if not alive else ("⇄ IN" if selected else "EN %d/%d" % [int(u["energy"]), BattleTypes.MAX_ENERGY])
	var note := _row_text(info, 12, fg, Vector2(10, 23), w - 12.0)
	note.size.y = 14.0
	note.custom_minimum_size.y = 14.0
	btn.add_child(note)
	return btn


# Altezza della riga di un operatore: sul telefono e' piu' alta, per il dito.
func _unit_row_height() -> float:
	return 54.0 if TouchUi.active() else 48.0


# Sotto il nome: fazione, aure, munizioni, effetti. Ognuno si puo' puntare o toccare per leggere cosa significa.
func _add_chips(inner: Control, u: Dictionary, selected: bool) -> void:
	var f: String = str(u.get("faction", ""))
	if f == "":
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	inner.add_child(row)
	var tint: Color = Hints.faction_color(f)
	if selected:
		tint = BattleTheme.BK
	var fac: InfoChip = InfoChip.faction_icon(f, tint)
	HintCard.bind(fac, func() -> Dictionary: return Hints.faction_card(BattleState.unit(shown, str(u["id"]))), self)
	fac.position = Vector2(196.0, 2.0 if not TouchUi.active() else 0.0)
	inner.add_child(fac)
	row.position = Vector2(206.0, 25.0 if not TouchUi.active() else 22.0)
	if int(u.get("ammo_max", 0)) > 0:
		var am: InfoChip = InfoChip.ammo(int(u["ammo"]), int(u["ammo_max"]), tint if selected else Hints.faction_color("libracorp"))
		HintCard.bind(am, func() -> Dictionary: return Hints.ammo_card(BattleState.unit(shown, str(u["id"]))), self)
		row.add_child(am)


func _unit_row(u: Dictionary, selected: bool, is_active: bool, slot: String = "", picked: bool = false) -> Control:
	var alive: bool = BattleState.is_alive(u)
	var row_h: float = _unit_row_height()
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, row_h)
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
	key.size = Vector2(6, row_h)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(key)
	# il contenuto resta disegnato come per i 44 punti originali, centrato nella riga
	var inner := Control.new()
	inner.position = Vector2(0, (row_h - 44.0) * 0.5)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(inner)

	var fg: Color = BattleTheme.BK if selected else (BattleTheme.CY if alive else BattleTheme.CY_DARK)
	var title: String = str(u["name"]).to_upper()
	if is_active and picked:
		title += "  ✓"
	var where: String = "K.O." if not alive else ("FRONT" if is_active else "BACK")
	var name_l := _row_text(title, 17, fg, Vector2(54, 0), 94.0)
	name_l.clip_text = true
	inner.add_child(name_l)
	# freccia del colore: ▲ danno maggiorato contro il boss, ▼ ridotto (il colore giusto fa +50%)
	if alive:
		var cm: float = BattleTypes.color_multiplier(str(u["color"]), str(BattleState.boss(shown)["color"]))
		if cm != 1.0:
			var arrow := BattleTheme.make_label("▲" if cm > 1.0 else "▼", 16, (BattleTheme.OK if cm > 1.0 else BattleTheme.RD) if not selected else BattleTheme.BK)
			arrow.position = Vector2(54.0 + minf(BattleTheme.hud().get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x, 86.0) + 4.0, 0)
			arrow.tooltip_text = "Danno +50% contro questo boss" if cm > 1.0 else "Danno ridotto contro questo boss"
			inner.add_child(arrow)
	# volto dell'operatore (la grafica vera se c'e', altrimenti il segnaposto anime)
	var face := PortraitView.new().setup(str(u["char"]), "icon")
	face.position = Vector2(10, 2)
	face.size = Vector2(38, 38)
	face.modulate = Color(1, 1, 1, 1.0 if alive else 0.4)
	inner.add_child(face)
	var lv_l := _row_text("LV%d" % int(u["level"]), 12, fg, Vector2(150, 0), 40.0)
	inner.add_child(lv_l)

	_add_chips(inner, u, selected)

	var hp_ratio: float = float(u["hp"]) / float(u["max_hp"])
	var hp := LineBar.new().setup(BattleTheme.BK if selected else (BattleTheme.RD if hp_ratio < 0.3 else BattleTheme.OK), Vector2(144, 8))
	if selected:
		hp.color_bg = Color(0, 0, 0, 0.35)
		hp.color_shield = Color("#1a6a99")
	hp.set_values(hp_ratio, float(u.get("shield", 0)) / float(u["max_hp"]))
	hp.position = Vector2(54, 22)
	inner.add_child(hp)
	var hp_t := _row_text("%d" % int(u["hp"]), 18, fg, Vector2(220, 0), 60.0)
	inner.add_child(hp_t)

	# energia come numero (2/6), ultimate come barra con la percentuale accanto
	var en_t := _row_text("EN %d/%d" % [int(u["energy"]), BattleTypes.MAX_ENERGY], 12, fg, Vector2(54, 27), 52.0)
	en_t.size.y = 14.0
	en_t.custom_minimum_size.y = 14.0
	inner.add_child(en_t)
	var gauge := LineBar.new().setup(BattleTheme.BK if selected else BattleTheme.RD, Vector2(62, 6))
	gauge.color_bg = Color(0, 0, 0, 0.35) if selected else Color(BattleTheme.RD_DARK, 0.8)
	var gr: float = float(u["gauge"]) / float(BattleTypes.GAUGE_MAX)
	gauge.set_values(gr)
	gauge.position = Vector2(110, 31)
	inner.add_child(gauge)
	var gp_t := _row_text("%d%%" % int(round(clampf(gr, 0.0, 1.0) * 100.0)), 12, fg, Vector2(176, 27), 34.0)
	gp_t.size.y = 14.0
	gp_t.custom_minimum_size.y = 14.0
	inner.add_child(gp_t)
	if not alive:
		var where_l := BattleTheme.make_label(where, 11, fg, true)
		where_l.position = Vector2(250, 3)
		inner.add_child(where_l)
	if int(u["gauge"]) >= BattleTypes.GAUGE_MAX and alive:
		lv_l.text = "ULT!"
		lv_l.add_theme_color_override("font_color", BattleTheme.BK if selected else BattleTheme.RD)
	return btn


# Testo di una riga operatore: Roboto Bold (MAIUSCOLO) e altezza fissa con centratura verticale, cosi' nome, livello e PV
# stanno sulla stessa linea ottica anche con dimensioni diverse.
func _row_text(text: String, size: int, color: Color, pos: Vector2, width: float) -> Label:
	var l := BattleTheme.make_label(text, size, color)
	l.add_theme_font_override("font", BattleTheme.hud())
	if color.get_luminance() < 0.35:
		l.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.0))     # testo scuro su fondo chiaro: niente ombra nera che lo impasta
	l.position = pos
	l.size = Vector2(width, 24)
	l.custom_minimum_size = Vector2(width, 24)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _on_unit_pressed(uid: String) -> void:
	if animating or locked or autoplay or str(shown.get("winner", "")) != "":
		return
	var slot: String = BattleState.slot_of(shown, uid)
	if slot != "" and _my_slots().has(slot):
		# un personaggio di front row: si danno gli ordini a lui
		if slot != _cur_slot_id():
			_cur_slot = slot
			_picks.erase(slot)
	else:
		# un personaggio di back row: entra al posto di quello selezionato (gratis, prima di tutto)
		var cur: String = _cur_slot_id()
		var same: bool = pending_swap == uid
		for other in _swaps.keys():
			if str(_swaps[other]) == uid:
				_swaps[other] = ""
		_swaps[cur] = "" if same else uid
		_picks.erase(cur)
		if not same:
			_coach_note("swap")
			_pending_balloon = cur
	_ops_sig = ""
	_refresh_operators()
	_refresh_orders()
	if _pending_balloon != "":
		_switch_balloon(_pending_balloon)
		_pending_balloon = ""


# Ordini: attacco, guardia, skill e ultimate dell'unita' che agira'.
func _refresh_orders() -> void:
	var me: Dictionary = _local_player()
	if me.is_empty() or str(shown["winner"]) != "":
		_orders_sig = ""
		for c in _orders_box.get_children():
			_orders_box.remove_child(c)
			c.queue_free()
		_order_buttons.clear()
		_orders_box.clear_arc()
		return
	# scelte fatte (o round in corso / autoplay): il ventaglio sparisce e si vede lo scontro
	if locked or animating or autoplay:
		_orders_sig = ""
		for c in _orders_box.get_children():
			_orders_box.remove_child(c)
			c.queue_free()
		_order_buttons.clear()
		_orders_box.clear_arc()
		return
	var cur_p: Dictionary = BattleState.player(shown, _cur_slot_id())
	if cur_p.is_empty():
		cur_p = me
	var uid: String = pending_swap if pending_swap != "" else str(cur_p["active"])
	var u: Dictionary = BattleState.unit(shown, uid)
	# firma di cio' che si vede (testi e pulsanti spenti): se e' uguale non si ricostruisce
	var sig: String = "%s|%s|%s|%s|%d|%s|%s" % [uid, pending_swap, locked, animating, int(u["gauge"]), _cur_slot_id(), str(autoplay)]
	var sig_ids: Array = []
	sig_ids.append_array(u["skills"])
	if str(u["ult"]) != "":
		sig_ids.append(str(u["ult"]))
	for mid in sig_ids:
		sig += "|" + str(BattleResolver.validate_choice(shown, _cur_slot_id(), _make_choice(str(mid))) == "")
	if sig == _orders_sig and _orders_box.get_child_count() > 0:
		return
	_orders_sig = sig
	for c in _orders_box.get_children():
		_orders_box.remove_child(c)
		c.queue_free()
	_order_buttons.clear()
	var touch: bool = TouchUi.active()
	var fan_r: float = 340.0 if touch else 290.0
	var fan_big: float = 620.0                   # curva dolce: raggio grande, il pulsante centrale resta dove stava
	var fo: Vector2 = _fan_origin()
	var mid_rad: float = deg_to_rad(6.0 if touch else 22.0)
	_orders_box.origin = Vector2(fo.x + cos(mid_rad) * fan_r - fan_big, fo.y + sin(mid_rad) * fan_r)
	_orders_box.tint = BattleTheme.unit_color(str(u["color"]))
	var title_text: String = str(u["name"]).to_upper()
	if pending_swap != "":
		title_text = "CAMBIO » " + title_text
	var n_slots: int = _my_slots().size()
	if n_slots > 1:
		var ords: Array = ["1st", "2nd", "3rd", "4th", "5th", "6th"]
		title_text += "  " + str(ords[clampi(_my_slots().find(_cur_slot_id()), 0, ords.size() - 1)])
	var title := BattleTheme.make_label(title_text, 14, BattleTheme.WH, true)
	title.set_meta("keep_case", true)       # "KIRA 1st": l'ordinale resta minuscolo
	_orders_box.add_child(title)
	var entries: Array = []
	for s in u["skills"]:
		entries.append({"id": str(s), "kind": "primary" if str(s) == "attack" else "normal"})
	if str(u["ult"]) != "":
		entries.append({"id": str(u["ult"]), "kind": "ultimate"})
	var bh: float = 56.0 if touch else 42.0
	# una sola misura di carattere per TUTTI i personaggi: la larghezza si adatta alla mossa piu' lunga del gioco, non il carattere
	var common_fs: int = 17 if touch else 15
	var longest: float = 0.0
	for mid in BattleContent.MOVES:
		longest = maxf(longest, BattleTheme.hud().get_string_size(_order_text(str(mid), BattleContent.MOVES[mid], 100), HORIZONTAL_ALIGNMENT_LEFT, -1, common_fs).x)
	var bw: float = clampf(longest + 44.0, 212.0, 262.0)
	var pts: Array = _orders_box.layout(entries.size(), bh, 4.0, fan_big, 0.0, 214.0 if touch else 236.0, 578.0)
	title.position = Vector2(float(pts[0].x) - 2.0, float(pts[0].y) - bh * 0.5 - 26.0)
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for pt in pts:
		lo = Vector2(minf(lo.x, float(pt.x) - 8.0), minf(lo.y, float(pt.y) - bh * 0.5))
		hi = Vector2(maxf(hi.x, float(pt.x) - 8.0 + bw + 28.0), maxf(hi.y, float(pt.y) + bh * 0.5))
	_fan_anchor.position = lo
	_fan_anchor.size = hi - lo
	var animate: bool = _fan_key != "%s|%d" % [uid, int(shown["round"])]
	_fan_key = "%s|%d" % [uid, int(shown["round"])]
	var min_left: float = 1e9
	for pt in pts:
		min_left = minf(min_left, float(pt.x) - 8.0)
	var n: int = 1
	for e in entries:
		var move_id: String = str(e["id"])
		var move: Dictionary = BattleContent.MOVES[move_id]
		var choice: Dictionary = _make_choice(move_id)
		var err: String = BattleResolver.validate_choice(shown, _cur_slot_id(), choice)
		var b := Button.new()
		b.text = _order_text(move_id, move, int(u["gauge"]))
		var order_unit_id: String = uid
		var order_err: String = err
		HintCard.bind(b, func() -> Dictionary: return Hints.move_card(BattleState.unit(shown, order_unit_id), move_id, order_err), self, true)
		var primary: bool = str(e["id"]) == "attack"
		var is_guard: bool = str(e["id"]) == "guard"
		var w: float = bw
		b.custom_minimum_size = Vector2(w, bh)
		b.size = Vector2(w, bh)
		# il testo non si taglia mai: si sceglie il carattere piu' grande che ci sta nel pulsante
		var fsize: int = common_fs
		BattleTheme.style_button(b, "normal", fsize)
		b.add_theme_font_override("font", BattleTheme.hud())
		b.add_theme_font_size_override("font_size", fsize)
		b.disabled = err != "" or locked or animating or autoplay
		var gprog: float = float(u["gauge"]) / float(BattleTypes.GAUGE_MAX) if str(e["kind"]) == "ultimate" else 0.0
		_style_order(b, err == "", gprog)
		# l'icona sta fuori dal pulsante, a sinistra e sulla stessa linea: il nome della mossa ha tutto lo spazio
		var oic: GameIcon = GameIcon.new().setup(GameIcon.move_key(move_id), BattleTheme.WH if err == "" else Color("#6b777c"), 32.0)
		oic.anchor_top = 0.5
		oic.anchor_bottom = 0.5
		var btn_left: float = float(pts[n - 1].x) - 8.0
		oic.offset_left = (min_left - 40.0) - btn_left        # tutte le icone sulla stessa colonna
		oic.offset_right = oic.offset_left + 32.0
		oic.offset_top = -16.0
		oic.offset_bottom = 16.0
		oic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(oic)
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.pressed.connect(_on_order_pressed.bind(move_id))
		b.focus_mode = Control.FOCUS_NONE
		var target: Vector2 = Vector2(float(pts[n - 1].x) - 8.0, float(pts[n - 1].y) - bh * 0.5)
		_orders_box.add_child(b)
		if animate and DisplayServer.get_name() != "headless":
			b.position = _orders_box.origin - Vector2(0.0, bh * 0.5)
			b.modulate.a = 0.0
			var tw: Tween = b.create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(b, "position", target, 0.22).set_delay(0.025 * float(n - 1))
			tw.tween_property(b, "modulate:a", 1.0, 0.14).set_delay(0.025 * float(n - 1))
		else:
			b.position = target
		_order_buttons.append(b)
		n += 1


# Testo di una mossa nel ventaglio: MAIUSCOLO, senza numero; il costo davanti (2E), la carica dell'ultimate dietro.
func _order_text(move_id: String, move: Dictionary, gauge: int) -> String:
	var name: String = BattleText.move_name(move_id)
	if str(move["kind"]) == "skill":
		return "%dE  %s" % [int(move["cost"]), name]
	if str(move["kind"]) == "ult":
		return "%s  %d%%" % [name, gauge]
	return name


# Mossa usabile = bianca con testo nero; non usabile = nera con testo grigio. L'ultimate si riempie di bianco man mano che si carica.
func _style_order(b: Button, usable: bool, gauge_progress: float) -> void:
	var box: SlantBox
	var txt_col: Color
	var outline: int = 0
	if usable:
		box = SlantBox.make(Color("#f4fbff"), Color("#10181c"), 14.0, Color(0, 0, 0, 0.55), 2.0)
		txt_col = BattleTheme.BK
	else:
		box = SlantBox.make(Color("#06090b"), Color("#2c373c"), 14.0, Color(0, 0, 0, 0.0), 2.0)
		txt_col = Color("#8b969b")
		if gauge_progress > 0.0:
			box.progress = gauge_progress
			box.progress_color = Color("#dfe9ec")
			txt_col = BattleTheme.WH
			outline = 4
	var hov: SlantBox = box
	if usable:
		hov = SlantBox.make(Color("#c4f4ff"), Color("#10181c"), 14.0, Color(0, 0, 0, 0.55), 2.0)
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("disabled", box)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(k, txt_col)
	b.add_theme_color_override("font_outline_color", BattleTheme.BK)
	b.add_theme_constant_override("outline_size", outline)


# Un pulsante tenuto premuto ha aperto la sua scheda: quel rilascio non e' un comando.
func _held_hint_order() -> bool:
	for b in _order_buttons:
		if is_instance_valid(b) and HintCard.consume_hold(b):
			return true
	return false


func _make_choice(move_id: String) -> Dictionary:
	var choice: Dictionary = {"swap": pending_swap, "move": move_id, "target": "", "order": _order_pick, "push": _push_pick if BattleContent.MOVES[move_id].has("mult") else ""}
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
	if animating or locked or autoplay or source == null:
		return
	if not _order_buttons.is_empty() and _held_hint_order():
		return
	var choice: Dictionary = _make_choice(move_id)
	var slot: String = _cur_slot_id()
	if BattleResolver.validate_choice(shown, slot, choice) != "":
		return
	_coach_note("pick", move_id)
	var slots: Array = _my_slots()
	if slots.size() <= 1 or not source.has_method("submit_party"):
		locked = true
		_refresh_orders()
		if not source.submit_choice(choice):
			locked = false
			_refresh_orders()
		return
	# piu' front: si raccolgono gli ordini di tutti, poi parte il round
	_picks[slot] = choice
	var nxt: String = ""
	for sid in slots:
		if not _picks.has(sid):
			nxt = sid
			break
	if nxt != "":
		_cur_slot = nxt
		_ops_sig = ""
		_refresh_operators()
		_refresh_orders()
		return
	locked = true
	_refresh_orders()
	_refresh_operators()
	if not source.submit_party(_picks.duplicate(true)):
		locked = false
		_refresh_orders()


func _open_pause() -> void:
	_pause = PauseMenu.open(self, source is NetworkManager)
	_pause.speed_changed.connect(func() -> void: event_delay = Settings.event_delay())
	_pause.quit_requested.connect(func() -> void:
		if source is NetworkManager:
			_on_leave_room()
		else:
			SceneRouter.go("hub"))


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if _pause != null and is_instance_valid(_pause):
		return          # in pausa i comandi tacciono (la finestra gestisce i suoi tasti)
	if event.keycode == KEY_ESCAPE and not _ended_shown and source != null and _tutorial == null:
		_open_pause()
		return
	# A battaglia finita: INVIO = rigioca / torna alla lobby, ESC = esci.
	if _ended_shown:
		if not _boon_buttons.is_empty() and event.keycode >= KEY_1 and event.keycode <= KEY_3:
			var bi: int = int(event.keycode) - int(KEY_1)
			if bi < _boon_buttons.size():
				_boon_buttons[bi].pressed.emit()
			return
		if (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER) and not _boon_buttons.is_empty():
			_boon_buttons[0].pressed.emit()
			return
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if source is NetworkManager:
				_on_hub()
			else:
				_on_again()
		elif event.keycode == KEY_ESCAPE:
			SceneRouter.go("hub" if not (source is NetworkManager) else "lobby")
		return
	if event.keycode == KEY_A and _auto_button != null and _auto_button.visible:
		set_autoplay(not autoplay)
		return
	if event.keycode == KEY_TAB and _tutorial == null and not locked and not animating and not autoplay:
		var ss: Array = _my_slots()
		if ss.size() > 1:
			_cur_slot = str(ss[(ss.find(_cur_slot_id()) + 1) % ss.size()])
			_ops_sig = ""
			_refresh_operators()
			_refresh_orders()
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
	# un round con tantissimi eventi (6 giocatori) non deve durare minuti: al massimo ~14 s a velocita' normale
	var step: float = minf(event_delay, maxf(0.06, ROUND_BUDGET / float(maxi(1, events.size()))))
	for e in events:
		if not is_inside_tree():
			return
		var line: Dictionary = BattleText.describe(shown, e)
		if str(line["text"]) != "":
			_push_log(str(line["text"]), str(line["kind"]))
		_mark_event(e)
		if str(e.get("t", "")) == "damage" and str(e.get("dst", "")) == BattleState.BOSS_ID and int(e.get("amount", 0)) > 0:
			var who: String = str(e.get("src", ""))
			_dmg_by[who] = int(_dmg_by.get(who, 0)) + int(e["amount"])
			_best_hit = maxi(_best_hit, int(e["amount"]))
		var extra: float = _event_fx(e)
		BattleText.apply_to_display(shown, e)
		_stage.set_state(shown)
		_refresh_boss()
		_refresh_operators()
		await get_tree().create_timer(step + extra).timeout
	animating = false
	_link_clear()
	_stage.clear_markers()
	_turn_acting = ""
	if not is_inside_tree():
		return
	_coach_note("round")
	_sync()


# Segnalino su chi agisce e su chi subisce, e riga evidenziata nel pannello dell'ordine.
func _mark_event(e: Dictionary) -> void:
	var t: String = str(e.get("t", ""))
	if t == "act":
		_stage.acting = str(e["unit"])
		_stage.acting_target = ""
	elif t == "boss_move":
		_stage.acting = BattleState.BOSS_ID
		_stage.acting_target = ""
	elif e.has("src") and e.has("dst"):
		_stage.acting = str(e["src"])
		_stage.acting_target = str(e["dst"])
	_turn_acting = _stage.acting
	_refresh_turn_panel()


const ROUND_BUDGET: float = 14.0       # secondi massimi di animazione per round (a velocita' normale)
const HIT_WORDS: Array = ["BAM!", "POW!", "CRACK!", "WHAM!", "BOOM!"]
const BIG_HIT_FRACTION: float = 0.12     # un colpo cosi' grande (rispetto ai PV massimi) e' "pesante"


# Effetti grafici e sonori di un evento. Ritorna i secondi di pausa in piu' (hit-stop).
func _event_fx(e: Dictionary) -> float:
	_recap_track(e)
	match str(e.get("t", "")):
		"damage":
			return _fx_damage(e)
		"bleed":
			_float_text("-" + BattleText.num(int(e["amount"])), str(e["unit"]), BattleTheme.RD, 28)
		"counter":
			Snd.play("counter")
			_stage.impact(6.0, 0.02)
			_pop("RISPOSTA!", str(e["unit"]), Hints.faction_color("libracorp"), BattleTheme.BK, 34, 60.0, Vector2(0.0, -30.0))
		"ammo":
			return _fx_ammo(e)
		"trait":
			Snd.play("trait")
			if str(e.get("trait", "")) == "atipico":
				_float_text(str(e.get("name", "ATIPICO")).to_upper(), str(e["unit"]), BattleTheme.POP, 22)
			else:
				_float_text("▲ DIF  ▲ VEL", str(e["unit"]), Hints.faction_color("libracorp"), 20)
		"status":
			_fx_status(e)
		"heal":
			Snd.play("heal")
			_pop("+" + BattleText.num(int(e["amount"])) + ("!" if bool(e.get("crit", false)) else ""), str(e["dst"]), BattleTheme.OK, BattleTheme.BK, 32, 52.0)
			if AnimFx.enabled():
				AnimFx.rise(_fx, _stage.anchor_of(str(e["dst"])))
		"shield":
			_float_text("+" + BattleText.num(int(e["amount"])), str(e["dst"]), BattleTheme.CY, 26)
			if AnimFx.enabled():
				AnimFx.shield(_fx, _stage.anchor_of(str(e["dst"])), false)
		"marks":
			return _fx_marks(e)
		"arena":
			if str(e["id"]) == "contaminazione" and not bool(e["ok"]):
				Snd.play("player_hit", 0.8)
				_float_text("-" + BattleText.num(int(e["amount"])), str(e["unit"]), BattleTheme.OK, 26)
				_pop("CONTAMINATO!", str(e["unit"]), BattleTheme.OK, BattleTheme.BK, 30, 56.0, Vector2(0.0, -50.0))
			elif str(e["id"]) == "eco":
				if bool(e["ok"]):
					Snd.play("crit", 0.8)
					_float_text("-" + BattleText.num(int(e["amount"])), BattleState.BOSS_ID, BattleTheme.CY, 28)
					_pop("ECO!", BattleState.BOSS_ID, BattleTheme.CY, BattleTheme.BK, 34, 60.0, Vector2(0.0, -80.0))
			elif str(e["id"]) == "sigillo":
				_pop("SIGILLO ROTTO!" if bool(e["ok"]) else "SIGILLO INTATTO", BattleState.BOSS_ID, BattleTheme.POP if bool(e["ok"]) else BattleTheme.RD, BattleTheme.BK, 34, 60.0, Vector2(0.0, -80.0))
				if bool(e["ok"]):
					Snd.play("crit", 0.9)
		"order":
			Snd.play("click", 1.2)
			_pop(str(Tactics.ORDERS[str(e["id"])]["name"]), BattleState.BOSS_ID, BattleTheme.CY, BattleTheme.BK, 30, 52.0, Vector2(0.0, 40.0))
		"push":
			Snd.play("player_hit", 0.7)
			_pop("PREZZO!" if str(e["id"]) == "prezzo" else "TECNICA PROIBITA!", str(e["unit"]), BattleTheme.RD, BattleTheme.WH, 32, 58.0, Vector2(0.0, -60.0))
		"plate":
			if bool(e["broke"]):
				Snd.play("crit", 1.0)
				_stage.impact(10.0, 0.04)
				_pop("PLACCA ROTTA!", BattleState.BOSS_ID, BattleTheme.POP, BattleTheme.BK, 36, 62.0, Vector2(0.0, -100.0))
		"chain":
			Snd.play("boss_charge" if bool(e["ok"]) else "dodge", 1.0)
			_pop("CATENA!" if bool(e["ok"]) else "CATENA SPEZZATA!", BattleState.BOSS_ID, BattleTheme.RD if bool(e["ok"]) else BattleTheme.OK, BattleTheme.WH, 34, 60.0, Vector2(0.0, -90.0))
		"resolve":
			Snd.play("heal", 1.2)
			_pop("DETERMINAZIONE!", str(e["unit"]), BattleTheme.OK, BattleTheme.BK, 30, 56.0, Vector2(0.0, -60.0))
		"behavior":
			Snd.play("boss_charge", 1.2)
			_pop(str(Arena.BEHAVIORS.get(str(e["id"]), {}).get("name", "")), BattleState.BOSS_ID, BattleTheme.RD, BattleTheme.WH, 26, 50.0, Vector2(0.0, -110.0))
		"rescue":
			Snd.play("heal")
			_pop("SOCCORSO!", str(e["who"]), BattleTheme.OK, BattleTheme.BK, 36, 62.0, Vector2(0.0, -50.0))
			_float_text("+" + BattleText.num(int(e["hp"])), str(e["who"]), BattleTheme.OK, 28)
		"react":
			var rk: String = str(e["kind"])
			Snd.play("counter" if rk != "dodge" else "dodge", 1.1)
			_stage.impact(8.0, 0.03)
			_pop("INTERROTTA!" if rk == "interrupt" else ("INTERCETTATA!" if rk == "intercept" else "SCHIVATA!"), str(e["unit"]), BattleTheme.OK, BattleTheme.BK, 36, 62.0, Vector2(0.0, -50.0))
		"reserve":
			if int(e["delta"]) > 0 and str(e["why"]) == "combo":
				_float_text("RISERVA +%d" % int(e["delta"]), BattleState.BOSS_ID, BattleTheme.CY, 20)
		"dodge":
			Snd.play("dodge")
			_pop("SCHIVA!", str(e["unit"]), BattleTheme.OK, BattleTheme.BK, 32, 54.0, Vector2(0.0, -30.0))
		"debuff":
			Snd.play("down", 1.4)
			var stat_lab: String = str(BattleContent.STAT_NAMES.get(str(e["stat"]), str(e["stat"]).to_upper()))
			_float_text("▼ %s" % stat_lab, str(e["unit"]), BattleTheme.RD, 24)
			ComicFx.speed_lines(_fx, _stage.anchor_of(str(e["unit"])), Color(BattleTheme.RD, 0.8), 0.2)
		"buff":
			Snd.play("trait")
			for p in shown["players"]:
				var au: Dictionary = BattleState.active_unit(shown, str(p["id"]))
				if BattleState.is_alive(au):
					_float_text("▲ ATK  ▲ VEL", str(au["id"]), BattleTheme.OK, 20)
			ComicFx.flash(_fx, Color(BattleTheme.OK, 0.25), 0.18)
		"summon":
			Snd.play("deploy")
			_stage.summon_pulse = 1.0
			_pop("TORRETTA!" if str(e["kind"]) == "turret" else "DRONE!", str(e["unit"]), BattleTheme.POP, BattleTheme.BK, 30, 56.0, Vector2(90.0, -30.0))
		"summon_shot":
			Snd.play("shot", 1.3)
			var src: Vector2 = _stage.anchor_of(str(e["unit"])) + Vector2(90.0, 20.0)
			var dstp: Vector2 = _stage.anchor_of(BattleState.BOSS_ID)
			ComicFx.speed_lines(_fx, dstp, Color(BattleTheme.POP if str(e["kind"]) == "turret" else BattleTheme.CY, 0.9), 0.16)
			_zap(src, dstp, BattleTheme.POP if str(e["kind"]) == "turret" else BattleTheme.CY)
		"summon_end":
			if str(e["kind"]) == "turret" and str(e["reason"]) == "ammo":
				Snd.play("crit", 0.7)
				_stage.impact(18.0, 0.05)
				ComicFx.flash(_fx, Color(1.0, 0.8, 0.3, 0.7), 0.25)
				_pop("BOOM!", BattleState.BOSS_ID, BattleTheme.POP, BattleTheme.RD, 64, 100.0, Vector2(0.0, -20.0))
				return 0.2
			if str(e["kind"]) == "drone" and str(e["reason"]) == "ammo":
				Snd.play("heal")
				ComicFx.flash(_fx, Color(BattleTheme.CY, 0.3), 0.2)
				_pop("SCUDI!", str(e["unit"]), BattleTheme.CY, BattleTheme.BK, 40, 70.0, Vector2(60.0, -20.0))
		"ronda":
			if int(e["on"]) == 1:
				Snd.play("ronda")
				_float_text("RONDA ▲", str(e["unit"]), Color("#f2fdff"), 22)
			else:
				Snd.play("crit", 1.2)
				var rat: Vector2 = _stage.anchor_of(str(e["unit"]))
				ComicFx.speed_lines(_fx, rat, Color("#f2fdff"), 0.3)
				UltFx.play(_fx, rat, Color("#f2fdff"), "strike", _stage.anchor_of(BattleState.BOSS_ID))
				_pop("RONDA!", str(e["unit"]), Color("#f2fdff"), BattleTheme.BK, 40, 70.0, Vector2(0.0, -50.0))
		"boss_move":
			Snd.play("boss_charge")
			_announce(BattleContent.BOSSES.get(str(BattleState.boss(shown)["char"]), {}).get("name", "BOSS"), BattleText.move_name(str(e.get("move", ""))), true)
		"act":
			return _fx_act(e)
		"phase":
			return _fx_phase(int(e.get("phase", 2)))
		"tenacity":
			Snd.play("crit", 0.6)
			_buzz(160)
			var tu: String = str(e["unit"])
			_stage.impact(18.0, 0.06)
			ComicFx.flash(_fx, Color(1.0, 0.85, 0.3, 0.55), 0.3)
			_pop("ULTIMA VOLONTA'!", tu, BattleTheme.POP, BattleTheme.BK, 58, 100.0, Vector2(0.0, -40.0))
			_float_text("1 PV · ULTIMATE PRONTA", tu, BattleTheme.POP, 20)
			if AnimFx.enabled():
				AnimFx.shockwave(_fx, _stage.anchor_of(tu), BattleTheme.POP, 160.0)
			_slow_motion(0.35, 0.35)
			return 0.3
		"balance":
			pass
		"break":
			Snd.play("crit", 0.5)
			_buzz(220)
			_stage.impact(24.0, 0.08)
			ComicFx.flash(_fx, Color(0.7, 0.95, 1.0, 0.6), 0.3)
			ComicFx.speed_lines(_fx, _stage.anchor_of(BattleState.BOSS_ID), Color(0.7, 0.95, 1.0, 0.95), 0.4)
			_pop("ROTTURA!", BattleState.BOSS_ID, BattleTheme.CY, BattleTheme.BK, 72, 125.0, Vector2(0.0, -30.0))
			ComicFx.caption(_fx, "BOSS STORDITO · SALTA LA MOSSA · +%d%% DANNO" % int(round((BattleTypes.BREAK_DAMAGE - 1.0) * 100.0)), Vector2(300.0, 300.0), BattleTheme.CY, 1.3)
			_slow_motion(0.3, 0.4)
			return 0.4
		"boss_stunned":
			Snd.play("down", 0.8)
			_stage.impact(10.0, 0.03)
			_pop("INTERROTTO!", BattleState.BOSS_ID, BattleTheme.CY, BattleTheme.BK, 56, 100.0, Vector2(0.0, -20.0))
			_announce(BattleContent.BOSSES.get(str(BattleState.boss(shown)["char"]), {}).get("name", "BOSS"), "STORDITO · " + BattleText.move_name(str(e.get("move", ""))) + " ANNULLATA", false)
			return 0.2
		"recover":
			_float_text("IL BOSS SI RIPRENDE", BattleState.BOSS_ID, BattleTheme.WH, 20)
		"synergy":
			return _fx_combo(e)
		"rhythm":
			Snd.play("trait", 1.3)
			_float_text("RITMO +%d%%" % int(round((BattleTypes.RHYTHM_BONUS - 1.0) * 100.0)), str(e["unit"]), BattleTheme.CY, 18)
		"swap":
			Snd.play("swap")
			_switch_fx(str(e.get("from", "")), str(e.get("to", "")))
		"link":
			return _fx_link(e)
		"link_break":
			_link_clear()
		"down":
			Snd.play("down")
			if str(e["unit"]) == BattleState.BOSS_ID:
				# colpo di grazia: lampo, linee e scritta gigante
				_buzz(220)
				_stage.impact(26.0, 0.08)
				ComicFx.speed_lines(_fx, _stage.anchor_of(BattleState.BOSS_ID), Color.WHITE, 0.5)
				ComicFx.flash(_fx, Color(1, 1, 1, 0.85), 0.35)
				_pop("FINISH!", BattleState.BOSS_ID, BattleTheme.POP, BattleTheme.RD, 84, 120.0, Vector2(0.0, -20.0))
				_slow_motion(0.25, 0.5)
				if AnimFx.enabled():
					AnimFx.shards(_fx, _stage.anchor_of(BattleState.BOSS_ID), Color("#ffd166"))
					ComicFx.flash(_fx, Color(1.0, 0.85, 0.3, 0.5), 0.5)
				return 0.35
			_buzz(110)
			_stage.impact(14.0, 0.04)
			ComicFx.flash(_fx, Color(1, 1, 1, 0.5), 0.15)
			_pop("K.O.!", str(e["unit"]), BattleTheme.RD, BattleTheme.WH, 56, 95.0)
			banter(_local_active_id(), "ko")
			return 0.12
	return 0.0


# Combo: preset visivo e peso (tier) vengono dalla regola; stessi effetti riutilizzati, intensita' diversa.
func _fx_combo(e: Dictionary) -> float:
	var tier: int = int(e.get("tier", 0))
	var td: Dictionary = ComboFx.tier_def(tier)
	var col: Color = Color(str(e.get("col", "#ffd25f")))
	var actor: String = str(e["unit"])
	var partner: String = str(e.get("with", actor))
	Snd.play("trait", 1.4 + 0.15 * float(tier))
	ComboFx.play(_fx, str(e.get("fx", "")), col, _stage.anchor_of(partner), _stage.anchor_of(actor), _stage.anchor_of(BattleState.BOSS_ID), tier)
	_pop(str(e["name"]) + "!", actor, col, BattleTheme.BK, 40 + 6 * tier, 76.0, Vector2(0.0, -50.0))
	_float_text("con %s" % str(BattleState.unit(shown, partner).get("name", "")).to_upper(), actor, col, 18)
	_stage.impact(float(td["shake"]), 0.02)
	if float(td["flash"]) > 0.0:
		ComicFx.flash(_fx, Color(col, float(td["flash"])), 0.2)
	if bool(td["lines"]):
		ComicFx.speed_lines(_fx, _stage.anchor_of(BattleState.BOSS_ID), Color(col, 0.9), 0.3)
	if bool(td["caption"]):
		ComicFx.caption(_fx, "COMBO x%d" % (tier + 1), Vector2(430.0, 120.0), col, 0.9)
	if float(td["slow"]) > 0.0:
		_slow_motion(float(td["slow"]), 0.35)
	return 0.05 + 0.08 * float(tier)


# Cambio di fase del boss: annuncio grande, lampo e un attimo di pausa per far capire che le regole sono cambiate.
func _fx_phase(phase: int) -> float:
	Snd.play("boss_charge", 0.7)
	_buzz(200)
	_stage.impact(22.0, 0.07)
	var col: Color = BattleTheme.RD if phase >= 3 else BattleTheme.POP
	ComicFx.flash(_fx, Color(col, 0.6), 0.35)
	ComicFx.speed_lines(_fx, _stage.anchor_of(BattleState.BOSS_ID), Color(col, 0.9), 0.45)
	var title: String = "ULTIMO RESPIRO!" if phase >= 3 else "FASE 2!"
	_pop(title, BattleState.BOSS_ID, col, BattleTheme.BK, 72, 130.0, Vector2(0.0, -30.0))
	ComicFx.caption(_fx, "IL BOSS CAMBIA SCHEMA · SCUDO · -1 ENERGIA · +%d ULTIMATE" % BattleTypes.PHASE_GAUGE, Vector2(260.0, 300.0), col, 1.4)
	banter(_local_active_id(), "enrage", true)
	_slow_motion(0.3, 0.45)
	return 0.5


# Rallenta il tempo per un attimo (colpo finale, momenti decisivi) e lo riporta alla normalita'.
func _slow_motion(scale: float, seconds: float) -> void:
	if not AnimFx.enabled() or DisplayServer.get_name() == "headless":
		return
	Engine.time_scale = scale
	var t: SceneTreeTimer = get_tree().create_timer(seconds * scale, true, false, true)
	t.timeout.connect(func() -> void: Engine.time_scale = 1.0)


# ---------- Resoconto di fine battaglia (perche' ho vinto o perso) ----------

var _recap: Dictionary = {"worst": 0, "worst_move": "", "worst_unit": "", "first_down": "", "breaks": 0, "synergies": 0, "last_move": "", "wills": 0, "unhandled": 0, "missed": 0, "reacts": 0, "spent": 0, "wasted": 0, "decisive": ""}


# REPLAY TATTICO: i momenti che contano, in ordine, con il turno in cui sono successi.
var _timeline: Array = []
var _combos_seen: Dictionary = {}


func _mark_moment(text: String) -> void:
	_timeline.append("T%02d  %s" % [int(shown.get("round", 0)), text])


func _recap_track(e: Dictionary) -> void:
	match str(e.get("t", "")):
		"synergy", "react", "rescue", "break", "phase", "tenacity", "arena", "behavior", "order", "push", "plate", "chain", "resolve":
			if str(e["t"]) == "plate" and not bool(e["broke"]):
				return
			var line: Dictionary = BattleText.describe(shown, e)
			if str(line.get("text", "")) != "":
				_mark_moment(str(line["text"]))
			if str(e["t"]) == "synergy":
				_combos_seen[str(e["id"])] = true
		"threat":
			if not bool(e["handled"]):
				_mark_moment("CARICA NON GESTITA: %s (-%d PV)" % [BattleText.move_name(str(e["move"])).to_upper(), int(e["lost"])])
		"down":
			_mark_moment("%s CADE" % str(BattleState.unit(shown, str(e["unit"])).get("name", "")).to_upper())
	match str(e.get("t", "")):
		"boss_move":
			_recap["last_move"] = str(e.get("move", ""))
		"damage":
			if str(e.get("src", "")) == BattleState.BOSS_ID and int(e.get("amount", 0)) > int(_recap["worst"]):
				_recap["worst"] = int(e["amount"])
				_recap["worst_move"] = str(_recap["last_move"])
				_recap["worst_unit"] = str(BattleState.unit(shown, str(e.get("dst", ""))).get("name", ""))
		"down":
			if str(e.get("unit", "")) != BattleState.BOSS_ID and str(_recap["first_down"]) == "":
				_recap["first_down"] = str(BattleState.unit(shown, str(e["unit"])).get("name", ""))
		"break":
			_recap["breaks"] = int(_recap["breaks"]) + 1
			if not _recap.has("break_round"):
				_recap["break_round"] = int(shown.get("round", 0))
		"synergy":
			_recap["synergies"] = int(_recap["synergies"]) + 1
			_recap["last_syn"] = str(e.get("name", ""))
		"react":
			_recap["reacts"] = int(_recap["reacts"]) + 1
		"reserve":
			if str(e.get("why", "")) == "react":
				_recap["spent"] = int(_recap["spent"]) - int(e["delta"])
			_recap["wasted"] = int(_recap["wasted"]) + int(e.get("wasted", 0))
		"threat":
			if not bool(e["handled"]):
				_recap["unhandled"] = int(_recap["unhandled"]) + 1
				if bool(e["could"]):
					_recap["missed"] = int(_recap["missed"]) + 1
		"tenacity":
			_recap["wills"] = int(_recap["wills"]) + 1
			_recap["will_unit"] = str(BattleState.unit(shown, str(e["unit"])).get("name", ""))


func _recap_text(victory: bool) -> String:
	var parts: Array = []
	if int(_recap["worst"]) > 0:
		parts.append("Colpo piu' duro subito: %s su %s (%s)" % [BattleText.move_name(str(_recap["worst_move"])), str(_recap["worst_unit"]).to_upper(), BattleText.num(int(_recap["worst"]))])
	if str(_recap["first_down"]) != "":
		parts.append("Primo a cadere: %s" % str(_recap["first_down"]).to_upper())
	parts.append("Fase raggiunta: %d" % int(shown.get("phase", 1)))
	parts.append("Rotture: %d  ·  Sinergie: %d" % [int(_recap["breaks"]), int(_recap["synergies"])])
	if int(_recap["unhandled"]) > 0:
		parts.append("Cariche non gestite: %d%s" % [int(_recap["unhandled"]), (" (%d con Riserva disponibile)" % int(_recap["missed"])) if int(_recap["missed"]) > 0 else ""])
	parts.append("Reazioni: %d  ·  Riserva spesa: %d  ·  sprecata: %d" % [int(_recap["reacts"]), int(_recap["spent"]), int(_recap["wasted"])])
	if _recap.has("break_round"):
		parts.append("Momento chiave: rottura al turno %d" % int(_recap["break_round"]))
	if _recap.has("will_unit"):
		parts.append("Salvataggio all'ultimo: %s resiste con 1 PV" % str(_recap["will_unit"]).to_upper())
	var stats: Dictionary = shown.get("stats", {})
	var tt: Array = Discoveries.titles(stats, victory)
	if not tt.is_empty():
		parts.append("Titoli: %s" % "  ·  ".join(PackedStringArray(tt)))
	if Discoveries.style_of(stats) != "":
		parts.append("Stile della squadra: %s" % Discoveries.style_of(stats))
	# momenti e cause: perche' e' andata cosi'
	var moments: Array = []
	if victory and _recap.has("will_unit"):
		moments.append("ULTIMO ISTANTE")
	if victory and int(stats.get("downs", 0)) == 0:
		moments.append("VITTORIA PULITA")
	if victory and int(stats.get("downs", 0)) >= 2:
		moments.append("VITTORIA DISPERATA")
	if int(stats.get("chains_broken", 0)) > 0:
		moments.append("CATENA SPEZZATA x%d" % int(stats["chains_broken"]))
	if not moments.is_empty():
		parts.append("Momenti: %s" % "  ·  ".join(PackedStringArray(moments)))
	var why: Array = []
	if int(stats.get("plates", 0)) > 0:
		why.append("%d placche rotte" % int(stats["plates"]))
	if int(stats.get("pushes", 0)) > 0:
		why.append("%d prezzi pagati (%d proibiti)" % [int(stats["pushes"]), int(stats.get("forbidden", 0))])
	if int(stats.get("orders", 0)) > 0:
		why.append("%d ordini di squadra" % int(stats["orders"]))
	if not why.is_empty():
		parts.append("Cause: %s" % ", ".join(PackedStringArray(why)))
	if Tactics.challenge_id(shown) != "":
		parts.append("Sfida: %s  %s" % [Tactics.challenge_text(shown), ("RIUSCITA +%d CREDITI" % Tactics.CHALLENGE_COINS) if Tactics.challenge_done(shown) else ("non riuscita" if victory else "")])
	if shown.has("learned"):
		parts.append("Il boss aveva imparato: %s" % str(shown["learned"]["name"]).to_lower())
	if shown.has("comeback"):
		parts.append("Rientro: avevi un aiuto dopo %d sconfitte di fila" % Extras.COMEBACK_AFTER)
	var tip: String = ""
	var untried: Array = []
	for r in Combos.RULES:
		if not _combos_seen.has(str(r["id"])):
			untried.append(str(r["name"]))
	if not untried.is_empty():
		parts.append("Combo mai provate: %s" % ", ".join(PackedStringArray(untried)))
	if str(_recap.get("last_syn", "")) != "" and (_recap.has("break_round") or victory):
		parts.append("Combo decisiva: %s" % str(_recap["last_syn"]))
	if not victory:
		if int(_recap["missed"]) > 0:
			tip = "Consiglio: quando il boss prepara una CARICA usa una reazione (Schivata, Intercettazione o Interruzione): avevi Riserva e non l'hai usata."
		elif int(_recap["breaks"]) == 0:
			tip = "Consiglio: marca il boss e colpisci col colore vantaggioso per rompere l'equilibrio e fargli saltare la mossa."
		elif str(_recap["first_down"]) != "":
			tip = "Consiglio: proteggi %s, o scambialo prima della mossa che lo colpisce (leggi l'allarme)." % str(_recap["first_down"]).to_upper()
	return "\n".join(parts) + ("\n" + tip if tip != "" else "")


# Finestra con i momenti chiave dello scontro, uno per riga.
func _open_replay() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.add_child(dim)
	var panel := HudPanel.new().setup("REPLAY TATTICO", BattleTheme.CY)
	panel.position = Vector2(250, 70)
	panel.size = Vector2(780, 580)
	dim.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.set_content(col)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var lines := VBoxContainer.new()
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(lines)
	if _timeline.is_empty():
		lines.add_child(BattleTheme.make_label("Nessun momento da ricordare: prova combo, reazioni e rotture.", 17, BattleTheme.CY_DIM))
	for t in _timeline:
		var l := BattleTheme.make_label(str(t), 16, BattleTheme.WH)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lines.add_child(l)
	var close := Button.new()
	close.text = "CHIUDI"
	close.custom_minimum_size = Vector2(0, 48)
	BattleTheme.style_button(close, "primary", 20)
	close.pressed.connect(dim.queue_free)
	col.add_child(close)


# Vibrazione breve sul telefono nei momenti forti (solo touch).
func _buzz(ms: int) -> void:
	Settings.buzz(ms)


# MARCHI: il mirino compare (o esplode, se consumato) sul boss.
func _fx_marks(e: Dictionary) -> float:
	var uid: String = str(e["unit"])
	_stage.mark_pulse = 1.0
	if int(e["added"]) > 0:
		Snd.play("mark", 1.0 + 0.04 * float(int(e["n"])))
		_pop("MARCHIO x%d" % int(e["n"]), uid, BattleTheme.POP, BattleTheme.BK, 34, 60.0, Vector2(0.0, -60.0))
		return 0.0
	Snd.play("mark_burst")
	_buzz(60)
	_stage.impact(12.0, 0.04)
	ComicFx.flash(_fx, Color(BattleTheme.POP, 0.4), 0.15)
	_pop("MARCHI SPESI!", uid, BattleTheme.RD, BattleTheme.WH, 40, 76.0, Vector2(0.0, -60.0))
	return 0.1


# Scarica elettrica a zig-zag tra due punti (torretta, drone).
func _zap(a: Vector2, b: Vector2, col: Color) -> void:
	LightningFx.play(_fx, a, b, col, 0.3, 0.9)


# LINK: striscione al centro con il numero della catena; CROSS in ciano, UNISONO in giallo.
var _link_node: Label

func _fx_link(e: Dictionary) -> float:
	var n: int = int(e["n"])
	var unison: bool = str(e["kind"]) == "unison"
	var col: Color = BattleTheme.POP if unison else BattleTheme.CY
	Snd.play("crit", 1.0 + 0.12 * float(n))
	_link_clear()
	_stage.link_from = str(e["with"])
	_stage.link_to = str(e["unit"])
	_stage.link_n = n
	_stage.link_col = col
	var l := BattleTheme.make_label("LINK x%d" % n, 54 + n * 6, col, true)
	l.add_theme_color_override("font_outline_color", BattleTheme.BK)
	l.add_theme_constant_override("outline_size", 14)
	l.position = Vector2(470.0, 120.0)
	l.rotation = deg_to_rad(-6.0)
	l.pivot_offset = Vector2(120.0, 40.0)
	l.scale = Vector2(1.7, 1.7)
	_fx.add_child(l)
	_link_node = l
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ComicFx.speed_lines(_fx, _stage.anchor_of(str(e["unit"])), col, 0.28)
	_pop("UNISONO!" if unison else "CROSS! ULT +%d" % BattleTypes.LINK_GAUGE, str(e["unit"]), col, BattleTheme.BK, 28, 56.0, Vector2(0.0, -40.0))
	_stage.impact(5.0 + 2.0 * float(n), 0.0)
	return 0.1


func _link_clear() -> void:
	_stage.link_n = 0
	if _link_node != null and is_instance_valid(_link_node):
		var l: Label = _link_node
		var tw := create_tween()
		tw.tween_property(l, "modulate:a", 0.0, 0.25)
		tw.tween_callback(l.queue_free)
	_link_node = null


# Effetto grafico del colpo, scelto per tipo: taglio, onda d'urto, scintille o proiettile (LibraCorp).
func _hit_anim(e: Dictionary, dst: String, to_boss: bool, is_crit: bool, heavy: bool) -> void:
	if not AnimFx.enabled():
		return
	var at: Vector2 = _stage.anchor_of(dst)
	var src: Dictionary = BattleState.unit(shown, str(e.get("src", "")))
	var fac: String = str(src.get("faction", ""))
	var col: Color = Hints.faction_color(fac) if fac != "" else Color.WHITE
	var power: float = 1.6 if is_crit else (1.25 if heavy else 1.0)
	if fac == "libracorp" and not src.is_empty() and str(src.get("id", "")) != dst:
		AnimFx.projectile(_fx, _stage.anchor_of(str(src["id"])) + Vector2(60.0, 0.0), at, col, func() -> void: AnimFx.sparks(_fx, at, col, 8, 200.0))
	elif heavy or is_crit:
		AnimFx.shockwave(_fx, at, col, 150.0 if to_boss else 110.0)
		AnimFx.sparks(_fx, at, col, 16, 300.0)
	elif randi() % 2 == 0:
		AnimFx.slash(_fx, at, col, power)
	else:
		AnimFx.sparks(_fx, at, col, 8, 220.0)


func _fx_damage(e: Dictionary) -> float:
	var dst: String = str(e["dst"])
	var amount: int = int(e["amount"])
	var to_boss: bool = dst == BattleState.BOSS_ID
	Snd.play("guard" if amount <= 0 else ("hit" if to_boss else "player_hit"), randf_range(0.94, 1.06))
	_stage.flash(dst)
	if amount <= 0:
		_pop("GUARD!", dst, BattleTheme.CY, BattleTheme.BK, 34, 62.0)
		if AnimFx.enabled():
			AnimFx.shield(_fx, _stage.anchor_of(dst), true)
		return 0.0
	var target: Dictionary = BattleState.unit(shown, dst)
	if bool(e.get("crit", false)) and amount > 0:
		Snd.play("crit")
		_buzz(30)
		_stage.impact(10.0, 0.03)
	var is_crit: bool = bool(e.get("crit", false))
	if to_boss:
		if is_crit:
			banter(str(e["src"]), "crit")
		if not _banter_enraged and float(int(target["hp"]) - amount) / float(maxi(1, int(target["max_hp"]))) < BattleTypes.ENRAGE_BELOW:
			_banter_enraged = true
			banter(_local_active_id(), "enrage", true)
	elif int(target.get("hp", 0)) - amount > 0 and float(int(target["hp"]) - amount) / float(maxi(1, int(target["max_hp"]))) < 0.3 and not _banter_low.has(dst):
		_banter_low[dst] = true
		banter(dst, "low_hp")
	var heavy: bool = float(amount) >= float(target.get("max_hp", 1)) * BIG_HIT_FRACTION
	var fill: Color = BattleTheme.POP if to_boss else BattleTheme.RD
	_hit_anim(e, dst, to_boss, is_crit, heavy)
	# un solo fumetto per colpo: il critico e' semplicemente piu' grande, col punto esclamativo
	_pop("-%s%s" % [BattleText.num(amount), "!" if is_crit else ""], dst, fill, BattleTheme.BK, 52 if is_crit else (44 if heavy else 32), 84.0 if is_crit else (74.0 if heavy else 56.0))
	if heavy or is_crit:
		var at: Vector2 = _stage.anchor_of(dst)
		ComicFx.speed_lines(_fx, at, Color(1, 1, 1, 0.9) if to_boss else BattleTheme.RD, 0.22)
		_stage.impact(11.0 if to_boss else 8.0, 0.025)
		return 0.06
	_stage.impact(4.0, 0.0)
	return 0.0


# ---------- Battute ----------

var _banter_node: Control = null
var _banter_until_ms: int = 0
var _banter_low: Dictionary = {}
var _banter_enraged: bool = false


# Fumetto in basso a destra (lontano dal tasto autoplay): volto di chi parla e una riga. Non piu' di uno ogni ~6 secondi.
func banter(uid: String, kind: String, force: bool = false) -> void:
	var now: int = Time.get_ticks_msec()
	if not force and now < _banter_until_ms:
		return
	var u: Dictionary = BattleState.unit(shown, uid)
	if u.is_empty() or str(u["side"]) != "player" or not Settings.banter:
		return
	if _coach != null and is_instance_valid(_coach) and _coach.panel.visible:
		return      # la guida passo-passo ha la precedenza sullo stesso angolo
	var text: String = Banter.line(kind, str(u["color"]), int(shown.get("round", 0)) + uid.length())
	if text == "":
		return
	_banter_until_ms = now + 6000
	if _banter_node != null and is_instance_valid(_banter_node):
		_banter_node.queue_free()
	var plate := Control.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.anchor_left = 1.0
	plate.anchor_right = 1.0
	plate.anchor_top = 1.0
	plate.anchor_bottom = 1.0
	plate.offset_left = -346.0 + _edge_r
	plate.offset_right = -2.0 + _edge_r
	plate.offset_top = -136.0
	plate.offset_bottom = -40.0
	var bg := PanelContainer.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_right = -70.0
	bg.add_theme_stylebox_override("panel", SlantBox.make(BattleTheme.BK, BattleTheme.WH, 12.0, BattleTheme.unit_color(str(u["color"])), 3.0))
	var lab := BattleTheme.make_label(text, 20, BattleTheme.WH, true)
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.add_theme_color_override("font_outline_color", BattleTheme.BK)
	bg.add_child(lab)
	plate.add_child(bg)
	var face := PortraitView.new().setup(str(u["char"]), "bust")
	face.show_expression_text = false
	face.set_expression(Banter.expression_for(kind))
	face.size = Vector2(120.0, 120.0)
	face.position = Vector2(plate.offset_right - plate.offset_left - 128.0, -22.0)
	plate.add_child(face)
	_overlay_banter_host().add_child(plate)
	_banter_node = plate
	plate.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(plate, "modulate:a", 1.0, 0.15)
	tw.tween_interval(3.4)
	tw.tween_property(plate, "modulate:a", 0.0, 0.4)
	tw.tween_callback(plate.queue_free)


# Abilita' (non ultimate, non attacco/guardia): ritratto di chi la usa con il nome della mossa, a destra, in un attimo.
func _skill_plate(u: Dictionary, move_id: String) -> void:
	if _skill_node != null and is_instance_valid(_skill_node):
		_skill_node.queue_free()
	var col: Color = BattleTheme.unit_color(str(u["color"]))
	var plate := Control.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.anchor_left = 1.0
	plate.anchor_right = 1.0
	plate.anchor_top = 0.5
	plate.anchor_bottom = 0.5
	plate.offset_left = -430.0 + _edge_r
	plate.offset_right = -2.0 + _edge_r
	plate.offset_top = -170.0
	plate.offset_bottom = -30.0
	var bg := PanelContainer.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.anchor_top = 0.5
	bg.anchor_bottom = 0.5
	bg.anchor_right = 1.0
	bg.offset_top = -4.0
	bg.offset_bottom = 46.0
	bg.offset_right = -120.0
	bg.add_theme_stylebox_override("panel", SlantBox.make(Color(BattleTheme.BK, 0.88), col, 12.0, col, 3.0))
	var lab := BattleTheme.make_label(BattleText.move_name(move_id).to_upper(), 28, BattleTheme.WH, true)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lab.add_theme_color_override("font_outline_color", BattleTheme.BK)
	bg.add_child(lab)
	plate.add_child(bg)
	var face := PortraitView.new().setup(str(u["char"]), "bust")
	face.show_expression_text = false
	face.size = Vector2(150.0, 150.0)
	face.position = Vector2(plate.offset_right - plate.offset_left - 132.0, -8.0)
	plate.add_child(face)
	_fx.add_child(plate)
	_skill_node = plate
	plate.modulate.a = 0.0
	plate.offset_left += 60.0
	plate.offset_right += 60.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(plate, "modulate:a", 1.0, 0.12)
	tw.tween_property(plate, "offset_left", plate.offset_left - 60.0, 0.18)
	tw.tween_property(plate, "offset_right", plate.offset_right - 60.0, 0.18)
	tw.chain().tween_interval(0.7)
	tw.chain().tween_property(plate, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(plate.queue_free)


var _skill_node: Control = null


func _local_active_id() -> String:
	var me: Dictionary = _local_player()
	return str(me.get("active", "")) if not me.is_empty() else ""


func _overlay_banter_host() -> Control:
	return _fx


func _fx_act(e: Dictionary) -> float:
	var move_id: String = str(e.get("move", ""))
	var move: Dictionary = BattleContent.MOVES.get(move_id, {})
	var kind: String = str(move.get("kind", "basic"))
	if kind == "basic":
		return 0.0
	var unit: Dictionary = BattleState.unit(shown, str(e.get("unit", "")))
	if unit.is_empty() or str(unit["id"]) == BattleState.BOSS_ID:
		return 0.0
	if kind == "ult":
		banter(str(unit["id"]), "ult", true)
		_announce(str(unit["name"]), BattleText.move_name(move_id), false)
	elif kind == "skill" or kind == "reaction":
		_skill_plate(unit, move_id)
	else:
		_float_text(BattleText.move_name(move_id), str(unit["id"]), BattleTheme.unit_color(str(unit["color"])), 18)
	if int(move.get("ammo", 0)) > 0:
		Snd.play("shot")
	elif int(move.get("ammo_gain", 0)) > 0:
		Snd.play("reload")
	if kind == "skill" and str(move.get("target", "")) == "enemy" and move.has("mult"):
		# abilita': scia nel colore dell'operatore verso il boss
		var scol: Color = BattleTheme.unit_color(str(unit["color"]))
		_zap(_stage.anchor_of(str(unit["id"])), _stage.anchor_of(BattleState.BOSS_ID), scol)
	if kind == "ult":
		var at: Vector2 = _stage.anchor_of(str(unit["id"]))
		var ucol: Color = BattleTheme.unit_color(str(unit["color"]))
		var ust: String = UltFx.style_for(move)
		var seconds: float = _play_cutin(str(unit.get("char", "")), BattleText.move_name(move_id), BattleTheme.unit_color(str(unit["color"])))
		# le particelle partono quando il ritratto sparisce, sul personaggio
		get_tree().create_timer(seconds * 0.9).timeout.connect(func() -> void:
			if is_inside_tree():
				UltFx.play(_fx, at, ucol, ust, _stage.anchor_of(BattleState.BOSS_ID) if ust == "strike" else Vector2.ZERO)
				Snd.play("crit", 0.8))
		return seconds
	return 0.0


# Munizioni che salgono o scendono: numero fluttuante con il proiettile.
func _fx_ammo(e: Dictionary) -> float:
	var uid: String = str(e["unit"])
	var before: int = int(BattleState.unit(shown, uid).get("ammo", 0))
	var delta: int = int(e["value"]) - before
	if delta > 0:
		_float_text("+%d ●" % delta, uid, Hints.faction_color("libracorp"), 24)
	elif delta < 0:
		_float_text("%d ●" % delta, uid, BattleTheme.CY_DIM, 22)
	if int(e["value"]) == 0:
		_float_text("A SECCO!", uid, BattleTheme.RD, 22)
	return 0.0


# Parola a fumetto per gli stati: ogni abilita' di classe si riconosce al volo.
func _fx_status(e: Dictionary) -> void:
	var uid: String = str(e["unit"])
	match str(e["status"]):
		"taunt":
			_pop("PROVOCA!", uid, BattleTheme.RD, BattleTheme.WH, 30, 54.0, Vector2(0.0, -40.0))
		"mark":
			_pop("MARCHIATO!", uid, BattleTheme.POP, BattleTheme.BK, 28, 54.0, Vector2(0.0, -40.0))
		"hidden":
			_pop("NASCOSTO!", uid, BattleTheme.OK, BattleTheme.BK, 28, 52.0, Vector2(0.0, -40.0))
		"guard":
			_pop("GUARDIA", uid, BattleTheme.CY, BattleTheme.BK, 26, 50.0, Vector2(0.0, -40.0))
		"bleed":
			_pop("SANGUINA!", uid, BattleTheme.RD, BattleTheme.WH, 26, 50.0, Vector2(0.0, -40.0))


# Didascalia inclinata col nome di chi agisce e dell'abilita'.
func _announce(who: String, what: String, hostile: bool) -> void:
	var text: String = "%s  //  %s" % [str(who).to_upper(), str(what).to_upper()]
	ComicFx.caption(_fx, text, Vector2(380.0 if hostile else 24.0, 168.0), BattleTheme.RD if hostile else BattleTheme.CY, 0.55)


# Premendo la casella in panchina: fumetto SWITCH! proprio fra il personaggio davanti e quello che entra.
func _switch_balloon(slot: String) -> void:
	await get_tree().process_frame          # i nodi appena ricreati hanno la posizione solo dopo un frame
	var node: Control = _pair_arrows.get(slot)
	if node == null or not is_instance_valid(node) or _fx == null:
		return
	var c: Vector2 = node.get_global_rect().get_center() - _fx.get_global_rect().position
	ComicFx.pop(_fx, "SWITCH!", c + Vector2(0.0, -46.0), BattleTheme.POP, BattleTheme.BK, 24, 44.0)


# Cambio front/back: fumetto SWITCH! e due frecce > < che si incontrano sul personaggio che entra.
func _switch_fx(from_uid: String, to_uid: String) -> void:
	if _stage == null or _fx == null or from_uid == "":
		return
	# il compagno che entra non ha ancora una posizione: si usa quella di chi esce, che sta nello stesso punto
	var uid: String = from_uid
	var at: Vector2 = _stage.anchor_of(uid)
	_pop("SWITCH!", uid, BattleTheme.POP, BattleTheme.BK, 40, 70.0, Vector2(0.0, -70.0))
	for side in [-1, 1]:
		var l := BattleTheme.make_label(">" if side < 0 else "<", 72, BattleTheme.WH, true)
		l.add_theme_color_override("font_outline_color", BattleTheme.BK)
		l.add_theme_constant_override("outline_size", 10)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.position = at + Vector2(float(side) * 90.0 - 20.0, -150.0)
		_fx.add_child(l)
		if DisplayServer.get_name() == "headless":
			l.queue_free()
			continue
		var tw: Tween = l.create_tween().set_parallel(true)
		tw.tween_property(l, "position:x", l.position.x - float(side) * 60.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(l, "modulate:a", 0.0, 0.25).set_delay(0.35)
		tw.chain().tween_callback(l.queue_free)


func _pop(text: String, uid: String, fill: Color, ink: Color, size: int, radius: float, offset: Vector2 = Vector2.ZERO) -> void:
	var pos: Vector2 = _stage.anchor_of(uid) + Vector2(randf_range(-18.0, 18.0), -50.0) + offset
	ComicFx.pop(_fx, text, pos, fill, ink, size, radius)


# Sequenza dell'ultimate: ritratto grande, banda inclinata e nome della mossa.
func _play_cutin(char_id: String, move_name: String, color: Color) -> float:
	return CutIn.play(_fx, char_id, move_name, color)


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
			color = "#ff4630"
		"link":
			color = "#ffe14d"
		"heal":
			color = "#6bffb0"
		"down", "end":
			color = "#ff4630"
	log_lines.append("[color=%s]> %s[/color]" % [color, text])
	while log_lines.size() > 8:
		log_lines.pop_front()
	_refresh_log()


func _refresh_log() -> void:
	if _log_label != null:
		_log_label.text = "\n".join(log_lines.slice(maxi(0, log_lines.size() - 4)))
		if _log_open:
			_log_seen = _log_label.text
		_refresh_log_handle()


# ---------- Fine battaglia ----------

func _check_end() -> void:
	if _ended_shown or shown.is_empty() or str(shown["winner"]) == "":
		return
	_ended_shown = true
	var rewards: Dictionary = {}
	if source.has_method("finish"):
		rewards = source.finish()
	var won: bool = str(shown["winner"]) == "players"
	if won and AnimFx.enabled():
		ComicFx.flash(_fx, Color(1.0, 0.85, 0.3, 0.45), 0.6)
		AnimFx.shards(_fx, Vector2(640.0, 300.0), Color("#ffd166"), Vector2(520.0, 160.0))
	# prima vittoria su questo boss: scena finale della storia, poi il riquadro dell'esito
	_last_won = won
	if won and source is SoloBattleSource and Story.enabled() and MissionConfig.endless_floor == 0:
		var post: String = Story.scene_id(str(BattleState.boss(shown)["char"]), "post")
		if Story.is_new(post):
			var view: DialogueView = Story.play(self, post)
			if view != null:
				await view.finished
	_show_result(won, rewards)


func _mvp_line() -> String:
	var best_id: String = ""
	var best_dmg: int = 0
	var total: int = 0
	for k in _dmg_by:
		total += int(_dmg_by[k])
		if int(_dmg_by[k]) > best_dmg:
			best_dmg = int(_dmg_by[k])
			best_id = str(k)
	if best_id == "" or total <= 0:
		return ""
	var u: Dictionary = BattleState.unit(shown, best_id)
	var nm: String = str(u.get("name", best_id)).to_upper() if not u.is_empty() else best_id.to_upper()
	return "MVP %s · %d DANNI (%d%%) · COLPO MIGLIORE %d" % [nm, best_dmg, int(round(100.0 * float(best_dmg) / float(total))), _best_hit]


func _show_result(victory: bool, rewards: Dictionary) -> void:
	if _pause != null and is_instance_valid(_pause):
		_pause.queue_free()        # la battaglia e' finita (in rete puo' succedere con la pausa aperta)
	Snd.duck(-14.0)
	Snd.play("victory" if victory else "defeat")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	ScreenFrame.overshoot(dim)
	_overlay.add_child(dim)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel := HudPanel.new().setup("ESITO", BattleTheme.CY if victory else BattleTheme.RD)
	panel.cut = 24.0
	_overlay.add_child(panel)
	_anchor(panel, Vector4(0.5, 0.0, 0.5, 1.0), Vector4(-300, 112, 300, -64))      # dall'alto del banner fino a quasi il bordo basso: i tasti non escono mai
	var accent: Color = BattleTheme.CY if victory else BattleTheme.RD
	ComicFx.flash(_overlay, Color.WHITE if victory else BattleTheme.RD, 0.18)
	ComicFx.speed_lines(_overlay, Vector2(640, 360), Color(1, 1, 1, 0.8), 0.5)
	var _banner := ComicFx.caption(_overlay, "VITTORIA!" if victory else "SCONFITTA...", Vector2(380, 44), accent, 99.0)
	_banner.name = "ResultBanner"
	UiMotion.slide_in([panel], Vector2(0, 60), 0.0, 0.3)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.set_content(box)
	var title := BattleTheme.make_label("OPERAZIONE RIUSCITA" if victory else "OPERAZIONE FALLITA", 40, BattleTheme.CY if victory else BattleTheme.RD, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var mission_text: String = "%s · %s" % [MissionConfig.boss_title(str(BattleState.boss(shown)["char"])), str(BattleContent.tier_of(int(shown.get("tier", 0)))["name"])]
	if MissionConfig.daily_mod != "":
		var wk: bool = MissionConfig.weekly
		mission_text = "%s · %s" % ["EVENTO DELLA SETTIMANA" if wk else "SFIDA DEL GIORNO", MissionConfig.boss_title(MissionConfig.boss_id)]
		if victory and source is SoloBattleSource and bool(source.daily_first):
			var rs: Dictionary = RosterStore.load_or_new()
			mission_text += " · SERIE %d (PREMI x%.1f)" % [Weekly.streak(rs) if wk else Daily.streak(rs), Weekly.reward_mult(rs) if wk else Daily.reward_mult(rs)]
		elif victory:
			mission_text += " · BONUS GIA' RISCOSSO"
	elif MissionConfig.endless_floor > 0:
		var best_floor: int = Endless.best(RosterStore.load_or_new()) if source is SoloBattleSource else 0
		mission_text = "CICLO INFINITO · PIANO %d · RECORD %d" % [MissionConfig.endless_floor, best_floor]
	var mission := BattleTheme.make_label(mission_text, 16, BattleTheme.WH)
	mission.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(mission)
	var mvp: String = _mvp_line()
	if mvp != "":
		var ml := BattleTheme.make_label(mvp, 15, BattleTheme.POP)
		ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(ml)
	var recap_label := BattleTheme.make_label(_recap_text(victory), 13, BattleTheme.CY_DIM)
	recap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recap_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(recap_label)
	var replay_btn := Button.new()
	replay_btn.text = "REPLAY TATTICO"
	replay_btn.custom_minimum_size = Vector2(0, 40)
	BattleTheme.style_button(replay_btn, "normal", 16)
	replay_btn.pressed.connect(_open_replay)
	box.add_child(replay_btn)
	box.add_child(BattleTheme.make_label("PREMI", 16, BattleTheme.WH))
	_reward_rows.clear()
	# i premi stanno in un'area che scorre se sono tanti: i tasti restano sempre visibili sotto
	var rscroll := ScrollContainer.new()
	rscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rscroll.custom_minimum_size = Vector2(0, 60)
	box.add_child(rscroll)
	var rbox := VBoxContainer.new()
	rbox.add_theme_constant_override("separation", 6)
	rbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rscroll.add_child(rbox)
	for line in _reward_lines(rewards):
		var rk: Array = GameIcon.reward_key(str(line))
		var row: Control
		if str(rk[0]) != "":
			row = GameIcon.line(str(rk[0]), rk[1], str(line), 17, BattleTheme.CY)
		else:
			row = BattleTheme.make_label(line, 17, BattleTheme.CY)
		var lr: int = _line_rarity(str(line))
		if lr >= 2:
			# epico = bordo viola, leggendario = bordo giallo: richiama l'attenzione
			var edge: Color = Color("#ffd25f") if lr >= 3 else Color("#b07bff")
			var frame := PanelContainer.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(edge, 0.14)
			sb.border_color = edge
			sb.set_border_width_all(3)
			sb.set_corner_radius_all(4)
			sb.content_margin_left = 10.0
			sb.content_margin_right = 10.0
			sb.content_margin_top = 4.0
			sb.content_margin_bottom = 4.0
			frame.add_theme_stylebox_override("panel", sb)
			frame.add_child(row)
			row = frame
		rbox.add_child(row)
		_reward_rows.append([row, lr])
	if not (source is NetworkManager) and not MissionConfig.expedition.is_empty():
		var go_on := Button.new()
		go_on.text = "CONTINUA LA SPEDIZIONE"
		go_on.custom_minimum_size = Vector2(0, 54)
		BattleTheme.style_button(go_on, "primary", 26)
		go_on.pressed.connect(func() -> void: SceneRouter.go("expedition"))
		box.add_child(go_on)
	elif not (source is NetworkManager):
		if MissionConfig.endless_floor > 0 and victory:
			# Ciclo Infinito: si sceglie un potenziamento (1 su 3) e si sale al piano dopo
			box.add_child(BattleTheme.make_label("SCEGLI UN POTENZIAMENTO · PIANO %d" % (MissionConfig.endless_floor + 1), 15, BattleTheme.POP))
			_boon_buttons.clear()
			var boon_row := HBoxContainer.new()
			boon_row.add_theme_constant_override("separation", 8)
			box.add_child(boon_row)
			var n_boon: int = 1
			for bid in Endless.offer(MissionConfig.endless_floor):
				var def: Dictionary = Endless.BOONS[bid]
				var bb := Button.new()
				bb.text = "%d  %s  %s" % [n_boon, str(def["name"]), str(def["desc"])]
				bb.custom_minimum_size = Vector2(0, 68)
				bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				BattleTheme.style_button(bb, "primary" if n_boon == 1 else "normal", 13)
				bb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				bb.pressed.connect(_pick_boon.bind(str(bid)))
				boon_row.add_child(bb)
				_boon_buttons.append(bb)
				n_boon += 1
		else:
			var again := Button.new()
			again.text = "RIGIOCA"
			if MissionConfig.endless_floor > 0:
				again.text = "NUOVA SERIE"
			again.custom_minimum_size = Vector2(0, 50)
			BattleTheme.style_button(again, "primary", 26)
			again.pressed.connect(_on_again)
			box.add_child(again)
		var pick := Button.new()
		pick.text = "SCEGLI MISSIONE"
		pick.custom_minimum_size = Vector2(0, 44)
		BattleTheme.style_button(pick, "normal", 20)
		pick.pressed.connect(_on_pick_mission)
		box.add_child(pick)
	var networked: bool = source is NetworkManager
	if networked and not (source as NetworkManager).exp_run().is_empty():
		var back_map := Button.new()
		back_map.text = "MAPPA DELLA SPEDIZIONE"
		back_map.custom_minimum_size = Vector2(0, 50)
		BattleTheme.style_button(back_map, "primary", 22)
		back_map.pressed.connect(func() -> void:
			ExpeditionScreen.use_net = true
			SceneRouter.go("expedition"))
		box.add_child(back_map)
	var hub := Button.new()
	hub.text = "TORNA ALLA LOBBY" if networked else "TORNA ALL'HUB"
	hub.custom_minimum_size = Vector2(0, 44)
	BattleTheme.style_button(hub, "primary" if networked else "normal", 20)
	hub.pressed.connect(_on_hub)
	box.add_child(hub)
	if networked:
		var leave := Button.new()
		leave.text = "ESCI DALLA STANZA"
		leave.custom_minimum_size = Vector2(0, 44)
		BattleTheme.style_button(leave, "normal", 20)
		leave.pressed.connect(_on_leave_room)
		box.add_child(leave)
	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame      # le righe devono avere la loro posizione prima di animarle
		_animate_rewards(_overlay)


# Rarita' scritta in una riga di premio ("MOSSA: CURA (RARA)"); -1 = nessuna (crediti, materiali).
func _line_rarity(line: String) -> int:
	var up: String = line.to_upper()
	for i in range(BattleTypes.RARITIES.size() - 1, -1, -1):
		if str(BattleTypes.RARITIES[i]).to_upper() in up and (up.begins_with("MOSSA") or up.begins_with("PEZZO") or up.begins_with("PASSIVA") or up.begins_with("ICONA")):
			return i
	return -1


# Le righe dei premi entrano una dopo l'altra; gli oggetti rari fanno piu' scena.
func _animate_rewards(host: Control) -> void:
	var delay: float = 0.25
	for entry in _reward_rows:
		var r: int = int(entry[1])
		RarityFx.reveal_row(host, entry[0], r, delay)
		delay += float(RarityFx.STAGGER[clampi(r, 0, 3)]) + 0.04


func _reward_lines(rewards: Dictionary) -> Array:
	var lines: Array = []
	if rewards.is_empty():
		return ["—"]
	if int(rewards.get("coins", 0)) > 0:
		lines.append("+%d CREDITI" % int(rewards["coins"]))
	for mat in rewards.get("materials", {}):
		lines.append("+%d %s" % [int(rewards["materials"][mat]), str(BattleContent.MATERIALS.get(mat, mat)).to_upper()])
	for d in rewards.get("drops", []):
		match str(d["kind"]):
			"gear":
				lines.append("PEZZO: %s %s" % [str(d["slot"]).to_upper(), str(BattleTypes.RARITIES[int(d["rarity"])]).to_upper()])
			"move":
				lines.append("MOSSA: %s (%s)" % [BattleText.move_name(str(d["id"])), str(BattleTypes.RARITIES[int(d["rarity"])]).to_upper()])
			"icon":
				lines.append("ICONA: %s (%s)" % [Profile.icon_name(str(d["id"])).to_upper(), str(BattleTypes.RARITIES[clampi(Profile.rarity_of(str(d["id"])), 0, 3)]).to_upper()])
			"passive":
				lines.append("PASSIVA: %s (%s)" % [str(BattleContent.PASSIVES[str(d["id"])]["name"]).to_upper(), str(BattleTypes.RARITIES[int(d["rarity"])]).to_upper()])
	if lines.is_empty():
		lines.append("—")
	return lines


func _pick_boon(id: String) -> void:
	if MissionConfig.endless_floor <= 0:
		return
	MissionConfig.endless_boons.append(id)
	_on_again()


func _on_again() -> void:
	if MissionConfig.endless_floor > 0:
		MissionConfig.set_endless(MissionConfig.endless_floor + 1 if _last_won else 1)
	SceneRouter.go("battle", true)


func _on_pick_mission() -> void:
	SceneRouter.go("missions")


func _on_hub() -> void:
	# In rete la stanza resta aperta: si torna alla lobby con tutti gli altri.
	SceneRouter.go("lobby" if source is NetworkManager else "hub")


func _on_leave_room() -> void:
	var session: Node = get_node_or_null("/root/NetSession")
	if session != null:
		session.leave_room()
	else:
		(source as NetworkManager).shutdown()
		SceneRouter.go("hub")
