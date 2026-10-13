class_name BattleNet
extends RefCounted

# Funzioni di supporto per la battaglia in rete (nuovo motore).
# Sono statiche e senza rete, cosi' si provano nei test.


# Stato come lo puo' vedere un singolo giocatore.
# Tolti:
#   - seed e stato dell'RNG: con quelli si potrebbero prevedere i bersagli del boss;
#   - le scelte degli altri durante la pianificazione (resta solo "bloccata").
# viewer_id vuoto = spettatore: non vede nessuna scelta.
static func snapshot_for(state: Dictionary, viewer_id: String) -> Dictionary:
	var data: Dictionary = state.duplicate(true)
	data["rng_seed"] = "0"
	data["rng_state"] = "0"
	for p in data.get("players", []):
		if str(p["id"]) == viewer_id:
			continue
		# le intenzioni dell'IA non sono un segreto: si vedono (servono a capire il turno)
		if p.get("choice") != null and not bool(p.get("ai", false)):
			p["choice"] = {"locked": true}
	return data


static func set_player_ai(state: Dictionary, player_id: String, ai: bool) -> bool:
	if state.is_empty():
		return false
	var p: Dictionary = BattleState.player(state, player_id)
	if p.is_empty():
		return false
	var was_ai: bool = bool(p["ai"])
	p["ai"] = ai
	if was_ai and not ai:
		p["choice"] = null      # chi rientra sceglie lui: la scelta dell'IA non vale
	elif ai and p["choice"] == null and BattleState.player_alive(state, p):
		p["choice"] = BattleAI.choose(state, player_id)
	return true


# Legge la squadra ricevuta in un messaggio "hello".
# Ritorna {"ok": bool, "team": Array, "error": String}.
# Senza squadra (client vecchi) si usa quella di partenza.
static func read_team(message: Dictionary) -> Dictionary:
	if not message.has("team"):
		return {"ok": true, "team": RosterState.team_entries(RosterState.new_roster()).slice(0, BattleTypes.NET_TEAM_SIZE), "error": ""}
	var raw: Variant = message["team"]
	if not (raw is Array):
		return {"ok": false, "team": [], "error": "squadra non valida"}
	var team: Array = BattleState.normalize(raw)
	var err: String = RosterState.validate_team(team)
	if err != "":
		return {"ok": false, "team": [], "error": err}
	return {"ok": true, "team": team.slice(0, BattleTypes.NET_TEAM_SIZE), "error": ""}


# Scelta pulita da un messaggio di rete: solo i campi attesi, solo stringhe.
static func clean_choice(message: Dictionary) -> Dictionary:
	return {
		"swap": str(message.get("swap", "")),
		"move": str(message.get("move", "")),
		"target": str(message.get("target", "")),
	}
