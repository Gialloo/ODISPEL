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

var bar: RoomBar = null
var last_error: String = ""
var _last_scene: Node = null
var _entering_battle: bool = false
var _known_lobby: Dictionary = {}


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
		var fighting: bool = scene is PvpScreen or (scene != null and (SceneRouter.is_current("battle") or SceneRouter.is_current("battle_v2") or SceneRouter.is_current("squad_v2")))
		if fighting != Settings.in_battle:
			Settings.in_battle = fighting
			Settings.apply_video()
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
	Notify.busy("rete", "CONNESSIONE AL SERVER...")
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
	Notify.busy("rete", "CONNESSIONE AL SERVER...")
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
	_known_lobby = {}
	Notify.idle("rete")

	if bar != null:
		bar.expanded = false
		bar.refresh()


# Esce dalla stanza (da qualsiasi schermata) e torna all'hub se serve.
func leave_room() -> void:
	close()

	if SceneRouter.is_current("battle") or SceneRouter.is_current("pvp"):
		SceneRouter.go("hub")

	Notify.toast("Sei uscito dalla stanza.")


func _attach() -> void:
	last_error = ""
	var roster: Dictionary = RosterStore.load_or_new()
	manager.local_cleared = (roster.get("cleared", {}) as Dictionary).duplicate()
	manager.local_profile = Profile.current()
	manager.set_local_team(RosterState.team_entries(roster))
	manager.lobby_updated.connect(_on_lobby_updated)
	manager.battle_updated.connect(_on_battle_updated)
	manager.network_error.connect(_on_network_error)
	manager.player_left.connect(_on_player_left)
	manager.player_assigned.connect(_on_player_assigned)
	manager.room_joined.connect(_on_room_joined)
	manager.waiting_for_host.connect(func(attempt: int) -> void:
		Notify.busy("rete", "RICERCA DELL'HOST... (%d)" % attempt))
	manager.signaling_lost.connect(func() -> void:
		Notify.warning("Il server non risponde: nessun altro potra' entrare."))

	if manager.is_host:
		manager.refresh_lobby()


# Rilegge la squadra scelta nella schermata Squadra e la comunica agli altri.
func refresh_team() -> void:
	if manager == null:
		return

	manager.set_local_team(RosterState.team_entries(RosterStore.load_or_new()))


func _on_room_joined() -> void:
	if manager != null and manager.is_host:
		Notify.idle("rete")
		Notify.success("Stanza creata. Aspetta gli altri operatori.")

	_on_lobby_updated()


func _on_player_assigned(_id: String) -> void:
	if manager != null and not manager.is_host:
		Notify.idle("rete")
		Notify.success("Sei nella stanza.")

	_on_lobby_updated()


func _on_lobby_updated() -> void:
	if manager != null:
		_announce_changes(_known_lobby, manager.lobby)
		_known_lobby = manager.lobby.duplicate(true)

	if bar != null:
		bar.refresh()


# Dice al giocatore cosa e' cambiato nella lobby: chi entra, chi e' pronto, la missione.
func _announce_changes(old: Dictionary, new: Dictionary) -> void:
	if old.is_empty():
		return

	var before: Dictionary = {}

	for p in old.get("players", []):
		before[str(p["id"])] = p

	var me: String = manager.local_player_id

	for p in new.get("players", []):
		var id: String = str(p["id"])
		var name: String = str(p["name"]).to_upper()

		if id == me:
			continue

		if not before.has(id):
			Notify.toast("%s E' ENTRATO NELLA STANZA" % name)
		elif bool(p["ready"]) and not bool(before[id]["ready"]):
			Notify.success("%s E' PRONTO" % name)

	if str(old.get("boss", "")) != str(new.get("boss", "")) or int(old.get("tier", 0)) != int(new.get("tier", 0)):
		if not manager.is_host:
			Notify.toast("MISSIONE: %s · %s" % [
				MissionConfig.boss_title(str(new["boss"])),
				str(BattleContent.tier_of(int(new["tier"]))["name"])
			])


func _on_player_left(player_id: String) -> void:
	var name: String = player_id

	if manager != null:
		for p in _known_lobby.get("players", []):
			if str(p["id"]) == player_id:
				name = str(p["name"])

	Notify.warning("%s ha lasciato la stanza." % name.to_upper())


func _on_network_error(reason: String) -> void:
	last_error = reason
	close()

	Notify.error("Errore di rete: " + Diagnostics.friendly_network_error(reason))


# La battaglia parte: tutti i giocatori della stanza ci vengono portati,
# da qualsiasi schermata si trovino.
func _on_battle_updated() -> void:
	if manager == null or _entering_battle or manager.battle.is_empty():
		return

	if str(manager.battle.get("winner", "")) != "":
		return

	var scene: Node = get_tree().current_scene

	if (SceneRouter.is_current("battle") or SceneRouter.is_current("pvp")) and scene.get("source") == manager:
		return

	enter_battle()


func enter_battle() -> void:
	if manager == null or _entering_battle:
		return

	_entering_battle = true
	Notify.transition(_swap_to_battle, "PREPARAZIONE OPERAZIONE")

	# Pronto per la battaglia successiva.
	await get_tree().process_frame
	_entering_battle = false


func _swap_to_battle() -> void:
	if manager == null:
		return

	var key: String = "pvp" if bool(manager.battle.get("pvp", false)) else "battle"
	var packed: PackedScene = load(SceneRouter.path_of(key)) as PackedScene
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


func _new_manager() -> NetworkManager:
	var new_manager := NetworkManager.new()
	new_manager.name = "NetworkManager"
	add_child(new_manager)
	return new_manager
