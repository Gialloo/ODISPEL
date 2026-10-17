class_name SquadV2
extends Control

# SQUADRA V2 (prova): schermata "Ashen Vow Interface" unita all'EQUIPAGGIO.
# Prima del TEST V2: scegli la squadra, potenzia gli operatori, equipaggia mosse e pezzi, poi COMBATTI.
# Usa la logica vera (RosterState); non tocca le schermate originali.

const W: int = 1280
const H: int = 720
const INK := Color("#0F0D10")
const CREAM := Color("#EDE6D8")
const PANEL := Color(0.09, 0.078, 0.102, 0.95)
const EQUIP_SLOTS: Array = [
	["skill0", "MOSSA 1"], ["skill1", "MOSSA 2"], ["skill2", "MOSSA 3"], ["skill3", "MOSSA 4"], ["ult", "ULTIMATE"],
	["passive0", "PASSIVA 1"], ["passive1", "PASSIVA 2"],
	["arma", "ARMA"], ["petto", "PETTO"], ["stivali", "STIVALI"],
]

var roster: Dictionary = {}
var save_path: String = RosterStore.DEFAULT_PATH
var selected: String = ""
var tab: String = "potenzia"      # potenzia | equip | leggenda
var equip_slot: String = ""       # "" = elenco slot, altrimenti inventario di quello slot
var status_text: String = ""

var stage: Control
var back: _Back
var portrait: PortraitView
var name_label: Label
var sub_label: Label
var epithet_label: Label
var num_label: Label
var res_label: Label
var dossier_node: Control
var tag_rect: ColorRect
var tag_label: Label
var stat_box: VBoxContainer
var tab_box: HBoxContainer
var content: VBoxContainer
var strip: HBoxContainer
var cta_toggle: _AButton
var cta_fight: _AButton
var status_label: Label
var _appear: float = 1.0
var _accent: Color = Color("#8a5cff")
var _accent_to: Color = Color("#8a5cff")
var _cards: Dictionary = {}


func _ready() -> void:
	roster = RosterStore.load_or_new()
	var team: Array = roster["team"]
	selected = str(team[0]) if not team.is_empty() else str(roster["characters"].keys()[0])
	_build()
	resized.connect(_center)
	_center()
	refresh()


func _center() -> void:
	if stage != null:
		var k: float = minf(size.x / float(W), size.y / float(H))
		stage.scale = Vector2(k, k)
		stage.position = ((size - Vector2(W, H) * k) * 0.5).floor()


func _process(delta: float) -> void:
	_accent = _accent.lerp(_accent_to, clampf(delta * 9.0, 0.0, 1.0))
	if _appear < 1.0:
		_appear = minf(1.0, _appear + delta * 2.6)
	var e: float = _ease_out_back(_appear)
	portrait.position = Vector2(420.0 - (1.0 - e) * 70.0, 70.0)
	portrait.modulate.a = clampf(_appear * 2.2, 0.0, 1.0)
	name_label.position.x = 44.0 - (1.0 - e) * 40.0
	name_label.modulate.a = clampf(_appear * 2.5, 0.0, 1.0)
	back.accent = _accent
	back.queue_redraw()
	dossier_node.queue_redraw()


static func _ease_out_back(t: float) -> float:
	var c1: float = 1.70158
	var c3: float = c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)


func _lbl(text: String, sz: int, col: Color, pos: Vector2, dim: Vector2, display: bool = true, align: int = HORIZONTAL_ALIGNMENT_LEFT, parent: Node = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", BattleTheme.display() if display else BattleTheme.hud())
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.position = pos
	l.size = dim
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.clip_text = true
	(parent if parent != null else stage).add_child(l)
	return l


func _build() -> void:
	stage = Control.new()
	stage.size = Vector2(W, H)
	stage.clip_contents = true
	add_child(stage)
	back = _Back.new()
	back.size = Vector2(W, H)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(back)
	# braci che salgono
	var em := CPUParticles2D.new()
	em.position = Vector2(560, 740)
	em.amount = 14
	em.lifetime = 6.0
	em.preprocess = 6.0
	em.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	em.emission_rect_extents = Vector2(320, 4)
	em.direction = Vector2(0, -1)
	em.spread = 12.0
	em.initial_velocity_min = 40.0
	em.initial_velocity_max = 90.0
	em.scale_amount_min = 2.0
	em.scale_amount_max = 4.0
	em.color = Color("#F6B37A")
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	em.material = mat
	stage.add_child(em)

	portrait = PortraitView.new()
	portrait.size = Vector2(440, 560)
	stage.add_child(portrait)

	# titolo
	_lbl("ODISPEL", 30, CREAM, Vector2(44, 26), Vector2(220, 36))
	_lbl("TEST V2   ·   SQUADRA", 13, Color(CREAM, 0.7), Vector2(44, 60), Vector2(260, 22), false)
	res_label = _lbl("", 15, CREAM, Vector2(500, 30), Vector2(610, 30), false, HORIZONTAL_ALIGNMENT_RIGHT)
	var bb := _AButton.new()
	bb.kind = "ghost"
	bb.text = "‹ HUB"
	bb.font_size = 14
	bb.position = Vector2(1130, 22)
	bb.size = Vector2(96, 36)
	bb.pressed.connect(func() -> void: SceneRouter.go("hub"))
	stage.add_child(bb)

	# etichetta classe (nastro crema inclinato)
	tag_rect = ColorRect.new()
	tag_rect.color = CREAM
	tag_rect.position = Vector2(846, 80)
	tag_rect.size = Vector2(190, 28)
	tag_rect.rotation = deg_to_rad(-4.0)
	tag_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(tag_rect)
	tag_label = _lbl("", 13, INK, Vector2(12, 0), Vector2(170, 28), false, HORIZONTAL_ALIGNMENT_LEFT, tag_rect)
	tag_label.add_theme_font_override("font", spaced(BattleTheme.hud(), 2))
	# piede: stato
	_lbl("■ SINCRONIZZATO", 12, Color(CREAM, 0.55), Vector2(44, 700), Vector2(240, 18), false).add_theme_font_override("font", spaced(BattleTheme.hud(), 2))

	# identita' (sinistra)
	num_label = _lbl("", 15, CREAM, Vector2(44, 120), Vector2(380, 22), false)
	name_label = _lbl("", 96, CREAM, Vector2(44, 140), Vector2(420, 112))
	name_label.clip_text = false
	sub_label = _lbl("", 18, Color(CREAM, 0.8), Vector2(44, 262), Vector2(380, 28), false)
	epithet_label = _lbl("", 17, CREAM, Vector2(44, 296), Vector2(340, 90), false)
	epithet_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	epithet_label.clip_text = false
	epithet_label.add_theme_font_override("font", BattleTheme.font("LibreCaslonCondensed-Bold"))
	epithet_label.add_theme_font_size_override("font_size", 26)
	epithet_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	# dossier (destra)
	var dossier := _Dossier.new()
	dossier.position = Vector2(838, 100)
	dossier.size = Vector2(396, 480)
	dossier.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dossier.owner_ref = self
	dossier_node = dossier
	stage.add_child(dossier)
	stat_box = VBoxContainer.new()
	stat_box.position = Vector2(868, 120)
	stat_box.size = Vector2(340, 120)
	stat_box.add_theme_constant_override("separation", 4)
	stage.add_child(stat_box)
	tab_box = HBoxContainer.new()
	tab_box.position = Vector2(868, 252)
	tab_box.size = Vector2(340, 36)
	tab_box.add_theme_constant_override("separation", 6)
	stage.add_child(tab_box)
	for t in [["potenzia", "POTENZIA"], ["equip", "EQUIPAGGIO"], ["leggenda", "LEGGENDA"]]:
		var b := _AButton.new()
		b.kind = "tab"
		b.text = t[1]
		b.font_size = 13
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 36)
		b.pressed.connect(_set_tab.bind(str(t[0])))
		tab_box.add_child(b)
	var sc := ScrollContainer.new()
	sc.position = Vector2(862, 296)
	sc.size = Vector2(352, 276)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stage.add_child(sc)
	sc.get_v_scroll_bar().modulate.a = 0.35
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.custom_minimum_size = Vector2(344, 0)
	content.add_theme_constant_override("separation", 6)
	sc.add_child(content)

	# striscia operatori
	var ssc := ScrollContainer.new()
	ssc.position = Vector2(30, 560)
	ssc.size = Vector2(790, 140)
	ssc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ssc.get_h_scroll_bar().modulate.a = 0.0
	stage.add_child(ssc)
	strip = HBoxContainer.new()
	strip.add_theme_constant_override("separation", 6)
	ssc.add_child(strip)

	# CTA
	status_label = _lbl("", 14, Color(CREAM, 0.75), Vector2(838, 586), Vector2(396, 22), false, HORIZONTAL_ALIGNMENT_RIGHT)
	cta_toggle = _AButton.new()
	cta_toggle.kind = "ghostcta"
	cta_toggle.font_size = 16
	cta_toggle.position = Vector2(838, 612)
	cta_toggle.size = Vector2(396, 42)
	cta_toggle.pressed.connect(toggle_team.bind(""))
	stage.add_child(cta_toggle)
	cta_fight = _AButton.new()
	cta_fight.kind = "cta"
	cta_fight.font_size = 28
	cta_fight.position = Vector2(838, 660)
	cta_fight.size = Vector2(396, 54)
	cta_fight.pressed.connect(fight)
	stage.add_child(cta_fight)


func _set_tab(t: String) -> void:
	tab = t
	equip_slot = ""
	refresh()


func select(id: String) -> void:
	if not RosterState.owns(roster, id) or id == selected:
		return
	selected = id
	equip_slot = ""
	status_text = ""
	_appear = 0.0
	Settings.buzz(12)
	refresh()


# ---------- azioni (stessa logica della schermata Roster) ----------

func _say(text: String, ok: bool) -> bool:
	status_text = text
	refresh()
	return ok


func _save() -> void:
	RosterStore.save(roster, save_path)


func toggle_team(char_id: String = "") -> bool:
	if char_id == "":
		char_id = selected
	var team: Array = (roster["team"] as Array).duplicate()
	if team.has(char_id):
		if team.size() <= 1:
			return _say("Serve almeno un operatore in squadra.", false)
		team.erase(char_id)
	elif team.size() < BattleTypes.TEAM_SIZE:
		team.append(char_id)
	else:
		return _say("Squadra piena (%d). Togli prima qualcuno." % BattleTypes.TEAM_SIZE, false)
	if not RosterState.set_team(roster, team):
		return _say("Squadra non valida.", false)
	_save()
	return _say("Squadra aggiornata.", true)


func upgrade() -> bool:
	var err: String = RosterState.level_up_character(roster, selected)
	if err != "":
		var msgs: Dictionary = {"max": "Livello massimo.", "monete": "CREDITI insufficienti.", "nucleo": "Nuclei insufficienti."}
		return _say(str(msgs.get(err, "Non riuscito: " + err)), false)
	_save()
	Settings.buzz(30)
	_appear = 0.5
	return _say("%s sale al livello %d." % [BattleContent.CHARACTERS[selected]["name"], int(roster["characters"][selected]["level"])], true)


func rank_up() -> bool:
	if not RosterState.rank_up(roster, selected):
		return _say("Copie insufficienti per il rank up.", false)
	_save()
	Settings.buzz(40)
	return _say("Rank up!", true)


func toggle_style() -> void:
	var now: String = BattleContent.style_of(selected, roster["characters"][selected])
	RosterState.set_style(roster, selected, "atipico" if now == "ortodosso" else "ortodosso")
	_save()
	refresh()


func gear_in_slot(char_id: String, slot: String) -> String:
	for gid in roster["gear"]:
		if str(roster["gear"][gid]["equipped_by"]) == char_id and str(roster["gear"][gid]["slot"]) == slot:
			return str(gid)
	return ""


func equip_item(item_id: String) -> bool:
	var key: String = equip_slot
	var ok: bool = false
	if key.begins_with("skill"):
		ok = RosterState.equip_skill(roster, selected, int(key.substr(5)), item_id)
	elif key == "ult":
		ok = RosterState.equip_ult(roster, selected, item_id)
	elif key.begins_with("passive"):
		ok = RosterState.equip_passive(roster, selected, int(key.substr(7)), item_id)
	elif item_id == "":
		var cur: String = gear_in_slot(selected, key)
		ok = cur == "" or RosterState.unequip_gear(roster, cur)
	else:
		ok = RosterState.equip_gear(roster, selected, item_id)
	if not ok:
		return _say("Non riuscito (nessuna copia libera o slot precedente vuoto).", false)
	_save()
	Settings.buzz(15)
	return _say("Equipaggiamento aggiornato.", true)


func upgrade_gear(gid: String) -> bool:
	var err: String = RosterState.level_up_gear(roster, gid)
	if err != "":
		return _say("Non riuscito: " + err, false)
	_save()
	return _say("Pezzo potenziato.", true)


func test_resources() -> void:
	roster["coins"] = int(roster["coins"]) + 5000
	roster["materials"]["nucleo"] = int(roster["materials"].get("nucleo", 0)) + 20
	roster["materials"]["lega"] = int(roster["materials"].get("lega", 0)) + 20
	_save()
	_say("Risorse di prova aggiunte.", true)


func fight() -> void:
	_save()
	Settings.buzz(40)
	SceneRouter.go("battle_v2")


# ---------- schermata ----------

func refresh() -> void:
	var def: Dictionary = BattleContent.CHARACTERS[selected]
	var e: Dictionary = roster["characters"][selected]
	_accent_to = BattleTheme.unit_color(str(def["color"]))
	var order: Array = (roster["team"] as Array).duplicate()
	var idx: int = order.find(selected)
	if portrait.char_id != selected:
		portrait.setup(selected, "splash")
	num_label.text = "No. %02d   —   %s" % [maxi(idx + 1, 0), str(def["cls"]).to_upper()]
	tag_label.text = "CLASSE · %s" % str(def["cls"]).to_upper()
	name_label.text = str(def["name"]).to_upper()
	name_label.add_theme_font_size_override("font_size", 96 if name_label.text.length() <= 5 else 72)
	var arch: Dictionary = Archetypes.DEFS.get(Archetypes.of_def(def), {})
	sub_label.text = "%s  ·  %s" % [str(def["color"]).to_upper(), str(arch.get("name", "")).to_upper()]
	epithet_label.text = str(Lore.character_text(selected).get("tag", ""))
	var mats: Dictionary = roster["materials"]
	res_label.text = "CREDITI %d    NUCLEI %d    LEGHE %d" % [int(roster["coins"]), int(mats.get("nucleo", 0)), int(mats.get("lega", 0))]
	status_label.text = status_text
	_refresh_stats(e)
	_refresh_tabs()
	_refresh_strip()
	var in_team: bool = order.has(selected)
	cta_toggle.text = ("SCIOGLI IL VINCOLO" if in_team else "LEGA ALLA SQUADRA") + "   %d/%d" % [order.size(), BattleTypes.TEAM_SIZE]
	cta_fight.accent = _accent_to
	cta_toggle.accent = _accent_to
	cta_fight.text = "COMBATTI"
	cta_fight.queue_redraw()
	cta_toggle.queue_redraw()
	for c in content.get_children():
		c.queue_free()
	match tab:
		"potenzia":
			_build_potenzia(e)
		"equip":
			_build_equip(e)
		_:
			_build_leggenda(def, e)


func _refresh_stats(e: Dictionary) -> void:
	for c in stat_box.get_children():
		c.queue_free()
	var st: Dictionary = BattleContent.compute_stats(Power.entry_of(roster, selected, Profile.owned_icons()))
	var maxes: Dictionary = {"hp": 1.0, "atk": 1.0, "def": 1.0, "spd": 1.0}
	for id in roster["characters"]:
		var s2: Dictionary = BattleContent.compute_stats(Power.entry_of(roster, str(id), Profile.owned_icons()))
		for k in maxes:
			maxes[k] = maxf(float(maxes[k]), float(s2[k]))
	for row in [["PV", "hp"], ["ATTACCO", "atk"], ["DIFESA", "def"], ["VELOCITA'", "spd"]]:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		var l := Label.new()
		l.text = row[0]
		l.custom_minimum_size = Vector2(96, 24)
		l.add_theme_font_size_override("font_size", 14)
		l.add_theme_color_override("font_color", Color(CREAM, 0.7))
		l.add_theme_font_override("font", BattleTheme.hud())
		hb.add_child(l)
		var bar := _Bar.new()
		bar.frac = float(st[row[1]]) / float(maxes[row[1]])
		bar.col = _accent_to
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size = Vector2(0, 24)
		hb.add_child(bar)
		var v := Label.new()
		v.text = str(int(st[row[1]]))
		v.custom_minimum_size = Vector2(52, 24)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.add_theme_font_size_override("font_size", 18)
		v.add_theme_font_override("font", BattleTheme.display())
		v.add_theme_color_override("font_color", CREAM)
		hb.add_child(v)
		stat_box.add_child(hb)
	var pw: Dictionary = Power.breakdown(roster, selected, Profile.owned_icons())
	var pl := Label.new()
	pl.text = "POTERE %d  ·  LIV %d  ·  RANK %d" % [int(pw["total"]), int(e["level"]), int(e["rank"])]
	pl.add_theme_font_size_override("font_size", 15)
	pl.add_theme_font_override("font", BattleTheme.hud())
	pl.add_theme_color_override("font_color", _accent_to.lightened(0.5))
	stat_box.add_child(pl)


func _refresh_tabs() -> void:
	var i: int = 0
	for t in ["potenzia", "equip", "leggenda"]:
		var b: _AButton = tab_box.get_child(i)
		b.on = tab == t
		b.accent = _accent_to
		b.queue_redraw()
		i += 1


func _refresh_strip() -> void:
	for c in strip.get_children():
		c.queue_free()
	var ids: Array = (roster["team"] as Array).duplicate()
	var rest: Array = roster["characters"].keys()
	rest.sort()
	for id in rest:
		if not ids.has(id):
			ids.append(id)
	for id in ids:
		var card := _Card.new()
		card.custom_minimum_size = Vector2(132, 126)
		card.char_id = str(id)
		var d: Dictionary = BattleContent.CHARACTERS[str(id)]
		card.col = BattleTheme.unit_color(str(d["color"]))
		card.on = str(id) == selected
		card.team_pos = (roster["team"] as Array).find(id) + 1
		card.level = int(roster["characters"][id]["level"])
		card.label = str(d["name"]).to_upper()
		card.pressed.connect(select.bind(str(id)))
		strip.add_child(card)


func _btn(text: String, kind: String, enabled: bool, cb: Callable, h: float = 40.0) -> _AButton:
	var b := _AButton.new()
	b.text = text
	b.kind = "sel" if kind == "primary" else "row"
	b.accent = _accent_to
	b.font_size = 15
	b.custom_minimum_size = Vector2(0, h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = not enabled
	b.pressed.connect(cb)
	content.add_child(b)
	return b


func _text(t: String, sz: int = 15, col: Color = CREAM) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_font_override("font", BattleTheme.hud())
	l.add_theme_color_override("font_color", col)
	l.custom_minimum_size = Vector2(340, 0)
	content.add_child(l)
	return l


func _build_potenzia(e: Dictionary) -> void:
	var lvl: int = int(e["level"])
	if lvl >= RosterState.MAX_LEVEL:
		_btn("LIVELLO MASSIMO", "normal", false, upgrade)
	else:
		var c: Dictionary = BattleContent.character_upgrade_cost(lvl)
		_btn("POTENZIA  LIV %d › %d     %d CR  ·  %d NUCLEI" % [lvl, lvl + 1, int(c["coins"]), int(c["nucleo"])], "primary", true, upgrade, 48)
	var rank: int = int(e["rank"])
	if rank >= RosterState.MAX_RANK:
		_btn("RANK MASSIMO", "normal", false, rank_up)
	else:
		_btn("RANK UP   COPIE %d / %d" % [RosterState.copies(roster, selected), RosterState.rank_cost(rank)], "primary" if RosterState.can_rank_up(roster, selected) else "normal", RosterState.can_rank_up(roster, selected), rank_up)
	if BattleContent.faction_of(selected) != "":
		_btn("STILE: %s" % BattleContent.style_of(selected, e).to_upper(), "normal", true, toggle_style)
	_btn("+ RISORSE DI PROVA (solo test)", "normal", true, test_resources, 34)
	var skills: Array = []
	for s in e["skills"]:
		skills.append(BattleText.move_name(str(s)))
	_text("MOSSE  " + (", ".join(skills) if not skills.is_empty() else "-"), 14, Color(CREAM, 0.8))
	_text("ULT  " + BattleText.move_name(str(e["ult"])), 14, Color(CREAM, 0.8))


func _slot_value(key: String, e: Dictionary) -> String:
	if key.begins_with("skill"):
		var i: int = int(key.substr(5))
		return BattleText.move_name(str(e["skills"][i])) if i < e["skills"].size() else "(vuoto)"
	if key == "ult":
		return BattleText.move_name(str(e["ult"]))
	if key.begins_with("passive"):
		var j: int = int(key.substr(7))
		return str(BattleContent.PASSIVES[str(e["passives"][j])]["name"]) if j < e["passives"].size() else "(vuoto)"
	var gid: String = gear_in_slot(selected, key)
	if gid == "":
		return "(vuoto)"
	var g: Dictionary = roster["gear"][gid]
	return "%s Lv%d" % [str(BattleTypes.RARITIES[int(g["rarity"])]).to_upper(), int(g["level"])]


func _gear_text(gid: String) -> String:
	var g: Dictionary = roster["gear"][gid]
	var rarity: int = clampi(int(g["rarity"]), 0, BattleContent.GEAR_RARITY_MULT.size() - 1)
	var mult: float = float(BattleContent.GEAR_RARITY_MULT[rarity]) * (1.0 + BattleContent.GEAR_LEVEL_BONUS * float(int(g["level"]) - 1))
	var parts: Array = []
	for k in BattleContent.GEAR_BASE[str(g["slot"])]:
		parts.append("%s +%d" % [str(k).to_upper(), int(round(float(BattleContent.GEAR_BASE[str(g["slot"])][k]) * mult))])
	return "%s Lv%d  %s" % [str(BattleTypes.RARITIES[int(g["rarity"])]).to_upper(), int(g["level"]), " ".join(parts)]


func _build_equip(e: Dictionary) -> void:
	if equip_slot == "":
		for entry in EQUIP_SLOTS:
			var key: String = str(entry[0])
			_btn("%-10s %s" % [entry[1], _slot_value(key, e)], "normal", true, func() -> void:
				equip_slot = key
				refresh(), 36)
		return
	var title: String = equip_slot
	for entry in EQUIP_SLOTS:
		if str(entry[0]) == equip_slot:
			title = str(entry[1])
	_btn("‹ %s" % title, "primary", true, func() -> void:
		equip_slot = ""
		refresh(), 36)
	var key2: String = equip_slot
	if key2.begins_with("skill") or key2 == "ult" or key2.begins_with("passive"):
		_equip_moves(key2, e)
	else:
		_equip_gear(key2)


func _equip_moves(key: String, e: Dictionary) -> void:
	var is_passive: bool = key.begins_with("passive")
	var field: String = "ult" if key == "ult" else ("passives" if is_passive else "skills")
	var current: String = ""
	if key.begins_with("skill"):
		var s: int = int(key.substr(5))
		current = str(e["skills"][s]) if s < e["skills"].size() else ""
	elif key == "ult":
		current = str(e["ult"])
	else:
		var p: int = int(key.substr(7))
		current = str(e["passives"][p]) if p < e["passives"].size() else ""
	if key != "ult":
		_btn("-- SVUOTA LO SLOT --", "normal", current != "", equip_item.bind(""), 34)
		if key.begins_with("skill"):
			for uid in Signatures.skills_for(selected, int(e["rank"])):
				_btn("%s%s  [unica]" % ["› " if str(uid) == current else "", BattleText.move_name(str(uid))], "primary" if str(uid) == current else "normal", true, equip_item.bind(str(uid)), 34)
			for bid in BattleTypes.BASIC_MOVES:
				_btn("%s%s  [base]" % ["› " if str(bid) == current else "", BattleText.move_name(str(bid))], "primary" if str(bid) == current else "normal", true, equip_item.bind(str(bid)), 34)
	var table: Dictionary = roster["passives"] if is_passive else roster["moves"]
	var ids: Array = table.keys()
	ids.sort()
	for id in ids:
		if not is_passive:
			var wanted: String = "skill" if key.begins_with("skill") else "ult"
			if not BattleContent.MOVES.has(id) or str(BattleContent.MOVES[id]["kind"]) != wanted:
				continue
		var owned: int = int(table[id])
		var free: int = owned - RosterState._used(roster, field, str(id))
		var cur: bool = str(id) == current
		var nm: String = str(BattleContent.PASSIVES[id]["name"]) if is_passive else BattleText.move_name(str(id))
		_btn("%s%s  [libere %d/%d]" % ["› " if cur else "", nm, free, owned], "primary" if cur else "normal", cur or free > 0, equip_item.bind(str(id)), 34)


func _equip_gear(key: String) -> void:
	var cur: String = gear_in_slot(selected, key)
	_btn("-- TOGLI IL PEZZO --", "normal", cur != "", equip_item.bind(""), 34)
	var ids: Array = []
	for gid in roster["gear"]:
		if str(roster["gear"][gid]["slot"]) == key:
			ids.append(str(gid))
	ids.sort()
	if ids.is_empty():
		_text("Nessun pezzo di questo tipo. Si trovano come premi.", 14, Color(CREAM, 0.6))
	for gid in ids:
		var g: Dictionary = roster["gear"][gid]
		var own: String = str(g["equipped_by"])
		var t: String = ("› " if own == selected else "") + _gear_text(gid)
		if own != "" and own != selected:
			t += "  (su %s)" % str(BattleContent.CHARACTERS[own]["name"]).to_upper()
		_btn(t, "primary" if own == selected else "normal", true, equip_item.bind(gid), 36)
	if cur != "":
		var g2: Dictionary = roster["gear"][cur]
		if int(g2["level"]) >= int(BattleContent.GEAR_MAX_LEVEL[int(g2["rarity"])]):
			_btn("PEZZO AL LIVELLO MASSIMO", "normal", false, upgrade_gear.bind(cur))
		else:
			var c: Dictionary = BattleContent.gear_upgrade_cost(int(g2["rarity"]), int(g2["level"]))
			_btn("POTENZIA PEZZO   %d CR  ·  %d LEGHE" % [int(c["coins"]), int(c["lega"])], "primary", true, upgrade_gear.bind(cur), 42)


func _build_leggenda(def: Dictionary, e: Dictionary) -> void:
	_text("%s  ·  %s" % [str(def["cls"]).to_upper(), str(BattleTypes.RARITIES[int(def["rarity"])]).to_upper()], 15, _accent_to.lightened(0.4))
	var arch: Dictionary = Archetypes.DEFS.get(Archetypes.of_def(def), {})
	_text("%s: %s" % [str(arch.get("name", "")), str(arch.get("line", ""))], 15)
	var faction: String = BattleContent.faction_of(selected)
	if faction != "":
		_text("%s  ·  %s" % [Factions.name_of(faction).to_upper(), BattleContent.style_of(selected, e).to_upper()], 15, _accent_to.lightened(0.4))
		_text(Atypical.describe(selected), 14, Color(CREAM, 0.8))
	if Signatures.has_passive(selected):
		_text("★ %s: %s" % [Signatures.passive_name(selected), Signatures.passive_text(selected, int(e["rank"]))], 14, Color(CREAM, 0.85))
	_text("RANK %d: %s" % [int(e["rank"]), Signatures.rank_perk_text(selected, int(e["rank"]))], 14, Color(CREAM, 0.8))


# ---------- parti disegnate ----------

static func spaced(base: Font, sp: float) -> Font:
	var fv := FontVariation.new()
	fv.base_font = base
	fv.spacing_glyph = int(sp)
	return fv


class _AButton extends Control:
	signal pressed
	var text: String = ""
	var kind: String = "row"      # row | sel | tab | cta | ghostcta | ghost
	var accent: Color = Color("#8a5cff")
	var on: bool = false
	var disabled: bool = false
	var font_size: int = 15
	var _hover: bool = false
	var _flash: float = 0.0

	func _ready() -> void:
		mouse_entered.connect(func() -> void:
			_hover = true
			queue_redraw())
		mouse_exited.connect(func() -> void:
			_hover = false
			queue_redraw())

	func _process(delta: float) -> void:
		if _flash > 0.0:
			_flash = maxf(0.0, _flash - delta * 4.0)
			queue_redraw()
			if _flash <= 0.0:
				set_process(false)

	func _gui_input(ev: InputEvent) -> void:
		if disabled:
			return
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			_flash = 1.0
			set_process(true)
			pressed.emit()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var cream := Color("#EDE6D8")
		var ink := Color("#0F0D10")
		var acc: Color = accent.lightened(0.15)
		var f: Font = SquadV2.spaced(BattleTheme.hud(), 1)
		var df: Font = SquadV2.spaced(BattleTheme.display(), 1)
		var a: float = 0.35 if disabled else 1.0
		match kind:
			"cta":
				var bg: Color = cream.lerp(acc, 0.0 if not _hover else 0.35).lerp(Color.WHITE, _flash * 0.6)
				draw_colored_polygon(PackedVector2Array([Vector2(w * 0.08, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]), bg)
				draw_string(df, Vector2(w * 0.12 + 6, h * 0.5 + font_size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, w * 0.6, font_size, ink)
				var ax: float = w - 52.0
				var ay: float = h * 0.5
				draw_line(Vector2(ax, ay), Vector2(ax + 30, ay), ink, 2.5)
				draw_polyline(PackedVector2Array([Vector2(ax + 23, ay - 7), Vector2(ax + 31, ay), Vector2(ax + 23, ay + 7)]), ink, 2.5)
			"ghostcta":
				var pts := PackedVector2Array([Vector2(w * 0.06, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)])
				draw_colored_polygon(pts, Color(cream, 0.06 + (0.06 if _hover else 0.0) + _flash * 0.2))
				pts.append(pts[0])
				draw_polyline(pts, Color(cream, 0.4), 1.0)
				draw_string(f, Vector2(w * 0.1 + 6, h * 0.5 + font_size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, w * 0.85, font_size, cream)
			"ghost":
				draw_rect(Rect2(0, h - 2, w, 2), Color(cream, 0.55 if _hover else 0.3))
				draw_string(f, Vector2(0, h * 0.5 + font_size * 0.36), text, HORIZONTAL_ALIGNMENT_CENTER, w, font_size, cream)
			"tab":
				draw_rect(Rect2(0, h - 1, w, 1), Color(cream, 0.16))
				if on:
					draw_rect(Rect2(0, h - 2, w, 2), acc)
				draw_string(f, Vector2(0, h * 0.5 + font_size * 0.36), text, HORIZONTAL_ALIGNMENT_CENTER, w, font_size, cream if on else Color(cream, 0.6))
			_:
				var sel: bool = kind == "sel"
				if sel:
					draw_rect(Rect2(0, 0, w, h), Color(accent, 0.28))
					draw_rect(Rect2(0, 0, 4, h), acc)
				elif _hover or _flash > 0.0:
					draw_rect(Rect2(0, 0, w, h), Color(cream, 0.06 + _flash * 0.12))
				draw_rect(Rect2(0, h - 1, w, 1), Color(cream, 0.1))
				draw_string(f, Vector2(16, h * 0.5 + font_size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, w - 24, font_size, Color(cream, a))


class _Back extends Control:
	var accent: Color = Color("#8a5cff")

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#0F0D10"))
		for i in range(-8, 100):
			var x: float = float(i) * 9.0 * 1.0
			draw_line(Vector2(x, 0), Vector2(x - 320.0, 720.0), Color(0.93, 0.9, 0.85, 0.028), 1.0)
		var a: Color = Color(accent.r * 0.8, accent.g * 0.8, accent.b * 0.8, 0.92)
		draw_colored_polygon(PackedVector2Array([Vector2(338 + 0.34 * 500, -50), Vector2(838, -50), Vector2(338 + 0.66 * 500, 770), Vector2(338, 770)]), a)
		draw_colored_polygon(PackedVector2Array([Vector2(730 + 0.7 * 108, -50), Vector2(838, -50), Vector2(730 + 0.3 * 108, 770), Vector2(730, 770)]), Color(0.93, 0.9, 0.85, 0.08))
		draw_rect(Rect2(0, 548, 840, 2), Color(0.93, 0.9, 0.85, 0.12))


class _Dossier extends Control:
	var owner_ref: SquadV2

	func _draw() -> void:
		var c: float = 36.0
		var pts := PackedVector2Array([Vector2(0, 0), Vector2(size.x - c, 0), Vector2(size.x, c), Vector2(size.x, size.y), Vector2(c, size.y), Vector2(0, size.y - c)])
		draw_colored_polygon(pts, Color(0.09, 0.078, 0.102, 0.95))
		draw_rect(Rect2(0, 0, 6, 110), owner_ref._accent if owner_ref != null else Color.WHITE)


class _Bar extends Control:
	var frac: float = 0.5
	var col: Color = Color.WHITE

	func _draw() -> void:
		var y: float = size.y * 0.5
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.93, 0.9, 0.85, 0.22), 1.0)
		var w: float = size.x * clampf(frac, 0.04, 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 3), Vector2(w, y - 3), Vector2(w - 5, y + 3), Vector2(0, y + 3)]), col)


class _Card extends Control:
	signal pressed
	var char_id: String = ""
	var label: String = ""
	var col: Color = Color.WHITE
	var on: bool = false
	var team_pos: int = 0
	var level: int = 1

	func _gui_input(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			pressed.emit()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var lift: float = 0.0 if on else 14.0
		var poly := PackedVector2Array([Vector2(w * 0.14, lift), Vector2(w, lift), Vector2(w * 0.86, h), Vector2(0, h)])
		var bg: Color = Color(col.r * 0.8, col.g * 0.8, col.b * 0.8, 1.0) if on else Color(0.13, 0.115, 0.15, 1.0)
		draw_colored_polygon(poly, bg)
		var tex: Texture2D = ArtLibrary.icon(char_id)
		if tex != null:
			draw_texture_rect(tex, Rect2(14, lift + 2, w - 40, h - lift - 30), false)
		else:
			var f: Font = BattleTheme.display()
			draw_string(f, Vector2(24, h - 36), label.substr(0, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 64, Color(1, 1, 1, 0.16))
		draw_rect(Rect2(0, h - 44, w, 44), Color(0.06, 0.05, 0.063, 0.8))
		draw_string(BattleTheme.display(), Vector2(12, h - 14), label, HORIZONTAL_ALIGNMENT_LEFT, w - 16, 17, Color("#EDE6D8"))
		draw_string(BattleTheme.hud(), Vector2(w * 0.4, lift + 20), "LV %d" % level, HORIZONTAL_ALIGNMENT_RIGHT, w * 0.5, 14, Color("#EDE6D8"))
		if team_pos > 0:
			draw_string(BattleTheme.display(), Vector2(w * 0.2, lift + 22), str(team_pos), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#F6B37A") if not on else Color("#0F0D10"))
		draw_rect(Rect2(0, h - 4, w, 4), col if team_pos > 0 else Color(1, 1, 1, 0.12))
