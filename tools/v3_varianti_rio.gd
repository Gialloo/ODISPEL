extends SceneTree

# Schermate delle varianti del ritratto di Rio (disegni dell'autore, 3/11/2026), una per ogni uso nel gioco:
# HUD normale, vita sotto il 50% e il 25%, SKILL e ULTIMATE scelte (ombra), BREAK (fotogramma disturbato),
# K.O. (SEGNALE PERSO), menu di pausa, skin della Replica (NG+) e schermata di caricamento (ricordo).
# Uso: xvfb-run -a -s "-screen 0 2400x1080x24" godot --path . --resolution 2400x1080 -s tools/v3_varianti_rio.gd -- <cartella> [touch|pc]

var out: String = "/tmp/v3varianti"
var bt: Node


func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1 and a[1] == "touch":
		TouchUi.force = true
	DirAccess.make_dir_recursive_absolute(out)
	Settings.ensure_loaded()
	Settings.hud_ritratto = true
	RitrattoLampo.lento = 6.0          # i lampi durano ~1 s veri: sotto xvfb passerebbero tra due fotogrammi
	_run()


func _shot(n: String) -> void:
	for i in 4:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out.path_join(n + ".png"))
	print("FOTO ", n)


func _rio() -> Dictionary:
	for uid in bt.b["units"]:
		var u: Dictionary = bt.b["units"][uid]
		if str(u.get("char", "")) == "zecca":
			return u
	return {}


# Si va avanti con GUARDIA (scelta e conferma) finche' non tocca a Rio.
func _turno_di_rio() -> bool:
	for k in 40:
		var guard: int = 0
		while not bool(bt.get("waiting")) and guard < 900:
			guard += 1
			await process_frame
		var u: Dictionary = bt.call("_unit_of", bt.get("cur_pid"))
		if str(u.get("char", "")) == "zecca":
			return true
		bt.call("_pick", "guard")
		await create_timer(0.1).timeout
		bt.call("_pick", "guard")
		await create_timer(0.3).timeout
	return false


# Il lampo vive ~1 s di tempo vero: sotto xvfb i fotogrammi sono lenti, quindi si aspetta che compaia e si scatta subito.
func _aspetta_lampo() -> void:
	for k in 600:
		for n in root.find_children("*", "Control", true, false):
			if not (n is RitrattoLampo):
				continue
			for i in 6:
				await process_frame
			return
		await process_frame


func _battaglia() -> void:
	bt = load("res://scripts/v3/battle3d.gd").new()
	bt.configure({"boss": "autovelox", "livello": 11, "arena": "tangenziale"})
	root.add_child(bt)
	for i in 3:
		await process_frame


func _run() -> void:
	await process_frame
	# --- 1) battaglia normale ---
	await _battaglia()
	var rio: Dictionary = _rio()
	rio["gauge"] = BattleTypes.GAUGE_MAX          # ULTIMATE pronta, per poterla scegliere
	if not await _turno_di_rio():
		print("ERRORE: il turno di Rio non arriva")
		quit(1)
		return
	await create_timer(1.0).timeout
	await _shot("01_hud_normale")
	bt.call("_pick", "skill")
	await create_timer(0.6).timeout
	await _shot("02_skill_ombra")
	bt.call("_pick", "")
	await create_timer(0.3).timeout
	bt.call("_pick", "ult")
	await create_timer(0.7).timeout
	await _shot("03_ultimate_ombra")
	bt.call("_pick", "")
	await create_timer(0.3).timeout
	# vita bassa: si rifanno i comandi del turno con i PV cambiati (lo stesso giro di quando tocca a lui)
	rio["hp"] = int(float(rio["max_hp"]) * 0.45)
	bt.call("_show_commands", true)
	bt.call("_refresh_hud")
	await create_timer(0.5).timeout
	await _shot("04_vita_sotto_50")
	rio["hp"] = int(float(rio["max_hp"]) * 0.2)
	bt.call("_show_commands", true)
	bt.call("_refresh_hud")
	await create_timer(0.5).timeout
	await _shot("05_vita_sotto_25")
	# BREAK causato da Rio: gli stessi eventi che manda il motore
	bt.call("_show_events", [{"t": "damage", "src": str(rio["id"]), "dst": "boss", "amount": 40}, {"t": "break"}], false)
	await _aspetta_lampo()
	await _shot("06_break")
	await create_timer(1.5).timeout
	# K.O.: SEGNALE PERSO
	rio["hp"] = 0
	bt.call("_refresh_hud")
	bt.call("_signal_lost_later", str(rio["id"]), 0.0)
	await _aspetta_lampo()
	await _shot("07_ko_segnale_perso")
	await create_timer(4.6, true, false, true).timeout       # con lento = 6 la figura si schiaccia dopo ~4 s
	await _shot("07b_ko_si_spegne")
	await create_timer(3.5, true, false, true).timeout
	await create_timer(1.0).timeout
	await _shot("08_ko_fila_squadra")
	# pausa
	rio["hp"] = int(rio["max_hp"])
	bt.call("_refresh_hud")
	bt.call("_open_pause")
	await create_timer(1.2, true, false, true).timeout          # le animazioni della pausa ignorano time_scale = 0
	await _shot("09_pausa")
	bt.call("_close_pause")
	await process_frame
	bt.queue_free()
	await create_timer(0.3).timeout
	# --- 2) la Replica (NG+): skin magenta ---
	Story.flags["replica"] = 1
	await _battaglia()
	rio = _rio()
	if await _turno_di_rio():
		await create_timer(1.0).timeout
		await _shot("10_ng_plus_skin")
	Story.flags["replica"] = 0
	bt.queue_free()
	await create_timer(0.3).timeout
	# --- 3) schermata di caricamento: si entra in battaglia dal gioco vero (main) ---
	var m: Node = load("res://scripts/v3/main.gd").new()
	root.add_child(m)
	await create_timer(1.0).timeout
	m.call("go", "battle", {"boss": "autovelox", "livello": 11, "arena": "tangenziale"})
	var car: Control = m.get("_carico")
	for k in 600:
		if car != null and car.modulate.a > 0.95:
			break
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out.path_join("11_caricamento_ricordo.png"))
	print("FOTO 11_caricamento_ricordo")
	await create_timer(1.0).timeout
	quit()
