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
	for sid in StoryData.SCENES.keys():
		var s: DialogueScript = DialogueScript.parse(StoryData.text(str(sid)))
		if s == null or not s.errors.is_empty():
			print("scena rotta: ", sid)
			n += 1
	_check("tutte le scene di storia si leggono", n == 0)
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
