
class_name GameState
extends Resource

var session: SessionState = null
var party: PartyState = null
var run: RunState = null
var combat: CombatState = null


func setup(
	session_id: String,
	owner_peer_id: int,
	authority_peer_id: int,
	max_players: int = 6
) -> void:
	session = SessionState.new()
	session.setup(session_id, owner_peer_id, authority_peer_id)

	party = PartyState.new()
	party.setup(session_id + "_party", max_players)

	run = null
	combat = null


func setup_run(
	run_id: String,
	run_seed: int,
	starting_node_id: String = ""
) -> bool:
	if run_id.is_empty():
		return false

	if session == null or party == null:
		return false

	run = RunState.new()
	run.setup(run_id, run_seed, starting_node_id)

	combat = null
	return true


func clear_run() -> void:
	combat = null
	run = null


func begin_combat(
	boss_id: String,
	boss_name: String,
	boss_hp: int
) -> bool:
	if run == null or not run.is_valid():
		return false

	if boss_id.is_empty() or boss_hp <= 0:
		return false

	if combat != null and not combat.is_finished():
		return false

	combat = CombatState.new()
	combat.setup(
		boss_id,
		boss_name,
		boss_hp,
		run.seed
	)

	return combat.begin_combat()


func end_combat() -> void:
	if combat == null:
		return

	combat.end_combat()


func clear_combat() -> void:
	combat = null


func is_valid() -> bool:
	if session == null or not session.is_valid():
		return false

	if party == null or not party.is_valid():
		return false

	if run != null and not run.is_valid():
		return false

	if combat != null and not combat.is_valid():
		return false

	return true


func to_dictionary() -> Dictionary:
	return {
		"session": (
			session.to_dictionary()
			if session != null
			else {}
		),
		"party": (
			party.to_dictionary()
			if party != null
			else {}
		),
		"run": (
			run.to_dictionary()
			if run != null
			else {}
		),
		"combat": (
			combat.to_dictionary()
			if combat != null
			else {}
		)
	}


func apply_dictionary(data: Dictionary) -> void:
	var session_data: Dictionary = data.get("session", {})
	if not session_data.is_empty():
		if session == null:
			session = SessionState.new()
		session.apply_dictionary(session_data)
	else:
		session = null

	var party_data: Dictionary = data.get("party", {})
	if not party_data.is_empty():
		if party == null:
			party = PartyState.new()
		party.apply_dictionary(party_data)
	else:
		party = null

	var run_data: Dictionary = data.get("run", {})
	if not run_data.is_empty():
		if run == null:
			run = RunState.new()
		run.apply_dictionary(run_data)
	else:
		run = null

	var combat_data: Dictionary = data.get("combat", {})
	if not combat_data.is_empty():
		if combat == null:
			combat = CombatState.new()
		combat.apply_dictionary(combat_data)
	else:
		combat = null


static func from_dictionary(data: Dictionary) -> GameState:
	var game_state := GameState.new()
	game_state.apply_dictionary(data)
	return game_state
