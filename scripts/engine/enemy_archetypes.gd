class_name EnemyArchetypes
extends RefCounted

# ARCHETIPI DEI NEMICI (Review 01 del game director, 4/11/2026): ogni nemico pone al giocatore un problema riconoscibile,
# e la risposta premia chi l'ha capito. Non sono regole nuove: danno un nome e una lettura alle regole che ci sono gia'
# (BreakRules, cicli di mosse, scheggia). La lettura la dice Echo a inizio scontro, gia' al primo incontro.
# Il nome dell'archetipo NON compare a schermo (sarebbe un'etichetta da JRPG qualunque): serve a noi per progettare.

const ARCHETYPES: Dictionary = {
	"aggressore": "Sopravvivere ai suoi attacchi",
	"difensore": "Aprire una finestra offensiva",
	"interruttore": "Interrompere le sue preparazioni",
	"predatore": "Gestire le priorità e le minacce",
	"distorsore": "Modificare le condizioni dello scontro",
}

# nemico -> [archetipo, lettura di Echo (corta: sta su un avviso)]
const ENEMIES: Dictionary = {
	"distributore": ["aggressore", "Colpi pesanti su uno solo: GUARDIA quando punta te"],
	"autovelox": ["aggressore", "Il Verbale fa male: para perfetto, poi punisci"],
	"frammento_blu": ["aggressore", "Veloce e insistente: tieni alta la guardia"],
	"cassaforte": ["difensore", "Si blinda: colpiscila quando è aperta"],
	"frammento_rosso": ["difensore", "Corazzato: serve il colore vincente"],
	"semaforo": ["interruttore", "Carica il ROSSO: rompilo prima che scatti"],
	"frammento_verde": ["interruttore", "Ricresce a ogni round: rompilo in fretta"],
	"cabina": ["predatore", "Sceglie una vittima: chi è chiamato risponde"],
	"manichino": ["distorsore", "Ti copia: cambia tipo di mossa ogni volta"],
	"gregario": ["predatore", "La Scheggia punta il più ferito: abbattila o coprilo"],
}
# Il frammento giallo resta senza archetipo: e' il nemico delle lezioni (impari i colori). Da decidere con l'autore.


static func of(enemy_id: String) -> String:
	return str((ENEMIES.get(enemy_id, ["", ""]) as Array)[0])


static func reading(enemy_id: String) -> String:
	return str((ENEMIES.get(enemy_id, ["", ""]) as Array)[1])
