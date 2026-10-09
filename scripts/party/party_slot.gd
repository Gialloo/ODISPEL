
class_name PartySlot
extends Resource

@export var slot_index: int = -1
@export var occupied: bool = false
@export var peer_id: int = 0
@export var is_human: bool = false
@export var is_ready: bool = false
@export var connected: bool = false
@export var controlled_by_ai: bool = false

var player: PlayerState = null
var player_id: String = ""


func setup(new_slot_index: int) -> void:
	slot_index = new_slot_index
	clear()


func assign_player(new_player: PlayerState) -> bool:
	if new_player == null or slot_index < 0:
		return false

	player = new_player
	player_id = new_player.id
	peer_id = new_player.network_peer_id

	occupied = true
	is_human = not new_player.controlled_by_ai
	is_ready = new_player.is_ready
	connected = new_player.connected
	controlled_by_ai = new_player.controlled_by_ai

	return true


func clear() -> void:
	occupied = false
	peer_id = 0
	is_human = false
	is_ready = false
	connected = false
	controlled_by_ai = false

	player = null
	player_id = ""


func disconnect_player() -> bool:
	if not occupied or player == null:
		return false

	player.disconnect_player()

	peer_id = 0
	connected = false
	controlled_by_ai = true
	is_human = false
	is_ready = false

	return true


func reconnect_player(new_peer_id: int) -> bool:
	if not occupied or player == null:
		return false

	if not player.reconnect_player(new_peer_id):
		return false

	peer_id = new_peer_id
	connected = true
	controlled_by_ai = false
	is_human = true
	is_ready = player.is_ready

	return true


func set_ready(ready_value: bool) -> bool:
	if not occupied or not connected or controlled_by_ai:
		return false

	is_ready = ready_value

	if player != null:
		player.is_ready = ready_value

	return true


func to_dictionary() -> Dictionary:
	return {
		"slot_index": slot_index,
		"occupied": occupied,
		"peer_id": peer_id,
		"is_human": is_human,
		"is_ready": is_ready,
		"connected": connected,
		"controlled_by_ai": controlled_by_ai,
		"player_id": player_id
	}


func apply_dictionary(data: Dictionary) -> void:
	slot_index = int(data.get("slot_index", -1))
	occupied = bool(data.get("occupied", false))
	peer_id = int(data.get("peer_id", 0))
	is_human = bool(data.get("is_human", false))
	is_ready = bool(data.get("is_ready", false))
	connected = bool(data.get("connected", false))
	controlled_by_ai = bool(data.get("controlled_by_ai", false))
	player_id = str(data.get("player_id", ""))

	# Il riferimento viene ricollegato da PartyState.
	player = null


func is_valid() -> bool:
	if slot_index < 0:
		return false

	if not occupied:
		return (
			player == null
			and player_id.is_empty()
			and peer_id == 0
		)

	return (
		not player_id.is_empty()
		and (
			controlled_by_ai
			or peer_id > 0
		)
	)


static func from_dictionary(data: Dictionary) -> PartySlot:
	var slot := PartySlot.new()
	slot.apply_dictionary(data)
	return slot
