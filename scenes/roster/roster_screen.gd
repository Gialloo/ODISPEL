extends Control

# Squadra e reclutamento: collezione, composizione della squadra da 3,
# potenziamento dei personaggi e reclutamento (singolo / x10).
# Ogni modifica viene salvata subito su save_path.

const HUB_SCENE: String = "res://scenes/hub/hub_demo.tscn"
const RARITY_COLORS: Array = [Color("#c9dde2"), Color("#7cf0ff"), Color("#b07bff"), Color("#ffd25f")]

var roster: Dictionary = {}
var save_path: String = RosterStore.DEFAULT_PATH
var tab: String = "squadra"          # "squadra" | "reclutamento"
var selected: String = ""            # personaggio mostrato nella scheda
var slot_target: int = 2             # posto della squadra sostituito quando e' piena
var status_text: String = ""
var last_results: Array = []
var next_seed: int = 0               # 0 = casuale; i test lo fissano

var _coins_label: Label
var _mats_label: Label
var _status_label: Label
var _tab_buttons: Dictionary = {}
var _team_page: Control
var _recruit_page: Control
var _list_box: VBoxContainer
var _slots_box: HBoxContainer
var _detail_label: Label
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
	var bg := ColorRect.new()
	bg.color = BattleTheme.BK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

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
	for entry in [["squadra", "SQUADRA"], ["reclutamento", "RECLUTAMENTO"]]:
		var b := Button.new()
		b.text = str(entry[1])
		b.position = Vector2(x, 90)
		b.size = Vector2(230, 40)
		BattleTheme.style_button(b, "normal", 20)
		b.pressed.connect(show_tab.bind(str(entry[0])))
		add_child(b)
		_tab_buttons[str(entry[0])] = b
		x += 242.0

	_build_team_page()
	_build_recruit_page()

	var back := Button.new()
	back.text = "TORNA ALL'HUB"
	back.position = Vector2(24, 664)
	back.size = Vector2(250, 44)
	BattleTheme.style_button(back, "normal", 20)
	back.pressed.connect(_on_back)
	add_child(back)

	_status_label = BattleTheme.make_label("", 16, BattleTheme.WH)
	_status_label.position = Vector2(296, 674)
	_status_label.size = Vector2(960, 28)
	add_child(_status_label)

	var cctv := ColorRect.new()
	cctv.set_anchors_preset(Control.PRESET_FULL_RECT)
	cctv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/cctv_overlay.gdshader")
	cctv.material = mat
	add_child(cctv)


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
	coll.set_content(_list_box)

	var squad := HudPanel.new().setup("SQUADRA ATTIVA", BattleTheme.RD)
	squad.position = Vector2(466, 14)
	squad.size = Vector2(794, 120)
	_team_page.add_child(squad)
	_slots_box = HBoxContainer.new()
	_slots_box.add_theme_constant_override("separation", 10)
	squad.set_content(_slots_box)

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
	var note := BattleTheme.make_label("Le copie aumentano il rank (max 5).\nA rank massimo si ottengono monete.\nIl x10 garantisce almeno un raro.", 14, BattleTheme.CY_DIM)
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
	return _say("Reclutamento completato (-%d monete)." % int(r["cost"]), true)


func _say(text: String, ok: bool) -> bool:
	status_text = text
	refresh()
	if _status_label != null:
		_status_label.add_theme_color_override("font_color", BattleTheme.WH if ok else BattleTheme.RD)
	return ok


func _save() -> void:
	RosterStore.save(roster, save_path)


func _on_back() -> void:
	var error := get_tree().change_scene_to_file(HUB_SCENE)
	if error != OK:
		push_error("Impossibile tornare all'hub. Codice: " + str(error))


# ---------- Aggiornamento grafico ----------

func refresh() -> void:
	if _list_box == null:
		return
	_coins_label.text = "MONETE %d" % int(roster["coins"])
	var mats: Dictionary = roster["materials"]
	_mats_label.text = "NUCLEI %d   LEGHE %d" % [int(mats.get("nucleo", 0)), int(mats.get("lega", 0))]
	_status_label.text = status_text
	_team_page.visible = tab == "squadra"
	_recruit_page.visible = tab == "reclutamento"
	for k in _tab_buttons:
		BattleTheme.style_button(_tab_buttons[k], "primary" if k == tab else "normal", 20)
	if tab == "squadra":
		_refresh_list()
		_refresh_slots()
		_refresh_detail()
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
		return
	var def: Dictionary = BattleContent.CHARACTERS[selected]
	var e: Dictionary = roster["characters"][selected]
	var st: Dictionary = BattleContent.compute_stats(e)
	_detail_title.text = str(def["name"]).to_upper()
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
	if in_team:
		tb.text = "TOGLI DALLA SQUADRA"
	elif (roster["team"] as Array).size() < BattleTypes.TEAM_SIZE:
		tb.text = "METTI IN SQUADRA"
	else:
		var tgt: String = str(roster["team"][clampi(slot_target, 0, (roster["team"] as Array).size() - 1)])
		tb.text = "AL POSTO DI %s" % str(BattleContent.CHARACTERS[tgt]["name"]).to_upper()
	BattleTheme.style_button(tb, "normal", 18)
	tb.pressed.connect(toggle_team.bind(selected))
	_action_box.add_child(tb)

	var ub := Button.new()
	ub.custom_minimum_size = Vector2(0, 50)
	ub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if int(e["level"]) >= RosterState.MAX_LEVEL:
		ub.text = "LIVELLO MASSIMO"
		ub.disabled = true
	else:
		var cost: Dictionary = BattleContent.character_upgrade_cost(int(e["level"]))
		ub.text = "POTENZIA  %dM + %dN" % [int(cost["coins"]), int(cost["nucleo"])]
	BattleTheme.style_button(ub, "primary", 18)
	ub.pressed.connect(upgrade.bind(selected))
	_action_box.add_child(ub)


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
