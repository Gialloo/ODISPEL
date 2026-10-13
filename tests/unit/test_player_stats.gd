extends SceneTree

# Statistiche del profilo.
#   godot --headless --path . -s res://tests/unit/test_player_stats.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _val(rows: Array, label: String) -> String:
	for r in rows:
		if str(r[0]) == label:
			return str(r[1])
	return "?"


func _init() -> void:
	var roster: Dictionary = RosterState.new_roster()
	var rows: Array = PlayerStats.rows(roster)
	_check("dieci voci", rows.size() == 10)
	_check("nuovo salvataggio: zero battaglie", _val(rows, "BATTAGLIE") == "0")
	_check("zero vittorie senza divisione per zero", _val(rows, "VITTORIE") == "0  (0%)")
	Feats.record_battle(roster, true)
	Feats.record_battle(roster, false)
	Feats.record_battle(roster, true)
	rows = PlayerStats.rows(roster)
	_check("tre battaglie", _val(rows, "BATTAGLIE") == "3")
	_check("due vittorie su tre = 67%", _val(rows, "VITTORIE") == "2  (67%)")
	Feats.record_pvp(roster, true)
	_check("una partita PvP vinta", _val(PlayerStats.rows(roster), "PVP VINTE") == "1  (100%)")
	_check("percent con totale zero", PlayerStats.percent(5, 0) == "0%")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
