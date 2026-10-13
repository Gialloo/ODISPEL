class_name PvpLocalSource
extends RefCounted

# Sfida PvP in locale contro l'IA (allenamento): stessa interfaccia della rete, nessuna connessione.

signal battle_updated
signal battle_events_received(events: Array)

var battle: Dictionary = {}
var local_player_id: String = "p1"
var battle_time_left: float = 0.0


func start(team: Array, mode: String, balanced: bool, seed_value: int, player_name: String = "GIOCATORE") -> void:
	var seats: Vector2i = PvpEngine.seats(mode)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var chars: Array = BattleContent.CHARACTERS.keys()
	var level: int = 1
	for e in team:
		level = maxi(level, int(e.get("level", 1)))
	var specs: Array = [{"id": local_player_id, "name": player_name, "ai": false, "team": team}]
	for i in range(1, seats.x):
		var squad: Array = []
		for k in 3:
			squad.append({"char": str(chars[rng.randi() % chars.size()]), "level": level, "rank": 0, "gear": [], "skills": [], "passives": [], "ult": ""})
		specs.append({"id": "ia_%d" % i, "name": "IA %d" % i, "ai": true, "team": squad})
	battle = PvpEngine.create(specs, mode, balanced, seed_value)
	battle_updated.emit()


func submit_choice(choice: Dictionary) -> bool:
	if not PvpEngine.submit_choice(battle, local_player_id, choice):
		return false
	if PvpEngine.can_resolve(battle):
		var events: Array = PvpEngine.resolve_round(battle)
		battle_events_received.emit(events)
	battle_updated.emit()
	return true


var save_path: String = RosterStore.DEFAULT_PATH
var rewards: Dictionary = {}
var _paid: bool = false


# Allenamento: una piccola parte della borsa, nessun contatore per le imprese.
func finish() -> Dictionary:
	if _paid or battle.is_empty() or str(battle["winner"]) == "":
		return rewards
	_paid = true
	var winner: String = str(battle["winner"])
	var mine: Dictionary = PvpEngine.player(battle, local_player_id)
	var outcome: String = "draw" if winner == "draw" else ("win" if str(mine.get("team", "")) == winner else "loss")
	rewards = PvpRewards.for_player(int(str(battle["rng_seed"]).to_int()), 0, outcome, true)
	var roster: Dictionary = RosterStore.load_or_new(save_path)
	RosterState.apply_rewards(roster, rewards)
	RosterStore.save(roster, save_path)
	return rewards
