extends Control

# Hub: da qui si parte in un click. CONTINUA rilancia la missione consigliata
# (o l'ultima scelta); le altre schermate sono a un passo. Niente scorrimenti.

var roster: Dictionary = {}
var continue_button: Button
var buttons: Dictionary = {}
var _status_panel: Control     # chiave -> Button (usati dai test)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var window: Window = get_window()
	if window != null:
		window.content_scale_size = Vector2i(1280, 720)
	if roster.is_empty():
		roster = RosterStore.load_or_new()
		if Objectives.ensure_today(roster):
			RosterStore.save(roster)
	else:
		Objectives.ensure_today(roster)
	_build()
	Warmup.scenes(scene_file_path)
	Warmup.shaders(self)


# ---------- Costruzione ----------

func _build() -> void:
	ScreenFx.solid(self, BattleTheme.BK)

	var hub_art: Texture2D = ArtLibrary.background("hub")
	if hub_art != null:
		var pic := TextureRect.new()
		pic.texture = hub_art
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pic)

	ScreenFx.menu_overlays(self, BattleTheme.RD)

	var title := OdispelLogo.new()
	title.position = Vector2(60, 24)
	add_child(title)
	add_child(_at(BattleTheme.make_label("MISSION CONTROL  ·  v" + GameConfig.VERSION, 16, BattleTheme.CY_DIM), Vector2(64, 136)))

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 14)
	menu.position = Vector2(60, 190)
	menu.size = Vector2(560, 440)
	add_child(menu)

	var next: Dictionary = MissionConfig.suggest(roster)
	continue_button = _menu_button(menu, "continue", "CONTINUA  ·  %s  ·  %s" % [MissionConfig.boss_title(str(next["boss"])), str(BattleContent.tier_of(int(next["tier"]))["name"])], "primary", 70, 24)
	_menu_button(menu, "missions", "SCEGLI MISSIONE", "normal", 56, 22)
	_menu_button(menu, "roster", "SQUADRA E RECLUTAMENTO", "normal", 56, 22)
	var can_endless: bool = Endless.available(roster)
	var endless_text: String = "CICLO INFINITO  ·  RECORD PIANO %d" % Endless.best(roster) if can_endless else "CICLO INFINITO  ·  BATTI %d BERSAGLI" % Endless.UNLOCK_BOSSES
	var eb: Button = _menu_button(menu, "endless", endless_text, "normal", 56, 22)
	eb.disabled = not can_endless
	_menu_button(menu, "lobby", "MULTIPLAYER CO-OP", "normal", 56, 22)
	var ready_feats: int = Feats.claimable_count(roster)
	_menu_button(menu, "feats", "OBIETTIVI" + ("  ·  %d DA RISCUOTERE" % ready_feats if ready_feats > 0 else ""), "primary" if ready_feats > 0 else "normal", 56, 22)
	_menu_button(menu, "settings", "IMPOSTAZIONI", "normal", 44, 18)
	menu.add_child(BattleTheme.make_label("INVIO = CONTINUA   ·   1-7 = SCORCIATOIE   ·   M = MUTO", 13, BattleTheme.CY_DIM))

	_build_status_panel()
	UiMotion.slide_in(buttons.values(), Vector2(-180, 0), 0.07, 0.3)
	UiMotion.slide_in([_status_panel], Vector2(120, 0), 0.0, 0.34)


func _at(c: Control, pos: Vector2) -> Control:
	c.position = pos
	return c


func _menu_button(parent: Control, key: String, text: String, kind: String, height: float, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, height)
	BattleTheme.style_button(b, kind, size)
	b.pressed.connect(_on_menu.bind(key))
	parent.add_child(b)
	buttons[key] = b
	return b


# Pannello con tutto cio' che serve sapere prima di giocare.
func _build_status_panel() -> void:
	var panel := HudPanel.new().setup("OPERATORE", BattleTheme.CY)
	panel.position = Vector2(680, 60)
	panel.size = Vector2(560, 560)
	add_child(panel)
	_status_panel = panel

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.set_content(box)

	box.add_child(BattleTheme.make_label("RISORSE", 14, BattleTheme.CY_DIM))
	var mats: Dictionary = roster["materials"]
	var res_row := HBoxContainer.new()
	res_row.add_theme_constant_override("separation", 26)
	for entry in [["coin", "MONETE %d" % int(roster["coins"])], ["nucleo", "NUCLEI %d" % int(mats.get("nucleo", 0))], ["lega", "LEGHE %d" % int(mats.get("lega", 0))]]:
		res_row.add_child(GameIcon.line(str(entry[0]), GameIcon.currency_color(str(entry[0])), str(entry[1]), 20))
	box.add_child(res_row)

	box.add_child(HSeparator.new())
	box.add_child(BattleTheme.make_label("SQUADRA ATTIVA", 14, BattleTheme.CY_DIM))
	for id in roster["team"]:
		var c: Dictionary = roster["characters"][id]
		var def: Dictionary = BattleContent.CHARACTERS[str(id)]
		var ucol: Color = BattleTheme.unit_color(str(def["color"]))
		var unit_row: HBoxContainer = GameIcon.line(str(def["cls"]), ucol, "%s   LV%d   %s" % [str(def["name"]).to_upper(), int(c["level"]), str(def["cls"]).to_upper()], 18, ucol)
		var fac: String = BattleContent.faction_of(str(id))
		if fac != "":
			unit_row.add_child(GameIcon.new().setup(fac, Hints.faction_color(fac), 22.0))
			unit_row.add_child(BattleTheme.make_label(Factions.name_of(fac).to_upper(), 14, Hints.faction_color(fac)))
		box.add_child(unit_row)

	box.add_child(HSeparator.new())
	box.add_child(BattleTheme.make_label("PROGRESSI", 14, BattleTheme.CY_DIM))
	var locked: int = 0
	for boss_id in BattleContent.BOSS_ORDER:
		if not RosterState.is_boss_unlocked(roster, str(boss_id)):
			locked += 1
			continue
		var cleared: int = RosterState.cleared_tiers(roster, str(boss_id))
		box.add_child(BattleTheme.make_label("%-12s %s" % [MissionConfig.boss_title(str(boss_id)), _pips(cleared)], 17, BattleTheme.CY))
	if locked > 0:
		box.add_child(BattleTheme.make_label("+ %d BERSAGLI DA SBLOCCARE" % locked, 15, BattleTheme.CY_DIM))

	if Endless.available(roster) and Endless.best(roster) > 0:
		box.add_child(BattleTheme.make_label("%-12s PIANO %d" % ["INFINITO", Endless.best(roster)], 17, BattleTheme.POP))

	box.add_child(HSeparator.new())
	box.add_child(BattleTheme.make_label("OBIETTIVI DI OGGI  %d/%d" % [Objectives.completed(roster), Objectives.COUNT], 14, BattleTheme.CY_DIM))
	for o in roster["objectives"]["list"]:
		var done: bool = bool(o["done"])
		var txt: String = "%s %s  (%d/%d)" % ["[X]" if done else "[ ]", Objectives.describe(o), int(o["progress"]), int(o["goal"])]
		box.add_child(BattleTheme.make_label(txt, 16, BattleTheme.OK if done else BattleTheme.WH))


func _pips(cleared: int) -> String:
	var out: String = ""
	for i in BattleContent.TIERS.size():
		out += "■ " if i < cleared else "□ "
	return out


# ---------- Azioni ----------

func _on_menu(key: String) -> void:
	match key:
		"continue":
			var next: Dictionary = MissionConfig.suggest(roster)
			Story.start_mission(self, str(next["boss"]), int(next["tier"]))
		"settings":
			SettingsPanel.open(self)
		"endless":
			if Endless.available(roster):
				Endless.start(1)
		_:
			SceneRouter.go(key)


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	for c in get_children():
		if c is SettingsPanel:      # con la finestra aperta le scorciatoie dell'hub tacciono
			return
	match event.keycode:
		KEY_ENTER, KEY_KP_ENTER, KEY_1:
			_on_menu("continue")
		KEY_2:
			_on_menu("missions")
		KEY_3:
			_on_menu("roster")
		KEY_4:
			_on_menu("lobby")
		KEY_5:
			_on_menu("settings")
		KEY_6:
			_on_menu("feats")
		KEY_7:
			_on_menu("endless")
