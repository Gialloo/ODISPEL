
class_name RunState
extends Resource

@export var run_id: String = ""
@export var seed: int = 0
@export var encounter_index: int = 0
@export var map_node_id: String = ""
@export var temporary_level: int = 1


func setup(
	new_run_id: String,
	new_seed: int,
	starting_node_id: String = ""
) -> void:
	run_id = new_run_id
	seed = new_seed
	encounter_index = 0
	map_node_id = starting_node_id
	temporary_level = 1


func advance_encounter() -> void:
	encounter_index += 1


func set_map_node(new_node_id: String) -> bool:
	if new_node_id.is_empty():
		return false

	map_node_id = new_node_id
	return true


func increase_temporary_level(amount: int = 1) -> void:
	if amount <= 0:
		return

	temporary_level += amount


func is_valid() -> bool:
	return (
		not run_id.is_empty()
		and encounter_index >= 0
		and temporary_level >= 1
	)


func to_dictionary() -> Dictionary:
	return {
		"run_id": run_id,
		"seed": seed,
		"encounter_index": encounter_index,
		"map_node_id": map_node_id,
		"temporary_level": temporary_level
	}


func apply_dictionary(data: Dictionary) -> void:
	run_id = str(data.get("run_id", ""))
	seed = int(data.get("seed", 0))
	encounter_index = max(0, int(data.get("encounter_index", 0)))
	map_node_id = str(data.get("map_node_id", ""))
	temporary_level = max(1, int(data.get("temporary_level", 1)))


static func from_dictionary(data: Dictionary) -> RunState:
	var run := RunState.new()
	run.apply_dictionary(data)
	return run
