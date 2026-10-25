class_name GameConfig
extends RefCounted

# Versione e dati fissi della V3 standalone.

const VERSION: String = "0.41.11"
const TITLE: String = "ODISPEL"
const SUBTITLE: String = "OFFICIAL DEMO · ATTO 1"
const CITY: String = "[CITTÀ]"          # PROVVISORIO: nome non ancora deciso

# Sul telefono e sul PC il test resta a 60 fotogrammi: meno calore e batteria, ed e' quello che misuriamo.
const MAX_FPS: int = 60  # solo per le prove; nel gioco il limite lo sceglie il giocatore (Settings.fps_cap)
