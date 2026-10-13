extends Control

# Hub: da qui si parte in un click. CONTINUA rilancia la missione consigliata
# (o l'ultima scelta); le altre schermate sono a un passo. Niente scorrimenti.

var roster: Dictionary = {}
var continue_button: Button
var buttons: Dictionary = {}
var _status_panel: Control     # chiave -> Button (usati dai test)
var profile_card: ProfileCard
var profile_button: Button


func _ready() -> void:
	ScreenFrame.setup(self)   # riquadro 1280x720 nell'area sicura dello schermo
	if roster.is_empty():
		roster = RosterStore.load_or_new()
		if Objectives.ensure_today(roster):
			RosterStore.save(roster)
	else:
		Objectives.ensure_today(roster)
	_build()
	ArtLibrary.prefetch_team(roster["team"])
	ArtLibrary.prefetch_boss(str(MissionConfig.suggest(roster)["boss"]))
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
	menu.add_theme_constant_override("separation", 7 if TouchUi.active() else 14)
	menu.position = Vector2(60, 190)
	menu.size = Vector2(560, 440)
	add_child(menu)

	var next: Dictionary = MissionConfig.suggest(roster)
	continue_button = _menu_button(menu, "continue", "CONTINUA  ·  %s  ·  %s" % [MissionConfig.boss_title(str(next["boss"])), str(BattleContent.tier_of(int(next["tier"]))["name"])], "primary", 70, 24)
	_menu_button(menu, "missions", "SCEGLI MISSIONE", "normal", 56, 22)
	var can_pull: bool = int(roster["coins"]) >= Recruiting.SINGLE_COST
	_menu_button(menu, "roster", "SQUADRA E RECLUTAMENTO" + ("  ·  RECLUTA!" if can_pull else ""), "primary" if can_pull else "normal", 56, 22)
	var can_endless: bool = Endless.available(roster)
	var endless_text: String = "CICLO INFINITO  ·  RECORD PIANO %d" % Endless.best(roster) if can_endless else "CICLO INFINITO  ·  BATTI %d BERSAGLI" % Endless.UNLOCK_BOSSES
	var eb: Button = _menu_button(menu, "endless", endless_text, "normal", 56, 22)
	eb.disabled = not can_endless
	_menu_button(menu, "lobby", "MULTIPLAYER CO-OP", "normal", 56, 22)
	var ready_feats: int = Feats.claimable_count(roster)
	_menu_button(menu, "feats", "OBIETTIVI" + ("  ·  %d DA RISCUOTERE" % ready_feats if ready_feats > 0 else ""), "primary" if ready_feats > 0 else "normal", 56, 22)
	_menu_button(menu, "settings", "IMPOSTAZIONI", "normal", 44, 18)
	if not TouchUi.active():
		menu.add_child(BattleTheme.make_label("INVIO = CONTINUA   ·   1-7 = SCORCIATOIE   ·   M = MUTO", 13, BattleTheme.CY_DIM))

	var tip := BattleTheme.make_label("CONSIGLIO:  " + _tip(), 14, BattleTheme.CY_DIM)
	tip.position = Vector2(64, 688)
	tip.size = Vector2(590, 22)
	tip.clip_text = true
	add_child(tip)

	_build_status_panel()
	UiMotion.slide_in(buttons.values(), Vector2(-180, 0), 0.07, 0.3)
	UiMotion.slide_in([_status_panel], Vector2(120, 0), 0.0, 0.34)


const TIPS: Array = [
	"Colore vantaggioso = +50% di danno. Rosso > Verde > Blu > Rosso, Giallo <-> Viola.",
	"Due compagni che agiscono di fila formano un LEGAME: ogni anello da' piu' danno.",
	"Chi sta in BACK ROW recupera piu' energia. Il cambio e' gratis.",
	"Leggi sempre l'ALLARME: mostra la mossa del boss e chi colpira'.",
	"La GUARDIA dimezza i danni e ricarica le munizioni dei LibraCorp.",
	"Gli obiettivi danno icone rare per il profilo: controlla la schermata OBIETTIVI.",
	"Le icone leggendarie cadono (di rado) dai boss, piu' spesso a difficolta' alta.",
	"Nelle impostazioni puoi scegliere velocita', scosse, lampi e qualita' grafica.",
	"In multiplayer puoi scrivere ai compagni col tasto CHAT per coordinare le ultimate.",
	"Dopo 30 reclutamenti senza un epico o un leggendario, il successivo e' garantito.",
]


# Un consiglio al giorno (uno diverso a ogni apertura dell'hub, in ordine).
func _tip() -> String:
	var day: int = int(Time.get_unix_time_from_system() / 86400.0)
	return str(TIPS[(day + int(Time.get_ticks_msec() / 1000.0 / 60.0)) % TIPS.size()])


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
	_build_profile_card()
	var panel := HudPanel.new().setup("OPERATORE", BattleTheme.CY)
	panel.position = Vector2(680, 96)
	panel.size = Vector2(560, 600)
	add_child(panel)
	_status_panel = panel

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
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
		var face := PortraitView.new().setup(str(id), "icon")
		face.custom_minimum_size = Vector2(36, 36)
		unit_row.add_child(face)
		unit_row.move_child(face, 0)
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
		var tops: Array = []
		for t in Endless.top(roster):
			tops.append(str(int(t["floor"])))
		if tops.size() > 1:
			box.add_child(BattleTheme.make_label("MIGLIORI: " + " · ".join(tops), 13, BattleTheme.CY_DIM))
	if Daily.streak(roster) > 0 or Daily.done_today(roster):
		box.add_child(BattleTheme.make_label("SFIDA DEL GIORNO %s  SERIE %d" % ["✓" if Daily.done_today(roster) else "·", Daily.streak(roster)], 14, BattleTheme.OK if Daily.done_today(roster) else BattleTheme.POP))

	box.add_child(HSeparator.new())
	box.add_child(BattleTheme.make_label("OBIETTIVI DI OGGI  %d/%d" % [Objectives.completed(roster), Objectives.COUNT], 14, BattleTheme.CY_DIM))
	for o in roster["objectives"]["list"]:
		var done: bool = bool(o["done"])
		var txt: String = "%s %s  (%d/%d)" % ["[X]" if done else "[ ]", Objectives.describe(o), int(o["progress"]), int(o["goal"])]
		box.add_child(BattleTheme.make_label(txt, 16, BattleTheme.OK if done else BattleTheme.WH))


# Carta del profilo: toccandola si apre la finestra per cambiare nome, icona e banner.
func _build_profile_card() -> void:
	Profile.ensure_loaded()
	profile_card = ProfileCard.new().setup(Profile.current(), Vector2(560, 62), "TOCCA PER MODIFICARE IL PROFILO")
	profile_card.position = Vector2(680, 18)
	add_child(profile_card)
	profile_button = Button.new()
	profile_button.flat = true
	profile_button.focus_mode = Control.FOCUS_NONE
	profile_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	profile_button.pressed.connect(_on_profile)
	profile_card.add_child(profile_button)


func _on_profile() -> void:
	var panel := ProfilePanel.open(self)
	panel.changed.connect(func() -> void: profile_card.update_data(Profile.current(), "TOCCA PER MODIFICARE IL PROFILO"))


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
		if c is SettingsPanel or c is ProfilePanel or c is ConfirmBox:      # con una finestra aperta le scorciatoie dell'hub tacciono
			return
	match event.keycode:
		KEY_ESCAPE:
			ExitGuard.ask(self)
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
