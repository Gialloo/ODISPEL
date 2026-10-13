extends SceneTree

var passed: int = 0
var failed: int = 0


func _check(name: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("PASS: ", name)
	else:
		failed += 1
		print("FAIL: ", name)


func _init() -> void:
	_check("titolo", TextCase.pretty("SCEGLI MISSIONE") == "Scegli missione")
	_check("separatore", TextCase.pretty("SFIDA DEL GIORNO  ·  SEMAFORO") == "Sfida del giorno  ·  Semaforo")
	_check("sigle", TextCase.pretty("PV x1.5   ATT x1.25") == "PV x1.5   ATT x1.25" or TextCase.pretty("PV X1.5") == "PV X1.5")
	_check("sigla in frase", TextCase.pretty("ATTACCO E PV ALTI") == "Attacco e PV alti")
	_check("pvp", TextCase.pretty("PVP BILANCIATO") == "PvP bilanciato")
	_check("nome proprio", TextCase.pretty("VINCI CON KIRA") == "Vinci con Kira")
	_check("testo misto invariato", TextCase.pretty("Dopo 30 reclutamenti") == "Dopo 30 reclutamenti")
	_check("due righe", TextCase.pretty("SFIDA\nSemaforo · RESISTENTE") == "Sfida\nSemaforo · Resistente")
	_check("apostrofo", TextCase.pretty("LA SCEGLIE L'HOST") == "La sceglie l'host")
	_check("trattino", TextCase.pretty("MULTIPLAYER CO-OP") == "Multiplayer co-op")
	_check("lettera sola", TextCase.pretty("M = MUTO") == "M = muto")
	_check("numeri restano", TextCase.pretty("LV1 STRIKER") == "LV1 striker")
	_check("formattazione intatta", TextCase.pretty("[color=#fff]ZZ[/color]") == "[color=#fff]ZZ[/color]")
	_check("accento a", TextCase.accents("difficolta'") == "difficoltà")
	_check("piu e e'", TextCase.accents("piu' forte e' vero") == "più forte è vero")
	_check("perche", TextCase.accents("perche' no") == "perché no")
	_check("apostrofo vero intatto", TextCase.accents("l'host dell'altro") == "l'host dell'altro")
	_check("maiuscolo", TextCase.accents("DIFFICOLTA'") == "DIFFICOLTÀ")
	print("%d passati, %d falliti" % [passed, failed])
	quit(1 if failed > 0 else 0)
