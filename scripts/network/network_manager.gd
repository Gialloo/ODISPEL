class_name NetworkManager
extends Node

signal room_joined
signal player_assigned(player_id: String)
signal snapshot_received
signal round_result_received(events: Array)
signal player_left(player_id: String)
signal network_error(reason: String)
# Battaglia con il nuovo motore (vedi BattleState / BattleNet).
signal battle_updated
signal lobby_updated
signal chat_received(entry: Dictionary)
signal battle_events_received(events: Array)

# Il signaling si è chiuso ma i collegamenti di gioco già aperti continuano.
signal signaling_lost

# Il client riprova a entrare perché l'host non c'è ancora.
signal waiting_for_host(attempt: int)

# Il server gratuito nel cloud può impiegare circa 1 minuto a svegliarsi.
const SIGNALING_CONNECT_TIMEOUT_MSEC: int = 90000
const LINK_OPEN_TIMEOUT_MSEC: int = 20000

var is_host: bool = false
var game: GameState = null
var player_level: int = 1

# Timer di pianificazione: lo fa scorrere solo l'host, e solo se attivato
# (altrimenti scadrebbe mentre si aspetta che entrino i giocatori).
var planning_timer_enabled: bool = false
var local_player_id: String = ""
var my_peer_id: String = ""

# Nuovo motore di battaglia: lo stato completo sta solo sull'host,
# i client ricevono una copia filtrata.
var battle: Dictionary = {}
var battle_time_left: float = 0.0
var battle_planning_seconds: float = 30.0
var battle_timer_enabled: bool = false
var local_team: Array = []          # squadra di chi gioca (host o client)
var lobby: Dictionary = {}           # stato della lobby condivisa (vedi _build_lobby)
var lobby_boss: String = "distributore"
var lobby_tier: int = 0
var lobby_mode: String = "coop"        # "coop" (contro il boss) oppure una modalita' PvP: duel, duo, ffa
var expedition: Dictionary = {}        # SPEDIZIONE cooperativa in corso (la possiede l'host; i client la ricevono con la lobby)
var lobby_balanced: bool = true        # PvP: true = tutti alla pari, false = conta la progressione
var _ready_players: Dictionary = {}  # player_id -> pronto (host)
var _player_teams: Dictionary = {}  # player_id -> squadra validata (host)
var local_profile: Dictionary = {}   # icona e banner di chi gioca qui ({icon, banner}); il nome va a parte
var _player_profiles: Dictionary = {} # player_id -> {icon, banner} (host)
var chat_log: Array = []              # ultimi messaggi: [{id, name, text, icon, banner}]
var _chat_last_ms: Dictionary = {}    # player_id -> ora dell'ultimo messaggio (anti-spam, host)
const CHAT_MAX_LEN: int = 140
const CHAT_KEEP: int = 60
const CHAT_GAP_MS: int = 400
var local_cleared: Dictionary = {}   # boss -> livelli battuti da chi gioca (serve all'host per avvisare chi non ha sbloccato)
var _player_cleared: Dictionary = {} # player_id -> {boss: livelli battuti} (host); manca se il giocatore non l'ha comunicato
var battle_rewards: Dictionary = {}  # premi di chi gioca qui, a battaglia finita
var reward_save_path: String = RosterStore.DEFAULT_PATH
var _battle_boss_id: String = ""
var _battle_seed: int = 0
var _rewards_applied: bool = false

# Token segreto del client: permette di riprendere lo stesso giocatore
# dopo una disconnessione. Si può salvare e reimpostare prima di start_client().
var session_token: String = ""

# Tentativi di ingresso del client se l'host non ha ancora creato la stanza.
var join_retry_limit: int = 15
var join_retry_interval: float = 2.0

var _socket := WebSocketPeer.new()
var _room_id: String = ""
var _display_name: String = ""
var _host_peer_id: String = ""
var _links: Dictionary = {}         # peer_id -> WebRTCLink
var _peer_players: Dictionary = {}  # peer_id -> player_id
var _abandoned_peers: Dictionary = {}  # host: chi ha lasciato la sfida in corso (non riceve piu' gli stati)
var _client_bid: int = 0               # client: identificativo della sfida che si sta guardando
var _ignored_bid: int = -1             # client: sfida lasciata, gli stati in ritardo si ignorano
var _peer_numbers: Dictionary = {}  # peer_id -> numero di peer di gioco
var _player_tokens: Dictionary = {} # token -> player_id (slot riservati)
var _peer_counter: int = 1
var _link_created: Dictionary = {}  # peer_id -> ms di creazione del link

var _shutting_down: bool = false
var _socket_was_open: bool = false
var _signaling_reported: bool = false
var _connect_started_msec: int = 0
var _join_attempts: int = 0
var _join_retry_in: float = -1.0


func start_host(
	host_game: GameState,
	url: String,
	room_id: String,
	display_name: String
) -> bool:
	if host_game == null or host_game.party == null:
		return false

	var players: Array = host_game.party.get_players()

	if players.is_empty():
		return false

	is_host = true
	game = host_game
	local_player_id = (players[0] as PlayerState).id
	_prepare_host_party()
	return _connect(url, room_id, display_name)


func start_client(url: String, room_id: String, display_name: String) -> bool:
	is_host = false

	if session_token.is_empty():
		session_token = Crypto.new().generate_random_bytes(16).hex_encode()

	return _connect(url, room_id, display_name)


func host_submit_action(action_id: String) -> bool:
	if not is_host:
		return false

	return _host_apply_action(local_player_id, action_id)


func submit_action(action_id: String) -> bool:
	if is_host:
		return host_submit_action(action_id)

	var link: WebRTCLink = _links.get(_host_peer_id)

	if link == null:
		return false

	return link.send_message({"type": "action", "action_id": action_id})


# Giocatori umani attualmente collegati (host compreso).
func get_connected_human_count() -> int:
	if game == null or game.party == null:
		return 0

	var count: int = 0

	for player: PlayerState in game.party.get_players():
		if player.connected and not player.controlled_by_ai:
			count += 1

	return count


# Toglie dal party i posti che nessuno ha mai occupato.
# Chi è entrato e poi è uscito resta (può rientrare, nel frattempo gioca l'IA).
func host_remove_unfilled_players() -> int:
	if not is_host or game == null:
		return 0

	var reserved: Array = _player_tokens.values()
	var removed: int = 0

	for player: PlayerState in game.party.get_players():
		if player.id == local_player_id:
			continue

		if player.connected or reserved.has(player.id):
			continue

		if game.party.remove_player(player.id):
			removed += 1

	return removed


# Avvia il combattimento per tutti. Servono l'host e almeno un client.
func host_start_combat(
	boss_id: String,
	boss_name: String,
	boss_hp: int,
	run_seed: int
) -> bool:
	if not is_host or game == null:
		return false

	if boss_id.is_empty() or boss_hp <= 0 or run_seed == 0:
		return false

	if game.combat != null and not game.combat.is_finished():
		return false

	if get_connected_human_count() < 2:
		return false

	host_remove_unfilled_players()

	if not game.setup_run("net_" + str(run_seed), run_seed, "start"):
		return false

	if not game.begin_combat(boss_id, boss_name, boss_hp):
		return false

	set_planning_timer_enabled(true)
	_broadcast_snapshot()
	return true


# Attiva o disattiva il timer dei round. Attivandolo riparte da capo.
func set_planning_timer_enabled(enabled: bool) -> void:
	planning_timer_enabled = enabled

	if (
		enabled
		and game != null
		and game.combat != null
		and game.combat.round_state != null
	):
		game.combat.round_state.begin()


# ---------- Battaglia (nuovo motore) ----------

# Imposta la squadra di chi gioca. Ritorna false se non e' valida.
func set_local_team(entries: Array) -> bool:
	if RosterState.validate_team(entries) != "":
		return false

	var new_team: Array = BattleState.normalize(entries)
	var changed: bool = new_team != local_team
	local_team = new_team

	if is_host and not local_player_id.is_empty():
		_player_teams[local_player_id] = local_team

	if changed:
		_team_changed()

	return true


# La squadra e' cambiata: la lobby lo mostra e chi era pronto deve riconfermare.
func _team_changed() -> void:
	_trace("squadra cambiata: il PRONTO locale si azzera")
	if is_host:
		if not local_player_id.is_empty():
			_ready_players[local_player_id] = false
			_broadcast_lobby()
	else:
		var link: WebRTCLink = _links.get(_host_peer_id)

		if link != null:
			link.send_message({"type": "team", "team": local_team})


# ---------- Lobby condivisa ----------

# Chi e' nella stanza: l'host e chi e' entrato con un proprio token.
func _lobby_player_ids() -> Array:
	var ids: Array = []

	if game == null or game.party == null:
		return ids

	var reserved: Array = _player_tokens.values()

	for player: PlayerState in game.party.get_players():
		if player.id == local_player_id or reserved.has(player.id):
			ids.append(player.id)

	return ids


func _build_lobby() -> Dictionary:
	var players: Array = []

	for id in _lobby_player_ids():
		var player: PlayerState = game.party.get_player_by_id(str(id))

		if player == null:
			continue

		var team: Array = local_team if id == local_player_id else _player_teams.get(id, [])
		var lead: Dictionary = {}

		if not team.is_empty():
			var first: Dictionary = team[0]
			lead = {"char": str(first.get("char", "")), "level": int(first.get("level", 1))}

		players.append({
			"id": str(id),
			"name": player.display_name,
			"connected": player.connected and not player.controlled_by_ai,
			"ready": bool(_ready_players.get(id, false)) and player.connected,
			"host": id == local_player_id,
			"lead": lead,
			"team_size": team.size(),
			"profile": Profile.clean_public(local_profile if id == local_player_id else _player_profiles.get(id, {}))
		})

	return {"players": players, "boss": lobby_boss, "tier": lobby_tier, "mode": lobby_mode, "balanced": lobby_balanced, "exp": expedition}


# Livelli battuti, ripuliti: solo boss noti e numeri tra 0 e il massimo.
static func _clean_cleared(raw: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for id in BattleContent.BOSS_ORDER:
		out[str(id)] = clampi(int(raw.get(str(id), 0)), 0, BattleContent.TIERS.size())
	return out


# Nomi dei giocatori che NON hanno sbloccato il boss/livello scelto (solo l'host ha l'elenco).
# Chi non ha comunicato i progressi non si segnala.
func players_lacking_unlock(boss_id: String, tier: int) -> Array:
	var names: Array = []
	if not is_host or game == null:
		return names
	for id in _lobby_player_ids():
		var cleared: Variant = local_cleared if str(id) == local_player_id else _player_cleared.get(str(id))
		if not (cleared is Dictionary):
			continue
		if not RosterState.is_tier_unlocked({"cleared": cleared}, boss_id, tier):
			var player: PlayerState = game.party.get_player_by_id(str(id))
			if player != null and player.connected:
				names.append(player.display_name)
	return names


# ---------- Chat ----------

# Scrive un messaggio a tutta la stanza (lobby o battaglia).
func send_chat(text: String) -> bool:
	var clean: String = clean_chat_text(text)

	if clean.is_empty():
		return false

	if is_host:
		return _host_chat(local_player_id, clean)

	var link: WebRTCLink = _links.get(_host_peer_id)

	if link == null:
		return false

	return link.send_message({"type": "chat", "text": clean})


static func clean_chat_text(raw: String) -> String:
	var out: String = ""

	for i in raw.length():
		var ch: String = raw[i]
		out += " " if ch.unicode_at(0) < 32 else ch

	return out.strip_edges().substr(0, CHAT_MAX_LEN)


func _host_chat(player_id: String, raw: String) -> bool:
	if game == null:
		return false

	var text: String = clean_chat_text(raw)
	var player: PlayerState = game.party.get_player_by_id(player_id)

	if text.is_empty() or player == null:
		return false

	var now: int = Time.get_ticks_msec()

	if now - int(_chat_last_ms.get(player_id, -100000)) < CHAT_GAP_MS:
		return false

	_chat_last_ms[player_id] = now
	var prof: Dictionary = Profile.clean_public(local_profile if player_id == local_player_id else _player_profiles.get(player_id, {}))
	var entry: Dictionary = {"id": player_id, "name": player.display_name, "text": text, "icon": prof["icon"], "banner": prof["banner"]}
	_store_chat(entry)
	_broadcast({"type": "chat", "entry": entry})
	return true


func _store_chat(entry: Dictionary) -> void:
	if entry.is_empty():
		return

	chat_log.append(entry)

	while chat_log.size() > CHAT_KEEP:
		chat_log.pop_front()

	chat_received.emit(entry)


static func _clean_chat_entry(raw: Dictionary) -> Dictionary:
	var text: String = clean_chat_text(str(raw.get("text", "")))

	if text.is_empty():
		return {}

	var prof: Dictionary = Profile.clean_public(raw)
	return {
		"id": str(raw.get("id", "")).substr(0, 40),
		"name": str(raw.get("name", "")).substr(0, 24),
		"text": text,
		"icon": prof["icon"],
		"banner": prof["banner"]
	}


func refresh_lobby() -> void:
	_broadcast_lobby()


func _broadcast_lobby() -> void:
	if not is_host or game == null:
		return

	lobby = _build_lobby()
	_broadcast({"type": "lobby", "state": lobby})
	lobby_updated.emit()


# C'e' una sfida davvero in corso? Se nessun umano la sta piu' giocando (tutti usciti o caduti) e' un residuo:
# si chiude da sola, cosi' se ne puo' avviare una nuova.
func _battle_in_progress() -> bool:
	if battle.is_empty() or str(battle.get("winner", "")) != "":
		return false

	for p in battle.get("players", []):
		if not bool(p.get("ai", false)):
			return true

	_trace("sfida senza giocatori umani: chiusa")
	battle = {}
	return false


# Traccia di rete nel log del gioco (godot.log): serve a capire dopo cosa e' successo in una stanza.
func _trace(text: String) -> void:
	print("[NET %s %s] %s" % ["HOST" if is_host else "CLIENT", Time.get_time_string_from_system(), text])


# Chi gioca qui segna se e' pronto.
func set_ready(value: bool) -> void:
	_trace("pronto locale -> %s" % str(value))
	if is_host:
		if local_player_id.is_empty():
			return

		_ready_players[local_player_id] = value
		_broadcast_lobby()
	else:
		var link: WebRTCLink = _links.get(_host_peer_id)

		if link != null:
			link.send_message({"type": "ready", "ready": value})


func is_local_ready() -> bool:
	for p in lobby.get("players", []):
		if str(p["id"]) == local_player_id:
			return bool(p["ready"])

	return false


# Solo l'host: sceglie boss e difficolta' per la prossima partita.
func host_set_mission(boss_id: String, tier: int) -> bool:
	if not is_host or not BattleContent.BOSSES.has(boss_id):
		return false

	_trace("missione scelta: %s livello %d (tutti i PRONTO azzerati)" % [boss_id, tier])

	lobby_boss = boss_id
	lobby_tier = clampi(tier, 0, BattleContent.TIERS.size() - 1)

	for id in _ready_players.keys():
		_ready_players[id] = false

	_broadcast_lobby()
	return true


# Solo l'host: sceglie co-op o una modalita' PvP, e se la sfida e' bilanciata.
func host_set_mode(mode: String, balanced: bool) -> bool:
	if not is_host or not (mode == "coop" or PvpEngine.MODES.has(mode)):
		return false

	_trace("modalita' scelta: %s bilanciato=%s (tutti i PRONTO azzerati)" % [mode, str(balanced)])
	lobby_mode = mode
	lobby_balanced = balanced

	for id in _ready_players.keys():
		_ready_players[id] = false

	_broadcast_lobby()
	return true


# Tutti i giocatori collegati hanno premuto PRONTO (e sono almeno 2).
func all_ready() -> bool:
	if not is_host or game == null:
		return false

	var humans: int = 0

	for p in _build_lobby()["players"]:
		if not bool(p["connected"]):
			continue

		humans += 1

		if not bool(p["ready"]):
			return false

	if lobby_mode != "coop" and humans > PvpEngine.seats(lobby_mode).y:
		return false

	return humans >= 2


# Perche' non si puo' ancora partire (testo per l'host).
func start_problem() -> String:
	if lobby_mode != "coop":
		var humans: int = 0

		for p in _build_lobby()["players"]:
			if bool(p["connected"]):
				humans += 1

		var most: int = PvpEngine.seats(lobby_mode).y

		if humans > most:
			return "Troppi giocatori per questa modalita': massimo %d." % most

	return "Servono almeno 2 giocatori e tutti PRONTI."


# ---------- SPEDIZIONE cooperativa ----------

# La spedizione in corso, vista da chiunque (host o client).
func exp_run() -> Dictionary:
	if is_host:
		return expedition
	var raw: Variant = lobby.get("exp", {})
	return raw if raw is Dictionary else {}


# Solo l'host: inizia una nuova spedizione per tutta la stanza.
func host_exp_new(boss_id: String, tier: int, long: bool = false, mods: Array = []) -> bool:
	if not is_host or not BattleContent.BOSSES.has(boss_id) or _battle_in_progress():
		return false

	if not expedition.is_empty() and str(expedition.get("phase", "")) != "done":
		return false

	expedition = Expedition.new_run(int(randi()) | 1, boss_id, tier, true, long, mods)
	_broadcast_lobby()
	return true


# Solo l'host: chiude la spedizione (anche a meta').
func host_exp_close() -> void:
	if not is_host:
		return

	expedition = {}
	_broadcast_lobby()


func exp_vote(option_id: String) -> bool:
	if is_host:
		return exp_vote_as(local_player_id, option_id)

	var link: WebRTCLink = _links.get(_host_peer_id)

	if link == null:
		return false

	return link.send_message({"type": "exp_vote", "option": option_id})


func exp_vote_as(player_id: String, option_id: String) -> bool:
	if not is_host or expedition.is_empty() or not Expedition.vote(expedition, player_id, option_id):
		return false

	_broadcast_lobby()
	return true


# Solo l'host: chiude la votazione (maggioranza; in pareggio vale il voto dell'host) e applica la scelta.
func host_exp_confirm() -> bool:
	if not is_host or expedition.is_empty():
		return false

	var k: String = Expedition.kind(expedition)

	if not ["path", "event", "cross", "boon"].has(k):
		return false

	var winner: String = Expedition.winner_of_votes(expedition, local_player_id)

	if Expedition.choose(expedition, winner) != "":
		return false

	_broadcast_lobby()
	return true


# Solo l'host: avvia il combattimento della tappa corrente.
func host_exp_fight() -> bool:
	if not is_host or expedition.is_empty() or Expedition.kind(expedition) != "fight":
		return false

	var bp: Dictionary = Expedition.battle_params(expedition)
	return host_start_battle(str(bp["boss"]), int(randi()) | 1, int(bp["tier"]), expedition)


# Fine di un combattimento della spedizione: l'host aggiorna la run una sola volta e la manda a tutti.
func _expedition_after_battle() -> void:
	if not is_host or expedition.is_empty() or battle.is_empty() or not battle.has("expedition"):
		return

	if str(battle.get("winner", "")) == "" or str(expedition.get("phase", "")) != "battle":
		return

	Expedition.after_battle(expedition, battle)
	_broadcast_lobby()


# Solo l'host: parte con la missione della lobby, se tutti sono pronti.
func host_launch() -> bool:
	if not all_ready():
		_trace("avvio rifiutato: %s" % start_problem())
		return false

	_trace("avvio partita: modalita' %s, boss %s livello %d" % [lobby_mode, lobby_boss, lobby_tier])

	if lobby_mode != "coop":
		return host_start_pvp(lobby_mode, lobby_balanced, int(randi()) | 1)

	return host_start_battle(lobby_boss, int(randi()) | 1, lobby_tier)


# Avvia una sfida PvP. I posti vuoti li riempie l'IA con la squadra dell'host.
# 1v1: 2 umani. 2v2: 2-4 umani (gli altri posti IA). Tutti contro tutti: 2-4 umani (almeno 3 posti).
func host_start_pvp(mode: String, balanced: bool, run_seed: int) -> bool:
	if not is_host or game == null or run_seed == 0 or not PvpEngine.MODES.has(mode):
		return false

	if _battle_in_progress():
		return false

	var seats: Vector2i = PvpEngine.seats(mode)
	var humans: Array = []

	for player: PlayerState in game.party.get_players():
		if player.connected and not player.controlled_by_ai:
			humans.append(player)

	if humans.size() < 2 or humans.size() > seats.y:
		return false

	host_remove_unfilled_players()

	if not local_team.is_empty() and not local_player_id.is_empty():
		_player_teams[local_player_id] = local_team

	var specs: Array = []
	var fallback: Array = local_team if not local_team.is_empty() else RosterState.team_entries(RosterState.new_roster())

	for player: PlayerState in humans:
		var team: Array = _player_teams.get(player.id, [])

		if team.is_empty():
			team = fallback

		specs.append({"id": player.id, "name": player.display_name, "ai": false, "team": team})

	var fill: int = 1

	while specs.size() < seats.x:
		specs.append({"id": "ia_%d" % fill, "name": "IA %d" % fill, "ai": true, "team": fallback})
		fill += 1

	battle = PvpEngine.create(specs, mode, balanced, run_seed)
	for id in _ready_players.keys():
		_ready_players[id] = false

	_abandoned_peers.clear()
	_battle_boss_id = ""
	_battle_seed = run_seed
	battle_rewards = {}
	_rewards_applied = false
	battle_time_left = battle_planning_seconds
	battle_timer_enabled = true
	_broadcast_battle()
	battle_updated.emit()
	_broadcast_lobby()
	return true


# Avvia la battaglia per tutti. Servono l'host e almeno un client.
func host_start_battle(boss_id: String, run_seed: int, tier: int = 0, exp_run: Dictionary = {}) -> bool:
	if not is_host or game == null or run_seed == 0:
		return false

	if not BattleContent.BOSSES.has(boss_id):
		return false

	if _battle_in_progress():
		return false

	if get_connected_human_count() < 2:
		return false

	host_remove_unfilled_players()

	if not local_team.is_empty() and not local_player_id.is_empty():
		_player_teams[local_player_id] = local_team

	var specs: Array = []

	for player: PlayerState in game.party.get_players():
		var team: Array = _player_teams.get(player.id, [])

		if team.is_empty():
			team = RosterState.team_entries(RosterState.new_roster())

		specs.append({
			"id": player.id,
			"name": player.display_name,
			"ai": not player.connected or player.controlled_by_ai,
			"team": team
		})

	battle = BattleState.create(specs, boss_id, run_seed, tier)

	if not exp_run.is_empty():
		Expedition.apply_to_battle(exp_run, battle)

	for id in _ready_players.keys():
		_ready_players[id] = false

	_abandoned_peers.clear()
	_battle_boss_id = boss_id
	_battle_seed = run_seed
	battle_rewards = {}
	_rewards_applied = false
	battle_time_left = battle_planning_seconds
	battle_timer_enabled = true
	_broadcast_battle()
	battle_updated.emit()
	_broadcast_lobby()
	return true


# Invia la scelta di chi gioca qui (host o client).
func submit_choice(choice: Dictionary) -> bool:
	if is_host:
		return _host_apply_choice(local_player_id, BattleNet.clean_choice(choice))

	var link: WebRTCLink = _links.get(_host_peer_id)

	if link == null:
		return false

	var message: Dictionary = BattleNet.clean_choice(choice)
	message["type"] = "choice"
	return link.send_message(message)


func _host_apply_choice(player_id: String, choice: Dictionary) -> bool:
	if battle.is_empty():
		return false

	if bool(battle.get("pvp", false)):
		if not PvpEngine.submit_choice(battle, player_id, choice):
			return false

		if PvpEngine.can_resolve(battle):
			_battle_resolve(false)
		else:
			_broadcast_battle()
			battle_updated.emit()

		return true

	if not BattleResolver.submit_choice(battle, player_id, choice):
		return false

	if BattleResolver.can_resolve(battle):
		_battle_resolve(false)
	else:
		_broadcast_battle()
		battle_updated.emit()

	return true


func _battle_try_resolve() -> void:
	if battle.is_empty():
		return

	if bool(battle.get("pvp", false)):
		if PvpEngine.can_resolve(battle):
			_battle_resolve(false)

		return

	if BattleResolver.can_resolve(battle):
		_battle_resolve(false)


func _battle_resolve(force: bool) -> void:
	var events: Array = PvpEngine.resolve_round(battle, force) if bool(battle.get("pvp", false)) else BattleResolver.resolve_round(battle, force)
	_expedition_after_battle()
	battle_time_left = battle_planning_seconds
	_broadcast({"type": "battle_events", "events": events})
	battle_events_received.emit(events)
	_broadcast_battle()
	battle_updated.emit()


func _broadcast_battle() -> void:
	# A battaglia finita ognuno riceve dall'host i propri premi (il client non
	# conosce il seed, quindi non potrebbe calcolarli ne' falsificarli).
	var all_rewards: Dictionary = {}

	if str(battle.get("winner", "")) != "" and bool(battle.get("pvp", false)):
		all_rewards = PvpRewards.for_battle(battle, _battle_seed)
		battle_rewards = all_rewards.get(local_player_id, {})

	if str(battle.get("winner", "")) != "" and not bool(battle.get("pvp", false)) and Expedition.pays_rewards(battle):
		all_rewards = BattleRewards.for_battle(battle, _battle_boss_id, _battle_seed)
		battle_rewards = all_rewards.get(local_player_id, {})

	for peer_id: String in _links.keys():
		var link: WebRTCLink = _links[peer_id]
		if _abandoned_peers.has(peer_id):
			continue

		var viewer_id: String = str(_peer_players.get(peer_id, ""))

		var message: Dictionary = {
			"type": "battle_snapshot",
			"state": BattleNet.snapshot_for(battle, viewer_id),
			"time_left": battle_time_left,
			"bid": _battle_seed
		}

		if not all_rewards.is_empty():
			message["rewards"] = all_rewards.get(viewer_id, {})

		link.send_message(message)


# Chi esce da una sfida a meta' (tasto ESCI/Abbandona). L'host chiude la sfida per tutti; un client esce
# e al suo posto gioca l'IA. In entrambi i casi la sfida lasciata non riporta piu' dentro chi e' uscito.
func abandon_battle() -> void:
	_trace("abbandono della sfida")

	if battle.is_empty() or str(battle.get("winner", "")) != "":
		return

	if is_host:
		battle = {}
		_abandoned_peers.clear()
		_broadcast({"type": "battle_aborted"})
		_broadcast_lobby()
		return

	var link: WebRTCLink = _links.get(_host_peer_id)
	_ignored_bid = _client_bid
	battle = {}

	if link != null:
		link.send_message({"type": "abandon"})


# A battaglia finita: assegna i premi alla collezione locale e la salva. Una volta sola.
func finish() -> Dictionary:
	if _rewards_applied or battle.is_empty() or str(battle.get("winner", "")) == "":
		return battle_rewards

	if bool(battle.get("pvp", false)):
		_rewards_applied = true
		var proster: Dictionary = RosterStore.load_or_new(reward_save_path)
		RosterState.apply_rewards(proster, battle_rewards)
		var winner: String = str(battle["winner"])
		var mine: Dictionary = PvpEngine.player(battle, local_player_id)
		var won: bool = winner != "draw" and str(mine.get("team", "")) == winner
		Feats.record_pvp(proster, won)
		RosterStore.save(proster, reward_save_path)
		return battle_rewards

	_rewards_applied = true
	var roster: Dictionary = RosterStore.load_or_new(reward_save_path)
	RosterState.apply_rewards(roster, battle_rewards)

	if str(battle["winner"]) == "players":
		var boss_id: String = str(BattleState.boss(battle)["char"])
		var tier: int = int(battle.get("tier", 0))

		if Expedition.pays_rewards(battle) and RosterState.mark_cleared(roster, boss_id, tier):
			for line in RosterState.unlock_news(boss_id, tier):
				Notify.success(line)

	Feats.record_battle(roster, str(battle["winner"]) == "players")
	for line in Discoveries.record(roster, str(BattleState.boss(battle)["char"]), str(battle["winner"]) == "players", battle.get("stats", {})):
		Notify.success(line)
	for line in Extras.record_mastery(roster, battle.get("stats", {})):
		Notify.success(line)
	Extras.record_result(roster, str(battle["winner"]) == "players")
	for line in Objectives.record_battle(roster, str(BattleState.boss(battle)["char"]), int(battle.get("tier", 0)), str(battle["winner"]) == "players", "", battle.get("stats", {})):
		Notify.success(line)

	RosterStore.save(roster, reward_save_path)
	return battle_rewards


func _tick_battle_timer(delta: float) -> void:
	if battle.is_empty() or str(battle["winner"]) != "":
		return

	battle_time_left = maxf(0.0, battle_time_left - delta)

	# Solo l'host decide: scaduto il tempo, chi non ha scelto attacca.
	if is_host and battle_timer_enabled and battle_time_left <= 0.0:
		_battle_resolve(true)


func shutdown() -> void:
	# Prima il flag: la chiusura volontaria non è un errore.
	_shutting_down = true

	for link: WebRTCLink in _links.values():
		link.close()

	_links.clear()
	_link_created.clear()
	_socket.close()


func _connect(url: String, room_id: String, display_name: String) -> bool:
	_room_id = room_id
	_display_name = display_name
	_shutting_down = false
	_socket_was_open = false
	_signaling_reported = false
	_join_attempts = 0
	_join_retry_in = -1.0
	_connect_started_msec = Time.get_ticks_msec()
	return _socket.connect_to_url(url) == OK


func _process(delta: float) -> void:
	if _shutting_down:
		return

	_socket.poll()
	_check_signaling_state(Time.get_ticks_msec())
	_tick_join_retry(delta)

	while _socket.get_available_packet_count() > 0:
		var data: Variant = WebRTCLink.parse_json(
			_socket.get_packet().get_string_from_utf8()
		)

		if data is Dictionary:
			_handle_signaling(data)

	for link: WebRTCLink in _links.values():
		link.poll()

	_check_link_timeouts(Time.get_ticks_msec())
	_tick_planning_timer(delta)
	_tick_battle_timer(delta)


func _send_join() -> void:
	if _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return

	_socket.send_text(JSON.stringify({
		"type": "join",
		"room_id": _room_id,
		"role": "host" if is_host else "client"
	}))


func _tick_join_retry(delta: float) -> void:
	if _join_retry_in < 0.0:
		return

	_join_retry_in -= delta

	if _join_retry_in <= 0.0:
		_join_retry_in = -1.0
		_send_join()


# Controlla la connessione al server di signaling.
func _check_signaling_state(now_msec: int) -> void:
	if _signaling_reported:
		return

	var state: int = _socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		_socket_was_open = true
		return

	if state == WebSocketPeer.STATE_CONNECTING:
		if now_msec - _connect_started_msec >= SIGNALING_CONNECT_TIMEOUT_MSEC:
			_signaling_reported = true
			_socket.close()
			network_error.emit("signaling non raggiungibile")

		return

	if state != WebSocketPeer.STATE_CLOSED:
		return

	if _connect_started_msec == 0:
		return

	_signaling_reported = true

	if not _socket_was_open:
		network_error.emit("signaling non raggiungibile")
		return

	# I collegamenti già aperti continuano a funzionare senza signaling.
	if _has_open_game_link():
		signaling_lost.emit()
	else:
		network_error.emit("signaling disconnesso")


func _has_open_game_link() -> bool:
	for link: WebRTCLink in _links.values():
		if link.has_been_open():
			return true

	return false


# Un collegamento che non si apre entro il tempo limite viene abbandonato.
func _check_link_timeouts(now_msec: int) -> void:
	for peer_id: String in _link_created.keys():
		var link: WebRTCLink = _links.get(peer_id)

		if link == null:
			_link_created.erase(peer_id)
			continue

		if link.has_been_open():
			_link_created.erase(peer_id)
			continue

		if now_msec - int(_link_created[peer_id]) < LINK_OPEN_TIMEOUT_MSEC:
			continue

		_link_created.erase(peer_id)

		if is_host:
			_drop_peer(peer_id)
		else:
			network_error.emit("connessione con l'host non riuscita (rete troppo restrittiva? vedi docs/PROVA_ONLINE.md)")


func _handle_signaling(data: Dictionary) -> void:
	match str(data.get("type", "")):
		"connected":
			_send_join()

		"joined":
			my_peer_id = str(data.get("peer_id", ""))
			_join_attempts = 0
			_join_retry_in = -1.0

			if not is_host:
				# È il server a dire chi è l'host della stanza.
				_host_peer_id = str(data.get("host_peer_id", ""))

				if _host_peer_id.is_empty():
					network_error.emit("nessun host nella stanza")
					return

				_create_link(_host_peer_id, false)

			room_joined.emit()

		"peer_joined":
			if is_host:
				var new_peer: String = str(data.get("peer_id", ""))
				_create_link(new_peer, true)
				(_links[new_peer] as WebRTCLink).start()

		"peer_left":
			# Il server lo manda solo all'host, quando esce un client.
			if is_host:
				_drop_peer(str(data.get("peer_id", "")))

		"room_closed":
			# L'host è uscito: il server ha chiuso la stanza.
			if not is_host:
				network_error.emit("host disconnesso")

		"offer", "answer", "ice_candidate":
			var from_peer: String = str(data.get("from_peer_id", ""))
			var payload: Variant = data.get("payload", {})
			var link: WebRTCLink = _links.get(from_peer)

			if link != null and payload is Dictionary:
				link.handle_signal(str(data["type"]), payload)

		"error":
			match str(data.get("code", "?")):
				"no_host":
					_on_no_host()
				"room_taken":
					network_error.emit("stanza già occupata: l'host deve crearla")
				"server_full":
					network_error.emit("il server e' pieno: riprova tra qualche minuto")
				"rate_limited":
					network_error.emit("troppi messaggi al server: riprova")
				"join_timeout":
					network_error.emit("sei rimasto troppo tempo senza entrare in una stanza")
				var code:
					network_error.emit("signaling: " + code)


# L'host potrebbe non aver ancora creato la stanza: il client riprova.
func _on_no_host() -> void:
	if not is_host and _join_attempts < join_retry_limit:
		_join_attempts += 1
		_join_retry_in = join_retry_interval
		waiting_for_host.emit(_join_attempts)
		return

	network_error.emit("nessun host nella stanza")


func _create_link(peer_id: String, initiator: bool) -> void:
	var link := WebRTCLink.new()

	if not link.setup(initiator):
		network_error.emit("setup WebRTC fallito")
		return

	link.outgoing_signal.connect(_on_link_signal.bind(peer_id))
	link.channel_opened.connect(_on_link_opened.bind(peer_id))
	link.channel_closed.connect(_on_link_closed.bind(peer_id))
	link.message_received.connect(_on_link_message.bind(peer_id))
	_links[peer_id] = link
	_link_created[peer_id] = Time.get_ticks_msec()


func _on_link_signal(type: String, payload: Dictionary, peer_id: String) -> void:
	if _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return

	_socket.send_text(JSON.stringify({
		"type": type,
		"target_peer_id": peer_id,
		"payload": payload
	}))


func _on_link_opened(peer_id: String) -> void:
	if not is_host:
		var link: WebRTCLink = _links.get(peer_id)

		if link != null:
			link.send_message({
				"type": "hello",
				"name": _display_name,
				"token": session_token,
				"version": GameConfig.VERSION,
				"team": local_team,
				"cleared": local_cleared,
				"profile": Profile.clean_public(local_profile)
			})


func _on_link_closed(peer_id: String) -> void:
	if _shutting_down:
		return

	if is_host:
		_drop_peer(peer_id)
	else:
		network_error.emit("collegamento con l'host chiuso")


func _on_link_message(message: Dictionary, peer_id: String) -> void:
	if is_host:
		_host_handle_message(message, peer_id)
	else:
		_client_handle_message(message)


# ---------- HOST ----------

func _host_handle_message(message: Dictionary, peer_id: String) -> void:
	match str(message.get("type", "")):
		"hello":
			_host_handle_hello(peer_id, message)

		"chat":
			var talker: String = str(_peer_players.get(peer_id, ""))

			if not talker.is_empty():
				_host_chat(talker, str(message.get("text", "")))

		"ready":
			var who: String = str(_peer_players.get(peer_id, ""))

			_trace("pronto ricevuto da %s (%s): %s" % [peer_id, who, str(message.get("ready", false))])

			if not who.is_empty():
				_ready_players[who] = bool(message.get("ready", false))
				_broadcast_lobby()

		"team":
			var owner_id: String = str(_peer_players.get(peer_id, ""))
			var checked: Dictionary = BattleNet.read_team(message)
			_trace("squadra ricevuta da %s: valida=%s (il suo PRONTO si azzera)" % [owner_id, str(checked["ok"])])

			if not owner_id.is_empty() and bool(checked["ok"]):
				_player_teams[owner_id] = checked["team"]
				_ready_players[owner_id] = false
				_broadcast_lobby()

		"exp_vote":
			var voter: String = str(_peer_players.get(peer_id, ""))

			if not voter.is_empty():
				exp_vote_as(voter, str(message.get("option", "")))

		"abandon":
			var leaver: String = str(_peer_players.get(peer_id, ""))

			if not leaver.is_empty() and not battle.is_empty():
				_abandoned_peers[peer_id] = true
				BattleNet.set_player_ai(battle, leaver, true)
				_ready_players[leaver] = false
				_battle_try_resolve()
				_broadcast_battle()
				battle_updated.emit()
				_broadcast_lobby()

		"choice":
			var chooser: String = str(_peer_players.get(peer_id, ""))

			if not chooser.is_empty():
				_host_apply_choice(chooser, BattleNet.clean_choice(message))

		"action":
			var player_id: String = str(_peer_players.get(peer_id, ""))

			if player_id.is_empty():
				return

			_host_apply_action(player_id, str(message.get("action_id", "")))


func _host_apply_action(player_id: String, action_id: String) -> bool:
	if not CombatResolver.submit_action(game, player_id, action_id):
		return false

	_host_try_resolve()
	_broadcast_snapshot()
	return true


func _host_try_resolve() -> void:
	if not CombatResolver.can_resolve(game):
		return

	_host_publish_round(CombatResolver.resolve_round(game, player_level))


func _host_publish_round(result: Dictionary) -> void:
	if result["ok"]:
		_broadcast({"type": "round_result", "events": result["events"]})
		round_result_received.emit(result["events"])


# Scaduto il tempo: chi non ha scelto attacca in automatico.
func _host_force_resolve() -> void:
	if not CombatResolver.can_force_resolve(game):
		return

	_host_publish_round(CombatResolver.resolve_round(game, player_level, true))
	_broadcast_snapshot()


func _tick_planning_timer(delta: float) -> void:
	if game == null or game.combat == null:
		return

	var combat: CombatState = game.combat

	if combat.phase != CombatState.Phase.PLANNING or combat.round_state == null:
		return

	if not is_host:
		# Solo per mostrare il conto alla rovescia: l'host resta l'autorità
		# e lo snapshot successivo corregge il valore.
		combat.update_planning_timer(delta)
		return

	if not planning_timer_enabled:
		return

	combat.update_planning_timer(delta)

	if combat.round_state.is_planning_finished():
		_host_force_resolve()


func _host_handle_hello(peer_id: String, message: Dictionary) -> void:
	if _peer_players.has(peer_id):
		return

	var link: WebRTCLink = _links.get(peer_id)

	if link == null:
		return

	if str(message.get("version", "")) != GameConfig.VERSION:
		link.send_message({
			"type": "error",
			"code": "version_mismatch",
			"host_version": GameConfig.VERSION
		})
		return

	var token: String = str(message.get("token", "")).strip_edges()

	if token.is_empty() or token.length() > 64:
		link.send_message({"type": "error", "code": "invalid_token"})
		return

	var team_result: Dictionary = BattleNet.read_team(message)

	if not bool(team_result["ok"]):
		link.send_message({"type": "error", "code": "invalid_team", "detail": str(team_result["error"])})
		return

	var player: PlayerState = null

	if _player_tokens.has(token):
		# Rientro: lo stesso token riprende lo stesso giocatore.
		player = game.party.get_player_by_id(str(_player_tokens[token]))

		if player == null:
			link.send_message({"type": "error", "code": "join_failed"})
			return

		# Se un vecchio collegamento è ancora aperto, il nuovo lo sostituisce.
		var old_peer: String = _peer_for_player(player.id)

		if not old_peer.is_empty() and old_peer != peer_id:
			_drop_peer(old_peer, false)
	else:
		if not _is_joining_open():
			link.send_message({"type": "error", "code": "game_in_progress"})
			return

		player = _find_free_player()

		if player == null:
			link.send_message({"type": "error", "code": "room_full"})
			return

	var peer_number: int = _allocate_peer_number()

	if not game.party.reconnect_player(player.id, peer_number):
		link.send_message({"type": "error", "code": "join_failed"})
		return

	var wanted_name: String = str(message.get("name", "")).strip_edges()

	if not wanted_name.is_empty():
		player.display_name = wanted_name.substr(0, 24)

	_peer_players[peer_id] = player.id
	_peer_numbers[peer_id] = peer_number
	_player_tokens[token] = player.id
	_player_teams[player.id] = team_result["team"]
	_player_profiles[player.id] = Profile.clean_public(message.get("profile"))
	if message.get("cleared") is Dictionary:
		_player_cleared[player.id] = _clean_cleared(message["cleared"])
	else:
		_player_cleared.erase(player.id)

	# Rientro a battaglia in corso: torna a comandare lui al posto dell'IA.
	BattleNet.set_player_ai(battle, player.id, false)

	_ready_players[player.id] = false
	_trace("ingresso/rientro di %s (%s): PRONTO azzerato" % [player.id, player.display_name])

	link.send_message({"type": "welcome", "player_id": player.id})
	player_assigned.emit(player.id)
	_broadcast_snapshot()
	_broadcast_lobby()


# Gli slot non ancora occupati da un giocatore reale non devono
# bloccare il round: si segnano come disconnessi finché non entra qualcuno.
func _prepare_host_party() -> void:
	var reserved: Array = _player_tokens.values()

	for player: PlayerState in game.party.get_players():
		if player.id != local_player_id and not reserved.has(player.id):
			game.party.disconnect_player(player.id)


# I nuovi giocatori possono entrare solo prima che il combattimento
# superi il primo round. Chi ha già un token può sempre rientrare.
func _is_joining_open() -> bool:
	if not battle.is_empty():
		return false

	if game.combat == null:
		return true

	if game.combat.is_finished():
		return false

	var round_state: RoundState = game.combat.round_state

	return round_state != null and round_state.number <= 1


func _allocate_peer_number() -> int:
	var highest: int = _peer_counter

	for player: PlayerState in game.party.get_players():
		highest = maxi(highest, player.network_peer_id)

	_peer_counter = highest + 1
	return _peer_counter


func _peer_for_player(player_id: String) -> String:
	for peer_id: String in _peer_players:
		if _peer_players[peer_id] == player_id:
			return peer_id

	return ""


func _find_free_player() -> PlayerState:
	var taken: Array = _peer_players.values()
	var reserved: Array = _player_tokens.values()

	for player: PlayerState in game.party.get_players():
		if player.id == local_player_id:
			continue

		if taken.has(player.id) or reserved.has(player.id):
			continue

		return player

	return null


# notify = false: sostituzione silenziosa (il giocatore rientra subito),
# senza segnarlo disconnesso né risolvere il round.
func _drop_peer(peer_id: String, notify: bool = true) -> void:
	if not _links.has(peer_id):
		return

	var link: WebRTCLink = _links[peer_id]
	_links.erase(peer_id)
	_link_created.erase(peer_id)
	_peer_numbers.erase(peer_id)
	link.close()

	if not _peer_players.has(peer_id):
		return

	var player_id: String = _peer_players[peer_id]
	_peer_players.erase(peer_id)
	_trace("collegamento perso con %s (%s) notifica=%s" % [peer_id, player_id, str(notify)])

	if not notify:
		return

	# Passa dal party, così anche lo slot resta coerente con il giocatore.
	game.party.disconnect_player(player_id)

	# In battaglia gioca l'IA al posto suo finche' non rientra.
	BattleNet.set_player_ai(battle, player_id, true)

	_ready_players[player_id] = false

	player_left.emit(player_id)
	_host_try_resolve()
	_battle_try_resolve()
	_broadcast_snapshot()
	_broadcast_lobby()


func _broadcast(message: Dictionary) -> void:
	for link: WebRTCLink in _links.values():
		link.send_message(message)


func _broadcast_snapshot() -> void:
	# Ogni client riceve la sua versione dello stato, senza i segreti.
	for peer_id: String in _links.keys():
		var link: WebRTCLink = _links[peer_id]
		var viewer_id: String = str(_peer_players.get(peer_id, ""))

		link.send_message({
			"type": "snapshot",
			"state": build_snapshot_for(game, viewer_id)
		})

	if not battle.is_empty():
		_broadcast_battle()

	snapshot_received.emit()


# Stato di gioco come lo può vedere un singolo giocatore.
# Tolti (l'host ha lo stato completo):
#   - seed dell'RNG e stato del generatore: con quelli un client modificato
#     potrebbe prevedere i bersagli del boss;
#   - le azioni scelte dagli altri giocatori durante la pianificazione
#     (resta visibile solo che hanno "bloccato" la scelta).
# L'identificativo vuoto vale per chi non ha ancora un giocatore assegnato.
static func build_snapshot_for(
	game_state: GameState,
	viewer_player_id: String
) -> Dictionary:
	var data: Dictionary = game_state.to_dictionary()

	var run_data: Variant = data.get("run", {})

	if run_data is Dictionary and not run_data.is_empty():
		run_data["seed"] = "0"

	var combat_data: Variant = data.get("combat", {})

	if not (combat_data is Dictionary) or combat_data.is_empty():
		return data

	combat_data["rng"] = {}

	if int(combat_data.get("phase", -1)) != int(CombatState.Phase.PLANNING):
		return data

	var party_data: Variant = data.get("party", {})

	if not (party_data is Dictionary):
		return data

	for slot_data in party_data.get("slots", []):
		var player_data: Variant = slot_data.get("player_data", {})

		if not (player_data is Dictionary) or player_data.is_empty():
			continue

		if str(player_data.get("id", "")) != viewer_player_id:
			player_data["selected_action_id"] = ""

	return data


# ---------- CLIENT ----------

func _client_handle_message(message: Dictionary) -> void:
	match str(message.get("type", "")):
		"welcome":
			local_player_id = str(message.get("player_id", ""))
			player_assigned.emit(local_player_id)

		"snapshot":
			var state: Variant = message.get("state", {})

			if state is Dictionary:
				if game == null:
					game = GameState.new()

				game.apply_dictionary(state)
				snapshot_received.emit()

		"battle_snapshot":
			var bstate: Variant = message.get("state", {})

			var bid: int = int(message.get("bid", 0))

			if bid != 0 and bid == _ignored_bid:
				return

			if bstate is Dictionary and not bstate.is_empty():
				var checked: String = BattleState.validate(BattleState.normalize(bstate))
				if checked != "":
					Notify.warning("Stato della sfida non valido (%s) Ignorato." % checked)
					return
				_client_bid = bid
				battle = BattleState.normalize(bstate)
				battle_time_left = float(message.get("time_left", 0.0))

				var rewards: Variant = message.get("rewards", null)

				if rewards is Dictionary:
					battle_rewards = BattleState.normalize(rewards)

				battle_updated.emit()

		"battle_aborted":
			battle = {}
			Notify.warning("L'host ha chiuso la sfida.")
			battle_updated.emit()

		"chat":
			var centry: Variant = message.get("entry", {})

			if centry is Dictionary:
				_store_chat(_clean_chat_entry(centry))

		"lobby":
			var lstate: Variant = message.get("state", {})

			if lstate is Dictionary:
				lobby = BattleState.normalize(lstate)
				lobby_updated.emit()

		"battle_events":
			var bevents: Variant = message.get("events", [])

			if bevents is Array:
				battle_events_received.emit(BattleState.normalize(bevents))

		"round_result":
			var events: Variant = message.get("events", [])

			if events is Array:
				round_result_received.emit(events)

		"error":
			var code: String = str(message.get("code", "?"))

			if code == "invalid_team":
				network_error.emit("squadra non valida: " + str(message.get("detail", "")))
			elif code == "version_mismatch":
				network_error.emit(
					"versione del gioco diversa: l'host usa la %s, tu la %s. Scarica l'ultima versione."
					% [str(message.get("host_version", "?")), GameConfig.VERSION]
				)
			else:
				network_error.emit("host: " + code)
