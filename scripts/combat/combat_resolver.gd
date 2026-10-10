class_name CombatResolver
extends RefCounted

const PLAYER_DAMAGE: int = 100
const BOSS_DAMAGE: int = 200
const MAX_DAMAGE_REDUCTION: float = 0.50
const VALID_ACTIONS: Array[String] = ["attack", "guard"]


static func submit_action(
	game: GameState,
	player_id: String,
	action_id: String
) -> bool:
	if not _is_in_phase(game, CombatState.Phase.PLANNING):
		return false

	if not VALID_ACTIONS.has(action_id):
		return false

	var player: PlayerState = _get_player(game, player_id)

	if player == null or not player.is_alive or player.is_locked:
		return false

	player.selected_action_id = action_id
	player.is_locked = true
	return true


static func can_resolve(game: GameState) -> bool:
	if not _is_in_phase(game, CombatState.Phase.PLANNING):
		return false

	var living: Array = game.party.get_living_players()

	if living.is_empty():
		return false

	for player: PlayerState in living:
		# Chi è disconnesso o controllato dall'IA non blocca il round.
		if player.controlled_by_ai or not player.connected:
			continue

		if not player.is_locked or player.selected_action_id.is_empty():
			return false

	return true
	
static func resolve_round(
	game: GameState,
	player_level: int = 1
) -> Dictionary:
	var result: Dictionary = {
		"ok": false,
		"finished": false,
		"victory": false,
		"events": []
	}

	if not can_resolve(game):
		return result

	var combat: CombatState = game.combat
	var events: Array = result["events"]

	if not combat.lock_round() or not combat.begin_resolution():
		return result

	result["ok"] = true

	# Azione automatica per chi è disconnesso e non ha scelto.
	for player: PlayerState in game.party.get_living_players():
		if player.selected_action_id.is_empty():
			player.selected_action_id = "attack"
			player.action_was_automatic = true
			player.is_locked = true
			events.append(_event(
				"auto_action",
				player.display_name + " è disconnesso: attacco automatico.",
				player.id
			))

	var level_steps: int = maxi(0, player_level - 1)

	# 1. Attacchi dei giocatori vivi, nell'ordine del party.
	var attack_damage: int = int(
		round(PLAYER_DAMAGE * (1.0 + 0.05 * level_steps))
	)

	for player: PlayerState in game.party.get_players():
		if not combat.is_boss_alive():
			break

		if not player.is_alive:
			continue

		if player.selected_action_id == "attack":
			var dealt: int = combat.boss.take_damage(attack_damage)
			events.append(_event(
				"player_attack",
				player.display_name + " infligge " + str(dealt) + " danni.",
				player.id,
				dealt
			))

	# 2. Boss sconfitto: niente contrattacco.
	if not combat.is_boss_alive():
		combat.end_combat()
		result["finished"] = true
		result["victory"] = true
		events.append(_event("victory", "COMBATTIMENTO COMPLETATO: VITTORIA."))
		return result

	# 3. Il boss attacca un giocatore vivo scelto con l'RNG dello stato.
	var living: Array = game.party.get_living_players()
	var target: PlayerState = null

	if not living.is_empty():
		target = living[combat.get_random_index(living.size())]

	if target != null and combat.begin_boss_reaction(target.id):
		var incoming: int = BOSS_DAMAGE

		if target.selected_action_id == "guard":
			incoming = int(ceil(float(incoming) / 2.0))
			events.append(_event(
				"guard",
				target.display_name + " si difende: danni ridotti.",
				target.id
			))

		var reduction: float = minf(0.05 * level_steps, MAX_DAMAGE_REDUCTION)
		incoming = int(round(incoming * (1.0 - reduction)))

		var taken: int = target.take_damage(incoming)
		events.append(_event(
			"boss_attack",
			"Il boss colpisce " + target.display_name
			+ " per " + str(taken) + " danni.",
			target.id,
			taken
		))

		if not target.is_alive:
			events.append(_event(
				"player_ko",
				target.display_name + " è KO.",
				target.id
			))

	combat.begin_status_update()

	# 4. Sconfitta: nessun giocatore vivo.
	if game.party.get_living_players().is_empty():
		combat.end_combat()
		result["finished"] = true
		events.append(_event("defeat", "COMBATTIMENTO COMPLETATO: SCONFITTA."))
		return result

	# 5. Round successivo.
	combat.round_state.advance()
	combat.begin_round()

	for player: PlayerState in game.party.get_players():
		player.reset_round_decision()

	return result


static func _is_in_phase(game: GameState, phase: CombatState.Phase) -> bool:
	return (
		game != null
		and game.party != null
		and game.combat != null
		and game.combat.phase == phase
	)


static func _get_player(game: GameState, player_id: String) -> PlayerState:
	for player: PlayerState in game.party.get_players():
		if player.id == player_id:
			return player

	return null


static func _event(
	type: String,
	text: String,
	player_id: String = "",
	amount: int = 0
) -> Dictionary:
	return {
		"type": type,
		"text": text,
		"player_id": player_id,
		"amount": amount
	}
