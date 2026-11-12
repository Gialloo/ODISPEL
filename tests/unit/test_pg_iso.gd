extends SceneTree

# PROVA GREZZA 3 · di nuovo a scorrimento (vista isometrica), con le migliorie decise il 12/11 sera:
# squadra a cambio rapido (un solo personaggio in campo), STAFFETTA, CAMBIO IN DIFESA, KO e ingresso del prossimo,
# carica (scatto e CONTRO CARICATO, annullata dal passo indietro), schiacciata caricata da sospesi, montante,
# BLACKOUT di squadra, PIANO con carica e cambio, e scontri interi.
const E = preload("res://scripts/prova_grezza/pg_engine.gd")

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


func _steps(e: PgEngine, n: int) -> void:
	for _i in range(n):
		e.step(E.TICK)


func _to_tele(e: PgEngine, kind: String, left: float) -> bool:
	for _i in range(60 * 60):
		e.step(E.TICK)
		e.hp = E.HP_MAX
		var d: Dictionary = e.danger()
		if not d.is_empty() and d["kind"] != kind:
			e.iframes = 1.0
		if not d.is_empty() and d["kind"] == kind and float(d["left"]) <= left:
			e.iframes = 0.0
			return true
	return false


func _near(e: PgEngine) -> void:
	e.px = e.ex - 1.3
	e.idle_wait = 99.0
	e.est = "idle"


func _tap(e: PgEngine, n: int = 10) -> void:
	e.press_attack()
	e.release_attack()
	_steps(e, n)


func _initialize() -> void:
	# 1. carica e scatto
	var e := E.new(3, 4)
	_near(e)
	e.px = e.ex - 4.0
	e.press_attack()
	_steps(e, 70)
	check(e.st == "charge" and e.charge_level() >= 2, "tenere premuto carica (livello %d)" % e.charge_level())
	var ehp0: float = e.ehp
	e.release_attack()
	_steps(e, 20)
	check(e.found.size() >= 0 and ehp0 - e.ehp >= 26.0, "lo scatto caricato arriva e colpisce forte (%.0f)" % (ehp0 - e.ehp))

	# 2. CONTRO CARICATO
	e = E.new(3, 4)
	e.press_attack()
	var guard: int = 0
	while guard < 900:
		e.step(E.TICK)
		guard += 1
		var d: Dictionary = e.danger()
		if not d.is_empty() and d["kind"] != "affondo":
			e.iframes = 0.5
		if not d.is_empty() and d["kind"] == "affondo" and float(d["left"]) <= 0.15:
			break
	e.take_events()
	e.release_attack()
	var c: Dictionary = _has(e.take_events(), "contro")
	check(not c.is_empty() and int(c["lv"]) >= 1 and e.found.has("contro_caricato"), "CONTRO CARICATO")

	# 3. il passo indietro annulla la carica
	e = E.new(3, 4)
	_near(e)
	e.press_attack()
	_steps(e, 20)
	e.input("via")
	check(e.st == "dodge" and not _has(e.take_events(), "carica_annullata").is_empty(), "passo indietro annulla la carica")
	e.release_attack()

	# 4. montante, giocoliere, schiacciata caricata
	e = E.new(3, 4)
	_near(e)
	e.posture = "blu"
	_tap(e)
	_tap(e)
	_steps(e, 25)
	_tap(e, 14)
	check(e.found.has("montante") and e.est == "air", "colpo, colpo, pausa, colpo: montante")
	for k in 3:
		_tap(e, 16)
	check(e.found.has("giocoliere"), "giocoliere")
	e.press_attack()
	_steps(e, 40)
	check(e.st == "hover", "in aria tenere premuto: sospeso")
	e.release_attack()
	_steps(e, 25)
	check(e.found.has("schianto"), "schiacciata caricata")

	# 5. staffetta
	e = E.new(3, 4)
	_near(e)
	_tap(e, 0)
	guard = 0
	while not e.can_cancel_now() and guard < 40:
		e.step(E.TICK)
		guard += 1
	e.input("cambio")
	_steps(e, 20)
	check(e.active == 1 and e.found.has("staffetta"), "STAFFETTA: cambio nel lampo bianco")
	check(e.posture == "blu", "chi entra porta la sua postura")

	# 6. CAMBIO IN DIFESA
	e = E.new(3, 4)
	check(_to_tele(e, "spazzata", 0.15), "SPAZZATA per il cambio in difesa")
	var hp0: float = e.hp
	e.take_events()
	e.input("cambio")
	c = _has(e.take_events(), "contro")
	_steps(e, 20)
	check(not c.is_empty() and c["cambio"] and e.found.has("cambio_difesa") and e.hp == E.HP_MAX, "CAMBIO IN DIFESA para anche la SPAZZATA")

	# 7. KO: entra il prossimo, senza parata gratis
	e = E.new(3, 4)
	check(_to_tele(e, "affondo", 0.05), "AFFONDO per il KO")
	e.hp = 1.0
	_steps(e, 10)
	check(e.party[0]["ko"] and e.active == 1 and e.over == "", "KO: entra il secondo")
	check(not e.found.has("cambio_difesa"), "il cambio forzato non para")

	# 8. BLACKOUT di squadra
	e = E.new(3, 4)
	_near(e)
	e.seg = 0.5
	e.last_seg_loss = e.time
	_tap(e, 12)
	check(e.est == "crollo", "CROLLO")
	e.take_events()
	e.input("verso")
	_steps(e, 70)
	var b: Dictionary = _has(e.take_events(), "blackout")
	check(not b.is_empty() and int(b["team"]) == 3, "BLACKOUT con tutta la squadra")

	# 9. PIANO con carica e cambio
	e = E.new(3, 4)
	_near(e)
	e.fiato = 60.0
	check(e.start_plan(["tocco", "carica", "cambio"]), "PIANO parte")
	_steps(e, 150)
	var passi: int = 0
	for x in e.take_events():
		if x["type"] == "piano_passo":
			passi += 1
	check(passi == 3 and e.active == 1, "PIANO in onda con carica e cambio (%d passi)" % passi)

	# 10. scontri interi con la squadra da 4
	var r1: Dictionary = _bot(11, "bravo")
	print("bravo: %s in %.1f s, KO %d, scoperte %d" % [r1["over"], r1["time"], r1["ko"], r1["found"]])
	check(r1["over"] == "vittoria", "il bravo vince")
	check(is_equal_approx(r1["time"], _bot(11, "bravo")["time"]), "stesso seme, stessa partita")
	var r3: Dictionary = _bot(11, "fermo")
	print("fermo: %s in %.1f s" % [r3["over"], r3["time"]])
	check(r3["over"] == "sconfitta", "chi sta fermo perde")
	var vinte: int = 0
	for sd in range(1, 9):
		var r4: Dictionary = _bot(sd, "caso")
		if r4["over"] == "vittoria" and r4["time"] < r1["time"] * 3.0:
			vinte += 1
	print("caso: %d vittorie su 8 in meno del triplo del tempo del bravo" % vinte)
	check(vinte <= 2, "a caso non si vince in fretta (con 4 personaggi chi preme a caso dura di più, ma ci mette 3 volte tanto)")

	print("pg_iso: " + ("OK" if fails == 0 else "%d FAIL" % fails))
	quit(0 if fails == 0 else 1)


func _bot(seed_v: int, kind: String) -> Dictionary:
	var e := E.new(seed_v, 4)
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var cool: float = 0.0
	for _i in range(60 * 400):
		e.step(E.TICK)
		e.take_events()
		if e.over != "":
			break
		cool -= E.TICK
		if kind == "fermo" or cool > 0.0:
			continue
		if kind == "caso":
			var gs: Array = ["tocco", "verso", "via", "su", "giu", "postura", "cambio"]
			e.input(gs[r.randi_range(0, gs.size() - 1)])
			cool = 0.2
			continue
		var d: Dictionary = e.danger()
		if not d.is_empty():
			if d["kind"] == "affondo":
				if d["color"] != e.posture:
					e.input("postura")
				if float(d["left"]) <= 0.18:
					e.input("verso")
					cool = 0.1
			elif float(d["left"]) <= 0.25:
				e.input("su")
				cool = 0.1
			continue
		if e.est == "crollo":
			e.input("verso")
			cool = 0.3
			continue
		if e.st == "idle" or e.can_cancel_now():
			if e.est == "air" and e.p_air <= 0.0:
				e.input("su")
			else:
				e.input("tocco")
			cool = 0.12
	var ko: int = 0
	for m in e.party:
		if m["ko"]:
			ko += 1
	return {"over": e.over, "time": e.time, "ko": ko, "found": e.found.size()}
