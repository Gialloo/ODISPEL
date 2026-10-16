extends SceneTree

# Impact frames: classificazione dei colpi, legame colpo -> mossa, guardia anti-sovrapposizione.
#   godot --headless --path . -s res://tests/unit/test_impact_frames.gd

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_run()
	print("impact_frames: %d ok, FAIL: %d" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _lookup(uid: String) -> Dictionary:
	return {"max_hp": 1000 if uid == "boss" else 200}


func _lv(events: Array, i: int, to_boss: bool, hp_before: int) -> int:
	var plan: Array = ImpactFrames.plan(events, _lookup)
	var e: Dictionary = events[i]
	var mx: int = int(_lookup(str(e["dst"]))["max_hp"])
	return ImpactFrames.level_of_event(e, plan[i], mx, hp_before, to_boss)


func _run() -> void:
	var F := ImpactFrames
	# 1 colpo normale non critico
	_check("normale = 0", F.level_for("basic", 20, false, 1000, 1000, true) == F.NONE)
	# 2 critico pesante (>=3% PV max) ma non eccezionale
	_check("critico pesante = 1", F.level_for("basic", 60, true, 1000, 1000, true) == F.CRIT)
	_check("critico minuscolo = 0", F.level_for("basic", 10, true, 1000, 1000, true) == F.NONE)
	# 3 danno eccezionale non critico
	_check("danno eccezionale = 2", F.level_for("basic", 200, false, 1000, 1000, true) == F.EXCEPTIONAL)
	# 4 ult non critica: nessun frame
	_check("ult normale = 0", F.level_for("ult", 50, false, 1000, 1000, true) == F.NONE)
	# 5 ult critica
	_check("ult critica = 3", F.level_for("ult", 120, true, 1000, 1000, true) == F.ULT_CRIT)
	# 6 ult eccezionale
	_check("ult devastante = 4", F.level_for("ult", 300, false, 1000, 1000, true) == F.ULT_EXCEPTIONAL)
	# priorita': ult eccezionale > ult critica > eccezionale > critico
	_check("priorita ult exc su crit", F.level_for("ult", 300, true, 1000, 1000, true) == F.ULT_EXCEPTIONAL)
	_check("eccezionale su critico", F.level_for("basic", 200, true, 1000, 1000, true) == F.EXCEPTIONAL)
	# soglia relativa sui PV attuali (colpo che toglie gran parte dei PV rimasti)
	_check("relativo ai PV attuali", F.level_for("basic", 90, false, 1000, 120, true) == F.EXCEPTIONAL)
	_check("0 danno = 0", F.level_for("ult", 0, true, 1000, 1000, true) == F.NONE)

	# 7 colpo che manda KO: il livello e' calcolato sul colpo, non sul "down"
	var ko: Array = [
		{"t": "act", "unit": "a", "move": "x", "kind": "ult"},
		{"t": "damage", "src": "a", "dst": "boss", "amount": 300, "crit": true},
		{"t": "down", "unit": "boss"}]
	_check("KO: colpo = 4", _lv(ko, 1, true, 300) == F.ULT_EXCEPTIONAL)
	_check("KO: 'down' non e' un colpo", F.level_of_event(ko[2], F.plan(ko, _lookup)[2], 1000, 0, true) == F.NONE)

	# 8 ult multi-bersaglio: un solo colpo decisivo (il piu' grande in proporzione)
	var multi: Array = [
		{"t": "act", "unit": "a", "move": "x", "kind": "ult"},
		{"t": "damage", "src": "a", "dst": "boss", "amount": 150, "crit": true},
		{"t": "damage", "src": "a", "dst": "e2", "amount": 190, "crit": true},
		{"t": "damage", "src": "a", "dst": "e3", "amount": 100, "crit": true}]
	var n: int = 0
	for i in [1, 2, 3]:
		if _lv(multi, i, str(multi[i]["dst"]) == "boss", 1000) > 0:
			n += 1
	_check("multi-bersaglio: un solo frame", n == 1)
	_check("multi-bersaglio: il decisivo e' il piu' grande", _lv(multi, 2, false, 200) > 0 and _lv(multi, 1, true, 1000) == 0)

	# colpi simultanei di due mosse diverse: due gruppi, due decisivi indipendenti
	var two: Array = [
		{"t": "act", "unit": "a", "move": "x", "kind": "ult"},
		{"t": "damage", "src": "a", "dst": "boss", "amount": 130, "crit": true},
		{"t": "act", "unit": "b", "move": "y", "kind": "basic"},
		{"t": "damage", "src": "b", "dst": "boss", "amount": 250, "crit": false}]
	_check("due mosse: ult crit", _lv(two, 1, true, 1000) == F.ULT_CRIT)
	_check("due mosse: eccezionale", _lv(two, 3, true, 1000) == F.EXCEPTIONAL)

	# contrattacco / spine dopo un'ult NON ereditano l'ult
	var ctr: Array = [
		{"t": "act", "unit": "a", "move": "x", "kind": "ult"},
		{"t": "damage", "src": "a", "dst": "boss", "amount": 20, "crit": false},
		{"t": "damage", "src": "boss", "dst": "a", "amount": 150, "crit": true},
		{"t": "damage", "src": "a", "dst": "a", "amount": 300, "crit": false, "thorns": true}]
	var pl: Array = F.plan(ctr, _lookup)
	_check("contrattacco e' basic", str(pl[2]["kind"]) == "basic")
	_check("spine saltate", bool(pl[3]["skip"]))

	# sequenza di piu' colpi della stessa mossa: un solo frame
	var seq: Array = [
		{"t": "act", "unit": "a", "move": "x", "kind": "basic"},
		{"t": "damage", "src": "a", "dst": "boss", "amount": 60, "crit": true},
		{"t": "damage", "src": "a", "dst": "boss", "amount": 70, "crit": true}]
	_check("sequenza: solo il piu' forte", _lv(seq, 1, true, 1000) == 0 and _lv(seq, 2, true, 1000) == F.CRIT)

	# 9 effetti ripetuti/sovrapposti: la guardia non ripete un livello uguale o minore
	var d := ImpactDirector.new()
	var first: float = d.play(F.EXCEPTIONAL, null, null, Vector2.ZERO)
	_check("primo frame mostrato", d.last_played == F.EXCEPTIONAL and first > 0.0)
	d.play(F.CRIT, null, null, Vector2.ZERO)
	_check("frame piu' debole sovrapposto: ignorato", d.last_played == 0)
	d.play(F.ULT_EXCEPTIONAL, null, null, Vector2.ZERO)
	_check("frame piu' forte sovrapposto: sostituisce", d.last_played == F.ULT_EXCEPTIONAL)
	_check("progressione hit-stop", F.HIT_STOP[1] < F.HIT_STOP[2] and F.HIT_STOP[2] < F.HIT_STOP[3] and F.HIT_STOP[3] < F.HIT_STOP[4])
	_check("hit-stop <= 0.22s", float(F.HIT_STOP[4]) <= 0.22)
	_check("progressione durata overlay", F.OVERLAY_LEN[1] < F.OVERLAY_LEN[2] and F.OVERLAY_LEN[3] < F.OVERLAY_LEN[4])
