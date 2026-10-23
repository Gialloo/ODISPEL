class_name Story
extends RefCounted

# L'atto 1 a passi (data/atto1.json): capitolo -> lista di passi (cartello, scena, area, rifugio, fine).
# Tiene il punto raggiunto, le scelte fatte (flag) e lo salva su disco (user://salvataggio.cfg).

const SAVE_PATH: String = "user://salvataggio.cfg"
# I test e gli strumenti di prova usano un file a parte, per non toccare il salvataggio vero di chi gioca
static var save_path: String = SAVE_PATH

static var _data: Dictionary = {}
static var chapter: int = 0
static var step: int = 0
static var flags: Dictionary = {}
static var area_state: Dictionary = {}     # stato dell'area corrente (nemici battuti, indizi, posizione): per tornare dopo una battaglia
                                           # e, salvato su disco, per riprendere a meta' area senza perdere gli indizi


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
	var p: Dictionary = passi[step]
	# nella Replica della diretta i cartelli lo dicono, così si capisce subito che è un nuovo giro
	if replica() > 0 and str(p.get("tipo", "")) == "cartello":
		p = p.duplicate()
		p["titolo"] = "REPLICA %d · %s" % [replica(), str(p.get("titolo", ""))]
	return p


static func chapter_title() -> String:
	var ch: Array = chapters()
	return str(ch[chapter].get("titolo", "")) if chapter < ch.size() else ""


static func new_game() -> void:
	chapter = 0
	step = 0
	flags = {}
	area_state = {}
	Progress.reset()
	save()


# Replica della diretta (New Game+, alla Chrono Trigger): si rigioca l'atto tenendo i legami stretti,
# le scelte su Echo e Saul si rifanno da capo e i nemici sono più duri (vedi "replica" negli argomenti della battaglia).
static func replica() -> int:
	return int(flags.get("replica", 0))


static func new_replica() -> void:
	var keep: Dictionary = {}
	for k in data().get("legami", {}):
		if has_flag(str(k)):
			keep[str(k)] = true
	keep["replica"] = replica() + 1
	chapter = 0
	step = 0
	flags = keep
	area_state = {}
	save()


static func start_chapter(i: int) -> void:
	chapter = clampi(i, 0, chapters().size() - 1)
	step = 0
	area_state = {}
	# le debolezze portate da un'area all'altra valgono solo nel capitolo in cui si sono trovate
	flags.erase("debolezza_nota")
	save()


static func has_save() -> bool:
	return FileAccess.file_exists(save_path)


static func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return false
	chapter = int(cfg.get_value("storia", "capitolo", 0))
	step = int(cfg.get_value("storia", "passo", 0))
	var saved: Variant = cfg.get_value("storia", "flag", {})
	flags = saved if saved is Dictionary else {}
	var st: Variant = cfg.get_value("storia", "area", {})
	area_state = st if st is Dictionary else {}
	Progress.from_save(cfg.get_value("squadra", "dati", {}))
	if not cfg.has_section("squadra"):
		# salvataggio di prima dei livelli: la squadra parte dal livello previsto per il capitolo (1, 3, 5, 7, 9, 11)
		for c in Progress.CAST:
			Progress.data["lv"][c] = 1 + 2 * clampi(chapter, 0, 5)
			for u in Progress.UNLOCKS[c]:
				if int(u[0]) <= int(Progress.data["lv"][c]):
					Progress._auto_equip(c, str(u[1]), str(u[2]))
	return true


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("storia", "capitolo", chapter)
	cfg.set_value("storia", "passo", step)
	cfg.set_value("storia", "flag", flags)
	if not area_state.is_empty():
		cfg.set_value("storia", "area", area_state)
	Progress.ensure()
	cfg.set_value("squadra", "dati", Progress.data)
	cfg.save(save_path)


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
