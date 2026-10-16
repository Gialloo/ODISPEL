extends SceneTree

# Le schede dell'elenco operatori si riusano senza mostrare dati vecchi (selezione, squadra, livello).
#   godot --headless --path . -s res://tests/unit/test_roster_cache.gd

var passed: int = 0
var failed: int = 0
const TMP: String = "user://test_roster_cache_tmp.json"


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _tile(s: Control, id: String) -> Button:
	for c in s._list_box.get_children():
		if c is Button and str(c.get_meta("char_id", "")) == id:
			return c
	return null


func _run() -> void:
	var r: Dictionary = RosterState.new_roster()
	var scene: Control = load("res://scenes/roster/roster_screen.tscn").instantiate()
	scene.roster = r
	scene.save_path = TMP
	root.add_child(scene)
	await process_frame
	var team: Array = (r["team"] as Array).duplicate()
	var a: String = str(team[0])
	var b: String = str(team[1])
	var c3: String = str(team[2])
	var n0: int = scene._list_box.get_child_count()
	var ta: Button = _tile(scene, c3)
	var tb: Button = _tile(scene, b)
	_check("schede presenti", ta != null and tb != null and n0 >= 6)
	scene.select(b)
	await process_frame
	_check("stesso numero di schede dopo la selezione", scene._list_box.get_child_count() == n0)
	_check("la scheda non toccata e' la stessa", _tile(scene, c3) == ta)
	_check("la scheda selezionata e' stata rifatta", _tile(scene, b) != tb)
	var sq: Button = _tile(scene, b)
	var has_badge: bool = false
	for c in sq.get_children():
		if c is Label and str(c.text).begins_with("SQ "):
			has_badge = true
	_check("l'operatore in squadra mostra SQ", has_badge)
	scene.toggle_team(b)
	await process_frame
	var has_badge2: bool = false
	for c in _tile(scene, b).get_children():
		if c is Label and str(c.text).begins_with("SQ "):
			has_badge2 = true
	_check("tolto dalla squadra: niente SQ", not has_badge2)
	scene.select_slot(1)
	await process_frame
	_check("slot: carte riviste senza errori", scene._slots_box.get_child_count() >= 6)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	print("roster_cache: %d ok, FAIL: %d" % [passed, failed])
	quit(1 if failed > 0 else 0)
