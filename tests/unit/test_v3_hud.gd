extends SceneTree

# Ruota dei colori letta dall'HUD: efficace / debole / neutro.
var fails: int = 0


func _chk(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + what)


func _tipo(a: String, d: String) -> String:
	return str(ColorHint.eval(a, d)["tipo"])


func _init() -> void:
	_chk(_tipo("rosso", "verde") == "efficace", "rosso > verde")
	_chk(_tipo("verde", "rosso") == "debole", "verde < rosso")
	_chk(_tipo("verde", "blu") == "efficace", "verde > blu")
	_chk(_tipo("blu", "verde") == "debole", "blu < verde")
	_chk(_tipo("blu", "rosso") == "efficace", "blu > rosso")
	_chk(_tipo("rosso", "blu") == "debole", "rosso < blu")
	_chk(_tipo("giallo", "viola") == "efficace", "giallo > viola")
	_chk(_tipo("viola", "giallo") == "efficace", "viola > giallo")
	for c in ["rosso", "verde", "blu", "giallo", "viola"]:
		_chk(_tipo(c, c) == "neutro", "neutro stesso colore " + c)
	_chk(_tipo("rosso", "giallo") == "neutro", "rosso/giallo neutro")
	_chk(_tipo("viola", "blu") == "neutro", "viola/blu neutro")
	_chk(_tipo("", "rosso") == "neutro", "colore vuoto neutro")
	_chk(is_equal_approx(float(ColorHint.eval("rosso", "verde")["mult"]), BattleTypes.COLOR_ADVANTAGE), "mult vantaggio")
	_chk(str(ColorHint.eval("rosso", "verde")["testo"]) == "EFFICACE", "testo efficace")
	_chk(str(ColorHint.eval("verde", "rosso")["testo"]) == "DEBOLE", "testo debole")
	_chk(ColorHint.line("rosso", "verde", "FRAMMENTO") == "VANTAGGIO ×1.5 sul FRAMMENTO", "riga vantaggio: " + ColorHint.line("rosso", "verde", "FRAMMENTO"))
	_chk(ColorHint.line("rosso", "giallo", "X") == "", "riga neutra vuota")
	if fails == 0:
		print("test_v3_hud: OK")
	quit(0 if fails == 0 else 1)
