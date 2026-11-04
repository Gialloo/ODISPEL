extends SceneTree

# Prova delle INQUADRATURE FIRMATE delle abilita' e della COPERTINA di vittoria: ogni turno ABILITA', il nemico finisce presto.
# Con --write-movie si guardano i fotogrammi; senza, stampa solo quando arriva la fase.
# Uso: xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 [--write-movie d/f.png --fixed-fps 30] -s tools/v3_firme.gd -- [boss] [arena]

func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	Settings.ensure_loaded()
	Story.set_flag("lezioni_fatte")
	_run(a[0] if a.size() > 0 else "frammento_rosso", a[1] if a.size() > 1 else "strada")


func _run(id: String, ar: String) -> void:
	await process_frame
	var m: Node = load("res://scripts/v3/main.gd").new()
	root.add_child(m)
	await create_timer(1.0).timeout
	m.call("go", "battle", {"boss": id, "visual": id, "livello": 3, "arena": ar, "ingresso": "normale", "debolezze": [],
		"minore": true, "ritorno": {"tipo": "area", "area": "incrocio", "vinto": {}, "perso": {}}})
	var bt: Node = null
	while bt == null or bt.get("waiting") != true:
		await process_frame
		bt = m.get("current")
	var st: Dictionary = bt.get("b")
	var boss: Dictionary = BattleState.boss(st)
	boss["hp"] = int(float(boss["max_hp"]) * 0.45)
	bt.set("auto_on", false)
	var f0: int = Engine.get_frames_drawn()
	var shown: bool = false
	while is_instance_valid(bt) and not bool(bt.get("ended")) and Engine.get_frames_drawn() - f0 < 2400:
		if bool(bt.get("waiting")):
			print("turno al fotogramma ", Engine.get_frames_drawn())
			bt.call("_command", "skill")
		await process_frame
	print("fine al fotogramma ", Engine.get_frames_drawn())
	await create_timer(4.0).timeout
	quit()
