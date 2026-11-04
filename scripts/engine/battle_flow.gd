class_name BattleFlow
extends RefCounted

# GIRO DEI TURNI DELLA V3 NEL MOTORE (Fase 0 del piano del combattimento, 04/11/2026).
# Prima il giro stava nella battaglia (battle3d._advance) e il simulatore (tools/v3_bilancio.gd) ne aveva una copia sua:
# ordine del round, azione rapida dello SLANCIO, vantaggio/agguato del primo round, turno dato alla tecnica a due.
# Ora sta qui, nello stato (state["flow"]), e chi guida la battaglia chiede soltanto "chi tocca adesso?".
# Perche': il motore deve poter giocare uno scontro intero senza animazioni, e la Timeline (Fase 1) si scrive in un posto solo.
# Le regole NON cambiano: SeqRound resta l'esecutore delle singole azioni.
#
# Uso: start_round(state[, ingresso]) -> next(state) finche' non torna {"end": true} -> per ogni voce:
#      player_action(...) (voce di un eroe) oppure SeqRound.boss_action(...) (voce "boss") -> SeqRound.finish(state) a fine round.


# Apre il round: SeqRound.begin e la lista dei turni per velocita'.
# ingresso (solo il primo round dello scontro): "vantaggio" = i nemici agiscono per ultimi, "agguato" = per primi.
static func start_round(state: Dictionary, ingresso: String = "") -> void:
	SeqRound.begin(state)
	var turns: Array = SeqRound.order(state)
	if ingresso == "vantaggio" or ingresso == "agguato":
		var foes: Array = turns.filter(func(e: Dictionary) -> bool: return bool(e["boss"]))
		var rest: Array = turns.filter(func(e: Dictionary) -> bool: return not bool(e["boss"]))
		turns = rest + foes if ingresso == "vantaggio" else foes + rest
	state["flow"] = {"list": turns, "i": -1}


# Il turno successivo. Salta da solo chi non puo' giocarlo (eroe caduto, o che ha dato il turno a una tecnica a due).
# Ritorna la voce ({unit, player, boss, spd, [greg], [quick]}) oppure {"end": true} quando il round e' finito.
static func next(state: Dictionary) -> Dictionary:
	var f: Dictionary = state.get("flow", {})
	if f.is_empty():
		return {"end": true}
	var turns: Array = f["list"]
	while true:
		f["i"] = int(f["i"]) + 1
		if int(f["i"]) >= turns.size():
			return {"end": true}
		var e: Dictionary = turns[int(f["i"])]
		if bool(e["boss"]) or _can_play(state, e):
			return e
	return {"end": true}


# Azione dell'eroe di turno (come SeqRound.player_action). Se guadagna SLANCIO, l'azione rapida entra subito dopo nella lista.
static func player_action(state: Dictionary, pid: String, choice: Dictionary, quick: bool = false) -> Array:
	var ev: Array = SeqRound.player_action(state, pid, choice, quick)
	var f: Dictionary = state.get("flow", {})
	if not f.is_empty():
		for x in ev:
			if str(x.get("t", "")) == "slancio":
				(f["list"] as Array).insert(int(f["i"]) + 1, {"unit": str(x["unit"]), "player": str(x["player"]), "boss": false, "spd": -1, "extra": true, "quick": true})
	return ev


# Lista dei turni del round (per mostrarla) e posizione del turno attuale (-1 prima del primo).
static func turns(state: Dictionary) -> Array:
	return state.get("flow", {}).get("list", [])


static func index(state: Dictionary) -> int:
	return int(state.get("flow", {}).get("i", -1))


static func _can_play(state: Dictionary, e: Dictionary) -> bool:
	var pl: Dictionary = BattleState.player(state, str(e["player"]))
	if pl.is_empty() or not BattleState.player_alive(state, pl):
		return false
	if bool(e.get("quick", false)):
		return true
	var u: Dictionary = BattleState.active_unit(state, str(e["player"]))
	return not DuoTechs.spent(state, str(u.get("id", "")))
