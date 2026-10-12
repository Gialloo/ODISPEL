extends Node

const ENCOUNTER_FILES: Array[EncounterData] = [
	preload("res://data/encounters/boss_test.tres"),
	preload("res://data/encounters/boss_02.tres"),
	preload("res://data/encounters/boss_03.tres")
]

var encounter_index: int = 0
var completed_encounter_ids: Array[String] = []

var player_exp: int = 0
var player_currency: int = 0
var player_level: int = 1
var claimed_reward_ids: Array[String] = []


func _ready() -> void:
	load_campaign()


func start_campaign() -> void:
	encounter_index = 0
	completed_encounter_ids.clear()
	player_exp = 0
	player_currency = 0
	player_level = 1
	claimed_reward_ids.clear()
	save_campaign()


func get_current_encounter() -> EncounterData:
	if encounter_index < 0 or encounter_index >= ENCOUNTER_FILES.size():
		return null

	return ENCOUNTER_FILES[encounter_index]


func has_next_encounter() -> bool:
	return encounter_index + 1 < ENCOUNTER_FILES.size()


func advance_to_next_encounter() -> bool:
	if not has_next_encounter():
		return false

	encounter_index += 1
	save_campaign()
	return true


func is_encounter_unlocked(encounter_id: String) -> bool:
	for i in range(ENCOUNTER_FILES.size()):
		var encounter: EncounterData = ENCOUNTER_FILES[i]

		if encounter.encounter_id != encounter_id:
			continue

		if i == 0:
			return true

		var previous_encounter: EncounterData = ENCOUNTER_FILES[i - 1]

		return is_encounter_completed(previous_encounter.encounter_id)

	return false


func select_encounter(encounter_id: String) -> bool:
	for i in range(ENCOUNTER_FILES.size()):
		var encounter: EncounterData = ENCOUNTER_FILES[i]

		if encounter.encounter_id == encounter_id:
			if not is_encounter_unlocked(encounter_id):
				return false

			encounter_index = i
			save_campaign()
			return true

	return false


func mark_encounter_completed(encounter_id: String) -> void:
	if encounter_id.is_empty() or not _encounter_exists(encounter_id):
		return

	if not completed_encounter_ids.has(encounter_id):
		completed_encounter_ids.append(encounter_id)
		save_campaign()


func claim_encounter_rewards(encounter_id: String) -> bool:
	var encounter: EncounterData = _get_encounter_by_id(encounter_id)

	if encounter == null or not encounter.is_valid():
		return false

	# La prima vittoria assegna la ricompensa completa.
	# Le vittorie successive assegnano il 20%.
	var first_completion: bool = not claimed_reward_ids.has(encounter_id)

	var exp_reward: int
	var currency_reward: int

	if first_completion:
		exp_reward = encounter.reward_exp
		currency_reward = encounter.reward_currency
	else:
		exp_reward = maxi(1, int(ceil(encounter.reward_exp * 0.2)))
		currency_reward = maxi(1, int(ceil(encounter.reward_currency * 0.2)))

	player_exp += exp_reward
	player_currency += currency_reward

	if first_completion:
		claimed_reward_ids.append(encounter_id)

	_update_player_level()
	save_campaign()

	return true

func is_encounter_completed(encounter_id: String) -> bool:
	return completed_encounter_ids.has(encounter_id)


func has_claimed_rewards(encounter_id: String) -> bool:
	return claimed_reward_ids.has(encounter_id)


func get_player_profile() -> Dictionary:
	return {
		"player_level": player_level,
		"player_exp": player_exp,
		"player_currency": player_currency,
		"exp_progress": get_exp_progress_in_level(),
		"exp_for_next_level": get_exp_for_next_level()
	}

func get_exp_for_next_level() -> int:
	return player_level * 100


func get_exp_progress_in_level() -> int:
	var exp_at_level_start: int = 0

	for level in range(1, player_level):
		exp_at_level_start += level * 100

	return player_exp - exp_at_level_start


func _update_player_level() -> void:
	player_level = 1
	var remaining_exp: int = player_exp

	while remaining_exp >= player_level * 100:
		remaining_exp -= player_level * 100
		player_level += 1


func save_campaign() -> void:
	var save_data: Dictionary = {
		"encounter_index": encounter_index,
		"completed_encounter_ids": completed_encounter_ids,
		"player_exp": player_exp,
		"player_currency": player_currency,
		"claimed_reward_ids": claimed_reward_ids
	}

	SaveManager.save_game(save_data)


func load_campaign() -> void:
	var save_data: Dictionary = SaveManager.load_game()

	if save_data.is_empty():
		encounter_index = 0
		completed_encounter_ids.clear()
		player_exp = 0
		player_currency = 0
		player_level = 1
		claimed_reward_ids.clear()
		return

	encounter_index = clampi(
		int(save_data.get("encounter_index", 0)),
		0,
		ENCOUNTER_FILES.size() - 1
	)

	completed_encounter_ids.clear()
	_load_valid_ids(
		save_data.get("completed_encounter_ids", []),
		completed_encounter_ids
	)

	var saved_exp: Variant = save_data.get("player_exp", 0)
	var saved_currency: Variant = save_data.get("player_currency", 0)

	if saved_exp is int or saved_exp is float:
		player_exp = maxi(0, int(saved_exp))
	else:
		player_exp = 0

	if saved_currency is int or saved_currency is float:
		player_currency = maxi(0, int(saved_currency))
	else:
		player_currency = 0

	_update_player_level()

	claimed_reward_ids.clear()
	_load_valid_ids(
		save_data.get("claimed_reward_ids", []),
		claimed_reward_ids
	)


func _load_valid_ids(saved_value: Variant, destination: Array[String]) -> void:
	if not saved_value is Array:
		return

	for saved_id in saved_value:
		var id: String = str(saved_id)

		if _encounter_exists(id) and not destination.has(id):
			destination.append(id)


func _get_encounter_by_id(encounter_id: String) -> EncounterData:
	for encounter in ENCOUNTER_FILES:
		if encounter.encounter_id == encounter_id:
			return encounter

	return null


func _encounter_exists(encounter_id: String) -> bool:
	return _get_encounter_by_id(encounter_id) != null
