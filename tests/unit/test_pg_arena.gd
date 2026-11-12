extends SceneTree

# PROVA GREZZA 2 · arena circolare, squadra da 4 (due davanti, due dietro), colpi caricati.
# Si prova: CONTRO e CONTRO CARICATO, scarto laterale fuori dalla linea dell'AFFONDO, salto sull'anello della SPAZZATA,
# colpo alle spalle, montante (colpo, colpo, pausa, colpo), schiacciata caricata, staffetta, COPERTURA, KO e
# ingresso di chi sta dietro, muro ad anello, CROLLO e BLACKOUT di squadra, PIANO, e scontri interi.
const A = preload("res://scripts/prova_grezza/pg_arena.gd")

var fails: int = 0


func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _has(evs: Array, t: String) -> Dictionary:
	for e in evs:
		if e["type"] == t:
			return e
	return {}


func _steps(e: PgArena, n: int) -> void:
	for _i in range(n):
		e.step(A.TICK)


func _to_tele(e: PgArena, kind: String, left: float, on_me: bool = true) -> bool:
	for _i in range(60 * 60):
		e.step(A.TICK)
		for f in e.fighters:
			f.hp = f.maxhp
		var d: Dictionary = e.danger()
		var ok: bool = not d.is_empty() and d["kind"] == kind and (not on_me or int(d["target"]) == e.active)
		if not d.is_empty() and not ok:
			for f in e.fighters:
				f.iframes = 0.6
		if ok and float(d["left"]) <= left:
			for f in e.fighters:
				f.iframes = 0.0
			return true
	return false


func _near(e: PgArena, dist: float = 1.4) -> void:
	# mette il controllato davanti al nemico, ferma il nemico
	e.me().pos = e.epos + Vector2(0, dist)
	e.efacing = Vector2(0, 1)
	e.est = "idle"
	e.eatk = {}
	e.idle_wait = 99.0
	e.me().st = "idle"
	e.me().p_air = 0.0


func _initialize() -> void:
	# 1. CONTRO sull'AFFONDO che punta a te
	var e := A.new(3)
	check(_to_tele(e, "affondo", 0.2), "arriva un AFFONDO su di me")
	e.take_events()
	e.input("verso")
	check(not _has(e.take_events(), "contro").is_empty() and e.est == "stun", "CONTRO")

	# 2. CONTRO CARICATO: carica e rilascia a tempo
	e = A.new(3)
	e.press_attack()
	_steps(e, 30)
	check(e.me().st == "charge" and e.charge_level() >= 1, "tenere premuto carica")
	var seg0: float = e.seg
	var guard: int = 0
	while guard < 600:
		e.step(A.TICK)
		guard += 1
		var dd: Dictionary = e.danger()
		if not dd.is_empty() and int(dd["target"]) != e.active:
			for f in e.fighters:
				f.iframes = 0.5
		if not dd.is_empty() and dd["kind"] == "affondo" and int(dd["target"]) == e.active and float(dd["left"]) <= 0.15:
			break
	seg0 = e.seg
	e.take_events()
	e.release_attack()
	var c: Dictionary = _has(e.take_events(), "contro")
	check(not c.is_empty() and int(c["lv"]) >= 2, "CONTRO CARICATO (livello %d)" % int(c.get("lv", 0)))
	check(seg0 - e.seg > 25.0, "il CONTRO CARICATO toglie molto SEGNALE (%.0f)" % (seg0 - e.seg))

	# 3. carica annullata con lo scarto
	e = A.new(3)
	_near(e, 3.0)
	e.press_attack()
	_steps(e, 20)
	e.input("sx")
	check(e.me().st == "dodge" and not _has(e.take_events(), "carica_annullata").is_empty(), "lo scarto annulla la carica")
	e.release_attack()

	# 4. scarto laterale fuori dalla linea dell'AFFONDO (niente i-frame: è la posizione che salva)
	e = A.new(3)
	check(_to_tele(e, "affondo", 0.3), "AFFONDO per lo scarto")
	var hp0: float = e.me().hp
	e.input("dx")
	e.me().iframes = 0.0
	_steps(e, 30)
	check(e.me().hp == hp0, "fuori dalla linea non ti prende")

	# 5. SPAZZATA: salto sull'anello
	e = A.new(3)
	check(_to_tele(e, "spazzata", 0.3), "arriva una SPAZZATA")
	e.me().pos = e.epos + Vector2(0, 2.0)
	hp0 = e.me().hp
	e.input("salto")
	_steps(e, 24)
	check(e.me().hp == hp0 and e.castigo_until > 0.0, "salto sull'anello")

	# 6. alle spalle
	e = A.new(3)
	_near(e)
	e.efacing = Vector2(0, -1)      # guarda dall'altra parte
	e.take_events()
	e.press_attack()
	e.release_attack()
	_steps(e, 12)
	check(e.found.has("alle_spalle"), "colpo alle spalle")

	# 7. montante: colpo, colpo, pausa, colpo, poi giocoliere e schiacciata caricata
	e = A.new(3)
	_near(e)
	e.me().posture = "blu"
	for k in 2:
		e.press_attack()
		e.release_attack()
		_steps(e, 10)
	_steps(e, 30)
	e.press_attack()
	e.release_attack()
	_steps(e, 14)
	check(e.found.has("montante") and e.est == "air", "montante con la pausa")
	for k in 3:
		e.press_attack()
		e.release_attack()
		_steps(e, 16)
	check(e.found.has("giocoliere"), "giocoliere")
	e.press_attack()
	_steps(e, 50)
	check(e.me().st == "hover", "in aria tenere premuto: sospeso")
	e.release_attack()
	_steps(e, 20)
	check(e.found.has("schianto"), "schiacciata caricata")

	# 8. staffetta: cambio nel lampo bianco
	e = A.new(3)
	_near(e)
	e.partner().pos = e.epos + Vector2(1.6, 0)
	e.press_attack()
	e.release_attack()
	var g: int = 0
	while not e.can_cancel_now() and g < 40:
		e.step(A.TICK)
		g += 1
	var old: int = e.active
	e.input("cambio")
	_steps(e, 20)
	check(e.active != old and e.found.has("staffetta"), "staffetta")

	# 9. COPERTURA e KO con ingresso da dietro
	e = A.new(3)
	check(_to_tele(e, "affondo", 0.05), "AFFONDO per la copertura")
	e.me().hp = 10.0
	e.cover_ready = 0.0
	e.take_events()
	_steps(e, 10)
	check(not _has(e.take_events(), "copertura").is_empty() and e.me().hp == 10.0, "COPERTURA da dietro")
	check(_to_tele(e, "affondo", 0.05), "altro AFFONDO")
	var who: int = e.active
	e.me().hp = 1.0
	e.cover_ready = 999.0
	_steps(e, 10)
	check(e.fighters[who].st == "ko" and not e.fighters[who].front and e.me().front and e.active != who, "KO: entra uno da dietro")

	# 10. muro dell'anello
	e = A.new(3)
	e.epos = Vector2(0, -6.5)
	_near(e)
	e.me().posture = "rosso"
	e.input("verso")
	_steps(e, 20)
	check(e.found.has("muro"), "AL MURO sul bordo dell'arena")

	# 11. CROLLO e BLACKOUT di squadra
	e = A.new(3)
	_near(e)
	e.seg = 1.0
	e.last_seg_loss = e.time
	e.press_attack()
	e.release_attack()
	_steps(e, 12)
	check(e.est == "crollo", "CROLLO")
	var ehp0: float = e.ehp
	e.take_events()
	e.input("verso")
	_steps(e, 70)
	var b: Dictionary = _has(e.take_events(), "blackout")
	check(not b.is_empty() and int(b["team"]) == 2 and ehp0 - e.ehp > A.ENEMY_HP * A.BLACKOUT_FRAC, "BLACKOUT con i due dietro")

	# 12. PIANO con carica e cambio
	e = A.new(3)
	_near(e)
	e.fiato = 60.0
	check(e.start_plan(["tocco", "carica", "cambio"]), "PIANO parte")
	_steps(e, 120)
	var passi: int = 0
	for x in e.take_events():
		if x["type"] == "piano_passo":
			passi += 1
	check(passi == 3, "PIANO in onda (%d passi)" % passi)

	# 13. scontri interi
	var r1: Dictionary = _bot(11, "bravo")
	print("bravo: %s in %.1f s, KO %d, scoperte %d" % [r1["over"], r1["time"], r1["ko"], r1["found"]])
	check(r1["over"] == "vittoria", "il bravo vince")
	check(r1["time"] > 30.0 and r1["time"] < 240.0, "durata del bravo (%.0f s)" % r1["time"])
	check(is_equal_approx(r1["time"], _bot(11, "bravo")["time"]), "stesso seme, stessa partita")
	var r3: Dictionary = _bot(11, "fermo")
	print("fermo: %s in %.1f s" % [r3["over"], r3["time"]])
	check(r3["over"] == "sconfitta", "chi sta fermo perde")
	var vinte: int = 0
	for sd in range(1, 7):
		var r4: Dictionary = _bot(sd, "caso")
		if r4["over"] == "vittoria" and r4["time"] < 150.0:
			vinte += 1
	print("caso: %d vittorie rapide su 6" % vinte)
	check(vinte <= 1, "a caso non si vince in fretta")

	print("pg_arena: " + ("OK" if fails == 0 else "%d FAIL" % fails))
	quit(0 if fails == 0 else 1)


func _bot(seed_v: int, kind: String) -> Dictionary:
	var e := A.new(seed_v)
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var cool: float = 0.0
	for _i in range(60 * 300):
		e.step(A.TICK)
		e.take_events()
		if e.over != "":
			break
		cool -= A.TICK
		if kind == "fermo":
			continue
		if kind == "caso":
			if cool <= 0.0:
				e.set_move(Vector2(r.randf_range(-1, 1), r.randf_range(-1, 1)))
				var gs: Array = ["tocco", "verso", "via", "sx", "dx", "salto", "postura", "cambio", "giu"]
				e.input(gs[r.randi_range(0, gs.size() - 1)])
				cool = 0.2
			continue
		var f: PgArena.Fighter = e.me()
		var d: Dictionary = e.danger()
		var dist: float = e.epos.distance_to(f.pos)
		e.set_move(Vector2(0, 1) if dist > 1.6 else Vector2.ZERO)
		if cool > 0.0:
			continue
		if not d.is_empty() and int(d["target"]) == e.active:
			if d["kind"] == "affondo":
				if d["color"] != f.posture:
					e.input("postura")
				if float(d["left"]) <= 0.18:
					e.input("verso")
					cool = 0.1
			elif float(d["left"]) <= 0.25:
				e.input("salto")
				cool = 0.1
			continue
		if e.est == "crollo":
			e.input("verso")
			cool = 0.3
			continue
		if (f.st == "idle" or e.can_cancel_now()) and dist <= A.REACH:
			e.input("tocco")
			cool = 0.12
	var ko: int = 0
	for f in e.fighters:
		if f.st == "ko":
			ko += 1
	return {"over": e.over, "time": e.time, "ko": ko, "found": e.found.size()}
