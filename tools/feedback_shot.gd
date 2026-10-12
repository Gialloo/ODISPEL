extends SceneTree

# Immagini di hub, avvisi, icona di attivita' e schermata di caricamento (serve un display):
#   godot --path . --resolution 1280x720 -s res://tools/feedback_shot.gd -- cartella_uscita

var _out: String = "user://"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_run()


func _shot(name: String, wait: float = 0.3) -> void:
	await create_timer(wait).timeout
	root.get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
	print("salvata ", name)


func _run() -> void:
	await process_frame
	var r: Dictionary = RosterState.new_roster()
	RosterState.mark_cleared(r, "distributore", 0)
	var hub: Node = load("res://scenes/hub/hub_demo.tscn").instantiate()
	hub.roster = r
	root.add_child(hub)
	current_scene = hub
	await _shot("hub")
	Notify.success("NUOVO BERSAGLIO: SEMAFORO")
	Notify.warning("NUOVO OPERATORE: SERA (EPICA)")
	Notify.toast("MARTA E' PRONTO")
	Notify.busy("rete", "CONNESSIONE AL SERVER...")
	await _shot("hub_avvisi")
	Notify.idle("rete")
	Notify.saved()
	await _shot("hub_salvato", 0.2)
	Notify.transition(func() -> void: pass, "PREPARAZIONE OPERAZIONE")
	await _shot("caricamento", 0.55)
	quit(0)
