extends SceneTree

const SERVER_URL: String = "ws://127.0.0.1:9080"
const ROOM_ID: String = "odispel-hard-test"
const TIMEOUT_SECONDS: float = 40.0
const SETTLE_SECONDS: float = 2.0

var role: String = ""
var manager: NetworkManager = null
var elapsed: float = 0.0
var junk_sent: bool = false
var precheck_at: float = -1.0
var host_prechecked: bool = false
var got_result: bool = false
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
	print("=== ODISPEL NETWORK HARD TEST ", role, " ===")

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

	if (
		role == "host"
		and precheck_at > 0.0
		and not host_prechecked
		and elapsed >= precheck_at
	):
		host_prechecked = true
		_host_precheck()

	return false


func _make_game() -> GameState:
	var game := GameState.new()
	game.setup("hard_test", 1, 1, 2)

	var p1 := PlayerState.new()
	p1.setup("player_1", "Host", 1)
	game.party.add_player(p1)

	var p2 := PlayerState.new()
	p2.setup("player_2", "Client", 2)
	game.party.add_player(p2)

	game.setup_run("hard_run", 12345, "start")
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

	if role == "client":
		if not junk_sent:
			junk_sent = true
			_send_junk()
	elif precheck_at < 0.0:
		precheck_at = elapsed + SETTLE_SECONDS


func _send_junk() -> void:
	# Solo per il test: si legge il collegamento privato verso l'host
	# per inviare messaggi che il client normale non invierebbe mai.
	var host_link: WebRTCLink = manager._links.get(manager._host_peer_id)

	if host_link == null:
		_fail("collegamento verso l'host non trovato.")
		return

	var messages: Array[Dictionary] = [
		{"type": "banana"},
		{"type": "action", "action_id": "banana"},
		{"type": "action"},
		{"type": "action", "action_id": {"x": 1}},
		{"type": "hello", "name": "Hacker"},
		{"type": "snapshot", "state": {}},
		{"type": "action", "player_id": "player_1", "action_id": "guard"},
		{"type": "action", "action_id": "attack"}
	]

	for message in messages:
		host_link.send_message(message)

	print("client: ", messages.size(), " messaggi ostili/duplicati inviati.")


func _host_precheck() -> void:
	var game: GameState = manager.game
	var p1: PlayerState = game.party.get_players()[0]
	var p2: PlayerState = game.party.get_players()[1]

	print("host: controllo dopo i messaggi ostili")

	_check("Boss non toccato", game.combat.boss.hp == 2000)
	_check("Round ancora il primo", game.combat.round_state.number == 1)
	_check("Fase ancora PLANNING", game.combat.phase == CombatState.Phase.PLANNING)
	_check(
		"Il client non ha agito al posto dell'host",
		not p1.is_locked and p1.selected_action_id == ""
	)
	_check(
		"Azione del client registrata una sola volta (guard)",
		p2.is_locked and p2.selected_action_id == "guard"
	)
	_check("Nome non cambiato dal secondo hello", p2.display_name == "Client")
	_check("Round non risolvibile senza l'host", not CombatResolver.can_resolve(game))

	if failed > 0:
		_fail("controlli iniziali dell'host falliti.")
		return

	manager.host_submit_action("attack")


func _on_round_result(_events: Array) -> void:
	got_result = true

	if role == "host":
		_check_final()


func _on_snapshot() -> void:
	if role == "client" and got_result:
		_check_final()


func _check_final() -> void:
	if finished:
		return

	finished = true

	var game: GameState = manager.game
	var p1: PlayerState = game.party.get_players()[0]
	var p2: PlayerState = game.party.get_players()[1]

	print(role, ": STATO boss=", game.combat.boss.hp,
		" p1=", p1.hp, " p2=", p2.hp,
		" round=", game.combat.round_state.number)

	var hits_consistent: bool = (
		(p1.hp == 800 and p2.hp == 1000)
		or (p1.hp == 1000 and p2.hp == 900)
	)

	_check("Boss a 1900 (attacca solo l'host)", game.combat.boss.hp == 1900)
	_check("Un solo giocatore colpito, danno coerente", hits_consistent)
	_check("Round 2 iniziato", game.combat.round_state.number == 2)
	_check("Scelte azzerate", p1.selected_action_id == "" and p2.selected_action_id == "")

	if failed == 0:
		print("PASS TEST DURO: ", role)
		quit_at = elapsed + 1.5
	else:
		_fail("stato finale non corretto.")


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
