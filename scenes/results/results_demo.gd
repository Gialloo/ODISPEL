
extends Control

var result_label: Label
var details_label: Label
var replay_button: Button
var continue_button: Button
var hub_button: Button


func _ready() -> void:
	_build_interface()


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = BattleTheme.BK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var layout := VBoxContainer.new()
	layout.custom_minimum_size = Vector2(460, 300)
	layout.add_theme_constant_override("separation", 18)
	center.add_child(layout)

	var title := Label.new()
	title.text = "ODISPEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	layout.add_child(title)

	result_label = Label.new()
	result_label.text = "RISULTATI"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 26)
	layout.add_child(result_label)

	details_label = Label.new()
	details_label.text = "Riepilogo dell'incontro"
	details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(details_label)

	replay_button = Button.new()
	replay_button.text = "RIGIOCA"
	replay_button.custom_minimum_size.y = 46
	replay_button.pressed.connect(_on_replay_pressed)
	layout.add_child(replay_button)

	continue_button = Button.new()
	continue_button.text = "CONTINUA"
	continue_button.custom_minimum_size.y = 46
	continue_button.pressed.connect(_on_continue_pressed)
	layout.add_child(continue_button)
	hub_button = Button.new()
	hub_button.text = "TORNA ALL'HUB"
	hub_button.custom_minimum_size.y = 46
	hub_button.pressed.connect(_on_hub_pressed)
	layout.add_child(hub_button)

	_show_result(str(get_tree().get_meta("combat_result", "victory")))

	# In rete non si rigioca né si prosegue da soli: si torna all'hub.
	if _is_net():
		replay_button.visible = false
		continue_button.visible = false


# True se il risultato viene da un combattimento in rete.
func _is_net() -> bool:
	return str(get_tree().get_meta("combat_mode", "local")) == "net"


# In rete l'incontro è quello dell'host, non quello selezionato qui.
func _result_encounter() -> EncounterData:
	if not _is_net():
		return CampaignState.get_current_encounter()

	var encounter_id: String = str(get_tree().get_meta("net_encounter_id", ""))

	for encounter: EncounterData in CampaignState.ENCOUNTER_FILES:
		if encounter.encounter_id == encounter_id:
			return encounter

	return null


func _show_result(result: String) -> void:
	var encounter: EncounterData = _result_encounter()

	var level_before: int = int(
		get_tree().get_meta(
			"combat_level_before",
			CampaignState.player_level
		)
	)
	var level_after: int = int(
		get_tree().get_meta(
			"combat_level_after",
			CampaignState.player_level
		)
	)

	if result == "defeat":
		result_label.text = "SCONFITTA"
		details_label.text = (
			"Il party è stato sconfitto.\n"
			+ "Nessuna ricompensa ottenuta.\n"
			+ "Puoi riprovare l'incontro."
		)
		continue_button.disabled = true
		return

	if level_after > level_before:
		result_label.text = "LEVEL UP!"
	else:
		result_label.text = "VITTORIA"

	if encounter != null:
		var rewards_claimed: bool = CampaignState.has_claimed_rewards(
			encounter.encounter_id
		)

		var level_up_text: String = ""
		if level_after > level_before:
			level_up_text = (
				"LEVEL UP! Livello "
				+ str(level_before)
				+ " → "
				+ str(level_after)
				+ "\n"
			)

		if rewards_claimed:
			details_label.text = (
				"Boss sconfitto!\n"
				+ level_up_text
				+ "EXP totale: " + str(CampaignState.player_exp) + "\n"
				+ "CREDITI totali: " + str(CampaignState.player_currency)
			)
		else:
			details_label.text = (
				"Boss sconfitto!\n"
				+ level_up_text
				+ "ATTENZIONE: ricompense non risultano riscosse.\n"
				+ "EXP prevista: " + str(encounter.reward_exp) + "\n"
				+ "CREDITI previsti: " + str(encounter.reward_currency)
			)

	if _is_net():
		continue_button.disabled = true
	elif CampaignState.has_next_encounter():
		continue_button.disabled = false
	else:
		details_label.text += "\nCampagna completata."
		continue_button.disabled = true


func _on_replay_pressed() -> void:
	var error := get_tree().change_scene_to_file(
		"res://scenes/combat/combat_demo.tscn"
	)

	if error != OK:
		push_error("Impossibile riavviare il combattimento. Codice: " + str(error))


func _on_continue_pressed() -> void:
	var result: String = str(get_tree().get_meta("combat_result", "victory"))

	if result != "victory":
		return

	if not CampaignState.advance_to_next_encounter():
		result_label.text = "CAMPAGNA COMPLETATA"
		details_label.text = "Hai completato tutti gli incontri disponibili."
		continue_button.disabled = true
		return

	var error := get_tree().change_scene_to_file(
		"res://scenes/combat/combat_demo.tscn"
	)

	if error != OK:
		push_error(
			"Impossibile avviare il prossimo incontro. Codice: "
			+ str(error)
		)

func _on_hub_pressed() -> void:
	if _is_net():
		NetSession.close()

	var error := get_tree().change_scene_to_file(
		"res://scenes/hub/hub_demo.tscn"
	)

	if error != OK:
		push_error(
			"Impossibile tornare all'hub. Codice: "
			+ str(error)
		)
