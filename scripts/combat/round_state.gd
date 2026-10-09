
class_name RoundState
extends Resource

@export var number: int = 0
@export var planning_time: float = 30.0
@export var time_remaining: float = 30.0
@export var reaction_time: float = 5.0
@export var reaction_time_remaining: float = 5.0


func setup(
	round_number: int = 1,
	planning_duration: float = 30.0,
	reaction_duration: float = 5.0
) -> void:
	number = maxi(1, round_number)
	planning_time = maxf(0.1, planning_duration)
	time_remaining = planning_time
	reaction_time = maxf(0.1, reaction_duration)
	reaction_time_remaining = reaction_time


func begin() -> void:
	time_remaining = planning_time


func update_planning_timer(delta: float) -> void:
	if delta <= 0.0:
		return

	time_remaining = maxf(0.0, time_remaining - delta)


func begin_reaction() -> void:
	reaction_time_remaining = reaction_time


func update_reaction_timer(delta: float) -> void:
	if delta <= 0.0:
		return

	reaction_time_remaining = maxf(
		0.0,
		reaction_time_remaining - delta
	)


func is_planning_finished() -> bool:
	return time_remaining <= 0.0


func is_reaction_finished() -> bool:
	return reaction_time_remaining <= 0.0


func advance() -> void:
	number += 1
	begin()


func to_dictionary() -> Dictionary:
	return {
		"number": number,
		"planning_time": planning_time,
		"time_remaining": time_remaining,
		"reaction_time": reaction_time,
		"reaction_time_remaining": reaction_time_remaining
	}


func apply_dictionary(data: Dictionary) -> void:
	number = maxi(0, int(data.get("number", 0)))
	planning_time = maxf(
		0.1,
		float(data.get("planning_time", 30.0))
	)
	time_remaining = clampf(
		float(data.get("time_remaining", planning_time)),
		0.0,
		planning_time
	)
	reaction_time = maxf(
		0.1,
		float(data.get("reaction_time", 5.0))
	)
	reaction_time_remaining = clampf(
		float(data.get("reaction_time_remaining", reaction_time)),
		0.0,
		reaction_time
	)


func is_valid() -> bool:
	return (
		number >= 0
		and planning_time > 0.0
		and reaction_time > 0.0
		and time_remaining >= 0.0
		and time_remaining <= planning_time
		and reaction_time_remaining >= 0.0
		and reaction_time_remaining <= reaction_time
	)


static func from_dictionary(data: Dictionary) -> RoundState:
	var round_state := RoundState.new()
	round_state.apply_dictionary(data)
	return round_state
