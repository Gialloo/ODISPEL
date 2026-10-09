
class_name NetworkIdentity
extends Resource

@export var peer_id: int = 0
@export var player_id: String = ""


func setup(new_peer_id: int, new_player_id: String) -> void:
	peer_id = new_peer_id
	player_id = new_player_id


func is_valid() -> bool:
	return peer_id > 0


func has_player() -> bool:
	return not player_id.is_empty()


func to_dictionary() -> Dictionary:
	return {
		"peer_id": peer_id,
		"player_id": player_id
	}


func apply_dictionary(data: Dictionary) -> void:
	peer_id = int(data.get("peer_id", 0))
	player_id = str(data.get("player_id", ""))


static func from_dictionary(data: Dictionary) -> NetworkIdentity:
	var identity := NetworkIdentity.new()
	identity.apply_dictionary(data)
	return identity
