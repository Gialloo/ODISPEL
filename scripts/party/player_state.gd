
class_name PlayerState
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var network_peer_id: int = 0

@export var controlled_by_ai: bool = false
@export var connected: bool = true
@export var is_ready: bool = false

@export var max_hp: int = 1000
@export var hp: int = 1000
@export var max_energy: int = 100
@export var energy: int = 100

# Decisione del turno
var selected_action: Resource = null
var selected_action_id: String = ""
var current_surety: float = 0.0
var decision_time: float = 0.0
var action_was_automatic: bool = false
var is_thinking: bool = false
var is_locked: bool = false

# Assist
var assist_target: PlayerState = null
var assist_target_id: String = ""
var is_assisting: bool = false
var assist_power_bonus: float = 0.0

# Reazione agli attacchi dei boss
var selected_reaction: Resource = null
var selected_reaction_id: String = ""
var reaction_locked: bool = false
var is_guarding: bool = false

var is_alive: bool = true


func setup(
	new_id: String,
	new_display_name: String,
	new_peer_id: int
) -> void:
	id = new_id
	display_name = new_display_name
	network_peer_id = new_peer_id

	controlled_by_ai = false
	connected = true
	is_ready = false

	hp = max_hp
	energy = max_energy
	is_alive = hp > 0


func take_damage(amount: int) -> int:
	if amount <= 0 or not is_alive:
		return 0

	var actual_damage: int = min(amount, hp)
	hp -= actual_damage

	if hp <= 0:
		die()

	return actual_damage


func heal(amount: int) -> int:
	if amount <= 0 or not is_alive:
		return 0

	var previous_hp: int = hp
	hp = min(hp + amount, max_hp)

	return hp - previous_hp


func spend_energy(amount: int) -> bool:
	if amount < 0 or energy < amount:
		return false

	energy -= amount
	return true


func restore_energy(amount: int) -> int:
	if amount <= 0 or not is_alive:
		return 0

	var previous_energy: int = energy
	energy = min(energy + amount, max_energy)

	return energy - previous_energy


func die() -> void:
	hp = 0
	is_alive = false
	is_locked = true
	reaction_locked = true


func disconnect_player() -> void:
	connected = false
	controlled_by_ai = true
	network_peer_id = 0


func reconnect_player(new_peer_id: int) -> bool:
	if new_peer_id <= 0:
		return false

	network_peer_id = new_peer_id
	connected = true
	controlled_by_ai = false

	return true


func can_act() -> bool:
	return is_alive and not is_locked


func can_react() -> bool:
	return is_alive and not reaction_locked


func has_energy(amount: int) -> bool:
	return amount >= 0 and energy >= amount


func get_control_type() -> String:
	if controlled_by_ai:
		return "AI"

	if connected:
		return "HUMAN"

	return "DISCONNECTED"


func reset_round_decision() -> void:
	selected_action = null
	selected_action_id = ""
	current_surety = 0.0
	decision_time = 0.0
	action_was_automatic = false
	is_thinking = false
	is_locked = false

	assist_target = null
	assist_target_id = ""
	is_assisting = false
	assist_power_bonus = 0.0

	selected_reaction = null
	selected_reaction_id = ""
	reaction_locked = false
	is_guarding = false


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"network_peer_id": network_peer_id,
		"controlled_by_ai": controlled_by_ai,
		"connected": connected,
		"is_ready": is_ready,
		"max_hp": max_hp,
		"hp": hp,
		"max_energy": max_energy,
		"energy": energy,
		"selected_action_id": selected_action_id,
		"current_surety": current_surety,
		"decision_time": decision_time,
		"action_was_automatic": action_was_automatic,
		"is_thinking": is_thinking,
		"is_locked": is_locked,
		"assist_target_id": assist_target_id,
		"is_assisting": is_assisting,
		"assist_power_bonus": assist_power_bonus,
		"selected_reaction_id": selected_reaction_id,
		"reaction_locked": reaction_locked,
		"is_guarding": is_guarding,
		"is_alive": is_alive
	}


func apply_dictionary(data: Dictionary) -> void:
	id = str(data.get("id", ""))
	display_name = str(data.get("display_name", ""))
	network_peer_id = int(data.get("network_peer_id", 0))

	controlled_by_ai = bool(data.get("controlled_by_ai", false))
	connected = bool(data.get("connected", true))
	is_ready = bool(data.get("is_ready", false))

	max_hp = max(1, int(data.get("max_hp", 1000)))
	hp = clampi(int(data.get("hp", max_hp)), 0, max_hp)
	max_energy = max(0, int(data.get("max_energy", 100)))
	energy = clampi(int(data.get("energy", max_energy)), 0, max_energy)

	selected_action = null
	selected_action_id = str(data.get("selected_action_id", ""))
	current_surety = clampf(float(data.get("current_surety", 0.0)), -1.0, 1.0)
	decision_time = maxf(0.0, float(data.get("decision_time", 0.0)))
	action_was_automatic = bool(data.get("action_was_automatic", false))
	is_thinking = bool(data.get("is_thinking", false))
	is_locked = bool(data.get("is_locked", false))

	assist_target = null
	assist_target_id = str(data.get("assist_target_id", ""))
	is_assisting = bool(data.get("is_assisting", false))
	assist_power_bonus = maxf(0.0, float(data.get("assist_power_bonus", 0.0)))

	selected_reaction = null
	selected_reaction_id = str(data.get("selected_reaction_id", ""))
	reaction_locked = bool(data.get("reaction_locked", false))
	is_guarding = bool(data.get("is_guarding", false))

	is_alive = bool(data.get("is_alive", hp > 0)) and hp > 0


static func from_dictionary(data: Dictionary) -> PlayerState:
	var player := PlayerState.new()
	player.apply_dictionary(data)
	return player
