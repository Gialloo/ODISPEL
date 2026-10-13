class_name PvpScreen
extends Control

# Schermata PvP: carte dei giocatori, mosse, bersaglio, log. Funziona con qualsiasi "sorgente" che offra
# battle, local_player_id, battle_time_left, battle_updated, battle_events_received e submit_choice():
# NetworkManager (in rete) o PvpLocalSource (allenamento contro l'IA).

const CARD_H: float = 106.0
const LOG_MAX: int = 40

var source: Variant = null
var pending_source: Variant = null
var shown: Dictionary = {}
var animating: bool = false
var locked: bool = false
var pending_move: String = ""          # mossa scelta che aspetta il bersaglio
var pending_skill: String = ""
var pending_kind: String = "enemy"     # "enemy" o "ally": chi si puo' toccare
var cards: Dictionary = {}              # id giocatore -> PvpCard
var zones: Dictionary = {}              # id giocatore -> PvpZone
var _stage: PvpStage
var _cards_layer: Control
var buttons: Dictionary = {}            # mossa -> Button
var swap_box: VBoxContainer
var _fan: FanMenu
var _icons: Dictionary = {}
var _rec_dot: ColorRect
var _t: float = 0.0
var _hint: Label
var _title: Label
var _round_label: Label
var _timer_label: Label
var _log: RichTextLabel
var _fx: Control
var _zone_layer: Control
var _result: Control = null
var _chat: ChatPanel = null
var _ended_shown: bool = false
var _timer_secs: int = -2
var _leave: Button


# ---------- Targhetta di un giocatore (in alto, come l'intestazione del boss nella battaglia PvE) ----------

class PvpCard extends Control:
	signal picked(player_id: String)
	var pid: String = ""
	var targetable: bool = false
	var mine: bool = false
	var ally: bool = false
	var _panel: Panel
	var _name: Label
	var _unit: Label
	var _hp: LineBar
	var _hp_text: Label
	var _gauge: LineBar
	var _info: Label
	var _bench: Label
	var _status: Label
	var _flash: float = 0.0

	func setup(player_id: String, card_w: float, is_me: bool, is_ally: bool) -> PvpCard:
		pid = player_id
		mine = is_me
		ally = is_ally
		custom_minimum_size = Vector2(card_w, CARD_H)
		size = Vector2(card_w, CARD_H)
		mouse_filter = Control.MOUSE_FILTER_STOP
		_panel = Panel.new()
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_panel)
		var iw: float = card_w - 20.0
		_name = BattleTheme.make_label("", 18, BattleTheme.WH, true)
		_name.position = Vector2(10, 4)
		_name.size = Vector2(iw * 0.62, 24)
		_name.clip_text = true
		add_child(_name)
		_status = BattleTheme.make_label("", 12, BattleTheme.POP, true)
		_status.position = Vector2(10 + iw * 0.62, 8)
		_status.size = Vector2(iw * 0.38, 18)
		_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_status.clip_text = true
		add_child(_status)
		_unit = BattleTheme.make_label("", 13, BattleTheme.CY_DIM)
		_unit.add_theme_font_override("font", BattleTheme.hud())
		_unit.position = Vector2(10, 28)
		_unit.size = Vector2(iw, 18)
		_unit.clip_text = true
		add_child(_unit)
		_hp = LineBar.new().setup(BattleTheme.OK, Vector2(iw, 12))
		_hp.position = Vector2(10, 48)
		_hp.size = Vector2(iw, 12)
		add_child(_hp)
		_hp_text = BattleTheme.make_label("", 14, BattleTheme.WH)
		_hp_text.add_theme_font_override("font", BattleTheme.hud())
		_hp_text.position = Vector2(10, 61)
		_hp_text.size = Vector2(iw * 0.55, 18)
		_hp_text.clip_text = true
		add_child(_hp_text)
		_info = BattleTheme.make_label("", 13, BattleTheme.CY)
		_info.add_theme_font_override("font", BattleTheme.hud())
		_info.position = Vector2(10 + iw * 0.55, 61)
		_info.size = Vector2(iw * 0.45, 18)
		_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_info.clip_text = true
		add_child(_info)
		_gauge = LineBar.new().setup(BattleTheme.WH, Vector2(iw, 6))
		_gauge.position = Vector2(10, 81)
		_gauge.size = Vector2(iw, 6)
		add_child(_gauge)
		_bench = BattleTheme.make_label("", 12, BattleTheme.CY_DIM)
		_bench.add_theme_font_override("font", BattleTheme.hud())
		_bench.position = Vector2(10, 87)
		_bench.size = Vector2(iw, 16)
		_bench.clip_text = true
		add_child(_bench)
		return self

	func _gui_input(event: InputEvent) -> void:
		var tap: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
		if tap and targetable:
			picked.emit(pid)

	func _ready() -> void:
		set_process(false)

	func flash() -> void:
		_flash = 1.0
		set_process(true)

	func _process(delta: float) -> void:
		if _flash > 0.0:
			_flash = maxf(0.0, _flash - delta * 3.0)
			modulate = Color.WHITE.lerp(Color(2.0, 1.4, 1.4), _flash)
		else:
			modulate = Color.WHITE
			set_process(false)

	func refresh(state: Dictionary, chosen: bool, selectable: bool) -> void:
		var p: Dictionary = PvpEngine.player(state, pid)
		if p.is_empty():
			return
		targetable = selectable
		var u: Dictionary = PvpEngine.active_unit(state, p)
		var alive_p: bool = PvpEngine.player_alive(state, p)
		var edge: Color = BattleTheme.CY if (mine or ally) else BattleTheme.RD
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.02, 0.06, 0.08, 0.78)
		sb.border_color = BattleTheme.POP if selectable else edge
		sb.set_border_width_all(4 if selectable else 2)
		sb.set_corner_radius_all(4)
		_panel.add_theme_stylebox_override("panel", sb)
		var tag: String = "" if mine else (" (ALLEATO)" if ally else "")
		_name.text = ("%s%s" % [str(p["name"]).to_upper(), tag]) + (" · IA" if bool(p["ai"]) else "")
		_name.add_theme_color_override("font_color", edge if alive_p else BattleTheme.CY_DARK)
		if u.is_empty():
			return
		_unit.text = "%s · %s" % [str(u["name"]).to_upper(), str(u["cls"]).to_upper()]
		_hp.set_values(float(u["hp"]) / maxf(1.0, float(u["max_hp"])), float(u["shield"]) / maxf(1.0, float(u["max_hp"])))
		_hp_text.text = "PV %s/%s%s" % [BattleText.num(int(u["hp"])), BattleText.num(int(u["max_hp"])), ("  +%s" % BattleText.num(int(u["shield"])) if int(u["shield"]) > 0 else "")]
		_gauge.set_values(float(u["gauge"]) / float(BattleTypes.GAUGE_MAX))
		_info.text = "EN %d/%d · ULT %d%%" % [int(u["energy"]), BattleTypes.MAX_ENERGY, int(u["gauge"])]
		var st: String = ""
		if not alive_p:
			st = "FUORI GIOCO"
		elif u["statuses"].has("guard"):
			st = "GUARDIA"
		elif chosen:
			st = "HA SCELTO ✓"
		elif state["winner"] == "":
			st = "SCEGLIE..."
		_status.text = st
		var bench: Array = []
		for uid in p["units"]:
			if str(uid) == str(p["active"]):
				continue
			var b: Dictionary = PvpEngine.unit(state, str(uid))
			bench.append("%s %s" % [str(b["name"]), ("KO" if not PvpEngine.alive(b) else "%d%%" % int(round(100.0 * float(b["hp"]) / maxf(1.0, float(b["max_hp"])))))])
		_bench.text = ("RISERVE: " + " · ".join(bench)) if not bench.is_empty() else ""


# Zona toccabile sopra un operatore sul palco: serve a scegliere il bersaglio toccando il personaggio.
class PvpZone extends Control:
	signal picked(player_id: String)
	var pid: String = ""
	var active: bool = false

	func setup(player_id: String) -> PvpZone:
		pid = player_id
		size = Vector2(170, 280)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		return self

	func set_active(on: bool) -> void:
		active = on
		mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE

	func _gui_input(event: InputEvent) -> void:
		var tap: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
		if tap and active:
			picked.emit(pid)


# ---------- Costruzione ----------

func _ready() -> void:
	ScreenFrame.setup(self)
	_build()
	if pending_source != null:
		bind_source(pending_source)


func _build() -> void:
	ScreenFx.solid(self, BattleTheme.BK)
	# lo stesso palco della battaglia contro il boss: sfondo, anelli, targhette, scatti
	_stage = PvpStage.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.party_lift = 28.0 if TouchUi.active() else 0.0
	add_child(_stage)
	# velatura ciano, telecamera e retino da fumetto, come in battaglia
	ScreenFx.battle(self)

	# zone toccabili sopra i personaggi (per scegliere il bersaglio)
	_zone_layer = Control.new()
	_zone_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_zone_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_zone_layer)

	# in alto a sinistra il tempo per scegliere, come "ORDINE ENTRO" della battaglia PvE
	var timer_panel := HudPanel.new().setup("ORDINE ENTRO", BattleTheme.CY_DIM)
	timer_panel.quiet = true
	timer_panel.margins = Vector4(14.0, 22.0, 14.0, 2.0)
	timer_panel.position = Vector2(8, 6)
	timer_panel.size = Vector2(148, 58)
	timer_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(timer_panel)
	_timer_label = BattleTheme.make_label("LIBERO", 28, BattleTheme.CY, true)
	timer_panel.set_content(_timer_label)
	_title = BattleTheme.make_label("PVP", 22, BattleTheme.WH, true)
	_title.position = Vector2(340, 8)
	_title.size = Vector2(600, 32)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	_leave = Button.new()
	_leave.text = "ESCI"
	_leave.focus_mode = Control.FOCUS_NONE
	BattleTheme.style_button(_leave, "normal", 16)
	add_child(_leave)
	_leave.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_leave.offset_left = -150.0
	_leave.offset_top = 6.0
	_leave.offset_right = -8.0
	_leave.offset_bottom = 44.0
	_leave.pressed.connect(_on_leave)

	var arena := Control.new()
	arena.name = "arena"
	arena.position = Vector2(0, 68)
	arena.size = Vector2(1280, CARD_H)
	arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arena)

	_hint = BattleTheme.make_label("", 18, BattleTheme.POP, true)
	_hint.position = Vector2(300, 178)
	_hint.size = Vector2(680, 28)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)

	# le mosse: stesso menu a ventaglio e stesso stile della battaglia PvE (si costruisce quando si sa dove sta il giocatore)
	_fan = FanMenu.new()
	_fan.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fan)
	swap_box = VBoxContainer.new()
	swap_box.position = Vector2(520, 210)
	swap_box.size = Vector2(300, 260)
	swap_box.add_theme_constant_override("separation", 6)
	swap_box.mouse_filter = Control.MOUSE_FILTER_IGNORE     # un contenitore vuoto non deve coprire i comandi
	add_child(swap_box)

	# registro in basso a destra e turno con REC nell'angolo, come in battaglia
	var panel := HudPanel.new().setup("", BattleTheme.CY_DIM)
	panel.bare = true
	panel.margins = Vector4(12, 8, 12, 6)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -370.0
	panel.offset_top = -150.0
	panel.offset_right = -10.0
	panel.offset_bottom = -34.0
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.add_theme_font_override("normal_font", BattleTheme.hud())
	_log.add_theme_font_size_override("normal_font_size", 15)
	_log.add_theme_font_size_override("bold_font_size", 15)
	panel.set_content(_log)
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 8)
	strip.alignment = BoxContainer.ALIGNMENT_END
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)
	strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	strip.offset_left = -260.0
	strip.offset_top = -50.0
	strip.offset_right = -10.0
	strip.offset_bottom = -14.0
	_round_label = BattleTheme.make_label("TURNO 01", 19, BattleTheme.CY_DIM)
	_round_label.add_theme_font_override("font", BattleTheme.hud())
	_round_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	strip.add_child(_round_label)
	var rec := BattleTheme.make_label("REC", 19, BattleTheme.WH, true)
	rec.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	strip.add_child(rec)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(14, 24)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(holder)
	_rec_dot = ColorRect.new()
	_rec_dot.color = BattleTheme.RD
	_rec_dot.size = Vector2(14, 14)
	_rec_dot.position = Vector2(0, 5)
	_rec_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_rec_dot)

	_fx = Control.new()
	_fx.name = "fx"
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fx)


# Ventaglio dei comandi: nasce a destra della squadra del giocatore, come in battaglia.
func _build_fan() -> void:
	for c in _fan.get_children():
		_fan.remove_child(c)
		c.queue_free()
	buttons.clear()
	_icons.clear()
	var names: Dictionary = {"attack": "ATTACCO", "skill": "ABILITA'", "guard": "GUARDIA", "ult": "ULTIMATE", "swap": "CAMBIA"}
	var order: Array = ["attack", "skill", "guard", "ult", "swap"]
	var touch: bool = TouchUi.active()
	var bh: float = 52.0 if touch else 42.0
	var bw: float = 232.0
	var fan_r: float = 340.0 if touch else 290.0
	var fan_big: float = 620.0
	var mid_rad: float = deg_to_rad(6.0 if touch else 22.0)
	var last: Vector3 = _stage.pose_of(str(_stage.side_left[_stage.side_left.size() - 1])) if not _stage.side_left.is_empty() else Vector3(215.0, 494.0, 0.82)
	var fo := Vector2(last.x - 145.0, last.y - 95.0 * last.z)
	_fan.origin = Vector2(fo.x + cos(mid_rad) * fan_r - fan_big, fo.y + sin(mid_rad) * fan_r)
	_fan.tint = BattleTheme.CY
	var pts: Array = _fan.layout(order.size(), bh, 4.0, fan_big, 0.0, 246.0, 706.0)
	var min_left: float = 1e9
	for pt in pts:
		min_left = minf(min_left, float(pt.x) - 8.0)
	for i in order.size():
		var m: String = str(order[i])
		var b := Button.new()
		b.text = str(names[m])
		b.custom_minimum_size = Vector2(bw, bh)
		b.size = Vector2(bw, bh)
		b.focus_mode = Control.FOCUS_NONE
		BattleTheme.style_button(b, "normal", 15)
		b.add_theme_font_override("font", BattleTheme.hud())
		b.add_theme_font_size_override("font_size", 15)
		b.position = Vector2(float(pts[i].x) - 8.0, float(pts[i].y) - bh * 0.5)
		b.pressed.connect(_on_move.bind(m))
		_fan.add_child(b)
		buttons[m] = b
		var ic := GameIcon.new().setup(_icon_key(m), BattleTheme.WH, 32.0)
		ic.position = Vector2(min_left - 40.0, b.position.y + bh * 0.5 - 16.0)
		ic.size = Vector2(32, 32)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fan.add_child(ic)
		_icons[m] = ic
	swap_box.position = Vector2(float(pts[0].x) + 250.0, float(pts[0].y) - 20.0)


# Icona di un comando del ventaglio: per abilita' e ultimate usa quella della mossa dell'operatore attivo.
func _icon_key(m: String) -> String:
	var mp: Dictionary = PvpEngine.player(shown, me()) if not shown.is_empty() else {}
	var u: Dictionary = PvpEngine.active_unit(shown, mp) if not mp.is_empty() else {}
	match m:
		"attack":
			return GameIcon.move_key("attack")
		"guard":
			return GameIcon.move_key("guard")
		"skill":
			var sk: Array = PvpEngine.skills_of(u) if not u.is_empty() else []
			return GameIcon.move_key(str(sk[0])) if not sk.is_empty() else "bolt"
		"ult":
			return GameIcon.move_key(PvpEngine.ult_of(u)) if not u.is_empty() else "burst"
	return "swap"


# Stile dei comandi come in battaglia: usabile = bianco con testo nero, non usabile = nero con testo grigio.
func _style_order(b: Button, usable: bool, gauge_progress: float) -> void:
	var box: SlantBox
	var txt_col: Color
	var outline: int = 0
	if usable:
		box = SlantBox.make(Color("#f4fbff"), Color("#10181c"), 14.0, Color(0, 0, 0, 0.55), 2.0)
		txt_col = BattleTheme.BK
	else:
		box = SlantBox.make(Color("#06090b"), Color("#2c373c"), 14.0, Color(0, 0, 0, 0.0), 2.0)
		txt_col = Color("#8b969b")
		if gauge_progress > 0.0:
			box.progress = gauge_progress
			box.progress_color = Color("#dfe9ec")
			txt_col = BattleTheme.WH
			outline = 4
	var hov: SlantBox = box
	if usable:
		hov = SlantBox.make(Color("#c4f4ff"), Color("#10181c"), 14.0, Color(0, 0, 0, 0.55), 2.0)
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("disabled", box)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(k, txt_col)
	b.add_theme_color_override("font_outline_color", BattleTheme.BK)
	b.add_theme_constant_override("outline_size", outline)


func bind_source(src: Variant) -> void:
	source = src
	src.battle_updated.connect(_on_updated)
	src.battle_events_received.connect(_on_events)
	if src is NetworkManager and _chat == null:
		_chat = ChatPanel.new().setup(src, true, Vector2(380, 200))
		_chat.position = Vector2(880, 414)
		_fx.add_child(_chat)
	if not src.battle.is_empty():
		_on_updated()


func me() -> String:
	return str(source.local_player_id) if source != null else ""


func _on_updated() -> void:
	if source != null and (source.battle as Dictionary).is_empty():
		# la sfida e' stata chiusa (l'host e' uscito): si torna alla lobby
		_go_back()
		return
	if animating:
		return
	_sync()


func _sync() -> void:
	shown = (source.battle as Dictionary).duplicate(true)
	locked = false
	pending_move = ""
	_build_cards()
	_stage.set_state(shown)
	_refresh()
	_check_end()


func _build_cards() -> void:
	if not cards.is_empty() and cards.size() == shown["players"].size():
		return
	var arena: Control = get_node("arena")
	for c in cards.values():
		c.queue_free()
	cards.clear()
	for z in zones.values():
		z.queue_free()
	zones.clear()
	_stage.local_player_id = me()
	_stage.set_state(shown)
	var lefts: Array = _stage.side_left
	var rights: Array = _stage.side_right
	var most: int = maxi(1, maxi(lefts.size(), rights.size()))
	var w: float = minf(300.0, (620.0 - 8.0 * float(most - 1)) / float(most))
	var x: float = 12.0
	for pid in lefts:
		_add_card(arena, str(pid), w, x, true)
		x += w + 8.0
	x = 1268.0 - w
	for pid in rights:
		_add_card(arena, str(pid), w, x, false)
		x -= w + 8.0
	_build_fan()


func _add_card(arena: Control, pid: String, w: float, x: float, friendly: bool) -> void:
	var c := PvpCard.new().setup(pid, w, pid == me(), friendly)
	c.position = Vector2(x, 0)
	c.picked.connect(_on_target)
	arena.add_child(c)
	cards[pid] = c
	var z := PvpZone.new().setup(pid)
	z.picked.connect(_on_target)
	_zone_layer.add_child(z)
	zones[pid] = z


func _mode_text() -> String:
	return "%s · %s" % [str(PvpEngine.MODE_NAMES.get(str(shown.get("mode", "duel")), "PVP")), "BILANCIATO" if bool(shown.get("balanced", true)) else "CON PROGRESSIONE"]


func _refresh() -> void:
	if shown.is_empty():
		return
	_title.text = "PVP · " + _mode_text()
	_round_label.text = "TURNO %02d" % int(shown["round"])
	var mp: Dictionary = PvpEngine.player(shown, me())
	var mine_ok: bool = not mp.is_empty() and PvpEngine.player_alive(shown, mp) and str(shown["winner"]) == ""
	var chosen_me: bool = mine_ok and mp["choice"] != null
	var picking: bool = pending_move != ""
	for pid in cards:
		var p: Dictionary = PvpEngine.player(shown, str(pid))
		var enemy: bool = not mp.is_empty() and str(p["team"]) != str(mp["team"])
		var side_ok: bool = enemy if pending_kind == "enemy" else (not mp.is_empty() and str(p["team"]) == str(mp["team"]))
		var selectable: bool = picking and side_ok and PvpEngine.player_alive(shown, p) and not locked
		cards[pid].refresh(shown, p["choice"] != null and not (str(pid) == me() and false), selectable)
		if zones.has(pid):
			var zn: PvpZone = zones[pid]
			var pos: Vector2 = _stage.anchor_of(str(p["active"]))
			zn.position = pos - Vector2(zn.size.x * 0.5, 170.0)
			zn.set_active(selectable)
	_stage.select_slot = me() if (mine_ok and not chosen_me and not locked) else ""
	var u: Dictionary = PvpEngine.active_unit(shown, mp) if not mp.is_empty() else {}
	var can_act: bool = mine_ok and not chosen_me and not locked and not u.is_empty()
	buttons["attack"].disabled = not can_act or not PvpEngine.alive(u)
	buttons["skill"].disabled = not can_act or not PvpEngine.alive(u) or not PvpEngine.can_skill(u)
	buttons["guard"].disabled = not can_act or not PvpEngine.alive(u)
	buttons["ult"].disabled = not can_act or not PvpEngine.alive(u) or not PvpEngine.can_ult(u)
	buttons["swap"].disabled = not can_act or PvpEngine.swap_options(shown, mp).is_empty()
	if not u.is_empty():
		buttons["ult"].text = (str(BattleContent.MOVES.get(PvpEngine.ult_of(u), {}).get("name", "ULTIMATE")).to_upper().left(14) if PvpEngine.can_ult(u) else "ULT %d%%" % int(u["gauge"]))
	for m in buttons:
		var bt: Button = buttons[m]
		var gp: float = float(u["gauge"]) / float(BattleTypes.GAUGE_MAX) if (m == "ult" and not u.is_empty()) else 0.0
		_style_order(bt, not bt.disabled, gp)
		if _icons.has(m):
			(_icons[m] as GameIcon).queue_free()
			var ic := GameIcon.new().setup(_icon_key(m), BattleTheme.WH if not bt.disabled else Color("#6b777c"), 32.0)
			ic.position = (_icons[m] as GameIcon).position
			ic.size = Vector2(32, 32)
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_fan.add_child(ic)
			_icons[m] = ic
	_clear_swaps()
	if str(shown["winner"]) != "":
		_hint.text = ""
	elif not mine_ok:
		_hint.text = "SEI FUORI GIOCO: STAI GUARDANDO"
	elif chosen_me or locked:
		_hint.text = "ORDINE INVIATO. ASPETTO GLI ALTRI..."
	elif picking:
		_hint.text = "TOCCA UN NEMICO PER COLPIRLO" if pending_kind == "enemy" else "TOCCA UN ALLEATO (O TE STESSO)"
	else:
		_hint.text = "SCEGLI LA MOSSA PER %s" % str(u.get("name", "")).to_upper()


func _clear_swaps() -> void:
	for c in swap_box.get_children():
		c.queue_free()


# ---------- Input ----------

func _on_move(move: String, skill_id: String = "") -> void:
	if locked or shown.is_empty() or animating:
		return
	var mp: Dictionary = PvpEngine.player(shown, me())
	var u: Dictionary = PvpEngine.active_unit(shown, mp)
	if move == "swap":
		_clear_swaps()
		for uid in PvpEngine.swap_options(shown, mp):
			var b: Dictionary = PvpEngine.unit(shown, str(uid))
			var btn := Button.new()
			btn.text = "%s (%d%%)" % [str(b["name"]).to_upper(), int(round(100.0 * float(b["hp"]) / maxf(1.0, float(b["max_hp"]))))]
			btn.custom_minimum_size = Vector2(240, 60)
			BattleTheme.style_button(btn, "normal", 20)
			btn.pressed.connect(_send.bind({"move": "swap", "swap": str(uid)}))
			swap_box.add_child(btn)
		pending_move = ""
		return
	if move == "skill" and skill_id == "":
		# l'operatore puo' avere piu' abilita' (anche uniche): si sceglie quale
		_clear_swaps()
		for sid in PvpEngine.skills_of(u):
			var m: Dictionary = BattleContent.MOVES[str(sid)]
			var sb := Button.new()
			sb.text = "%s  %d⚡" % [str(m["name"]).to_upper(), int(m["cost"])]
			sb.custom_minimum_size = Vector2(300, 60)
			sb.clip_text = true
			sb.disabled = not PvpEngine.can_use(u, str(sid))
			BattleTheme.style_button(sb, "normal", 18)
			sb.pressed.connect(_on_move.bind("skill", str(sid)))
			swap_box.add_child(sb)
		pending_move = ""
		return
	var mid: String = skill_id if move == "skill" else PvpEngine.move_id_for(u, {"move": move})
	var kind: String = PvpEngine.target_kind(mid)
	var base: Dictionary = {"move": move, "skill": skill_id}
	if kind == "":
		_send(base)
		return
	var pool: Array = PvpEngine.enemies_of(shown, me()) if kind == "enemy" else PvpEngine.allies_of(shown, me())
	if pool.size() == 1:
		base["target"] = str(pool[0]["id"])
		_send(base)
		return
	pending_move = move
	pending_skill = skill_id
	pending_kind = kind
	_clear_swaps()
	_refresh()


func _on_target(pid: String) -> void:
	if pending_move == "" or locked:
		return
	_send({"move": pending_move, "skill": pending_skill, "target": pid})


func _send(choice: Dictionary) -> void:
	if locked or source == null:
		return
	locked = true
	pending_move = ""
	pending_skill = ""
	var ok: bool = source.submit_choice(choice)
	if not ok:
		locked = false
	_refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1:
			_on_move("attack")
		KEY_2:
			_on_move("skill")
		KEY_3:
			_on_move("guard")
		KEY_4:
			_on_move("ult")
		KEY_ESCAPE:
			_on_leave()


func _on_leave() -> void:
	if _ended_shown:
		_go_back()
		return
	ConfirmBox.ask(self, "Abbandonare la sfida?", _go_back)


func _go_back() -> void:
	if source is NetworkManager:
		(source as NetworkManager).abandon_battle()      # no-op se la sfida e' gia' finita
		SceneRouter.go("lobby")
	else:
		SceneRouter.go("hub")


# ---------- Eventi ----------

func _on_events(events: Array) -> void:
	_play(events)


func _log_line(text: String) -> void:
	if _log != null:
		_log.append_text(text + "\n")


func _name_of(uid: String) -> String:
	var u: Dictionary = PvpEngine.unit(shown, uid)
	return str(u.get("name", uid)).to_upper()


func _card_of_unit(uid: String) -> PvpCard:
	var u: Dictionary = PvpEngine.unit(shown, uid)
	return cards.get(str(u.get("owner", "")))


func _anchor(card: PvpCard) -> Vector2:
	var p: Dictionary = PvpEngine.player(shown, card.pid)
	return _stage.anchor_of(str(p.get("active", "")))


# Il PV, lo scudo e l'attivo cambiano sullo schermo man mano che gli eventi scorrono (non solo alla fine del round).
func _apply(e: Dictionary) -> void:
	match str(e.get("t", "")):
		"damage", "heal", "shield":
			var u: Dictionary = PvpEngine.unit(shown, str(e.get("dst", "")))
			if u.is_empty():
				return
			match str(e["t"]):
				"damage":
					u["shield"] = maxi(0, int(u["shield"]) - int(e.get("absorbed", 0)))
					u["hp"] = maxi(0, int(u["hp"]) - int(e["amount"]))
				"heal":
					u["hp"] = mini(int(u["max_hp"]), int(u["hp"]) + int(e["amount"]))
				"shield":
					u["shield"] = int(u["shield"]) + int(e["amount"])
		"swap":
			var p: Dictionary = PvpEngine.player(shown, str(e.get("player", "")))
			if not p.is_empty():
				p["active"] = str(e["to"])
	_stage.set_state(shown)
	_refresh()


func _play(events: Array) -> void:
	if shown.is_empty():
		return
	animating = true
	var step: float = clampf(4.0 / float(maxi(1, events.size())), 0.08, minf(0.45, Settings.event_delay()))
	for e in events:
		_event(e)
		_apply(e)
		if not is_inside_tree():
			return
		await get_tree().create_timer(step).timeout
	_stage.acting = ""
	animating = false
	_sync()


func _event(e: Dictionary) -> void:
	match str(e.get("t", "")):
		"round":
			_log_line("[color=#7cf0ff]— TURNO %d —[/color]" % int(e["n"]))
			if AnimFx.enabled():
				AnimFx.round_banner(_fx, "TURNO %d" % int(e["n"]))
		"act":
			var mname: String = str(BattleContent.MOVES.get(str(e["move"]), {}).get("name", "mossa")).to_upper()
			_log_line("%s: %s%s" % [_name_of(str(e["unit"])), mname, "  [ULTIMATE]" if str(e.get("kind", "")) == "ult" else ""])
			_stage.acting = str(e["unit"])
			if str(e.get("kind", "")) != "basic":
				var ac: PvpCard = _card_of_unit(str(e["unit"]))
				if ac != null:
					AnimFx.float_text(_fx, mname.capitalize(), _anchor(ac) + Vector2(-50.0, -120.0), BattleTheme.CY, 22)
			Snd.play("deploy" if str(e.get("kind", "")) != "basic" else "hit", 1.0)
		"damage":
			var card: PvpCard = _card_of_unit(str(e["dst"]))
			_log_line("   %s subisce %s%s%s" % [_name_of(str(e["dst"])), BattleText.num(int(e["amount"])), "!" if bool(e.get("crit", false)) else "", " (assorbiti %s)" % BattleText.num(int(e["absorbed"])) if int(e.get("absorbed", 0)) > 0 else ""])
			_stage.flash(str(e["dst"]))
			_stage.impact(9.0 if bool(e.get("crit", false)) else 4.0, 0.03 if bool(e.get("crit", false)) else 0.01)
			if card != null:
				card.flash()
				var at: Vector2 = _anchor(card)
				AnimFx.float_text(_fx, "-" + BattleText.num(int(e["amount"])) + ("!" if bool(e.get("crit", false)) else ""), at + Vector2(-30.0, -40.0), BattleTheme.POP if bool(e.get("crit", false)) else BattleTheme.RD, 40 if bool(e.get("crit", false)) else 30)
				if AnimFx.enabled():
					AnimFx.slash(_fx, at, Color.WHITE, 1.5 if bool(e.get("crit", false)) else 1.0)
					AnimFx.sparks(_fx, at, BattleTheme.RD, 8, 200.0)
			Snd.play("crit" if bool(e.get("crit", false)) else "player_hit", randf_range(0.95, 1.05))
		"heal":
			var hc: PvpCard = _card_of_unit(str(e["dst"]))
			_log_line("   %s recupera %s" % [_name_of(str(e["dst"])), BattleText.num(int(e["amount"]))])
			if hc != null:
				AnimFx.float_text(_fx, "+" + BattleText.num(int(e["amount"])), _anchor(hc) + Vector2(-20.0, -40.0), BattleTheme.OK, 30)
				if AnimFx.enabled():
					AnimFx.rise(_fx, _anchor(hc))
			Snd.play("heal")
		"shield":
			var sc: PvpCard = _card_of_unit(str(e["dst"]))
			if sc != null and AnimFx.enabled():
				AnimFx.shield(_fx, _anchor(sc), false)
			Snd.play("trait")
		"guard":
			var gc: PvpCard = _card_of_unit(str(e["unit"]))
			_log_line("   %s si mette in guardia" % _name_of(str(e["unit"])))
			if gc != null and AnimFx.enabled():
				AnimFx.shield(_fx, _anchor(gc), false, BattleTheme.CY)
			Snd.play("guard")
		"swap":
			_log_line("   %s entra in campo" % _name_of(str(e["to"])))
			Snd.play("swap")
		"down":
			var dc: PvpCard = _card_of_unit(str(e["unit"]))
			_log_line("[color=#ff4630]   %s e' K.O.![/color]" % _name_of(str(e["unit"])))
			if dc != null:
				AnimFx.float_text(_fx, "K.O.!", _anchor(dc) + Vector2(-30.0, -60.0), BattleTheme.RD, 44)
				if AnimFx.enabled():
					AnimFx.shards(_fx, _anchor(dc), BattleTheme.RD, Vector2(160.0, 140.0))
			Snd.play("down")
		"end":
			Snd.play("down", 0.8)


# ---------- Fine partita ----------

func _check_end() -> void:
	if _ended_shown or shown.is_empty() or str(shown["winner"]) == "":
		return
	_ended_shown = true
	var bag: Dictionary = {}
	if source != null and source.has_method("finish"):
		bag = source.finish()
	var winner: String = str(shown["winner"])
	var mp: Dictionary = PvpEngine.player(shown, me())
	var won: bool = winner != "draw" and str(mp.get("team", "")) == winner
	var title: String = "PAREGGIO" if winner == "draw" else ("VITTORIA!" if won else "SCONFITTA")
	var col: Color = BattleTheme.POP if winner == "draw" else (BattleTheme.OK if won else BattleTheme.RD)
	var names: Array = []
	for pid in PvpEngine.winner_players(shown):
		names.append(str(PvpEngine.player(shown, str(pid))["name"]).to_upper())
	var panel := HudPanel.new().setup("ESITO", col)
	panel.position = Vector2(320, 130)
	panel.size = Vector2(640, 390)
	_fx.add_child(panel)
	_result = panel
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.set_content(box)
	var t := BattleTheme.make_label(title, 56, col, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var who := BattleTheme.make_label(("HA VINTO: " + ", ".join(names)) if not names.is_empty() else "NESSUN VINCITORE", 20, BattleTheme.WH)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	who.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(who)
	var info := BattleTheme.make_label("%s · %d CICLI" % [_mode_text(), int(shown["round"])], 16, BattleTheme.CY_DIM)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)
	var bag_text: String = PvpRewards.text(bag) if bag is Dictionary else ""
	if bag_text != "":
		var bl := BattleTheme.make_label("BORSA FIGHT:  " + bag_text, 17, BattleTheme.GOLD, true)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(bl)
	var back := Button.new()
	back.text = "TORNA ALLA LOBBY" if source is NetworkManager else "TORNA ALL'HUB"
	back.custom_minimum_size = Vector2(0, 64)
	BattleTheme.style_button(back, "primary", 24)
	back.pressed.connect(_go_back)
	box.add_child(back)
	if won and AnimFx.enabled():
		ComicFx.flash(_fx, Color(1.0, 0.85, 0.3, 0.4), 0.5)
		AnimFx.shards(_fx, Vector2(640.0, 200.0), Color("#ffd166"), Vector2(520.0, 140.0))


# ---------- Tempo ----------

func _process(delta: float) -> void:
	_t += delta
	if _rec_dot != null:
		var on: bool = int(_t * 1.6) % 2 == 0
		if _rec_dot.visible != on:
			_rec_dot.visible = on
	if source == null or shown.is_empty() or str(shown["winner"]) != "":
		return
	var left: int = int(ceil(float(source.battle_time_left))) if source is NetworkManager else -1
	if left != _timer_secs:
		_timer_secs = left
		_timer_label.text = "%02d" % left if left >= 0 else "LIBERO"
		_timer_label.add_theme_color_override("font_color", BattleTheme.RD if left <= 5 and left >= 0 else BattleTheme.POP)
