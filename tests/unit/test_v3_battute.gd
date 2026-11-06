extends SceneTree

# Battute a fumetto della squadra in battaglia: ci sono per tutti, sono corte, rispettano le voci, escono con misura.

var fails: int = 0
const CAST: Array = ["lance", "nox", "rio", "saul"]


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	var bat: Dictionary = DialogData.all().get("battaglia", {})
	check(not bat.is_empty(), "sezione battaglia in dialoghi_atto1.json")
	for kind in ["critico", "ko_nemico", "copre", "rialzato"]:
		for c in CAST:
			check(not (bat.get(kind, {}) as Dictionary).get(c, []).is_empty(), "%s: battute per %s" % [kind, c])
	for sp in CAST:
		for fallen in CAST:
			if sp != fallen:
				check(not ((bat.get("compagno_ko", {}) as Dictionary).get(sp, {}) as Dictionary).get(fallen, []).is_empty(), "compagno_ko: %s per %s" % [sp, fallen])
	# ogni riga: personaggio della squadra, testo corto (si legge sul telefono), Saul mai col punto esclamativo, niente nomi vecchi
	for r in _all_rows(bat):
		var t: String = str(r.get("testo", ""))
		check(CAST.has(str(r.get("chi", ""))), "chi valido: " + str(r))
		check(t.length() > 0 and t.length() <= 70, "battuta corta: " + t)
		check(not (str(r["chi"]) == "saul" and t.contains("!")), "Saul senza punto esclamativo: " + t)
		check(not t.contains("Ferri") and not t.contains("Zecca"), "nomi canonici: " + t)

	var q := BattleQuips.new(bat)
	q.rng.seed = 7
	q.now_msec = 0
	# il K.O. di un compagno si dice sempre, anche subito dopo un'altra battuta
	var ko: Array = q.pick("compagno_ko", "rio", ["lance", "nox", "saul"])
	check(ko.size() == 1 and str(ko[0]["chi"]) != "rio", "chi cade non parla, parla un compagno in piedi")
	check(not q.pick("rialzato", "rio", CAST).is_empty(), "chi si rialza parla anche dentro la pausa")
	# dentro la pausa le battute normali tacciono
	var quiet: bool = true
	for i in 30:
		if not q.pick("critico", "lance", CAST).is_empty():
			quiet = false
	check(quiet, "pausa tra due battute rispettata")
	# niente ripetizioni nella stessa battaglia
	var seen: Dictionary = {}
	var rep: bool = false
	for i in 200:
		q.now_msec += 10000
		var r: Array = q.pick("ko_nemico", "lance", CAST)
		if r.is_empty():
			continue
		var k: String = str(r[0]["testo"])
		rep = rep or seen.has(k)
		seen[k] = true
	check(not rep and seen.size() == 3, "le battute di Lance sul K.O. escono tutte, una volta sola (%d)" % seen.size())
	# la risposta esce solo se chi risponde e' in piedi; la voce con "se" solo per quel compagno
	for i in 200:
		q.now_msec += 10000
		var r: Array = q.pick("critico", "rio", ["rio", "nox"])
		for row in r:
			check(str(row["chi"]) != "lance", "Lance a terra non risponde")
	var q2 := BattleQuips.new(bat)
	q2.now_msec = 0
	for i in 200:
		q2.now_msec += 10000
		for row in q2.pick("copre", "saul", CAST, "nox"):
			check(str(row["testo"]) != "Rifiuto.", "il conto a Lance solo quando copre Lance")
	print("test_v3_battute: " + ("OK" if fails == 0 else "%d errori" % fails))
	quit(1 if fails > 0 else 0)


func _all_rows(bat: Dictionary) -> Array:
	var out: Array = []
	for kind in bat:
		var g: Dictionary = bat[kind]
		for k in g:
			var lists: Array = []
			if g[k] is Dictionary:
				for k2 in g[k]:
					lists.append_array(g[k][k2])
			else:
				lists = g[k]
			for entry in lists:
				out.append_array(BattleQuips._righe(entry, str((entry as Dictionary).get("se", ""))) if entry is Dictionary else entry)
	return out
