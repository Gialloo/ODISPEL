extends SceneTree

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
	var host := Control.new()
	root.add_child(host)
	var m: PauseMenu = PauseMenu.open(host, false)
	var got: Array = [false, false]
	m.resumed.connect(func() -> void: got[0] = true)
	m.quit_requested.connect(func() -> void: got[1] = true)
	await process_frame
	_check("la pausa si apre", is_instance_valid(m) and m.resume_button != null)
	m.resume_button.pressed.emit()
	await process_frame
	await process_frame
	_check("riprendi chiude e avvisa", got[0] and not is_instance_valid(m))
	var m2: PauseMenu = PauseMenu.open(host, true)
	m2.quit_requested.connect(func() -> void: got[1] = true)
	await process_frame
	var btns: Array = []
	for n in m2.find_children("*", "Button", true, false):
		btns.append(n)
	_check("tre pulsanti", btns.size() == 3)
	btns[2].pressed.emit()
	await process_frame
	await process_frame
	_check("esci avvisa e chiude", got[1] and not is_instance_valid(m2))
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
