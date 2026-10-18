class_name RosterStore
extends RefCounted

# Lettura e scrittura della collezione su disco. Il file e' separato dal
# salvataggio della run (odispel_save.json).

const DEFAULT_PATH: String = "user://odispel_roster.json"


static func save(roster: Dictionary, path: String = DEFAULT_PATH) -> bool:
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
		dir.remove(path.get_file())
	return dir.rename(tmp_path.get_file(), path.get_file()) == OK


# Se il file manca o e' rovinato ritorna una collezione iniziale nuova.
# Un file rovinato viene prima copiato in <path>.corrotto: il salvataggio
# successivo lo sovrascriverebbe e i progressi andrebbero persi per sempre.
static func load_or_new(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		# chiusura a meta' salvataggio: il file nuovo e' rimasto in .tmp
		var recovered: Dictionary = _read(path + ".tmp")
		return recovered if not recovered.is_empty() else RosterState.new_roster()
	var roster: Dictionary = _read(path)
	if roster.is_empty():
		DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".corrotto"))
		push_warning("Collezione non leggibile: copia in %s.corrotto, si riparte da zero." % path)
		return RosterState.new_roster()
	return roster


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var roster: Dictionary = RosterState.from_json(file.get_as_text())
	file.close()
	return roster
