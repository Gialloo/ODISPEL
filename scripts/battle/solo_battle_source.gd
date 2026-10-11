class_name SoloBattleSource
extends RefCounted

# Sorgente di una battaglia in solitaria: stessa interfaccia che l'interfaccia
# usa per la rete (battle, local_player_id, battle_time_left, segnali, submit_choice).

signal battle_updated
signal battle_events_received(events: Array)

var battle: Dictionary = {}
var local_player_id: String = "p1"
var battle_time_left: float = -1.0     # negativo = nessun timer
var boss_id: String = "distributore"
var seed_value: int = 1
var roster: Dictionary = {}
var rewards: Dictionary = {}
var save_path: String = RosterStore.DEFAULT_PATH
var _finished: bool = false


func start(new_roster: Dictionary, new_boss_id: String, new_seed: int) -> void:
	roster = new_roster
	boss_id = new_boss_id
	seed_value = new_seed
	rewards = {}
	_finished = false
	battle = RosterState.create_solo_battle(roster, "IO", boss_id, seed_value)
	battle_updated.emit()


func submit_choice(choice: Dictionary) -> bool:
	if battle.is_empty() or not BattleResolver.submit_choice(battle, local_player_id, choice):
		return false
	var events: Array = BattleResolver.resolve_round(battle)
	battle_events_received.emit(events)
	battle_updated.emit()
	return true


# A battaglia finita: assegna i premi alla collezione e la salva. Una volta sola.
func finish() -> Dictionary:
	if _finished or str(battle.get("winner", "")) == "":
		return rewards
	_finished = true
	var all: Dictionary = BattleRewards.for_battle(battle, boss_id, seed_value)
	rewards = all.get(local_player_id, {})
	RosterState.apply_rewards(roster, rewards)
	RosterStore.save(roster, save_path)
	return rewards
