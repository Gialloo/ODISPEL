extends SceneTree

# Aura delle Rondini: carica, forma potenziata, ricarica.
#   godot --headless --path . -s res://tests/unit/test_ronda.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _state(team: Array) -> Dictionary:
	var entries: Array = []
	for id in team:
		entries.append(BattleContent.default_entry(str(id), 1, 0))
	return BattleState.create([{"id": "a", "name": "a", "ai": false, "team": entries}], "distributore", 5)


func _init() -> void:
	var s: Dictionary = _state(["kira", "rex", "sera"])
	var kira: Dictionary = BattleState.unit(s, "a:kira")
	_check("la Rondine parte carica", Factions.ronda_ready(kira))
	var atk_charged: int = int(kira["atk"])
	var solo: Dictionary = _state(["kira", "dax", "elle"])
	_check("senza altre Rondini c'e' comunque aura propria", Factions.ronda_ready(BattleState.unit(solo, "a:kira")))
	var boss: Dictionary = BattleState.boss(s)
	boss["hp"] = 1000000
	boss["max_hp"] = 1000000
	var ev: Array = []
	BattleResolver._player_act(s, kira, "attack", "", ev)
	var ronda_ev: bool = false
	for e in ev:
		if str(e["t"]) == "ronda" and int(e["on"]) == 0:
			ronda_ev = true
	_check("l'attacco spende la carica", ronda_ev and not Factions.ronda_ready(kira))
	_check("senza carica le stat tornano", int(kira["atk"]) < atk_charged)
	var dmg1: int = 1000000 - int(boss["hp"])
	var ev2: Array = []
	BattleResolver._player_act(s, kira, "attack", "", ev2)
	var dmg2: int = 1000000 - int(boss["hp"]) - dmg1
	_check("la forma potenziata colpisce piu' forte", dmg1 > dmg2)
	# ricarica
	var ev3: Array = []
	BattleResolver.begin_round(s)
	_check("dopo 1 round non e' ancora carica", not Factions.ronda_ready(kira))
	BattleResolver.begin_round(s)
	_check("dopo 2 round si ricarica", Factions.ronda_ready(kira))
	var back: Dictionary = BattleState.from_json(BattleState.to_json(s))
	_check("JSON identico", JSON.stringify(back) == JSON.stringify(s))
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
