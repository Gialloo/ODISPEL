extends Node

# Autoload "NetSession": tiene viva la connessione di rete mentre si cambia
# scena (lobby -> combattimento -> risultati).
#
# Va registrato in Progetto > Impostazioni progetto > Autoload con il nome
# NetSession e questo file come percorso.

const PLAYER_BASE_HP: int = 1000
const HP_PER_LEVEL: float = 0.10

var manager: NetworkManager = null

# Il token resta per tutta la sessione dell'app: chi esce dalla stanza
# e rientra con lo stesso token riprende lo stesso giocatore.
var client_token: String = ""


func is_active() -> bool:
	return manager != null


func start_host(
	url: String,
	room_id: String,
	display_name: String,
	max_players: int
) -> bool:
	close()

	var game := GameState.new()
	game.setup("lobby_" + room_id, 1, 1, max_players)

	var level: int = maxi(1, CampaignState.player_level)
	var hp_multiplier: float = 1.0 + HP_PER_LEVEL * float(level - 1)

	for index in range(game.party.max_players):
		var player := PlayerState.new()
		player.max_hp = int(round(PLAYER_BASE_HP * hp_multiplier))
		player.setup(
			"player_" + str(index + 1),
			display_name if index == 0 else "Posto " + str(index + 1),
			index + 1
		)

		if not game.party.add_player(player):
			return false

	manager = _new_manager()
	manager.player_level = level

	if not manager.start_host(game, url, room_id, display_name):
		close()
		return false

	return true


func start_client(url: String, room_id: String, display_name: String) -> bool:
	close()

	manager = _new_manager()

	if not client_token.is_empty():
		manager.session_token = client_token

	if not manager.start_client(url, room_id, display_name):
		close()
		return false

	client_token = manager.session_token
	return true


# Solo l'host: avvia il combattimento con l'incontro scelto nella campagna.
func host_start_combat() -> bool:
	if manager == null or not manager.is_host:
		return false

	var encounter: EncounterData = CampaignState.get_current_encounter()

	if encounter == null or not encounter.is_valid():
		return false

	var run_seed: int = randi() % 2000000000 + 1

	return manager.host_start_combat(
		encounter.encounter_id,
		encounter.display_name,
		encounter.boss_max_hp,
		run_seed
	)


func close() -> void:
	if manager == null:
		return

	manager.shutdown()
	manager.queue_free()
	manager = null


func _new_manager() -> NetworkManager:
	var new_manager := NetworkManager.new()
	new_manager.name = "NetworkManager"
	add_child(new_manager)
	return new_manager
