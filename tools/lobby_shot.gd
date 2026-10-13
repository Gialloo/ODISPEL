extends SceneTree

# Immagini della lobby e della barra stanza, senza rete vera (serve un display):
#   godot --path . --resolution 1280x720 -s res://tools/lobby_shot.gd -- cartella_uscita

var _out: String = "user://"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_run()


func _shot(name: String) -> void:
	await create_timer(0.35).timeout
	root.get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
	print("salvata ", name)


func _entries(ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		out.append(BattleContent.default_entry(str(id)))
	return out


func _run() -> void:
	await process_frame      # lascia partire gli autoload (font, maiuscole)
	var ns: Node = root.get_node("NetSession")
	var game := GameState.new()
	game.setup("shot", 1, 1, 4)
	for i in 4:
		var p := PlayerState.new()
		p.setup("player_" + str(i + 1), "P" + str(i + 1), i + 1)
		game.party.add_player(p)
	var m := NetworkManager.new()
	m.is_host = true
	m.game = game
	m.local_player_id = "player_1"
	m._prepare_host_party()
	ns.add_child(m)
	ns.manager = m
	ns._attach()
	m.set_local_team(_entries(["kira", "dax", "elle"]))
	m._links["a"] = WebRTCLink.new()
	m._host_handle_message({"type": "hello", "name": "Marta", "token": "ta", "version": GameConfig.VERSION, "team": _entries(["nova", "bruno"])}, "a")
	m._links["b"] = WebRTCLink.new()
	m._host_handle_message({"type": "hello", "name": "Luca", "token": "tb", "version": GameConfig.VERSION, "team": _entries(["sera", "mira"])}, "b")
	m._host_handle_message({"type": "ready", "ready": true}, "a")
	m.host_set_mission("semaforo", 0)
	m._host_handle_message({"type": "ready", "ready": true}, "a")

	var lobby: Node = load("res://scenes/lobby/lobby_demo.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	await _shot("lobby_stanza")
	lobby.queue_free()

	var hub: Node = load("res://scenes/hub/hub_demo.tscn").instantiate()
	root.add_child(hub)
	current_scene = hub
	await _shot("hub_con_barra")
	ns.bar._on_toggle()
	await _shot("hub_barra_aperta")
	hub.queue_free()

	var rs: Node = load("res://scenes/roster/roster_screen.tscn").instantiate()
	root.add_child(rs)
	current_scene = rs
	await _shot("squadra_con_barra")
	ns.close()
	quit(0)
