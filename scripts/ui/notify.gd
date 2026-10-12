class_name Notify
extends RefCounted

# Porta d'ingresso unica per i feedback al giocatore (avvisi, icona di attivita',
# salvataggio, schermata di caricamento). Se il gioco non ha l'interfaccia
# (per esempio nei test) le chiamate non fanno nulla.

enum Kind { INFO, SUCCESS, WARNING, ERROR }


static func _hub() -> Node:
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("Feedback")
	return null


# Avviso breve in un angolo dello schermo.
static func toast(text: String, kind: Kind = Kind.INFO) -> void:
	var hub: Node = _hub()
	if hub != null:
		hub.show_toast(text, kind)


static func success(text: String) -> void:
	toast(text, Kind.SUCCESS)


static func warning(text: String) -> void:
	toast(text, Kind.WARNING)


static func error(text: String) -> void:
	toast(text, Kind.ERROR)


# Icona rotante "sto lavorando" nell'angolo. Ogni attivita' ha un nome: finita
# quella, chiama idle(nome). Se ce ne sono piu' di una mostra l'ultima.
static func busy(job: String, text: String) -> void:
	var hub: Node = _hub()
	if hub != null:
		hub.begin_job(job, text)


static func idle(job: String) -> void:
	var hub: Node = _hub()
	if hub != null:
		hub.end_job(job)


# "SALVATO" con la spunta, subito dopo un salvataggio.
static func saved() -> void:
	var hub: Node = _hub()
	if hub != null:
		hub.show_saved(true)


static func save_failed() -> void:
	var hub: Node = _hub()
	if hub != null:
		hub.show_saved(false)


# Esegue `action` (di solito un cambio scena) coperta dalla schermata di caricamento.
static func transition(action: Callable, title: String = "CARICAMENTO", tip: String = "") -> void:
	var hub: Node = _hub()
	if hub != null:
		hub.transition(action, title, tip)
	else:
		action.call()
