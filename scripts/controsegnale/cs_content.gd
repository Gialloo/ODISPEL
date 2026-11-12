class_name CsContent
extends RefCounted

# CONTROSEGNALE · dati del combattimento in tempo reale a contrattacchi.
# Meccaniche ispirate a un JRPG a timeline con contrattacchi a colori; nomi, testi e numeri sono di ODISPEL.
# Progetto: /mnt/project-files/odispel/v3/combat_system/CONTROSEGNALE_PROGETTO.md
# I nomi delle mosse sono provvisori: li rivede la Voce dei personaggi.

const ROSSO: String = "rosso"
const GIALLO: String = "giallo"
const BLU: String = "blu"
const BIANCO: String = "bianco"          # colpo SFONDA: non si contra, si fa SCARTO
const COLORS: Array = [ROSSO, GIALLO, BLU]

# ---------------------------------------------------------------- finestre (secondi di gioco)
const WIN_GOOD_BEFORE: float = 0.30      # CONTRO buono: da 300 ms prima dell'impatto...
const WIN_GOOD_AFTER: float = 0.12       # ...a 120 ms dopo
const WIN_PERFECT: float = 0.08          # CONTRO perfetto: +-80 ms
const WIDE_MULT: float = 1.5             # finestra AMPIA (D12)
const BUFFER: float = 0.10               # memoria del tocco: 100 ms prima della finestra conta lo stesso (D12)
const SIMUL: float = 0.06                # tocchi entro 60 ms valgono come uno (D12)
const DANGER_LEAD: float = 0.60          # da 600 ms prima dell'impatto la coda si congela e i tocchi sono CONTRO (D2)
const MISS_STREAK_HINT: int = 3          # dopo 3 CONTRO mancati di fila Echo propone AMPIA (D12)

# ---------------------------------------------------------------- tempo
const TICK: float = 1.0 / 60.0
const IDLE_SLOW_AFTER: float = 1.0       # RALLENTY dopo 1 s senza tocchi
const SLOW_SCALE: float = 0.35

# ---------------------------------------------------------------- DIRETTA (combo, D11)
const DIRETTA_MAX: float = 100.0
const DIRETTA_STEPS: Array = [0.0, 33.0, 66.0, 100.0]   # soglie dei gradini 0..3
const DIRETTA_MULT: Array = [1.0, 1.1, 1.25, 1.5]
const DIRETTA_HIT: float = 6.0
const DIRETTA_CONTRO: float = 14.0
const DIRETTA_CONTRO_PERFECT: float = 20.0
const DIRETTA_IDLE_AFTER: float = 2.0    # cala solo se non fai niente per 2 s...
const DIRETTA_IDLE_RATE: float = 8.0     # ...di 8 al secondo, mai sotto il gradino in cui sei (D3, D11)

# ---------------------------------------------------------------- SEGNALE, BLACKOUT, TAG, FURIA
const SEGNALE_CONTRO: float = 18.0
const SEGNALE_CONTRO_PERFECT: float = 28.0
const SEGNALE_SPECCHIO_HEAL: float = 12.0 # contrare il colore dello SPECCHIO ridà segnale al nemico (D10)
const BLACKOUT_TIME: float = 5.0
const BLACKOUT_DMG_MULT: float = 2.0
const FINALE_FRAC: float = 0.15       # il finale toglie il 15% della vita massima
const TAG_TIME: float = 8.0
const TAG_DMG_MULT: float = 1.3
const TAG_SEGNALE_MULT: float = 1.3
const FURIA_MAX: float = 100.0
const FURIA_RATE: float = 9.0            # al secondo se il nemico non viene colpito (D3)
const FURIA_INTERVAL_MULT: float = 0.5
const FURIA_ATTACKS: int = 3
const COOLDOWN_WEAK_MULT: float = 0.35   # in cooldown la mossa parte, ma a un terzo della potenza
const QUEUE_MAX: int = 3
const COMBO_GAP: float = 1.5
const PARTNER_REVIVE: float = 8.0
const PARTNER_REVIVE_HP: float = 0.3
const WRONG_COLOR_DMG: float = 0.5       # colore sbagliato nella finestra: para a metà, niente contro
const COUNTER_HIT_DMG: int = 10          # il CONTRO colpisce anche, poco

# ---------------------------------------------------------------- eroi
# set1: le tre mosse di frequenza. set2: GUARDIA, CURA, TAG (ognuna su un tasto colore).
const HEROES: Dictionary = {
	"lance": {
		"name": "Lance", "hp": 220,
		"set1": {
			ROSSO: {"id": "lance_r", "name": "Carica a spalla", "dmg": 13, "cd": 1.6, "dur": 0.72},
			GIALLO: {"id": "lance_g", "name": "Colpo di guanto", "dmg": 9, "cd": 0.9, "dur": 0.48},
			BLU: {"id": "lance_b", "name": "Presa e leva", "dmg": 11, "cd": 1.3, "dur": 0.64},
		},
		"set2": {
			ROSSO: {"id": "lance_guard", "name": "Copertura", "kind": "guard", "cd": 6.0, "dur": 0.25},
			GIALLO: {"id": "lance_heal", "name": "Razione", "kind": "heal", "amount": 40, "cd": 12.0, "dur": 0.5},
			BLU: {"id": "lance_tag", "name": "Segna il bersaglio", "kind": "tag", "tag": BLU, "cd": 9.0, "dur": 0.6},
		},
	},
	"rio": {
		"name": "Rio", "hp": 170,
		"set1": {
			ROSSO: {"id": "rio_r", "name": "Flash in faccia", "dmg": 10, "cd": 1.1, "dur": 0.56},
			GIALLO: {"id": "rio_g", "name": "Asta da selfie", "dmg": 12, "cd": 1.4, "dur": 0.64},
			BLU: {"id": "rio_b", "name": "Zoom", "dmg": 8, "cd": 0.8, "dur": 0.45},
		},
		"set2": {
			ROSSO: {"id": "rio_tag", "name": "Tag in diretta", "kind": "tag", "tag": ROSSO, "cd": 9.0, "dur": 0.6},
			GIALLO: {"id": "rio_hype", "name": "Chat in fiamme", "kind": "diretta", "amount": 30.0, "cd": 14.0, "dur": 0.5},
			BLU: {"id": "rio_guard", "name": "Filtro", "kind": "guard", "cd": 6.0, "dur": 0.25},
		},
	},
}

# ---------------------------------------------------------------- nemici
# pattern: colpi in ordine, ciclico. windup = durata del MIRINO prima dell'impatto. gap = pausa dopo il colpo.
const ENEMIES: Dictionary = {
	"frammento": {
		"name": "Frammento", "hp": 1300, "segnale": 60, "dmg": 22,
		"pattern": [
			{"color": ROSSO, "windup": 1.2, "gap": 1.4},
			{"color": BLU, "windup": 1.0, "gap": 1.2},
			{"color": GIALLO, "windup": 1.2, "gap": 1.6},
		],
	},
	"sfondatore": {
		"name": "Sfondatore", "hp": 1500, "segnale": 70, "dmg": 26,
		"pattern": [
			{"color": GIALLO, "windup": 1.1, "gap": 1.2},
			{"color": BIANCO, "windup": 1.4, "gap": 1.5},
			{"color": ROSSO, "windup": 0.9, "gap": 1.2},
			{"color": BLU, "windup": 1.0, "gap": 1.4},
		],
	},
	"specchio": {
		"name": "Riflesso", "hp": 1500, "segnale": 70, "dmg": 24, "specchio": ROSSO,
		"pattern": [
			{"color": ROSSO, "windup": 1.0, "gap": 1.2},
			{"color": GIALLO, "windup": 1.1, "gap": 1.3},
			{"color": ROSSO, "windup": 0.9, "gap": 1.0},
			{"color": BLU, "windup": 1.1, "gap": 1.5},
		],
	},
	"boss_ripetitore": {
		"name": "Il Ripetitore", "hp": 14000, "segnale": 160, "dmg": 30, "boss": true,
		"pattern": [
			{"color": ROSSO, "windup": 1.0, "gap": 0.8},
			{"color": ROSSO, "windup": 0.7, "gap": 1.2},
			{"color": BIANCO, "windup": 1.3, "gap": 1.0},
			{"color": BLU, "windup": 0.9, "gap": 0.6},
			{"color": GIALLO, "windup": 0.8, "gap": 1.4},
		],
		# a metà vita lo SPECCHIO passa sul blu: la risposta cambia (D10)
		"phase2": {"specchio": BLU},
	},
}

# Tempi di riferimento per il VOTO (D6): sotto il par si prende il massimo sul tempo.
const PAR_TIME: Dictionary = {"frammento": 25.0, "sfondatore": 30.0, "specchio": 40.0, "boss_ripetitore": 150.0}


static func step_of(value: float) -> int:
	var s: int = 0
	for i in range(DIRETTA_STEPS.size()):
		if value >= float(DIRETTA_STEPS[i]):
			s = i
	return s
