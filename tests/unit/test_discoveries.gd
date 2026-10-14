extends SceneTree

# Archivio delle scoperte, titoli e stile di squadra.
#   godot --headless --path . -s res://tests/unit/test_discoveries.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	var roster: Dictionary = RosterState.new_roster()
	_check("archivio vuoto", Discoveries.count(roster) == 0)
	var stats: Dictionary = {"downs": 0, "synergies": 4, "breaks": 2, "reactions": 3, "spent": 0, "seen_combos": ["copertura", "traccia"], "seen_arena": ["sigillo"], "seen_behavior": ["punisce_cure"]}
	var lines: Array = Discoveries.record(roster, "distributore", true, stats)
	_check("3 scoperte + boss", Discoveries.count(roster) == 4 and lines.size() == 4)
	_check("seconda volta: nessuna novita'", Discoveries.record(roster, "distributore", true, stats).is_empty())
	_check("conteggio stabile", Discoveries.count(roster) == 4)
	var t: Array = Discoveries.titles(stats, true)
	_check("titoli: nessuno e' caduto", t.has("NESSUNO E' CADUTO") and t.has("ORCHESTRA") and t.has("SPEZZAGUARDIE") and t.has("MURO DI REAZIONI"))
	_check("titoli: sconfitta senza premi di vittoria", not Discoveries.titles(stats, false).has("NESSUNO E' CADUTO"))
	_check("stile", Discoveries.style_of(stats) == "COORDINATO" and Discoveries.style_of({}) == "")
	_check("firma squadra", Discoveries.signature(roster) == "COORDINATO")
	var known: Dictionary = Discoveries.known(roster)
	_check("known contiene il boss", (known["behaviors"] as Array).has("distributore"))
	# lo stato porta la conoscenza e il suggerimento cambia
	var st: Dictionary = RosterState.create_solo_battle(roster, "T", "distributore", 3)
	_check("stato con known", st.has("known"))
	var noted: bool = false
	for l in Arena.hint_lines(st):
		if str(l).begins_with("NOTO"):
			noted = true
	_check("suggerimento NOTO", noted)
	var fresh: Dictionary = RosterState.create_solo_battle(RosterState.new_roster(), "T", "distributore", 3)
	var unknown: bool = false
	for l in Arena.hint_lines(fresh):
		if str(l).begins_with("Questo boss"):
			unknown = true
	_check("suggerimento sconosciuto", unknown)
	# il motore riempie le statistiche dagli eventi
	var spec: Dictionary = {"id": "a", "name": "a", "ai": false, "team": [BattleContent.default_entry("kira"), BattleContent.default_entry("dax"), BattleContent.default_entry("elle")]}
	var b: Dictionary = BattleState.create([spec], "distributore", 9)
	var evs: Array = [{"t": "arena", "id": "sigillo", "ok": true, "unit": "", "amount": 0}, {"t": "behavior", "id": "punisce_cure", "n": 1}, {"t": "synergy", "id": "traccia", "name": "TRACCIA"}, {"t": "synergy", "id": "traccia", "name": "TRACCIA"}]
	BattleResolver._tally(b, evs)
	var s: Dictionary = b["stats"]
	_check("tally: scoperte senza doppioni", (s["seen_combos"] as Array) == ["traccia"] and (s["seen_arena"] as Array) == ["sigillo"] and (s["seen_behavior"] as Array) == ["punisce_cure"])
	# roster vecchio senza archivio
	var old: Dictionary = RosterState.new_roster()
	old.erase("discoveries")
	_check("vecchi salvataggi ok", Discoveries.count(old) == 0 and RosterState.validate(old) == "")
	# codice squadra
	var team: Array = RosterState.team_entries(RosterState.new_roster())
	var code: String = BuildCode.encode(team)
	_check("codice leggibile", code.begins_with("ODS1|") and code.find("kira") > 0)
	var back: Dictionary = BuildCode.decode(code)
	_check("codice: round trip", bool(back["ok"]) and (back["team"] as Array).size() == team.size() and str(back["team"][0]["char"]) == str(team[0]["char"]))
	_check("codice: nessuna differenza", BuildCode.compare(team, back["team"]).is_empty())
	_check("codice finto", not bool(BuildCode.decode("ODS1|kira.1.0:inventata::")["ok"]))
	_check("codice sbagliato", not bool(BuildCode.decode("ciao")["ok"]) and not bool(BuildCode.decode("ODS1|zzz.1.0:::")["ok"]))
	# nuove interazioni tra status
	_check("combo: condanna e cascata", Combos.rule("condanna").has("id") and Combos.rule("cascata").has("id"))
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
