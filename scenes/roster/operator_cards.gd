class_name OperatorCards
extends RefCounted

# Mattonelle dell'archivio operatori: la griglia della collezione e le carte della squadra.
# Sono pulsanti con dentro ritratto ed etichette, cosi' si legge chi e' chi a colpo d'occhio.

const TILE_SIZE: Vector2 = Vector2(100.0, 112.0)


static func _label(text: String, size: int, color: Color, pos: Vector2, bold: bool = false, width: float = 0.0) -> Label:
	var l := BattleTheme.make_label(text, size, color, bold)
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if width > 0.0:
		l.size = Vector2(width, size + 8.0)
		l.clip_text = true
	return l


static func _icon(key: String, color: Color, pos: Vector2, px: float = 17.0) -> GameIcon:
	var ic := GameIcon.new().setup(key, color, px)
	ic.position = pos
	return ic


static func _portrait(id: String, kind: String, pos: Vector2, size: Vector2, dim: bool = false) -> PortraitView:
	var pv := PortraitView.new().setup(id, kind)
	pv.show_expression_text = false
	pv.position = pos
	pv.size = size
	pv.dimmed = dim
	return pv


static func _stars(rank: int) -> String:
	return "*".repeat(rank) + ".".repeat(RosterState.MAX_RANK - rank)


# Mattonella della collezione. slot: posto in squadra (0 = non e' in squadra, 1..3 = posto).
static func tile(id: String, owned: bool, entry: Dictionary, slot: int, selected: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = TILE_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.clip_contents = true
	BattleTheme.style_button(b, "primary" if selected else "normal", 14)
	b.set_meta("char_id", id)
	var def: Dictionary = BattleContent.CHARACTERS[id]
	if not owned:
		b.disabled = true
		b.add_child(_portrait(id, "icon", Vector2(8, 8), Vector2(84, 60), true))
		b.add_child(_label("???", 15, BattleTheme.CY_DARK, Vector2(8, 72), true))
		b.add_child(_label("non reclutato", 11, BattleTheme.CY_DARK, Vector2(8, 92)))
		b.tooltip_text = "Non ancora reclutato"
		return b
	var fg: Color = BattleTheme.WH
	b.add_child(_portrait(id, "icon", Vector2(8, 8), Vector2(84, 60)))
	b.add_child(_label(str(def["name"]).to_upper(), 15, fg, Vector2(8, 70), true, 86.0))
	b.add_child(_label("Lv%d %s" % [int(entry["level"]), _stars(int(entry["rank"]))], 12, BattleTheme.WH if selected else BattleTheme.CY, Vector2(8, 91)))
	var key := ColorRect.new()
	key.color = BattleTheme.unit_color(str(def["color"]))
	key.position = Vector2(0, 0)
	key.size = Vector2(5, TILE_SIZE.y)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(key)
	if slot > 0:
		var badge := ColorRect.new()
		badge.color = BattleTheme.RD
		badge.position = Vector2(TILE_SIZE.x - 34.0, 0)
		badge.size = Vector2(34, 18)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(badge)
		b.add_child(_label("SQ %d" % slot, 12, BattleTheme.WH, Vector2(TILE_SIZE.x - 31.0, 0), true))
	b.tooltip_text = "%s · %s" % [str(def["name"]), str(def["cls"])]
	return b


# Carta di un posto della squadra: ritratto grande, nome, classe, fazione. id vuoto = posto libero.
static func slot_card(index: int, id: String, entry: Dictionary, active: bool) -> Button:
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 100)
	b.focus_mode = Control.FOCUS_NONE
	b.clip_contents = true
	BattleTheme.style_button(b, "primary" if active else "normal", 14)
	var fg: Color = BattleTheme.WH
	var dim: Color = BattleTheme.WH if active else BattleTheme.CY
	var front: bool = index < BattleTypes.FRONT_SIZE
	var tag: String = ("FRONT %d" % (index + 1)) if front else ("BACK %d" % (index - BattleTypes.FRONT_SIZE + 1))
	b.add_child(_label(tag, 12, dim, Vector2(66, 4), true))
	if id == "":
		b.add_child(_portrait("", "icon", Vector2(6, 6), Vector2(56, 56), true))
		b.add_child(_label("+ LIBERO", 16, fg, Vector2(66, 24), true))
		b.add_child(_label("Scegli dalla\ncollezione.", 12, dim, Vector2(66, 50)))
		return b
	var def: Dictionary = BattleContent.CHARACTERS[id]
	var col: Color = BattleTheme.WH if active else BattleTheme.unit_color(str(def["color"]))
	b.add_child(_portrait(id, "icon", Vector2(6, 6), Vector2(56, 56)))
	var nl := _label(str(def["name"]), 18, col, Vector2(66, 20), true, 120.0)
	nl.set_meta("keep_case", true)
	b.add_child(nl)
	b.add_child(_icon(str(def["cls"]), col, Vector2(66, 45), 13.0))
	b.add_child(_label("%s · %s" % [str(def["cls"]).capitalize(), str(def["color"]).capitalize()], 11, fg, Vector2(82, 44), false, 108.0))
	var faction: String = BattleContent.faction_of(id)
	if faction != "":
		var fcol: Color = BattleTheme.WH if active else Hints.faction_color(faction)
		b.add_child(_icon(faction, fcol, Vector2(66, 61), 13.0))
		b.add_child(_label(Factions.name_of(faction).to_upper(), 11, fcol, Vector2(82, 60), false, 108.0))
	b.add_child(_label("Lv%d  %s" % [int(entry["level"]), _stars(int(entry["rank"]))], 11, dim, Vector2(8, 70)))
	b.tooltip_text = "%s: %s" % [tag, str(def["name"])]
	return b
