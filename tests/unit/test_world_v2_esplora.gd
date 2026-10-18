extends SceneTree
# Esplorazione del Test V2 (zone nuove, scoperte, vernice, panchine, corsa): godot -s tests/unit/test_world_v2_esplora.gd
var fails := 0
func ok(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)
func _tp(w, p: Vector2) -> void:
	w.player = p
	w._seed_trail()
	w._place_all()
func _init() -> void:
	_run()
func _run() -> void:
	Settings.tutorial_done = true
	WorldV2Ctx.reset()
	WorldV2Ctx.active = true
	WorldV2Ctx.read["intro"] = true
	var scn = (load("res://scenes/world_v2/world_v2.tscn") as PackedScene).instantiate()
	root.add_child(scn)
	await create_timer(0.5).timeout
	ok(scn.mode == "walk", "si parte a camminare")
	# --- raggiungibilita': flood fill dalla piazza (serranda chiusa) con la stessa collisione del giocatore
	var step: float = 0.35
	var seen: Dictionary = {}
	var q: Array = [Vector2i(int(round(scn.SPAWN.x / step)), int(round(scn.SPAWN.y / step)))]
	seen[q[0]] = true
	var qi: int = 0
	while qi < q.size():
		var c: Vector2i = q[qi]
		qi += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if seen.has(n):
				continue
			if scn._free(Vector2(n.x * step, n.y * step)):
				seen[n] = true
				q.append(n)
	var unreachable: Array = []
	for o in scn.talk_objs:
		var id: String = str(o["id"])
		if id == "boss" or id == "terminale_x":
			continue
		var pos: Vector2 = o["pos"]
		var rad: float = float(o["radius"])
		var hit: bool = false
		var r: int = int(rad / step) + 1
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				var cell := Vector2i(int(round(pos.x / step)) + dx, int(round(pos.y / step)) + dz)
				if seen.has(cell) and Vector2(cell.x * step, cell.y * step).distance_to(pos) <= rad:
					hit = true
		if not hit:
			unreachable.append(id)
	# con la serranda chiusa il Largo e il boss restano chiusi: solo quelli sono ammessi
	for id in unreachable:
		ok(id in ["serranda", "boss", "terminale"] and false or id == "boss", "oggetto irraggiungibile: " + str(id))
	print("scoperte totali: ", scn._disc.size(), "  oggetti: ", scn.talk_objs.size(), "  non raggiungibili: ", unreachable)
	ok(scn._disc.size() >= 40, "almeno 40 scoperte (%d)" % scn._disc.size())
	# ogni zona nuova e' raggiungibile a piedi
	for i in range(scn.AREAS.size()):
		var rc: Rect2 = scn.AREAS[i]["rect"]
		var any: bool = false
		for cell in seen.keys():
			if rc.has_point(Vector2(cell.x * step, cell.y * step)):
				any = true
				break
		if i == 3 or i == 4:
			continue           # via della serranda e largo: chiuse dalla serranda
		ok(any, "zona raggiungibile: " + str(scn.AREAS[i]["name"]))
	# --- scoperta: leggere un oggetto la registra una volta sola
	_tp(scn, Vector2(25.5, -2.6))
	await create_timer(0.3).timeout
	ok(str(scn._near.get("id", "")) == "ramen", "banco del ramen vicino (%s)" % str(scn._near.get("id", "")))
	var n0: int = scn._found_count()
	scn._last_adv = -10.0
	scn._interact_pressed()
	ok(WorldV2Ctx.found.has("ramen") and scn._found_count() == n0 + 1, "scoperta registrata")
	while scn.mode == "dialog":
		scn._last_adv = -10.0
		scn._advance_dialog()
	scn._last_adv = -10.0
	scn._interact_pressed()
	ok(scn._found_count() == n0 + 1, "stessa scoperta non conta due volte")
	while scn.mode == "dialog":
		scn._last_adv = -10.0
		scn._advance_dialog()
	# --- zone visitate
	ok(WorldV2Ctx.zones.has(5), "zona visitata (mercato)")
	# --- vernice: primo colpo, poi cambia colore; salva nel contesto
	_tp(scn, Vector2(-38.2, 4.5))
	await create_timer(0.3).timeout
	ok(scn._near.has("spray"), "muro da dipingere vicino")
	scn._last_adv = -10.0
	scn._use(scn._near)
	ok(WorldV2Ctx.sprayed.size() == 1 and WorldV2Ctx.found.has("tag1"), "tag dipinto e scoperta")
	var c0: int = int(WorldV2Ctx.sprayed[0]["c"])
	scn._use(scn._near)
	ok(WorldV2Ctx.sprayed.size() == 1 and int(WorldV2Ctx.sprayed[0]["c"]) != c0, "secondo spruzzo cambia colore")
	# --- panchina: ci si siede, si resta fermi, ci si alza muovendosi
	_tp(scn, Vector2(-9.0, 21.95))
	await create_timer(0.3).timeout
	ok(str(scn._near.get("id", "")) == "panca_c", "panchina vicina")
	scn._last_adv = -10.0
	scn._use(scn._near)
	ok(scn.mode == "sit", "seduto")
	var ps: Vector2 = scn.player
	await create_timer(1.0).timeout
	ok(scn.player.distance_to(ps) < 0.01, "da seduto non ci si muove")
	scn.test_move = Vector2(0, -1)
	await create_timer(0.4).timeout
	ok(scn.mode == "walk", "muovendosi ci si alza")
	scn.test_move = Vector2.ZERO
	await create_timer(0.3).timeout
	# --- inerzia e corsa
	_tp(scn, Vector2(-8.0, 18.5))
	scn._vel = Vector2.ZERO
	scn._run_on = false
	var x0: float = scn.player.x
	scn.test_move = Vector2(1, 0)
	await create_timer(0.05).timeout
	ok(scn._vel.length() < scn.SPEED, "parte con inerzia (v=%.2f)" % scn._vel.length())
	await create_timer(1.0).timeout
	var dwalk: float = scn.player.x - x0
	scn.test_move = Vector2.ZERO
	await create_timer(0.5).timeout
	ok(scn._vel.length() < 0.5, "si ferma")
	_tp(scn, Vector2(-8.0, 18.5))
	scn._run_on = true
	x0 = scn.player.x
	scn.test_move = Vector2(1, 0)
	await create_timer(1.0).timeout
	var drun: float = scn.player.x - x0
	scn.test_move = Vector2.ZERO
	scn._run_on = false
	ok(drun > dwalk * 1.3, "correre e' piu' veloce (%.1f vs %.1f)" % [drun, dwalk])
	# --- acqua: non si cammina fuori dalla banchina
	_tp(scn, Vector2(20, 22))
	scn.test_move = Vector2(0, 1)
	await create_timer(1.5).timeout
	ok(scn.player.y < 24.0, "il canale ferma (z=%.2f)" % scn.player.y)
	scn.test_move = Vector2.ZERO
	# --- PNG: il gatto cammina, e si ferma quando il giocatore e' vicino
	var cat: Dictionary = {}
	for n in scn._npcs:
		if n["kind"] == "cat" and (n["route"] as Array).size() > 1:
			cat = n
	ok(not cat.is_empty(), "gatto vagante presente")
	_tp(scn, Vector2(-30, -3))
	var cp0: Vector2 = cat["pos"]
	await create_timer(4.0).timeout
	ok((cat["pos"] as Vector2).distance_to(cp0) > 0.5, "il gatto si muove")
	_tp(scn, cat["pos"])
	var cp1: Vector2 = cat["pos"]
	await create_timer(1.0).timeout
	ok((cat["pos"] as Vector2).distance_to(cp1) < 0.05, "il gatto si ferma se gli sei vicino")
	# --- panorama: la camera si allarga una volta
	WorldV2Ctx.read.erase("vista")
	_tp(scn, Vector2(36, -19.5))
	await create_timer(2.5).timeout
	ok(scn.cam.size > scn.CAM_SIZE + 2.0, "panorama allarga la camera (%.1f)" % scn.cam.size)
	ok(WorldV2Ctx.found.has("panorama"), "panorama scoperto")
	# --- salvataggio esplorazione su disco (solo se persist)
	WorldV2Ctx.persist = false
	WorldV2Ctx.save_persist()
	ok(not FileAccess.file_exists(WorldV2Ctx.SAVE_PATH), "senza persist non si scrive nulla")
	WorldV2Ctx.persist = true
	WorldV2Ctx.save_persist()
	var f0: int = WorldV2Ctx.found.size()
	var z0: int = WorldV2Ctx.zones.size()
	WorldV2Ctx.found = {}
	WorldV2Ctx.zones = {}
	WorldV2Ctx.sprayed = []
	WorldV2Ctx.load_persist()
	ok(WorldV2Ctx.found.size() == f0 and WorldV2Ctx.zones.size() == z0 and WorldV2Ctx.sprayed.size() == 1, "esplorazione ricaricata (%d/%d)" % [WorldV2Ctx.found.size(), WorldV2Ctx.sprayed.size()])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(WorldV2Ctx.SAVE_PATH))
	WorldV2Ctx.reset()
	print("esplora: ", "OK" if fails == 0 else "FAIL %d" % fails)
	quit(1 if fails > 0 else 0)
