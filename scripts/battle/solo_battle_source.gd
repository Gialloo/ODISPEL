class_name SoloBattleSource
extends RefCounted

# Sorgente di una battaglia in solitaria: stessa interfaccia che l'interfaccia
# usa per la rete (battle, local_player_id, battle_time_left, segnali, submit_choice).

signal battle_updated
signal battle_events_received(events: Array)

var battle: Dictionary = {}
var local_player_id: String = "p1"
var battle_time_left: float = -1.0     # negativo = nessun timer
var boss_id: String = "distributore"
var tier: int = 0
var endless_floor: int = 0       # > 0: CICLO INFINITO a questo piano
var daily_mod: String = ""       # non vuoto: SFIDA DEL GIORNO con questo modificatore
var weekly: bool = false         # con daily_mod: EVENTO DELLA SETTIMANA
var daily_first: bool = false    # vera se questa vittoria ha pagato il bonus del giorno
var seed_value: int = 1
var roster: Dictionary = {}
var rewards: Dictionary = {}
var save_path: String = RosterStore.DEFAULT_PATH
var _finished: bool = false


func start(new_roster: Dictionary, new_boss_id: String, new_seed: int, new_tier: int = 0) -> void:
	roster = new_roster
	boss_id = new_boss_id
	seed_value = new_seed
	tier = clampi(new_tier, 0, BattleContent.TIERS.size() - 1)
	rewards = {}
	_finished = false
	battle = RosterState.create_solo_battle(roster, "IO", boss_id, seed_value, 0, tier)
	if daily_mod != "":
		Endless.apply(battle, Weekly.FLOOR if weekly else Daily.FLOOR, daily_mod)
	elif endless_floor > 0:
		Endless.apply(battle, endless_floor)
		if endless_floor > 1:
			Endless.apply_boons(battle, MissionConfig.endless_boons)
			Endless.apply_carry(battle, MissionConfig.endless_carry)
	battle_updated.emit()


# Gli slot di front row controllati dal giocatore (in solitaria: tutti, nell'ordine).
func my_slots() -> Array:
	var out: Array = []
	for p in battle.get("players", []):
		if str(p["id"]) == local_player_id or str(p.get("leader", "")) == local_player_id:
			out.append(str(p["id"]))
	return out


# Un solo slot (compatibilita'): gli altri slot ancora liberi li gioca l'IA, poi si risolve il round.
func submit_choice(choice: Dictionary) -> bool:
	if battle.is_empty() or not BattleResolver.submit_choice(battle, local_player_id, choice):
		return false
	for sid in my_slots():
		if sid != local_player_id and not _slot_done(sid):
			_ai_fill(sid)
	return _resolve()


# Tutte le scelte del giocatore insieme: {slot_id: choice}. Gli slot non indicati o non validi li gioca l'IA.
func submit_party(choices: Dictionary) -> bool:
	if battle.is_empty() or str(battle["winner"]) != "":
		return false
	for sid in my_slots():
		var p: Dictionary = BattleState.player(battle, sid)
		if not BattleState.player_alive(battle, p):
			continue
		if choices.has(sid) and BattleResolver.validate_choice(battle, sid, choices[sid]) == "":
			p["choice"] = choices[sid].duplicate(true)
		else:
			_ai_fill(sid)
	return _resolve()


# AUTOPLAY: l'IA gioca da sola tutta la squadra per questo round.
func autoplay_round() -> bool:
	if battle.is_empty() or str(battle["winner"]) != "":
		return false
	for sid in my_slots():
		var p: Dictionary = BattleState.player(battle, sid)
		if BattleState.player_alive(battle, p):
			p["choice"] = null
			_ai_fill(sid)
	return _resolve()


func _slot_done(sid: String) -> bool:
	return BattleState.player(battle, sid).get("choice") != null


func _ai_fill(sid: String) -> void:
	var p: Dictionary = BattleState.player(battle, sid)
	if p.is_empty() or not BattleState.player_alive(battle, p):
		return
	p["choice"] = BattleAI.choose(battle, sid)


func _resolve() -> bool:
	var events: Array = BattleResolver.resolve_round(battle)
	battle_events_received.emit(events)
	battle_updated.emit()
	return true


# A battaglia finita: assegna i premi alla collezione e la salva. Una volta sola.
func finish() -> Dictionary:
	if _finished or str(battle.get("winner", "")) == "":
		return rewards
	_finished = true
	var all: Dictionary = BattleRewards.for_battle(battle, boss_id, seed_value)
	rewards = all.get(local_player_id, {})
	var won: bool = str(battle["winner"]) == "players"
	if endless_floor > 0:
		rewards = Endless.scale_rewards(rewards, endless_floor) if won else rewards
		MissionConfig.endless_carry = Endless.carry_from(battle) if won else {}
		if not won:
			Endless.finish_run(roster, endless_floor - 1)
		if Endless.record(roster, endless_floor, won):
			Notify.success("NUOVO RECORD: PIANO %d" % endless_floor)
	if daily_mod != "" and weekly:
		if won and Weekly.record_event(roster):
			daily_first = true
			rewards = Daily.scale_rewards(rewards, Weekly.reward_mult(roster))
			Notify.success("EVENTO DELLA SETTIMANA SUPERATO · SERIE %d" % Weekly.streak(roster))
	elif daily_mod != "" and won and Daily.record_win(roster):
		daily_first = true
		rewards = Daily.scale_rewards(rewards, Daily.reward_mult(roster))
		Notify.success("SFIDA DEL GIORNO SUPERATA · SERIE %d" % Daily.streak(roster))
	RosterState.apply_rewards(roster, rewards)
	if won and endless_floor == 0 and daily_mod == "":
		if RosterState.mark_cleared(roster, boss_id, tier):
			for line in RosterState.unlock_news(boss_id, tier):
				Notify.success(line)
	if won:
		for line in Weekly.record_win(roster, daily_mod != "" and not weekly and daily_first):
			Notify.success(line)
	for line in Weekly.finish_notes(roster):
		Notify.success(line)
	Feats.record_battle(roster, str(battle["winner"]) == "players")
	for line in Objectives.record_battle(roster, boss_id, tier, str(battle["winner"]) == "players", "", battle.get("stats", {})):
		Notify.success(line)
	RosterStore.save(roster, save_path)
	return rewards
