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
static func load_or_new(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return RosterState.new_roster()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return RosterState.new_roster()
	var roster: Dictionary = RosterState.from_json(file.get_as_text())
	file.close()
	if roster.is_empty():
		return RosterState.new_roster()
	return roster
