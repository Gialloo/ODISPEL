class_name NewGame
extends RefCounted

# "Nuovo gioco": si ricomincia da capo (operatori, monete, missioni, obiettivi, storia, tutorial).
# Restano le impostazioni e il profilo (nome, icone ottenute, banner).


static func question() -> String:
	return "SEI SICURO DI VOLER INIZIARE UN NUOVO GIOCO?\n\nTutti i progressi andranno persi."


# Cancella i progressi. Ritorna true se il nuovo salvataggio e' stato scritto.
static func reset(roster_path: String = RosterStore.DEFAULT_PATH) -> bool:
	var ok: bool = RosterStore.save(RosterState.new_roster(), roster_path)
	var cs: Node = Engine.get_main_loop().root.get_node_or_null("CampaignState") if Engine.get_main_loop() != null else null
	if cs != null:
		cs.start_campaign()
	Settings.seen_scenes = []
	Settings.tutorial_done = false
	Settings.gacha_guide_seen = false
	Settings.save()
	MissionConfig.endless_floor = 0
	MissionConfig.daily_mod = ""
	MissionConfig.endless_boons = []
	MissionConfig.endless_carry = {}
	return ok


# Chiede conferma e poi riparte dall'hub.
static func ask(host: Node, on_done: Callable = Callable()) -> ConfirmBox:
	return ConfirmBox.ask(host, question(), func() -> void:
		reset()
		Notify.success("Nuovo gioco iniziato")
		if on_done.is_valid():
			on_done.call()
		else:
			SceneRouter.go("hub"), "SI, RICOMINCIA", "NO, TORNA INDIETRO")
