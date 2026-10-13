class_name FeatsScreen
extends Control

# Schermata OBIETTIVI: le imprese permanenti (Feats) con progresso e premio fisso, da riscuotere a mano.

const GROUP_ICONS: Dictionary = {"MISSIONI": "target", "BATTAGLIE": "sword", "OPERATORI": "striker", "POTENZIAMENTI": "arma"}

var roster: Dictionary = {}
var save_path: String = RosterStore.DEFAULT_PATH
var group: String = "DA RISCUOTERE"        # gruppo mostrato: "DA RISCUOTERE", "TUTTE" o uno di Feats.GROUPS
var group_buttons: Dictionary = {}
var claim_all_button: Button
var _list: VBoxContainer
var _summary: Label
var _coins: Label
var _mats: Label


func _ready() -> void:
	ScreenFrame.setup(self)   # riquadro 1280x720 nell'area sicura dello schermo
	if roster.is_empty():
		roster = RosterStore.load_or_new(save_path)
	_build()
	if Feats.claimable_count(roster) == 0:
		group = "TUTTE"
	refresh()


func _build() -> void:
	ScreenFx.solid(self, BattleTheme.BK)
	var title := BattleTheme.make_label("OBIETTIVI", 40, BattleTheme.WH, true)
	title.position = Vector2(24, 10)
	add_child(title)
	var sub := BattleTheme.make_label("// IMPRESE  ·  PREMI FISSI, NIENTE FORTUNA", 15, BattleTheme.CY_DIM)
	sub.position = Vector2(28, 62)
	add_child(sub)
	_coins = BattleTheme.make_label("", 22, BattleTheme.CY, true)
	_coins.position = Vector2(1044, 12)
	_coins.size = Vector2(216, 30)
	add_child(_coins)
	_icon("coin", Vector2(1012, 14), 26.0)
	_mats = BattleTheme.make_label("", 16, BattleTheme.CY_DIM)
	_mats.position = Vector2(1040, 52)
	_mats.size = Vector2(200, 24)
	add_child(_mats)
	_icon("nucleo", Vector2(1014, 52), 22.0)

	var names: Array = ["DA RISCUOTERE", "TUTTE"]
	names.append_array(Feats.GROUPS)
	var tabs := HBoxContainer.new()      # le schede si dividono la larghezza: mai fuori dallo schermo
	tabs.position = Vector2(24, 82 if TouchUi.active() else 88)
	tabs.size = Vector2(1232, 46)
	tabs.add_theme_constant_override("separation", 6)
	add_child(tabs)
	for g in names:
		var b := Button.new()
		b.text = str(g)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_stretch_ratio = float({"DA RISCUOTERE": 230, "TUTTE": 105, "MISSIONI": 130, "BATTAGLIE": 140, "OPERATORI": 140, "POTENZIAMENTI": 160, "INFINITO": 120, "PVP": 80}.get(str(g), 140))
		b.custom_minimum_size = Vector2(0, 40)
		b.clip_text = true
		_style_tab(b, "normal")
		b.pressed.connect(show_group.bind(str(g)))
		tabs.add_child(b)
		group_buttons[str(g)] = b

	var panel := HudPanel.new().setup("IMPRESE", BattleTheme.CY)
	panel.position = Vector2(20, 152 if TouchUi.active() else 142)
	panel.size = Vector2(1240, 454 if TouchUi.active() else 502)
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)
	panel.set_content(scroll)

	_summary = BattleTheme.make_label("", 16, BattleTheme.WH)
	_summary.position = Vector2(296, 640 if TouchUi.active() else 676)
	_summary.size = Vector2(620, 28)
	add_child(_summary)
	claim_all_button = Button.new()
	claim_all_button.position = Vector2(930, 620 if TouchUi.active() else 660)
	claim_all_button.size = Vector2(330, 52)
	BattleTheme.style_button(claim_all_button, "primary", 20)
	claim_all_button.pressed.connect(claim_all)
	add_child(claim_all_button)
	var back := Button.new()
	back.text = "TORNA ALL'HUB"
	back.position = Vector2(24, 620 if TouchUi.active() else 664)
	back.size = Vector2(250, 44)
	BattleTheme.style_button(back, "normal", 20)
	back.pressed.connect(func() -> void: SceneRouter.go("hub"))
	add_child(back)
	ScreenFx.menu_overlays(self, BattleTheme.RD)


# Schede: su telefono il testo e' un po' piu' piccolo cosi' ci stanno tutte e otto per intero.
func _style_tab(b: Button, kind: String) -> void:
	BattleTheme.style_button(b, kind, 15)
	b.add_theme_font_size_override("font_size", 15)


func _icon(key: String, pos: Vector2, px: float) -> void:
	var ic := GameIcon.new().setup(key, GameIcon.currency_color(key), px)
	ic.position = pos
	add_child(ic)


func show_group(g: String) -> void:
	group = g
	refresh()


# Imprese del gruppo mostrato.
func visible_feats() -> Array:
	var out: Array = []
	for f in Feats.all():
		if group == "DA RISCUOTERE":
			if Feats.can_claim(roster, f):
				out.append(f)
		elif group == "TUTTE" or str(f["group"]) == group:
			out.append(f)
	return out


func claim(id: String) -> bool:
	var reward: Dictionary = Feats.claim(roster, id)
	if reward.is_empty():
		return false
	RosterStore.save(roster, save_path)
	Snd.play("success")
	Notify.toast("IMPRESA RISCOSSA  +%s" % Feats.reward_text(reward), Notify.Kind.SUCCESS)
	refresh()
	return true


func claim_all() -> int:
	var n: int = Feats.claim_all(roster)
	if n > 0:
		RosterStore.save(roster, save_path)
		Snd.play("success")
		Notify.toast("%d IMPRESE RISCOSSE" % n, Notify.Kind.SUCCESS)
	refresh()
	return n


func refresh() -> void:
	if _list == null:
		return
	_coins.text = "GOLD %d" % int(roster["coins"])
	var mats: Dictionary = roster["materials"]
	_mats.text = "NUCLEI %d     LEGHE %d" % [int(mats.get("nucleo", 0)), int(mats.get("lega", 0))]
	var ready: int = Feats.claimable_count(roster)
	for g in group_buttons:
		var label: String = str({"DA RISCUOTERE": "DA RISCUOTERE", "POTENZIAMENTI": "POTENZIAM.", "OPERATORI": "OPERATORI"}.get(str(g), str(g)))
		if str(g) == "DA RISCUOTERE":
			label += " (%d)" % ready
		(group_buttons[g] as Button).text = label
		_style_tab(group_buttons[g], "primary" if str(g) == group else "normal")
	_summary.text = "RISCOSSE %d / %d" % [Feats.done_count(roster), Feats.all().size()]
	claim_all_button.text = "RISCUOTI TUTTO (%d)" % ready
	claim_all_button.disabled = ready == 0
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var feats: Array = visible_feats()
	if feats.is_empty():
		_list.add_child(BattleTheme.make_label("Niente da riscuotere: gioca ancora, o guarda TUTTE le imprese.", 18, BattleTheme.CY_DIM))
		return
	var last_group: String = ""
	for f in feats:
		if group in ["TUTTE", "DA RISCUOTERE"] and str(f["group"]) != last_group:
			last_group = str(f["group"])
			var head := BattleTheme.make_label(last_group, 15, BattleTheme.GOLD, true)
			_list.add_child(head)
		_list.add_child(_row(f))


func _row(f: Dictionary) -> Control:
	var done: bool = Feats.is_done(roster, f)
	var got: bool = Feats.is_claimed(roster, f)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 62)
	var edge: Color = BattleTheme.GOLD if (done and not got) else (BattleTheme.CY_DARK if got else BattleTheme.CY_DIM)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.03, 0.09, 0.11) if not (done and not got) else Color(0.12, 0.1, 0.03)
	box.border_color = edge
	box.set_border_width_all(2)
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", box)
	panel.set_meta("feat_id", str(f["id"]))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var ic := GameIcon.new().setup(str(GROUP_ICONS.get(str(f["group"]), "bolt")), BattleTheme.GOLD if done else BattleTheme.CY, 34.0)
	row.add_child(ic)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	var name_l := BattleTheme.make_label(str(f["name"]).to_upper(), 19, BattleTheme.WH if not got else BattleTheme.CY_DIM, true)
	text.add_child(name_l)
	text.add_child(BattleTheme.make_label(str(f["desc"]), 14, BattleTheme.CY if not got else BattleTheme.CY_DIM))
	var prog := VBoxContainer.new()
	prog.custom_minimum_size = Vector2(150, 0)
	prog.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(prog)
	var goal: int = int(f["goal"])
	var cur: int = Feats.progress(roster, f)
	var bar := SegBar.new().setup(10, BattleTheme.OK if done else BattleTheme.CY, Vector2(140, 10))
	bar.set_ratio(float(cur) / float(maxi(goal, 1)))
	prog.add_child(bar)
	prog.add_child(BattleTheme.make_label("%d / %d" % [cur, goal], 14, BattleTheme.WH))
	var rew := BattleTheme.make_label(Feats.reward_text(f["reward"]), 13, BattleTheme.GOLD if not got else BattleTheme.CY_DIM)
	rew.custom_minimum_size = Vector2(250, 0)
	rew.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rew.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(rew)
	var b := Button.new()
	b.custom_minimum_size = Vector2(160, 44)
	if got:
		b.text = "RISCOSSA"
		b.disabled = true
		BattleTheme.style_button(b, "normal", 16)
	elif done:
		b.text = "RISCUOTI"
		BattleTheme.style_button(b, "primary", 18)
		b.pressed.connect(claim.bind(str(f["id"])))
	else:
		b.text = "IN CORSO"
		b.disabled = true
		BattleTheme.style_button(b, "normal", 16)
	row.add_child(b)
	return panel
