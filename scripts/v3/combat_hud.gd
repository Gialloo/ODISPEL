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
# "short" e' la versione corta per l'avviso con l'icona della catena (meno testo sullo schermo).
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
				var txt: String = "IMPULSO · " + str(e.get("name", "")).to_upper()      # la combo e' un Impulso: nome dato a cio' che esiste, nessuna barra nuova
				if int(rule.get("gauge", 0)) > 0:
					txt += " · +ULTIMATE"
				best_score = score
				best = {"text": txt, "col": Color(str(e.get("col", "#ffd25f"))),
					"short": str(e.get("name", "")).to_upper() + (" · +ULT" if int(rule.get("gauge", 0)) > 0 else "")}
		elif t == "link":
			var unison: bool = str(e.get("kind", "")) == "unison"
			var score2: int = int(e.get("n", 1)) + (1 if unison else 0)
			if score2 > best_score:
				var pct: int = int(round(float(int(e.get("n", 1))) * BattleTypes.LINK_BONUS * 100.0))
				var txt2: String = "LEGAME +%d%% DANNO" % pct
				if not unison:
					txt2 += " · +ULTIMATE"
				best_score = score2
				best = {"text": txt2, "col": Color("#ffd25f") if unison else Color("#7cf0ff"),
					"short": "+%d%%" % pct + ("" if unison else " · +ULT")}
	return best


# Avviso corto: titolo (prima di " · " o ":") e, se breve, il resto in piccolo. Il resto lungo si lascia: c'e' gia' nelle descrizioni.
# HUD 0.61, P0-C: regola del BREAK + lettura di Echo in un avviso solo. Titolo = nome della regola; resto = il consiglio
# di Echo (dopo i due punti della lettura) e il numero della regola (dopo i due punti di "short", se c'e'). "" se non sta in una riga.
# ("IL VERBALE", "dopo la parata perfetta: x2", "Il Verbale fa male: para perfetto, poi punisci") -> "IL VERBALE · para perfetto, poi punisci: x2"
static func merge_rule_reading(rule_name: String, short: String, reading: String) -> String:
	var tip: String = reading
	var i: int = reading.find(": ")
	if i > 0:
		tip = reading.substr(i + 2)
	var num: String = short
	var j: int = short.rfind(": ")
	if j > 0:
		num = short.substr(j + 2)
	var tail: String = "%s: %s" % [tip.strip_edges(), num.strip_edges()]
	if tail.length() > 48:
		return ""          # troppo lungo per una riga: restano i due avvisi di prima (non si taglia niente)
	return "%s · %s" % [rule_name, tail]


static func notice_parts(text: String, max_sub: int = 34) -> Array:
	var cut: int = -1
	for sep in [" · ", ": "]:
		var i: int = text.find(sep)
		if i > 0 and (cut < 0 or i < cut):
			cut = i
	if cut < 0:
		return [text, ""]
	var head: String = text.substr(0, cut)
	var rest: String = text.substr(cut + (3 if text.substr(cut, 3) == " · " else 2)).strip_edges()
	return [head, rest if rest.length() <= max_sub else ""]
