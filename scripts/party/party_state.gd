
class_name PartyState
extends Resource

@export var party_id: String = ""
@export_range(2, 6) var max_players: int = 6

var slots: Array[PartySlot] = []


func setup(new_party_id: String, requested_max_players: int = 6) -> void:
	party_id = new_party_id
	max_players = clampi(requested_max_players, 2, 6)

	slots.clear()

	for index in range(max_players):
		var slot := PartySlot.new()
		slot.setup(index)
		slots.append(slot)


func get_slot(slot_index: int) -> PartySlot:
	if slot_index < 0 or slot_index >= slots.size():
		return null

	return slots[slot_index]


func get_slot_by_player_id(target_player_id: String) -> PartySlot:
	for slot in slots:
		if slot.occupied and slot.player_id == target_player_id:
			return slot

	return null


func get_slot_by_peer_id(target_peer_id: int) -> PartySlot:
	if target_peer_id <= 0:
		return null

	for slot in slots:
		if slot.occupied and slot.peer_id == target_peer_id:
			return slot

	return null


func get_player_by_id(target_player_id: String) -> PlayerState:
	var slot := get_slot_by_player_id(target_player_id)

	if slot == null:
		return null

	return slot.player


func get_player_by_peer_id(target_peer_id: int) -> PlayerState:
	var slot := get_slot_by_peer_id(target_peer_id)

	if slot == null:
		return null

	return slot.player


func add_player(player: PlayerState) -> bool:
	if player == null or player.id.is_empty():
		return false

	if get_slot_by_player_id(player.id) != null:
		return false

	if player.network_peer_id > 0:
		if get_slot_by_peer_id(player.network_peer_id) != null:
			return false

	for slot in slots:
		if not slot.occupied:
			return slot.assign_player(player)

	return false


func remove_player(target_player_id: String) -> bool:
	var slot := get_slot_by_player_id(target_player_id)

	if slot == null:
		return false

	slot.clear()
	return true


func disconnect_player(target_player_id: String) -> bool:
	var slot := get_slot_by_player_id(target_player_id)

	if slot == null:
		return false

	return slot.disconnect_player()


func reconnect_player(
	target_player_id: String,
	new_peer_id: int
) -> bool:
	if new_peer_id <= 0:
		return false

	if get_slot_by_peer_id(new_peer_id) != null:
		return false

	var slot := get_slot_by_player_id(target_player_id)

	if slot == null:
		return false

	return slot.reconnect_player(new_peer_id)


func set_player_ready(
	target_player_id: String,
	ready_value: bool
) -> bool:
	var slot := get_slot_by_player_id(target_player_id)

	if slot == null:
		return false

	return slot.set_ready(ready_value)


func set_player_ai(
	target_player_id: String,
	ai_enabled: bool
) -> bool:
	var slot := get_slot_by_player_id(target_player_id)

	if slot == null or slot.player == null:
		return false

	if ai_enabled:
		if slot.player.connected:
			slot.player.disconnect_player()

		slot.peer_id = 0
		slot.connected = false
		slot.controlled_by_ai = true
		slot.is_human = false
		slot.is_ready = false
		return true

	if not slot.player.connected:
		return false

	slot.controlled_by_ai = false
	slot.is_human = true
	return true


func get_players() -> Array[PlayerState]:
	var result: Array[PlayerState] = []

	for slot in slots:
		if slot.occupied and slot.player != null:
			result.append(slot.player)

	return result


func get_connected_players() -> Array[PlayerState]:
	var result: Array[PlayerState] = []

	for slot in slots:
		if (
			slot.occupied
			and slot.player != null
			and slot.connected
			and not slot.controlled_by_ai
		):
			result.append(slot.player)

	return result


func get_living_players() -> Array[PlayerState]:
	var result: Array[PlayerState] = []

	for slot in slots:
		if (
			slot.occupied
			and slot.player != null
			and slot.player.is_alive
		):
			result.append(slot.player)

	return result


func get_occupied_count() -> int:
	var count := 0

	for slot in slots:
		if slot.occupied:
			count += 1

	return count


func get_connected_count() -> int:
	return get_connected_players().size()


func get_ready_count() -> int:
	var count := 0

	for slot in slots:
		if slot.occupied and slot.is_ready:
			count += 1

	return count


func can_start() -> bool:
	if get_occupied_count() < 2:
		return false

	for slot in slots:
		if not slot.occupied:
			continue

		if not slot.connected or slot.controlled_by_ai:
			return false

		if not slot.is_ready:
			return false

	return true


func to_dictionary() -> Dictionary:
	var serialized_slots: Array[Dictionary] = []

	for slot in slots:
		serialized_slots.append(slot.to_dictionary())

	return {
		"party_id": party_id,
		"max_players": max_players,
		"slots": serialized_slots
	}


func apply_dictionary(data: Dictionary) -> void:
	party_id = str(data.get("party_id", ""))
	max_players = clampi(int(data.get("max_players", 6)), 2, 6)

	slots.clear()

	var serialized_slots: Array = data.get("slots", [])

	for index in range(max_players):
		var slot := PartySlot.new()

		if index < serialized_slots.size():
			var slot_data: Dictionary = serialized_slots[index]
			slot.apply_dictionary(slot_data)
		else:
			slot.setup(index)

		slots.append(slot)


func relink_players(players: Array[PlayerState]) -> void:
	var players_by_id: Dictionary = {}

	for player in players:
		if player != null and not player.id.is_empty():
			players_by_id[player.id] = player

	for slot in slots:
		slot.player = null

		if not slot.occupied:
			continue

		if players_by_id.has(slot.player_id):
			var player: PlayerState = players_by_id[slot.player_id]
			slot.player = player

			# Ripristina i dati dello slot dal modello giocatore.
			slot.peer_id = player.network_peer_id
			slot.connected = player.connected
			slot.controlled_by_ai = player.controlled_by_ai
			slot.is_human = not player.controlled_by_ai
			slot.is_ready = player.is_ready


func is_valid() -> bool:
	if party_id.is_empty():
		return false

	if max_players < 2 or max_players > 6:
		return false

	if slots.size() != max_players:
		return false

	var seen_player_ids: Dictionary = {}
	var seen_peer_ids: Dictionary = {}

	for index in range(slots.size()):
		var slot: PartySlot = slots[index]

		if slot == null or slot.slot_index != index:
			return false

		if not slot.is_valid():
			return false

		if not slot.occupied:
			continue

		if seen_player_ids.has(slot.player_id):
			return false

		seen_player_ids[slot.player_id] = true

		if slot.peer_id > 0:
			if seen_peer_ids.has(slot.peer_id):
				return false

			seen_peer_ids[slot.peer_id] = true

	return true


static func from_dictionary(data: Dictionary) -> PartyState:
	var party := PartyState.new()
	party.apply_dictionary(data)
	return party
