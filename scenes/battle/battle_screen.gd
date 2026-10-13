extends Control

# Schermata di battaglia (nuovo motore). Funziona con qualsiasi "sorgente" che
# offra: battle, local_player_id, battle_time_left, battle_updated,
# battle_events_received e submit_choice() - SoloBattleSource o NetworkManager.


var source: Variant = null
var pending_source: Variant = null    # sorgente da collegare appena la scena e' pronta
var event_delay: float = 0.42
var shown: Dictionary = {}          # copia dello stato come lo vede il giocatore ora
var animating: bool = false
var locked: bool = false            # ordine inviato, si aspetta il round
var pending_swap: String = ""       # personaggio scelto per il cambio
var log_lines: Array = []
var _last_won: bool = false
var _dmg_by: Dictionary = {}      # danni al boss per operatore (per l'MVP a fine battaglia)
var _best_hit: int = 0
var _ended_shown: bool = false

var _stage: BattleStage
var _reward_rows: Array = []
var _turn_box: VBoxContainer
var _turn_sig: String = ""
var _turn_acting: String = ""
var _fx: Control
var _boss_name: Label
var _boss_bar: SegBar
var _boss_hp: Label
var _round_label: Label
var _timer_label: Label
var _clock_label: Label
var _tele_panel: HudPanel
var _boss_panel: HudPanel
var _tutorial: TutorialOverlay = null
var _tele_label: Label
var _tele_target: Label
var _ops_box: VBoxContainer
var _orders_box: FanMenu
var _fan_key: String = ""
var _log_label: RichTextLabel
var _overlay: Control
var _rec_dot: ColorRect
var _t: float = 0.0
var _clock_sec: int = -1
var _ops_sig: String = ""
var _orders_sig: String = ""
var _timer_secs: int = -2
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
	if source is SoloBattleSource and Settings.should_show_tutorial():
		_start_tutorial.call_deferred()


# ---------- Tutorial ----------

func _panel_of(c: Control) -> Control:
	var node: Node = c
	while node != null and not (node is HudPanel):
		node = node.get_parent()
	return node as Control


func tutorial_steps() -> Array:
	return [
		{"title": "BENVENUTO, OPERATORE", "target": null,
		"text": "Una anomalia ti sta davanti. Il tuo compito: metterla a terra prima che metta K.O. tutta la tua squadra. Si combatte a round: ogni round scegli un ordine, poi si risolve tutto insieme."},
		{"title": "IL BERSAGLIO", "target": _boss_panel,
		"text": "Qui vedi il nome del boss e la sua integrita'. Quando la barra arriva a zero, hai vinto. Sotto meta' integrita' il boss va in furia e colpisce piu' forte."},
		{"title": "ALLARME", "target": _tele_panel,
		"text": "Il boss ti avvisa: questa e' la mossa che usera' in QUESTO round e chi colpira'. Cambia ogni round, quindi leggila sempre prima di scegliere."},
		{"title": "I TUOI OPERATORI", "target": _panel_of(_ops_box),
		"text": "La tua squadra: PV, energia e carica dell'ultimate di ciascuno. Uno solo e' in campo (il triangolo). Clicca un compagno in panchina per scambiarlo: il cambio e' gratis e avviene prima di tutto. Chi sta in panchina recupera piu' energia."},
		{"title": "COME FUNZIONA UN TURNO", "target": _panel_of(_turn_box),
		"text": "Ogni round TU scegli solo per il tuo operatore in campo. I compagni IA scelgono da soli (non copiano te) e la loro scelta e' gia' visibile nell'ORDINE DEL TURNO. Poi si risolve tutto in fila per priorita' e velocita': il segnalino rosso mostra chi agisce e chi subisce. Dietro di te vedi in silhouette il tuo party in panchina (solo i tuoi operatori)."},
		{"title": "GLI ORDINI", "target": _orders_box,
		"text": "I comandi si aprono a ventaglio attorno al tuo operatore. Scegli cosa fare: ATTACCO, GUARDIA (dimezza i danni), le abilita' (costano energia) e l'ULTIMATE, che si carica combattendo. Scorciatoie: tasti 1-4. I colori contano: un colpo del colore giusto fa +50% di danni, quello sbagliato -33%."},
		{"title": "CLASSI E FAZIONI", "target": null,
		"text": "STRIKER fa danno, VANGUARD regge i colpi, WARDEN cura e protegge. Le FAZIONI (LibraCorp, Rondini, Magabondi, Kairos) danno bonus ai compagni dello stesso gruppo: piu' sono rari, piu' il bonus e' grande. Nell'archivio operatori trovi STRATEGIE, ARCHIVIO e la LEGENDA di ogni personaggio."},
		{"title": "LINK: LA CATENA", "target": _panel_of(_turn_box),
		"text": "Quando due compagni agiscono di fila (prima che il boss si muova) nasce un LINK: ogni anello da' +15% di danno. Fazioni DIVERSE = CROSS, caricano l'ultimate di entrambi. Stessa fazione o stesso colore = UNISONO, anello doppio. Metti in squadra alleati improbabili e fai agire i tuoi di fila: il boss spezza la catena."},
		{"title": "PRONTO?", "target": null,
		"text": "Il registro in basso racconta cosa succede ogni round. Se finisce male, non c'e' problema: si ritenta e si guadagnano comunque monete per potenziare la squadra. Buona fortuna!"},
	]


func _start_tutorial() -> void:
	if _tutorial != null or not is_inside_tree():
		return
	await get_tree().process_frame     # aspetta che i pannelli abbiano la loro posizione
	_tutorial = TutorialOverlay.new().setup(tutorial_steps())
	add_child(_tutorial)
	_tutorial.finished.connect(_on_tutorial_finished)


func _on_tutorial_finished(_skipped: bool) -> void:
	_tutorial = null
	Settings.finish_tutorial()


# ---------- Avvio ----------

func _start_solo() -> void:
	var s := SoloBattleSource.new()
	bind_source(s)
	s.endless_floor = MissionConfig.endless_floor
	s.daily_mod = MissionConfig.daily_mod
	s.start(RosterStore.load_or_new(), MissionConfig.boss_id, int(randi()) | 1, MissionConfig.tier)
	if DisplayServer.get_name() != "headless":
		get_tree().create_timer(1.4).timeout.connect(func() -> void:
			if is_inside_tree() and str(shown.get("winner", "")) == "":
				banter(_local_active_id(), "start", true))
	if MissionConfig.daily_mod != "" and DisplayServer.get_name() != "headless":
		var dm: Dictionary = {}
		for m in Endless.MODS:
			if str(m["id"]) == MissionConfig.daily_mod:
				dm = m
		ComicFx.caption(_fx, "SFIDA DEL GIORNO  //  %s: %s" % [str(dm.get("name", "")), str(dm.get("desc", ""))], Vector2(240.0, 300.0), BattleTheme.POP, 1.8)
	elif MissionConfig.endless_floor > 0 and DisplayServer.get_name() != "headless":
		var emod: Dictionary = Endless.mod_for(MissionConfig.endless_floor)
		var cap: String = "PIANO %d" % MissionConfig.endless_floor
		if not emod.is_empty():
			cap += "  //  %s: %s" % [str(emod["name"]), str(emod["desc"])]
		ComicFx.caption(_fx, cap, Vector2(300.0, 300.0), BattleTheme.POP, 1.6)


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
	ScreenFx.solid(self, BattleTheme.BK)      # (non disegnato: lo schermo e' gia' pulito di questo colore)

	_stage = BattleStage.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	# velatura ciano, telecamera e retino da fumetto: un solo passaggio a tutto schermo
	ScreenFx.battle(self)

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
	var rec := BattleTheme.make_label("REC", 24, BattleTheme.WH, true)
	rec.position = Vector2(56, 20)
	add_child(rec)
	var cam := BattleTheme.make_label("CAM-07 · VIA S. GIORGIO · PARK 3", 14, BattleTheme.CY)
	cam.position = Vector2(28, 70)
	cam.visible = false
	add_child(cam)
	_clock_label = BattleTheme.make_label("", 15, BattleTheme.CY)
	_clock_label.position = Vector2(28, 92)
	_clock_label.visible = false
	add_child(_clock_label)
	_round_label = BattleTheme.make_label("CICLO 01", 22, BattleTheme.WH, true)
	_round_label.position = Vector2(28, 52)
	add_child(_round_label)


func _build_boss_banner() -> void:
	var panel := HudPanel.new().setup("SOGGETTO N.07", BattleTheme.RD)
	_boss_panel = panel
	add_child(panel)
	panel.margins = Vector4(18.0, 26.0, 18.0, 8.0)
	_anchor(panel, Vector4(0.5, 0.0, 0.5, 0.0), Vector4(-300, 24, 140, 120))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.set_content(box)
	_boss_name = BattleTheme.make_label("SOGGETTO", 13, BattleTheme.RD)
	box.add_child(_boss_name)
	_boss_bar = SegBar.new().setup(30, BattleTheme.RD, Vector2(0, 18))
	_boss_bar.color_off = BattleTheme.RD_DARK
	_boss_bar.smooth = true
	box.add_child(_boss_bar)
	_boss_hp = BattleTheme.make_label("INTEGRITA'", 17, BattleTheme.WH)
	_boss_hp.add_theme_font_override("font", BattleTheme.hud())
	box.add_child(_boss_hp)

	var timer_panel := HudPanel.new().setup("ORDINE ENTRO", BattleTheme.RD)
	timer_panel.quiet = true
	add_child(timer_panel)
	timer_panel.margins = Vector4(14.0, 22.0, 14.0, 2.0)
	_anchor(timer_panel, Vector4(0.0, 0.0, 0.0, 0.0), Vector4(170, 20, 330, 80))
	_timer_label = BattleTheme.make_label("LIBERO", 34, BattleTheme.CY, true)
	timer_panel.set_content(_timer_label)


func _build_telegraph() -> void:
	_tele_panel = HudPanel.new().setup("ALLARME", BattleTheme.RD)
	add_child(_tele_panel)
	_tele_panel.margins = Vector4(18.0, 26.0, 18.0, 6.0)
	_anchor(_tele_panel, Vector4(0.5, 0.0, 0.5, 0.0), Vector4(-300, 128, 140, 204))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	_tele_panel.set_content(box)
	_tele_label = BattleTheme.make_label("PROSSIMA MOSSA", 28, BattleTheme.WH, true)
	box.add_child(_tele_label)
	_tele_target = BattleTheme.make_label("", 15, BattleTheme.RD)
	box.add_child(_tele_target)


# Pannello "ORDINE DEL TURNO": chi agisce, in che ordine e cosa ha scelto (le IA decidono da sole).
func _build_turn_panel() -> void:
	var panel := HudPanel.new().setup("ORDINE DEL TURNO", BattleTheme.CY_DIM)
	panel.quiet = true
	panel.margins = Vector4(12, 26, 12, 6)
	add_child(panel)
	_anchor(panel, Vector4(0.0, 0.0, 0.0, 0.0), Vector4(20, 92, 330, 218))
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
			var mine: bool = not me.is_empty() and str(p["id"]) == str(me["id"])
			row["mine"] = mine
			row["name"] = str(u.get("name", "?")).to_upper()
			row["who"] = "TU" if mine else ("IA" if bool(p["ai"]) else str(p["name"]).to_upper().left(4))
			var choice: Variant = p["choice"]
			if mine:
				var pend: String = pending_swap
				if locked or (choice is Dictionary and choice.has("move")):
					action = BattleText.move_name(str(entry["move"])) if str(entry["move"]) != "" else "BLOCCATO"
				else:
					action = "SCEGLI TU" + ("  (CAMBIO)" if pend != "" else "")
				row["color"] = BattleTheme.WH
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
	var sig: String = "%s|%d|%s|%s" % [_turn_acting, int(shown.get("round", 0)) if not shown.is_empty() else 0, str(locked), pending_swap]
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
	var fs: int = 13 if not TouchUi.active() else 14
	for r in rows:
		var acting_now: bool = str(r["unit"]) == _turn_acting
		var text: String = "%s%d  %-4s %-7s » %s" % ["▶" if acting_now else " ", int(r["n"]), str(r["who"]), str(r["name"]).left(7), str(r["action"])]
		var col: Color = BattleTheme.GOLD if acting_now else (r["color"] as Color)
		var l := BattleTheme.make_label(text, fs, col, bool(r["mine"]))
		l.clip_text = true
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_turn_box.add_child(l)


func _build_operators() -> void:
	var panel := HudPanel.new().setup("", BattleTheme.CY)
	panel.bare = true
	panel.margins = Vector4(10.0, 10.0, 10.0, 8.0)
	add_child(panel)
	_anchor(panel, Vector4(0.0, 1.0, 0.0, 1.0), Vector4(20, -(_unit_row_height() * 3.0 + 84.0) if TouchUi.active() else -224.0, 372, -18))
	_ops_box = VBoxContainer.new()
	_ops_box.add_theme_constant_override("separation", 3)
	panel.set_content(_ops_box)


func _build_orders() -> void:
	_orders_box = FanMenu.new()
	_orders_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_orders_box)


# Il ventaglio nasce dal torace dell'operatore del giocatore, dove lo disegna il palco.
func _fan_origin() -> Vector2:
	var idx: int = 0
	var players: Array = shown.get("players", [])
	for i in players.size():
		if str(players[i]["id"]) == str(source.local_player_id):
			idx = i
	var pose: Vector3 = _stage.party_pose(idx, players.size())
	return Vector2(pose.x + 36.0, pose.y - 95.0 * pose.z)


func _build_log() -> void:
	var panel := HudPanel.new().setup("", BattleTheme.CY_DIM)
	panel.bare = true
	panel.margins = Vector4(12, 8, 12, 6)
	add_child(panel)
	_anchor(panel, Vector4(0.0, 1.0, 1.0, 1.0), Vector4(392, -86, -716 if TouchUi.active() else -556, -18))
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
			if secs < 0:
				_timer_label.text = "LIBERO"
				_timer_label.add_theme_color_override("font_color", BattleTheme.CY)
			else:
				_timer_label.text = "%02d:%02d" % [secs / 60, secs % 60]
				_timer_label.add_theme_color_override("font_color", BattleTheme.RD if secs <= 10 else BattleTheme.WH)


func _refresh_all() -> void:
	if shown.is_empty():
		return
	_stage.local_player_id = str(source.local_player_id)
	_stage.set_state(shown)
	_refresh_boss()
	_refresh_telegraph()
	_refresh_operators()
	_refresh_orders()
	_refresh_turn_panel()
	_refresh_log()
	_round_label.text = "CICLO %02d" % int(shown["round"])


func _refresh_boss() -> void:
	var boss: Dictionary = BattleState.boss(shown)
	var info: Dictionary = BattleContent.BOSSES.get(str(boss["char"]), {})
	var tier_name: String = str(BattleContent.tier_of(int(shown.get("tier", 0)))["name"])
	if int(shown.get("endless", 0)) > 0:
		var emod: Dictionary = Endless.mod_for(int(shown["endless"]))
		tier_name = "PIANO %d%s" % [int(shown["endless"]), (" · " + str(emod["name"])) if not emod.is_empty() else ""]
	_boss_name.text = "%s · %s · %s" % [str(info.get("name", "SOGGETTO")).to_upper(), str(info.get("title", "")).to_upper(), tier_name]
	_boss_bar.set_ratio(float(boss["hp"]) / float(boss["max_hp"]))
	var tags: String = ""
	for s in boss["statuses"]:
		if str(s) == "mark" and int(boss.get("marks", 0)) > 0:
			tags += "  [MARCHI x%d]" % int(boss["marks"])
		else:
			tags += "  [%s]" % BattleText.status_name(str(s))
	for m in boss.get("mods", []):
		if int(m["pm"]) < 0:
			tags += " ▼%s" % str(BattleContent.STAT_NAMES.get(str(m["stat"]), str(m["stat"]).to_upper()))
	_boss_hp.text = "PV  %d/%d%s" % [int(boss["hp"]), int(boss["max_hp"]), tags]


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
	var tlen: int = _tele_label.text.length()
	_tele_label.add_theme_font_size_override("font_size", 28 if tlen <= 14 else maxi(17, int(28.0 * 14.0 / float(tlen))))
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
	var me: Dictionary = _local_player()
	# firma di cio' che si vede: se non e' cambiata nulla, i nodi restano dove sono
	var sig: String = ""
	var active_id: String = ""
	if not me.is_empty():
		active_id = pending_swap if pending_swap != "" else str(me["active"])
		sig = "%s|%s|" % [active_id, str(me["active"])]
		for uid in me["team"]:
			var tu: Dictionary = BattleState.unit(shown, uid)
			sig += "%s,%d,%d,%d,%d,%d,%s,%d,%d;" % [uid, int(tu["hp"]), int(tu["max_hp"]), int(tu["energy"]), int(tu["gauge"]), int(tu["level"]), Factions.aura_text(tu), int(tu["ammo"]), (tu["mods"] as Array).size()]
		for p in shown["players"]:
			if p["id"] != me["id"]:
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


# Altezza della riga di un operatore: sul telefono e' piu' alta, per il dito.
func _unit_row_height() -> float:
	return 60.0 if TouchUi.active() else 44.0


# Sotto il nome: fazione, aure, munizioni, effetti. Ognuno si puo' puntare o toccare per leggere cosa significa.
func _add_chips(inner: Control, u: Dictionary, selected: bool) -> void:
	var f: String = str(u.get("faction", ""))
	if f == "":
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.position = Vector2(244.0, 26.0 if not TouchUi.active() else 22.0)
	inner.add_child(row)
	var tint: Color = Hints.faction_color(f)
	if selected:
		tint = BattleTheme.BK
	var fac: InfoChip = InfoChip.badge(Hints.faction_code(f), tint)
	HintCard.bind(fac, func() -> Dictionary: return Hints.faction_card(BattleState.unit(shown, str(u["id"]))), self)
	row.add_child(fac)
	if int(u.get("ammo_max", 0)) > 0:
		var am: InfoChip = InfoChip.ammo(int(u["ammo"]), int(u["ammo_max"]), tint if selected else Hints.faction_color("libracorp"))
		HintCard.bind(am, func() -> Dictionary: return Hints.ammo_card(BattleState.unit(shown, str(u["id"]))), self)
		row.add_child(am)


func _unit_row(u: Dictionary, selected: bool, is_active: bool) -> Control:
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
	if is_active:
		title += "  ▶"
	var where: String = "K.O." if not alive else ("IN CAMPO" if is_active else "PANCHINA")
	var name_l := BattleTheme.make_label(title, 17, fg, true)
	name_l.position = Vector2(54, -2)
	inner.add_child(name_l)
	# volto dell'operatore (la grafica vera se c'e', altrimenti il segnaposto anime)
	var face := PortraitView.new().setup(str(u["char"]), "icon")
	face.position = Vector2(10, 2)
	face.size = Vector2(38, 38)
	face.modulate = Color(1, 1, 1, 1.0 if alive else 0.4)
	inner.add_child(face)
	var lv_l := BattleTheme.make_label("LV%d" % int(u["level"]), 12, fg)
	lv_l.position = Vector2(196, 3)
	inner.add_child(lv_l)

	_add_chips(inner, u, selected)

	var hp_ratio: float = float(u["hp"]) / float(u["max_hp"])
	var hp := SegBar.new().setup(14, BattleTheme.BK if selected else (BattleTheme.RD if hp_ratio < 0.3 else BattleTheme.CY), Vector2(196, 8))
	hp.color_off = Color(0, 0, 0, 0.35) if selected else BattleTheme.CY_DARK
	hp.set_ratio(hp_ratio)
	hp.position = Vector2(54, 22)
	inner.add_child(hp)
	var hp_t := BattleTheme.make_label("%d" % int(u["hp"]), 18, fg, true)
	hp_t.position = Vector2(262, 1)
	inner.add_child(hp_t)

	var en := SegBar.new().setup(BattleTypes.MAX_ENERGY, BattleTheme.BK if selected else BattleTheme.WH, Vector2(78, 6))
	en.color_off = Color(0, 0, 0, 0.35) if selected else BattleTheme.CY_DARK
	en.set_ratio(float(u["energy"]) / float(BattleTypes.MAX_ENERGY))
	en.position = Vector2(54, 34)
	inner.add_child(en)
	var gauge := SegBar.new().setup(10, BattleTheme.BK if selected else BattleTheme.RD, Vector2(96, 6))
	gauge.color_off = Color(0, 0, 0, 0.35) if selected else BattleTheme.RD_DARK
	gauge.set_ratio(float(u["gauge"]) / float(BattleTypes.GAUGE_MAX))
	gauge.position = Vector2(142, 34)
	inner.add_child(gauge)
	if not alive:
		var where_l := BattleTheme.make_label(where, 11, fg, true)
		where_l.position = Vector2(274, 3)
		inner.add_child(where_l)
	if int(u["gauge"]) >= BattleTypes.GAUGE_MAX and alive:
		lv_l.text = "ULT!"
		lv_l.add_theme_color_override("font_color", BattleTheme.BK if selected else BattleTheme.RD)
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
	var me: Dictionary = _local_player()
	if me.is_empty() or str(shown["winner"]) != "":
		_orders_sig = ""
		for c in _orders_box.get_children():
			_orders_box.remove_child(c)
			c.queue_free()
		_order_buttons.clear()
		_orders_box.clear_arc()
		return
	var uid: String = pending_swap if pending_swap != "" else str(me["active"])
	var u: Dictionary = BattleState.unit(shown, uid)
	# firma di cio' che si vede (testi e pulsanti spenti): se e' uguale non si ricostruisce
	var sig: String = "%s|%s|%s|%s|%d" % [uid, pending_swap, locked, animating, int(u["gauge"])]
	var sig_ids: Array = ["attack", "guard"]
	sig_ids.append_array(u["skills"])
	if str(u["ult"]) != "":
		sig_ids.append(str(u["ult"]))
	for mid in sig_ids:
		sig += "|" + str(BattleResolver.validate_choice(shown, str(source.local_player_id), _make_choice(str(mid))) == "")
	if sig == _orders_sig and _orders_box.get_child_count() > 0:
		return
	_orders_sig = sig
	for c in _orders_box.get_children():
		_orders_box.remove_child(c)
		c.queue_free()
	_order_buttons.clear()
	var touch: bool = TouchUi.active()
	_orders_box.origin = _fan_origin()
	_orders_box.tint = BattleTheme.unit_color(str(u["color"]))
	var title := BattleTheme.make_label(("CAMBIO » %s (GRATIS)" if pending_swap != "" else "ORDINE PER %s") % str(u["name"]).to_upper(), 14, BattleTheme.WH, true)
	_orders_box.add_child(title)
	var entries: Array = [{"id": "attack", "kind": "primary"}, {"id": "guard", "kind": "normal"}]
	for s in u["skills"]:
		entries.append({"id": str(s), "kind": "normal"})
	if str(u["ult"]) != "":
		entries.append({"id": str(u["ult"]), "kind": "ultimate"})
	var bh: float = 56.0 if touch else 42.0
	var bw: float = 232.0 if touch else 196.0
	var pts: Array = _orders_box.layout(entries.size(), bh, 6.0, 340.0 if touch else 290.0)
	title.position = Vector2(float(pts[0].x) + 6.0, float(pts[0].y) - bh * 0.5 - 24.0)
	var animate: bool = _fan_key != "%s|%d" % [uid, int(shown["round"])]
	_fan_key = "%s|%d" % [uid, int(shown["round"])]
	var n: int = 1
	for e in entries:
		var move_id: String = str(e["id"])
		var move: Dictionary = BattleContent.MOVES[move_id]
		var choice: Dictionary = _make_choice(move_id)
		var err: String = BattleResolver.validate_choice(shown, str(source.local_player_id), choice)
		var b := Button.new()
		var suffix: String = ""
		if str(move["kind"]) == "skill":
			suffix = "  %dE" % int(move["cost"])
		elif str(move["kind"]) == "ult":
			suffix = "  %d%%" % int(u["gauge"])
		b.text = "%d  %s%s" % [n, BattleText.move_name(move_id), suffix]
		var order_unit_id: String = uid
		var order_err: String = err
		HintCard.bind(b, func() -> Dictionary: return Hints.move_card(BattleState.unit(shown, order_unit_id), move_id, order_err), self, true)
		var primary: bool = str(e["id"]) == "attack"
		var is_guard: bool = str(e["id"]) == "guard"
		var w: float = bw + (28.0 if primary else 0.0)
		b.custom_minimum_size = Vector2(w, bh)
		b.size = Vector2(w, bh)
		# il testo non si taglia mai: si sceglie il carattere piu' grande che ci sta nel pulsante
		var size_base: int = 22 if primary else 17
		var avail: float = w - 74.0        # margini del pulsante e icona
		var fsize: int = size_base
		while fsize > (14 if touch else 10) and BattleTheme.display().get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x > avail:
			fsize -= 1
		BattleTheme.style_button(b, str(e["kind"]) if not is_guard else "normal", fsize)
		b.add_theme_font_size_override("font_size", fsize)
		b.disabled = err != "" or locked or animating
		var oic: GameIcon = GameIcon.attach(b, GameIcon.move_key(move_id), BattleTheme.WH if primary else GameIcon.move_color(move_id), 26.0 if primary else 20.0)
		oic.modulate.a = 0.35 if b.disabled else 1.0
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


# Un pulsante tenuto premuto ha aperto la sua scheda: quel rilascio non e' un comando.
func _held_hint_order() -> bool:
	for b in _order_buttons:
		if is_instance_valid(b) and HintCard.consume_hold(b):
			return true
	return false


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
	if not _order_buttons.is_empty() and _held_hint_order():
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
	# A battaglia finita: INVIO = rigioca / torna alla lobby, ESC = esci.
	if _ended_shown:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if source is NetworkManager:
				_on_hub()
			else:
				_on_again()
		elif event.keycode == KEY_ESCAPE:
			SceneRouter.go("hub" if not (source is NetworkManager) else "lobby")
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
		await get_tree().create_timer(event_delay + extra).timeout
	animating = false
	_link_clear()
	_stage.clear_markers()
	_turn_acting = ""
	if not is_inside_tree():
		return
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


const HIT_WORDS: Array = ["BAM!", "POW!", "CRACK!", "WHAM!", "BOOM!"]
const BIG_HIT_FRACTION: float = 0.12     # un colpo cosi' grande (rispetto ai PV massimi) e' "pesante"


# Effetti grafici e sonori di un evento. Ritorna i secondi di pausa in piu' (hit-stop).
func _event_fx(e: Dictionary) -> float:
	match str(e.get("t", "")):
		"damage":
			return _fx_damage(e)
		"bleed":
			_float_text("-%d" % int(e["amount"]), str(e["unit"]), BattleTheme.RD, 28)
		"counter":
			Snd.play("counter")
			_stage.impact(6.0, 0.02)
			_pop("RISPOSTA!", str(e["unit"]), Hints.faction_color("libracorp"), BattleTheme.BK, 34, 60.0, Vector2(0.0, -30.0))
		"ammo":
			return _fx_ammo(e)
		"trait":
			Snd.play("trait")
			_float_text("▲ DIF  ▲ VEL", str(e["unit"]), Hints.faction_color("libracorp"), 20)
		"status":
			_fx_status(e)
		"heal":
			Snd.play("heal")
			_pop("+%d" % int(e["amount"]), str(e["dst"]), BattleTheme.OK, BattleTheme.BK, 32, 52.0)
		"shield":
			_float_text("+%d" % int(e["amount"]), str(e["dst"]), BattleTheme.CY, 26)
		"marks":
			return _fx_marks(e)
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
		"swap":
			Snd.play("swap")
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
				return 0.35
			_buzz(110)
			_stage.impact(14.0, 0.04)
			ComicFx.flash(_fx, Color(1, 1, 1, 0.5), 0.15)
			_pop("K.O.!", str(e["unit"]), BattleTheme.RD, BattleTheme.WH, 56, 95.0)
			banter(_local_active_id(), "ko")
			return 0.12
	return 0.0


# Vibrazione breve sul telefono nei momenti forti (solo touch).
func _buzz(ms: int) -> void:
	if TouchUi.active():
		Input.vibrate_handheld(ms)


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
	var line := Line2D.new()
	line.width = 4.0
	line.default_color = col
	var pts := PackedVector2Array()
	for i in 9:
		var f: float = float(i) / 8.0
		var p: Vector2 = a.lerp(b, f)
		if i > 0 and i < 8:
			p += Vector2(randf_range(-8.0, 8.0), randf_range(-14.0, 14.0))
		pts.append(p)
	line.points = pts
	_fx.add_child(line)
	var tw := create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.22)
	tw.tween_callback(line.queue_free)


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


func _fx_damage(e: Dictionary) -> float:
	var dst: String = str(e["dst"])
	var amount: int = int(e["amount"])
	var to_boss: bool = dst == BattleState.BOSS_ID
	Snd.play("guard" if amount <= 0 else ("hit" if to_boss else "player_hit"), randf_range(0.94, 1.06))
	_stage.flash(dst)
	if amount <= 0:
		_pop("GUARD!", dst, BattleTheme.CY, BattleTheme.BK, 34, 62.0)
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
	# un solo fumetto per colpo: il critico e' semplicemente piu' grande, col punto esclamativo
	_pop("-%d%s" % [amount, "!" if is_crit else ""], dst, fill, BattleTheme.BK, 52 if is_crit else (44 if heavy else 32), 84.0 if is_crit else (74.0 if heavy else 56.0))
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


# Fumetto in alto a destra: volto di chi parla e una riga. Non piu' di uno ogni ~6 secondi.
func banter(uid: String, kind: String, force: bool = false) -> void:
	var now: int = Time.get_ticks_msec()
	if not force and now < _banter_until_ms:
		return
	var u: Dictionary = BattleState.unit(shown, uid)
	if u.is_empty() or str(u["side"]) != "player" or not Settings.banter:
		return
	var text: String = Banter.line(kind, str(u["color"]), int(shown.get("round", 0)) + uid.length())
	if text == "":
		return
	_banter_until_ms = now + 6000
	if _banter_node != null and is_instance_valid(_banter_node):
		_banter_node.queue_free()
	var plate := Control.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	plate.anchor_left = 1.0
	plate.anchor_right = 1.0
	plate.offset_left = -400.0
	plate.offset_right = -22.0
	plate.offset_top = 22.0
	plate.offset_bottom = 112.0
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
			color = "#ff2d55"
		"link":
			color = "#ffe14d"
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
		_log_label.text = "\n".join(log_lines.slice(maxi(0, log_lines.size() - 4)))


# ---------- Fine battaglia ----------

func _check_end() -> void:
	if _ended_shown or shown.is_empty() or str(shown["winner"]) == "":
		return
	_ended_shown = true
	var rewards: Dictionary = {}
	if source.has_method("finish"):
		rewards = source.finish()
	var won: bool = str(shown["winner"]) == "players"
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
	Snd.duck(-14.0)
	Snd.play("victory" if victory else "defeat")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel := HudPanel.new().setup("ESITO", BattleTheme.CY if victory else BattleTheme.RD)
	panel.cut = 24.0
	_overlay.add_child(panel)
	_anchor(panel, Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-300, -230, 300, 230))
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
		mission_text = "SFIDA DEL GIORNO · %s" % MissionConfig.boss_title(MissionConfig.boss_id)
		if victory and source is SoloBattleSource and bool(source.daily_first):
			mission_text += " · SERIE %d (PREMI x%.1f)" % [Daily.streak(RosterStore.load_or_new()), Daily.reward_mult(RosterStore.load_or_new())]
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
	box.add_child(BattleTheme.make_label("PREMI", 16, BattleTheme.WH))
	_reward_rows.clear()
	for line in _reward_lines(rewards):
		var rk: Array = GameIcon.reward_key(str(line))
		var row: Control
		if str(rk[0]) != "":
			row = GameIcon.line(str(rk[0]), rk[1], str(line), 17, BattleTheme.CY)
		else:
			row = BattleTheme.make_label(line, 17, BattleTheme.CY)
		box.add_child(row)
		_reward_rows.append([row, _line_rarity(str(line))])
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	if not (source is NetworkManager):
		var again := Button.new()
		again.text = "RIGIOCA"
		if MissionConfig.endless_floor > 0:
			again.text = "PIANO %d  ›" % (MissionConfig.endless_floor + 1) if victory else "NUOVA SERIE"
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


# Rarita' scritta in una riga di premio ("MOSSA: CURA (RARA)"); -1 = nessuna (monete, materiali).
func _line_rarity(line: String) -> int:
	var up: String = line.to_upper()
	for i in range(BattleTypes.RARITIES.size() - 1, -1, -1):
		if str(BattleTypes.RARITIES[i]).to_upper() in up and (up.begins_with("MOSSA") or up.begins_with("PEZZO") or up.begins_with("PASSIVA")):
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
