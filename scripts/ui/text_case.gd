class_name TextCase
extends RefCounted

# Testi leggibili: i testi scritti TUTTO IN MAIUSCOLO diventano "Prima lettera maiuscola, resto minuscolo".
# Si applica da solo a etichette e pulsanti quando vengono disegnati (hook), cosi' non serve cambiare ogni schermata.
# Restano maiuscole le sigle (PV, ATK, LV...), i nomi propri tornano con l'iniziale maiuscola.
# Non tocca: testo gia' misto, testi con "[" (formattazione), nodi con meta "keep_case" (es. i critici, scritti in maiuscolo apposta).

const KEEP_UPPER: Dictionary = {
	"PV": "PV", "ATT": "ATT", "DIF": "DIF", "VEL": "VEL", "HP": "HP", "LV": "LV", "ATK": "ATK", "DEF": "DEF", "SPD": "SPD",
	"PVP": "PvP", "PVE": "PvE", "FFA": "FFA", "IA": "IA", "AI": "AI", "OK": "OK", "FPS": "FPS", "HUD": "HUD", "REC": "REC",
	"ID": "ID", "TV": "TV", "KO": "KO", "K.O.": "K.O.", "INT": "INT", "STR": "STR", "AGI": "AGI", "SQ": "SQ", "UI": "UI",
}
const SENTENCE_BREAKS: Array = ["· ", ": ", "// ", "| ", ". ", "! ", "? ", "- ", "(", "\n"]

static var _names: Dictionary = {}
static var _tag: RegEx = null


static func _proper_names() -> Dictionary:
	if _names.is_empty():
		for id in BattleContent.CHARACTERS:
			_names[str(BattleContent.CHARACTERS[id].get("name", id)).to_upper()] = str(BattleContent.CHARACTERS[id].get("name", id))
		for id in BattleContent.BOSSES:
			var n: String = str(BattleContent.BOSSES[id].get("name", id))
			_names[n.to_upper()] = n.capitalize() if n == n.to_upper() or n == n.to_lower() else n
		for f in Factions.FACTIONS:
			_names[str(Factions.FACTIONS[f]["name"]).to_upper()] = str(Factions.FACTIONS[f]["name"])
		_names["ODISPEL"] = "ODISPEL"
	return _names


static func _letters(w: String) -> String:
	var out: String = ""
	for c in w:
		if c.to_lower() != c.to_upper():
			out += c
	return out


# Una parola e' "da correggere" se ha almeno 2 lettere, tutte maiuscole, e nessuna cifra.
static func _shout(w: String) -> bool:
	var l: String = _letters(w)
	if l.length() < 2 or l != l.to_upper():
		return false
	for c in w:
		if c >= "0" and c <= "9":
			return false
	return true


static func _fix_word(w: String) -> String:
	if w == "E" or w == "O":
		return w.to_lower()      # congiunzioni da sole
	if not _shout(w):
		return w
	var core: String = _letters(w)
	var key: String = w.strip_edges().trim_prefix("(").trim_suffix(")").trim_suffix(",").trim_suffix(".").trim_suffix("!").trim_suffix("?").trim_suffix(":")
	if KEEP_UPPER.has(key):
		return w.replace(key, str(KEEP_UPPER[key]))
	var names: Dictionary = _proper_names()
	if names.has(key):
		return w.replace(key, str(names[key]))
	if w.contains("-") or w.contains("'"):
		# CO-OP -> Co-op, L'HOST -> l'host (le parti dopo - restano minuscole)
		return w.to_lower()
	return w.to_lower()


static func pretty(s: String) -> String:
	if s.length() < 2:
		return s
	if _tag == null:
		_tag = RegEx.create_from_string("\\[/?[a-z_]+(=[^\\]]*)?\\]")
	if _tag.search(s) != null:
		return s
	var changed: bool = false
	var lines: PackedStringArray = s.split("\n")
	for li in lines.size():
		var words: PackedStringArray = lines[li].split(" ")
		for i in words.size():
			var fixed: String = _fix_word(words[i])
			if fixed != words[i]:
				words[i] = fixed
				changed = true
		lines[li] = " ".join(words)
	if not changed:
		return s
	var out: String = "\n".join(lines)
	# iniziale maiuscola a inizio testo e dopo ogni pausa di frase
	var chars: Array = []
	var cap_next: bool = true
	var i: int = 0
	while i < out.length():
		var c: String = out[i]
		if cap_next and c >= "0" and c <= "9":
			cap_next = false
		elif cap_next and c.to_lower() != c.to_upper():
			# "v0.24.8": la v della versione resta minuscola
			if not (c == "v" and i + 1 < out.length() and out[i + 1] >= "0" and out[i + 1] <= "9"):
				c = c.to_upper()
			cap_next = false
		chars.append(c)
		for b in SENTENCE_BREAKS:
			if out.substr(i + 1 - b.length(), b.length()) == b and i + 1 - b.length() >= 0:
				cap_next = true
		i += 1
	return "".join(chars)


# Collega il controllo: ogni volta che viene disegnato, se il testo e' tutto maiuscolo lo sistema (una sola volta).
static func hook(n: Node) -> void:
	if n is Label or n is Button:
		n.draw.connect(_on_draw.bind(n))


static func _on_draw(n: Node) -> void:
	if not is_instance_valid(n) or n.has_meta("keep_case"):
		return
	var t: String = str(n.get("text"))
	if t == "":
		return
	var p: String = pretty(t)
	if p != t:
		_apply.call_deferred(n, p)


static func _apply(n: Node, p: String) -> void:
	if is_instance_valid(n):
		n.set("text", p)
