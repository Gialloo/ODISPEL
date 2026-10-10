
class_name EncounterData
extends Resource

@export var encounter_id: String = ""
@export var display_name: String = ""
@export var boss_max_hp: int = 1000
@export var reward_exp: int = 0
@export var reward_currency: int = 0


func is_valid() -> bool:
	return (
		not encounter_id.is_empty()
		and not display_name.is_empty()
		and boss_max_hp > 0
		and reward_exp >= 0
		and reward_currency >= 0
	)
