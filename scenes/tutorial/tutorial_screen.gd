class_name TutorialScreen
extends Control

# Schermata TUTORIAL: tutte le meccaniche spiegate, sempre consultabili. Il primo tutorial letto fino in fondo
# da' un premio fisso; leggerli aumenta anche le imprese "Studioso" nella schermata OBIETTIVI.

var roster: Dictionary = {}
var save_path: String = RosterStore.DEFAULT_PATH
var _list: VBoxContainer
var _summary: Label
var _coins: Label
var _guide: GachaGuide = null


func _ready() -> void:
	ScreenFrame.setup(self)
	if roster.is_empty():
		roster = RosterStore.load_or_new(save_path)
	_build()
	refresh()


func _build() -> void:
	ScreenFx.solid(self, BattleTheme.BK)
	var title := BattleTheme.make_label("TUTORIAL", 40, BattleTheme.WH, true)
	title.position = Vector2(24, 10)
	add_child(title)
	var sub := BattleTheme.make_label("// OGNI MECCANICA SPIEGATA  ·  LEGGI FINO IN FONDO PER IL PREMIO", 15, BattleTheme.CY_DIM)
	sub.position = Vector2(28, 62)
	add_child(sub)
	_coins = BattleTheme.make_label("", 22, BattleTheme.CY, true)
	_coins.position = Vector2(1044, 12)
	_coins.size = Vector2(216, 30)
	add_child(_coins)
	var ic := GameIcon.new().setup("coin", GameIcon.currency_color("coin"), 26.0)
	ic.position = Vector2(1012, 14)
	add_child(ic)

	var panel := HudPanel.new().setup("LEZIONI", BattleTheme.CY)
	panel.position = Vector2(20, 100)
	panel.size = Vector2(1240, 500 if not TouchUi.active() else 470)
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)
	panel.set_content(scroll)

	_summary = BattleTheme.make_label("", 17, BattleTheme.WH)
	_summary.position = Vector2(296, 640 if TouchUi.active() else 664)
	_summary.size = Vector2(900, 30)
	add_child(_summary)
	var back := Button.new()
	back.text = "TORNA ALL'HUB"
	back.position = Vector2(24, 620 if TouchUi.active() else 652)
	back.size = Vector2(250, 48)
	BattleTheme.style_button(back, "normal", 20)
	back.pressed.connect(func() -> void: SceneRouter.go("hub"))
	add_child(back)
	ScreenFx.menu_overlays(self, BattleTheme.RD)


func refresh() -> void:
	if _list == null:
		return
	_coins.text = "CREDITI %d" % int(roster["coins"])
	_summary.text = "LETTI %d / %d   ·   PREMIO PER OGNI TUTORIAL: %s" % [Tutorials.done_count(roster), Tutorials.total(), Tutorials.reward_text()]
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for t in Tutorials.all():
		_list.add_child(_row(t))


func _row(t: Dictionary) -> Control:
	var id: String = str(t["id"])
	var done: bool = Tutorials.is_done(roster, id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 56)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.03, 0.09, 0.11) if done else Color(0.12, 0.1, 0.03)
	box.border_color = BattleTheme.CY_DARK if done else BattleTheme.GOLD
	box.set_border_width_all(2)
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 3.0
	box.content_margin_bottom = 3.0
	panel.add_theme_stylebox_override("panel", box)
	panel.set_meta("tutorial_id", id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	row.add_child(GameIcon.new().setup(str(t["icon"]), BattleTheme.CY_DIM if done else BattleTheme.GOLD, 32.0))
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	text.add_child(BattleTheme.make_label(str(t["title"]), 19, BattleTheme.CY_DIM if done else BattleTheme.WH, true))
	text.add_child(BattleTheme.make_label("%d %s  ·  %s" % [(t["pages"] as Array).size(), "pagina" if (t["pages"] as Array).size() == 1 else "pagine", "LETTO (puoi rileggerlo quando vuoi)" if done else "PREMIO: " + Tutorials.reward_text()], 13, BattleTheme.CY_DIM if done else BattleTheme.GOLD))
	var b := Button.new()
	b.custom_minimum_size = Vector2(170, 44)
	b.text = "RILEGGI" if done else "LEGGI"
	BattleTheme.style_button(b, "normal" if done else "primary", 18)
	b.pressed.connect(open_tutorial.bind(id))
	row.add_child(b)
	return panel


func open_tutorial(id: String) -> void:
	var t: Dictionary = Tutorials.by_id(id)
	if t.is_empty() or _guide != null:
		return
	_guide = GachaGuide.open_pages(self, str(t["title"]), t["pages"])
	_guide.closed.connect(_on_closed.bind(id, _guide))


# Alla chiusura: se ha letto fino all'ultima pagina, il tutorial e' fatto (premio la prima volta).
func _on_closed(id: String, guide: GachaGuide) -> void:
	var finished: bool = guide.reached_end
	_guide = null
	if not finished:
		return
	var reward: Dictionary = Tutorials.complete(roster, id)
	if not reward.is_empty():
		RosterStore.save(roster, save_path)
		Snd.play("success")
		Notify.toast("TUTORIAL COMPLETATO  +%s" % Tutorials.reward_text(), Notify.Kind.SUCCESS)
	refresh()
