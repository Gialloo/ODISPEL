extends SceneTree

# Barra della stanza, lobby condivisa e ingresso in battaglia da qualsiasi schermata.
# Senza rete vera: l'host e' un NetworkManager con collegamenti vuoti.
#   godot --headless --path . -s res://tests/unit/test_room_ui.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _initialize() -> void:
	_run()


func _entries(ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		out.append(BattleContent.default_entry(str(id)))
	return out


func _swap_to(path: String) -> Node:
	var old: Node = current_scene
	var scene: Node = load(path).instantiate()
	root.add_child(scene)
	current_scene = scene
	if old != null:
		old.queue_free()
	return scene


func _run() -> void:
	await process_frame
	var ns: Node = root.get_node("NetSession")
	var bar: Node = ns.bar
	_check("tema applicato alla finestra", root.theme != null)
	_check("senza stanza la barra e' nascosta", not bar.visible)

	var game := GameState.new()
	game.setup("room_ui", 1, 1, 3)
	for i in 3:
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
	m.set_local_team(_entries(["kira", "dax"]))
	m._links["a"] = WebRTCLink.new()
	m._host_handle_message({"type": "hello", "name": "Marta", "token": "ta", "version": GameConfig.VERSION, "team": _entries(["nova"])}, "a")

	# hub
	var hub: Node = _swap_to("res://scenes/hub/hub_demo.tscn")
	await process_frame
	await process_frame
	_check("nell'hub la barra e' visibile", bar.visible)
	_check("il pulsante dice PRONTO", bar._ready_button.text == "PRONTO")
	bar._on_ready()
	_check("premendo si e' pronti", m.is_local_ready() and bar._ready_button.text == "ANNULLA")
	bar._on_toggle()
	_check("la barra si apre", bar._drop.visible)
	_check("due carte giocatore", bar._cards.get_child_count() == 2)
	_check("AVVIA bloccato se manca un pronto", bar._start_button.disabled)

	# squadra: si consulta e si cambia senza uscire dalla stanza
	var rs: Node = _swap_to("res://scenes/roster/roster_screen.tscn")
	await process_frame
	await process_frame
	_check("nella squadra la barra resta", bar.visible and ns.manager == m)
	_check("la stanza non e' stata chiusa", ns.manager != null)

	# missioni
	_swap_to("res://scenes/missions/mission_screen.tscn")
	await process_frame
	await process_frame
	var ms: Node = current_scene
	_check("missioni: barra visibile", bar.visible)
	_check("missioni: partenza in solitaria bloccata nella stanza", ms.go_button.disabled)

	# lobby: la barra lascia il posto alla lobby grande
	var lobby: Node = _swap_to("res://scenes/lobby/lobby_demo.tscn")
	await process_frame
	await process_frame
	_check("lobby: barra nascosta", not bar.visible)
	_check("lobby: mostra la stanza", lobby.room_panel.visible and not lobby.form_panel.visible)
	_check("lobby: due carte", lobby.cards_box.get_child_count() == 2)
	_check("lobby: AVVIA bloccato", lobby.start_button.disabled)

	# l'altro giocatore e' pronto: parte la battaglia e tutti ci vanno da dove stanno
	_swap_to("res://scenes/hub/hub_demo.tscn")
	await process_frame
	m._host_handle_message({"type": "ready", "ready": true}, "a")
	_check("tutti pronti: si puo' avviare", m.all_ready())
	_check("AVVIA si sblocca nella barra", not bar._start_button.disabled)
	_check("l'host avvia", m.host_launch())
	await process_frame
	await process_frame
	_check("si entra in battaglia dall'hub", str(current_scene.scene_file_path).contains("battle_screen"))
	_check("la battaglia e' quella di rete", current_scene.source == m)
	_check("in battaglia la barra e' nascosta", not bar.visible)

	# uscita dalla stanza
	ns.leave_room()
	await process_frame
	await process_frame
	_check("uscendo la stanza si chiude", ns.manager == null)
	_check("si torna all'hub", str(current_scene.scene_file_path).contains("hub_demo"))
	_check("senza stanza la barra sparisce", not bar.visible)

	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
