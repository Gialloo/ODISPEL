extends SceneTree

# Tutorial spezzato: nella storia le spiegazioni arrivano a gruppi, al massimo due per scontro.
var fails: int = 0


func _chk(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _battaglia() -> Object:
	var bt: Object = load("res://scripts/v3/battle3d.gd").new()
	bt.set("lezioni", true)
	return bt


# simula una spiegazione data (senza aprire il dialogo)
func _attive() -> bool:
	var bt: Node = load("res://scripts/v3/battle3d.gd").new()
	var r: bool = bt.call("_lezioni_attive")
	bt.free()
	return r


func _vedi(bt: Object, key: String) -> void:
	Story.set_flag("lez_" + key)
	if key != "tut_fine":
		bt.set("_lez_ora", int(bt.get("_lez_ora")) + 1)


func _init() -> void:
	Story.flags = {}
	_chk(_attive(), "partita nuova: lezioni attive")
	Story.flags = {"tutorial_fatto": true}
	_chk(not _attive(), "vecchio salvataggio col tutorial fatto: niente lezioni")
	Story.flags = {"replica": 1, "lezioni_iniziate": true}
	_chk(not _attive(), "Replica: niente lezioni")

	Story.flags = {}
	# scontro 1: schermo e ATTACCO, poi basta
	var b1: Object = _battaglia()
	_chk(b1.call("_lezione_ok", "tut_intro"), "1: intro")
	_chk(not b1.call("_lezione_ok", "tut_guardia"), "1: guardia non prima dell'attacco")
	_chk(not b1.call("_lezione_ok", "tut_telegrafo"), "1: telegrafo dopo")
	_vedi(b1, "tut_intro")
	_vedi(b1, "tut_attacco")
	_chk(not b1.call("_lezione_ok", "tut_guardia"), "1: massimo due per scontro")
	_chk(not b1.call("_lezione_ok", "tut_fine"), "1: esperienza non ancora")
	# scontro 2: GUARDIA e ABILITA', poi a vittoria esperienza e SQUADRA
	var b2: Object = _battaglia()
	_chk(not b2.call("_lezione_ok", "tut_attacco"), "2: attacco gia' visto")
	_chk(b2.call("_lezione_ok", "tut_guardia"), "2: guardia")
	_vedi(b2, "tut_guardia")
	_vedi(b2, "tut_abilita")
	_chk(b2.call("_lezione_ok", "tut_fine"), "2: esperienza a scontro finito, fuori dal limite")
	_vedi(b2, "tut_fine")
	# scontro 3: mossa annunciata e guardia a tempo
	var b3: Object = _battaglia()
	_chk(b3.call("_lezione_ok", "tut_telegrafo"), "3: telegrafo")
	_chk(not b3.call("_lezione_ok", "tut_reazioni"), "3: reazioni dopo")
	_vedi(b3, "tut_telegrafo")
	_vedi(b3, "tut_qte")
	# scontro 4: reazioni e rottura; l'extra solo dopo l'Ultimate
	var b4: Object = _battaglia()
	_vedi(b4, "tut_reazioni")
	_vedi(b4, "tut_rottura")
	var b5: Object = _battaglia()
	_chk(not b5.call("_lezione_ok", "tut_extra"), "5: extra dopo l'Ultimate")
	_chk(b5.call("_lezione_ok", "tut_ultimate"), "5: ultimate")
	_vedi(b5, "tut_ultimate")
	_chk(b5.call("_lezione_ok", "tut_extra"), "5: extra")
	_vedi(b5, "tut_extra")
	_chk(b5.call("_lezioni_viste"), "tutte viste")
	for bt in [b1, b2, b3, b4, b5]:
		(bt as Node).free()
	Story.flags = {}
	if fails == 0:
		print("test_v3_lezioni: OK")
	else:
		print("test_v3_lezioni: %d falliti" % fails)
	quit(1 if fails > 0 else 0)
