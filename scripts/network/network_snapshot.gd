
class_name NetworkSnapshot
extends Resource

# Identificativo progressivo dell'evento incluso nello snapshot.
@export var event_id: int = 0

# Generazione dell'autorità che ha prodotto lo snapshot.
@export var authority_epoch: int = 0

# Stato serializzato della partita.
var state_data: Dictionary = {}


func create_from_game_state(
	game_state: GameState,
	new_event_id: int
) -> bool:
	if game_state == null:
		return false

	if not game_state.is_valid():
		return false

	if new_event_id < 0:
		return false

	event_id = new_event_id
	authority_epoch = game_state.session.authority_epoch
	state_data = game_state.to_dictionary().duplicate(true)

	return is_valid()


func apply_to_game_state(target_state: GameState) -> bool:
	if target_state == null or not is_valid():
		return false

	# Non consentire il ritorno a una generazione di autorità precedente.
	if target_state.session != null:
		if authority_epoch < target_state.session.authority_epoch:
			return false

	# Controlla lo snapshot prima di modificare lo stato di destinazione.
	var candidate: GameState = GameState.from_dictionary(state_data)

	if not candidate.is_valid():
		return false

	target_state.apply_dictionary(state_data)

	return target_state.is_valid()


func to_dictionary() -> Dictionary:
	return {
		"event_id": event_id,
		"authority_epoch": authority_epoch,
		"state_data": state_data.duplicate(true)
	}


func apply_dictionary(data: Dictionary) -> void:
	event_id = int(data.get("event_id", 0))
	authority_epoch = int(data.get("authority_epoch", 0))

	var received_state: Variant = data.get("state_data", {})

	if received_state is Dictionary:
		state_data = received_state.duplicate(true)
	else:
		state_data = {}


func is_valid() -> bool:
	if event_id < 0 or authority_epoch < 0:
		return false

	if state_data.is_empty():
		return false

	var session_data: Variant = state_data.get("session", {})

	if not session_data is Dictionary:
		return false

	if session_data.is_empty():
		return false

	return (
		int(session_data.get("authority_epoch", -1))
		== authority_epoch
	)


static func from_dictionary(data: Dictionary) -> NetworkSnapshot:
	var snapshot := NetworkSnapshot.new()
	snapshot.apply_dictionary(data)
	return snapshot
