class_name BuildCode
extends RefCounted

# CODICE SQUADRA: la configurazione di una squadra (operatori, livelli, abilita', passive) in una riga leggibile.
# Si puo' copiare e mandare a un amico: chi lo importa lo trova controllato (niente abilita' inventate) e puo' confrontarlo.
# Formato:  ODS1|kira.5.2:atk,heal:ult:pas1+pas2|dax...   (id.livello.rank:skill+skill:ult:passiva+passiva)

const PREFIX: String = "ODS1"


static func encode(entries: Array) -> String:
	var parts: Array = [PREFIX]
	for e in entries:
		var skills: Array = (e.get("skills", []) as Array).map(func(x: Variant) -> String: return str(x))
		var pas: Array = (e.get("passives", []) as Array).map(func(x: Variant) -> String: return str(x))
		parts.append("%s.%d.%d:%s:%s:%s" % [str(e.get("char", "")), int(e.get("level", 1)), int(e.get("rank", 0)), "+".join(PackedStringArray(skills)), str(e.get("ult", "")), "+".join(PackedStringArray(pas))])
	return "|".join(PackedStringArray(parts))


# Ritorna {"ok": bool, "error": String, "team": Array}. Non da' nulla che il giocatore non possieda: e' solo la lettura.
static func decode(code: String) -> Dictionary:
	var out: Dictionary = {"ok": false, "error": "", "team": []}
	var parts: PackedStringArray = code.strip_edges().split("|")
	if parts.size() < 2 or parts[0] != PREFIX:
		out["error"] = "codice non riconosciuto"
		return out
	if parts.size() - 1 > BattleTypes.TEAM_SIZE:
		out["error"] = "troppi operatori"
		return out
	var team: Array = []
	for i in range(1, parts.size()):
		var f: PackedStringArray = parts[i].split(":")
		if f.size() != 4:
			out["error"] = "voce %d non valida" % i
			return out
		var head: PackedStringArray = f[0].split(".")
		if head.size() != 3 or not BattleContent.CHARACTERS.has(head[0]):
			out["error"] = "operatore sconosciuto nella voce %d" % i
			return out
		var entry: Dictionary = BattleContent.default_entry(head[0])
		entry["level"] = clampi(int(head[1]), 1, RosterState.MAX_LEVEL)
		entry["rank"] = clampi(int(head[2]), 0, RosterState.MAX_RANK)
		entry["skills"] = _list(f[1])
		entry["ult"] = f[2]
		entry["passives"] = _list(f[3])
		var err: String = RosterState.validate_entry(entry)
		if err != "":
			out["error"] = "voce %d: %s" % [i, err]
			return out
		team.append(entry)
	out["ok"] = true
	out["team"] = team
	return out


static func _list(text: String) -> Array:
	var out: Array = []
	for x in text.split("+"):
		if x != "":
			out.append(x)
	return out


# Confronto leggibile con la propria squadra: righe del tipo "kira: skill diverse".
static func compare(mine: Array, other: Array) -> Array:
	var lines: Array = []
	for o in other:
		var found: bool = false
		for m in mine:
			if str(m.get("char", "")) == str(o.get("char", "")):
				found = true
				if (m.get("skills", []) as Array) != (o.get("skills", []) as Array):
					lines.append("%s: abilita' diverse" % str(o["char"]))
				if (m.get("passives", []) as Array) != (o.get("passives", []) as Array):
					lines.append("%s: passive diverse" % str(o["char"]))
				if str(m.get("ult", "")) != str(o.get("ult", "")):
					lines.append("%s: ultimate diversa" % str(o["char"]))
		if not found:
			lines.append("%s: non e' nella tua squadra" % str(o.get("char", "")))
	return lines
