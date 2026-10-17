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


static func reset() -> void:
	active = false
	boss_id = "distributore"
	pending = ""
	result = ""
	pos = Vector2.INF
	facing = 1.0
	defeated = {}
	read = {}


# Nome della scena a cui tornare dalla battaglia V2
static func back_scene() -> String:
	return "world_v2" if active else "squad_v2"
