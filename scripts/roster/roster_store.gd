class_name RosterStore
extends RefCounted

# Lettura e scrittura della collezione su disco. Il file e' separato dal
# salvataggio della run (odispel_save.json).

const DEFAULT_PATH: String = "user://odispel_roster.json"


static func save(roster: Dictionary, path: String = DEFAULT_PATH) -> bool:
	var ok: bool = _write(roster, path)
	if ok:
		Notify.saved()
	else:
		Notify.save_failed()
	return ok


static func _write(roster: Dictionary, path: String) -> bool:
	if RosterState.validate(roster) != "":
		return false
	# scrive su un file temporaneo e poi lo rinomina: niente file a meta' se si chiude
	var tmp_path: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(RosterState.to_json(roster))
	file.close()
	var dir: DirAccess = DirAccess.open(path.get_base_dir())
	if dir == null:
		return false
	if dir.file_exists(path.get_file()):
		# copia di sicurezza dell'ultimo salvataggio buono: se il nuovo si rovina, c'e' ancora questo
		if dir.file_exists(path.get_file() + ".bak"):
			dir.remove(path.get_file() + ".bak")
		dir.copy(path, path + ".bak")
		dir.remove(path.get_file())
	return dir.rename(tmp_path.get_file(), path.get_file()) == OK


# Se il file manca o e' rovinato ritorna una collezione iniziale nuova.
static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var roster: Dictionary = RosterState.from_json(file.get_as_text())
	file.close()
	return roster


# Carica la collezione. Se il file principale e' rovinato prova la copia di sicurezza; se anche quella
# non va, mette da parte il file rovinato (.corrotto) invece di sovrascriverlo con una collezione nuova.
static func load_or_new(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		var spare: Dictionary = _read(path + ".bak")
		return spare if not spare.is_empty() else RosterState.new_roster()
	var roster: Dictionary = _read(path)
	if not roster.is_empty():
		return roster
	var backup: Dictionary = _read(path + ".bak")
	var dir: DirAccess = DirAccess.open(path.get_base_dir())
	if dir != null:
		if dir.file_exists(path.get_file() + ".corrotto"):
			dir.remove(path.get_file() + ".corrotto")
		dir.copy(path, path + ".corrotto")
	if not backup.is_empty():
		push_warning("RosterStore: salvataggio rovinato, uso la copia di sicurezza.")
		return backup
	return RosterState.new_roster()
