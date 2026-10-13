extends Control

# Scelta della missione: boss e livello di difficolta'. I blocchi seguono i
# progressi salvati nella collezione (RosterState.cleared).

var roster: Dictionary = {}
var selected_boss: String = "distributore"
var selected_tier: int = 0
var boss_buttons: Dictionary = {}
var tier_buttons: Array = []
var go_button: Button
var daily_button: Button
var info_label: Label
var _desc_label: Label
var _boss_title: Label
var _boss_sub: Label


func _ready() -> void:
	ScreenFrame.setup(self)   # riquadro 1280x720 nell'area sicura dello schermo
	if roster.is_empty():
		roster = RosterStore.load_or_new()
	# Si apre sulla missione consigliata: il primo boss non ancora finito.
	var next: Dictionary = MissionConfig.suggest(roster)
	selected_boss = str(next["boss"])
	selected_tier = int(next["tier"])
	_build()
	select_boss(selected_boss)


func _build() -> void:
	ScreenFx.solid(self, BattleTheme.BK)
	ScreenFx.menu_overlays(self, BattleTheme.RD)

	var title := BattleTheme.make_label("SELEZIONE MISSIONE", 34, BattleTheme.CY, true)
	title.position = Vector2(40, 24)
	add_child(title)

	# Elenco dei boss
	var list_panel := HudPanel.new().setup("BERSAGLI", BattleTheme.CY)
	list_panel.position = Vector2(40, 90)
	list_panel.size = Vector2(380, 520)
	add_child(list_panel)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list_panel.set_content(list)
	for id in BattleContent.BOSS_ORDER:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 48)
		b.pressed.connect(select_boss.bind(id))
		list.add_child(b)
		boss_buttons[id] = b

	# Dettagli
	var det := HudPanel.new().setup("DOSSIER", BattleTheme.RD)
	det.position = Vector2(440, 90)
	det.size = Vector2(800, 520)
	add_child(det)
	var dbox := VBoxContainer.new()
	dbox.add_theme_constant_override("separation", 5 if TouchUi.active() else 10)
	det.set_content(dbox)
	_boss_title = BattleTheme.make_label("", 30, BattleTheme.RD, true)
	dbox.add_child(_boss_title)
	_boss_sub = BattleTheme.make_label("", 14, BattleTheme.CY)
	_boss_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_boss_sub.custom_minimum_size = Vector2(740, 0)
	dbox.add_child(_boss_sub)
	_desc_label = BattleTheme.make_label("", 17, BattleTheme.WH)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(740, 56)
	dbox.add_child(_desc_label)
	dbox.add_child(BattleTheme.make_label("LIVELLO DI MINACCIA", 15, BattleTheme.CY))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	dbox.add_child(row)
	for i in BattleContent.TIERS.size():
		var tb := Button.new()
		tb.custom_minimum_size = Vector2(0, 54)
		tb.clip_text = true
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.pressed.connect(select_tier.bind(i))
		row.add_child(tb)
		tier_buttons.append(tb)
	info_label = BattleTheme.make_label("", 16, BattleTheme.CY)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = Vector2(740, 52)
	dbox.add_child(info_label)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dbox.add_child(sp)
	var story_button := Button.new()
	story_button.text = "RIVEDI LA SCENA INIZIALE"
	story_button.custom_minimum_size = Vector2(0, 36)
	BattleTheme.style_button(story_button, "normal", 16)
	story_button.pressed.connect(_on_replay_story)
	dbox.add_child(story_button)
	var dboss: String = Daily.boss_for(roster)
	var dmod: Dictionary = Daily.mod_for()
	daily_button = Button.new()
	daily_button.text = "SFIDA DEL GIORNO  ·  %s  ·  %s  ·  %s" % [MissionConfig.boss_title(dboss), str(dmod["name"]), ("BONUS RISCOSSO" if Daily.done_today(roster) else "x%.1f  ·  SERIE %d" % [Daily.reward_mult(roster), Daily.streak(roster)])]
	daily_button.custom_minimum_size = Vector2(0, 44)
	daily_button.clip_text = true
	BattleTheme.style_button(daily_button, "normal", 16)
	daily_button.pressed.connect(_on_daily)
	dbox.add_child(daily_button)
	go_button = Button.new()
	go_button.text = "AVVIA MISSIONE"
	go_button.custom_minimum_size = Vector2(0, 56)
	BattleTheme.style_button(go_button, "primary", 28)
	go_button.pressed.connect(_on_go)
	dbox.add_child(go_button)

	UiMotion.slide_in([list_panel], Vector2(-140, 0), 0.0, 0.3)
	UiMotion.slide_in([det], Vector2(140, 0), 0.0, 0.34)
	add_child(_hint("INVIO avvia  ·  1-8 bersaglio  ·  SU/GIU difficolta'  ·  ESC indietro", Vector2(440, 640)))

	var back := Button.new()
	back.text = "TORNA ALL'HUB"
	back.position = Vector2(40, 630)
	back.size = Vector2(380, 54)
	BattleTheme.style_button(back, "normal", 20)
	back.pressed.connect(_on_back)
	add_child(back)


func select_boss(id: String) -> bool:
	if not BattleContent.BOSSES.has(id) or not RosterState.is_boss_unlocked(roster, id):
		return false
	selected_boss = id
	if not RosterState.is_tier_unlocked(roster, id, selected_tier):
		selected_tier = 0
	_refresh()
	return true


func select_tier(t: int) -> bool:
	if t < 0 or t >= BattleContent.TIERS.size() or not RosterState.is_tier_unlocked(roster, selected_boss, t):
		return false
	selected_tier = t
	_refresh()
	return true


func _refresh() -> void:
	for id in boss_buttons:
		var b: Button = boss_buttons[id]
		var boss: Dictionary = BattleContent.BOSSES[id]
		var open: bool = RosterState.is_boss_unlocked(roster, id)
		var cleared: int = RosterState.cleared_tiers(roster, id)
		if open:
			b.text = "%s   [%d/%d]" % [str(boss["name"]).to_upper(), cleared, BattleContent.TIERS.size()]
		else:
			b.text = "??? BLOCCATO"
		b.disabled = not open
		BattleTheme.style_button(b, "primary" if id == selected_boss else "normal", 20)
	var boss: Dictionary = BattleContent.BOSSES[selected_boss]
	_boss_title.text = str(boss["name"]).to_upper()
	_boss_sub.text = str(boss["title"]).to_upper()
	_desc_label.text = str(boss["desc"])
	for i in tier_buttons.size():
		var tb: Button = tier_buttons[i]
		var t: Dictionary = BattleContent.TIERS[i]
		var open: bool = RosterState.is_tier_unlocked(roster, selected_boss, i)
		tb.text = str(t["name"]) if open else "%s [X]" % str(t["name"])
		tb.disabled = not open
		BattleTheme.style_button(tb, "primary" if i == selected_tier else "normal", 18)
	var session: Node = get_node_or_null("/root/NetSession")
	var in_room: bool = session != null and session.get("manager") != null
	go_button.disabled = in_room
	go_button.text = "ESCI DALLA STANZA PER GIOCARE DA SOLO" if in_room else "AVVIA MISSIONE"
	var tier: Dictionary = BattleContent.TIERS[selected_tier]
	info_label.text = "PV x%.1f   ATTACCO x%.2f   DIFESA +%d   PREMI x%.1f" % [float(tier["hp"]), float(tier["atk"]), int(tier["def"]), float(tier["reward"])]
	if selected_tier + 1 < BattleContent.TIERS.size() and not RosterState.is_tier_unlocked(roster, selected_boss, selected_tier + 1):
		info_label.text += "\nBatti questo livello per sbloccare il successivo."


func _on_go() -> void:
	Story.start_mission(self, selected_boss, selected_tier)


func _on_daily() -> void:
	Daily.start(roster)


func _on_replay_story() -> void:
	var view: DialogueView = Story.play(self, Story.scene_id(selected_boss, "pre"), false)
	if view == null:
		Notify.warning("Nessuna scena per questo bersaglio.")


func _on_back() -> void:
	SceneRouter.go("hub")


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE:
			_on_back()
		KEY_ENTER, KEY_KP_ENTER:
			if not go_button.disabled:
				_on_go()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
			select_boss(str(BattleContent.BOSS_ORDER[int(event.keycode) - int(KEY_1)]))
		KEY_UP:
			select_tier(selected_tier - 1)
		KEY_DOWN:
			select_tier(selected_tier + 1)


func _hint(text: String, pos: Vector2) -> Label:
	var l := BattleTheme.make_label(text, 13, BattleTheme.CY_DARK)
	l.position = pos
	return l
