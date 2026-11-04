extends SceneTree

# Prova del BOSS A DUE FASI (battle3d._phase_shift): il boss parte poco sopra meta' vita, si attacca finche' si squarcia.
# Con --write-movie si guardano i fotogrammi; senza, stampa solo quando arriva la fase.
# Uso: xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --resolution 1280x720 [--write-movie d/f.png --fixed-fps 30] -s tools/v3_fase.gd -- [boss] [arena]

func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	Settings.ensure_loaded()
	Story.set_flag("lezioni_fatte")
	_run(a[0] if a.size() > 0 else "semaforo", a[1] if a.size() > 1 else "anomalia_rossa")


func _run(id: String, ar: String) -> void:
	await process_frame
	var m: Node = load("res://scripts/v3/main.gd").new()
	root.add_child(m)
	await create_timer(1.0).timeout
	m.call("go", "battle", {"boss": id, "visual": id, "livello": 3, "arena": ar, "ingresso": "normale", "debolezze": [],
		"ritorno": {"tipo": "storia", "area": "incrocio", "perso": {}}})
	var bt: Node = null
	while bt == null or bt.get("waiting") != true:
		await process_frame
		bt = m.get("current")
	var st: Dictionary = bt.get("b")
	var boss: Dictionary = BattleState.boss(st)
	boss["hp"] = int(float(boss["max_hp"]) * 0.53)
	var f0: int = Engine.get_frames_drawn()
	var shown: bool = false
	while is_instance_valid(bt) and not bool(bt.get("ended")) and Engine.get_frames_drawn() - f0 < 2400:
		if not shown and int(bt.get("_phase_shown")) >= 2:
			shown = true
			print("FASE 2 al fotogramma ", Engine.get_frames_drawn())
		if bool(bt.get("waiting")):
			bt.call("_command", "attack")
		await process_frame
	quit()
