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
	# New Game+ fino a NG+10: dalla decima si rigioca la decima (la squadra puo' continuare a salire fino al livello 100)
	keep["replica"] = mini(replica() + 1, BattleTypes.REPLICA_MAX)
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
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak")


static func validate_area_state(v: Variant) -> bool:
	if not (v is Dictionary):
		return false
	var area: Dictionary = v
	if area.has("pos"):
		if not (area["pos"] is Vector3):
			return false
		var pos: Vector3 = area["pos"]
		if not is_finite(pos.x) or not is_finite(pos.y) or not is_finite(pos.z):
			return false
	if area.has("yaw"):
		if not (area["yaw"] is int or area["yaw"] is float) or not is_finite(float(area["yaw"])):
			return false
	for key in ["clues", "defeated"]:
		if not area.has(key):
			continue
		if not (area[key] is Array):
			return false
		for item in area[key]:
			if not (item is String) or str(item).is_empty():
				return false
	if area.has("banter_used"):
		if not (area["banter_used"] is Dictionary):
			return false
		for key in area["banter_used"]:
			if not (key is String) or str(key).is_empty() or not (area["banter_used"][key] is bool):
				return false
	return true


static func _read_valid_save(path: String) -> ConfigFile:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return null
	var loaded_chapter: int = int(cfg.get_value("storia", "capitolo", -1))
	var loaded_step: int = int(cfg.get_value("storia", "passo", -1))
	var chs: Array = chapters()
	if loaded_chapter < 0 or loaded_chapter > chs.size() or loaded_step < 0:
		return null
	if loaded_chapter < chs.size():
		var steps: Array = chs[loaded_chapter].get("passi", [])
		if loaded_step >= steps.size():
			return null
	var saved: Variant = cfg.get_value("storia", "flag", {})
	var st: Variant = cfg.get_value("storia", "area", {})
	if not (saved is Dictionary) or not validate_area_state(st):
		return null
	if cfg.has_section("squadra"):
		if not Progress.validate_save(cfg.get_value("squadra", "dati", null)):
			return null
	return cfg


static func load_game() -> bool:
	var cfg: ConfigFile = _read_valid_save(save_path)
	if cfg == null:
		# Se l'app si è interrotta tra lo spostamento del vecchio file e quello del temporaneo,
		# prova il backup prima di dichiarare persa la partita.
		cfg = _read_valid_save(save_path + ".bak")
	if cfg == null:
		return false
	chapter = int(cfg.get_value("storia", "capitolo", 0))
	step = int(cfg.get_value("storia", "passo", 0))
	flags = cfg.get_value("storia", "flag", {})
	area_state = cfg.get_value("storia", "area", {})
	if cfg.has_section("squadra"):
		Progress.from_save(cfg.get_value("squadra", "dati", {}))
	else:
		Progress.reset()
		# salvataggio di prima dei livelli: la squadra parte dal livello previsto per il capitolo (1, 3, 5, 7, 9, 11)
		for c in Progress.CAST:
			Progress.data["lv"][c] = 1 + 2 * clampi(chapter, 0, 5)
			for u in Progress.UNLOCKS[c]:
				if int(u[0]) <= int(Progress.data["lv"][c]):
					Progress._auto_equip(c, str(u[1]), str(u[2]))
	return true

static func save() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("storia", "capitolo", chapter)
	cfg.set_value("storia", "passo", step)
	cfg.set_value("storia", "flag", flags)
	if not area_state.is_empty():
		cfg.set_value("storia", "area", area_state)
	Progress.ensure()
	cfg.set_value("squadra", "dati", Progress.data)
	var temp_path: String = save_path + ".tmp"
	var backup_path: String = save_path + ".bak"
	var temp_abs: String = ProjectSettings.globalize_path(temp_path)
	var save_abs: String = ProjectSettings.globalize_path(save_path)
	var backup_abs: String = ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(temp_abs)
	if cfg.save(temp_path) != OK:
		return false
	var had_save: bool = FileAccess.file_exists(save_path)
	var main_valid: bool = had_save and _read_valid_save(save_path) != null
	if main_valid:
		# Conserva il file principale valido come backup. Non sovrascrivere mai un backup
		# recuperabile con un file principale che la validazione ha appena rifiutato.
		if FileAccess.file_exists(backup_path) and DirAccess.remove_absolute(backup_abs) != OK:
			DirAccess.remove_absolute(temp_abs)
			return false
		if DirAccess.rename_absolute(save_abs, backup_abs) != OK:
			DirAccess.remove_absolute(temp_abs)
			return false
	elif had_save:
		# Il file principale e' gia' invalido: lo sposta da parte, ma lascia intatto l'eventuale .bak.
		var bad_abs: String = ProjectSettings.globalize_path(save_path + ".bad")
		if FileAccess.file_exists(save_path + ".bad") and DirAccess.remove_absolute(bad_abs) != OK:
			DirAccess.remove_absolute(temp_abs)
			return false
		if DirAccess.rename_absolute(save_abs, bad_abs) != OK:
			DirAccess.remove_absolute(temp_abs)
			return false
	if DirAccess.rename_absolute(temp_abs, save_abs) != OK:
		if main_valid and FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_abs, save_abs)
		DirAccess.remove_absolute(temp_abs)
		return false
	# Il .bak e' il punto di recupero dell'ultimo salvataggio valido precedente.
	# Non eliminarlo dopo la scrittura: deve restare disponibile se il nuovo file si corrompe.
	return true


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
