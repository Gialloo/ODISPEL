class_name RoomBar
extends CanvasLayer

# Barra della stanza: resta sopra a tutte le schermate (hub, squadra, missioni...)
# finche' si e' in una stanza di gruppo. Mostra chi c'e', il personaggio guida di
# ognuno, il pulsante PRONTO e, per l'host, la scelta missione e AVVIA.
# Si nasconde solo nelle schermate che mostrano gia' la lobby o la battaglia.

var session: Node = null
var expanded: bool = false

var _root: Control
var _strip: PanelContainer
var _ready_button: Button
var _toggle_button: Button
var _title: Label
var _drop: PanelContainer
var _cards: VBoxContainer
var _picker: LobbyView.MissionPicker
var _start_button: Button
var _last_sig: String = ""


func _init() -> void:
	layer = 50
	name = "RoomBar"


func setup(owner_session: Node) -> RoomBar:
	session = owner_session
	_build()
	visible = false
	return self


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.build()   # una CanvasLayer non eredita il tema della finestra
	add_child(_root)
	var safe: Control = ScreenFrame.safe_holder(_root)

	_strip = PanelContainer.new()
	_strip.add_theme_stylebox_override("panel", LobbyView._style(BattleTheme.CY))
	_strip.anchor_left = 1.0
	_strip.anchor_right = 1.0
	_strip.anchor_top = 1.0
	_strip.anchor_bottom = 1.0
	_strip.offset_left = -448.0
	_strip.offset_right = -10.0
	_strip.offset_top = -58.0
	_strip.offset_bottom = -8.0
	safe.add_child(_strip)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_strip.add_child(row)

	_title = BattleTheme.make_label("STANZA", 15, BattleTheme.CY)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_title)

	_ready_button = Button.new()
	_ready_button.custom_minimum_size = Vector2(130, 34)
	_ready_button.pressed.connect(_on_ready)
	row.add_child(_ready_button)

	_toggle_button = Button.new()
	_toggle_button.custom_minimum_size = Vector2(40, 34)
	_toggle_button.pressed.connect(_on_toggle)
	row.add_child(_toggle_button)

	_drop = PanelContainer.new()
	_drop.add_theme_stylebox_override("panel", LobbyView._style(BattleTheme.CY))
	_drop.anchor_left = 1.0
	_drop.anchor_right = 1.0
	_drop.anchor_top = 1.0
	_drop.anchor_bottom = 1.0
	_drop.offset_left = -448.0
	_drop.offset_right = -10.0
	_drop.offset_bottom = -64.0
	_drop.offset_top = -64.0
	safe.add_child(_drop)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_drop.add_child(col)

	_cards = VBoxContainer.new()
	_cards.add_theme_constant_override("separation", 6)
	col.add_child(_cards)

	col.add_child(BattleTheme.make_label("MISSIONE", 13, BattleTheme.CY_DIM))
	_picker = LobbyView.MissionPicker.new()
	col.add_child(_picker)

	_start_button = Button.new()
	_start_button.text = "AVVIA PARTITA"
	_start_button.custom_minimum_size = Vector2(0, 44)
	BattleTheme.style_button(_start_button, "primary", 22)
	_start_button.pressed.connect(_on_start)
	col.add_child(_start_button)

	var lobby_button := Button.new()
	lobby_button.text = "APRI LA LOBBY"
	lobby_button.custom_minimum_size = Vector2(0, 38)
	BattleTheme.style_button(lobby_button, "normal", 18)
	lobby_button.pressed.connect(_on_open_lobby)
	col.add_child(lobby_button)

	var leave := Button.new()
	leave.text = "ESCI DALLA STANZA"
	leave.custom_minimum_size = Vector2(0, 38)
	BattleTheme.style_button(leave, "normal", 18)
	leave.pressed.connect(_on_leave)
	col.add_child(leave)


	_drop.visible = false


func _manager() -> NetworkManager:
	return session.manager if session != null else null


# Chiamata quando la lobby, la scena o lo stato cambiano.
func refresh() -> void:
	var m: NetworkManager = _manager()
	var scene: Node = get_tree().current_scene if is_inside_tree() else null
	var hidden_here: bool = scene != null and (
		str(scene.scene_file_path).contains("battle_screen")
		or str(scene.scene_file_path).contains("lobby_demo")
	)
	visible = m != null and not hidden_here
	if not visible:
		return

	var players: Array = m.lobby.get("players", [])
	_title.text = "STANZA · %d OPERATORI" % players.size()
	var mine: bool = m.is_local_ready()
	_ready_button.text = "ANNULLA" if mine else "PRONTO"
	BattleTheme.style_button(_ready_button, "normal" if mine else "primary", 18)
	_ready_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toggle_button.text = "▲" if expanded else "▼"
	_toggle_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	BattleTheme.style_button(_toggle_button, "normal", 16)
	_toggle_button.alignment = HORIZONTAL_ALIGNMENT_CENTER

	_drop.visible = expanded
	if expanded:
		LobbyView.fill_players(_cards, m.lobby, m.local_player_id, false)
		if _picker.manager == null:
			_picker.setup(m)
		else:
			_picker.manager = m
			_picker.refresh()
		_start_button.visible = m.is_host
		_start_button.disabled = not m.all_ready()
		_drop.offset_top = _drop.offset_bottom - _drop.get_combined_minimum_size().y


func _on_ready() -> void:
	var m: NetworkManager = _manager()
	if m != null:
		m.set_ready(not m.is_local_ready())


func _on_toggle() -> void:
	expanded = not expanded
	refresh()


func _on_start() -> void:
	var m: NetworkManager = _manager()
	if m != null and not m.host_launch():
		Notify.warning("Servono almeno 2 giocatori e tutti PRONTI.")


func _on_open_lobby() -> void:
	SceneRouter.go("lobby")


func _on_leave() -> void:
	session.leave_room()
