extends SceneTree

const SERVER_URL: String = "ws://127.0.0.1:9080"
const ROOM_ID: String = "odispel-nm-test"
const TIMEOUT_SECONDS: float = 40.0

var role: String = ""
var manager: NetworkManager = null
var elapsed: float = 0.0
var got_result: bool = false
var action_sent: bool = false
var quit_at: float = -1.0


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()

	if args.is_empty() or not ["host", "client"].has(args[0]):
		print("USO: aggiungere -- host oppure -- client")
		quit(1)
		return

	role = args[0]
	print("=== ODISPEL NETWORK MANAGER TEST ", role, " ===")

	manager = NetworkManager.new()
	root.add_child(manager)

	manager.player_assigned.connect(_on_player_assigned)
	manager.round_result_received.connect(_on_round_result)
	manager.snapshot_received.connect(_on_snapshot)
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

	return false


func _make_game() -> GameState:
	var game := GameState.new()
	game.setup("nm_test", 1, 1, 2)

	var p1 := PlayerState.new()
	p1.setup("player_1", "Host", 1)
	game.party.add_player(p1)

	var p2 := PlayerState.new()
	p2.setup("player_2", "Client", 2)
	game.party.add_player(p2)

	game.setup_run("nm_run", 12345, "start")
	game.begin_combat("boss_test", "Boss", 2000)
	return game


func _on_player_assigned(player_id: String) -> void:
	print(role, ": giocatore assegnato/entrato: ", player_id)

	if action_sent:
		return

	action_sent = true

	# Il client agisce appena riceve il proprio id; l'host appena entra il client.
	manager.submit_action("attack")
	print(role, ": azione attack inviata.")


func _on_round_result(events: Array) -> void:
	got_result = true
	print(role, ": round risolto, eventi: ", events.size())

	if role == "host":
		_check_state()


func _on_snapshot() -> void:
	if role == "client" and got_result:
		_check_state()


func _check_state() -> void:
	var game: GameState = manager.game
	var p1: PlayerState = game.party.get_players()[0]
	var p2: PlayerState = game.party.get_players()[1]
	var lost: int = (1000 - p1.hp) + (1000 - p2.hp)

	print(role, ": STATO boss=", game.combat.boss.hp,
		" p1=", p1.hp, " p2=", p2.hp,
		" round=", game.combat.round_state.number)

	var ok: bool = (
		game.combat.boss.hp == 1800
		and lost == 200
		and game.combat.round_state.number == 2
	)

	if ok:
		print("PASS: ", role, " ha lo stato corretto dopo il round.")
		quit_at = elapsed + 1.5
	else:
		_fail("stato non corretto.")


func _on_error(reason: String) -> void:
	# Dopo il PASS, la chiusura del collegamento è normale.
	if quit_at > 0.0:
		return

	_fail(reason)


func _fail(reason: String) -> void:
	print("FAIL: ", reason)

	if manager != null:
		manager.shutdown()

	quit(1)
