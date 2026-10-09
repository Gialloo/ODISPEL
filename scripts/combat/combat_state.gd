
class_name CombatState
extends Resource

enum Phase {
	NONE,
	PLANNING,
	LOCKED,
	RESOLUTION,
	BOSS_REACTION,
	STATUS_UPDATE,
	ENDED
}

@export var phase: Phase = Phase.NONE
@export var team_gauge: int = 0
@export var max_team_gauge: int = 100
@export var boss_reaction_target_id: String = ""

var round_state: RoundState = null
var boss: BossState = null
var rng: RNGState = null


func setup(
	boss_id: String,
	boss_name: String,
	boss_hp: int,
	run_seed: int
) -> void:
	phase = Phase.NONE
	team_gauge = 0
	max_team_gauge = 100
	boss_reaction_target_id = ""

	round_state = RoundState.new()
	round_state.setup(1, 30.0, 5.0)

	boss = BossState.new()
	boss.setup(boss_id, boss_name, boss_hp)

	rng = RNGState.new()
	rng.setup(run_seed)


func begin_combat() -> bool:
	if boss == null or not boss.is_alive:
		return false

	if round_state == null:
		round_state = RoundState.new()
		round_state.setup()

	phase = Phase.PLANNING
	round_state.begin()
	return true


func begin_round() -> bool:
	if is_finished():
		return false

	if round_state == null:
		round_state = RoundState.new()
		round_state.setup()

	phase = Phase.PLANNING
	round_state.begin()
	boss_reaction_target_id = ""
	return true


func lock_round() -> bool:
	if phase != Phase.PLANNING:
		return false

	phase = Phase.LOCKED
	return true


func begin_resolution() -> bool:
	if phase != Phase.LOCKED:
		return false

	phase = Phase.RESOLUTION
	return true


func begin_boss_reaction(target_player_id: String) -> bool:
	if phase != Phase.RESOLUTION:
		return false

	if target_player_id.is_empty():
		return false

	phase = Phase.BOSS_REACTION
	boss_reaction_target_id = target_player_id

	if round_state != null:
		round_state.begin_reaction()

	return true


func begin_status_update() -> bool:
	if (
		phase != Phase.RESOLUTION
		and phase != Phase.BOSS_REACTION
	):
		return false

	phase = Phase.STATUS_UPDATE
	boss_reaction_target_id = ""
	return true


func end_combat() -> void:
	phase = Phase.ENDED
	boss_reaction_target_id = ""


func update_planning_timer(delta: float) -> void:
	if phase != Phase.PLANNING or round_state == null:
		return

	round_state.update_planning_timer(delta)


func update_reaction_timer(delta: float) -> void:
	if phase != Phase.BOSS_REACTION or round_state == null:
		return

	round_state.update_reaction_timer(delta)


func add_team_gauge(amount: int) -> int:
	if amount <= 0:
		return 0

	var previous_gauge: int = team_gauge
	team_gauge = mini(team_gauge + amount, max_team_gauge)

	return team_gauge - previous_gauge


func spend_team_gauge(amount: int) -> bool:
	if amount < 0 or team_gauge < amount:
		return false

	team_gauge -= amount
	return true


func is_boss_alive() -> bool:
	return boss != null and boss.is_alive


func is_finished() -> bool:
	return (
		phase == Phase.ENDED
		or (boss != null and not boss.is_alive)
	)


func reaction_finished() -> bool:
	return (
		round_state == null
		or round_state.is_reaction_finished()
	)


func get_random_int(min_value: int, max_value: int) -> int:
	if rng == null:
		rng = RNGState.new()
		rng.setup(1)

	return rng.random_int(min_value, max_value)


func get_random_index(array_size: int) -> int:
	if rng == null:
		rng = RNGState.new()
		rng.setup(1)

	return rng.random_index(array_size)


func to_dictionary() -> Dictionary:
	return {
		"phase": int(phase),
		"team_gauge": team_gauge,
		"max_team_gauge": max_team_gauge,
		"boss_reaction_target_id": boss_reaction_target_id,
		"round_state": (
			round_state.to_dictionary()
			if round_state != null
			else {}
		),
		"boss": (
			boss.to_dictionary()
			if boss != null
			else {}
		),
		"rng": (
			rng.to_dictionary()
			if rng != null
			else {}
		)
	}


func apply_dictionary(data: Dictionary) -> void:
	phase = int(data.get("phase", Phase.NONE)) as Phase
	team_gauge = clampi(int(data.get("team_gauge", 0)), 0, 100)
	max_team_gauge = maxi(1, int(data.get("max_team_gauge", 100)))
	team_gauge = mini(team_gauge, max_team_gauge)
	boss_reaction_target_id = str(
		data.get("boss_reaction_target_id", "")
	)

	var round_data: Dictionary = data.get("round_state", {})
	if not round_data.is_empty():
		if round_state == null:
			round_state = RoundState.new()
		round_state.apply_dictionary(round_data)
	else:
		round_state = null

	var boss_data: Dictionary = data.get("boss", {})
	if not boss_data.is_empty():
		if boss == null:
			boss = BossState.new()
		boss.apply_dictionary(boss_data)
	else:
		boss = null

	var rng_data: Dictionary = data.get("rng", {})
	if not rng_data.is_empty():
		if rng == null:
			rng = RNGState.new()
		rng.apply_dictionary(rng_data)
	else:
		rng = null


func is_valid() -> bool:
	if int(phase) < int(Phase.NONE) or int(phase) > int(Phase.ENDED):
		return false

	if max_team_gauge <= 0:
		return false

	if team_gauge < 0 or team_gauge > max_team_gauge:
		return false

	if round_state != null and not round_state.is_valid():
		return false

	if boss != null and not boss.is_valid():
		return false

	return true


static func from_dictionary(data: Dictionary) -> CombatState:
	var combat_state := CombatState.new()
	combat_state.apply_dictionary(data)
	return combat_state
