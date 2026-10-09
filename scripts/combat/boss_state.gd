
class_name BossState
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 10000
@export var hp: int = 10000
@export var is_alive: bool = true
@export var is_broken: bool = false


func setup(
	new_id: String,
	new_display_name: String,
	new_max_hp: int
) -> void:
	id = new_id
	display_name = new_display_name
	max_hp = maxi(1, new_max_hp)
	hp = max_hp
	is_alive = true
	is_broken = false


func take_damage(amount: int) -> int:
	if amount <= 0 or not is_alive:
		return 0

	var actual_damage: int = mini(amount, hp)
	hp -= actual_damage

	if hp <= 0:
		die()

	return actual_damage


func heal(amount: int) -> int:
	if amount <= 0 or not is_alive:
		return 0

	var previous_hp: int = hp
	hp = mini(hp + amount, max_hp)

	return hp - previous_hp


func break_boss() -> bool:
	if not is_alive or is_broken:
		return false

	is_broken = true
	return true


func recover_from_break() -> bool:
	if not is_alive or not is_broken:
		return false

	is_broken = false
	return true


func die() -> void:
	hp = 0
	is_alive = false
	is_broken = false


func get_hp_ratio() -> float:
	if max_hp <= 0:
		return 0.0

	return float(hp) / float(max_hp)


func is_defeated() -> bool:
	return not is_alive or hp <= 0


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"max_hp": max_hp,
		"hp": hp,
		"is_alive": is_alive,
		"is_broken": is_broken
	}


func apply_dictionary(data: Dictionary) -> void:
	id = str(data.get("id", ""))
	display_name = str(data.get("display_name", ""))

	max_hp = maxi(1, int(data.get("max_hp", 10000)))
	hp = clampi(int(data.get("hp", max_hp)), 0, max_hp)

	is_alive = bool(data.get("is_alive", hp > 0)) and hp > 0
	is_broken = bool(data.get("is_broken", false)) and is_alive


func is_valid() -> bool:
	return (
		not id.is_empty()
		and max_hp > 0
		and hp >= 0
		and hp <= max_hp
		and (is_alive == (hp > 0))
		and (not is_broken or is_alive)
	)


static func from_dictionary(data: Dictionary) -> BossState:
	var boss := BossState.new()
	boss.apply_dictionary(data)
	return boss
