class_name Story
extends RefCounted

# L'atto 1 a passi (data/atto1.json): capitolo -> lista di passi (cartello, scena, area, rifugio, fine).
# Tiene il punto raggiunto, le scelte fatte (flag) e lo salva su disco (user://salvataggio.cfg).

const SAVE_PATH: String = "user://salvataggio.cfg"

static var _data: Dictionary = {}
static var chapter: int = 0
static var step: int = 0
static var flags: Dictionary = {}
static var area_state: Dictionary = {}     # stato dell'area corrente (nemici battuti, indizi, posizione) per tornare dopo una battaglia


static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open("res://data/atto1.json", FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_data = parsed
	return _data


static func chapters() -> Array:
	return data().get("capitoli", [])


static func area(id: String) -> Dictionary:
	return (data().get("aree", {}) as Dictionary).get(id, {})


static func current() -> Dictionary:
	var ch: Array = chapters()
	if chapter >= ch.size():
		return {"tipo": "fine"}
	var passi: Array = ch[chapter].get("passi", [])
	if step >= passi.size():
		return {"tipo": "fine"}
	return passi[step]


static func chapter_title() -> String:
	var ch: Array = chapters()
	return str(ch[chapter].get("titolo", "")) if chapter < ch.size() else ""


static func new_game() -> void:
	chapter = 0
	step = 0
	flags = {}
	area_state = {}
	save()


static func start_chapter(i: int) -> void:
	chapter = clampi(i, 0, chapters().size() - 1)
	step = 0
	area_state = {}
	save()


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	chapter = int(cfg.get_value("storia", "capitolo", 0))
	step = int(cfg.get_value("storia", "passo", 0))
	flags = cfg.get_value("storia", "flag", {})
	area_state = {}
	return true


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("storia", "capitolo", chapter)
	cfg.set_value("storia", "passo", step)
	cfg.set_value("storia", "flag", flags)
	cfg.save(SAVE_PATH)


static func set_flag(f: String) -> void:
	if f != "":
		flags[f] = true


static func has_flag(f: String) -> bool:
	return bool(flags.get(f, false))


# Passa al passo successivo (o al capitolo successivo) e salva
static func advance() -> void:
	area_state = {}
	step += 1
	var passi: Array = chapters()[chapter].get("passi", []) if chapter < chapters().size() else []
	if step >= passi.size():
		chapter += 1
		step = 0
	save()


# Schermata e argomenti per il passo corrente
static func screen_for_current() -> Array:
	var p: Dictionary = current()
	match str(p.get("tipo", "")):
		"area":
			return ["area", {"area": str(p.get("area", "")), "resume": area_state}]
		"scena", "rifugio":
			return ["scene", {"passo": p}]
		"cartello":
			return ["card", {"passo": p}]
	return ["ending", {}]


# Legami attivi (per il bonus in battaglia): [{"chi": [a, b], "nome": ...}]
static func active_bonds() -> Array:
	var out: Array = []
	var leg: Dictionary = data().get("legami", {})
	for k in leg:
		if has_flag(str(k)):
			out.append(leg[k])
	return out
