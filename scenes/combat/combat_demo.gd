
extends Control

const PLAYER_MAX_HP: int = 1000
const BOSS_MAX_HP: int = 2000
const PLAYER_DAMAGE: int = 100
const BOSS_DAMAGE: int = 200
const MAX_DAMAGE_REDUCTION: float = 0.50

var game: GameState
var player_actions: Dictionary = {}
var player_labels: Dictionary = {}
var player_bars: Dictionary = {}
var action_buttons: Dictionary = {}

var boss_label: Label
var boss_bar: ProgressBar
var round_label: Label
var status_label: Label
var resolve_button: Button
var combat_log: RichTextLabel

var boss_target_index: int = 0
var combat_over: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_interface()

	if not _initialize_combat():
		status_label.text = "ERRORE: impossibile inizializzare il combattimento."
		return

	_refresh_interface()
	_update_resolve_button()
	_log("Combattimento iniziato. Scegli un'azione per entrambi i giocatori.")


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = BattleTheme.BK
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
	title.text = "ODISPEL — COMBAT DEMO"
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)

	round_label = Label.new()
	round_label.text = "Round 1"
	layout.add_child(round_label)

	var boss_title := Label.new()
	boss_title.text = "BOSS DI PROVA"
	boss_title.add_theme_font_size_override("font_size", 20)
	layout.add_child(boss_title)

	boss_label = Label.new()
	layout.add_child(boss_label)

	boss_bar = ProgressBar.new()
	boss_bar.custom_minimum_size.y = 24
	boss_bar.show_percentage = false
	layout.add_child(boss_bar)

	var separator := HSeparator.new()
	layout.add_child(separator)

	var players_title := Label.new()
	players_title.text = "PARTY"
	players_title.add_theme_font_size_override("font_size", 20)
	layout.add_child(players_title)

	for player_id in ["player_1", "player_2"]:
		var player_box := VBoxContainer.new()
		player_box.add_theme_constant_override("separation", 6)
		layout.add_child(player_box)

		var player_name := Label.new()
		player_name.text = "Giocatore"
		player_box.add_child(player_name)
		player_labels[player_id] = player_name

		var hp_bar := ProgressBar.new()
		hp_bar.custom_minimum_size.y = 18
		hp_bar.show_percentage = false
		player_box.add_child(hp_bar)
		player_bars[player_id] = hp_bar

		var buttons_row := HBoxContainer.new()
		buttons_row.add_theme_constant_override("separation", 8)
		player_box.add_child(buttons_row)

		var attack_button := Button.new()
		attack_button.text = "Attacca (100 danni base)"
		attack_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		attack_button.pressed.connect(
			_on_action_selected.bind(player_id, "attack")
		)
		buttons_row.add_child(attack_button)

		var guard_button := Button.new()
		guard_button.text = "Difenditi"
		guard_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		guard_button.pressed.connect(
			_on_action_selected.bind(player_id, "guard")
		)
		buttons_row.add_child(guard_button)

		action_buttons[player_id] = {
			"attack": attack_button,
			"guard": guard_button
		}

	separator = HSeparator.new()
	layout.add_child(separator)

	status_label = Label.new()
	status_label.text = "Scegli le azioni."
	layout.add_child(status_label)

	resolve_button = Button.new()
	resolve_button.text = "RISOLVI ROUND"
	resolve_button.custom_minimum_size.y = 44
	resolve_button.disabled = true
	resolve_button.pressed.connect(_resolve_round)
	layout.add_child(resolve_button)

	var log_title := Label.new()
	log_title.text = "REGISTRO DEL COMBATTIMENTO"
	layout.add_child(log_title)

	combat_log = RichTextLabel.new()
	combat_log.bbcode_enabled = false
	combat_log.scroll_following = true
	combat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	combat_log.custom_minimum_size.y = 160
	layout.add_child(combat_log)


func _initialize_combat() -> bool:
	var encounter: EncounterData = CampaignState.get_current_encounter()

	if encounter == null:
		push_error("Nessun incontro disponibile nella campagna.")
		return false

	if not encounter.is_valid():
		push_error("Configurazione dell'incontro non valida.")
		return false

	game = GameState.new()
	game.setup("combat_demo_session", 1, 1, 2)

	# Statistiche del party in base al livello effettivo.
	var level: int = maxi(1, CampaignState.player_level)
	var hp_level_steps: int = level - 1
	var hp_multiplier: float = 1.0 + (0.10 * hp_level_steps)

	var player_one := PlayerState.new()
	player_one.max_hp = int(round(PLAYER_MAX_HP * hp_multiplier))
	player_one.setup("player_1", "Giocatore 1", 1)

	var player_two := PlayerState.new()
	player_two.max_hp = int(round(PLAYER_MAX_HP * hp_multiplier))
	player_two.setup("player_2", "Giocatore 2", 2)

	if not game.party.add_player(player_one):
		return false

	if not game.party.add_player(player_two):
		return false

	if not game.setup_run("combat_demo_run", 12345, "start"):
		return false

	if not game.begin_combat(
		encounter.encounter_id,
		encounter.display_name,
		encounter.boss_max_hp
	):
		return false

	return true


func _on_action_selected(player_id: String, action: String) -> void:
	if combat_over:
		return

	if not CombatResolver.submit_action(game, player_id, action):
		return

	var player: PlayerState = _get_player(player_id)
	player_actions[player_id] = action

	var buttons: Dictionary = action_buttons[player_id]
	buttons["attack"].disabled = true
	buttons["guard"].disabled = true

	status_label.text = player.display_name + ": " + (
		"attacco selezionato."
		if action == "attack"
		else "difesa selezionata."
	)

	_log(player.display_name + " sceglie: " + action + ".")

	if CombatResolver.can_resolve(game):
		status_label.text = "Le azioni sono pronte. Risolvi il round."
	else:
		status_label.text += " In attesa degli altri giocatori."

	_update_resolve_button()


func _all_living_players_have_actions() -> bool:
	if game == null or game.party == null:
		return false

	var living_players: Array = game.party.get_living_players()

	if living_players.is_empty():
		return false

	for player in living_players:
		if not player_actions.has(player.id):
			return false

	return true


func _update_resolve_button() -> void:
	if resolve_button == null:
		return

	resolve_button.disabled = (
		combat_over
		or game == null
		or not _all_living_players_have_actions()
	)


func _resolve_round() -> void:
	if combat_over or not CombatResolver.can_resolve(game):
		return

	resolve_button.disabled = true

	var result: Dictionary = CombatResolver.resolve_round(
		game,
		CampaignState.player_level
	)

	if not result["ok"]:
		_update_resolve_button()
		return

	for event: Dictionary in result["events"]:
		_log(event["text"])

	_refresh_interface()

	if result["finished"]:
		_finish_combat(result["victory"])
		return

	player_actions.clear()

	for player_id in ["player_1", "player_2"]:
		var buttons: Dictionary = action_buttons[player_id]
		var player: PlayerState = _get_player(player_id)
		var can_act_now: bool = player != null and player.can_act()

		buttons["attack"].disabled = not can_act_now
		buttons["guard"].disabled = not can_act_now

	status_label.text = "Round pronto. Scegli le azioni."
	_update_resolve_button()

func _choose_boss_target() -> PlayerState:
	var living_players: Array = game.party.get_living_players()

	if living_players.is_empty():
		return null

	# Alterna il bersaglio tra i giocatori ancora vivi.
	for offset in range(living_players.size()):
		var index: int = (boss_target_index + offset) % living_players.size()
		var candidate: PlayerState = living_players[index]

		if candidate != null:
			boss_target_index = (index + 1) % living_players.size()
			return candidate

	return null


func _get_player(player_id: String) -> PlayerState:
	for player in game.party.get_players():
		if player.id == player_id:
			return player

	return null


func _refresh_interface() -> void:
	if game == null or game.combat == null:
		return

	var boss: BossState = game.combat.boss

	boss_label.text = (
		boss.display_name + " — "
		+ str(boss.hp) + " / " + str(boss.max_hp) + " HP"
	)

	boss_bar.max_value = boss.max_hp
	boss_bar.value = boss.hp

	round_label.text = "Round " + str(game.combat.round_state.number)

	for player_id in ["player_1", "player_2"]:
		var player: PlayerState = _get_player(player_id)

		if player == null:
			continue

		var name_label: Label = player_labels[player_id]
		var hp_bar: ProgressBar = player_bars[player_id]

		name_label.text = (
			player.display_name + " — "
			+ str(player.hp) + " / " + str(player.max_hp) + " HP"
		)

		if not player.can_act():
			name_label.text += " — KO"

		hp_bar.max_value = player.max_hp
		hp_bar.value = player.hp


func _finish_combat(victory: bool) -> void:
	combat_over = true
	game.end_combat()

	# Registra il livello prima delle eventuali ricompense.
	get_tree().set_meta(
		"combat_level_before",
		CampaignState.player_level
	)

	if victory:
		status_label.text = "VITTORIA — boss sconfitto!"
		_log("COMBATTIMENTO COMPLETATO: VITTORIA.")

		var encounter: EncounterData = CampaignState.get_current_encounter()

		if encounter != null:
			CampaignState.mark_encounter_completed(encounter.encounter_id)

			if CampaignState.claim_encounter_rewards(encounter.encounter_id):
				_log(
					"RICOMPENSE OTTENUTE: "
					+ str(encounter.reward_exp) + " EXP, "
					+ str(encounter.reward_currency) + " CREDITI."
				)
			else:
				_log("Ricompense già riscosse per questo incontro.")
		else:
			push_error(
				"Impossibile registrare il completamento: incontro non trovato."
			)
	else:
		status_label.text = "SCONFITTA — party KO."
		_log("COMBATTIMENTO COMPLETATO: SCONFITTA.")

	# Registra il livello dopo le eventuali ricompense.
	get_tree().set_meta(
		"combat_level_after",
		CampaignState.player_level
	)

	resolve_button.disabled = true

	for player_id in ["player_1", "player_2"]:
		var buttons: Dictionary = action_buttons[player_id]
		buttons["attack"].disabled = true
		buttons["guard"].disabled = true

	_refresh_interface()

	get_tree().set_meta("combat_mode", "local")
	get_tree().set_meta(
		"combat_result",
		"victory" if victory else "defeat"
	)

	var error := get_tree().change_scene_to_file(
		"res://scenes/results/results_demo.tscn"
	)

	if error != OK:
		push_error(
			"Impossibile aprire la schermata dei risultati. Codice: "
			+ str(error)
		)


func _log(message: String) -> void:
	if combat_log != null:
		combat_log.append_text(message + "\n")
