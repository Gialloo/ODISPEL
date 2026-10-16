extends SceneTree

# Tasto AUTO: un tocco = un cambio. Due eventi quasi insieme (tocco + mouse emulato) non devono riaccendere e spegnere.
#   godot --headless --path . -s res://tests/unit/test_autoplay_toggle.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()


func _run() -> void:
	var s: Node = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(s)
	await create_timer(0.8).timeout
	_check("parte spento", not s.autoplay)
	s._auto_button.pressed.emit()
	s._auto_button.pressed.emit()          # doppio evento immediato: ignorato
	_check("doppio evento = acceso", s.autoplay)
	await create_timer(0.5).timeout
	s._auto_button.pressed.emit()
	_check("secondo tocco vero = spento", not s.autoplay)
	await create_timer(0.5).timeout
	s.toggle_autoplay()
	_check("tasto A / toggle = acceso", s.autoplay)
	await create_timer(1.0).timeout
	_check("resta acceso senza altri tocchi", s.autoplay)
	print("autoplay_toggle: %d ok, FAIL: %d" % [passed, failed])
	quit(1 if failed > 0 else 0)
