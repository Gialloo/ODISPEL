extends Control

# Combattimento in rete. Lo stato arriva sempre dall'host (NetSession.manager):
# qui si mostra e si inviano le azioni del giocatore locale.

const RESULTS_SCENE: String = "res://scenes/results/results_demo.tscn"
const HUB_SCENE: String = "res://scenes/hub/hub_demo.tscn"
const FINISH_DELAY: float = 2.5

var manager: NetworkManager = null

var round_label: Label
var timer_label: Label
var boss_label: Label
var boss_bar: ProgressBar
var status_label: Label
var attack_button: Button
var attack_button_label_base: String = "Attacca (100 danni base)"
var guard_button: Button
var party_box: VBoxContainer
var combat_log: RichTextLabel

var _rows: Dictionary = {}  # player_id -> {"label": Label, "bar": ProgressBar}
var _finished: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	manager = NetSession.manager

	if manager == null or manager.game == null:
		push_error("Combattimento in rete senza sessione attiva.")
		call_deferred("_leave_to_hub")
		return

	_build_interface()

	manager.snapshot_received.connect(_on_snapshot)
	manager.round_result_received.connect(_on_round_result)
	manager.network_error.connect(_on_network_error)
	manager.player_left.connect(_on_player_left)
	manager.signaling_lost.connect(_on_signaling_lost)

	_log("Combattimento iniziato. Scegli la tua azione.")
	_refresh()


func _process(_delta: float) -> void:
	if _finished or manager == null or manager.game == null:
		return

	var combat: CombatState = manager.game.combat

	if combat == null or combat.round_state == null:
		return

	if combat.phase == CombatState.Phase.PLANNING:
		timer_label.text = "Tempo per scegliere: " + str(
			int(ceil(combat.round_state.time_remaining))
		) + " s"
	else:
		timer_label.text = ""


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#11121a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "ODISPEL — COMBATTIMENTO CO-OP"
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)

	var header := HBoxContainer.new()
	layout.add_child(header)

	round_label = Label.new()
	round_label.text = "Round 1"
	round_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(round_label)

	timer_label = Label.new()
	header.add_child(timer_label)

	boss_label = Label.new()
	boss_label.add_theme_font_size_override("font_size", 20)
	layout.add_child(boss_label)

	boss_bar = ProgressBar.new()
	boss_bar.custom_minimum_size.y = 24
	boss_bar.show_percentage = false
	layout.add_child(boss_bar)

	layout.add_child(HSeparator.new())

	var party_title := Label.new()
	party_title.text = "PARTY"
	party_title.add_theme_font_size_override("font_size", 20)
	layout.add_child(party_title)

	party_box = VBoxContainer.new()
	party_box.add_theme_constant_override("separation", 4)
	layout.add_child(party_box)

	layout.add_child(HSeparator.new())

	var buttons_row := HBoxContainer.new()
	buttons_row.add_theme_constant_override("separation", 8)
	layout.add_child(buttons_row)

	attack_button = Button.new()
	attack_button.text = attack_button_label_base
	attack_button.custom_minimum_size.y = 44
	attack_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attack_button.pressed.connect(_on_action_pressed.bind("attack"))
	buttons_row.add_child(attack_button)

	guard_button = Button.new()
	guard_button.text = "Difenditi"
	guard_button.custom_minimum_size.y = 44
	guard_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guard_button.pressed.connect(_on_action_pressed.bind("guard"))
	buttons_row.add_child(guard_button)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status_label)

	var leave_button := Button.new()
	leave_button.text = "ESCI DALLA PARTITA"
	leave_button.pressed.connect(_leave_to_hub)
	layout.add_child(leave_button)

	var log_title := Label.new()
	log_title.text = "REGISTRO DEL COMBATTIMENTO"
	layout.add_child(log_title)

	combat_log = RichTextLabel.new()
	combat_log.bbcode_enabled = false
	combat_log.scroll_following = true
	combat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	combat_log.custom_minimum_size.y = 140
	layout.add_child(combat_log)


func _on_snapshot() -> void:
	_refresh()


func _refresh() -> void:
	if manager == null or manager.game == null:
		return

	var game: GameState = manager.game
	var combat: CombatState = game.combat

	if combat == null or combat.boss == null or game.party == null:
		return

	var boss: BossState = combat.boss
	boss_label.text = (
		boss.display_name + " — " + str(boss.hp) + " / " + str(boss.max_hp) + " HP"
	)
	boss_bar.max_value = boss.max_hp
	boss_bar.value = boss.hp

	if combat.round_state != null:
		round_label.text = "Round " + str(combat.round_state.number)

	for player: PlayerState in game.party.get_players():
		if not _rows.has(player.id):
			_add_row(player.id)

		var row: Dictionary = _rows[player.id]
		var label: Label = row["label"]
		var bar: ProgressBar = row["bar"]

		var mine: String = " (tu)" if player.id == manager.local_player_id else ""
		label.text = (
			player.display_name + mine
			+ " — " + str(player.hp) + " / " + str(player.max_hp) + " HP"
			+ " — " + _player_status(player)
		)
		bar.max_value = player.max_hp
		bar.value = player.hp

	_update_buttons()

	if combat.phase == CombatState.Phase.ENDED and not _finished:
		_finish(not combat.is_boss_alive())


func _add_row(player_id: String) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	party_box.add_child(box)

	var label := Label.new()
	box.add_child(label)

	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 14
	bar.show_percentage = false
	box.add_child(bar)

	_rows[player_id] = {"label": label, "bar": bar}


func _player_status(player: PlayerState) -> String:
	if not player.is_alive:
		return "KO"

	if not player.connected:
		return "disconnesso (IA)"

	if player.controlled_by_ai:
		return "IA"

	if player.is_locked:
		var text: String = "pronto"

		# Si vede la scelta degli altri solo dopo il round, quella propria sempre.
		if (
			player.id == manager.local_player_id
			and not player.selected_action_id.is_empty()
		):
			text += " (" + player.selected_action_id + ")"

		return text

	return "sta scegliendo"


func _local_player() -> PlayerState:
	if manager == null or manager.game == null or manager.game.party == null:
		return null

	for player: PlayerState in manager.game.party.get_players():
		if player.id == manager.local_player_id:
			return player

	return null


func _update_buttons() -> void:
	var me: PlayerState = _local_player()
	var combat: CombatState = manager.game.combat

	var can_choose: bool = (
		not _finished
		and me != null
		and me.can_act()
		and combat != null
		and combat.phase == CombatState.Phase.PLANNING
	)

	attack_button.disabled = not can_choose
	guard_button.disabled = not can_choose

	if _finished:
		return

	if me == null:
		status_label.text = "In attesa dei dati dall'host..."
	elif not me.is_alive:
		status_label.text = "Sei KO. Guarda il resto del party."
	elif me.is_locked:
		status_label.text = "Scelta inviata. In attesa degli altri giocatori."
	else:
		status_label.text = "Scegli la tua azione."


func _on_action_pressed(action_id: String) -> void:
	if _finished or manager == null:
		return

	if manager.submit_action(action_id):
		attack_button.disabled = true
		guard_button.disabled = true
		status_label.text = "Azione inviata: " + action_id + "."


func _on_round_result(events: Array) -> void:
	var victory: bool = false
	var defeat: bool = false

	for event: Variant in events:
		if not event is Dictionary:
			continue

		_log(str(event.get("text", "")))

		match str(event.get("type", "")):
			"victory":
				victory = true
			"defeat":
				defeat = true

	_refresh()

	if victory:
		_finish(true)
	elif defeat:
		_finish(false)


func _on_player_left(player_id: String) -> void:
	_log(player_id + " si è disconnesso: gioca l'IA al suo posto.")


func _on_signaling_lost() -> void:
	_log("Il server di signaling non risponde: la partita continua.")


func _on_network_error(reason: String) -> void:
	# A combattimento finito la chiusura dei collegamenti è normale.
	if _finished:
		return

	_log("ERRORE DI RETE: " + reason)
	status_label.text = "Connessione persa: " + reason
	attack_button.disabled = true
	guard_button.disabled = true


func _finish(victory: bool) -> void:
	if _finished:
		return

	_finished = true
	attack_button.disabled = true
	guard_button.disabled = true

	var combat: CombatState = manager.game.combat
	var boss_id: String = ""

	if combat != null and combat.boss != null:
		boss_id = combat.boss.id

	get_tree().set_meta("combat_level_before", CampaignState.player_level)

	if victory:
		status_label.text = "VITTORIA — boss sconfitto!"
		_log("COMBATTIMENTO COMPLETATO: VITTORIA.")

		# Le ricompense sono dell'incontro dell'host, non di quello
		# selezionato nella campagna locale di ciascun giocatore.
		if not boss_id.is_empty():
			CampaignState.mark_encounter_completed(boss_id)

			if CampaignState.claim_encounter_rewards(boss_id):
				_log("Ricompense ottenute.")
	else:
		status_label.text = "SCONFITTA — party KO."
		_log("COMBATTIMENTO COMPLETATO: SCONFITTA.")

	get_tree().set_meta("combat_level_after", CampaignState.player_level)
	get_tree().set_meta("combat_result", "victory" if victory else "defeat")
	get_tree().set_meta("combat_mode", "net")
	get_tree().set_meta("net_encounter_id", boss_id)

	await get_tree().create_timer(FINISH_DELAY).timeout

	if not is_inside_tree():
		return

	var error: int = get_tree().change_scene_to_file(RESULTS_SCENE)

	if error != OK:
		push_error("Impossibile aprire la schermata dei risultati. Codice: " + str(error))


func _leave_to_hub() -> void:
	NetSession.close()
	var error: int = get_tree().change_scene_to_file(HUB_SCENE)

	if error != OK:
		push_error("Impossibile tornare all'hub. Codice: " + str(error))


func _log(message: String) -> void:
	if combat_log != null:
		combat_log.append_text(message + "\n")
