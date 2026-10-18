class_name Breadcrumb
extends RefCounted

# Traccia del punto raggiunto, scritta su disco a ogni passaggio importante.
# Se il gioco crasha, al riavvio il menu mostra dove si era fermato: serve a capire il crash anche senza adb.

const PATH: String = "user://breadcrumb.txt"
# Passi che NON indicano un crash (uscita normale o app messa in pausa dal telefono)
const SAFE: Array = ["", "uscita", "pausa", "menu"]

const NAMES: Dictionary = {
	"avvio": "Avvio del gioco",
	"menu": "Menu",
	"strada_carico": "Caricamento della strada 3D",
	"apertura": "Apertura (la cupola)",
	"strada": "Esplorazione della strada",
	"dialogo": "Dialogo",
	"battaglia_carico": "Caricamento del combattimento 3D",
	"battaglia": "Combattimento",
	"ultimate": "Sequenza dell'ultimate",
	"risultato": "Schermata finale del combattimento",
	"fine": "Fine del test",
}

static var _previous: String = ""
static var _read: bool = false


# Da chiamare una volta all'avvio, prima di mark(): legge dove si era fermata la sessione precedente.
static func read_previous() -> String:
	if not _read:
		_read = true
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f != null:
			_previous = f.get_as_text().strip_edges()
	return _previous


static func mark(step: String) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(step)
		f.flush()


# Testo da mostrare se la sessione precedente si e' interrotta in modo anomalo ("" se e' andata bene).
static func crash_note() -> String:
	var p: String = read_previous()
	if SAFE.has(p):
		return ""
	return "La sessione precedente si è interrotta durante: %s." % str(NAMES.get(p, p))
