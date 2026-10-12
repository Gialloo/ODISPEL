extends SceneTree

# Stili delle particelle delle ultimate.
#   godot --headless --path . -s res://tests/unit/test_ult_fx.gd

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
	for id in BattleContent.MOVES:
		var m: Dictionary = BattleContent.MOVES[id]
		if str(m["kind"]) == "ult":
			pass
	_check("attacco -> strike", UltFx.style_for(BattleContent.MOVES["spezzatutto"]) == "strike")
	_check("rinascita -> heal", UltFx.style_for(BattleContent.MOVES["rinascita"]) == "heal")
	_check("bastione -> shield", UltFx.style_for(BattleContent.MOVES["bastione"]) == "shield")
	await process_frame
	var host := Control.new()
	root.add_child(host)
	var f: UltFx = UltFx.play(host, Vector2(300, 300), Color.RED, "strike", Vector2(800, 300))
	await create_timer(0.2).timeout
	_check("le particelle vivono", is_instance_valid(f) and f._parts.size() > 10)
	await create_timer(UltFx.LIFE + 0.2).timeout
	_check("poi spariscono", not is_instance_valid(f))
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
