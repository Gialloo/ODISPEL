extends SceneTree

# Eco (alleato di storia), nuovi boss e scene di storia ben formate.
#   godot --headless --path . -s res://tests/unit/test_story_allies.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	var r: Dictionary = RosterState.new_roster()
	_check("Eco non e' nella squadra all'inizio", not RosterState.owns(r, "eco"))
	RosterState.mark_cleared(r, "distributore", 0)
	RosterState.grant_story_allies(r)
	_check("Eco si unisce dopo il primo boss", RosterState.owns(r, "eco"))
	RosterState.grant_story_allies(r)
	_check("nessun doppione se richiamato", r["characters"].size() == RosterState.new_roster()["characters"].size() + 1)
	for id in ["ascensore", "manichino", "orologio"]:
		_check("boss %s definito" % id, BattleContent.BOSSES.has(id) and BattleContent.BOSS_ORDER.has(id))
	_check("contenuti validi", BattleContent.validate().is_empty())
	var n: int = 0
	for sid in StoryData.SCENES.keys() + StorySeason2.SCENES.keys():
		var s: DialogueScript = DialogueScript.parse(StoryData.text(str(sid)))
		if s == null or not s.errors.is_empty():
			print("scena rotta: ", sid)
			n += 1
	_check("tutte le scene di storia si leggono", n == 0)
	var rd: Dictionary = RosterState.new_roster()
	_check("Dafne non e' ancora nella squadra", not RosterState.owns(rd, "dafne"))
	RosterState.mark_cleared(rd, "sirena", 0)
	_check("battere la Sirena porta Dafne", RosterState.owns(rd, "dafne"))
	_check("Dafne e' valida nel salvataggio", RosterState.validate(rd) == "")
	_check("stagione 2: 10 boss con ciclo valido", BattleContent.BOSS_ORDER.size() - 8 == 10)
	print("---")
	var rn: Dictionary = RosterState.new_roster()
	_check("Nico non c'e' all'inizio", not RosterState.owns(rn, "nico"))
	RosterState.mark_cleared(rn, "specchio", 0)
	_check("battere lo Specchio porta Nico", RosterState.owns(rn, "nico"))
	_check("Nico e' valido nel salvataggio", RosterState.validate(rn) == "")
	var st: Dictionary = RosterState.create_solo_battle(rn, "Io", "distributore", 3, 2, 0)
	_check("la battaglia con Nico parte", st["round"] == 1)
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
