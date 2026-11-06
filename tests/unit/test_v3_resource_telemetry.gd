extends SceneTree

var fails: int = 0


func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _team() -> Array:
	var team: Array = []
	for id in ["ferri", "nox", "zecca", "saul"]:
		team.append(BattleContent.default_entry(id))
	return team


func _fresh() -> Dictionary:
	return BattleState.create_solo("IO", _team(), [], "semaforo", 17)


func _has_event(events: Array, kind: String) -> Dictionary:
	for e in events:
		if str(e.get("t", "")) == kind:
			return e
	return {}


func _unit_resources() -> void:
	var state: Dictionary = _fresh()
	var u: Dictionary = BattleState.active_unit(state, "p1")      # create_solo da' sempre lo slot "p1": "IO" e' solo il nome
	var events: Array = []
	u["energy"] = 5
	ResourceTelemetry.gain_unit(u, "energy", 3, BattleTypes.MAX_ENERGY, events, "test_gain")
	var gain: Dictionary = _has_event(events, "resource_change")
	check(int(u["energy"]) == BattleTypes.MAX_ENERGY, "il guadagno rispetta il tetto EN")
	check(int(gain.get("requested", -1)) == 3 and int(gain.get("effective", -1)) == 1 and int(gain.get("wasted", -1)) == 2, "il guadagno EN distingue richiesto, effettivo e spreco")
	ResourceTelemetry.spend_unit(u, "energy", 9, events, "test_spend")
	var spend: Dictionary = {}
	for e in events:
		if str(e.get("t", "")) == "resource_change" and str(e.get("source", "")) == "test_spend":
			spend = e
	check(int(u["energy"]) == 0, "la spesa non scende sotto zero")
	check(int(spend.get("requested", -1)) == 9 and int(spend.get("effective", -1)) == BattleTypes.MAX_ENERGY and int(spend.get("wasted", -1)) == 9 - BattleTypes.MAX_ENERGY, "la spesa registra la quota non pagabile")


func _net_snapshot() -> void:
	var state: Dictionary = _fresh()
	var u: Dictionary = BattleState.active_unit(state, "p1")      # create_solo da' sempre lo slot "p1": "IO" e' solo il nome
	var before: Dictionary = ResourceTelemetry.snapshot(state)
	var events: Array = []
	ResourceTelemetry.gain_unit(u, "gauge", 12, BattleTypes.GAUGE_MAX, events, "snapshot_test")
	ResourceTelemetry.record(state, before, events, "test_action")
	var net: Dictionary = _has_event(events, "resource_delta")
	check(not net.is_empty(), "lo snapshot genera un delta netto")
	check(str(net.get("resource", "")) == "gauge" and int(net.get("delta", 0)) == 12, "il delta netto coincide con la variazione effettiva")
	check(str(net.get("source", "")) == "test_action", "il delta conserva la fase quando manca un evento azione")


func _hype_and_ammo() -> void:
	var u: Dictionary = {"id": "IO:zecca", "char": "zecca", "hype": Kits.HYPE_MAX - 5}
	var events: Array = []
	Kits.add_hype(u, 20, events, "test_hype")
	var hype: Dictionary = _has_event(events, "hype")
	check(int(u["hype"]) == Kits.HYPE_MAX, "HYPE rispetta il tetto")
	check(int(hype.get("requested", -1)) == 20 and int(hype.get("effective", -1)) == 5 and int(hype.get("wasted", -1)) == 15, "HYPE registra l'eccedenza persa")
	var ammo_unit: Dictionary = {"id": "IO:saul", "char": "saul", "ammo": 1, "ammo_max": 3}
	BattleResolver._change_ammo(ammo_unit, 5, events, "test_reload")
	var reload: Dictionary = {}
	for e in events:
		if str(e.get("t", "")) == "ammo" and str(e.get("source", "")) == "test_reload":
			reload = e
	check(int(ammo_unit["ammo"]) == 3 and int(reload.get("effective", -1)) == 2 and int(reload.get("wasted", -1)) == 3, "ricarica munizioni registra l'eccedenza")
	BattleResolver._change_ammo(ammo_unit, -5, events, "test_shot")
	var shot: Dictionary = {}
	for e in events:
		if str(e.get("t", "")) == "ammo" and str(e.get("source", "")) == "test_shot":
			shot = e
	check(int(ammo_unit["ammo"]) == 0 and int(shot.get("effective", 0)) == -3 and int(shot.get("wasted", -1)) == 2, "spesa munizioni registra la parte non disponibile")


func _reserve_and_ardore() -> void:
	var state: Dictionary = _fresh()
	var events: Array = []
	BattleResolver._gain_reserve(state, BattleTypes.RESERVE_MAX, "test_gain", events)
	var reserve_gain: Dictionary = _has_event(events, "reserve")
	check(int(reserve_gain.get("effective", -1)) == BattleTypes.RESERVE_MAX - BattleTypes.RESERVE_START, "Riserva registra il guadagno effettivo al tetto")
	check(int(reserve_gain.get("wasted", -1)) == BattleTypes.RESERVE_START, "Riserva registra l'eccedenza al tetto")
	BattleResolver._spend_reserve(state, BattleTypes.RESERVE_MAX + 2, "test_spend", events)
	var reserve_spend: Dictionary = {}
	for e in events:
		if str(e.get("t", "")) == "reserve" and str(e.get("why", "")) == "test_spend":
			reserve_spend = e
	check(int(state["reserve"]) == 0 and int(reserve_spend.get("effective", -1)) == BattleTypes.RESERVE_MAX, "Riserva non scende sotto zero")
	check(int(reserve_spend.get("wasted", -1)) == 2, "Riserva registra la spesa non soddisfatta")
	Ritmo.st(state)["level"] = Ritmo.APICE
	Ritmo.st(state)["ardore"] = 95
	var ritmo_events: Array = []
	Ritmo.gain(state, 20, "test_gain", "", ritmo_events)
	var ardore_gain: Dictionary = _has_event(ritmo_events, "ritmo_gain")
	check(Ritmo.ardore(state) == 100 and int(ardore_gain.get("wasted", -1)) == 15, "Ardore registra l'eccedenza oltre il tetto")
	Ritmo.drain(state, 120, "test_drain", ritmo_events)
	var ardore_loss: Dictionary = {}
	for e in ritmo_events:
		if str(e.get("t", "")) == "ritmo_loss":
			ardore_loss = e
	check(Ritmo.ardore(state) == 0 and int(ardore_loss.get("effective", -1)) == 100 and int(ardore_loss.get("wasted", -1)) == 20, "Ardore registra la perdita effettiva e la quota non applicabile")


func _per_unit_source() -> void:
	var state: Dictionary = {
		"units": {
			"lance": {"id": "lance", "side": "player", "char": "ferri", "energy": 3, "gauge": 10, "hype": 0, "ammo": 0},
			"nox": {"id": "nox", "side": "player", "char": "nox", "energy": 2, "gauge": 5, "hype": 0, "ammo": 0}
		}
	}
	var before: Dictionary = ResourceTelemetry.snapshot(state)
	state["units"]["lance"]["energy"] = 4
	state["units"]["nox"]["energy"] = 3
	var events: Array = [
		{"t": "act", "unit": "lance", "move": "firma"},
		{"t": "duo", "unit": "nox", "id": "copertura"}
	]
	ResourceTelemetry.record(state, before, events, "player_action")
	var sources: Dictionary = {}
	for e in events:
		if str(e.get("t", "")) == "resource_delta":
			sources[str(e["unit"])] = str(e["source"])
	check(str(sources.get("lance", "")) == "azione:firma", "la risorsa di Lance usa la sua azione")
	check(str(sources.get("nox", "")) == "duo:copertura", "la risorsa di Nox usa la sua tecnica combinata")

	before = ResourceTelemetry.snapshot(state)
	state["units"]["lance"]["energy"] = 5
	var duo_events: Array = [
		{"t": "act", "unit": "lance", "move": "duo_protezione"},
		{"t": "duo", "unit": "lance", "id": "duo_protezione", "with": "nox"}
	]
	ResourceTelemetry.record(state, before, duo_events, "player_action")
	var duo_source: String = ""
	for e in duo_events:
		if str(e.get("t", "")) == "resource_delta":
			duo_source = str(e["source"])
	check(duo_source == "duo:duo_protezione", "la tecnica a due prevale sull'evento act generico dello stesso attore")

	before = ResourceTelemetry.snapshot(state)
	var team_gain_events: Array = []
	ResourceTelemetry.gain_unit(state["units"]["nox"], "energy", 1, 10, team_gain_events, "duo_team")
	ResourceTelemetry.record(state, before, team_gain_events, "player_action")
	var team_gain_source: String = ""
	for e in team_gain_events:
		if str(e.get("t", "")) == "resource_delta":
			team_gain_source = str(e["source"])
	check(team_gain_source == "duo_team", "il delta netto eredita la fonte diretta del guadagno energia di squadra")

	before = ResourceTelemetry.snapshot(state)
	state["units"]["lance"]["energy"] = 6
	var mixed_events: Array = [
		{"t": "act", "unit": "lance", "move": "attacco"},
		{"t": "act", "unit": "lance", "move": "guardia"}
	]
	ResourceTelemetry.record(state, before, mixed_events, "player_action")
	var mixed_source: String = ""
	for e in mixed_events:
		if str(e.get("t", "")) == "resource_delta":
			mixed_source = str(e["source"])
	check(mixed_source == "mista", "piu' azioni della stessa unita' non vengono attribuite arbitrariamente")


func _init() -> void:
	_per_unit_source()
	_unit_resources()
	_net_snapshot()
	_hype_and_ammo()
	_reserve_and_ardore()
	if fails == 0:
		print("test_v3_resource_telemetry: OK")
	else:
		print("test_v3_resource_telemetry: %d FALLITI" % fails)
	quit(1 if fails > 0 else 0)
