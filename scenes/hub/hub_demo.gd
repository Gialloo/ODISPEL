
extends Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Tornando all'hub si chiude sempre l'eventuale sessione di rete.
	NetSession.close()

	_build_interface()


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
	layout.custom_minimum_size = Vector2(460, 500)
	layout.add_theme_constant_override("separation", 12)
	center.add_child(layout)

	var title := Label.new()
	title.text = "ODISPEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "MISSION CONTROL"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	layout.add_child(subtitle)

	var version_label := Label.new()
	version_label.text = "v" + GameConfig.VERSION
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.modulate = Color(1, 1, 1, 0.5)
	layout.add_child(version_label)

	var description := Label.new()
	description.text = "Seleziona una missione da affrontare."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(description)

	var separator := HSeparator.new()
	layout.add_child(separator)

	# PROFILO GIOCATORE
	var profile: Dictionary = CampaignState.get_player_profile()

	var profile_panel := PanelContainer.new()
	profile_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#1b1c29")
	panel_style.border_color = Color("#7439a6")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 16.0
	panel_style.content_margin_right = 16.0
	panel_style.content_margin_top = 10.0
	panel_style.content_margin_bottom = 10.0
	profile_panel.add_theme_stylebox_override("panel", panel_style)
	layout.add_child(profile_panel)

	var profile_layout := VBoxContainer.new()
	profile_layout.add_theme_constant_override("separation", 6)
	profile_panel.add_child(profile_layout)

	var profile_title := Label.new()
	profile_title.text = "PROFILO GIOCATORE"
	profile_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profile_title.add_theme_font_size_override("font_size", 18)
	profile_layout.add_child(profile_title)

	var level_label := Label.new()
	level_label.text = "LIVELLO " + str(profile["player_level"])
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 26)
	profile_layout.add_child(level_label)

	var exp_label := Label.new()
	exp_label.text = (
		"ESPERIENZA  "
		+ str(profile["exp_progress"])
		+ " / "
		+ str(profile["exp_for_next_level"])
		+ " EXP"
	)
	exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profile_layout.add_child(exp_label)

	var exp_bar := ProgressBar.new()
	exp_bar.min_value = 0
	exp_bar.max_value = max(1, int(profile["exp_for_next_level"]))
	exp_bar.value = int(profile["exp_progress"])
	exp_bar.show_percentage = false
	exp_bar.custom_minimum_size.y = 18
	profile_layout.add_child(exp_bar)

	var total_exp_label := Label.new()
	total_exp_label.text = "EXP TOTALE: " + str(profile["player_exp"])
	total_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_exp_label.add_theme_font_size_override("font_size", 12)
	profile_layout.add_child(total_exp_label)

	var currency_label := Label.new()
	currency_label.text = "MONETE: " + str(profile["player_currency"])
	currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	currency_label.add_theme_font_size_override("font_size", 16)
	profile_layout.add_child(currency_label)

	separator = HSeparator.new()
	layout.add_child(separator)

	# ELENCO MISSIONI
	for encounter in CampaignState.ENCOUNTER_FILES:
		var mission_button := Button.new()

		var is_completed: bool = CampaignState.is_encounter_completed(
			encounter.encounter_id
		)

		var is_unlocked: bool = CampaignState.is_encounter_unlocked(
			encounter.encounter_id
		)

		var mission_status: String

		if is_completed:
			mission_status = "COMPLETATA"
		elif is_unlocked:
			mission_status = "DISPONIBILE"
		else:
			mission_status = "BLOCCATA"

		mission_button.text = (
			mission_status
			+ "  |  "
			+ encounter.display_name
			+ "  |  HP Boss: "
			+ str(encounter.boss_max_hp)
		)

		mission_button.custom_minimum_size = Vector2(0, 46)
		mission_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mission_button.disabled = not is_unlocked

		mission_button.pressed.connect(
			_on_mission_pressed.bind(encounter.encounter_id)
		)

		layout.add_child(mission_button)

	separator = HSeparator.new()
	layout.add_child(separator)

	var battle_button := Button.new()
	battle_button.text = "NUOVO COMBATTIMENTO (SOLO)"
	battle_button.custom_minimum_size = Vector2(0, 46)
	battle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_button.pressed.connect(_on_new_battle_pressed)
	layout.add_child(battle_button)

	var multiplayer_button := Button.new()
	multiplayer_button.text = "MULTIPLAYER CO-OP"
	multiplayer_button.custom_minimum_size = Vector2(0, 46)
	multiplayer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	multiplayer_button.pressed.connect(_on_multiplayer_pressed)
	layout.add_child(multiplayer_button)


func _on_new_battle_pressed() -> void:
	var error := get_tree().change_scene_to_file(
		"res://scenes/battle/battle_screen.tscn"
	)

	if error != OK:
		push_error("Impossibile aprire la battaglia. Codice: " + str(error))


func _on_multiplayer_pressed() -> void:
	var error := get_tree().change_scene_to_file(
		"res://scenes/lobby/lobby_demo.tscn"
	)

	if error != OK:
		push_error("Impossibile aprire la lobby. Codice: " + str(error))


func _on_mission_pressed(encounter_id: String) -> void:
	if not CampaignState.select_encounter(encounter_id):
		push_error("Impossibile selezionare la missione: " + encounter_id)
		return

	var error := get_tree().change_scene_to_file(
		"res://scenes/combat/combat_demo.tscn"
	)

	if error != OK:
		push_error(
			"Impossibile avviare la missione. Codice: " + str(error)
		)
