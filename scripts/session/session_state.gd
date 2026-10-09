
class_name SessionState
extends Resource

@export var session_id: String = ""
@export var owner_peer_id: int = 0
@export var authority_peer_id: int = 0
@export var authority_epoch: int = 0


func setup(
	new_session_id: String,
	new_owner_peer_id: int,
	new_authority_peer_id: int
) -> void:
	session_id = new_session_id
	owner_peer_id = new_owner_peer_id
	authority_peer_id = new_authority_peer_id
	authority_epoch = 0


func change_authority(new_authority_peer_id: int) -> bool:
	if new_authority_peer_id <= 0:
		return false

	if new_authority_peer_id == authority_peer_id:
		return false

	authority_peer_id = new_authority_peer_id
	authority_epoch += 1
	return true


func is_authority(peer_id: int) -> bool:
	return peer_id > 0 and peer_id == authority_peer_id


func is_owner(peer_id: int) -> bool:
	return peer_id > 0 and peer_id == owner_peer_id


func is_valid() -> bool:
	return (
		not session_id.is_empty()
		and owner_peer_id > 0
		and authority_peer_id > 0
		and authority_epoch >= 0
	)


func to_dictionary() -> Dictionary:
	return {
		"session_id": session_id,
		"owner_peer_id": owner_peer_id,
		"authority_peer_id": authority_peer_id,
		"authority_epoch": authority_epoch
	}


func apply_dictionary(data: Dictionary) -> void:
	session_id = str(data.get("session_id", ""))
	owner_peer_id = int(data.get("owner_peer_id", 0))
	authority_peer_id = int(data.get("authority_peer_id", 0))
	authority_epoch = int(data.get("authority_epoch", 0))


static func from_dictionary(data: Dictionary) -> SessionState:
	var state := SessionState.new()
	state.apply_dictionary(data)
	return state
