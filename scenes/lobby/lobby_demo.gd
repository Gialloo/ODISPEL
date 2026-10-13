extends Control

# Lobby co-op. Senza stanza: modulo per crearne una o entrare. Dentro la stanza:
# tutti i giocatori con il loro personaggio guida, PRONTO e (per l'host) AVVIA.
# La stanza vive in NetSession, quindi si puo' uscire da questa schermata
# (hub, squadra, missioni) senza perderla: la barra in alto la tiene a portata.

const DEFAULT_ROOM: String = "odispel"

var form_panel: HudPanel
var room_panel: HudPanel
var url_edit: LineEdit
var room_edit: LineEdit
var name_edit: LineEdit
var max_players_spin: SpinBox
var host_button: Button
var join_button: Button
var status_label: Label
var room_info_label: Label
var cards_box: HBoxContainer
var picker: LobbyView.MissionPicker
var ready_button: Button
var start_button: Button
var _in_room: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var window: Window = get_window()
	if window != null:
		window.content_scale_size = Vector2i(1280, 720)
	_build_interface()
	if NetSession.manager != null:
		_connect_manager()
		_show_room()
	else:
		_show_form()


func _build_interface() -> void:
	ScreenFx.solid(self, BattleTheme.BK)

	ScreenFx.menu_overlays(self, BattleTheme.CY)

	var title := BattleTheme.make_label("LOBBY CO-OP", 34, BattleTheme.CY, true)
	title.position = Vector2(40, 22)
	add_child(title)

	status_label = BattleTheme.make_label("", 15, BattleTheme.WH)
	status_label.position = Vector2(40, 672)
	status_label.size = Vector2(1200, 30)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status_label)

	_build_form()
	_build_room()


func _build_form() -> void:
	form_panel = HudPanel.new().setup("CONNESSIONE", BattleTheme.CY)
	form_panel.position = Vector2(340, 90)
	form_panel.size = Vector2(600, 540)
	add_child(form_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	form_panel.set_content(box)

	url_edit = _add_field(box, "SERVER DI SIGNALING", GameConfig.get_server_url())
	room_edit = _add_field(box, "STANZA", DEFAULT_ROOM)
	name_edit = _add_field(box, "IL TUO NOME", "Giocatore")

	var spin_row := HBoxContainer.new()
	box.add_child(spin_row)
	var spin_label := BattleTheme.make_label("POSTI NEL PARTY (SOLO HOST)", 14, BattleTheme.CY)
	spin_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_row.add_child(spin_label)
	max_players_spin = SpinBox.new()
	max_players_spin.min_value = 2
	max_players_spin.max_value = 6
	max_players_spin.step = 1
	max_players_spin.value = 4
	spin_row.add_child(max_players_spin)

	host_button = Button.new()
	host_button.text = "CREA STANZA (HOST)"
	host_button.custom_minimum_size.y = 52
	BattleTheme.style_button(host_button, "primary", 22)
	host_button.pressed.connect(_on_host_pressed)
	box.add_child(host_button)

	join_button = Button.new()
	join_button.text = "ENTRA IN UNA STANZA"
	join_button.custom_minimum_size.y = 52
	BattleTheme.style_button(join_button, "normal", 22)
	join_button.pressed.connect(_on_join_pressed)
	box.add_child(join_button)

	var back := Button.new()
	back.text = "TORNA ALL'HUB"
	back.custom_minimum_size.y = 44
	BattleTheme.style_button(back, "normal", 18)
	back.pressed.connect(_on_back_pressed)
	box.add_child(back)


func _build_room() -> void:
	room_panel = HudPanel.new().setup("STANZA", BattleTheme.RD)
	room_panel.position = Vector2(40, 80)
	room_panel.size = Vector2(1200, 580)
	add_child(room_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	room_panel.set_content(box)

	room_info_label = BattleTheme.make_label("", 18, BattleTheme.WH)
	box.add_child(room_info_label)

	cards_box = HBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 12)
	cards_box.custom_minimum_size = Vector2(0, 310)
	box.add_child(cards_box)

	box.add_child(BattleTheme.make_label("MISSIONE (LA SCEGLIE L'HOST)", 14, BattleTheme.CY_DIM))
	picker = LobbyView.MissionPicker.new()
	box.add_child(picker)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)

	ready_button = Button.new()
	ready_button.custom_minimum_size = Vector2(240, 54)
	ready_button.pressed.connect(_on_ready_pressed)
	row.add_child(ready_button)

	start_button = Button.new()
	start_button.text = "AVVIA PARTITA"
	start_button.custom_minimum_size = Vector2(260, 54)
	BattleTheme.style_button(start_button, "primary", 24)
	start_button.pressed.connect(_on_start_pressed)
	row.add_child(start_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var squad := Button.new()
	squad.text = "SQUADRA"
	squad.custom_minimum_size = Vector2(160, 54)
	BattleTheme.style_button(squad, "normal", 20)
	squad.pressed.connect(func() -> void: SceneRouter.go("roster"))
	row.add_child(squad)

	var hub := Button.new()
	hub.text = "HUB"
	hub.custom_minimum_size = Vector2(110, 54)
	BattleTheme.style_button(hub, "normal", 20)
	hub.pressed.connect(func() -> void: SceneRouter.go("hub"))
	row.add_child(hub)

	var leave := Button.new()
	leave.text = "ESCI"
	leave.custom_minimum_size = Vector2(110, 54)
	BattleTheme.style_button(leave, "normal", 20)
	leave.pressed.connect(_on_leave_pressed)
	row.add_child(leave)


func _add_field(parent: Control, caption: String, value: String) -> LineEdit:
	parent.add_child(BattleTheme.make_label(caption, 14, BattleTheme.CY))
	var edit := LineEdit.new()
	edit.text = value
	edit.custom_minimum_size.y = 36
	parent.add_child(edit)
	return edit


func _show_form() -> void:
	_in_room = false
	form_panel.visible = true
	room_panel.visible = false
	host_button.disabled = false
	join_button.disabled = false


func _show_room() -> void:
	_in_room = true
	form_panel.visible = false
	room_panel.visible = true
	if picker.manager == null and NetSession.manager != null:
		picker.setup(NetSession.manager)
	_refresh()


func _set_status(text: String) -> void:
	status_label.text = text


# Legge e controlla i campi del modulo. Restituisce {} se qualcosa non va.
func _read_form() -> Dictionary:
	var url: String = GameConfig.normalize_server_url(url_edit.text)
	var room: String = room_edit.text.strip_edges()
	var display_name: String = name_edit.text.strip_edges()

	if not (url.begins_with("ws://") or url.begins_with("wss://")):
		_set_status("L'indirizzo del server deve iniziare con ws:// o wss://")
		return {}

	var room_check := RegEx.new()
	room_check.compile("^[a-zA-Z0-9_-]{1,48}$")

	if room_check.search(room) == null:
		_set_status("Il nome della stanza può avere solo lettere, numeri, - e _ (max 48).")
		return {}

	if display_name.is_empty():
		display_name = "Giocatore"

	url_edit.text = url
	GameConfig.remember_server_url(url)
	return {"url": url, "room": room, "name": display_name.substr(0, 24)}


func _on_host_pressed() -> void:
	var form: Dictionary = _read_form()
	if form.is_empty():
		return
	if not NetSession.start_host(form["url"], form["room"], form["name"], int(max_players_spin.value)):
		_set_status("Impossibile avviare l'host.")
		return
	_after_connect_started(form["room"])


func _on_join_pressed() -> void:
	var form: Dictionary = _read_form()
	if form.is_empty():
		return
	if not NetSession.start_client(form["url"], form["room"], form["name"]):
		_set_status("Impossibile avviare la connessione.")
		return
	_after_connect_started(form["room"])


var _room_name: String = ""


func _after_connect_started(room: String) -> void:
	_room_name = room
	_connect_manager()
	host_button.disabled = true
	join_button.disabled = true
	_set_status("Connessione al server... (se è inattivo può servire fino a 1 minuto)")


func _connect_manager() -> void:
	var manager: NetworkManager = NetSession.manager
	if manager == null:
		return
	manager.room_joined.connect(_on_room_joined)
	manager.lobby_updated.connect(_refresh)
	manager.waiting_for_host.connect(_on_waiting_for_host)
	manager.signaling_lost.connect(_on_signaling_lost)


func _on_room_joined() -> void:
	_show_room()
	if NetSession.manager.is_host:
		_set_status("Stanza creata. Fai entrare gli altri: quando tutti sono PRONTI puoi avviare.")
	else:
		_set_status("Collegamento con l'host in corso...")


func _on_waiting_for_host(attempt: int) -> void:
	_set_status("L'host non c'è ancora: nuovo tentativo (" + str(attempt) + ")...")


func _on_signaling_lost() -> void:
	_set_status("Il server di signaling non risponde: nessun altro potrà entrare.")


func _process(_delta: float) -> void:
	# La stanza e' sparita (errore di rete o uscita dalla barra): torna il modulo.
	if _in_room and NetSession.manager == null:
		_show_form()
		_set_status(("Errore di rete: " + NetSession.last_error) if NetSession.last_error != "" else "Sei uscito dalla stanza.")
	elif not _in_room and NetSession.manager == null and NetSession.last_error != "" and host_button.disabled:
		_show_form()
		_set_status("Errore di rete: " + NetSession.last_error)


func _refresh() -> void:
	var manager: NetworkManager = NetSession.manager
	if manager == null or not _in_room:
		return

	var players: Array = manager.lobby.get("players", [])
	room_info_label.text = "STANZA %s  —  %s  —  %d OPERATORI" % [
		(_room_name if _room_name != "" else room_edit.text.strip_edges()).to_upper(),
		"SEI L'HOST" if manager.is_host else "SEI UN CLIENT",
		players.size()
	]
	LobbyView.fill_players(cards_box, manager.lobby, manager.local_player_id, true)
	picker.refresh()

	var mine: bool = manager.is_local_ready()
	ready_button.text = "ANNULLA PRONTO" if mine else "PRONTO"
	BattleTheme.style_button(ready_button, "normal" if mine else "primary", 24)
	ready_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_button.visible = manager.is_host
	start_button.disabled = not manager.all_ready()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo or not _in_room:
		return
	# SPAZIO = pronto / annulla, INVIO = avvia (host), ESC = hub (la stanza resta aperta)
	match event.keycode:
		KEY_SPACE:
			_on_ready_pressed()
		KEY_ENTER, KEY_KP_ENTER:
			if not start_button.disabled and start_button.visible:
				_on_start_pressed()
		KEY_ESCAPE:
			SceneRouter.go("hub")


func _on_ready_pressed() -> void:
	var manager: NetworkManager = NetSession.manager
	if manager != null:
		manager.set_ready(not manager.is_local_ready())


func _on_start_pressed() -> void:
	var manager: NetworkManager = NetSession.manager
	if manager == null:
		return
	if not manager.all_ready():
		_set_status("Servono almeno 2 giocatori e tutti PRONTI.")
		return
	# Chi non ha ancora sbloccato quel livello puo' giocarlo lo stesso, ma l'host deve confermare.
	var lacking: Array = manager.players_lacking_unlock(manager.lobby_boss, manager.lobby_tier)
	if lacking.is_empty():
		manager.host_launch()
		return
	var who: String = " e ".join(lacking) if lacking.size() <= 2 else "%s e altri %d" % [str(lacking[0]), lacking.size() - 1]
	var text: String = "%s non ha ancora sbloccato questo livello.\nProcedere lo stesso?" % who if lacking.size() == 1 else "%s non hanno ancora sbloccato questo livello.\nProcedere lo stesso?" % who
	ConfirmBox.ask(self, text, func() -> void:
		if NetSession.manager != null and not NetSession.manager.host_launch():
			_set_status("Servono almeno 2 giocatori e tutti PRONTI."))


func _on_leave_pressed() -> void:
	NetSession.leave_room()
	_show_form()
	_set_status("Sei uscito dalla stanza.")


func _on_back_pressed() -> void:
	SceneRouter.go("hub")
