class_name BattleTypes
extends RefCounted

# Costanti e regole di base del nuovo motore di combattimento.

const COLORS: Array = ["rosso", "verde", "blu", "giallo", "viola"]
const CLASSES: Array = ["striker", "vanguard", "warden"]
const RARITIES: Array = ["comune", "rara", "epica", "leggendaria"]
const GEAR_SLOTS: Array = ["arma", "petto", "stivali"]

# Vantaggi di colore: rosso > verde > blu > rosso, giallo <-> viola.
const BEATS: Dictionary = {
	"rosso": "verde",
	"verde": "blu",
	"blu": "rosso",
	"giallo": "viola",
	"viola": "giallo",
}
const COLOR_ADVANTAGE: float = 1.5
const COLOR_DISADVANTAGE: float = 0.67

const TEAM_SIZE: int = 3
const SKILL_SLOTS: int = 2
const PASSIVE_SLOTS: int = 2

const MAX_ENERGY: int = 6
const START_ENERGY: int = 2
const REGEN_ACTIVE: int = 1
const REGEN_BENCH: int = 2

# Munizioni (LibraCorp): si spendono per colpi speciali e per il contrattacco, si recuperano con Ricarica e Guardia.
const AMMO_MAX: int = 3
const COUNTER_MULT: float = 0.5

const GAUGE_MAX: int = 100
const GAUGE_ON_HIT: int = 15
const GAUGE_ON_DAMAGED: int = 10

# LEGAMI (combo tra compagni nello stesso round)
const LINK_BONUS: float = 0.15     # danno in piu' per ogni anello della catena
const LINK_MAX: int = 4
const LINK_GAUGE: int = 12         # ultimate caricata a entrambi quando si legano fazioni diverse (CROSS)

const BLEED_FRACTION: float = 0.04
const MARK_BONUS: float = 1.25
const GUARD_FACTOR: float = 0.5
const ENRAGE_BONUS: float = 1.25
const ENRAGE_BELOW: float = 0.5
const HUNTER_BONUS: float = 1.2

const ACTION_ATTACK: String = "attack"
const ACTION_GUARD: String = "guard"


static func color_multiplier(attacker_color: String, defender_color: String) -> float:
	if BEATS.get(attacker_color, "") == defender_color:
		return COLOR_ADVANTAGE
	if BEATS.get(defender_color, "") == attacker_color:
		return COLOR_DISADVANTAGE
	return 1.0
