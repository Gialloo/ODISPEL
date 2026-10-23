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
	_chk(ColorHint.line("rosso", "verde", "FRAMMENTO") == "Colore vincente: +50% su Frammento", "riga vantaggio: " + ColorHint.line("rosso", "verde", "FRAMMENTO"))
	_chk(ColorHint.line("verde", "rosso", "FRAMMENTO") == "Colore debole: -33% su Frammento", "riga svantaggio: " + ColorHint.line("verde", "rosso", "FRAMMENTO"))
	_chk(ColorHint.line("rosso", "giallo", "X") == "", "riga neutra vuota")
	_chk(CombatHud.is_strong(1.6, []), "scarica e' forte")
	_chk(not CombatHud.is_strong(0.7, []), "raffica non e' forte")
	_chk(CombatHud.is_strong(0.7, ["p1"]), "letale e' forte")
	_chk(CombatHud.tele_line("Scarica", "LANCE", false, true, false) == "Prossima mossa: SCARICA (FORTE) su LANCE", "riga forte: " + CombatHud.tele_line("Scarica", "LANCE", false, true, false))
	_chk(CombatHud.tele_line("Raffica", "", true, false, false) == "Prossima mossa: RAFFICA · SU TUTTI", "riga su tutti")
	_chk(CombatHud.tele_line("Verbale", "ECHO", false, true, true).ends_with(" · CATENA"), "riga catena")
	_chk(CombatHud.link_banner([]).is_empty(), "nessun legame, nessun banner")
	var lk: Dictionary = CombatHud.link_banner([{"t": "link", "n": 1, "kind": "cross"}, {"t": "link", "n": 2, "kind": "unison"}])
	_chk(str(lk.get("text", "")) == "LEGAME +30% DANNO", "legame piu' forte vince: " + str(lk))
	var cx: Dictionary = CombatHud.link_banner([{"t": "link", "n": 1, "kind": "cross"}])
	_chk(str(cx.get("text", "")) == "LEGAME +15% DANNO · +ULTIMATE", "legame cross: " + str(cx))
	var sy: Dictionary = CombatHud.link_banner([{"t": "link", "n": 4, "kind": "unison"}, {"t": "synergy", "id": "traccia", "name": "Traccia", "tier": 1, "col": "#ffd25f"}])
	_chk(str(sy.get("text", "")) == "IMPULSO · TRACCIA · +ULTIMATE", "combo (ora chiamata Impulso, scelta voluta del giro 2) batte legame: " + str(sy))
	if fails == 0:
		print("test_v3_hud: OK")
	quit(0 if fails == 0 else 1)
