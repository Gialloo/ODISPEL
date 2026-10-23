class_name CombatHud
extends RefCounted

# Testi brevi della battaglia leggibili dal giocatore, funzioni pure (nessun nodo): si provano in tests/unit/test_v3_hud.gd.

const STRONG_MULT: float = 1.5     # da questa potenza in su il colpo annunciato e' "FORTE" (Scarica 1.6, Verbale 1.85, Rosso 1.9)


# Il colpo annunciato pesa: potenza alta, oppure la stima di BattleResolver.threat_preview dice che qualcuno cadrebbe.
static func is_strong(mult: float, lethal: Array) -> bool:
	return mult >= STRONG_MULT or not lethal.is_empty()


# Riga del telegrafo: "Prossima mossa: SCARICA (FORTE) su LANCE", "... RAFFICA · SU TUTTI", con " · CATENA" se segue un secondo colpo.
static func tele_line(move_name: String, who: String, on_all: bool, strong: bool, chain: bool) -> String:
	var s: String = "Prossima mossa: " + move_name.to_upper() + (" (FORTE)" if strong else "")
	s += " · SU TUTTI" if on_all else " su " + who
	if chain:
		s += " · CATENA"
	return s
