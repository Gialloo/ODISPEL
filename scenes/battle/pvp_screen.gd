class_name PvpScreen
extends Control

# Schermata PvP: carte dei giocatori, mosse, bersaglio, log. Funziona con qualsiasi "sorgente" che offra
# battle, local_player_id, battle_time_left, battle_updated, battle_events_received e submit_choice():
# NetworkManager (in rete) o PvpLocalSource (allenamento contro l'IA).

const CARD_H: float = 318.0
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
var buttons: Dictionary = {}            # mossa -> Button
var swap_box: HBoxContainer
var _hint: Label
var _title: Label
var _round_label: Label
var _timer_label: Label
var _log: RichTextLabel
var _fx: Control
var _result: Control = null
var _chat: ChatPanel = null
var _ended_shown: bool = false
var _timer_secs: int = -2
var _leave: Button


# ---------- Carta di un giocatore ----------

class PvpCard extends Control:
	signal picked(player_id: String)
	var pid: String = ""
	var targetable: bool = false
	var mine: bool = false
	var ally: bool = false
	var _panel: Panel
	var _name: Label
	var _unit: Label
	var _face: PortraitView
	var _hp: SegBar
	var _hp_text: Label
	var _gauge: SegBar
	var _info: Label
	var _bench: Label
	var _status: Label
	var _flash: float = 0.0
	var _char: String = ""

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
		_name = BattleTheme.make_label("", 20, BattleTheme.WH, true)
		_name.position = Vector2(10, 6)
		_name.size = Vector2(card_w - 20.0, 26)
		_name.clip_text = true
		add_child(_name)
		_unit = BattleTheme.make_label("", 15, BattleTheme.CY_DIM)
		_unit.position = Vector2(10, 32)
		_unit.size = Vector2(card_w - 20.0, 22)
		_unit.clip_text = true
		add_child(_unit)
		_face = PortraitView.new()
		_face.show_expression_text = false
		_face.position = Vector2(10, 58)
		_face.size = Vector2(card_w - 20.0, 112)
		_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_face)
		_hp = SegBar.new().setup(12, BattleTheme.OK, Vector2(card_w - 20.0, 16))
		_hp.smooth = true
		_hp.position = Vector2(10, 176)
		_hp.size = Vector2(card_w - 20.0, 16)
		add_child(_hp)
		_hp_text = BattleTheme.make_label("", 16, BattleTheme.WH)
		_hp_text.position = Vector2(10, 194)
		_hp_text.size = Vector2(card_w - 20.0, 22)
		_hp_text.clip_text = true
		add_child(_hp_text)
		_gauge = SegBar.new().setup(10, BattleTheme.POP, Vector2(card_w - 20.0, 10))
		_gauge.position = Vector2(10, 220)
		_gauge.size = Vector2(card_w - 20.0, 10)
		add_child(_gauge)
		_info = BattleTheme.make_label("", 15, BattleTheme.CY)
		_info.position = Vector2(10, 234)
		_info.size = Vector2(card_w - 20.0, 22)
		_info.clip_text = true
		add_child(_info)
		_status = BattleTheme.make_label("", 15, BattleTheme.POP, true)
		_status.position = Vector2(10, 256)
		_status.size = Vector2(card_w - 20.0, 22)
		_status.clip_text = true
		add_child(_status)
		_bench = BattleTheme.make_label("", 13, BattleTheme.CY_DIM)
		_bench.position = Vector2(10, 282)
		_bench.size = Vector2(card_w - 20.0, 30)
		_bench.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
		sb.bg_color = Color(0.02, 0.06, 0.08, 0.92)
		sb.border_color = BattleTheme.POP if selectable else edge
		sb.set_border_width_all(4 if selectable else 2)
		sb.set_corner_radius_all(4)
		_panel.add_theme_stylebox_override("panel", sb)
		var tag: String = " (TU)" if mine else (" (ALLEATO)" if ally else "")
		_name.text = ("%s%s" % [str(p["name"]).to_upper(), tag]) + (" · IA" if bool(p["ai"]) else "")
		_name.add_theme_color_override("font_color", edge if alive_p else BattleTheme.CY_DARK)
		if u.is_empty():
			return
		_unit.text = "%s · %s" % [str(u["name"]).to_upper(), str(u["cls"]).to_upper()]
		if _char != str(u["char"]):
			_char = str(u["char"])
			_face.setup(_char, "bust")
		_face.dimmed = not PvpEngine.alive(u)
		_face.queue_redraw()
		_hp.set_ratio(float(u["hp"]) / maxf(1.0, float(u["max_hp"])))
		_hp.color_on = BattleTheme.OK if float(u["hp"]) / maxf(1.0, float(u["max_hp"])) > 0.35 else BattleTheme.RD
		_hp_text.text = "PV %s/%s%s" % [BattleText.num(int(u["hp"])), BattleText.num(int(u["max_hp"])), ("  +%s SCUDO" % BattleText.num(int(u["shield"])) if int(u["shield"]) > 0 else "")]
		_gauge.set_ratio(float(u["gauge"]) / float(BattleTypes.GAUGE_MAX))
		_info.text = "ENERGIA %d/%d   ULT %d%%" % [int(u["energy"]), BattleTypes.MAX_ENERGY, int(u["gauge"])]
		var st: String = ""
		if not alive_p:
			st = "FUORI GIOCO"
		elif u["statuses"].has("guard"):
			st = "GUARDIA"
		elif chosen:
			st = "HA SCELTO ✓"
		elif state["winner"] == "":
			st = "STA SCEGLIENDO..."
		_status.text = st
		var bench: Array = []
		for uid in p["units"]:
			if str(uid) == str(p["active"]):
				continue
			var b: Dictionary = PvpEngine.unit(state, str(uid))
			bench.append("%s %s" % [str(b["name"]), ("KO" if not PvpEngine.alive(b) else "%d%%" % int(round(100.0 * float(b["hp"]) / maxf(1.0, float(b["max_hp"])))))])
		_bench.text = ("RISERVE: " + " · ".join(bench)) if not bench.is_empty() else "NESSUNA RISERVA"


# ---------- Costruzione ----------

func _ready() -> void:
	ScreenFrame.setup(self)
	_build()
	if pending_source != null:
		bind_source(pending_source)


func _build() -> void:
	ScreenFx.solid(self, BattleTheme.BK)
	ScreenFx.menu_overlays(self, BattleTheme.RD)
	_title = BattleTheme.make_label("PVP", 30, BattleTheme.WH, true)
	_title.position = Vector2(20, 8)
	_title.size = Vector2(700, 40)
	add_child(_title)
	_round_label = BattleTheme.make_label("", 22, BattleTheme.CY, true)
	_round_label.position = Vector2(760, 12)
	_round_label.size = Vector2(240, 32)
	add_child(_round_label)
	_timer_label = BattleTheme.make_label("", 22, BattleTheme.POP, true)
	_timer_label.position = Vector2(1010, 12)
	_timer_label.size = Vector2(130, 32)
	add_child(_timer_label)
	_leave = Button.new()
	_leave.text = "ESCI"
	_leave.position = Vector2(1150, 8)
	_leave.size = Vector2(110, 44)
	BattleTheme.style_button(_leave, "normal", 18)
	_leave.pressed.connect(_on_leave)
	add_child(_leave)

	var arena := Control.new()
	arena.name = "arena"
	arena.position = Vector2(20, 56)
	arena.size = Vector2(1240, CARD_H)
	arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arena)

	_hint = BattleTheme.make_label("", 18, BattleTheme.POP, true)
	_hint.position = Vector2(20, 380)
	_hint.size = Vector2(1240, 28)
	add_child(_hint)

	var names: Dictionary = {"attack": "ATTACCO", "skill": "ABILITA'", "guard": "GUARDIA", "ult": "ULTIMATE", "swap": "CAMBIA"}
	var grid := GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(20, 414)
	grid.size = Vector2(400, 200)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	add_child(grid)
	for m in ["attack", "skill", "guard", "ult", "swap"]:
		var b := Button.new()
		b.text = str(names[m])
		b.custom_minimum_size = Vector2(196, 64)
		b.clip_text = true
		BattleTheme.style_button(b, "primary" if m == "attack" else "normal", 20)
		b.pressed.connect(_on_move.bind(m))
		grid.add_child(b)
		buttons[m] = b
	swap_box = HBoxContainer.new()
	swap_box.position = Vector2(20, 622)
	swap_box.size = Vector2(1000, 64)
	swap_box.add_theme_constant_override("separation", 8)
	add_child(swap_box)

	var panel := HudPanel.new().setup("REGISTRO", BattleTheme.CY)
	panel.position = Vector2(440, 414)
	panel.size = Vector2(420, 200)
	add_child(panel)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.add_theme_font_size_override("normal_font_size", 15)
	_log.add_theme_font_size_override("bold_font_size", 15)
	panel.set_content(_log)

	_fx = Control.new()
	_fx.name = "fx"
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fx)


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
	_refresh()
	_check_end()


func _build_cards() -> void:
	if not cards.is_empty() and cards.size() == shown["players"].size():
		return
	var arena: Control = get_node("arena")
	for c in cards.values():
		c.queue_free()
	cards.clear()
	var mine: Dictionary = PvpEngine.player(shown, me())
	var mine_team: String = str(mine.get("team", ""))
	var lefts: Array = []
	var rights: Array = []
	for p in shown["players"]:
		if str(p["id"]) == me():
			lefts.push_front(p)
		elif str(p["team"]) == mine_team:
			lefts.append(p)
		else:
			rights.append(p)
	if lefts.is_empty():                 # spettatore: tutti a destra
		lefts = []
	var total: int = lefts.size() + rights.size()
	var w: float = minf(300.0, (1240.0 - 60.0 - 16.0 * float(total - 1)) / float(maxi(1, total)))
	var x: float = 0.0
	for p in lefts:
		var c := PvpCard.new().setup(str(p["id"]), w, str(p["id"]) == me(), true)
		c.picked.connect(_on_target)
		c.position = Vector2(x, 0)
		arena.add_child(c)
		cards[str(p["id"])] = c
		x += w + 16.0
	# separatore VS
	var vs := BattleTheme.make_label("VS", 34, BattleTheme.RD, true)
	vs.position = Vector2(x - 6.0, 130)
	vs.size = Vector2(40, 40)
	vs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena.add_child(vs)
	x += 44.0
	for p in rights:
		var c := PvpCard.new().setup(str(p["id"]), w, false, false)
		c.position = Vector2(x, 0)
		c.picked.connect(_on_target)
		arena.add_child(c)
		cards[str(p["id"])] = c
		x += w + 16.0


func _mode_text() -> String:
	return "%s · %s" % [str(PvpEngine.MODE_NAMES.get(str(shown.get("mode", "duel")), "PVP")), "BILANCIATO" if bool(shown.get("balanced", true)) else "CON PROGRESSIONE"]


func _refresh() -> void:
	if shown.is_empty():
		return
	_title.text = "PVP · " + _mode_text()
	_round_label.text = "CICLO %02d" % int(shown["round"])
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
	var u: Dictionary = PvpEngine.active_unit(shown, mp) if not mp.is_empty() else {}
	var can_act: bool = mine_ok and not chosen_me and not locked and not u.is_empty()
	buttons["attack"].disabled = not can_act or not PvpEngine.alive(u)
	buttons["skill"].disabled = not can_act or not PvpEngine.alive(u) or not PvpEngine.can_skill(u)
	buttons["guard"].disabled = not can_act or not PvpEngine.alive(u)
	buttons["ult"].disabled = not can_act or not PvpEngine.alive(u) or not PvpEngine.can_ult(u)
	buttons["swap"].disabled = not can_act or PvpEngine.swap_options(shown, mp).is_empty()
	if not u.is_empty():
		buttons["ult"].text = (str(BattleContent.MOVES.get(PvpEngine.ult_of(u), {}).get("name", "ULTIMATE")).to_upper().left(11) if PvpEngine.can_ult(u) else "ULT %d%%" % int(u["gauge"]))
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
	return Vector2(20.0, 56.0) + card.position + Vector2(card.size.x * 0.5, 120.0)


func _play(events: Array) -> void:
	if shown.is_empty():
		return
	animating = true
	var step: float = clampf(4.0 / float(maxi(1, events.size())), 0.08, minf(0.45, Settings.event_delay()))
	for e in events:
		_event(e)
		if not is_inside_tree():
			return
		await get_tree().create_timer(step).timeout
	animating = false
	_sync()


func _event(e: Dictionary) -> void:
	match str(e.get("t", "")):
		"round":
			_log_line("[color=#7cf0ff]— CICLO %d —[/color]" % int(e["n"]))
			if AnimFx.enabled():
				AnimFx.round_banner(_fx, "CICLO %d" % int(e["n"]))
		"act":
			var mname: String = str(BattleContent.MOVES.get(str(e["move"]), {}).get("name", "mossa")).to_upper()
			_log_line("%s: %s%s" % [_name_of(str(e["unit"])), mname, "  [ULTIMATE]" if str(e.get("kind", "")) == "ult" else ""])
			Snd.play("deploy" if str(e.get("kind", "")) != "basic" else "hit", 1.0)
		"damage":
			var card: PvpCard = _card_of_unit(str(e["dst"]))
			_log_line("   %s subisce %s%s%s" % [_name_of(str(e["dst"])), BattleText.num(int(e["amount"])), "!" if bool(e.get("crit", false)) else "", " (assorbiti %s)" % BattleText.num(int(e["absorbed"])) if int(e.get("absorbed", 0)) > 0 else ""])
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

func _process(_delta: float) -> void:
	if source == null or shown.is_empty() or str(shown["winner"]) != "":
		return
	var left: int = int(ceil(float(source.battle_time_left))) if source is NetworkManager else -1
	if left != _timer_secs:
		_timer_secs = left
		_timer_label.text = "%02d" % left if left >= 0 else ""
		_timer_label.add_theme_color_override("font_color", BattleTheme.RD if left <= 5 and left >= 0 else BattleTheme.POP)
