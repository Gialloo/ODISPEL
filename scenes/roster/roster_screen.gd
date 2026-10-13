extends Control

# Squadra e reclutamento: collezione, composizione della squadra da 3,
# potenziamento dei personaggi e reclutamento (singolo / x10).
# Ogni modifica viene salvata subito su save_path.

const RARITY_COLORS: Array = [Color("#c9dde2"), BattleTheme.CY, BattleTheme.UNIT_COLORS["viola"], BattleTheme.GOLD]  # = BattleTheme.rarity_color

var roster: Dictionary = {}
var save_path: String = RosterStore.DEFAULT_PATH
const EQUIP_SLOTS: Array = [
	["skill0", "SKILL 1"], ["skill1", "SKILL 2"], ["ult", "ULTIMATE"],
	["passive0", "PASSIVA 1"], ["passive1", "PASSIVA 2"],
	["arma", "ARMA"], ["petto", "PETTO"], ["stivali", "STIVALI"],
]

var tab: String = "squadra"          # "squadra" | "equip" | "reclutamento"
var equip_slot: String = "skill0"
var selected: String = ""            # personaggio mostrato nella scheda
var slot_target: int = 2             # posto della squadra sostituito quando e' piena
var status_text: String = ""
var last_results: Array = []
var next_seed: int = 0               # 0 = casuale; i test lo fissano

var _coins_label: Label
var _mats_label: Label
var _lega_label: Label
var _status_label: Label
var _tab_buttons: Dictionary = {}
var guide_button: Button
var strategy_button: Button
var archive_button: Button
var legend_button: Button
var _team_page: Control
var _recruit_page: Control
var banner: String = "standard"        # banner di reclutamento scelto (vedi Recruiting.BANNERS)
var banner_buttons: Dictionary = {}
var _banner_note: Label
var _equip_page: Control
var _equip_name: Label
var _equip_info: Label
var _equip_icons: HBoxContainer
var _detail_icons: HBoxContainer
var _equip_portrait: PortraitView
var _equip_slots_box: VBoxContainer
var _equip_list: VBoxContainer
var _equip_action: HBoxContainer
var _equip_title: HudPanel
var _pity_bar: ProgressBar
var _list_box: GridContainer
var _filter_rarity: int = 0        # 0 = tutte, altrimenti rarita' + 1
var _filter_faction: int = 0       # 0 = tutte, altrimenti indice in Factions.ORDER + 1
var _filter_level: int = 0         # 0 = tutti, 1.. = fasce di livello (vedi LEVEL_BANDS)
var _filter_color: int = 0         # 0 = tutti, altrimenti indice in COLOR_ORDER + 1
const LEVEL_BANDS: Array = [[1, 9], [10, 24], [25, 39], [40, 50]]
const COLOR_ORDER: Array = ["rosso", "verde", "blu", "giallo", "viola"]
var _slots_box: HBoxContainer
var _detail_label: Label
var _detail_portrait: PortraitView
var _detail_title: Label
var _action_box: GridContainer
var _pity_label: Label
var _results_box: VBoxContainer
var _pull_buttons: Array = []
var _reveal_rows: bool = false      # le righe dell'esito entrano animate solo subito dopo un reclutamento
var _t: float = 0.0


func _ready() -> void:
	ScreenFrame.setup(self)   # riquadro 1280x720 nell'area sicura dello schermo
	if roster.is_empty():
		roster = RosterStore.load_or_new(save_path)
	_build()
	if selected == "" or not RosterState.owns(roster, selected):
		selected = str(roster["team"][0]) if not roster["team"].is_empty() else ""
	refresh()


# ---------- Costruzione ----------

func _build() -> void:
	ScreenFx.solid(self, BattleTheme.BK)
	var bg_end: int = get_child_count()

	var title := BattleTheme.make_label("ARCHIVIO OPERATORI", 40, BattleTheme.WH, true)
	title.position = Vector2(24, 10)
	add_child(title)
	var sub := BattleTheme.make_label("// SQUADRA E RECLUTAMENTO", 15, BattleTheme.CY_DIM)
	sub.position = Vector2(28, 62)
	add_child(sub)

	# le tre risorse in una riga, stesso font (Archivo Black MAIUSCOLO) e stessa larghezza
	_coins_label = _header_resource("coin", 720.0)
	_mats_label = _header_resource("nucleo", 900.0)
	_lega_label = _header_resource("lega", 1080.0)

	var x: float = 24.0
	for entry in [["squadra", "SQUADRA"], ["equip", "EQUIPAGGIO"], ["reclutamento", "RECLUTAMENTO"]]:
		var b := Button.new()
		b.text = str(entry[1])
		b.position = Vector2(x, 90)
		b.size = Vector2(230, 40)
		BattleTheme.style_button(b, "normal", 20)
		b.pressed.connect(show_tab.bind(str(entry[0])))
		add_child(b)
		_tab_buttons[str(entry[0])] = b
		x += 242.0

	var strat := Button.new()
	strat.text = "STRATEGIE"
	strat.position = Vector2(x, 90)
	strat.size = Vector2(230, 40)
	BattleTheme.style_button(strat, "primary", 20)
	strat.pressed.connect(open_strategy_guide)
	add_child(strat)
	strategy_button = strat

	var arch := Button.new()
	arch.text = "ARCHIVIO"
	arch.position = Vector2(x + 242.0, 90)
	arch.size = Vector2(230, 40)
	BattleTheme.style_button(arch, "normal", 20)
	arch.pressed.connect(open_archive)
	add_child(arch)
	archive_button = arch

	_build_team_page()
	_build_equip_page()
	_build_recruit_page()

	var back := Button.new()
	back.text = "TORNA ALL'HUB"
	back.position = Vector2(24, 654 if TouchUi.active() else 664)
	back.size = Vector2(250, 64 if TouchUi.active() else 44)
	BattleTheme.style_button(back, "normal", 20)
	back.pressed.connect(_on_back)
	add_child(back)

	_status_label = BattleTheme.make_label("", 16, BattleTheme.WH)
	_status_label.position = Vector2(296, 674)
	_status_label.size = Vector2(960, 28)
	add_child(_status_label)

	# velo e pioggia stanno DIETRO ai pannelli: le immagini degli operatori restano con i loro colori e senza righe sopra
	var n_before: int = get_child_count()
	ScreenFx.menu_overlays(self, BattleTheme.RD)
	for i in range(get_child_count() - n_before):
		move_child(get_child(n_before + i), bg_end + i)


func _header_icon(key: String, pos: Vector2, px: float) -> void:
	var ic := GameIcon.new().setup(key, GameIcon.currency_color(key), px)
	ic.position = pos
	add_child(ic)


# Sul telefono le liste lunghe si scorrono con il dito; sul PC restano com'erano.
func _set_scrolled(panel: HudPanel, box: Container) -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	panel.set_content(scroll)


# Collezione: sopra la griglia quattro filtri (rarita', fazione, livello, colore); la griglia scorre sotto.
func _set_filtered(panel: HudPanel, box: Container) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	col.add_child(row)
	var rar: Array = ["Rarita'"]
	for r in BattleTypes.RARITIES:
		rar.append(str(r).capitalize())
	var fac: Array = ["Fazione"]
	for f in Factions.ORDER:
		fac.append(str(Factions.FACTIONS[f]["name"]))
	var lev: Array = ["Livello"]
	for b in LEVEL_BANDS:
		lev.append("Lv %d-%d" % [int(b[0]), int(b[1])])
	var colr: Array = ["Colore"]
	for c in COLOR_ORDER:
		colr.append(str(c).capitalize())
	for spec in [["rarity", rar], ["faction", fac], ["level", lev], ["color", colr]]:
		var ob := OptionButton.new()
		for it in spec[1]:
			ob.add_item(str(it))
		BattleTheme.style_button(ob, "normal", 13)
		ob.custom_minimum_size = Vector2(0, 38 if TouchUi.active() else 28)
		ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ob.fit_to_longest_item = false
		ob.item_selected.connect(_on_filter.bind(str(spec[0])))
		row.add_child(ob)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	col.add_child(scroll)
	panel.set_content(col)


func _on_filter(index: int, which: String) -> void:
	match which:
		"rarity":
			_filter_rarity = index
		"faction":
			_filter_faction = index
		"level":
			_filter_level = index
		"color":
			_filter_color = index
	_refresh_list()


# Un operatore passa i filtri attivi? (il livello vale solo per chi e' stato reclutato)
func _passes_filters(id: String) -> bool:
	var def: Dictionary = BattleContent.CHARACTERS[id]
	if _filter_rarity > 0 and int(def["rarity"]) != _filter_rarity - 1:
		return false
	if _filter_faction > 0 and str(def.get("faction", "")) != str(Factions.ORDER[_filter_faction - 1]):
		return false
	if _filter_color > 0 and str(def.get("color", "")) != str(COLOR_ORDER[_filter_color - 1]):
		return false
	if _filter_level > 0:
		if not RosterState.owns(roster, id):
			return false
		var lv: int = int(roster["characters"][id]["level"])
		var band: Array = LEVEL_BANDS[_filter_level - 1]
		if lv < int(band[0]) or lv > int(band[1]):
			return false
	return true


func _page() -> Control:
	var p := Control.new()
	p.position = Vector2(0, 144)
	p.size = Vector2(1280, 508)
	add_child(p)
	return p


func _build_team_page() -> void:
	_team_page = _page()

	# in alto la squadra (anteprima dei 3 posti), sotto a sinistra la griglia, a destra la scheda
	var squad := HudPanel.new().setup("LA TUA SQUADRA  -  3 FRONT + 3 BACK", BattleTheme.RD)
	squad.position = Vector2(20, 8)
	squad.size = Vector2(1240, 158)
	if TouchUi.active():
		squad.margins = Vector4(12.0, 50.0, 12.0, 6.0)      # le carte stanno sotto il pulsante MIGLIORE
	_team_page.add_child(squad)
	_slots_box = HBoxContainer.new()
	_slots_box.add_theme_constant_override("separation", 8)
	squad.set_content(_slots_box)
	var squad_hint := BattleTheme.make_label("FRONT = IN CAMPO · BACK = RISERVE (SCAMBIO GRATIS)", 13, BattleTheme.CY_DIM)
	squad_hint.position = Vector2(420, 4)
	squad.add_child(squad_hint)
	var auto := Button.new()
	auto.text = "MIGLIORE" if TouchUi.active() else "SQUADRA MIGLIORE"
	auto.position = Vector2(1080 if TouchUi.active() else 990, 2)
	auto.size = Vector2(160 if TouchUi.active() else 236, 28)
	BattleTheme.style_button(auto, "normal", 14)
	if TouchUi.active():
		auto.custom_minimum_size = Vector2(0, 0)
		auto.size = Vector2(160, 38)
		auto.position.y = 2.0
	auto.pressed.connect(auto_team)
	squad.add_child(auto)

	var coll := HudPanel.new().setup("COLLEZIONE  -  TOCCA PER SCEGLIERE", BattleTheme.CY)
	coll.position = Vector2(20, 176)
	coll.size = Vector2(522, 332)
	_team_page.add_child(coll)
	_list_box = GridContainer.new()
	_list_box.columns = 4      # 4 colonne: stanno nel pannello; con tanti operatori la griglia scorre
	_list_box.add_theme_constant_override("h_separation", 6)
	_list_box.add_theme_constant_override("v_separation", 6)
	_set_filtered(coll, _list_box)

	var card := HudPanel.new().setup("SCHEDA OPERATORE", BattleTheme.CY)
	card.margins = Vector4(14.0, 30.0, 250.0, 12.0)
	card.position = Vector2(556, 176)
	card.size = Vector2(704, 332)
	_team_page.add_child(card)
	var leg := Button.new()
	leg.text = "?" if TouchUi.active() else "Legenda ?"
	leg.set_meta("keep_case", true)
	leg.position = Vector2(640 if TouchUi.active() else 466, 2)
	leg.size = Vector2(56 if TouchUi.active() else 180, 30)
	BattleTheme.style_button(leg, "normal", 14)
	leg.custom_minimum_size = Vector2(0, 0)
	leg.size = Vector2(56 if TouchUi.active() else 180, 30)
	leg.add_theme_font_override("font", BattleTheme.display())
	leg.pressed.connect(open_legend)
	card.add_child(leg)
	legend_button = leg

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	card.set_content(col)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	col.add_child(title_row)
	_detail_title = BattleTheme.make_label("", 28, BattleTheme.WH, true)
	_detail_title.set_meta("keep_case", true)
	title_row.add_child(_detail_title)
	_detail_icons = HBoxContainer.new()
	_detail_icons.add_theme_constant_override("separation", 4)
	_detail_icons.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_child(_detail_icons)
	_detail_label = BattleTheme.make_label("", 13, BattleTheme.WH)
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# il testo scorre se non ci sta (su telefono i pulsanti sono piu' alti): cosi' i comandi restano sempre visibili
	_detail_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dscroll := ScrollContainer.new()
	dscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dscroll.custom_minimum_size = Vector2(0, 60)
	dscroll.add_child(_detail_label)
	col.add_child(dscroll)
	_action_box = GridContainer.new()
	_action_box.columns = 2
	_action_box.add_theme_constant_override("h_separation", 8)
	_action_box.add_theme_constant_override("v_separation", 6)
	col.add_child(_action_box)
	# illustrazione dell'operatore (la tua grafica `splash.png`, o il segnaposto)
	_detail_portrait = PortraitView.new().setup("", "splash")
	_detail_portrait.show_expression_text = false
	_detail_portrait.position = Vector2(458.0, 34.0)
	_detail_portrait.size = Vector2(240.0, 292.0)
	card.add_child(_detail_portrait)


func _build_equip_page() -> void:
	_equip_page = _page()

	# chi stai equipaggiando: ritratto grande, nome, classe e frecce per cambiare operatore
	var who_h: float = 196.0 if TouchUi.active() else 150.0      # su telefono i pulsanti sono piu' alti
	var who := HudPanel.new().setup("STAI MODIFICANDO", BattleTheme.RD)
	who.position = Vector2(20, 8)
	who.size = Vector2(430, who_h)
	_equip_page.add_child(who)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	who.set_content(row)
	_equip_portrait = PortraitView.new().setup("", "splash")
	_equip_portrait.show_expression_text = false
	_equip_portrait.custom_minimum_size = Vector2(130, 0)
	row.add_child(_equip_portrait)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	col.add_child(name_row)
	_equip_name = BattleTheme.make_label("", 24, BattleTheme.WH, true)
	_equip_name.clip_text = true
	_equip_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(_equip_name)
	_equip_icons = HBoxContainer.new()
	_equip_icons.add_theme_constant_override("separation", 4)
	name_row.add_child(_equip_icons)
	_equip_info = BattleTheme.make_label("", 13, BattleTheme.CY)
	_equip_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_equip_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_equip_info)
	var arrows := HBoxContainer.new()
	arrows.add_theme_constant_override("separation", 8)
	col.add_child(arrows)
	var prev := Button.new()
	prev.text = "<" if TouchUi.active() else "<  PREC."
	prev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prev.custom_minimum_size = Vector2(0, 50 if TouchUi.active() else 34)
	BattleTheme.style_button(prev, "normal", 14)
	prev.pressed.connect(cycle_char.bind(-1))
	arrows.add_child(prev)
	var nxt := Button.new()
	nxt.text = ">" if TouchUi.active() else "SUCC.  >"
	nxt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nxt.custom_minimum_size = Vector2(0, 50 if TouchUi.active() else 34)
	BattleTheme.style_button(nxt, "normal", 14)
	nxt.pressed.connect(cycle_char.bind(1))
	arrows.add_child(nxt)

	var slots := HudPanel.new().setup("SLOT", BattleTheme.CY)
	slots.position = Vector2(20, 8.0 + who_h + 8.0)
	slots.size = Vector2(430, 508.0 - (8.0 + who_h + 8.0))
	_equip_page.add_child(slots)
	_equip_slots_box = VBoxContainer.new()
	_equip_slots_box.add_theme_constant_override("separation", 3)
	_set_scrolled(slots, _equip_slots_box)

	_equip_title = HudPanel.new().setup("INVENTARIO", BattleTheme.CY)
	_equip_title.position = Vector2(466, 8)
	_equip_title.size = Vector2(794, 500)
	_equip_page.add_child(_equip_title)
	var icol := VBoxContainer.new()
	icol.add_theme_constant_override("separation", 6)
	_equip_title.set_content(icol)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	icol.add_child(scroll)
	_equip_list = VBoxContainer.new()
	_equip_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equip_list.add_theme_constant_override("separation", 3)
	scroll.add_child(_equip_list)
	_equip_action = HBoxContainer.new()
	icol.add_child(_equip_action)


func _build_recruit_page() -> void:
	_recruit_page = _page()

	var info := HudPanel.new().setup("RECLUTAMENTO", BattleTheme.RD)
	info.position = Vector2(20, 14)
	info.size = Vector2(430, 494)
	_recruit_page.add_child(info)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	info.set_content(col)
	var tabs := HBoxContainer.new()          # i due banner: standard e nuovi operatori
	tabs.add_theme_constant_override("separation", 6)
	col.add_child(tabs)
	for bn in [["standard", "STANDARD"], ["nuovi", "NUOVI OPERATORI"]]:
		var tb := Button.new()
		tb.text = str(bn[1])
		tb.clip_text = true
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.custom_minimum_size = Vector2(0, 40)
		tb.pressed.connect(set_banner.bind(str(bn[0])))
		tabs.add_child(tb)
		banner_buttons[str(bn[0])] = tb
	_banner_note = BattleTheme.make_label("", 14, BattleTheme.GOLD)
	_banner_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_banner_note)
	_pity_label = BattleTheme.make_label("", 16, BattleTheme.CY)
	_pity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_pity_label)
	_pity_bar = ProgressBar.new()          # avanzamento verso l'epico garantito
	_pity_bar.max_value = float(Recruiting.PITY_LIMIT)
	_pity_bar.show_percentage = false
	_pity_bar.custom_minimum_size = Vector2(0, 14)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.04, 0.07, 0.1, 0.95)
	bar_bg.set_border_width_all(1)
	bar_bg.border_color = BattleTheme.CY_DIM
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color("#c07bff")
	_pity_bar.add_theme_stylebox_override("background", bar_bg)
	_pity_bar.add_theme_stylebox_override("fill", bar_fill)
	col.add_child(_pity_bar)
	for entry in [[1, "RECLUTA x1"], [10, "RECLUTA x10"]]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 56)
		BattleTheme.style_button(b, "primary", 24)
		b.pressed.connect(pull.bind(int(entry[0])))
		col.add_child(b)
		_pull_buttons.append([b, int(entry[0]), str(entry[1])])
	var guide := Button.new()
	guide.text = "COME FUNZIONA  ?"
	guide.custom_minimum_size = Vector2(0, 40)
	BattleTheme.style_button(guide, "normal", 20)
	guide.pressed.connect(open_gacha_guide)
	col.add_child(guide)
	guide_button = guide
	var odds: Array = BattleContent.rarity_odds()
	col.add_child(BattleTheme.make_label("QUOTE DI RECLUTAMENTO", 13, BattleTheme.CY_DIM))
	for r in 4:
		var rc: Color = BattleTheme.rarity_color(r)
		col.add_child(GameIcon.line("nucleo", rc, "%s  %d%%" % [str(BattleTypes.RARITIES[r]).to_upper(), int(odds[r])], 15, rc))
	var note := BattleTheme.make_label("Le copie si spendono col RANK UP.\nIl x10 garantisce almeno un raro.", 14, BattleTheme.CY_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.queue_free()        # lo spiega gia' "COME FUNZIONA"

	var res := HudPanel.new().setup("ESITO", BattleTheme.CY)
	res.position = Vector2(466, 14)
	res.size = Vector2(794, 494)
	_recruit_page.add_child(res)
	_results_box = VBoxContainer.new()
	_results_box.add_theme_constant_override("separation", 2)
	res.set_content(_results_box)


func _process(delta: float) -> void:
	_t += delta


# ---------- Azioni (usate anche dai test) ----------

func show_tab(name: String) -> void:
	var changed: bool = tab != name
	tab = name
	refresh()
	if changed and is_inside_tree():
		var page: Control = {"squadra": _team_page, "equip": _equip_page, "reclutamento": _recruit_page}.get(name)
		if page != null:
			page.modulate.a = 0.0
			page.create_tween().tween_property(page, "modulate:a", 1.0, 0.18)
	if name == "reclutamento" and Settings.should_show_gacha_guide():
		open_gacha_guide()


# Apre la guida al reclutamento (da sola la prima volta, poi dal bottone).
func open_gacha_guide() -> GachaGuide:
	for c in get_children():
		if c is GachaGuide:
			return c
	return GachaGuide.open(self)


# Guida a classi e fazioni: cosa fanno e cosa serve per farle funzionare.
func open_strategy_guide() -> GachaGuide:
	for c in get_children():
		if c is GachaGuide:
			return c
	return GachaGuide.open_pages(self, "STRATEGIE: CLASSI E FAZIONI", StrategyInfo.pages())


# Archivio consultabile: glossario dei termini e scheda di ogni operatore.
func open_archive() -> GachaGuide:
	for c in get_children():
		if c is GachaGuide:
			return c
	return GachaGuide.open_pages(self, "ARCHIVIO: GLOSSARIO E OPERATORI", Lore.archive_pages())


# Legenda dell'operatore selezionato: chi e', come si usa, la sua classe e la sua fazione.
func open_legend() -> GachaGuide:
	for c in get_children():
		if c is GachaGuide:
			return c
	if selected == "" or not RosterState.owns(roster, selected):
		return null
	var e: Dictionary = roster["characters"][selected]
	var pages: Array = [Lore.legend_page(selected, BattleContent.style_of(selected, e))]
	pages.append_array(Lore.ability_pages(selected, int(e["rank"])))
	return GachaGuide.open_pages(self, "LEGENDA", pages)


func select(char_id: String) -> void:
	if RosterState.owns(roster, char_id):
		selected = char_id
		refresh()


func select_slot(index: int) -> void:
	var team: Array = roster["team"]
	if index >= 0 and index < team.size():
		slot_target = index
		selected = str(team[index])
	elif index >= 0 and index < BattleTypes.TEAM_SIZE:
		slot_target = team.size()
	refresh()


# Scambia di posto il personaggio scelto con quello del posto selezionato (es. dalla back row al front).
func swap_with_slot(char_id: String) -> bool:
	var team: Array = (roster["team"] as Array).duplicate()
	var a: int = team.find(char_id)
	var b: int = slot_target
	if a < 0 or b < 0 or b >= team.size() or a == b:
		return _say("Scegli prima il posto con cui scambiare.", false)
	var tmp: Variant = team[a]
	team[a] = team[b]
	team[b] = tmp
	if not RosterState.set_team(roster, team):
		return _say("Squadra non valida.", false)
	selected = char_id
	slot_target = b
	_save()
	return _say("Posti scambiati.", true)


# Mette il personaggio scelto in squadra, lo toglie, o prende il posto selezionato.
func toggle_team(char_id: String) -> bool:
	if not RosterState.owns(roster, char_id):
		return _say("Personaggio non posseduto.", false)
	var team: Array = (roster["team"] as Array).duplicate()
	if team.has(char_id):
		if team.size() <= 1:
			return _say("Serve almeno un operatore in squadra.", false)
		team.erase(char_id)
		slot_target = clampi(slot_target, 0, team.size())
	elif team.size() < BattleTypes.TEAM_SIZE:
		team.append(char_id)
	else:
		team[clampi(slot_target, 0, team.size() - 1)] = char_id
	if not RosterState.set_team(roster, team):
		return _say("Squadra non valida.", false)
	_save()
	return _say("Squadra aggiornata.", true)


# Alterna ortodosso/atipico (vedi Factions). Solo per chi ha una fazione.
func toggle_style(char_id: String) -> bool:
	if not RosterState.owns(roster, char_id):
		return false
	var now: String = BattleContent.style_of(char_id, roster["characters"][char_id])
	var next: String = "atipico" if now == "ortodosso" else "ortodosso"
	if not RosterState.set_style(roster, char_id, next):
		return _say("Questo operatore non ha una fazione.", false)
	_save()
	refresh()
	return _say("%s ora e' %s." % [str(BattleContent.CHARACTERS[char_id]["name"]), next], true)


func upgrade(char_id: String) -> bool:
	var err: String = RosterState.level_up_character(roster, char_id)
	if err != "":
		var msgs: Dictionary = {"max": "Livello massimo.", "monete": "CREDITI insufficiente.",
			"nucleo": "Nuclei insufficienti.", "sconosciuto": "Personaggio non posseduto."}
		return _say(str(msgs.get(err, "Non riuscito: " + err)), false)
	_save()
	var okl: bool = _say("%s sale al livello %d." % [BattleContent.CHARACTERS[char_id]["name"], int(roster["characters"][char_id]["level"])], true)
	_celebrate("LV +1", Color("#7cf0ff"), false)
	return okl


func rank_up(char_id: String) -> bool:
	if not RosterState.owns(roster, char_id):
		return _say("Personaggio non posseduto.", false)
	var rank: int = int(roster["characters"][char_id].get("rank", 0))
	if rank >= RosterState.MAX_RANK:
		return _say("Rank massimo.", false)
	if not RosterState.rank_up(roster, char_id):
		return _say("Servono %d copie (ne hai %d)." % [RosterState.rank_cost(rank), RosterState.copies(roster, char_id)], false)
	_save()
	var name: String = str(BattleContent.CHARACTERS[char_id]["name"])
	var what: String = Signatures.rank_upgrade_text(char_id, rank + 1)
	Notify.toast("%s: RANK %d  ·  %s" % [name.to_upper(), rank + 1, what])
	var okr: bool = _say("%s sale al rank %d." % [name, rank + 1], true)
	_celebrate("RANK UP!", Color("#ffd166"), true)
	return okr


func set_banner(b: String) -> void:
	if not Recruiting.BANNERS.has(b) or b == banner:
		return
	banner = b
	last_results = []
	if _recruit_page != null:
		_refresh_recruit()


func pull(count: int) -> bool:
	var s: int = next_seed if next_seed != 0 else (int(randi()) | 1)
	var r: Dictionary = Recruiting.pull(roster, count, s, banner)
	if not bool(r["ok"]):
		last_results = []
		if str(r["error"]) == "monete":
			return _say("Servono %d CREDITI." % int(r["cost"]), false)
		return _say("Reclutamento non riuscito.", false)
	last_results = r["results"]
	_reveal_rows = DisplayServer.get_name() != "headless"
	_save()
	if DisplayServer.get_name() != "headless":
		if AnimFx.enabled():
			var top: int = 0
			for pr in last_results:
				top = maxi(top, int(pr["rarity"]))
			var res: Array = last_results
			AnimFx.portal(self, top, func() -> void: PullReveal.play(self, res))
		else:
			PullReveal.play(self, last_results)
	_announce_pulls(last_results)
	return _say("Reclutamento completato (-%d CREDITI)." % int(r["cost"]), true)


# Avvisa dei nuovi operatori ottenuti (max 3, i migliori per primi).
func _announce_pulls(results: Array) -> void:
	var fresh: Array = []
	for r in results:
		if str(r["outcome"]) == "new":
			fresh.append(r)
	fresh.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["rarity"]) > int(b["rarity"]))
	for r in fresh.slice(0, 3):
		Notify.toast("NUOVO OPERATORE: %s (%s)" % [str(BattleContent.CHARACTERS[str(r["char"])]["name"]).to_upper(), str(BattleTypes.RARITIES[int(r["rarity"])]).to_upper()], Notify.Kind.WARNING)


# Mette in squadra i migliori operatori posseduti, senza cercarli uno a uno.
func auto_team() -> bool:
	var best: Array = RosterState.best_team(roster)
	if best == roster["team"]:
		return _say("La squadra e' gia' la migliore possibile.", true)
	if not RosterState.set_team(roster, best):
		return _say("Squadra non valida.", false)
	slot_target = 0
	selected = str(best[0])
	_save()
	return _say("Squadra migliore schierata.", true)


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE:
			_on_back()
		KEY_LEFT:
			cycle_char(-1)
		KEY_RIGHT:
			cycle_char(1)


# Passa all'operatore posseduto precedente/successivo.
func cycle_char(direction: int) -> void:
	var ids: Array = roster["characters"].keys()
	ids.sort()
	if ids.is_empty():
		return
	var i: int = ids.find(selected)
	i = (maxi(i, 0) + direction + ids.size()) % ids.size()
	selected = str(ids[i])
	refresh()


func select_equip_slot(key: String) -> void:
	equip_slot = key
	refresh()


# Id del pezzo equipaggiato da un personaggio in uno slot ("" se vuoto).
func gear_in_slot(char_id: String, slot: String) -> String:
	for gid in roster["gear"]:
		var g: Dictionary = roster["gear"][gid]
		if str(g["equipped_by"]) == char_id and str(g["slot"]) == slot:
			return str(gid)
	return ""


# Mette nello slot scelto l'oggetto indicato (id mossa/passiva/pezzo); "" svuota lo slot.
func equip_item(item_id: String) -> bool:
	if not RosterState.owns(roster, selected):
		return _say("Nessun operatore.", false)
	var ok: bool = false
	var key: String = equip_slot
	if key.begins_with("skill"):
		var idx: int = int(key.substr(5))
		ok = RosterState.equip_skill(roster, selected, idx, item_id)
		if not ok:
			return _say(_why_not(idx, roster["characters"][selected]["skills"].size(), item_id, "skills"), false)
	elif key == "ult":
		ok = RosterState.equip_ult(roster, selected, item_id)
		if not ok:
			return _say("Nessuna copia libera di questa ultimate.", false)
	elif key.begins_with("passive"):
		var pidx: int = int(key.substr(7))
		ok = RosterState.equip_passive(roster, selected, pidx, item_id)
		if not ok:
			return _say(_why_not(pidx, roster["characters"][selected]["passives"].size(), item_id, "passives"), false)
	else:
		if item_id == "":
			var cur: String = gear_in_slot(selected, key)
			ok = cur == "" or RosterState.unequip_gear(roster, cur)
		else:
			if not roster["gear"].has(item_id) or str(roster["gear"][item_id]["slot"]) != key:
				return _say("Pezzo non adatto a questo slot.", false)
			ok = RosterState.equip_gear(roster, selected, item_id)
		if not ok:
			return _say("Non riuscito.", false)
	_save()
	return _say("Equipaggiamento aggiornato.", true)


func _why_not(slot: int, size: int, item_id: String, field: String) -> String:
	if item_id != "" and slot > size:
		return "Riempi prima lo slot precedente."
	if item_id != "":
		var list: Array = roster["characters"][selected][field]
		for i in list.size():
			if i != slot and str(list[i]) == item_id:
				return "Gia' equipaggiata su questo operatore."
		return "Nessuna copia libera."
	return "Non riuscito."


func upgrade_gear(gear_id: String) -> bool:
	var err: String = RosterState.level_up_gear(roster, gear_id)
	if err != "":
		var msgs: Dictionary = {"max": "Pezzo al livello massimo.", "monete": "CREDITI insufficiente.",
			"lega": "Leghe insufficienti.", "sconosciuto": "Pezzo sconosciuto."}
		return _say(str(msgs.get(err, "Non riuscito: " + err)), false)
	_save()
	return _say("Pezzo potenziato al livello %d." % int(roster["gear"][gear_id]["level"]), true)


# Scintille e scritta che sale quando un operatore cresce; al rank lampo dorato.
func _celebrate(text: String, col: Color, flash: bool) -> void:
	if not AnimFx.enabled() or not is_inside_tree():
		return
	var at := Vector2(900.0, 330.0)
	AnimFx.sparks(self, at, col, 18, 300.0)
	AnimFx.float_text(self, text, at + Vector2(-60.0, 0.0), col, 44)
	if flash:
		AnimFx.shockwave(self, at, col, 200.0)
		ComicFx.flash(self, Color(1.0, 0.85, 0.3, 0.4), 0.4)


func _say(text: String, ok: bool) -> bool:
	status_text = text
	Notify.toast(text, Notify.Kind.SUCCESS if ok else Notify.Kind.ERROR)
	refresh()
	if _status_label != null:
		_status_label.add_theme_color_override("font_color", BattleTheme.WH if ok else BattleTheme.RD)
	return ok


func _save() -> void:
	RosterStore.save(roster, save_path)


func _on_back() -> void:
	SceneRouter.go("hub")


# Una risorsa nell'intestazione: icona + scritta Archivo Black. Ritorna la scritta (il testo si aggiorna in refresh).
func _header_resource(icon_key: String, x: float) -> Label:
	_header_icon(icon_key, Vector2(x, 40), 24.0)
	var l := BattleTheme.make_label("", 17, BattleTheme.WH, true)
	l.position = Vector2(x + 32.0, 38.0)
	l.size = Vector2(142, 28)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(l)
	return l


# ---------- Aggiornamento grafico ----------

func refresh() -> void:
	if _list_box == null:
		return
	_coins_label.text = "CREDITI %d" % int(roster["coins"])
	var mats: Dictionary = roster["materials"]
	_mats_label.text = "NUCLEI %d" % int(mats.get("nucleo", 0))
	_lega_label.text = "LEGHE %d" % int(mats.get("lega", 0))
	_status_label.text = status_text
	_team_page.visible = tab == "squadra"
	_equip_page.visible = tab == "equip"
	_recruit_page.visible = tab == "reclutamento"
	for k in _tab_buttons:
		BattleTheme.style_button(_tab_buttons[k], "primary" if k == tab else "normal", 20)
	if tab == "squadra":
		_refresh_list()
		_refresh_slots()
		_refresh_detail()
	elif tab == "equip":
		_refresh_equip()
	else:
		_refresh_recruit()


func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _stars(rank: int) -> String:
	return "*".repeat(rank) + ".".repeat(RosterState.MAX_RANK - rank)


func _refresh_list() -> void:
	_clear(_list_box)
	var ids: Array = BattleContent.CHARACTERS.keys()
	ids.sort_custom(func(a, b):
		var ra: int = int(BattleContent.CHARACTERS[a]["rarity"])
		var rb: int = int(BattleContent.CHARACTERS[b]["rarity"])
		if ra != rb:
			return ra > rb
		return str(a) < str(b))
	var team: Array = roster["team"]
	for id in ids:
		if not _passes_filters(str(id)):
			continue
		var owned: bool = RosterState.owns(roster, id)
		var b: Button = OperatorCards.tile(str(id), owned, roster["characters"][id] if owned else {}, team.find(id) + 1, id == selected)
		if owned:
			b.pressed.connect(select.bind(id))
		_list_box.add_child(b)


func _refresh_slots() -> void:
	_clear(_slots_box)
	var team: Array = roster["team"]
	for i in BattleTypes.TEAM_SIZE:
		var id: String = str(team[i]) if i < team.size() else ""
		var b: Button = OperatorCards.slot_card(i, id, roster["characters"][id] if id != "" else {}, i == slot_target)
		b.pressed.connect(select_slot.bind(i))
		if i == BattleTypes.FRONT_SIZE:
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(18, 0)
			_slots_box.add_child(gap)
		_slots_box.add_child(b)


func _refresh_detail() -> void:
	_clear(_action_box)
	if selected == "" or not RosterState.owns(roster, selected):
		_detail_title.text = "NESSUN OPERATORE"
		_detail_label.text = ""
		_detail_portrait.visible = false
		return
	var def: Dictionary = BattleContent.CHARACTERS[selected]
	var e: Dictionary = roster["characters"][selected]
	var st: Dictionary = BattleContent.compute_stats(e)
	_detail_title.text = str(def["name"])
	_fill_identity_icons(_detail_icons, selected, 28.0)
	_detail_portrait.visible = true
	if _detail_portrait.char_id != selected:
		_detail_portrait.setup(selected, "splash")
	_detail_title.add_theme_color_override("font_color", BattleTheme.unit_color(str(def["color"])))
	var skills: Array = []
	for s in e["skills"]:
		skills.append(BattleText.move_name(str(s)))
	for s in Signatures.skills_for(selected, int(e["rank"])):
		skills.append("★" + BattleText.move_name(str(s)))
	var passives: Array = []
	for p in e["passives"]:
		passives.append(str(BattleContent.PASSIVES[str(p)]["name"]))
	var lines: Array = []
	var arch: Dictionary = Archetypes.DEFS.get(Archetypes.of_def(def), {})
	lines.append("%s = %s  |  %s  |  %s" % [str(def["color"]).to_upper(), str(arch.get("tag", "")), str(def["cls"]).to_upper(), str(BattleTypes.RARITIES[int(def["rarity"])]).to_upper()])
	lines.append("%s: %s" % [str(arch.get("name", "")), str(arch.get("line", ""))])
	var faction: String = BattleContent.faction_of(selected)
	if faction != "":
		lines.append("%s  |  %s  |  %s" % [Factions.name_of(faction).to_upper(), str(Factions.FACTIONS[faction]["doctrine"]).to_upper(), BattleContent.style_of(selected, e).to_upper()])
	if faction != "":
		lines.append(("IN USO  " if BattleContent.style_of(selected, e) == "atipico" else "") + Atypical.describe(selected))
	lines.append("LIV %d/%d   RANK %s" % [int(e["level"]), RosterState.MAX_LEVEL, _stars(int(e["rank"]))])
	lines.append("PV %d  ATK %d  DEF %d  VEL %d" % [int(st["hp"]), int(st["atk"]), int(st["def"]), int(st["spd"])])
	lines.append("SKILL  %s" % (", ".join(skills) if not skills.is_empty() else "-"))
	lines.append("ULT  %s" % BattleText.move_name(str(e["ult"])))
	var pass_names: Array = passives.duplicate()
	if Signatures.has_passive(selected):
		pass_names.append("★" + Signatures.passive_name(selected))
	lines.append("PASSIVE  %s" % (", ".join(pass_names) if not pass_names.is_empty() else "-"))
	if Signatures.has_passive(selected):
		lines.append("★ %s" % Signatures.passive_text(selected, int(e["rank"])))
	lines.append("RANK %d: %s" % [int(e["rank"]), Signatures.rank_perk_text(selected, int(e["rank"]))])
	for rk in range(1, int(e["rank"]) + 1):
		lines.append("  R%d  %s" % [rk, Signatures.rank_upgrade_text(selected, rk)])
	var nm: String = Signatures.next_milestone(selected, int(e["rank"]))
	if nm != "":
		lines.append("PROSSIMO  %s" % nm)
		lines.append("COPIE  %d / %d per il RANK UP" % [RosterState.copies(roster, selected), RosterState.rank_cost(int(e["rank"]))])
	_detail_label.text = "\n".join(lines)

	var in_team: bool = (roster["team"] as Array).has(selected)
	var tb := Button.new()
	tb.custom_minimum_size = Vector2(0, 54 if TouchUi.active() else 40)
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.clip_text = true
	tb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if in_team:
		tb.text = "TOGLI"
	elif (roster["team"] as Array).size() < BattleTypes.TEAM_SIZE:
		tb.text = "METTI IN SQUADRA"
	else:
		var tgt: String = str(roster["team"][clampi(slot_target, 0, (roster["team"] as Array).size() - 1)])
		tb.text = "AL POSTO DI %s" % str(BattleContent.CHARACTERS[tgt]["name"]).to_upper()
	BattleTheme.style_button(tb, "normal", 15)
	tb.pressed.connect(toggle_team.bind(selected))
	_action_box.add_child(tb)
	var team_now: Array = roster["team"]
	if in_team and team_now.size() > 1 and slot_target < team_now.size() and str(team_now[slot_target]) != selected:
		var sb := Button.new()
		sb.custom_minimum_size = Vector2(0, 54 if TouchUi.active() else 40)
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.clip_text = true
		sb.text = "SCAMBIA CON %s" % str(BattleContent.CHARACTERS[str(team_now[slot_target])]["name"]).to_upper()
		BattleTheme.style_button(sb, "normal", 15)
		sb.pressed.connect(swap_with_slot.bind(selected))
		_action_box.add_child(sb)

	var ub := Button.new()
	ub.custom_minimum_size = Vector2(0, 54 if TouchUi.active() else 40)
	ub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ub.clip_text = true
	ub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if int(e["level"]) >= RosterState.MAX_LEVEL:
		ub.text = "LIVELLO MASSIMO"
		ub.disabled = true
	else:
		var cost: Dictionary = BattleContent.character_upgrade_cost(int(e["level"]))
		ub.text = "POTENZIA"
		_cost_row(ub, [["coin", int(cost["coins"])], ["nucleo", int(cost["nucleo"])]], 15)
		ub.size_flags_stretch_ratio = 1.6
	BattleTheme.style_button(ub, "primary", 15)
	ub.pressed.connect(upgrade.bind(selected))
	_action_box.add_child(ub)

	var rb := Button.new()
	rb.custom_minimum_size = Vector2(0, 54 if TouchUi.active() else 40)
	rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rb.clip_text = true
	rb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if int(e["rank"]) >= RosterState.MAX_RANK:
		rb.text = "RANK MASSIMO"
		rb.disabled = true
	else:
		var need: int = RosterState.rank_cost(int(e["rank"]))
		var have: int = RosterState.copies(roster, selected)
		rb.text = "RANK UP %d/%d" % [have, need]
		rb.disabled = have < need
	BattleTheme.style_button(rb, "primary" if RosterState.can_rank_up(roster, selected) else "normal", 15)
	rb.pressed.connect(rank_up.bind(selected))
	_action_box.add_child(rb)

	if faction != "":
		var sb := Button.new()
		sb.custom_minimum_size = Vector2(0, 54 if TouchUi.active() else 40)
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.clip_text = true
		sb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		sb.text = ("%s" if TouchUi.active() else "STILE: %s") % BattleContent.style_of(selected, e).to_upper()
		BattleTheme.style_button(sb, "normal", 15)
		sb.pressed.connect(toggle_style.bind(selected))
		_action_box.add_child(sb)

	var eb := Button.new()
	eb.text = "EQUIPAGGIO"
	eb.custom_minimum_size = Vector2(0, 54 if TouchUi.active() else 40)
	eb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eb.clip_text = true
	eb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	BattleTheme.style_button(eb, "normal", 15)
	eb.pressed.connect(show_tab.bind("equip"))
	_action_box.add_child(eb)


# Icone di classe e fazione di un operatore (una riga accanto al nome).
func _fill_identity_icons(box: Container, char_id: String, px: float) -> void:
	_clear(box)
	var def: Dictionary = BattleContent.CHARACTERS[char_id]
	box.add_child(GameIcon.new().setup(str(def["cls"]), BattleTheme.unit_color(str(def["color"])), px))
	var faction: String = BattleContent.faction_of(char_id)
	if faction != "":
		box.add_child(GameIcon.new().setup(faction, Hints.faction_color(faction), px))


# Icona e colore di uno slot dell'equipaggiamento (per le skill, quella della mossa montata).
func _slot_icon(key: String) -> Array:
	var e: Dictionary = roster["characters"][selected]
	if key.begins_with("skill"):
		var i: int = int(key.substr(5))
		if i < e["skills"].size():
			return [GameIcon.move_key(str(e["skills"][i])), GameIcon.move_color(str(e["skills"][i]))]
		return ["bolt", BattleTheme.CY_DIM]
	if key == "ult":
		return ["burst", BattleTheme.GOLD]
	if key.begins_with("passive"):
		return ["passive", BattleTheme.CY]
	return [GameIcon.gear_key(key), BattleTheme.CY]


func _gear_stats_text(g: Dictionary) -> String:
	var rarity: int = clampi(int(g["rarity"]), 0, BattleContent.GEAR_RARITY_MULT.size() - 1)
	var mult: float = float(BattleContent.GEAR_RARITY_MULT[rarity]) * (1.0 + BattleContent.GEAR_LEVEL_BONUS * float(int(g["level"]) - 1))
	var parts: Array = []
	var base: Dictionary = BattleContent.GEAR_BASE[str(g["slot"])]
	for k in base:
		parts.append("%s +%d" % [str(k).to_upper(), int(round(float(base[k]) * mult))])
	return " ".join(parts)


func _gear_text(gid: String) -> String:
	var g: Dictionary = roster["gear"][gid]
	return "%s Lv%d/%d  %s" % [str(BattleTypes.RARITIES[int(g["rarity"])]).to_upper(), int(g["level"]),
		int(BattleContent.GEAR_MAX_LEVEL[int(g["rarity"])]), _gear_stats_text(g)]


func _slot_value_text(key: String) -> String:
	var e: Dictionary = roster["characters"][selected]
	if key.begins_with("skill"):
		var i: int = int(key.substr(5))
		return BattleText.move_name(str(e["skills"][i])) if i < e["skills"].size() else "(vuoto)"
	if key == "ult":
		return BattleText.move_name(str(e["ult"]))
	if key.begins_with("passive"):
		var j: int = int(key.substr(7))
		return str(BattleContent.PASSIVES[str(e["passives"][j])]["name"]) if j < e["passives"].size() else "(vuoto)"
	var gid: String = gear_in_slot(selected, key)
	return _gear_text(gid) if gid != "" else "(vuoto)"


func _item_button(text: String, kind: String, enabled: bool, id: String, icon_key: String = "", icon_color: Color = BattleTheme.CY) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	b.clip_text = true
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	BattleTheme.style_button(b, kind, 16)
	b.disabled = not enabled
	if icon_key != "":
		var ic: GameIcon = GameIcon.attach(b, icon_key, BattleTheme.WH if kind == "primary" else icon_color, 22.0)
		ic.modulate.a = 1.0 if enabled else 0.35
	b.pressed.connect(equip_item.bind(id))
	return b


func _refresh_equip() -> void:
	_clear(_equip_slots_box)
	_clear(_equip_list)
	_clear(_equip_action)
	if selected == "" or not RosterState.owns(roster, selected):
		_equip_name.text = "NESSUN OPERATORE"
		return
	var def: Dictionary = BattleContent.CHARACTERS[selected]
	var e: Dictionary = roster["characters"][selected]
	_equip_name.text = "%s  Lv%d" % [str(def["name"]).to_upper(), int(e["level"])]
	_equip_name.add_theme_color_override("font_color", BattleTheme.unit_color(str(def["color"])))
	_equip_info.text = "%s · %s\n%s" % [str(def["cls"]).to_upper(), str(def["color"]).to_upper(), Lore.character_text(selected).get("tag", "")]
	if _equip_portrait.char_id != selected:
		_equip_portrait.setup(selected, "splash")
	_fill_identity_icons(_equip_icons, selected, 26.0)

	for entry in EQUIP_SLOTS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 46 if TouchUi.active() else 34)
		b.clip_text = true
		b.text = "%-9s %s" % [str(entry[1]), _slot_value_text(str(entry[0]))]
		BattleTheme.style_button(b, "primary" if str(entry[0]) == equip_slot else "normal", 15)
		var sk: Array = _slot_icon(str(entry[0]))
		GameIcon.attach(b, str(sk[0]), BattleTheme.WH if str(entry[0]) == equip_slot else (sk[1] as Color), 20.0)
		b.pressed.connect(select_equip_slot.bind(str(entry[0])))
		_equip_slots_box.add_child(b)

	var key: String = equip_slot
	var title: String = key
	for entry in EQUIP_SLOTS:
		if str(entry[0]) == key:
			title = str(entry[1])
	_equip_title.title = "INVENTARIO: " + title
	_equip_title.queue_redraw()

	if key.begins_with("skill") or key == "ult" or key.begins_with("passive"):
		_refresh_equip_moves(key)
	else:
		_refresh_equip_gear(key)


func _refresh_equip_moves(key: String) -> void:
	var is_passive: bool = key.begins_with("passive")
	var field: String = "skills"
	var slot: int = 0
	var current: String = ""
	var e: Dictionary = roster["characters"][selected]
	if key.begins_with("skill"):
		slot = int(key.substr(5))
		current = str(e["skills"][slot]) if slot < e["skills"].size() else ""
	elif key == "ult":
		field = "ult"
		current = str(e["ult"])
	else:
		field = "passives"
		slot = int(key.substr(7))
		current = str(e["passives"][slot]) if slot < e["passives"].size() else ""

	if key != "ult":
		_equip_list.add_child(_item_button("-- SVUOTA LO SLOT --", "normal", current != "", ""))

	var table: Dictionary = roster["passives"] if is_passive else roster["moves"]
	var ids: Array = table.keys()
	ids.sort()
	for id in ids:
		var wanted: String = "skill" if key.begins_with("skill") else "ult"
		if not is_passive and (not BattleContent.MOVES.has(id) or str(BattleContent.MOVES[id]["kind"]) != wanted):
			continue
		var owned: int = int(table[id])
		var used: int = RosterState._used(roster, field, str(id))
		var free: int = owned - used
		var is_current: bool = str(id) == current
		var name: String = str(BattleContent.PASSIVES[id]["name"]) if is_passive else BattleText.move_name(str(id))
		var hint: String = _passive_hint(str(id)) if is_passive else BattleText.move_hint(str(id))
		var text: String = "%s%s   [libere %d/%d]   %s" % ["> " if is_current else "", name, free, owned, hint]
		var ik: String = "passive" if is_passive else GameIcon.move_key(str(id))
		var icol: Color = BattleTheme.CY if is_passive else GameIcon.move_color(str(id))
		_equip_list.add_child(_item_button(text, "primary" if is_current else "normal", is_current or free > 0, str(id), ik, icol))


func _passive_hint(pid: String) -> String:
	var p: Dictionary = BattleContent.PASSIVES[pid]
	if p.has("atk_mult"):
		return "ATK +%d%%" % int(round((float(p["atk_mult"]) - 1.0) * 100.0))
	if p.has("hp_mult"):
		return "PV +%d%%" % int(round((float(p["hp_mult"]) - 1.0) * 100.0))
	if p.has("on_enter_shield"):
		return "scudo quando entra"
	if p.has("hunter"):
		return "piu' danni al boss ferito"
	return ""


func _refresh_equip_gear(key: String) -> void:
	var cur: String = gear_in_slot(selected, key)
	_equip_list.add_child(_item_button("-- TOGLI IL PEZZO --", "normal", cur != "", ""))
	var ids: Array = []
	for gid in roster["gear"]:
		if str(roster["gear"][gid]["slot"]) == key:
			ids.append(str(gid))
	ids.sort()
	if ids.is_empty():
		_equip_list.add_child(BattleTheme.make_label("Nessun pezzo di questo tipo. Si trovano come premi.", 16, BattleTheme.CY_DIM))
	for gid in ids:
		var g: Dictionary = roster["gear"][gid]
		var owner_id: String = str(g["equipped_by"])
		var tag: String = ""
		if owner_id == selected:
			tag = "> "
		var text: String = "%s%s" % [tag, _gear_text(gid)]
		if owner_id != "" and owner_id != selected:
			text += "   (su %s)" % str(BattleContent.CHARACTERS[owner_id]["name"]).to_upper()
		_equip_list.add_child(_item_button(text, "primary" if owner_id == selected else "normal", true, gid, GameIcon.gear_key(key), BattleTheme.rarity_color(int(g["rarity"]))))
	if cur != "":
		var g2: Dictionary = roster["gear"][cur]
		var ub := Button.new()
		ub.custom_minimum_size = Vector2(0, 46)
		ub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if int(g2["level"]) >= int(BattleContent.GEAR_MAX_LEVEL[int(g2["rarity"])]):
			ub.text = "PEZZO AL LIVELLO MASSIMO"
			ub.disabled = true
		else:
			var cost: Dictionary = BattleContent.gear_upgrade_cost(int(g2["rarity"]), int(g2["level"]))
			ub.text = "POTENZIA PEZZO"
			_cost_row(ub, [["coin", int(cost["coins"])], ["lega", int(cost["lega"])]], 15)
		BattleTheme.style_button(ub, "primary", 15)
		ub.pressed.connect(upgrade_gear.bind(cur))
		_equip_action.add_child(ub)


func _refresh_recruit() -> void:
	for bk in banner_buttons:
		BattleTheme.style_button(banner_buttons[bk], "primary" if str(bk) == banner else "normal", 15)
	_banner_note.text = "Solo i 10 operatori del secondo roster." if banner == "nuovi" else "Tutti gli operatori. I 10 nuovi escono con meta' delle probabilita'."
	var left: int = Recruiting.PITY_LIMIT - int(roster["pity"])
	_pity_label.text = "Reclutamenti totali: %d\nEpico garantito entro %d reclutamenti.\nCREDITI: %d" % [int(roster["pulls"]), left, int(roster["coins"])]
	_pity_bar.value = float(int(roster["pity"]))
	for entry in _pull_buttons:
		var b: Button = entry[0]
		var cost: int = Recruiting.cost_for(int(entry[1]))
		b.text = str(entry[2])
		b.disabled = int(roster["coins"]) < cost
		BattleTheme.style_button(b, "primary", 24)
		_cost_row(b, [["coin", cost]], 24)

	_clear(_results_box)
	if last_results.is_empty():
		var empty := BattleTheme.make_label("Nessun reclutamento ancora.  Premi RECLUTA per chiamare un nuovo operatore.", 18, BattleTheme.CY_DIM)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(700, 0)
		_results_box.add_child(empty)
		var owned_n: int = 0
		for cid in BattleContent.CHARACTERS:
			if RosterState.owns(roster, str(cid)):
				owned_n += 1
		_results_box.add_child(BattleTheme.make_label("COLLEZIONE: %d / %d OPERATORI" % [owned_n, BattleContent.CHARACTERS.size()], 16, BattleTheme.CY))
		var faces := HFlowContainer.new()
		faces.add_theme_constant_override("h_separation", 8)
		faces.add_theme_constant_override("v_separation", 8)
		for cid in BattleContent.CHARACTERS:
			if banner == "nuovi" and not Recruiting.NEW_IDS.has(str(cid)):
				continue
			var face := PortraitView.new().setup(str(cid), "icon")
			face.show_expression_text = false
			face.dimmed = not RosterState.owns(roster, str(cid))
			face.custom_minimum_size = Vector2(64, 64)
			faces.add_child(face)
		_results_box.add_child(faces)
		return
	var delay: float = 0.0
	for r in last_results:
		var def: Dictionary = BattleContent.CHARACTERS[str(r["char"])]
		var outcome: String = ""
		match str(r["outcome"]):
			"new":
				outcome = "NUOVO!"
			"copy":
				outcome = "COPIA +1  (%d/%d per il RANK UP)" % [int(r.get("copies", 0)), RosterState.rank_cost(int(r.get("rank", 0)))]
			_:
				outcome = "RANK MAX  +%d CREDITI" % int(r["refund"])
		var line := "%-6s %-11s %s" % [str(def["name"]).to_upper(), str(BattleTypes.RARITIES[int(r["rarity"])]).to_upper(), outcome]
		var l := BattleTheme.make_label(line, 22, RARITY_COLORS[clampi(int(r["rarity"]), 0, 3)])
		_results_box.add_child(l)
		if _reveal_rows:
			l.custom_minimum_size = Vector2(0, 30)
			RarityFx.reveal_row(self, l, int(r["rarity"]), delay)
			delay += float(RarityFx.STAGGER[clampi(int(r["rarity"]), 0, 3)])
	_reveal_rows = false


# Costo di un'azione scritto con le icone delle valute (crediti, nuclei, leghe) a destra del pulsante.
func _cost_row(b: Button, costs: Array, fs: int) -> void:
	var old: Node = b.get_node_or_null("cost_row")
	if old != null:
		b.remove_child(old)
		old.queue_free()
	var row := HBoxContainer.new()
	row.name = "cost_row"
	row.alignment = BoxContainer.ALIGNMENT_END
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_right = -16.0
	var col: Color = Color("#6b777c") if b.disabled else BattleTheme.WH
	for c in costs:
		var key: String = str(c[0])
		var item := GameIcon.line(key, GameIcon.currency_color(key) if not b.disabled else col, str(int(c[1])), fs, col, float(fs) + 6.0)
		item.add_theme_constant_override("separation", 5)
		row.add_child(item)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_child(row)
