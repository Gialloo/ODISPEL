class_name Discoveries
extends RefCounted

# ARCHIVIO DELLE SCOPERTE: cio' che la squadra ha davvero visto accadere (combo, eventi dell'arena, come reagisce ogni boss).
# Non e' solo una lista: i comportamenti dei boss noti vengono ricordati durante la pianificazione delle battaglie successive.
# Alimentato dalle statistiche della battaglia (state["stats"]), che il motore riempie dagli eventi: un unico linguaggio comune.
#   roster["discoveries"] = {"combos": [id], "arena": [id], "behaviors": [id], "titles": {titolo: n}, "style": {tipo: n}}


static func data(roster: Dictionary) -> Dictionary:
	if not roster.has("discoveries") or not (roster["discoveries"] is Dictionary):
		roster["discoveries"] = {}
	var d: Dictionary = roster["discoveries"]
	for k in ["combos", "arena", "behaviors"]:
		if not d.has(k) or not (d[k] is Array):
			d[k] = []
	for k in ["titles", "style"]:
		if not d.has(k) or not (d[k] is Dictionary):
			d[k] = {}
	return d


# Cio' che la battaglia deve sapere in partenza (comportamenti dei boss gia' osservati).
static func known(roster: Dictionary) -> Dictionary:
	var d: Dictionary = data(roster)
	return {"behaviors": (d["behaviors"] as Array).duplicate(), "arena": (d["arena"] as Array).duplicate(), "combos": (d["combos"] as Array).duplicate()}


static func count(roster: Dictionary) -> int:
	var d: Dictionary = data(roster)
	return (d["combos"] as Array).size() + (d["arena"] as Array).size() + (d["behaviors"] as Array).size()


static func total() -> int:
	return Combos.RULES.size() + Arena.EVENT_ORDER.size() + Arena.BEHAVIOR_ORDER.size()


# Titoli meritati in una battaglia, ricavati solo da fatti verificabili. Non premiano il danno: premiano lo stile.
static func titles(stats: Dictionary, victory: bool, new_found: int = 0) -> Array:
	var out: Array = []
	if victory and int(stats.get("downs", 0)) == 0:
		out.append("NESSUNO E' CADUTO")
	if victory and int(stats.get("spent", 0)) == 0 and int(stats.get("synergies", 0)) > 0:
		out.append("RISERVA INTATTA")
	if int(stats.get("reactions", 0)) >= 3:
		out.append("MURO DI REAZIONI")
	if int(stats.get("rescues", 0)) >= 1:
		out.append("NESSUNO RESTA INDIETRO")
	if int(stats.get("breaks", 0)) >= 2:
		out.append("SPEZZAGUARDIE")
	if int(stats.get("synergies", 0)) >= 4:
		out.append("ORCHESTRA")
	if new_found > 0:
		out.append("MAI VISTO PRIMA")
	return out


# Stile della squadra in questa battaglia (una parola, non una classificazione rigida).
static func style_of(stats: Dictionary) -> String:
	var best: String = ""
	var top: int = 0
	var scores: Dictionary = {
		"DIFENSIVO": int(stats.get("reactions", 0)) + int(stats.get("rescues", 0)),
		"COORDINATO": int(stats.get("synergies", 0)),
		"INCISIVO": int(stats.get("breaks", 0)) * 2,
	}
	for k in ["DIFENSIVO", "COORDINATO", "INCISIVO"]:
		if int(scores[k]) > top:
			top = int(scores[k])
			best = k
	return best


# Registra la battaglia: restituisce le righe da mostrare (nuove scoperte, titoli). Idempotente per le scoperte.
static func record(roster: Dictionary, boss_id: String, victory: bool, stats: Dictionary) -> Array:
	var d: Dictionary = data(roster)
	var lines: Array = []
	var fresh: int = 0
	for pair in [["combos", "seen_combos"], ["arena", "seen_arena"]]:
		for id in stats.get(str(pair[1]), []):
			if not (d[str(pair[0])] as Array).has(str(id)):
				(d[str(pair[0])] as Array).append(str(id))
				fresh += 1
				var nm: String = str(id)
				if str(pair[0]) == "combos":
					nm = str(Combos.rule(str(id)).get("name", id))
				else:
					nm = str(Arena.EVENTS.get(str(id), {}).get("name", id))
				lines.append("ARCHIVIO: scoperto %s" % nm)
	if not (stats.get("seen_behavior", []) as Array).is_empty() and not (d["behaviors"] as Array).has(boss_id):
		(d["behaviors"] as Array).append(boss_id)
		fresh += 1
		lines.append("ARCHIVIO: capito come reagisce questo boss (%s)" % str(Arena.BEHAVIORS[Arena.behavior_of(boss_id)]["name"]))
	for t in titles(stats, victory, fresh):
		d["titles"][t] = int(d["titles"].get(t, 0)) + 1
	var st: String = style_of(stats)
	if st != "":
		d["style"][st] = int(d["style"].get(st, 0)) + 1
	return lines


# Stile ricorrente della squadra (il piu' frequente), per il profilo.
static func signature(roster: Dictionary) -> String:
	var d: Dictionary = data(roster)
	var best: String = ""
	var top: int = 0
	for k in d["style"]:
		if int(d["style"][k]) > top:
			top = int(d["style"][k])
			best = str(k)
	return best
