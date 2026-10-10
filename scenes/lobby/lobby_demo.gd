extends Control

const HUB_SCENE: String = "res://scenes/hub/hub_demo.tscn"
const COMBAT_SCENE: String = "res://scenes/combat/combat_net.tscn"
const DEFAULT_ROOM: String = "odispel"

var form_box: VBoxContainer
var room_box: VBoxContainer
var url_edit: LineEdit
var room_edit: LineEdit
var name_edit: LineEdit
var max_players_spin: SpinBox
var host_button: Button
var join_button: Button
var status_label: Label
var room_info_label: Label
var players_label: Label
var start_button: Button

var _leaving: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Tornando qui si riparte sempre da una sessione pulita.
	NetSession.close()

	_build_interface()
	_show_form()


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#11121a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var layout := VBoxContainer.new()
	layout.custom_minimum_size = Vector2(480, 420)
	layout.add_theme_constant_override("separation", 10)
	center.add_child(layout)

	var title := Label.new()
	title.text = "ODISPEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "LOBBY CO-OP"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	layout.add_child(subtitle)

	layout.add_child(HSeparator.new())

	# --- Modulo di connessione ---
	form_box = VBoxContainer.new()
	form_box.add_theme_constant_override("separation", 8)
	layout.add_child(form_box)

	url_edit = _add_field(form_box, "Server di signaling", GameConfig.get_server_url())
	room_edit = _add_field(form_box, "Stanza", DEFAULT_ROOM)
	name_edit = _add_field(form_box, "Il tuo nome", "Giocatore")

	var spin_row := HBoxContainer.new()
	form_box.add_child(spin_row)

	var spin_label := Label.new()
	spin_label.text = "Posti nel party (solo host)"
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
	host_button.custom_minimum_size.y = 44
	host_button.pressed.connect(_on_host_pressed)
	form_box.add_child(host_button)

	join_button = Button.new()
	join_button.text = "ENTRA IN UNA STANZA (CLIENT)"
	join_button.custom_minimum_size.y = 44
	join_button.pressed.connect(_on_join_pressed)
	form_box.add_child(join_button)

	var back_button := Button.new()
	back_button.text = "TORNA ALL'HUB"
	back_button.custom_minimum_size.y = 40
	back_button.pressed.connect(_on_back_pressed)
	form_box.add_child(back_button)

	# --- Stanza ---
	room_box = VBoxContainer.new()
	room_box.add_theme_constant_override("separation", 8)
	layout.add_child(room_box)

	room_info_label = Label.new()
	room_info_label.add_theme_font_size_override("font_size", 18)
	room_box.add_child(room_info_label)

	players_label = Label.new()
	players_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	room_box.add_child(players_label)

	start_button = Button.new()
	start_button.text = "AVVIA PARTITA"
	start_button.custom_minimum_size.y = 46
	start_button.pressed.connect(_on_start_pressed)
	room_box.add_child(start_button)

	var leave_button := Button.new()
	leave_button.text = "ESCI DALLA STANZA"
	leave_button.custom_minimum_size.y = 40
	leave_button.pressed.connect(_on_leave_pressed)
	room_box.add_child(leave_button)

	layout.add_child(HSeparator.new())

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 48
	layout.add_child(status_label)


func _add_field(parent: Control, caption: String, value: String) -> LineEdit:
	var label := Label.new()
	label.text = caption
	parent.add_child(label)

	var edit := LineEdit.new()
	edit.text = value
	edit.custom_minimum_size.y = 34
	parent.add_child(edit)
	return edit


func _show_form() -> void:
	form_box.visible = true
	room_box.visible = false
	host_button.disabled = false
	join_button.disabled = false


func _show_room() -> void:
	form_box.visible = false
	room_box.visible = true

	var manager: NetworkManager = NetSession.manager

	if manager == null:
		return

	room_info_label.text = (
		"Stanza: " + room_edit.text.strip_edges()
		+ ("  —  sei l'HOST" if manager.is_host else "  —  sei un CLIENT")
	)
	start_button.visible = manager.is_host
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

	return {
		"url": url,
		"room": room,
		"name": display_name.substr(0, 24)
	}


func _on_host_pressed() -> void:
	var form: Dictionary = _read_form()

	if form.is_empty():
		return

	if not NetSession.start_host(
		form["url"], form["room"], form["name"], int(max_players_spin.value)
	):
		_set_status("Impossibile avviare l'host.")
		return

	_after_connect_started()


func _on_join_pressed() -> void:
	var form: Dictionary = _read_form()

	if form.is_empty():
		return

	if not NetSession.start_client(form["url"], form["room"], form["name"]):
		_set_status("Impossibile avviare la connessione.")
		return

	_after_connect_started()


func _after_connect_started() -> void:
	var manager: NetworkManager = NetSession.manager

	manager.room_joined.connect(_on_room_joined)
	manager.snapshot_received.connect(_refresh)
	manager.player_assigned.connect(_on_player_assigned)
	manager.player_left.connect(_on_player_left)
	manager.network_error.connect(_on_network_error)
	manager.waiting_for_host.connect(_on_waiting_for_host)
	manager.signaling_lost.connect(_on_signaling_lost)

	host_button.disabled = true
	join_button.disabled = true
	_set_status("Connessione al server... (se è inattivo può servire fino a 1 minuto)")


func _on_room_joined() -> void:
	_show_room()

	if NetSession.manager.is_host:
		_set_status("Stanza creata. Fai entrare gli altri, poi avvia la partita.")
	else:
		_set_status("Collegamento con l'host in corso...")


func _on_player_assigned(player_id: String) -> void:
	var manager: NetworkManager = NetSession.manager

	if manager != null and not manager.is_host:
		_set_status("Sei dentro come " + player_id + ". Attendi che l'host avvii la partita.")

	_refresh()


func _on_player_left(player_id: String) -> void:
	_set_status(player_id + " ha lasciato la stanza.")
	_refresh()


func _on_waiting_for_host(attempt: int) -> void:
	_set_status("L'host non c'è ancora: nuovo tentativo (" + str(attempt) + ")...")


func _on_signaling_lost() -> void:
	_set_status("Il server di signaling non risponde: nessun altro potrà entrare.")


func _on_network_error(reason: String) -> void:
	if _leaving:
		return

	NetSession.close()
	_show_form()
	_set_status("Errore di rete: " + reason)


func _refresh() -> void:
	var manager: NetworkManager = NetSession.manager

	if manager == null or _leaving:
		return

	var game: GameState = manager.game
	var lines := PackedStringArray()

	if game != null and game.party != null:
		for player: PlayerState in game.party.get_players():
			var tag: String = " (tu)" if player.id == manager.local_player_id else ""
			var state: String = "libero"

			if player.connected and not player.controlled_by_ai:
				state = "connesso"
			elif player.controlled_by_ai and manager.is_host:
				state = "libero / disconnesso"

			lines.append("• " + player.display_name + tag + "  —  " + state)

	players_label.text = (
		"\n".join(lines) if not lines.is_empty() else "In attesa dei dati dell'host..."
	)

	if manager.is_host:
		start_button.disabled = manager.get_connected_human_count() < 2
		return

	# Il client segue l'host: appena parte il combattimento, ci va anche lui.
	if game != null and game.combat != null and not game.combat.is_finished():
		_go_to_combat()


func _on_start_pressed() -> void:
	var manager: NetworkManager = NetSession.manager

	if manager == null:
		return

	# Combattimento già avviato (per esempio il cambio scena era fallito):
	# basta riprovare ad aprirlo.
	if (
		manager.game != null
		and manager.game.combat != null
		and not manager.game.combat.is_finished()
	):
		_go_to_combat()
		return

	if manager.get_connected_human_count() < 2:
		_set_status("Impossibile avviare: servono almeno 2 giocatori connessi.")
		return

	if not NetSession.host_start_combat():
		_set_status("Impossibile avviare: incontro della campagna non valido.")
		return

	_go_to_combat()


func _go_to_combat() -> void:
	if _leaving:
		return

	_leaving = true
	var error: int = get_tree().change_scene_to_file(COMBAT_SCENE)

	if error != OK:
		_leaving = false
		push_error("Impossibile aprire il combattimento. Codice: " + str(error))


func _on_leave_pressed() -> void:
	NetSession.close()
	_show_form()
	_set_status("Sei uscito dalla stanza.")


func _on_back_pressed() -> void:
	NetSession.close()
	var error: int = get_tree().change_scene_to_file(HUB_SCENE)

	if error != OK:
		push_error("Impossibile tornare all'hub. Codice: " + str(error))
