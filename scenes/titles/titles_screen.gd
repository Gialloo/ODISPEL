class_name TitlesScreen
extends Control

# Schermata TITOLI E POTERE: i titoli epici/leggendari (bonus permanenti dell'account) e il potere di ogni personaggio.

var roster: Dictionary = {}
var save_path: String = RosterStore.DEFAULT_PATH
var tab: String = "TITOLI"
var tab_buttons: Dictionary = {}
var _list: VBoxContainer
var _head: Label
var _sub: Label
var _delta_text: String = ""


func _ready() -> void:
	ScreenFrame.setup(self)
	if roster.is_empty():
		roster = RosterStore.load_or_new(save_path)
	var d: int = Power.delta(roster, Profile.owned_icons())
	if d != 0:
		_delta_text = "  (%s%d dall'ultima visita)" % ["+" if d > 0 else "", d]
	_build()
	refresh()
	Power.mark_seen(roster, Profile.owned_icons())
	RosterStore.save(roster, save_path)


func _build() -> void:
	ScreenFx.solid(self, BattleTheme.BK)
	var title := BattleTheme.make_label("TITOLI E POTERE", 40, BattleTheme.WH, true)
	title.position = Vector2(24, 10)
	add_child(title)
	_sub = BattleTheme.make_label("", 15, BattleTheme.CY_DIM)
	_sub.position = Vector2(28, 62)
	_sub.size = Vector2(1220, 22)
	add_child(_sub)
	_head = BattleTheme.make_label("", 22, BattleTheme.GOLD, true)
	_head.position = Vector2(560, 14)
	_head.size = Vector2(700, 30)
	_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_head)
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(24, 92)
	tabs.size = Vector2(1232, 46)
	tabs.add_theme_constant_override("separation", 8)
	add_child(tabs)
	for g in ["TITOLI", "POTERE DEI PERSONAGGI"]:
		var b := Button.new()
		b.text = g
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 40)
		BattleTheme.style_button(b, "normal", 18)
		b.pressed.connect(show_tab.bind(g))
		tabs.add_child(b)
		tab_buttons[g] = b
	var panel := HudPanel.new().setup("ELENCO", BattleTheme.CY)
	panel.position = Vector2(20, 158)
	panel.size = Vector2(1240, 456 if not TouchUi.active() else 430)
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)
	panel.set_content(scroll)
	var back := Button.new()
	back.text = "TORNA AGLI OBIETTIVI"
	back.position = Vector2(24, 620 if TouchUi.active() else 664)
	back.size = Vector2(300, 44)
	BattleTheme.style_button(back, "normal", 20)
	back.pressed.connect(func() -> void: SceneRouter.go("feats"))
	add_child(back)
	ScreenFx.menu_overlays(self, BattleTheme.RD)


func show_tab(t: String) -> void:
	tab = t
	refresh()


func refresh() -> void:
	if _list == null:
		return
	var icons: Array = Profile.owned_icons()
	_head.text = "POTERE ACCOUNT %d%s" % [Power.account(roster, icons), _delta_text]
	for g in tab_buttons:
		BattleTheme.style_button(tab_buttons[g], "primary" if str(g) == tab else "normal", 18)
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	if tab == "TITOLI":
		_sub.text = "// BONUS PERMANENTI PER TUTTI I PERSONAGGI  ·  CONTA IL TITOLO PIU' ALTO DI OGNI LINEA  ·  OTTENUTI IN AUTOMATICO"
		_fill_titles(icons)
	else:
		_sub.text = "// POTERE = PV, ATTACCO, DIFESA E VELOCITA' MESSI INSIEME  ·  SQUADRA %d" % Power.team(roster, icons)
		_fill_power(icons)


func _fill_titles(icons: Array) -> void:
	var items: Array = Titles.all().duplicate()
	var act: Array = Titles.active(roster, icons)
	var act_ids: Array = act.map(func(t: Variant) -> String: return str(t["id"]))
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ea: int = 1 if Titles.is_earned(roster, a, icons) else 0
		var eb: int = 1 if Titles.is_earned(roster, b, icons) else 0
		if ea != eb:
			return ea > eb
		if int(a["rarity"]) != int(b["rarity"]):
			return int(a["rarity"]) > int(b["rarity"])
		return str(a["id"]) < str(b["id"]))
	for t in items:
		_list.add_child(_title_row(t, icons, act_ids))


func _title_row(t: Dictionary, icons: Array, act_ids: Array) -> Control:
	var got: bool = Titles.is_earned(roster, t, icons)
	var live: bool = act_ids.has(str(t["id"]))
	var col: Color = Profile.RARITY_COLORS[int(t["rarity"])]
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 58)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.03, 0.09, 0.11) if got else Color(0.03, 0.04, 0.05)
	box.border_color = col if got else Color(0.2, 0.25, 0.28)
	box.set_border_width_all(2)
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 3.0
	box.content_margin_bottom = 3.0
	panel.add_theme_stylebox_override("panel", box)
	panel.set_meta("title_id", str(t["id"]))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	text.add_child(BattleTheme.make_label("%s  ·  %s" % [str(t["name"]).to_upper(), Titles.rarity_name(t)], 18, col if got else BattleTheme.CY_DIM, true))
	text.add_child(BattleTheme.make_label(str(t["desc"]), 13, BattleTheme.CY if got else BattleTheme.CY_DIM))
	var bonus := BattleTheme.make_label(Titles.bonus_text(t), 14, BattleTheme.GOLD if got else BattleTheme.CY_DIM)
	bonus.custom_minimum_size = Vector2(380, 0)
	bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bonus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(bonus)
	var state := BattleTheme.make_label("", 15, BattleTheme.WH, true)
	state.custom_minimum_size = Vector2(150, 0)
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if live:
		state.text = "ATTIVO"
		state.add_theme_color_override("font_color", BattleTheme.OK)
	elif got:
		state.text = "SUPERATO"
		state.add_theme_color_override("font_color", BattleTheme.CY_DIM)
	else:
		state.text = "%d / %d" % [mini(Titles.value(roster, t, icons), int(t["goal"])), int(t["goal"])]
	row.add_child(state)
	return panel


func _fill_power(icons: Array) -> void:
	var ids: Array = roster["characters"].keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var pa: int = Power.of_character(roster, a, icons)
		var pb: int = Power.of_character(roster, b, icons)
		if pa != pb:
			return pa > pb
		return a < b)
	for id in ids:
		_list.add_child(_power_row(str(id), icons))


func _power_row(id: String, icons: Array) -> Control:
	var e: Dictionary = roster["characters"][id]
	var def: Dictionary = BattleContent.CHARACTERS[id]
	var bd: Dictionary = Power.breakdown(roster, id, icons)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 54)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.03, 0.09, 0.11)
	box.border_color = BattleTheme.unit_color(str(def["color"]))
	box.set_border_width_all(2)
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 3.0
	box.content_margin_bottom = 3.0
	panel.add_theme_stylebox_override("panel", box)
	panel.set_meta("char_id", id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	text.add_child(BattleTheme.make_label("%s  ·  LIV %d  ·  RANK %d" % [str(def["name"]).to_upper(), int(e["level"]), int(e["rank"])], 18, BattleTheme.WH, true))
	text.add_child(BattleTheme.make_label("BASE %d   LIVELLO +%d   RANK +%d   EQUIP. +%d   TITOLI +%d" % [bd["base"], bd["level"], bd["rank"], bd["gear"], bd["titles"]], 13, BattleTheme.CY))
	var tn := BattleTheme.make_label(Power.tier_name(int(bd["total"])), 14, BattleTheme.CY_DIM)
	tn.custom_minimum_size = Vector2(110, 0)
	tn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(tn)
	var pw := BattleTheme.make_label("%d" % int(bd["total"]), 28, BattleTheme.GOLD, true)
	pw.custom_minimum_size = Vector2(110, 0)
	pw.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pw.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(pw)
	return panel
