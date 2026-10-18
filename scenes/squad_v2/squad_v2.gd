class_name SquadV2
extends Control

# SQUADRA V2 (prova): schermata "Ashen Vow Interface" unita all'EQUIPAGGIO.
# Prima del TEST V2: scegli la squadra, potenzia gli operatori, equipaggia mosse e pezzi, poi COMBATTI
# (passando dalla schermata di caricamento). Usa la logica vera (RosterState); non tocca le schermate originali.
#
# Prestazioni: niente _process e niente ridisegno per fotogramma. Sfondo, lastra e pannello sono nodi statici
# (Polygon2D / TextureRect); i colori cambiano con un Tween; le carte del roster si creano una volta e si aggiornano.

const W: int = 1280
const H: int = 720
const INK := Color("#0F0D10")
const CREAM := Color("#EDE6D8")
const EQUIP_SLOTS: Array = [
	["skill0", "MOSSA 1"], ["skill1", "MOSSA 2"], ["skill2", "MOSSA 3"], ["skill3", "MOSSA 4"], ["ult", "ULTIMATE"],
	["passive0", "PASSIVA 1"], ["passive1", "PASSIVA 2"],
	["arma", "ARMA"], ["petto", "PETTO"], ["stivali", "STIVALI"],
]
const TABS: Array = [["potenzia", "POTENZIA"], ["equip", "EQUIPAGGIO"], ["leggenda", "LEGGENDA"]]
# un kanji per operatore (come nell'originale Ashen Vow); in mancanza, quello della classe
const KANJI: Dictionary = {
	"kira": "煌", "dax": "鉄", "elle": "翠", "bruno": "蒼", "nova": "星", "mira": "澪", "rex": "紅", "ivo": "藍",
	"sera": "緑", "eco": "響", "tana": "灯", "nico": "炎", "dafne": "花", "angela": "天", "moro": "烈", "vesper": "宵",
	"nami": "波", "oriel": "鏡", "silex": "石", "yuna": "雪", "rhea": "潮", "flux": "流", "cato": "影", "lyra": "琴",
}
const KANJI_CLASS: Dictionary = {"striker": "刃", "vanguard": "盾", "warden": "守"}

static var _fonts: Dictionary = {}
static var boost: float = 1.0      # testi piccoli piu' grandi su telefono (stessi punti di partenza, nessuno spostamento)


static func fs(sz: int) -> int:
	return sz if sz > 22 else int(round(float(sz) * boost))


var roster: Dictionary = {}
var save_path: String = RosterStore.DEFAULT_PATH
var selected: String = ""
var tab: String = "potenzia"      # potenzia | equip | leggenda
var equip_slot: String = ""       # "" = elenco slot, altrimenti inventario di quello slot
var slot_target: int = 0          # posto della squadra sostituito quando e' piena
var status_text: String = ""

var accent: Color = Color("#8a5cff"):
	set(v):
		accent = v
		_apply_accent()

var stage: Control
var slab: Polygon2D
var panel_bar: ColorRect
var kanji_label: Label
var portrait: PortraitView
var name_label: Label
var sub_label: Label
var epithet_label: Label
var num_label: Label
var res_label: Label
var tag_label: Label
var status_label: Label
var stat_box: VBoxContainer
var tab_buttons: Array = []
var content_scroll: ScrollContainer
var content: VBoxContainer
var strip_scroll: ScrollContainer
var strip: HBoxContainer
var cta_toggle: _AButton
var cta_fight: _AButton
var _cards: Dictionary = {}       # id -> _Card
var _strip_sig: String = ""
var _accent_tween: Tween
var _intro_tween: Tween
var _pending_scroll: float = -1.0


static func font_hud() -> Font:
	return BattleTheme.hud()


static func font_display() -> Font:
	return _font("display", func() -> Font: return BattleTheme.display(), 1)


static func font_caps() -> Font:
	return _font("caps", func() -> Font: return BattleTheme.hud(), 2)


static func font_serif() -> Font:
	return _font("serif", func() -> Font: return BattleTheme.font("LibreCaslonCondensed-Bold"), 0)


static func font_kanji() -> Font:
	return _font("kanji", func() -> Font: return BattleTheme.font("NotoSerifJP-Black-subset"), 0)


static func _font(key: String, base: Callable, spacing: int) -> Font:
	if not _fonts.has(key):
		var fv := FontVariation.new()
		fv.base_font = base.call()
		fv.spacing_glyph = spacing
		_fonts[key] = fv
	return _fonts[key]


func _ready() -> void:
	boost = 1.22 if TouchUi.active() else 1.0
	roster = RosterStore.load_or_new()
	var team: Array = roster["team"]
	selected = str(team[0]) if not team.is_empty() else str(roster["characters"].keys()[0])
	slot_target = maxi(team.size() - 1, 0)
	_build()
	resized.connect(_center)
	_center()
	accent = _color_of(selected)
	refresh(false, true)
	_intro()


func _center() -> void:
	if stage != null:
		var k: float = minf(size.x / float(W), size.y / float(H))
		stage.scale = Vector2(k, k)
		stage.position = ((size - Vector2(W, H) * k) * 0.5).floor()


func _color_of(id: String) -> Color:
	return BattleTheme.unit_color(str(BattleContent.CHARACTERS[id]["color"]))


# ---------- costruzione (una volta sola) ----------

func _lbl(text: String, sz: int, col: Color, pos: Vector2, dim: Vector2, font: Font, align: int = HORIZONTAL_ALIGNMENT_LEFT, parent: Node = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", fs(sz))
	l.add_theme_color_override("font_color", col)
	l.position = pos
	l.size = dim
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.clip_text = true
	(parent if parent != null else stage).add_child(l)
	return l


func _hatch_texture() -> Texture2D:
	# tassello 9x17: righe sottili inclinate, come lo sfondo di Ashen Vow
	var img := Image.create(9, 17, false, Image.FORMAT_RGBA8)
	for y in 17:
		var x: int = int(round(float(y) * 9.0 / 17.0)) % 9
		img.set_pixel(x, y, Color(0.93, 0.9, 0.85, 0.05))
	return ImageTexture.create_from_image(img)


func _build() -> void:
	stage = Control.new()
	stage.size = Vector2(W, H)
	stage.clip_contents = true
	add_child(stage)
	var bg := ColorRect.new()
	bg.color = INK
	bg.size = Vector2(W, H)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(bg)
	var hatch := TextureRect.new()
	hatch.texture = _hatch_texture()
	hatch.stretch_mode = TextureRect.STRETCH_TILE
	hatch.size = Vector2(W, H)
	hatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(hatch)
	# lastra inclinata colorata + striscia crema
	slab = Polygon2D.new()
	slab.polygon = PackedVector2Array([Vector2(338 + 0.34 * 500, -50), Vector2(838, -50), Vector2(338 + 0.66 * 500, 770), Vector2(338, 770)])
	stage.add_child(slab)
	var stripe := Polygon2D.new()
	stripe.polygon = PackedVector2Array([Vector2(730 + 0.7 * 108, -50), Vector2(838, -50), Vector2(730 + 0.3 * 108, 770), Vector2(730, 770)])
	stripe.color = Color(0.93, 0.9, 0.85, 0.08)
	stage.add_child(stripe)
	var line := ColorRect.new()
	line.color = Color(0.93, 0.9, 0.85, 0.12)
	line.position = Vector2(0, 548)
	line.size = Vector2(840, 2)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(line)
	# kanji gigante sulla lastra
	kanji_label = _lbl("", 460, Color(INK, 0.3), Vector2(340, 40), Vector2(480, 560), font_kanji(), HORIZONTAL_ALIGNMENT_CENTER)
	kanji_label.clip_text = false
	# testo verticale sul bordo destro
	_lbl("分\n隊", 16, Color(CREAM, 0.55), Vector2(1244, 150), Vector2(24, 60), font_kanji(), HORIZONTAL_ALIGNMENT_CENTER).clip_text = false
	_embers()

	portrait = PortraitView.new()
	portrait.size = Vector2(440, 560)
	portrait.position = Vector2(420, 70)
	stage.add_child(portrait)

	_lbl("ODISPEL", 30, CREAM, Vector2(44, 26), Vector2(220, 36), font_display())
	_lbl("TEST V2   ·   SQUADRA", 13, Color(CREAM, 0.7), Vector2(44, 60), Vector2(300, 22), font_caps())
	_lbl("■ SINCRONIZZATO", 12, Color(CREAM, 0.55), Vector2(44, 700), Vector2(240, 18), font_caps())
	res_label = _lbl("", 15, CREAM, Vector2(500, 30), Vector2(610, 30), font_hud(), HORIZONTAL_ALIGNMENT_RIGHT)
	var bb := _AButton.new()
	bb.kind = "ghost"
	bb.text = "‹ HUB"
	bb.font_size = 14
	bb.position = Vector2(1130, 22)
	bb.size = Vector2(96, 36)
	bb.pressed.connect(func() -> void: SceneRouter.go("hub"))
	stage.add_child(bb)

	# nastro crema con la classe
	var tag := ColorRect.new()
	tag.color = CREAM
	tag.position = Vector2(846, 80)
	tag.size = Vector2(190, 28)
	tag.rotation = deg_to_rad(-4.0)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(tag)
	tag_label = _lbl("", 13, INK, Vector2(12, 0), Vector2(170, 28), font_caps(), HORIZONTAL_ALIGNMENT_LEFT, tag)

	# identita' (sinistra)
	num_label = _lbl("", 15, CREAM, Vector2(44, 120), Vector2(380, 22), font_caps())
	name_label = _lbl("", 96, CREAM, Vector2(44, 140), Vector2(420, 112), font_display())
	name_label.clip_text = false
	sub_label = _lbl("", 18, Color(CREAM, 0.8), Vector2(44, 262), Vector2(380, 28), font_caps())
	epithet_label = _lbl("", 26, CREAM, Vector2(44, 300), Vector2(340, 90), font_serif())
	epithet_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	epithet_label.clip_text = false
	epithet_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	# pannello dossier (angoli tagliati) a destra
	var dossier := Polygon2D.new()
	var c: float = 36.0
	var dw: float = 396.0
	var dh: float = 480.0
	dossier.position = Vector2(838, 100)
	dossier.polygon = PackedVector2Array([Vector2(0, 0), Vector2(dw - c, 0), Vector2(dw, c), Vector2(dw, dh), Vector2(c, dh), Vector2(0, dh - c)])
	dossier.color = Color(0.09, 0.078, 0.102, 0.95)
	stage.add_child(dossier)
	panel_bar = ColorRect.new()
	panel_bar.position = Vector2(838, 100)
	panel_bar.size = Vector2(6, 110)
	panel_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(panel_bar)
	stat_box = VBoxContainer.new()
	stat_box.position = Vector2(868, 120)
	stat_box.size = Vector2(340, 120)
	stat_box.add_theme_constant_override("separation", 4)
	stage.add_child(stat_box)
	var tab_box := HBoxContainer.new()
	tab_box.position = Vector2(868, 252)
	tab_box.size = Vector2(340, 36)
	tab_box.add_theme_constant_override("separation", 6)
	stage.add_child(tab_box)
	for t in TABS:
		var b := _AButton.new()
		b.kind = "tab"
		b.text = t[1]
		b.font_size = 13
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 36)
		b.pressed.connect(_set_tab.bind(str(t[0])))
		tab_box.add_child(b)
		tab_buttons.append(b)
	content_scroll = ScrollContainer.new()
	content_scroll.position = Vector2(862, 296)
	content_scroll.size = Vector2(352, 276)
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.get_v_scroll_bar().modulate.a = 0.35
	stage.add_child(content_scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.custom_minimum_size = Vector2(344, 0)
	content.add_theme_constant_override("separation", 4)
	content_scroll.add_child(content)

	# striscia operatori
	strip_scroll = ScrollContainer.new()
	strip_scroll.position = Vector2(30, 556)
	strip_scroll.size = Vector2(790, 150)
	strip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip_scroll.get_h_scroll_bar().modulate.a = 0.0
	stage.add_child(strip_scroll)
	strip = HBoxContainer.new()
	strip.add_theme_constant_override("separation", 6)
	strip_scroll.add_child(strip)

	# azioni
	status_label = _lbl("", 14, Color(CREAM, 0.75), Vector2(838, 584), Vector2(396, 24), font_hud(), HORIZONTAL_ALIGNMENT_RIGHT)
	cta_toggle = _AButton.new()
	cta_toggle.kind = "ghostcta"
	cta_toggle.font_size = 16
	cta_toggle.position = Vector2(838, 612)
	cta_toggle.size = Vector2(396, 42)
	cta_toggle.pressed.connect(toggle_team)
	stage.add_child(cta_toggle)
	cta_fight = _AButton.new()
	cta_fight.kind = "cta"
	cta_fight.font_size = 28
	cta_fight.text = "COMBATTI"
	cta_fight.position = Vector2(838, 660)
	cta_fight.size = Vector2(396, 54)
	cta_fight.pressed.connect(fight)
	stage.add_child(cta_fight)


func _embers() -> void:
	var em := CPUParticles2D.new()
	em.position = Vector2(560, 740)
	em.amount = 12
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


func _apply_accent() -> void:
	if slab == null:
		return
	slab.color = Color(accent.r * 0.8, accent.g * 0.8, accent.b * 0.8, 0.92)
	panel_bar.color = accent
	for b in tab_buttons:
		b.accent = accent
		b.queue_redraw()
	cta_fight.accent = accent
	cta_toggle.accent = accent


# Entrata di un operatore: il ritratto e il nome scivolano dentro con un piccolo rimbalzo.
func _intro() -> void:
	if _intro_tween != null:
		_intro_tween.kill()
	portrait.position = Vector2(490, 70)
	portrait.modulate.a = 0.0
	name_label.position.x = 4.0
	name_label.modulate.a = 0.0
	kanji_label.modulate.a = 0.0
	_intro_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(portrait, "position:x", 420.0, 0.45)
	_intro_tween.tween_property(name_label, "position:x", 44.0, 0.45)
	_intro_tween.tween_property(portrait, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_LINEAR)
	_intro_tween.tween_property(name_label, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_LINEAR)
	_intro_tween.tween_property(kanji_label, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_LINEAR)


func _set_tab(t: String) -> void:
	tab = t
	equip_slot = ""
	refresh(false)


func select(id: String) -> void:
	if not RosterState.owns(roster, id) or id == selected:
		return
	selected = id
	equip_slot = ""
	status_text = ""
	var idx: int = (roster["team"] as Array).find(id)
	if idx >= 0:
		slot_target = idx
	Settings.buzz(12)
	var to: Color = _color_of(id)
	if _accent_tween != null:
		_accent_tween.kill()
	_accent_tween = create_tween()
	_accent_tween.tween_property(self, "accent", to, 0.25)
	_intro()
	refresh(false)


func cycle(dir: int) -> void:
	var ids: Array = _strip_ids()
	var i: int = ids.find(selected)
	select(str(ids[posmod(i + dir, ids.size())]))


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A:
				cycle(-1)
			KEY_RIGHT, KEY_D:
				cycle(1)
			KEY_ENTER, KEY_KP_ENTER:
				fight()


# ---------- azioni (stessa logica della schermata Roster) ----------

func _say(text: String, ok: bool, keep_scroll: bool = true) -> bool:
	status_text = text
	refresh(keep_scroll)
	return ok


func _save() -> void:
	RosterStore.save(roster, save_path)


func team_ids() -> Array:
	return roster["team"]


func toggle_team() -> bool:
	var team: Array = team_ids().duplicate()
	var id: String = selected
	var msg: String
	if team.has(id):
		if team.size() <= 1:
			return _say("Serve almeno un operatore in squadra.", false)
		team.erase(id)
		slot_target = clampi(slot_target, 0, team.size() - 1)
		msg = "%s lascia la squadra." % _name_of(id)
	elif team.size() < BattleTypes.TEAM_SIZE:
		team.append(id)
		msg = "%s entra in squadra." % _name_of(id)
	else:
		var out: String = str(team[clampi(slot_target, 0, team.size() - 1)])
		team[clampi(slot_target, 0, team.size() - 1)] = id
		msg = "%s prende il posto di %s." % [_name_of(id), _name_of(out)]
	if not RosterState.set_team(roster, team):
		return _say("Squadra non valida.", false)
	_save()
	Settings.buzz(25)
	var ok: bool = _say(msg, true)
	if _cards.has(id):
		(_cards[id] as _Card).pop()
	return ok


func _name_of(id: String) -> String:
	return str(BattleContent.CHARACTERS[id]["name"])


func upgrade() -> bool:
	var err: String = RosterState.level_up_character(roster, selected)
	if err != "":
		var msgs: Dictionary = {"max": "Livello massimo.", "monete": "CREDITI insufficienti.", "nucleo": "Nuclei insufficienti."}
		return _say(str(msgs.get(err, "Non riuscito: " + err)), false)
	_save()
	Settings.buzz(30)
	return _say("%s sale al livello %d." % [_name_of(selected), int(roster["characters"][selected]["level"])], true)


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
	refresh(true)


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


# Si combatte con la squadra scelta, passando dalla schermata di caricamento del progetto.
func fight() -> void:
	_save()
	Settings.buzz(40)
	WorldV2Ctx.reset()           # il Test V2 parte dalla mappa: il combattimento comincia con un incontro
	WorldV2Ctx.active = true
	WorldV2Ctx.persist = true     # scoperte e tag di vernice restano tra una sessione e l'altra (file a parte, non il salvataggio)
	WorldV2Ctx.load_persist()
	SceneRouter.go("world_v2", true)


# ---------- aggiornamento ----------

func refresh(keep_scroll: bool = true, first: bool = false) -> void:
	var def: Dictionary = BattleContent.CHARACTERS[selected]
	var e: Dictionary = roster["characters"][selected]
	var team: Array = team_ids()
	if portrait.char_id != selected:
		portrait.setup(selected, "splash")
	var idx: int = team.find(selected)
	kanji_label.text = str(KANJI.get(selected, KANJI_CLASS.get(str(def["cls"]), "刃")))
	tag_label.text = "CLASSE · %s" % str(def["cls"]).to_upper()
	num_label.text = ("No. %02d" % (idx + 1) if idx >= 0 else "RISERVA") + "   —   %s" % str(def["cls"]).to_upper()
	name_label.text = str(def["name"]).to_upper()
	name_label.add_theme_font_size_override("font_size", 96 if name_label.text.length() <= 5 else 72)
	var arch: Dictionary = Archetypes.DEFS.get(Archetypes.of_def(def), {})
	sub_label.text = "%s  ·  %s" % [str(def["color"]).to_upper(), str(arch.get("name", "")).to_upper()]
	epithet_label.text = str(Lore.character_text(selected).get("tag", ""))
	var mats: Dictionary = roster["materials"]
	res_label.text = "CREDITI %d    NUCLEI %d    LEGHE %d" % [int(roster["coins"]), int(mats.get("nucleo", 0)), int(mats.get("lega", 0))]
	status_label.text = status_text
	_refresh_stats(e)
	for i in tab_buttons.size():
		var b: _AButton = tab_buttons[i]
		b.on = tab == str(TABS[i][0])
		b.queue_redraw()
	_refresh_strip()
	_refresh_actions(team)
	var keep: int = content_scroll.scroll_vertical if keep_scroll else 0
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	match tab:
		"potenzia":
			_build_potenzia(e)
		"equip":
			_build_equip(e)
		_:
			_build_leggenda(def, e)
	content_scroll.scroll_vertical = keep
	if keep > 0:
		content_scroll.set_deferred("scroll_vertical", keep)


func _refresh_actions(team: Array) -> void:
	var in_team: bool = team.has(selected)
	if in_team:
		cta_toggle.text = "SCIOGLI DALLA SQUADRA   %d/%d" % [team.size(), BattleTypes.TEAM_SIZE]
	elif team.size() < BattleTypes.TEAM_SIZE:
		cta_toggle.text = "LEGA ALLA SQUADRA   %d/%d" % [team.size(), BattleTypes.TEAM_SIZE]
	else:
		cta_toggle.text = "AL POSTO DI %s" % _name_of(str(team[clampi(slot_target, 0, team.size() - 1)])).to_upper()
	cta_toggle.on = in_team
	cta_toggle.queue_redraw()
	cta_fight.text = "COMBATTI   ·   %d" % team.size()
	cta_fight.queue_redraw()


func _strip_ids() -> Array:
	var ids: Array = team_ids().duplicate()
	var rest: Array = roster["characters"].keys()
	rest.sort()
	for id in rest:
		if not ids.has(id):
			ids.append(id)
	return ids


func _refresh_strip() -> void:
	var ids: Array = _strip_ids()
	var team: Array = team_ids()
	var sig: String = ",".join(PackedStringArray(ids)) + "|" + str(team.size())
	if sig != _strip_sig:
		# l'ordine (squadra prima, poi riserva) e' cambiato: si ricostruisce, conservando lo scorrimento
		var keep: int = strip_scroll.scroll_horizontal
		for c in strip.get_children():
			strip.remove_child(c)
			c.queue_free()
		_cards.clear()
		var divided: bool = false
		for id in ids:
			if not divided and not team.has(id):
				divided = true
				var gap := Control.new()
				gap.custom_minimum_size = Vector2(18, 0)
				gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
				strip.add_child(gap)
			var card := _Card.new()
			card.custom_minimum_size = Vector2(132, 134)
			card.char_id = str(id)
			card.label = _name_of(str(id)).to_upper()
			card.col = _color_of(str(id))
			card.pressed.connect(select.bind(str(id)))
			strip.add_child(card)
			_cards[id] = card
		_strip_sig = sig
		strip_scroll.set_deferred("scroll_horizontal", keep)
	for id in ids:
		var card: _Card = _cards[id]
		card.on = id == selected
		card.team_pos = team.find(id) + 1
		card.level = int(roster["characters"][id]["level"])
		card.queue_redraw()
	# tiene in vista la carta scelta
	_show_selected.call_deferred()


func _show_selected() -> void:
	var card: Control = _cards.get(selected)
	if card != null and is_instance_valid(card) and card.is_inside_tree() and strip.is_ancestor_of(card):
		strip_scroll.ensure_control_visible(card)


func _refresh_stats(e: Dictionary) -> void:
	for c in stat_box.get_children():
		stat_box.remove_child(c)
		c.queue_free()
	var icons: Array = Profile.owned_icons()
	var st: Dictionary = BattleContent.compute_stats(Power.entry_of(roster, selected, icons))
	var maxes: Dictionary = {"hp": 1.0, "atk": 1.0, "def": 1.0, "spd": 1.0}
	for id in roster["characters"]:
		var s2: Dictionary = BattleContent.compute_stats(Power.entry_of(roster, str(id), icons))
		for k in maxes:
			maxes[k] = maxf(float(maxes[k]), float(s2[k]))
	for row in [["PV", "hp"], ["ATTACCO", "atk"], ["DIFESA", "def"], ["VELOCITA'", "spd"]]:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		hb.add_child(_stat_label(row[0], 14, font_hud(), Color(CREAM, 0.7), 96, HORIZONTAL_ALIGNMENT_LEFT))
		var bar := _Bar.new()
		bar.frac = float(st[row[1]]) / float(maxes[row[1]])
		bar.col = accent_target()
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size = Vector2(0, 24)
		hb.add_child(bar)
		hb.add_child(_stat_label(str(int(st[row[1]])), 18, font_display(), CREAM, 52, HORIZONTAL_ALIGNMENT_RIGHT))
		stat_box.add_child(hb)
	var pw: Dictionary = Power.breakdown(roster, selected, icons)
	var pl := _stat_label("POTERE %d  ·  LIV %d  ·  RANK %d" % [int(pw["total"]), int(e["level"]), int(e["rank"])], 15, font_hud(), accent_target().lightened(0.5), 0, HORIZONTAL_ALIGNMENT_LEFT)
	stat_box.add_child(pl)


func accent_target() -> Color:
	return _color_of(selected)


func _stat_label(t: String, sz: int, f: Font, col: Color, w: float, align: int) -> Label:
	var l := Label.new()
	l.text = t
	l.custom_minimum_size = Vector2(w, 24)
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", fs(sz))
	l.add_theme_font_override("font", f)
	l.add_theme_color_override("font_color", col)
	return l


# ---------- contenuto delle schede ----------

func _btn(text: String, kind: String, enabled: bool, cb: Callable, h: float = 40.0) -> _AButton:
	var b := _AButton.new()
	b.text = text
	b.kind = "sel" if kind == "primary" else "row"
	b.accent = accent_target()
	b.font_size = 15
	b.custom_minimum_size = Vector2(0, maxf(h, 44.0) if TouchUi.active() else h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = not enabled
	b.pressed.connect(cb)
	content.add_child(b)
	return b


func _text(t: String, sz: int = 15, col: Color = CREAM) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", fs(sz))
	l.add_theme_font_override("font", font_hud())
	l.add_theme_color_override("font_color", col)
	l.custom_minimum_size = Vector2(340, 0)
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(l)
	return l


func _build_potenzia(e: Dictionary) -> void:
	var lvl: int = int(e["level"])
	if lvl >= RosterState.MAX_LEVEL:
		_btn("LIVELLO MASSIMO", "normal", false, upgrade, 48)
	else:
		var c: Dictionary = BattleContent.character_upgrade_cost(lvl)
		_btn("POTENZIA  LIV %d › %d     %d CR  ·  %d NUCLEI" % [lvl, lvl + 1, int(c["coins"]), int(c["nucleo"])], "primary", true, upgrade, 48)
	var rank: int = int(e["rank"])
	if rank >= RosterState.MAX_RANK:
		_btn("RANK MASSIMO", "normal", false, rank_up)
	else:
		var can: bool = RosterState.can_rank_up(roster, selected)
		_btn("RANK UP   COPIE %d / %d" % [RosterState.copies(roster, selected), RosterState.rank_cost(rank)], "primary" if can else "normal", can, rank_up)
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
	var base: Dictionary = BattleContent.GEAR_BASE[str(g["slot"])]
	for k in base:
		parts.append("%s +%d" % [str(k).to_upper(), int(round(float(base[k]) * mult))])
	return "%s Lv%d  %s" % [str(BattleTypes.RARITIES[int(g["rarity"])]).to_upper(), int(g["level"]), " ".join(parts)]


func _open_slot(key: String) -> void:
	equip_slot = key
	refresh(false)


func _close_slot() -> void:
	equip_slot = ""
	refresh(false)


func _build_equip(e: Dictionary) -> void:
	if equip_slot == "":
		for entry in EQUIP_SLOTS:
			var key: String = str(entry[0])
			_btn("%s   %s" % [entry[1], _slot_value(key, e)], "normal", true, _open_slot.bind(key), 36)
		return
	var title: String = equip_slot
	for entry in EQUIP_SLOTS:
		if str(entry[0]) == equip_slot:
			title = str(entry[1])
	_btn("‹ %s" % title, "primary", true, _close_slot, 36)
	if equip_slot.begins_with("skill") or equip_slot == "ult" or equip_slot.begins_with("passive"):
		_equip_moves(equip_slot, e)
	else:
		_equip_gear(equip_slot)


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
			t += "  (su %s)" % _name_of(own).to_upper()
		_btn(t, "primary" if own == selected else "normal", true, equip_item.bind(gid), 36)
	if cur != "":
		var g2: Dictionary = roster["gear"][cur]
		if int(g2["level"]) >= int(BattleContent.GEAR_MAX_LEVEL[int(g2["rarity"])]):
			_btn("PEZZO AL LIVELLO MASSIMO", "normal", false, upgrade_gear.bind(cur))
		else:
			var c: Dictionary = BattleContent.gear_upgrade_cost(int(g2["rarity"]), int(g2["level"]))
			_btn("POTENZIA PEZZO   %d CR  ·  %d LEGHE" % [int(c["coins"]), int(c["lega"])], "primary", true, upgrade_gear.bind(cur), 42)


func _build_leggenda(def: Dictionary, e: Dictionary) -> void:
	var hi: Color = accent_target().lightened(0.4)
	_text("%s  ·  %s" % [str(def["cls"]).to_upper(), str(BattleTypes.RARITIES[int(def["rarity"])]).to_upper()], 15, hi)
	var arch: Dictionary = Archetypes.DEFS.get(Archetypes.of_def(def), {})
	_text("%s: %s" % [str(arch.get("name", "")), str(arch.get("line", ""))], 15)
	var faction: String = BattleContent.faction_of(selected)
	if faction != "":
		_text("%s  ·  %s" % [Factions.name_of(faction).to_upper(), BattleContent.style_of(selected, e).to_upper()], 15, hi)
		_text(Atypical.describe(selected), 14, Color(CREAM, 0.8))
	if Signatures.has_passive(selected):
		_text("★ %s: %s" % [Signatures.passive_name(selected), Signatures.passive_text(selected, int(e["rank"]))], 14, Color(CREAM, 0.85))
	_text("RANK %d: %s" % [int(e["rank"]), Signatures.rank_perk_text(selected, int(e["rank"]))], 14, Color(CREAM, 0.8))


# ---------- controlli disegnati ----------

# Base dei controlli toccabili: il tocco vale solo se rilasciato senza trascinare, cosi' le liste scorrono con il dito.
# MOUSE_FILTER_PASS fa arrivare il trascinamento al ScrollContainer sotto.
class _Tappable extends Control:
	signal pressed
	const DRAG_LIMIT: float = 12.0
	var disabled: bool = false
	var _down: bool = false
	var _from: Vector2 = Vector2.ZERO

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _on_down() -> void:
		pass

	func _on_up() -> void:
		pass

	func _gui_input(ev: InputEvent) -> void:
		if disabled:
			return
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_down = true
				_from = ev.position
				_on_down()
			elif _down:
				_down = false
				_on_up()
				if ev.position.distance_to(_from) < DRAG_LIMIT:
					pressed.emit()
		elif ev is InputEventMouseMotion and _down:
			if ev.position.distance_to(_from) >= DRAG_LIMIT:
				_down = false
				_on_up()


class _AButton extends _Tappable:
	var text: String = ""
	var kind: String = "row"      # row | sel | tab | cta | ghostcta | ghost
	var accent: Color = Color("#8a5cff")
	var on: bool = false
	var font_size: int = 15
	var _hover: bool = false
	var _held: bool = false

	func _ready() -> void:
		mouse_entered.connect(func() -> void:
			_hover = true
			queue_redraw())
		mouse_exited.connect(func() -> void:
			_hover = false
			queue_redraw())

	func _on_down() -> void:
		_held = true
		queue_redraw()

	func _on_up() -> void:
		_held = false
		queue_redraw()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var cream := SquadV2.CREAM
		var ink := SquadV2.INK
		var acc: Color = accent.lightened(0.15)
		var f: Font = SquadV2.font_caps() if kind in ["tab", "ghost"] else SquadV2.font_hud()
		var a: float = 0.35 if disabled else 1.0
		var fsz: int = mini(SquadV2.fs(font_size), 14) if kind == "tab" else SquadV2.fs(font_size)
		var ty: float = h * 0.5 + fsz * 0.36
		match kind:
			"cta":
				var bg: Color = cream.lerp(acc, 0.35 if _hover else 0.0).lerp(Color.WHITE, 0.0).darkened(0.12 if _held else 0.0)
				draw_colored_polygon(PackedVector2Array([Vector2(w * 0.08, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]), bg)
				draw_string(SquadV2.font_display(), Vector2(w * 0.12 + 6, ty), text, HORIZONTAL_ALIGNMENT_LEFT, w * 0.7, fsz, ink)
				var ax: float = w - 52.0
				var ay: float = h * 0.5
				draw_line(Vector2(ax, ay), Vector2(ax + 30, ay), ink, 2.5)
				draw_polyline(PackedVector2Array([Vector2(ax + 23, ay - 7), Vector2(ax + 31, ay), Vector2(ax + 23, ay + 7)]), ink, 2.5)
			"ghostcta":
				var pts := PackedVector2Array([Vector2(w * 0.06, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)])
				var fill: Color = Color(acc, 0.28) if on else Color(cream, 0.06 + (0.06 if _hover else 0.0) + (0.14 if _held else 0.0))
				draw_colored_polygon(pts, fill)
				pts.append(pts[0])
				draw_polyline(pts, Color(acc if on else cream, 0.55 if on else 0.4), 1.0)
				draw_string(f, Vector2(w * 0.1 + 6, ty), text, HORIZONTAL_ALIGNMENT_LEFT, w * 0.85, fsz, cream)
			"ghost":
				draw_rect(Rect2(0, h - 2, w, 2), Color(cream, 0.55 if _hover or _held else 0.3))
				draw_string(f, Vector2(0, ty), text, HORIZONTAL_ALIGNMENT_CENTER, w, fsz, cream)
			"tab":
				draw_rect(Rect2(0, h - 1, w, 1), Color(cream, 0.16))
				if on:
					draw_rect(Rect2(0, h - 2, w, 2), acc)
				draw_string(f, Vector2(0, ty), text, HORIZONTAL_ALIGNMENT_CENTER, w, fsz, cream if on else Color(cream, 0.6))
			_:
				if kind == "sel":
					draw_rect(Rect2(0, 0, w, h), Color(accent, 0.28))
					draw_rect(Rect2(0, 0, 4, h), acc)
				elif _hover or _held:
					draw_rect(Rect2(0, 0, w, h), Color(cream, 0.06 + (0.08 if _held else 0.0)))
				draw_rect(Rect2(0, h - 1, w, 1), Color(cream, 0.1))
				draw_string(f, Vector2(16, ty), text, HORIZONTAL_ALIGNMENT_LEFT, w - 24, fsz, Color(cream, a))


class _Bar extends Control:
	var frac: float = 0.5
	var col: Color = Color.WHITE

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var y: float = size.y * 0.5
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.93, 0.9, 0.85, 0.22), 1.0)
		var w: float = size.x * clampf(frac, 0.04, 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 3), Vector2(w, y - 3), Vector2(w - 5, y + 3), Vector2(0, y + 3)]), col)


class _Card extends _Tappable:
	var char_id: String = ""
	var label: String = ""
	var col: Color = Color.WHITE
	var on: bool = false
	var team_pos: int = 0
	var level: int = 1
	var _tex: Texture2D = null
	var _pop: float = 0.0

	func _ready() -> void:
		_tex = ArtLibrary.icon(char_id)
		pivot_offset = custom_minimum_size * 0.5

	# piccolo rimbalzo quando entra o esce dalla squadra
	func pop() -> void:
		var tw: Tween = create_tween()
		tw.tween_property(self, "scale", Vector2(1.08, 1.08), 0.08)
		tw.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var lift: float = 0.0 if on else 14.0
		var poly := PackedVector2Array([Vector2(w * 0.14, lift), Vector2(w, lift), Vector2(w * 0.86, h - 6), Vector2(0, h - 6)])
		draw_colored_polygon(poly, Color(col.r * 0.8, col.g * 0.8, col.b * 0.8, 1.0) if on else Color(0.13, 0.115, 0.15, 1.0))
		if _tex != null:
			draw_texture_rect(_tex, Rect2(14, lift + 2, w - 40, h - lift - 36), false)
		else:
			draw_string(SquadV2.font_display(), Vector2(24, h - 42), label.substr(0, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 64, Color(1, 1, 1, 0.16))
		draw_rect(Rect2(0, h - 50, w, 44), Color(0.06, 0.05, 0.063, 0.8))
		draw_string(SquadV2.font_display(), Vector2(12, h - 20), label, HORIZONTAL_ALIGNMENT_LEFT, w - 16, SquadV2.fs(17), SquadV2.CREAM)
		draw_string(SquadV2.font_hud(), Vector2(w * 0.4, lift + 20), "LV %d" % level, HORIZONTAL_ALIGNMENT_RIGHT, w * 0.5, SquadV2.fs(14), SquadV2.CREAM)
		if team_pos > 0:
			draw_string(SquadV2.font_display(), Vector2(w * 0.2, lift + 22), str(team_pos), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, SquadV2.INK if on else Color("#F6B37A"))
			draw_rect(Rect2(0, h - 6, w, 6), col)
		else:
			draw_rect(Rect2(0, h - 6, w, 2), Color(1, 1, 1, 0.14))
