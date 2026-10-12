extends SceneTree

# LINK: catena di combo tra compagni nello stesso round.
#   godot --headless --path . -s res://tests/unit/test_link.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _links(events: Array) -> Array:
	var out: Array = []
	for e in events:
		if str(e.get("t", "")) == "link":
			out.append(e)
	return out


func _init() -> void:
	var s: Dictionary = BattleState.create_solo("T", [{"char": "kira"}, {"char": "dax"}, {"char": "elle"}], [{"char": "bruno"}, {"char": "eco"}], "distributore", 5)
	var ev: Array = BattleResolver.resolve_round(s, true)
	var links: Array = _links(ev)
	_check("tre giocatori: nascono dei link", links.size() >= 1)
	_check("il primo a muoversi non fa link", links.is_empty() or str(links[0]["with"]) != str(links[0]["unit"]))
	var capped := true
	for l in links:
		if int(l["n"]) > BattleTypes.LINK_MAX or int(l["n"]) < 1:
			capped = false
		if not ["cross", "unison"].has(str(l["kind"])):
			capped = false
	_check("n tra 1 e il massimo, tipo valido", capped)
	# la catena riparte dopo la mossa del boss: nessun link con un indice di evento precedente alla mossa del boss
	var after_boss := false
	var ok := true
	for e in ev:
		if str(e.get("t", "")) == "boss_move" or (str(e.get("t", "")) == "act" and str(e["unit"]) == BattleState.BOSS_ID):
			after_boss = true
		elif str(e.get("t", "")) == "link" and after_boss and int(e["n"]) > 2:
			ok = false
	_check("dopo il boss la catena riparte", ok)
	# determinismo
	var a: Dictionary = BattleState.create_solo("T", [{"char": "kira"}, {"char": "dax"}, {"char": "elle"}], [{"char": "bruno"}, {"char": "eco"}], "distributore", 5)
	var b: Dictionary = BattleState.create_solo("T", [{"char": "kira"}, {"char": "dax"}, {"char": "elle"}], [{"char": "bruno"}, {"char": "eco"}], "distributore", 5)
	_check("stesso seme, stessi eventi", JSON.stringify(BattleResolver.resolve_round(a, true)) == JSON.stringify(BattleResolver.resolve_round(b, true)))
	_check("lo stato resta JSON", JSON.parse_string(BattleState.to_json(a)) != null)
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
