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


# Link e combo di un'azione: ne mostra UNO solo, il piu' forte. Ritorna {} se non c'e' niente, altrimenti {"text", "col": Color}.
# Gli eventi sono quelli gia' emessi dal motore: "synergy" (id, name, tier, col) e "link" (n anelli, kind cross|unison).
static func link_banner(events: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_score: int = -1
	for e in events:
		var t: String = str(e.get("t", ""))
		if t == "synergy":
			var score: int = 10 + int(e.get("tier", 1))
			if score > best_score:
				var rule: Dictionary = {}
				for r in Combos.RULES:
					if str(r["id"]) == str(e.get("id", "")):
						rule = r
				var txt: String = "COMBO · " + str(e.get("name", "")).to_upper()
				if int(rule.get("gauge", 0)) > 0:
					txt += " · +ULTIMATE"
				best_score = score
				best = {"text": txt, "col": Color(str(e.get("col", "#ffd25f")))}
		elif t == "link":
			var unison: bool = str(e.get("kind", "")) == "unison"
			var score2: int = int(e.get("n", 1)) + (1 if unison else 0)
			if score2 > best_score:
				var pct: int = int(round(float(int(e.get("n", 1))) * BattleTypes.LINK_BONUS * 100.0))
				var txt2: String = "LEGAME +%d%% DANNO" % pct
				if not unison:
					txt2 += " · +ULTIMATE"
				best_score = score2
				best = {"text": txt2, "col": Color("#ffd25f") if unison else Color("#7cf0ff")}
	return best
