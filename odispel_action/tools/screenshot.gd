extends SceneTree

# Salva un'immagine della scena principale con i comandi touch visibili.
# Serve un display (non funziona con --headless). Esempio su Linux senza schermo:
#   xvfb-run -s "-screen 0 1280x720x24" godot --path odispel_action \
#     --rendering-method gl_compatibility -s res://tools/screenshot.gd -- out.png [corsa]
# Con "corsa" il personaggio corre e salta prima dello scatto.

class Runner:
	extends Node
	var frame: int = 0

	func get_intent() -> PlayerIntent:
		frame += 1
		var i := PlayerIntent.new()
		i.move = Vector3(-0.6, 0.0, -1.0).normalized()
		i.jump_pressed = frame == 40
		i.jump_held = true
		return i


func _initialize() -> void:
	_run()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://screenshot.png"
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var touch: TouchControls = main.get_node("HUD/TouchControls")
	main.get_node("LocalInputSource").set_touch_visible(true)
	if args.size() > 1 and args[1] == "corsa":
		var runner := Runner.new()
		main.add_child(runner)
		main.get_node("Player").intent_source = runner
		for i in 58:
			await physics_frame
	else:
		await _frames(30)
	# un dito sul joystick, per mostrarlo
	touch.handle_touch(0, Vector2(200, touch.size.y - 200), true)
	touch.handle_drag(0, Vector2(250, touch.size.y - 270))
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(out)
	print("salvato: ", out)
	quit()


func _frames(n: int) -> void:
	for i in n:
		await process_frame
