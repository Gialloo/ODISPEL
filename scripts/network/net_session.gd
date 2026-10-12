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

const BATTLE_PATH: String = "res://scenes/battle/battle_screen.tscn"
const HUB_PATH: String = "res://scenes/hub/hub_demo.tscn"

var bar: RoomBar = null
var last_error: String = ""
var _last_scene: Node = null
var _entering_battle: bool = false


func _ready() -> void:
	# Tema grafico unico per tutto il gioco, popup compresi.
	get_tree().root.theme = UiTheme.build()
	bar = RoomBar.new().setup(self)
	add_child(bar)


func _process(_delta: float) -> void:
	# Cambio di schermata: la squadra potrebbe essere cambiata, la barra va rivista.
	var scene: Node = get_tree().current_scene
	if scene != _last_scene:
		_last_scene = scene
		if manager != null:
			refresh_team()
		if bar != null:
			bar.refresh()


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

	_attach()
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
	_attach()
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
	_entering_battle = false

	if bar != null:
		bar.expanded = false
		bar.refresh()


# Esce dalla stanza (da qualsiasi schermata) e torna all'hub se serve.
func leave_room() -> void:
	close()

	var scene: Node = get_tree().current_scene

	if scene != null and str(scene.scene_file_path).contains("battle_screen"):
		get_tree().change_scene_to_file(HUB_PATH)

	if bar != null:
		bar.show_toast("Sei uscito dalla stanza.")


func _attach() -> void:
	last_error = ""
	manager.set_local_team(RosterState.team_entries(RosterStore.load_or_new()))
	manager.lobby_updated.connect(_on_lobby_updated)
	manager.battle_updated.connect(_on_battle_updated)
	manager.network_error.connect(_on_network_error)
	manager.player_left.connect(_on_player_left)
	manager.player_assigned.connect(func(_id: String) -> void: _on_lobby_updated())
	manager.room_joined.connect(_on_lobby_updated)

	if manager.is_host:
		manager.refresh_lobby()


# Rilegge la squadra scelta nella schermata Squadra e la comunica agli altri.
func refresh_team() -> void:
	if manager == null:
		return

	manager.set_local_team(RosterState.team_entries(RosterStore.load_or_new()))


func _on_lobby_updated() -> void:
	if bar != null:
		bar.refresh()


func _on_player_left(player_id: String) -> void:
	if bar != null:
		var name: String = player_id

		for p in manager.lobby.get("players", []) if manager != null else []:
			if str(p["id"]) == player_id:
				name = str(p["name"])

		bar.show_toast("%s ha lasciato la stanza." % name)


func _on_network_error(reason: String) -> void:
	last_error = reason
	close()

	if bar != null:
		bar.show_toast("Errore di rete: " + reason, 8.0)


# La battaglia parte: tutti i giocatori della stanza ci vengono portati,
# da qualsiasi schermata si trovino.
func _on_battle_updated() -> void:
	if manager == null or _entering_battle or manager.battle.is_empty():
		return

	if str(manager.battle.get("winner", "")) != "":
		return

	var scene: Node = get_tree().current_scene

	if scene != null and str(scene.scene_file_path).contains("battle_screen") and scene.get("source") == manager:
		return

	enter_battle()


func enter_battle() -> void:
	if manager == null or _entering_battle:
		return

	_entering_battle = true
	var packed: PackedScene = load(BATTLE_PATH) as PackedScene
	var battle_scene: Node = packed.instantiate()
	battle_scene.set("pending_source", manager)
	var tree: SceneTree = get_tree()
	var old: Node = tree.current_scene
	tree.root.add_child(battle_scene)
	tree.current_scene = battle_scene

	if old != null:
		old.queue_free()

	if bar != null:
		bar.refresh()

	# Pronto per la battaglia successiva.
	await tree.process_frame
	_entering_battle = false


func _new_manager() -> NetworkManager:
	var new_manager := NetworkManager.new()
	new_manager.name = "NetworkManager"
	add_child(new_manager)
	return new_manager
