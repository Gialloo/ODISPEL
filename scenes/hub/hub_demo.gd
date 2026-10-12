extends Control

# Hub: da qui si parte in un click. CONTINUA rilancia la missione consigliata
# (o l'ultima scelta); le altre schermate sono a un passo. Niente scorrimenti.

var roster: Dictionary = {}
var continue_button: Button
var buttons: Dictionary = {}     # chiave -> Button (usati dai test)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var window: Window = get_window()
	if window != null:
		window.content_scale_size = Vector2i(1280, 720)
	if roster.is_empty():
		roster = RosterStore.load_or_new()
	_build()


# ---------- Costruzione ----------

func _build() -> void:
	var background := ColorRect.new()
	background.color = BattleTheme.BK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var cctv := ColorRect.new()
	cctv.set_anchors_preset(Control.PRESET_FULL_RECT)
	cctv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/cctv_overlay.gdshader")
	cctv.material = mat
	add_child(cctv)

	var title := BattleTheme.make_label("ODISPEL", 64, BattleTheme.WH, true)
	title.position = Vector2(60, 40)
	add_child(title)
	add_child(_at(BattleTheme.make_label("MISSION CONTROL  ·  v" + GameConfig.VERSION, 16, BattleTheme.CY_DIM), Vector2(64, 124)))

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 14)
	menu.position = Vector2(60, 190)
	menu.size = Vector2(560, 440)
	add_child(menu)

	var next: Dictionary = MissionConfig.suggest(roster)
	continue_button = _menu_button(menu, "continue", "CONTINUA  ·  %s  ·  %s" % [MissionConfig.boss_title(str(next["boss"])), str(BattleContent.tier_of(int(next["tier"]))["name"])], "primary", 70, 24)
	_menu_button(menu, "missions", "SCEGLI MISSIONE", "normal", 56, 22)
	_menu_button(menu, "roster", "SQUADRA E RECLUTAMENTO", "normal", 56, 22)
	_menu_button(menu, "lobby", "MULTIPLAYER CO-OP", "normal", 56, 22)
	_menu_button(menu, "settings", "IMPOSTAZIONI", "normal", 44, 18)
	menu.add_child(BattleTheme.make_label("INVIO = CONTINUA   ·   1-5 = SCORCIATOIE   ·   M = MUTO", 13, BattleTheme.CY_DARK))

	_build_status_panel()


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

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.set_content(box)

	box.add_child(BattleTheme.make_label("RISORSE", 14, BattleTheme.CY_DIM))
	var mats: Dictionary = roster["materials"]
	box.add_child(BattleTheme.make_label("MONETE %d     NUCLEI %d     LEGHE %d" % [int(roster["coins"]), int(mats.get("nucleo", 0)), int(mats.get("lega", 0))], 20, BattleTheme.WH))

	box.add_child(HSeparator.new())
	box.add_child(BattleTheme.make_label("SQUADRA ATTIVA", 14, BattleTheme.CY_DIM))
	for id in roster["team"]:
		var c: Dictionary = roster["characters"][id]
		var def: Dictionary = BattleContent.CHARACTERS[str(id)]
		box.add_child(BattleTheme.make_label("%s   LV%d   %s" % [str(def["name"]).to_upper(), int(c["level"]), str(def["cls"]).to_upper()], 18, BattleTheme.unit_color(str(def["color"]))))

	box.add_child(HSeparator.new())
	box.add_child(BattleTheme.make_label("PROGRESSI", 14, BattleTheme.CY_DIM))
	for boss_id in BattleContent.BOSS_ORDER:
		var open: bool = RosterState.is_boss_unlocked(roster, str(boss_id))
		var cleared: int = RosterState.cleared_tiers(roster, str(boss_id))
		var line: String = "%-12s %s" % [MissionConfig.boss_title(str(boss_id)), _pips(cleared) if open else "BLOCCATO"]
		box.add_child(BattleTheme.make_label(line, 17, BattleTheme.CY if open else BattleTheme.CY_DARK))


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
			MissionConfig.set_mission(str(next["boss"]), int(next["tier"]))
			SceneRouter.go("battle", true)
		"settings":
			SettingsPanel.open(self)
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
