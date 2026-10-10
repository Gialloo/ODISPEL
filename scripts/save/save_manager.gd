
extends Node

const SAVE_PATH: String = "user://odispel_save.json"
const SAVE_VERSION: int = 1


func save_game(data: Dictionary) -> bool:
	var save_data: Dictionary = data.duplicate(true)
	save_data["save_version"] = SAVE_VERSION

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error(
			"Impossibile aprire il file di salvataggio. Errore: "
			+ str(FileAccess.get_open_error())
		)
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

	print("SALVATAGGIO COMPLETATO: ", SAVE_PATH)
	return true


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		print("Nessun salvataggio trovato.")
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		push_error(
			"Impossibile leggere il salvataggio. Errore: "
			+ str(FileAccess.get_open_error())
		)
		return {}

	var json_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_text)

	if not parsed is Dictionary:
		push_error("Il file di salvataggio non contiene dati validi.")
		return {}

	var save_data: Dictionary = parsed

	if int(save_data.get("save_version", 0)) != SAVE_VERSION:
		push_warning("Versione del salvataggio non compatibile.")
		return {}

	print("SALVATAGGIO CARICATO: ", SAVE_PATH)
	return save_data
