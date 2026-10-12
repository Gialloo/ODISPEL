class_name DialogueScript
extends RefCounted

# Legge un copione di testo e lo trasforma in una lista di passi.
#
# Formato (una cosa per riga; le righe che iniziano con # sono commenti):
#
#   @bg strada_notte           sfondo (art/backgrounds/dialogue/strada_notte.png)
#   kira [angry] L: Testo.     personaggio, espressione, lato (L o R) e battuta
#   dax: Testo.                lato ed espressione facoltativi (si ricordano)
#   *: Testo di narrazione.    senza ritratto
#   > Scelta uno -> etichetta  una o piu' righe di fila = scelta multipla
#   > Scelta due -> altra
#   :etichetta                 punto di arrivo di una scelta
#   @goto altra                salto
#   @end                       fine della scena
#
# Personaggi: gli id degli operatori (kira, dax, elle, bruno, ...) o dei boss
# (distributore, semaforo, tombino). Espressioni: neutral, happy, angry, sad,
# surprised, hurt.

var steps: Array = []
var labels: Dictionary = {}
var errors: Array = []


static func parse(text: String) -> DialogueScript:
	var d := DialogueScript.new()
	var last_side: Dictionary = {}
	var last_expr: Dictionary = {}
	var pending_choice: Array = []
	var sides_used: int = 0

	for raw in text.split("\n"):
		var line: String = raw.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue

		if line.begins_with(">"):
			var body: String = line.substr(1).strip_edges()
			var parts: PackedStringArray = body.split("->")
			if parts.size() != 2:
				d.errors.append("scelta senza '->': " + line)
				continue
			pending_choice.append({"text": parts[0].strip_edges(), "goto": parts[1].strip_edges()})
			continue

		if not pending_choice.is_empty():
			d.steps.append({"type": "choice", "options": pending_choice})
			pending_choice = []

		if line.begins_with(":"):
			d.labels[line.substr(1).strip_edges()] = d.steps.size()
		elif line.begins_with("@"):
			var words: PackedStringArray = line.substr(1).split(" ", false)
			match words[0]:
				"bg":
					d.steps.append({"type": "bg", "name": words[1] if words.size() > 1 else ""})
				"goto":
					d.steps.append({"type": "goto", "label": words[1] if words.size() > 1 else ""})
				"end":
					d.steps.append({"type": "end"})
				_:
					d.errors.append("comando sconosciuto: " + line)
		else:
			var colon: int = line.find(":")
			if colon <= 0:
				d.errors.append("riga non valida: " + line)
				continue
			var head: String = line.substr(0, colon).strip_edges()
			var text_part: String = line.substr(colon + 1).strip_edges()
			var expr: String = ""
			var side: String = ""
			if head.contains("["):
				var open_at: int = head.find("[")
				var close_at: int = head.find("]")
				if close_at > open_at:
					expr = head.substr(open_at + 1, close_at - open_at - 1).strip_edges()
					head = head.substr(0, open_at) + " " + head.substr(close_at + 1)
			var tokens: PackedStringArray = head.split(" ", false)
			if tokens.is_empty():
				d.errors.append("riga senza personaggio: " + line)
				continue
			var speaker: String = tokens[0]
			if tokens.size() > 1 and tokens[1] in ["L", "R"]:
				side = tokens[1]
			if speaker == "*":
				d.steps.append({"type": "line", "speaker": "", "expr": "neutral", "side": "", "text": text_part})
				continue
			if side == "":
				side = str(last_side.get(speaker, "L" if sides_used % 2 == 0 else "R"))
				if not last_side.has(speaker):
					sides_used += 1
			last_side[speaker] = side
			if expr == "":
				expr = str(last_expr.get(speaker, "neutral"))
			last_expr[speaker] = expr
			d.steps.append({"type": "line", "speaker": speaker, "expr": expr, "side": side, "text": text_part})

	if not pending_choice.is_empty():
		d.steps.append({"type": "choice", "options": pending_choice})
	d._validate()
	return d


func _validate() -> void:
	for s in steps:
		match str(s["type"]):
			"goto":
				if not labels.has(str(s["label"])):
					errors.append("salto verso etichetta inesistente: " + str(s["label"]))
			"choice":
				for o in s["options"]:
					if not labels.has(str(o["goto"])):
						errors.append("scelta verso etichetta inesistente: " + str(o["goto"]))
			"line":
				var who: String = str(s["speaker"])
				if who != "" and not BattleContent.CHARACTERS.has(who) and not BattleContent.BOSSES.has(who):
					errors.append("personaggio sconosciuto: " + who)
				if not (str(s["expr"]) in ArtLibrary.EXPRESSIONS):
					errors.append("espressione sconosciuta: " + str(s["expr"]))


func is_valid() -> bool:
	return errors.is_empty() and not steps.is_empty()
