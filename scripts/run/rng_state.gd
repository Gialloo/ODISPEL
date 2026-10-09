
class_name RNGState
extends Resource

@export var seed_value: int = 1
@export var state_value: int = 0

var generator: RandomNumberGenerator = null


func setup(new_seed: int) -> void:
	seed_value = new_seed
	generator = RandomNumberGenerator.new()
	generator.seed = seed_value
	sync_state()


func restore() -> void:
	if generator == null:
		generator = RandomNumberGenerator.new()
		generator.seed = seed_value

	generator.state = state_value


func sync_state() -> void:
	if generator == null:
		return

	state_value = generator.state


func reset() -> void:
	generator = RandomNumberGenerator.new()
	generator.seed = seed_value
	sync_state()


func random_int(min_value: int, max_value: int) -> int:
	if min_value > max_value:
		return min_value

	if generator == null:
		reset()

	var result: int = generator.randi_range(min_value, max_value)
	sync_state()
	return result


func random_float(min_value: float, max_value: float) -> float:
	if min_value > max_value:
		return min_value

	if generator == null:
		reset()

	var result: float = generator.randf_range(min_value, max_value)
	sync_state()
	return result


func random_index(array_size: int) -> int:
	if array_size <= 0:
		return -1

	return random_int(0, array_size - 1)


func to_dictionary() -> Dictionary:
	if generator != null:
		sync_state()

	return {
		"seed_value": seed_value,
		"state_value": state_value
	}


func apply_dictionary(data: Dictionary) -> void:
	seed_value = int(data.get("seed_value", 1))
	state_value = int(data.get("state_value", 0))

	generator = RandomNumberGenerator.new()
	generator.seed = seed_value

	if state_value != 0:
		generator.state = state_value
	else:
		# Uno stato nullo indica che il generatore deve ripartire
		# dalla seed iniziale.
		generator.seed = seed_value

	sync_state()


func is_valid() -> bool:
	return seed_value != 0 and state_value != 0


static func from_dictionary(data: Dictionary) -> RNGState:
	var rng_state := RNGState.new()
	rng_state.apply_dictionary(data)
	return rng_state
