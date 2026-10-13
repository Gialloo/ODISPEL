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

const TEAM_SIZE: int = 6          # party massimo (front row + back row)
const FRONT_SIZE: int = 3         # personaggi in front row in solitaria
const NET_TEAM_SIZE: int = 3      # in rete ogni giocatore porta al massimo 3 personaggi (1 in campo)
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
const GUARD_FACTOR: float = 0.5
const ENRAGE_BONUS: float = 1.25
const ENRAGE_BELOW: float = 0.5
const HUNTER_BONUS: float = 1.2
const RHYTHM_BONUS: float = 1.1        # RITMO: danno in piu' se cambi mossa rispetto al round prima
# EQUILIBRIO del boss (rottura): i colpi lo consumano; a zero il boss e' STORDITO, perde la mossa annunciata e prende piu' danno.
const BREAK_BASE: float = 8.0
const BREAK_PER_PLAYER: float = 3.0
const BREAK_PER_TIER: int = 3
const BREAK_PER_PHASE: int = 2
const BREAK_ADV: int = 3               # colpo con vantaggio di colore
const BREAK_NEUTRAL: int = 2
const BREAK_DISADV: int = 1
const BREAK_MARKED: int = 1            # il boss e' marchiato: ogni colpo rompe di piu' (chi marchia prepara, chi colpisce rompe)
const BREAK_HEAVY: int = 1             # colpo pesante (moltiplicatore >= 2)
const BREAK_DAMAGE: float = 1.25       # danno extra sul boss stordito
# SINERGIE tra compagni nello stesso round
const SYN_COVER: float = 1.12         # COPERTURA: un compagno ha scudato/curato/provocato prima, il tuo colpo fa di piu'
const SYN_TRACE_GAUGE: int = 10       # TRACCIA: colpisci un boss marchiato da un altro: ultimate +10 a te, +5 a chi ha marchiato
const PHASE_2_BELOW: float = 0.5
const PHASE_3_BELOW: float = 0.25
const PHASE_SHIELD: float = 0.05       # scudo del boss a ogni cambio di fase (in % dei PV massimi)
const PHASE_GAUGE: int = 25            # carica ultimate regalata alla squadra a ogni fase (rimonta)

const ACTION_ATTACK: String = "attack"
const ACTION_GUARD: String = "guard"


static func color_multiplier(attacker_color: String, defender_color: String) -> float:
	if BEATS.get(attacker_color, "") == defender_color:
		return COLOR_ADVANTAGE
	if BEATS.get(defender_color, "") == attacker_color:
		return COLOR_DISADVANTAGE
	return 1.0
