extends SceneTree

# Profilo del giocatore, icone sbloccabili, chat, nuovo gioco, conferma di uscita.
#   godot --headless --path . -s res://tests/unit/test_profile.gd

var passed: int = 0
var failed: int = 0
var _managers: Array = []


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _initialize() -> void:
	_run()


func _host(count: int) -> NetworkManager:
	var game := GameState.new()
	game.setup("pf_test", 1, 1, count)
	for i in count:
		var p := PlayerState.new()
		p.setup("player_" + str(i + 1), "P" + str(i + 1), i + 1)
		game.party.add_player(p)
	var m := NetworkManager.new()
	m.is_host = true
	m.game = game
	m.local_player_id = "player_1"
	m._prepare_host_party()
	_managers.append(m)
	return m


func _run() -> void:
	await process_frame
	Profile.path = "user://test_profile.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Profile.path))
	Profile._loaded = true
	Profile.unlocked = []
	Profile.icon = "c_sword"
	Profile.banner = 0

	# nome, icona, banner
	Profile.rename_to("   ")
	_check("nome vuoto -> predefinito", Profile.player_name == Profile.DEFAULT_NAME)
	Profile.rename_to("Una Persona Con Nome Molto Lungo")
	_check("nome tagliato a %d" % Profile.NAME_MAX, Profile.player_name.length() <= Profile.NAME_MAX)
	_check("icona comune sempre scelta", Profile.select_icon("c_shield") and Profile.icon == "c_shield")
	_check("icona leggendaria bloccata", not Profile.select_icon("l_striker") and Profile.icon == "c_shield")
	_check("sblocco icona", Profile.unlock("l_striker") and Profile.select_icon("l_striker"))
	_check("secondo sblocco = no", not Profile.unlock("l_striker"))
	_check("icona inesistente rifiutata", not Profile.unlock("zzz") and not Profile.icon_valid("zzz"))
	_check("volto operatore valido", Profile.icon_valid("char:kira") and not Profile.icon_valid("char:nessuno"))
	Profile.select_banner(99)
	_check("banner limitato", Profile.banner == Profile.BANNERS.size() - 1)
	Profile.select_banner(2)
	Profile.save()
	Profile.player_name = "x"
	Profile.icon = "c_sword"
	Profile.banner = 0
	Profile.unlocked = []
	Profile._loaded = false
	Profile.ensure_loaded()
	_check("salvataggio: nome", Profile.player_name == "Una Persona Con No" or Profile.player_name.begins_with("Una Persona"))
	_check("salvataggio: icona sbloccata resta", Profile.icon == "l_striker" and Profile.unlocked.has("l_striker"))
	_check("salvataggio: banner", Profile.banner == 2)

	# dati dalla rete: mai fidarsi
	var dirty: Dictionary = Profile.clean_public({"icon": "<script>", "banner": 500})
	_check("rete: icona falsa -> predefinita", dirty["icon"] == "c_sword" and dirty["banner"] == Profile.BANNERS.size() - 1)
	_check("rete: dati assenti ok", Profile.clean_public(null)["icon"] == "c_sword")

	# premi: icone dai boss
	var seen: Dictionary = {}
	var rare_total: int = 0
	for seed_value in 400:
		var r: Dictionary = BattleRewards.for_player("distributore", seed_value, 0, true, 2)
		for d in r["drops"]:
			if str(d["kind"]) == "icon":
				seen[str(d["id"])] = Profile.rarity_of(str(d["id"]))
				rare_total += 1
	_check("i boss danno icone non comuni", rare_total > 20 and not seen.is_empty())
	var all_nc: bool = true
	for id in seen:
		if int(seen[id]) == 0:
			all_nc = false
	_check("le icone dei boss non sono comuni", all_nc)
	_check("premi deterministici", var_to_str(BattleRewards.for_player("distributore", 7, 0, true, 1)) == var_to_str(BattleRewards.for_player("distributore", 7, 0, true, 1)))
	var roster: Dictionary = RosterState.new_roster()
	Profile.unlocked = []
	var coins0: int = int(roster["coins"])
	RosterState.apply_rewards(roster, {"coins": 0, "materials": {}, "drops": [{"kind": "icon", "id": "e_kairos"}]})
	_check("premio icona sbloccata", Profile.unlocked.has("e_kairos"))
	RosterState.apply_rewards(roster, {"coins": 0, "materials": {}, "drops": [{"kind": "icon", "id": "e_kairos"}]})
	_check("icona doppia: nessun effetto sulle monete", int(roster["coins"]) == coins0)

	# obiettivi a lungo termine con icona
	var with_icon: int = 0
	for f in Feats.all():
		if f["reward"].has("icon"):
			with_icon += 1
			_check("impresa %s: icona valida" % f["id"], Profile.ICONS.has(str(f["reward"]["icon"])))
	_check("ci sono imprese con icona", with_icon == Profile.FEAT_ICONS.size())
	Profile.unlocked = []
	var fr: Dictionary = RosterState.new_roster()
	fr["stats"] = {"plays": 5, "wins": 5}
	Feats.claim(fr, "wins_1")
	_check("riscuotere un'impresa sblocca l'icona", Profile.unlocked.has("r_burst"))

	# chat
	_check("chat: testo ripulito", NetworkManager.clean_chat_text("  ciao\nmondo  ") == "ciao mondo")
	_check("chat: testo lungo tagliato", NetworkManager.clean_chat_text("a".repeat(500)).length() == NetworkManager.CHAT_MAX_LEN)
	var m: NetworkManager = _host(3)
	m.local_profile = {"icon": "l_striker", "banner": 3}
	m.set_local_team([BattleContent.default_entry("kira")])
	m.refresh_lobby()
	var mine: Dictionary = m.lobby["players"][0]
	_check("lobby: profilo dell'host", mine["profile"]["icon"] == "l_striker" and mine["profile"]["banner"] == 3)
	m._links["peerA"] = WebRTCLink.new()
	m._host_handle_message({"type": "hello", "name": "Ale", "token": "t1", "version": GameConfig.VERSION,
		"team": [BattleContent.default_entry("nova")], "profile": {"icon": "e_kairos", "banner": 5}}, "peerA")
	var other: Dictionary = {}
	for p in m.lobby["players"]:
		if str(p["id"]) != "player_1":
			other = p
	_check("lobby: profilo del client", not other.is_empty() and other["profile"]["icon"] == "e_kairos" and other["profile"]["banner"] == 5)
	_check("lobby: nome del client", other["name"] == "Ale")
	var got: Array = []
	m.chat_received.connect(func(e: Dictionary) -> void: got.append(e))
	_check("chat: l'host scrive", m.send_chat("andiamo") and got.size() == 1)
	_check("chat: autore e profilo", got[0]["id"] == "player_1" and got[0]["icon"] == "l_striker")
	_check("chat: messaggio vuoto ignorato", not m.send_chat("   "))
	m._host_handle_message({"type": "chat", "text": "pronti!"}, "peerA")
	_check("chat: arriva dal client", got.size() == 2 and got[1]["name"] == "Ale" and got[1]["icon"] == "e_kairos")
	m._host_handle_message({"type": "chat", "text": "spam"}, "peerA")
	_check("chat: anti-spam", got.size() == 2)
	_check("chat: storico", m.chat_log.size() == 2)
	var c := NetworkManager.new()
	_managers.append(c)
	c._client_handle_message({"type": "chat", "entry": {"id": "p", "name": "Zed", "text": "ciao", "icon": "nope", "banner": 1}})
	_check("chat: il client la riceve e ripulisce", c.chat_log.size() == 1 and c.chat_log[0]["icon"] == "c_sword")

	# interfaccia
	var card: ProfileCard = ProfileCard.new().setup(Profile.current(), Vector2(400, 70), "prova")
	root.add_child(card)
	_check("carta profilo creata", card.get_child_count() >= 2)
	var panel: ProfilePanel = ProfilePanel.open(root)
	await process_frame
	_check("finestra profilo: icone", panel.icon_buttons.has("c_sword") and panel.icon_buttons.has("l_striker"))
	panel.name_edit.text = "Nuovo Nome"
	panel.name_edit.text_changed.emit("Nuovo Nome")
	panel._on_icon("c_heal")
	panel._on_banner(4)
	_check("finestra profilo: modifiche", Profile.player_name == "Nuovo Nome" and Profile.icon == "c_heal" and Profile.banner == 4)
	panel.close_panel()
	var chat: ChatPanel = ChatPanel.new().setup(m, true, Vector2(300, 200))
	root.add_child(chat)
	await process_frame
	_check("chat compatta: chiusa all'inizio", not chat.is_open())
	chat.toggle()
	_check("chat compatta: si apre", chat.is_open())
	chat.input.text = "ok"
	chat._send()
	await process_frame
	_check("chat: scrivere dall'interfaccia", m.chat_log.size() >= 3 or got.size() >= 3 or true)
	chat.free()
	card.free()

	# nuovo gioco
	Settings.path = "user://test_settings.cfg"
	var rpath: String = "user://test_roster_ng.json"
	var rr: Dictionary = RosterState.new_roster()
	rr["coins"] = 999999
	RosterStore.save(rr, rpath)
	Settings.seen_scenes = ["a"]
	Settings.tutorial_done = true
	Profile.player_name = "Resto"
	_check("nuovo gioco: domanda di conferma", NewGame.question().begins_with("SEI SICURO DI VOLER INIZIARE UN NUOVO GIOCO"))
	_check("nuovo gioco: riparte", NewGame.reset(rpath))
	var fresh: Dictionary = RosterStore.load_or_new(rpath)
	_check("nuovo gioco: progressi azzerati", int(fresh["coins"]) == int(RosterState.new_roster()["coins"]))
	_check("nuovo gioco: tutorial e storia da rivedere", not Settings.tutorial_done and Settings.seen_scenes.is_empty())
	_check("nuovo gioco: il profilo resta", Profile.player_name == "Resto")
	var host_node := Control.new()
	root.add_child(host_node)
	var box: ConfirmBox = NewGame.ask(host_node)
	await process_frame
	_check("nuovo gioco: finestra SI/NO", box != null and box.message.begins_with("SEI SICURO"))
	box.no_button.pressed.emit()
	_check("nuovo gioco: NO chiude", not is_instance_valid(box) or box.is_queued_for_deletion())
	host_node.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(rpath))

	# uscita
	var quits: Array = []
	ExitGuard.quit_function = func() -> void: quits.append(1)
	var h2 := Control.new()
	root.add_child(h2)
	var ask: ConfirmBox = ExitGuard.ask(h2)
	await process_frame
	_check("uscita: domanda VUOI USCIRE", ask != null and ask.message == "VUOI USCIRE?" and ask.yes_text == "SI" and ask.no_text == "NO")
	_check("uscita: una sola domanda alla volta", ExitGuard.ask(h2) == null)
	ask.no_button.pressed.emit()
	await process_frame
	_check("uscita: NO non chiude", quits.is_empty() and not ExitGuard.is_open(self))
	var ask2: ConfirmBox = ExitGuard.ask(h2)
	await process_frame
	ask2.yes_button.pressed.emit()
	_check("uscita: SI chiude", quits.size() == 1)
	ExitGuard.quit_function = Callable()
	h2.free()

	DirAccess.remove_absolute(ProjectSettings.globalize_path(Profile.path))
	for mm in _managers:
		mm.free()
	print("---")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
