extends SceneTree

# PROVA GREZZA · motore del Manichino da prova (core CONTROSEGNALE v2).
# Si prova: CONTRO buono/perfetto/di frequenza, verso troppo presto (danno doppio), salto sulla SPAZZATA e castigo,
# schivata, annullamento col FIATO, muro, CROLLO e BLACKOUT, PIANO, scrollata anti-catena infinita,
# e scontri interi con un giocatore bravo, uno fermo e uno a caso (stesso seme = stessa partita).
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


func _to_tele(e: PgEngine, kind: String, left: float) -> bool:
	# avanza finché il nemico mira un colpo del tipo voluto e mancano 'left' secondi all'impatto
	for _i in range(60 * 60):
		e.step(E.TICK)
		var d: Dictionary = e.danger()
		if not d.is_empty() and d["kind"] != kind:
			e.hp = E.HP_MAX
			e.iframes = 1.0      # i colpi che non ci servono passano senza fare danno
		if not d.is_empty() and d["kind"] == kind and float(d["left"]) <= left:
			e.iframes = 0.0
			return true
	return false


func _initialize() -> void:
	# 1. CONTRO buono
	var e := E.new(3)
	check(_to_tele(e, "affondo", 0.25), "arriva un AFFONDO")
	e.posture = "rosso" if e.danger()["color"] == "blu" else "blu"
	e.take_events()
	e.input("verso")
	var ev: Array = e.take_events()
	var c: Dictionary = _has(ev, "contro")
	check(not c.is_empty() and not c["perfect"] and not c["freq"], "CONTRO buono a 250 ms")
	check(e.est == "stun" and e.seg < E.SEG_MAX, "il CONTRO ferma il nemico e toglie SEGNALE")
	check(e.found.has("contro"), "Registro: CONTRO")

	# 2. CONTRO perfetto e di frequenza
	e = E.new(3)
	check(_to_tele(e, "affondo", 0.07), "AFFONDO quasi all'impatto")
	e.posture = e.danger()["color"]
	var seg0: float = e.seg
	e.take_events()
	e.input("verso")
	c = _has(e.take_events(), "contro")
	check(not c.is_empty() and c["perfect"] and c["freq"], "CONTRO perfetto e di frequenza")
	check(seg0 - e.seg >= 49.0, "la frequenza toglie molto SEGNALE (%.0f)" % (seg0 - e.seg))
	check(e.est_t > 1.0, "UN ALTRO: il nemico resta fermo più a lungo")

	# 3. memoria: un gesto 100 ms prima della finestra conta
	e = E.new(3)
	check(_to_tele(e, "affondo", E.WIN + 0.08), "AFFONDO appena prima della finestra")
	e.take_events()
	e.input("verso")
	check(not _has(e.take_events(), "contro").is_empty(), "memoria del gesto: CONTRO")

	# 4. verso troppo presto = danno doppio
	e = E.new(3)
	check(_to_tele(e, "affondo", 0.7), "AFFONDO lontano")
	var hp0: float = e.hp
	e.input("verso")
	check(not _has(e.take_events(), "troppo_presto").is_empty(), "segnala il troppo presto")
	for _i in range(60):
		e.step(E.TICK)
	check(is_equal_approx(hp0 - e.hp, E.ATTACKS["affondo"]["dmg"] * 2.0), "troppo presto: danno doppio (%.0f)" % (hp0 - e.hp))

	# 5. SPAZZATA saltata e castigo in aria
	e = E.new(3)
	check(_to_tele(e, "spazzata", 0.3), "arriva una SPAZZATA")
	hp0 = e.hp
	e.input("su")
	for _i in range(24):
		e.step(E.TICK)
	ev = e.take_events()
	check(not _has(ev, "saltata").is_empty() and e.hp == hp0, "salto sopra la SPAZZATA")
	e.px = e.ex - 1.2
	e.input("tocco")
	for _i in range(12):
		e.step(E.TICK)
	check(e.found.has("salto_castigo"), "castigo dopo il salto")

	# 6. schivata
	e = E.new(3)
	check(_to_tele(e, "affondo", 0.1), "AFFONDO per la schivata")
	hp0 = e.hp
	e.input("via")
	for _i in range(20):
		e.step(E.TICK)
	check(not _has(e.take_events(), "schivata").is_empty() and e.hp == hp0, "schivata con passo indietro")

	# 7. annullamento: costa FIATO, solo nel lampo bianco
	e = E.new(3)
	e.px = 5.6
	e.idle_wait = 99.0
	e.input("tocco")
	var guard: int = 0
	while not e.can_cancel_now() and guard < 60:
		e.step(E.TICK)
		guard += 1
	check(e.can_cancel_now(), "il colpo a segno apre il lampo bianco")
	var f0: float = e.fiato
	e.input("su")
	check(is_equal_approx(f0 - e.fiato, E.CANCEL_COST) and e.move.get("id", "") == "lancio", "annullo il colpo nel lancio")
	check(e.found.has("annullo"), "Registro: annullamento")

	# 8. lancio, giocoliere, schiacciata
	for _i in range(12):
		e.step(E.TICK)
	check(e.est == "air" and e.p_air > 0.0, "il lancio porta in aria tutti e due")
	for _k in range(3):
		e.input("tocco")
		for _i in range(20):
			e.step(E.TICK)
	check(e.found.has("giocoliere"), "tre colpi in aria: giocoliere")
	e.input("giu")
	for _i in range(20):
		e.step(E.TICK)
	check(e.found.has("schiacciata") and e.est == "down", "schiacciata a terra")

	# 9. muro
	e = E.new(3)
	e.ex = 10.6
	e.px = 9.0
	e.idle_wait = 99.0
	e.input("verso")
	for _i in range(20):
		e.step(E.TICK)
	check(e.found.has("muro"), "l'affondo inchioda al muro")

	# 10. CROLLO e BLACKOUT
	e = E.new(3)
	e.px = 5.6
	e.idle_wait = 99.0
	e.seg = 2.0
	e.input("tocco")
	for _i in range(20):
		e.step(E.TICK)
	check(e.est == "crollo", "SEGNALE a zero: CROLLO")
	var ehp0: float = e.ehp
	e.input("verso")
	for _i in range(70):
		e.step(E.TICK)
	check(e.found.has("blackout") and ehp0 - e.ehp >= E.ENEMY_HP * E.BLACKOUT_FRAC - 0.1, "BLACKOUT dal CROLLO")
	check(e.seg == E.SEG_MAX and e.phase == 1, "dopo il BLACKOUT il SEGNALE torna e il nemico cambia passo")

	# 11. PIANO
	e = E.new(3)
	e.px = 5.6
	e.idle_wait = 99.0
	e.fiato = 50.0
	check(e.start_plan(["tocco", "tocco", "su"]), "il PIANO parte con FIATO sufficiente")
	check(is_equal_approx(e.fiato, 50.0 - E.PIANO_COST), "il PIANO costa FIATO")
	for _i in range(90):
		e.step(E.TICK)
	var passi: int = 0
	for x in e.take_events():
		if x["type"] == "piano_passo":
			passi += 1
	check(passi == 3 and not e.plan_active, "il PIANO va in onda tutto (%d passi)" % passi)
	check(not e.start_plan(["tocco"]), "senza FIATO il PIANO non parte")

	# 12. PIANO + CONTRO: il pollice sospende il PIANO senza cancellarlo
	e = E.new(3)
	e.fiato = 80.0
	check(_to_tele(e, "affondo", 0.2), "AFFONDO durante il PIANO")
	e.start_plan(["tocco", "tocco"])
	e.input("verso")
	check(e.found.has("piano_contro") and e.plan_active, "CONTRO dentro il PIANO, il PIANO resta")

	# 13. scrollata
	e = E.new(3)
	e.px = 5.6
	e.idle_wait = 99.0
	e.seg = 1000.0
	var scrollata: bool = false
	for _k in range(12):
		e.px = e.ex - 1.3
		e.input("tocco")
		for _i in range(11):
			e.step(E.TICK)
		if not _has(e.take_events(), "scrollata").is_empty():
			scrollata = true
	check(scrollata, "niente catene infinite: il nemico si scrolla")

	# 14. scontri interi
	var r1: Dictionary = _bot(11, "bravo")
	print("bravo: %s in %.1f s, vita %.0f, scoperte %d" % [r1["over"], r1["time"], r1["hp"], r1["found"]])
	check(r1["over"] == "vittoria", "il giocatore bravo vince")
	check(r1["time"] > 25.0 and r1["time"] < 240.0, "durata giusta per il bravo (%.0f s)" % r1["time"])
	var r2: Dictionary = _bot(11, "bravo")
	check(is_equal_approx(r1["time"], r2["time"]), "stesso seme, stessa partita")
	var r3: Dictionary = _bot(11, "fermo")
	print("fermo: %s in %.1f s" % [r3["over"], r3["time"]])
	check(r3["over"] == "sconfitta", "chi non fa niente perde")
	var vinte: int = 0
	for sd in range(1, 9):
		var r4: Dictionary = _bot(sd, "caso")
		if r4["over"] == "vittoria" and r4["time"] < 120.0:
			vinte += 1
	print("caso: %d vittorie rapide su 8" % vinte)
	check(vinte <= 1, "a caso non si vince in fretta (%d su 8)" % vinte)

	print("prova_grezza: " + ("OK" if fails == 0 else "%d FAIL" % fails))
	quit(0 if fails == 0 else 1)


func _bot(seed_v: int, kind: String) -> Dictionary:
	var e := E.new(seed_v)
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var cool: float = 0.0
	for _i in range(60 * 300):
		e.step(E.TICK)
		e.take_events()
		if e.over != "":
			break
		cool -= E.TICK
		if kind == "fermo" or cool > 0.0:
			continue
		if kind == "caso":
			e.input(["tocco", "verso", "via", "su", "giu", "postura"][r.randi_range(0, 5)])
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
	return {"over": e.over, "time": e.time, "hp": e.hp, "ehp": e.ehp, "found": e.found.size()}
