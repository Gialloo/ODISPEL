extends SceneTree

# Schermata di avvio in stile VHS, senza giocare: menu fermo e menu con un tasto scelto (hover).
# xvfb-run -a godot --path . --resolution 1280x720 -s tools/v3_menu_vhs.gd -- /tmp/menu [touch]

var out: String = "/tmp/menu"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.has("touch"):
		TouchUi.force = true
	Settings.ensure_loaded()
	DirAccess.make_dir_recursive_absolute(out)
	root.add_child(load("res://scenes/main.tscn").instantiate())
	_run()


func _run() -> void:
	await create_timer(6.0, true, false, true).timeout
	root.get_texture().get_image().save_png(out + "/menu.png")
	var b: Button = null
	for n in root.find_children("*", "Button", true, false):
		if (n as Button).text == "NUOVA PARTITA" and (n as Button).is_visible_in_tree():
			b = n
	if b != null:
		b.set_meta("vhs_scelto", true)
		b.modulate.a = 0.85
		b.get_child(0).queue_redraw()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(out + "/menu_scelto.png")
	quit()
