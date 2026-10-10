extends SceneTree

const SERVER_URL: String = "ws://127.0.0.1:9080"
const ROOM_ID: String = "odispel-disc-test"
const TIMEOUT_SECONDS: float = 40.0
const CLIENT_LEAVE_DELAY: float = 1.0

var role: String = ""
var manager: NetworkManager = null
var elapsed: float = 0.0
var client_leave_at: float = -1.0
var client_left: bool = false
var host_acted: bool = false
var left_player_id: String = ""
var finished: bool = false
var quit_at: float = -1.0
var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()

	if args.is_empty() or not ["host", "client"].has(args[0]):
		print("USO: aggiungere -- host oppure -- client")
		quit(1)
		return

	role = args[0]
	print("=== ODISPEL NETWORK DISCONNECT TEST ", role, " ===")

	manager = NetworkManager.new()
	root.add_child(manager)

	manager.player_assigned.connect(_on_player_assigned)
	manager.player_left.connect(_on_player_left)
	manager.round_result_received.connect(_on_round_result)
	manager.network_error.connect(_on_error)

	var started: bool = false

	if role == "host":
		started = manager.start_host(_make_game(), SERVER_URL, ROOM_ID, "Host")
	else:
		started = manager.start_client(SERVER_URL, ROOM_ID, "Client")

	if not started:
		_fail("avvio fallito.")


func _process(delta: float) -> bool:
	elapsed += delta

	if quit_at > 0.0 and elapsed >= quit_at:
		manager.shutdown()
		quit(0)
		return true

	if elapsed > TIMEOUT_SECONDS:
		_fail("Timeout.")
		return true

	# Il client esce di scena senza agire.
	if (
		role == "client"
		and client_leave_at > 0.0
		and not client_left
		and elapsed >= client_leave_at
	):
		client_left = true
		print("client: mi disconnetto senza agire.")
		manager.shutdown()
		quit(0)
		return true

	return false


func _make_game() -> GameState:
	var game := GameState.new()
	game.setup("disc_test", 1, 1, 2)

	var p1 := PlayerState.new()
	p1.setup("player_1", "Host", 1)
	game.party.add_player(p1)

	var p2 := PlayerState.new()
	p2.setup("player_2", "Client", 2)
	game.party.add_player(p2)

	game.setup_run("disc_run", 12345, "start")
	game.begin_combat("boss_test", "Boss", 2000)
	return game


func _check(name: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _on_player_assigned(player_id: String) -> void:
	print(role, ": giocatore assegnato/entrato: ", player_id)

	if role == "client" and client_leave_at < 0.0:
		client_leave_at = elapsed + CLIENT_LEAVE_DELAY


func _on_player_left(player_id: String) -> void:
	if role != "host" or host_acted:
		return

	left_player_id = player_id
	print("host: ", player_id, " si è disconnesso.")

	var game: GameState = manager.game
	var p2: PlayerState = game.party.get_players()[1]

	_check("Giocatore segnato disconnesso", not p2.connected)
	_check("Giocatore controllato dall'IA", p2.controlled_by_ai)
	_check("Round non ancora risolto", game.combat.round_state.number == 1)

	host_acted = true
	manager.host_submit_action("attack")


func _on_round_result(events: Array) -> void:
	if role != "host" or finished:
		return

	finished = true

	var game: GameState = manager.game
	var p1: PlayerState = game.party.get_players()[0]
	var p2: PlayerState = game.party.get_players()[1]
	var has_auto: bool = false

	for event: Dictionary in events:
		if event["type"] == "auto_action":
			has_auto = true

	print("host: STATO boss=", game.combat.boss.hp,
		" p1=", p1.hp, " p2=", p2.hp,
		" round=", game.combat.round_state.number)

	_check("Boss a 1800 (host + attacco automatico)", game.combat.boss.hp == 1800)
	_check("Evento auto_action presente", has_auto)
	_check("Round 2 iniziato", game.combat.round_state.number == 2)
	_check("Fase tornata a PLANNING", game.combat.phase == CombatState.Phase.PLANNING)
	_check("Il giocatore disconnesso resta disconnesso", not p2.connected)

	if failed == 0:
		print("PASS TEST DISCONNESSIONE: host")
		quit_at = elapsed + 1.0
	else:
		_fail("controlli finali falliti.")


func _on_error(reason: String) -> void:
	# Il client si disconnette di proposito; l'host non riceve errori.
	if role == "client" or quit_at > 0.0:
		return

	_fail(reason)


func _fail(reason: String) -> void:
	print("FAIL: ", reason)

	if manager != null:
		manager.shutdown()

	quit(1)
