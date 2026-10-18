class_name BattleNet
extends RefCounted

# Funzioni di supporto per la battaglia in rete (nuovo motore).
# Sono statiche e senza rete, cosi' si provano nei test.


# Stato come lo puo' vedere un singolo giocatore.
# Tolti:
#   - seed e stato dell'RNG: con quelli si potrebbero prevedere i bersagli del boss;
#   - le scelte degli altri durante la pianificazione (resta solo "bloccata");
#   - gli eventi dell'ultimo round: arrivano gia' col messaggio "battle_events",
#     ripeterli in ogni snapshot raddoppierebbe i dati inviati.
# viewer_id vuoto = spettatore: non vede nessuna scelta.
static func snapshot_for(state: Dictionary, viewer_id: String) -> Dictionary:
	var data: Dictionary = state.duplicate(true)
	data["events"] = []
	data["rng_seed"] = "0"
	data["rng_state"] = "0"
	for p in data.get("players", []):
		if str(p["id"]) == viewer_id:
			continue
		if p.get("choice") != null:
			p["choice"] = {"locked": true}
	return data


static func set_player_ai(state: Dictionary, player_id: String, ai: bool) -> bool:
	if state.is_empty():
		return false
	var p: Dictionary = BattleState.player(state, player_id)
	if p.is_empty():
		return false
	p["ai"] = ai
	return true


# Legge la squadra ricevuta in un messaggio "hello".
# Ritorna {"ok": bool, "team": Array, "error": String}.
# Senza squadra (client vecchi) si usa quella di partenza.
static func read_team(message: Dictionary) -> Dictionary:
	if not message.has("team"):
		return {"ok": true, "team": RosterState.team_entries(RosterState.new_roster()), "error": ""}
	var raw: Variant = message["team"]
	if not (raw is Array):
		return {"ok": false, "team": [], "error": "squadra non valida"}
	var team: Array = BattleState.normalize(raw)
	var err: String = RosterState.validate_team(team)
	if err != "":
		return {"ok": false, "team": [], "error": err}
	return {"ok": true, "team": team, "error": ""}


# Scelta pulita da un messaggio di rete: solo i campi attesi, solo stringhe.
static func clean_choice(message: Dictionary) -> Dictionary:
	return {
		"swap": str(message.get("swap", "")),
		"move": str(message.get("move", "")),
		"target": str(message.get("target", "")),
	}
