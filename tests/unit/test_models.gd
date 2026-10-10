
extends SceneTree

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	call_deferred("_run_tests")


func check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("PASS: ", description)
	else:
		failed += 1
		push_error("FAIL: " + description)


func _run_tests() -> void:
	print("")
	print("=== ODISPEL MODEL TESTS ===")

	_test_network_identity()
	_test_player_state()
	_test_party_state()
	_test_run_state()
	_test_rng_state()
	_test_rng_json_precision()
	_test_round_state()
	_test_boss_state()
	_test_combat_state()
	_test_game_state()
	_test_network_snapshot()

	print("")
	print("=== RISULTATI ===")
	print("PASS: ", passed)
	print("FAIL: ", failed)

	if failed == 0:
		print("TUTTI I TEST SUPERATI")
		quit(0)
	else:
		print("SONO NECESSARIE CORREZIONI")
		quit(1)


func _test_network_identity() -> void:
	var identity := NetworkIdentity.new()
	identity.setup(7, "player_test")

	check(identity.is_valid(), "NetworkIdentity valida")
	check(identity.has_player(), "NetworkIdentity contiene il giocatore")

	var restored := NetworkIdentity.from_dictionary(
		identity.to_dictionary()
	)

	check(
		restored.peer_id == 7 and restored.player_id == "player_test",
		"NetworkIdentity serializzazione"
	)


func _test_player_state() -> void:
	var player := PlayerState.new()
	player.setup("player_1", "Tester", 1)

	check(player.is_alive, "PlayerState iniziale vivo")
	check(player.hp == player.max_hp, "HP iniziali corretti")

	var damage := player.take_damage(100)
	check(damage == 100, "Danno applicato correttamente")

	var restored := PlayerState.from_dictionary(
		player.to_dictionary()
	)

	check(
		restored.id == player.id and restored.hp == player.hp,
		"PlayerState serializzazione"
	)


func _test_party_state() -> void:
	var party := PartyState.new()
	party.setup("party_test", 2)
	
	

	var player_1 := PlayerState.new()
	player_1.setup("player_1", "Tester 1", 1)

	var player_2 := PlayerState.new()
	player_2.setup("player_2", "Tester 2", 2)

	check(party.add_player(player_1), "Aggiunta primo giocatore")
	check(party.add_player(player_2), "Aggiunta secondo giocatore")
	check(party.get_occupied_count() == 2, "Conteggio giocatori")
	check(party.is_valid(), "Party valido")

	check(
		party.set_player_ready("player_1", true),
		"Impostazione ready"
	)

	check(
		party.disconnect_player("player_2"),
		"Disconnessione giocatore"
	)

	check(
		party.get_player_by_id("player_2").controlled_by_ai,
		"AI attivata dopo disconnessione"
	)

	var restored := PartyState.from_dictionary(
		party.to_dictionary()
	)

	check(restored.is_valid(), "Party serializzazione e validazione")

	check(
		restored.get_players().size() == 2,
		"Party conserva i dati dei giocatori dopo serializzazione"
	)


func _test_run_state() -> void:
	var run := RunState.new()
	run.setup("run_test", 12345, "node_start")

	check(run.is_valid(), "RunState valida")

	run.advance_encounter()
	check(run.encounter_index == 1, "Avanzamento incontro")

	var restored := RunState.from_dictionary(run.to_dictionary())

	check(
		restored.is_valid() and restored.seed == 12345,
		"RunState serializzazione"
	)


func _test_rng_state() -> void:
	var rng_a := RNGState.new()
	var rng_b := RNGState.new()

	rng_a.setup(12345)
	rng_b.setup(12345)

	var first_a: int = rng_a.random_int(0, 100)
	var first_b: int = rng_b.random_int(0, 100)

	check(first_a == first_b, "RNG deterministico")

	var restored := RNGState.from_dictionary(rng_a.to_dictionary())

	check(restored.is_valid(), "RNG serializzazione valida")
	check(
		restored.random_int(0, 100) == rng_a.random_int(0, 100),
		"RNG continua la sequenza dopo ripristino"
	)


func _test_rng_json_precision() -> void:
	var rng := RNGState.new()
	rng.setup(987654321987654321)

	# Valori oltre 2^53 devono sopravvivere al passaggio per JSON.
	for _i in range(5):
		rng.random_int(0, 1000)

	var parsed: Variant = JSON.parse_string(JSON.stringify(rng.to_dictionary()))
	check(parsed is Dictionary, "RNG: JSON valido")

	if not parsed is Dictionary:
		return

	check(parsed["state_value"] is String, "RNG: stato serializzato come stringa")
	check(parsed["seed_value"] is String, "RNG: seed serializzato come stringa")

	var restored := RNGState.from_dictionary(parsed)
	check(restored.seed_value == rng.seed_value, "RNG: seed identico dopo JSON")
	check(restored.state_value == rng.state_value, "RNG: stato identico dopo JSON")
	check(
		restored.random_int(0, 1000000) == rng.random_int(0, 1000000),
		"RNG: stessa sequenza dopo JSON"
	)

	var legacy := RNGState.from_dictionary({"seed_value": 12345, "state_value": 42})
	check(
		legacy.seed_value == 12345 and legacy.state_value == 42,
		"RNG: i vecchi dati numerici si leggono ancora"
	)

	var run := RunState.new()
	run.setup("big_run", 987654321987654321, "start")
	var run_parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dictionary()))
	check(
		run_parsed is Dictionary
		and RunState.from_dictionary(run_parsed).seed == 987654321987654321,
		"RunState: seed grande identico dopo JSON"
	)


func _test_round_state() -> void:
	var round_state := RoundState.new()
	round_state.setup(1, 30.0, 5.0)

	check(round_state.is_valid(), "RoundState valida")

	round_state.begin_reaction()
	round_state.update_reaction_timer(1.0)

	check(
		round_state.reaction_time_remaining < 5.0,
		"Timer di reazione aggiornato"
	)

	var restored := RoundState.from_dictionary(
		round_state.to_dictionary()
	)

	check(restored.is_valid(), "RoundState serializzazione")


func _test_boss_state() -> void:
	var boss := BossState.new()
	boss.setup("boss_test", "Boss di prova", 1000)

	check(boss.is_valid(), "BossState valida")

	var damage := boss.take_damage(250)
	check(damage == 250 and boss.hp == 750, "Danno al boss")

	var restored := BossState.from_dictionary(boss.to_dictionary())

	check(
		restored.is_valid() and restored.hp == 750,
		"BossState serializzazione"
	)


func _test_combat_state() -> void:
	var combat := CombatState.new()
	combat.setup("boss_test", "Boss di prova", 1000, 12345)

	check(combat.begin_combat(), "Avvio combattimento")
	check(combat.is_valid(), "CombatState valida")

	var restored := CombatState.from_dictionary(
		combat.to_dictionary()
	)

	check(restored.is_valid(), "CombatState serializzazione")


func _test_game_state() -> void:
	var game := GameState.new()
	game.setup("session_test", 1, 1, 2)

	check(game.is_valid(), "GameState iniziale valida")

	check(
		game.setup_run("run_test", 12345, "node_start"),
		"Creazione run in GameState"
	)

	check(
		game.begin_combat("boss_test", "Boss di prova", 1000),
		"Creazione combattimento in GameState"
	)

	check(game.is_valid(), "GameState completa valida")


func _test_network_snapshot() -> void:
	var game := GameState.new()
	game.setup("snapshot_test", 1, 1, 2)

	var player := PlayerState.new()
	player.setup("player_1", "Tester", 1)
	check(game.party.add_player(player), "Preparazione snapshot")

	check(game.setup_run("run_snapshot", 9876, "node_start"),
		"Preparazione run snapshot")

	check(game.begin_combat("boss_snapshot", "Boss", 1000),
		"Preparazione combattimento snapshot")

	var snapshot := NetworkSnapshot.new()

	check(
		snapshot.create_from_game_state(game, 1),
		"Creazione NetworkSnapshot"
	)

	var restored_snapshot := NetworkSnapshot.from_dictionary(
		snapshot.to_dictionary()
	)

	check(restored_snapshot.is_valid(), "NetworkSnapshot serializzazione")

	var restored_game := GameState.from_dictionary(
		restored_snapshot.state_data
	)

	check(restored_game.is_valid(), "Ripristino GameState dallo snapshot")

	check(
		restored_game.party.get_players().size() == 1,
		"Snapshot conserva i dati dei giocatori"
	)
