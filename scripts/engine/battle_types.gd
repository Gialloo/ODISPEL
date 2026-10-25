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
const FRONT_SIZE: int = 4         # V3: quattro in campo (stile Star Rail); nella V2 erano 3
const NET_TEAM_SIZE: int = 3      # in rete ogni giocatore porta al massimo 3 personaggi (1 in campo)
const SKILL_SLOTS: int = 4       # mosse del menu (max 4 + ultimate); Attacco e Guardia occupano uno slot come le altre
const BASIC_MOVES: Array = ["attack", "guard"]
# Valori medi dei boss, usati dai livelli di difficolta' "appiattiti".
const FLAT_BOSS_HP: float = 1400.0
const FLAT_BOSS_ATK: float = 440.0
const KIT_BONUS_PCT: int = 3      # kit completo (4 mosse + ultimate): +3% PV, attacco e difesa (per ora uguale per tutti)
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
const ENRAGE_BONUS: float = 1.5
const ENRAGE_BELOW: float = 0.5
const HUNTER_BONUS: float = 1.1
const RHYTHM_BONUS: float = 1.1        # RITMO: danno in piu' se cambi mossa rispetto al round prima
# EQUILIBRIO del boss (rottura): i colpi lo consumano; a zero il boss e' STORDITO, perde la mossa annunciata e prende piu' danno.
const BREAK_BASE: float = 22.0
const BREAK_PER_PLAYER: float = 3.0
const BREAK_PER_TIER: int = 3
const BREAK_PER_PHASE: int = 2
const BREAK_ADV: int = 3               # colpo con vantaggio di colore
const BREAK_NEUTRAL: int = 2
const BREAK_DISADV: int = 1
const BREAK_MARKED: int = 1            # il boss e' marchiato: ogni colpo rompe di piu' (chi marchia prepara, chi colpisce rompe)
const BREAK_HEAVY: int = 1             # colpo pesante (moltiplicatore >= 2)
const BREAK_DAMAGE: float = 1.25       # danno extra sul boss stordito
# SCALA DEL NEMICO NELLA STORIA (la squadra sale di livello, il nemico cresce con lei): usata da battle3d.gd e da tools/v3_bilancio.gd
const REPLICA_K: float = 0.15             # Replica della diretta: +15% PV e attacco dei nemici per ogni giro dopo il primo
const REPLICA_K_GIRI: int = 4             # ... fino al quarto giro: dopo la durezza la portano i livelli (con 10 giri gli scontri duravano il doppio)
const STORY_HP_BOSS: float = 3.0          # PV del boss rispetto al motore
const STORY_HP_MINOR: float = 1.5         # PV di un nemico minore (frammento)
const STORY_ATK_K: float = 2.5            # attacco di tutti i nemici della storia
const STORY_HP_PER_LEVEL: float = 0.14    # +14% PV per livello sopra il primo
const STORY_ATK_PER_LEVEL: float = 0.24   # +24% attacco per livello sopra il primo
# OLTRE L'ATTO 1 (Replica della diretta = New Game+, livelli fino a 100): fino a STORY_KNEE valgono le due righe sopra, tarate
# sull'atto 1; dopo, il nemico cresce come la squadra (stesso +8% a livello di LEVEL_BONUS) piu' un poco, perche' la squadra
# ha mosse, tratti e sinergie piu' forti (la retta di prima a livello 100 dava un attacco x24 contro PV x9: ingiocabile)
const STORY_KNEE: int = 12
const STORY_HP_EXTRA: float = 0.0         # PV: +1,2% a livello oltre il ginocchio, sopra la crescita della squadra
const STORY_ATK_EXTRA: float = 0.0        # attacco: idem (compensa la difesa della squadra, che a livelli alti ripara molto di piu')
const REPLICA_MAX: int = 10               # New Game+ fino a NG+10 (la decima si puo' rigiocare quanto si vuole)
const REPLICA_LEVEL_FIRST: int = 13       # NG+1: i nemici del capitolo 1 (livello 1) sono tarati sul livello 14
const REPLICA_LEVEL_STEP: int = 9         # ogni giro dopo il primo: +9 livelli (NG+10: dal 95 al 100)
const ENEMY_MAX_LEVEL: int = 100
const REPLICA_EXP_FIRST: float = 2.0      # NG+1: esperienza x2 ...
const REPLICA_EXP_STEP: float = 0.25      # ... e +25% a ogni giro dopo (NG+10: x4,25)
const SLANCIO_GUARD_SHIELD: float = 0.08  # SLANCIO con scelta: la Guardia rapida da' uno scudo dell'8% dei PV massimi a tutta la squadra ...
const SLANCIO_GUARD_EN: int = 1          # ... e 1 energia in piu': l'azione extra rende di piu' se non e' un attacco
const SLANCIO_ON: bool = true             # colpo col colore vincente = azione rapida subito dopo (una volta a round, squadra)
const BREAK_TEAM_MULT: float = 1.3         # attacco di squadra alla rottura: colpo di ogni altro eroe (0 = spento). 1.3: deve pesare, e' il premio del BREAK (prima 0.6, non si notava)
const BREAK_RECOVER: float = 0.75       # frazione della barra con cui il boss si riprende dopo una rottura (1 = piena)
const BREAK_REGEN: int = 1             # equilibrio recuperato a fine round se non e' stato rotto
# SINERGIE tra compagni nello stesso round
const SYN_COVER: float = 1.12         # COPERTURA: un compagno ha scudato/curato/provocato prima, il tuo colpo fa di piu'
const SYN_TRACE_GAUGE: int = 10       # TRACCIA: colpisci un boss marchiato da un altro: ultimate +10 a te, +5 a chi ha marchiato
const ADAPT_MULT: float = 0.85        # ADATTAMENTO: la terza volta di fila che usi la stessa mossa il boss si abitua
const ARDOR_BELOW: float = 0.3         # ARDORE: sotto il 30% PV l'operatore colpisce piu' forte (rimonta)
const ARDOR_BONUS: float = 1.15
const PHASE_2_BELOW: float = 0.5
const PHASE_3_BELOW: float = 0.25
const PHASE_SHIELD: float = 0.05       # scudo del boss a ogni cambio di fase (in % dei PV massimi)
const PHASE_GAUGE: int = 25            # carica ultimate regalata alla squadra a ogni fase (rimonta)

const ACTION_ATTACK: String = "attack"
const ACTION_GUARD: String = "guard"


# SECONDO PUNTO DEBOLE (boss gialli): la ruota dei colori resta com'e'; in piu' il boss ha un secondo colore che lo ferisce (+25% danno).
const WEAK2_MULT: float = 1.25

# Il colpo di `attacker` colpisce il secondo punto debole di `defender` (solo boss con "weak2", e solo se la ruota non gia' favorisce)?
static func hits_weak2(attacker: Dictionary, defender: Dictionary) -> bool:
	var w2: String = str(defender.get("weak2", ""))
	return w2 != "" and str(attacker.get("color", "")) == w2 and color_multiplier(str(attacker["color"]), str(defender["color"])) <= 1.0


static func color_multiplier(attacker_color: String, defender_color: String) -> float:
	if BEATS.get(attacker_color, "") == defender_color:
		return COLOR_ADVANTAGE
	if BEATS.get(defender_color, "") == attacker_color:
		return COLOR_DISADVANTAGE
	return 1.0

# RISERVA DI SQUADRA (condivisa): si spende per le reazioni.
const RESERVE_START: int = 3
const RESERVE_MAX: int = 6
const RESERVE_PER_ROUND: int = 1
const RESERVE_PER_COMBO: int = 1          # una sola volta a round
const PHASE_DRAINS_RESERVE: bool = false  # Fase 3 del piano: la fase 2 non prosciuga piu' la Riserva, cambia la domanda (rompilo mentre carica, BreakRules)
const RESERVE_DRAIN_PHASE: int = 2        # la fase 2 prosciuga la Riserva (solo con PHASE_DRAINS_RESERVE)
const RESERVE_DRAIN_ROUND: int = 1        # e in fase 2+ il boss ne assorbe ancora un po' ogni round
const INTERRUPT_PTS: int = 4              # equilibrio tolto da un'Interruzione
const RESCUE_HP: float = 0.25            # PV con cui torna chi viene soccorso
const INTERCEPT_FACTOR: float = 0.6       # danno preso da chi intercetta

# GUARDIA A TEMPO (V3): il giocatore tocca lo schermo quando parte il colpo annunciato del boss.
# "good" = nella finestra, "perfect" = proprio al momento dell'impatto (vedi state["timed_guard"]).
const TIMED_GUARD_FACTOR: float = 0.6     # danno preso con la guardia a tempo
const TIMED_PERFECT_FACTOR: float = 0.25  # danno preso con la parata perfetta
const TIMED_GUARD_GAUGE: int = 8          # ultimate caricata a chi para in tempo
const TIMED_PERFECT_GAUGE: int = 18       # ultimate caricata a chi para perfetto
const TIMED_COUNTER_MULT: float = 0.9     # contrattacco della parata perfetta (scalfisce anche l'equilibrio)


# ---------------------------------------------------------------- scala dei nemici della storia (atto 1 e New Game+)

# Livello di un nemico nella Replica numero `replica` (0 = prima partita): l'atto 1 va da 1 a 11, NG+1 da 14 a 24, ...
static func replica_level(base_level: int, replica: int) -> int:
	if replica <= 0:
		return base_level
	var r: int = mini(replica, REPLICA_MAX)
	return mini(ENEMY_MAX_LEVEL, base_level + REPLICA_LEVEL_FIRST + REPLICA_LEVEL_STEP * (r - 1))


# PV e attacco in piu' della Replica (moltiplicatore, sopra la scala per livello)
static func replica_hard(replica: int) -> float:
	return 1.0 + REPLICA_K * float(clampi(replica, 0, REPLICA_K_GIRI))


# Esperienza in piu' nella Replica (moltiplicatore)
static func replica_exp(replica: int) -> float:
	if replica <= 0:
		return 1.0
	return REPLICA_EXP_FIRST + REPLICA_EXP_STEP * float(mini(replica, REPLICA_MAX) - 1)


static func _party_growth(level: int) -> float:
	return 1.0 + 0.08 * float(level - 1)      # = BattleContent.LEVEL_BONUS (qui per non legare i tipi ai contenuti)


# Moltiplicatore dei PV del nemico per livello (1.0 al livello 1)
static func story_hp_grow(level: int) -> float:
	var k: int = mini(level, STORY_KNEE)
	var g: float = 1.0 + STORY_HP_PER_LEVEL * float(k - 1)
	if level > STORY_KNEE:
		g *= _party_growth(level) / _party_growth(STORY_KNEE) * (1.0 + STORY_HP_EXTRA * float(level - STORY_KNEE))
	return g


# Moltiplicatore dell'attacco del nemico per livello (1.0 al livello 1)
static func story_atk_grow(level: int) -> float:
	var k: int = mini(level, STORY_KNEE)
	var g: float = 1.0 + STORY_ATK_PER_LEVEL * float(k - 1)
	if level > STORY_KNEE:
		g *= _party_growth(level) / _party_growth(STORY_KNEE) * (1.0 + STORY_ATK_EXTRA * float(level - STORY_KNEE))
	return g

