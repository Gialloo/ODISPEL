class_name GameConfig
extends RefCounted

# Versione del gioco: host e client devono averla uguale per giocare insieme.
# Va aumentata a ogni nuova release che cambia le regole o la rete.
const VERSION: String = "0.24.17"

# Server di signaling predefinito (se cambia, basta un file server.txt).
const DEFAULT_SERVER_URL: String = "wss://odispel-signaling.onrender.com"

const SERVER_FILE_NAME: String = "server.txt"
const SETTINGS_PATH: String = "user://network_settings.cfg"


# Percorso di server.txt: accanto all'exe (nell'editor: nella cartella del progetto).
static func server_file_path() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://").path_join(SERVER_FILE_NAME)

	return OS.get_executable_path().get_base_dir().path_join(SERVER_FILE_NAME)


# Accetta anche https:// e http:// (le trasforma in wss:// e ws://) e toglie gli "/" finali.
static func normalize_server_url(raw: String) -> String:
	var url: String = raw.strip_edges()

	if url.begins_with("https://"):
		url = "wss://" + url.substr(8)
	elif url.begins_with("http://"):
		url = "ws://" + url.substr(7)

	while url.ends_with("/"):
		url = url.left(url.length() - 1)

	return url


static func is_valid_server_url(url: String) -> bool:
	return (
		(url.begins_with("ws://") and url.length() > 5)
		or (url.begins_with("wss://") and url.length() > 6)
	)


# Prima riga utile di server.txt (le righe vuote e quelle che iniziano con # si ignorano).
static func read_server_file() -> String:
	var file := FileAccess.open(server_file_path(), FileAccess.READ)

	if file == null:
		return ""

	var content: String = file.get_as_text()
	file.close()

	for line in content.split("\n"):
		var text: String = line.strip_edges()

		if text.is_empty() or text.begins_with("#"):
			continue

		var url: String = normalize_server_url(text)
		return url if is_valid_server_url(url) else ""

	return ""


# Ordine: server.txt, poi l'ultimo indirizzo usato, poi quello predefinito.
static func get_server_url() -> String:
	var from_file: String = read_server_file()

	if not from_file.is_empty():
		return from_file

	var settings := ConfigFile.new()

	if settings.load(SETTINGS_PATH) == OK:
		var saved: String = normalize_server_url(str(settings.get_value("network", "server_url", "")))

		if is_valid_server_url(saved):
			return saved

	return DEFAULT_SERVER_URL


# Ricorda l'indirizzo usato, ma solo se è diverso da quello predefinito:
# così una nuova versione con un nuovo server predefinito arriva a chi non l'ha mai cambiato.
static func remember_server_url(raw: String) -> void:
	if not read_server_file().is_empty():
		return

	var url: String = normalize_server_url(raw)

	if not is_valid_server_url(url):
		return

	var settings := ConfigFile.new()
	settings.load(SETTINGS_PATH)

	if url == DEFAULT_SERVER_URL:
		if settings.has_section_key("network", "server_url"):
			settings.erase_section_key("network", "server_url")
	else:
		settings.set_value("network", "server_url", url)

	settings.save(SETTINGS_PATH)
