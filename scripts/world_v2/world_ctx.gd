class_name WorldV2Ctx
extends RefCounted

# Stato condiviso tra la mappa del Test V2 (world_v2) e la battaglia V2: la scena viene ricaricata a ogni combattimento,
# quindi posizione, avversari battuti e risultato dell'ultimo scontro vivono qui. Niente salvataggio su disco:
# il Test V2 e' un addestramento, chiudendo il gioco si riparte da capo.

static var active: bool = false          # la battaglia e' stata lanciata dalla mappa
static var boss_id: String = "distributore"
static var pending: String = ""          # id dell'incontro in corso
static var result: String = ""           # "", "win", "lose", "flee"
static var pos: Vector2 = Vector2.INF    # posizione del giocatore (x, z); INF = punto di partenza
static var facing: float = 1.0
static var defeated: Dictionary = {}     # id incontro -> true
static var read: Dictionary = {}         # oggetti letti (solo per i dialoghi)

# ESPLORAZIONE (scoperte, zone visitate, tag di vernice {"i": indice muro, "c": indice colore}): in un file a parte (user://world_v2.cfg), NON nel salvataggio del gioco.
# Si scrive solo se `persist` e' vero (si imposta giocando dalla SQUADRA V2; i test non toccano il disco).
const SAVE_PATH: String = "user://world_v2.cfg"
static var persist: bool = false
static var found: Dictionary = {}        # id scoperta -> true
static var zones: Dictionary = {}        # indice zona visitata -> true
static var sprayed: Array = []           # tag di vernice: {"x","z","c"}


static func reset() -> void:
	active = false
	boss_id = "distributore"
	pending = ""
	result = ""
	pos = Vector2.INF
	facing = 1.0
	defeated = {}
	read = {}
	persist = false
	found = {}
	zones = {}
	sprayed = []


# Nome della scena a cui tornare dalla battaglia V2
static func back_scene() -> String:
	return "world_v2" if active else "squad_v2"


static func load_persist() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for k in cfg.get_value("esplora", "found", []):
		found[str(k)] = true
	for k in cfg.get_value("esplora", "zones", []):
		zones[int(k)] = true
	var sp: Variant = cfg.get_value("esplora", "sprayed", [])
	if sp is Array:
		sprayed = (sp as Array).duplicate(true)


static func save_persist() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("esplora", "found", found.keys())
	cfg.set_value("esplora", "zones", zones.keys())
	cfg.set_value("esplora", "sprayed", sprayed)
	cfg.save(SAVE_PATH)
