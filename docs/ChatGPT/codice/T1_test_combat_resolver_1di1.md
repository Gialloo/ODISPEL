FILE test_combat_resolver.gd - PARTE 1 DI 1
Percorso: tests/unit/test_combat_resolver.gd
(Codice GDScript, rientri con tab. Questa e' l'ultima parte: ora puoi analizzare tutto il file.)

```gdscript
extends SceneTree

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	print("=== ODISPEL COMBAT RESOLVER TESTS ===")

	_test_submit_rules()
	_test_attack_round()
	_test_guard_round()
	_test_full_combat()
	_test_disconnected_players()
	_test_forced_resolution()

	print("")
	print("=== RISULTATI ===")
	print("PASS: ", passed)
	print("FAIL: ", failed)

	if failed == 0:
		print("TUTTI I TEST SUPERATI")

	quit(0 if failed == 0 else 1)


func _check(name: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _make_game(run_seed: int) -> GameState:
	var game := GameState.new()
	game.setup("test_session", 1, 1, 2)

	var p1 := PlayerState.new()
	p1.setup("player_1", "Giocatore 1", 1)
	game.party.add_player(p1)

	var p2 := PlayerState.new()
	p2.setup("player_2", "Giocatore 2", 2)
	game.party.add_player(p2)

	game.setup_run("test_run", run_seed, "start")
	game.begin_combat("boss_test", "Boss", 2000)
	return game


func _player(game: GameState, player_id: String) -> PlayerState:
	for player: PlayerState in game.party.get_players():
		if player.id == player_id:
			return player

	return null


func _test_submit_rules() -> void:
	var game: GameState = _make_game(12345)

	_check("Azione sconosciuta rifiutata", not CombatResolver.submit_action(game, "player_1", "banana"))
	_check("Giocatore sconosciuto rifiutato", not CombatResolver.submit_action(game, "nessuno", "attack"))
	_check("Azione valida accettata", CombatResolver.submit_action(game, "player_1", "attack"))
	_check("Azione duplicata rifiutata", not CombatResolver.submit_action(game, "player_1", "guard"))
	_check("Round non risolvibile con azioni mancanti", not CombatResolver.can_resolve(game))

	var early: Dictionary = CombatResolver.resolve_round(game)
	_check("Risoluzione anticipata rifiutata", early["ok"] == false)

	CombatResolver.submit_action(game, "player_2", "guard")
	_check("Round risolvibile con tutte le azioni", CombatResolver.can_resolve(game))


func _test_attack_round() -> void:
	var game: GameState = _make_game(12345)
	CombatResolver.submit_action(game, "player_1", "attack")
	CombatResolver.submit_action(game, "player_2", "attack")

	var result: Dictionary = CombatResolver.resolve_round(game)
	var p1: PlayerState = _player(game, "player_1")
	var p2: PlayerState = _player(game, "player_2")
	var lost: int = (1000 - p1.hp) + (1000 - p2.hp)

	_check("Round risolto", result["ok"] == true)
	_check("Boss perde 200 HP", game.combat.boss.hp == 1800)
	_check("Il boss colpisce un solo giocatore per 200", lost == 200)
	_check("Round successivo iniziato", game.combat.round_state.number == 2)
	_check("Fase tornata a PLANNING", game.combat.phase == CombatState.Phase.PLANNING)
	_check("Scelte azzerate", p1.selected_action_id == "" and not p1.is_locked)
	_check("Eventi registrati", (result["events"] as Array).size() >= 3)


func _test_guard_round() -> void:
	var game: GameState = _make_game(12345)
	CombatResolver.submit_action(game, "player_1", "guard")
	CombatResolver.submit_action(game, "player_2", "guard")
	CombatResolver.resolve_round(game)

	var p1: PlayerState = _player(game, "player_1")
	var p2: PlayerState = _player(game, "player_2")
	var lost: int = (1000 - p1.hp) + (1000 - p2.hp)

	_check("Boss intatto se tutti si difendono", game.combat.boss.hp == 2000)
	_check("Difesa dimezza il danno (100)", lost == 100)


func _play_full(run_seed: int) -> Dictionary:
	var game: GameState = _make_game(run_seed)
	var rounds: int = 0
	var finished: bool = false
	var victory: bool = false

	while rounds < 50 and not finished:
		CombatResolver.submit_action(game, "player_1", "attack")
		CombatResolver.submit_action(game, "player_2", "attack")

		var result: Dictionary = CombatResolver.resolve_round(game)
		rounds += 1

		if not result["ok"]:
			break

		finished = result["finished"]
		victory = result["victory"]

	return {
		"game": game,
		"rounds": rounds,
		"finished": finished,
		"victory": victory,
		"boss_hp": game.combat.boss.hp,
		"p1_hp": _player(game, "player_1").hp,
		"p2_hp": _player(game, "player_2").hp
	}


func _test_full_combat() -> void:
	var first: Dictionary = _play_full(12345)
	var game: GameState = first["game"]

	_check("Combattimento termina entro 50 round", first["finished"] == true)
	_check("Fase finale ENDED", game.combat.phase == CombatState.Phase.ENDED)

	if first["victory"]:
		_check("Vittoria: boss a 0 HP", first["boss_hp"] == 0)
	else:
		_check("Sconfitta: nessun giocatore vivo", game.party.get_living_players().is_empty())

	_check("Nessuna azione dopo la fine", not CombatResolver.submit_action(game, "player_1", "attack"))
	_check("Nessuna risoluzione dopo la fine", CombatResolver.resolve_round(game)["ok"] == false)

	var second: Dictionary = _play_full(12345)
	_check(
		"Stesso seed, stesso risultato",
		first["rounds"] == second["rounds"]
		and first["boss_hp"] == second["boss_hp"]
		and first["p1_hp"] == second["p1_hp"]
		and first["p2_hp"] == second["p2_hp"]
	)


func _has_event(result: Dictionary, event_type: String) -> bool:
	for event: Dictionary in result["events"]:
		if event["type"] == event_type:
			return true

	return false


func _test_disconnected_players() -> void:
	# Caso 1: il giocatore 2 cade prima di scegliere.
	var game: GameState = _make_game(12345)
	_player(game, "player_2").disconnect_player()

	_check(
		"Disconnesso: il giocatore connesso che non ha scelto blocca ancora",
		not CombatResolver.can_resolve(game)
	)

	CombatResolver.submit_action(game, "player_1", "attack")

	_check("Disconnesso: non blocca il round", CombatResolver.can_resolve(game))

	var result: Dictionary = CombatResolver.resolve_round(game)

	_check("Disconnesso: round risolto", result["ok"] == true)
	_check("Disconnesso: attacco automatico (boss a 1800)", game.combat.boss.hp == 1800)
	_check("Disconnesso: evento auto_action registrato", _has_event(result, "auto_action"))
	_check("Disconnesso: round successivo iniziato", game.combat.round_state.number == 2)

	# Caso 2: il giocatore 2 sceglie guard e poi cade.
	var game2: GameState = _make_game(12345)
	CombatResolver.submit_action(game2, "player_2", "guard")
	_player(game2, "player_2").disconnect_player()

	_check(
		"Scelta fatta prima di cadere: manca ancora il giocatore 1",
		not CombatResolver.can_resolve(game2)
	)

	CombatResolver.submit_action(game2, "player_1", "attack")
	var result2: Dictionary = CombatResolver.resolve_round(game2)

	_check("Scelta conservata: round risolto", result2["ok"] == true)
	_check("Scelta conservata: attacca solo il giocatore 1 (boss a 1900)", game2.combat.boss.hp == 1900)
	_check("Scelta conservata: nessuna azione automatica", not _has_event(result2, "auto_action"))


func _test_forced_resolution() -> void:
	var game: GameState = _make_game(12345)
	CombatResolver.submit_action(game, "player_1", "attack")

	_check("Forzato: senza force il round non si risolve", not CombatResolver.can_resolve(game))
	_check("Forzato: la risoluzione forzata è possibile", CombatResolver.can_force_resolve(game))

	var normal: Dictionary = CombatResolver.resolve_round(game)
	_check("Forzato: resolve_round normale rifiutato", normal["ok"] == false)

	var result: Dictionary = CombatResolver.resolve_round(game, 1, true)

	_check("Forzato: round risolto", result["ok"] == true)
	_check("Forzato: attacco automatico di chi non ha scelto (boss a 1800)", game.combat.boss.hp == 1800)
	_check("Forzato: evento auto_action", _has_event(result, "auto_action"))

	var timeout_text: bool = false

	for event: Dictionary in result["events"]:
		if event["type"] == "auto_action" and "in tempo" in str(event["text"]):
			timeout_text = true

	_check("Forzato: il messaggio parla di tempo scaduto", timeout_text)
	_check("Forzato: round successivo iniziato", game.combat.round_state.number == 2)

	# Fuori dalla fase di pianificazione la forzatura non vale.
	var ended: GameState = _make_game(12345)
	ended.combat.end_combat()
	_check("Forzato: nessuna forzatura a combattimento finito", not CombatResolver.can_force_resolve(ended))
```
