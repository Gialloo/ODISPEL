class_name LobbyView
extends RefCounted

# Pezzi grafici condivisi dalla lobby: carte dei giocatori e scelta missione.


# Silhouette di un operatore, nel colore del personaggio.
class Portrait extends Control:
	var color: Color = BattleTheme.CY

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var cx: float = w * 0.5
		draw_circle(Vector2(cx, h * 0.24), h * 0.14, color)
		draw_rect(Rect2(cx - w * 0.28, h * 0.42, w * 0.56, h * 0.30), color)
		draw_rect(Rect2(cx - w * 0.22, h * 0.72, w * 0.18, h * 0.28), color)
		draw_rect(Rect2(cx + w * 0.04, h * 0.72, w * 0.18, h * 0.28), color)


static func _style(border: Color, filled: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = border.darkened(0.7) if filled else BattleTheme.PANEL
	s.border_color = border
	s.set_border_width_all(2)
	s.content_margin_left = 10.0
	s.content_margin_right = 10.0
	s.content_margin_top = 6.0
	s.content_margin_bottom = 6.0
	return s


static func lead_name(lead: Dictionary) -> String:
	if lead.is_empty():
		return "—"
	var info: Dictionary = BattleContent.CHARACTERS.get(str(lead["char"]), {})
	return "%s  LV%d" % [str(info.get("name", lead["char"])).to_upper(), int(lead["level"])]


static func lead_color(lead: Dictionary) -> Color:
	if lead.is_empty():
		return BattleTheme.CY_DIM
	var info: Dictionary = BattleContent.CHARACTERS.get(str(lead["char"]), {})
	return BattleTheme.unit_color(str(info.get("color", "")))


static func status_of(p: Dictionary) -> String:
	if not bool(p["connected"]):
		return "OFFLINE"
	return "PRONTO" if bool(p["ready"]) else "IN ATTESA"


# Riempie il contenitore con una carta per giocatore.
# big = carte alte con silhouette (lobby), altrimenti righe compatte (barra).
static func fill_players(box: Container, lobby: Dictionary, local_id: String, big: bool = false) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()

	var index: int = 0
	for p in lobby.get("players", []):
		index += 1
		var lead: Dictionary = p["lead"]
		var color: Color = lead_color(lead)
		var status: String = status_of(p)
		var border: Color = BattleTheme.CY if status == "PRONTO" else (BattleTheme.RD if status == "OFFLINE" else BattleTheme.CY_DIM)

		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _style(border, status == "PRONTO"))
		card.name = "card_" + str(p["id"])
		if big:
			card.custom_minimum_size = Vector2(190, 300)
		box.add_child(card)

		var inner: BoxContainer = VBoxContainer.new() if big else HBoxContainer.new()
		inner.add_theme_constant_override("separation", 6 if big else 10)
		card.add_child(inner)

		var portrait := Portrait.new()
		portrait.color = color if status != "OFFLINE" else BattleTheme.RD_DARK
		portrait.custom_minimum_size = Vector2(120, 130) if big else Vector2(26, 34)
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		inner.add_child(portrait)

		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override("separation", 2)
		inner.add_child(text)

		var who: String = str(p["name"]).to_upper() + ("  [TU]" if str(p["id"]) == local_id else "")
		if bool(p["host"]):
			who += "  ★"
		text.add_child(BattleTheme.make_label("ID-%02d  %s" % [index, who], 16 if big else 14, BattleTheme.WH))
		text.add_child(BattleTheme.make_label(lead_name(lead), 15 if big else 13, color))
		if big:
			text.add_child(BattleTheme.make_label("SQUADRA: %d" % int(p["team_size"]), 13, BattleTheme.CY_DIM))

		var badge := BattleTheme.make_label(status, 16 if big else 13, BattleTheme.BK if status == "PRONTO" else border, true)
		badge.name = "status"
		if status == "PRONTO":
			var back := PanelContainer.new()
			var bs: StyleBoxFlat = _style(BattleTheme.CY)
			bs.bg_color = BattleTheme.CY
			back.add_theme_stylebox_override("panel", bs)
			back.add_child(badge)
			inner.add_child(back)
		else:
			inner.add_child(badge)


# Scelta di boss e difficolta' (solo l'host la usa).
class MissionPicker extends HBoxContainer:
	var manager: NetworkManager = null
	var boss_pick: OptionButton
	var tier_pick: OptionButton
	var _roster: Dictionary = {}
	var _updating: bool = false

	func setup(new_manager: NetworkManager) -> MissionPicker:
		manager = new_manager
		add_theme_constant_override("separation", 8)
		boss_pick = OptionButton.new()
		boss_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tier_pick = OptionButton.new()
		tier_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for id in BattleContent.BOSS_ORDER:
			boss_pick.add_item(MissionConfig.boss_title(str(id)))
		for t in BattleContent.TIERS:
			tier_pick.add_item(str(t["name"]))
		add_child(boss_pick)
		add_child(tier_pick)
		boss_pick.item_selected.connect(_on_boss)
		tier_pick.item_selected.connect(_on_tier)
		refresh()
		return self

	func refresh() -> void:
		_updating = true
		_roster = RosterStore.load_or_new()
		var boss: String = manager.lobby_boss if manager.is_host else str(manager.lobby.get("boss", "distributore"))
		var tier: int = manager.lobby_tier if manager.is_host else int(manager.lobby.get("tier", 0))
		for i in BattleContent.BOSS_ORDER.size():
			var id: String = str(BattleContent.BOSS_ORDER[i])
			boss_pick.set_item_disabled(i, not RosterState.is_boss_unlocked(_roster, id))
			if id == boss:
				boss_pick.select(i)
		for i in BattleContent.TIERS.size():
			tier_pick.set_item_disabled(i, not RosterState.is_tier_unlocked(_roster, boss, i))
		tier_pick.select(clampi(tier, 0, BattleContent.TIERS.size() - 1))
		boss_pick.disabled = not manager.is_host
		tier_pick.disabled = not manager.is_host
		_updating = false

	func _on_boss(index: int) -> void:
		if _updating:
			return
		manager.host_set_mission(str(BattleContent.BOSS_ORDER[index]), 0)

	func _on_tier(index: int) -> void:
		if _updating:
			return
		manager.host_set_mission(str(BattleContent.BOSS_ORDER[boss_pick.selected]), index)
