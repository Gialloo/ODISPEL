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
var _status_label: Label
var _tab_buttons: Dictionary = {}
var guide_button: Button
var strategy_button: Button
var _team_page: Control
var _recruit_page: Control
var _equip_page: Control
var _equip_name: Label
var _equip_slots_box: VBoxContainer
var _equip_list: VBoxContainer
var _equip_action: HBoxContainer
var _equip_title: HudPanel
var _list_box: VBoxContainer
var _slots_box: HBoxContainer
var _detail_label: Label
var _detail_portrait: PortraitView
var _detail_title: Label
var _action_box: HBoxContainer
var _pity_label: Label
var _results_box: VBoxContainer
var _pull_buttons: Array = []
var _t: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var window: Window = get_window()
	if window != null:
		window.content_scale_size = Vector2i(1280, 720)
	if roster.is_empty():
		roster = RosterStore.load_or_new(save_path)
	_build()
	if selected == "" or not RosterState.owns(roster, selected):
		selected = str(roster["team"][0]) if not roster["team"].is_empty() else ""
	refresh()


# ---------- Costruzione ----------

func _build() -> void:
	ScreenFx.solid(self, BattleTheme.BK)

	var title := BattleTheme.make_label("ARCHIVIO OPERATORI", 40, BattleTheme.WH, true)
	title.position = Vector2(24, 10)
	add_child(title)
	var sub := BattleTheme.make_label("// SQUADRA E RECLUTAMENTO", 15, BattleTheme.CY_DIM)
	sub.position = Vector2(28, 62)
	add_child(sub)

	_coins_label = BattleTheme.make_label("", 22, BattleTheme.CY, true)
	_coins_label.position = Vector2(820, 14)
	_coins_label.size = Vector2(440, 30)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_coins_label)
	_mats_label = BattleTheme.make_label("", 16, BattleTheme.CY_DIM)
	_mats_label.position = Vector2(700, 48)
	_mats_label.size = Vector2(560, 24)
	_mats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_mats_label)

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

	ScreenFx.menu_overlays(self, BattleTheme.RD)


# Sul telefono le liste lunghe si scorrono con il dito; sul PC restano com'erano.
func _set_scrolled(panel: HudPanel, box: VBoxContainer) -> void:
	if not TouchUi.active():
		panel.set_content(box)
		return
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	panel.set_content(scroll)


func _page() -> Control:
	var p := Control.new()
	p.position = Vector2(0, 144)
	p.size = Vector2(1280, 508)
	add_child(p)
	return p


func _build_team_page() -> void:
	_team_page = _page()

	var coll := HudPanel.new().setup("COLLEZIONE", BattleTheme.CY)
	coll.position = Vector2(20, 14)
	coll.size = Vector2(430, 494)
	_team_page.add_child(coll)
	_list_box = VBoxContainer.new()
	_list_box.add_theme_constant_override("separation", 3)
	_set_scrolled(coll, _list_box)

	var squad := HudPanel.new().setup("SQUADRA ATTIVA", BattleTheme.RD)
	squad.position = Vector2(466, 14)
	squad.size = Vector2(794, 120)
	_team_page.add_child(squad)
	_slots_box = HBoxContainer.new()
	_slots_box.add_theme_constant_override("separation", 10)
	squad.set_content(_slots_box)
	var auto := Button.new()
	auto.text = "SQUADRA MIGLIORE"
	auto.position = Vector2(1010, 2)
	auto.size = Vector2(236, 28)
	BattleTheme.style_button(auto, "normal", 14)
	auto.pressed.connect(auto_team)
	squad.add_child(auto)

	var card := HudPanel.new().setup("SCHEDA", BattleTheme.CY)
	card.position = Vector2(466, 150)
	card.size = Vector2(794, 358)
	_team_page.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	card.set_content(col)
	_detail_title = BattleTheme.make_label("", 30, BattleTheme.WH, true)
	col.add_child(_detail_title)
	_detail_label = BattleTheme.make_label("", 16, BattleTheme.CY)
	_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_detail_label)
	_action_box = HBoxContainer.new()
	_action_box.add_theme_constant_override("separation", 10)
	col.add_child(_action_box)
	# illustrazione dell'operatore (la tua grafica `splash.png`, o il segnaposto)
	_detail_portrait = PortraitView.new().setup("", "splash")
	_detail_portrait.show_expression_text = false
	_detail_portrait.position = Vector2(500.0, 36.0)
	_detail_portrait.size = Vector2(270.0, 250.0)
	card.add_child(_detail_portrait)


func _build_equip_page() -> void:
	_equip_page = _page()

	var who := HudPanel.new().setup("OPERATORE", BattleTheme.RD)
	who.position = Vector2(20, 14)
	who.size = Vector2(430, 88 if TouchUi.active() else 72)
	_equip_page.add_child(who)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	who.set_content(row)
	var prev := Button.new()
	prev.text = "<"
	prev.custom_minimum_size = Vector2(50, 0)
	BattleTheme.style_button(prev, "normal", 20)
	prev.pressed.connect(cycle_char.bind(-1))
	row.add_child(prev)
	_equip_name = BattleTheme.make_label("", 22, BattleTheme.WH, true)
	_equip_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equip_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equip_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_equip_name)
	var nxt := Button.new()
	nxt.text = ">"
	nxt.custom_minimum_size = Vector2(50, 0)
	BattleTheme.style_button(nxt, "normal", 20)
	nxt.pressed.connect(cycle_char.bind(1))
	row.add_child(nxt)

	var slots := HudPanel.new().setup("SLOT", BattleTheme.CY)
	slots.position = Vector2(20, 114 if TouchUi.active() else 102)
	slots.size = Vector2(430, 394 if TouchUi.active() else 406)
	_equip_page.add_child(slots)
	_equip_slots_box = VBoxContainer.new()
	_equip_slots_box.add_theme_constant_override("separation", 3)
	_set_scrolled(slots, _equip_slots_box)

	_equip_title = HudPanel.new().setup("INVENTARIO", BattleTheme.CY)
	_equip_title.position = Vector2(466, 14)
	_equip_title.size = Vector2(794, 494)
	_equip_page.add_child(_equip_title)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_equip_title.set_content(col)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_equip_list = VBoxContainer.new()
	_equip_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equip_list.add_theme_constant_override("separation", 3)
	scroll.add_child(_equip_list)
	_equip_action = HBoxContainer.new()
	col.add_child(_equip_action)


func _build_recruit_page() -> void:
	_recruit_page = _page()

	var info := HudPanel.new().setup("RECLUTAMENTO", BattleTheme.RD)
	info.position = Vector2(20, 14)
	info.size = Vector2(430, 494)
	_recruit_page.add_child(info)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	info.set_content(col)
	_pity_label = BattleTheme.make_label("", 16, BattleTheme.CY)
	_pity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_pity_label)
	for entry in [[1, "RECLUTA x1"], [10, "RECLUTA x10"]]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 64)
		BattleTheme.style_button(b, "primary", 24)
		b.pressed.connect(pull.bind(int(entry[0])))
		col.add_child(b)
		_pull_buttons.append([b, int(entry[0]), str(entry[1])])
	var guide := Button.new()
	guide.text = "COME FUNZIONA  ?"
	guide.custom_minimum_size = Vector2(0, 46)
	BattleTheme.style_button(guide, "normal", 20)
	guide.pressed.connect(open_gacha_guide)
	col.add_child(guide)
	guide_button = guide
	var odds: Array = BattleContent.rarity_odds()
	var note := BattleTheme.make_label("Quote: comune %d%% · rara %d%% · epica %d%% · leggendaria %d%%.\nLe copie aumentano il rank (max 5).\nIl x10 garantisce almeno un raro." % [odds[0], odds[1], odds[2], odds[3]], 14, BattleTheme.CY_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(note)

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
	tab = name
	refresh()
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
		var msgs: Dictionary = {"max": "Livello massimo.", "monete": "Monete insufficienti.",
			"nucleo": "Nuclei insufficienti.", "sconosciuto": "Personaggio non posseduto."}
		return _say(str(msgs.get(err, "Non riuscito: " + err)), false)
	_save()
	return _say("%s sale al livello %d." % [BattleContent.CHARACTERS[char_id]["name"], int(roster["characters"][char_id]["level"])], true)


func pull(count: int) -> bool:
	var s: int = next_seed if next_seed != 0 else (int(randi()) | 1)
	var r: Dictionary = Recruiting.pull(roster, count, s)
	if not bool(r["ok"]):
		last_results = []
		if str(r["error"]) == "monete":
			return _say("Servono %d monete." % int(r["cost"]), false)
		return _say("Reclutamento non riuscito.", false)
	last_results = r["results"]
	_save()
	if DisplayServer.get_name() != "headless":
		PullReveal.play(self, last_results)
	_announce_pulls(last_results)
	return _say("Reclutamento completato (-%d monete)." % int(r["cost"]), true)


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
		var msgs: Dictionary = {"max": "Pezzo al livello massimo.", "monete": "Monete insufficienti.",
			"lega": "Leghe insufficienti.", "sconosciuto": "Pezzo sconosciuto."}
		return _say(str(msgs.get(err, "Non riuscito: " + err)), false)
	_save()
	return _say("Pezzo potenziato al livello %d." % int(roster["gear"][gear_id]["level"]), true)


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


# ---------- Aggiornamento grafico ----------

func refresh() -> void:
	if _list_box == null:
		return
	_coins_label.text = "MONETE %d" % int(roster["coins"])
	var mats: Dictionary = roster["materials"]
	_mats_label.text = "NUCLEI %d   LEGHE %d" % [int(mats.get("nucleo", 0)), int(mats.get("lega", 0))]
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
	for id in ids:
		var def: Dictionary = BattleContent.CHARACTERS[id]
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 40)
		b.clip_text = true
		if RosterState.owns(roster, id):
			var e: Dictionary = roster["characters"][id]
			var mark: String = "[SQ] " if (roster["team"] as Array).has(id) else "     "
			b.text = "%s%-6s Lv%-2d %s" % [mark, str(def["name"]).to_upper(), int(e["level"]), _stars(int(e["rank"]))]
			BattleTheme.style_button(b, "primary" if id == selected else "normal", 17)
			b.pressed.connect(select.bind(id))
		else:
			b.text = "      ???    non reclutato"
			BattleTheme.style_button(b, "normal", 17)
			b.disabled = true
		b.set_meta("char_id", id)
		_list_box.add_child(b)


func _refresh_slots() -> void:
	_clear(_slots_box)
	var team: Array = roster["team"]
	for i in BattleTypes.TEAM_SIZE:
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if i < team.size():
			var id: String = str(team[i])
			var e: Dictionary = roster["characters"][id]
			var def: Dictionary = BattleContent.CHARACTERS[id]
			b.text = "%d. %s\nLv%d  %s" % [i + 1, str(def["name"]).to_upper(), int(e["level"]), str(def["color"]).to_upper()]
		else:
			b.text = "%d. (vuoto)" % (i + 1)
		BattleTheme.style_button(b, "primary" if i == slot_target else "normal", 17)
		b.pressed.connect(select_slot.bind(i))
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
	_detail_title.text = str(def["name"]).to_upper()
	_detail_portrait.visible = true
	if _detail_portrait.char_id != selected:
		_detail_portrait.setup(selected, "splash")
	_detail_title.add_theme_color_override("font_color", BattleTheme.unit_color(str(def["color"])))
	var skills: Array = []
	for s in e["skills"]:
		skills.append(BattleText.move_name(str(s)))
	var passives: Array = []
	for p in e["passives"]:
		passives.append(str(BattleContent.PASSIVES[str(p)]["name"]))
	var lines: Array = []
	lines.append("%s  |  %s  |  %s" % [str(def["color"]).to_upper(), str(def["cls"]).to_upper(), str(BattleTypes.RARITIES[int(def["rarity"])]).to_upper()])
	lines.append("LIVELLO %d/%d    RANK %s" % [int(e["level"]), RosterState.MAX_LEVEL, _stars(int(e["rank"]))])
	var faction: String = BattleContent.faction_of(selected)
	if faction != "":
		lines.append("%s  |  %s  |  %s" % [Factions.name_of(faction).to_upper(), str(Factions.FACTIONS[faction]["doctrine"]).to_upper(), BattleContent.style_of(selected, e).to_upper()])
	lines.append("")
	lines.append("PV  %-6d ATK %-5d" % [int(st["hp"]), int(st["atk"])])
	lines.append("DEF %-6d VEL %-5d" % [int(st["def"]), int(st["spd"])])
	lines.append("")
	lines.append("SKILL     %s" % (", ".join(skills) if not skills.is_empty() else "-"))
	lines.append("ULTIMATE  %s" % BattleText.move_name(str(e["ult"])))
	lines.append("PASSIVA   %s" % (", ".join(passives) if not passives.is_empty() else "-"))
	_detail_label.text = "\n".join(lines)

	var in_team: bool = (roster["team"] as Array).has(selected)
	var tb := Button.new()
	tb.custom_minimum_size = Vector2(0, 50)
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.clip_text = true
	tb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if in_team:
		tb.text = "TOGLI" if TouchUi.active() else "TOGLI DALLA SQUADRA"
	elif (roster["team"] as Array).size() < BattleTypes.TEAM_SIZE:
		tb.text = "METTI" if TouchUi.active() else "METTI IN SQUADRA"
	else:
		var tgt: String = str(roster["team"][clampi(slot_target, 0, (roster["team"] as Array).size() - 1)])
		tb.text = "AL POSTO DI %s" % str(BattleContent.CHARACTERS[tgt]["name"]).to_upper()
	BattleTheme.style_button(tb, "normal", 18)
	tb.pressed.connect(toggle_team.bind(selected))
	_action_box.add_child(tb)

	var ub := Button.new()
	ub.custom_minimum_size = Vector2(0, 50)
	ub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ub.clip_text = true
	ub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if int(e["level"]) >= RosterState.MAX_LEVEL:
		ub.text = "LIVELLO MASSIMO"
		ub.disabled = true
	else:
		var cost: Dictionary = BattleContent.character_upgrade_cost(int(e["level"]))
		ub.text = ("POTENZIA %dM+%dN" if TouchUi.active() else "POTENZIA  %dM + %dN") % [int(cost["coins"]), int(cost["nucleo"])]
		ub.size_flags_stretch_ratio = 1.6
	BattleTheme.style_button(ub, "primary", 18)
	ub.pressed.connect(upgrade.bind(selected))
	_action_box.add_child(ub)

	if faction != "":
		var sb := Button.new()
		sb.custom_minimum_size = Vector2(0, 50)
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.clip_text = true
		sb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		sb.text = "STILE: %s" % BattleContent.style_of(selected, e).to_upper()
		BattleTheme.style_button(sb, "normal", 18)
		sb.pressed.connect(toggle_style.bind(selected))
		_action_box.add_child(sb)

	var eb := Button.new()
	eb.text = "EQUIPAGGIO"
	eb.custom_minimum_size = Vector2(0, 50)
	eb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eb.clip_text = true
	eb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	BattleTheme.style_button(eb, "normal", 18)
	eb.pressed.connect(show_tab.bind("equip"))
	_action_box.add_child(eb)


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


func _item_button(text: String, kind: String, enabled: bool, id: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	b.clip_text = true
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	BattleTheme.style_button(b, kind, 16)
	b.disabled = not enabled
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

	for entry in EQUIP_SLOTS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 40)
		b.clip_text = true
		b.text = "%-9s %s" % [str(entry[1]), _slot_value_text(str(entry[0]))]
		BattleTheme.style_button(b, "primary" if str(entry[0]) == equip_slot else "normal", 15)
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
		_equip_list.add_child(_item_button(text, "primary" if is_current else "normal", is_current or free > 0, str(id)))


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
		_equip_list.add_child(_item_button(text, "primary" if owner_id == selected else "normal", true, gid))
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
			ub.text = "POTENZIA PEZZO  %dM + %dL" % [int(cost["coins"]), int(cost["lega"])]
		BattleTheme.style_button(ub, "primary", 18)
		ub.pressed.connect(upgrade_gear.bind(cur))
		_equip_action.add_child(ub)


func _refresh_recruit() -> void:
	var left: int = Recruiting.PITY_LIMIT - int(roster["pity"])
	_pity_label.text = "Reclutamenti totali: %d\nEpico garantito entro %d reclutamenti.\nMonete: %d" % [int(roster["pulls"]), left, int(roster["coins"])]
	for entry in _pull_buttons:
		var b: Button = entry[0]
		var cost: int = Recruiting.cost_for(int(entry[1]))
		b.text = "%s  (%d)" % [str(entry[2]), cost]
		b.disabled = int(roster["coins"]) < cost
		BattleTheme.style_button(b, "primary", 24)

	_clear(_results_box)
	if last_results.is_empty():
		_results_box.add_child(BattleTheme.make_label("Nessun reclutamento ancora.", 18, BattleTheme.CY_DIM))
		return
	for r in last_results:
		var def: Dictionary = BattleContent.CHARACTERS[str(r["char"])]
		var outcome: String = ""
		match str(r["outcome"]):
			"new":
				outcome = "NUOVO!"
			"rank":
				outcome = "RANK +1"
			_:
				outcome = "RANK MAX  +%d monete" % int(r["refund"])
		var line := "%-6s %-11s %s" % [str(def["name"]).to_upper(), str(BattleTypes.RARITIES[int(r["rarity"])]).to_upper(), outcome]
		var l := BattleTheme.make_label(line, 22, RARITY_COLORS[clampi(int(r["rarity"]), 0, 3)])
		_results_box.add_child(l)
