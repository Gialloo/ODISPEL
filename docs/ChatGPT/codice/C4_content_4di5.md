FILE battle_content.gd - PARTE 4 DI 5
Percorso: scripts/battle/battle_content.gd
(Codice GDScript, rientri con tab. Non rispondere finche' non scrivo FINE FILE.)

```gdscript
const BOSSES: Dictionary = {
	"distributore": {
		"name": "Distributore", "title": "CLASSE ANOMALIA · MINACCIA BASSA", "color": "giallo", "hp_per_player": 900,
		"atk": 390, "def": 25, "spd": 105,
		"desc": "Un distributore automatico impazzito. Colpi pesanti a un solo bersaglio e scosse che fanno sanguinare.",
		"cycle": ["scarica", "raffica", "scossa", "sovraccarico"],
		"ally": "eco",
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 3,
		"reward": {"coins": 600, "nucleo": [4, 8], "lega": [2, 6], "gear_chance": 65},
	},
	"semaforo": {
		"name": "Semaforo", "title": "CLASSE ANOMALIA · MINACCIA MEDIA", "color": "rosso", "hp_per_player": 850,
		"atk": 380, "def": 20, "spd": 118,
		"desc": "Un semaforo che non cambia piu' colore. Veloce: agisce prima di quasi tutti. Marchia la squadra e punta chi e' piu' ferito.",
		"cycle": ["lampeggio", "rosso", "giallo", "verde"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 3,
		"reward": {"coins": 900, "nucleo": [6, 10], "lega": [4, 8], "gear_chance": 75},
	},
	"tombino": {
		"name": "Tombino", "title": "CLASSE ANOMALIA · MINACCIA ALTA", "color": "viola", "hp_per_player": 1000,
		"atk": 340, "def": 35, "spd": 82,
		"desc": "Qualcosa vive sotto il tombino. Lento ma resistente: si cura risucchiando i feriti e si chiude sotto uno scudo.",
		"cycle": ["gorgo", "risucchio", "alluvione", "chiusura"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 4,
		"reward": {"coins": 1300, "nucleo": [8, 14], "lega": [6, 12], "gear_chance": 85},
	},
	"cabina": {
		"name": "Cabina", "title": "CLASSE ANOMALIA · MINACCIA CRITICA", "color": "blu", "hp_per_player": 1100,
		"atk": 360, "def": 30, "spd": 96,
		"desc": "Una cabina telefonica che squilla da sola. Marchia la squadra, chiama un bersaglio con un colpo pesante e si nutre di chi e' gia' ferito.",
		"cycle": ["squillo", "chiamata", "interferenza", "linea_occupata"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 4,
		"reward": {"coins": 1700, "nucleo": [10, 16], "lega": [8, 14], "gear_chance": 95},
	},
	"ascensore": {
		"name": "Ascensore", "title": "CLASSE ANOMALIA · MINACCIA ESTREMA", "color": "blu", "hp_per_player": 1200,
		"atk": 380, "def": 40, "spd": 90,
		"desc": "L'ascensore della torre LibraCorp: sale a piani che non esistono. Porte che si chiudono su un solo bersaglio, cadute su tutta la squadra, e una manutenzione che lo protegge.",
		"cycle": ["porte", "caduta_libera", "piano_zero", "manutenzione"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 4,
		"reward": {"coins": 2100, "nucleo": [12, 18], "lega": [9, 15], "gear_chance": 100},
	},
	"manichino": {
		"name": "Manichino", "title": "CLASSE ANOMALIA · MINACCIA ESTREMA", "color": "verde", "hp_per_player": 1150,
		"atk": 400, "def": 28, "spd": 112,
		"desc": "Un manichino in vetrina che copia chi lo guarda. Veloce: marchia tutti dietro il vetro, posa su un bersaglio e si nutre dei feriti.",
		"cycle": ["posa", "vetrina", "copia", "sfilata"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 4,
		"reward": {"coins": 2500, "nucleo": [14, 20], "lega": [11, 17], "gear_chance": 100},
	},
	"orologio": {
		"name": "Orologio", "title": "CLASSE ANOMALIA · MINACCIA ASSOLUTA", "color": "viola", "hp_per_player": 1500,
		"atk": 420, "def": 45, "spd": 100,
		"desc": "L'orologio della torre, al centro di CAM-00. Ferma il tempo per chi lo guarda: colpi pesanti, lancette che feriscono tutti e un'ora zero che marchia la squadra.",
		"cycle": ["rintocco", "lancette", "ora_zero", "tempo_perso"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 3500, "nucleo": [18, 26], "lega": [14, 22], "gear_chance": 100},
	},
	"specchio": {
		"name": "Specchio", "title": "CLASSE ANOMALIA · OLTRE LA SCALA", "color": "rosso", "hp_per_player": 1700,
		"atk": 440, "def": 50, "spd": 108,
		"ally": "nico",
		"desc": "Lo specchio che c'era dietro l'orologio: mostra la squadra come sarebbe stata se il tempo non si fosse fermato. Un riflesso colpisce un solo bersaglio, i frantumi feriscono tutti e il doppio si nutre dei piu' deboli.",
		"cycle": ["riflesso", "frantumi", "doppio", "simmetria"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 4600, "nucleo": [22, 30], "lega": [18, 26], "gear_chance": 100},
	},
	"sirena": {
		"name": "Sirena", "title": "S2 · MINACCIA ALTA", "color": "rosso", "hp_per_player": 1250,
		"atk": 430, "def": 42, "spd": 104,
		"ally": "dafne",
		"desc": "La sirena d'allarme di Via Pia: urla da sola da tre notti. Marchia tutta la squadra, chiama un solo bersaglio con l'allarme rosso e si ripara dietro il coprifuoco.",
		"cycle": ["ululato", "allarme", "stridio", "coprifuoco"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 5000, "nucleo": [24, 32], "lega": [20, 28], "gear_chance": 100},
	},
	"lampione": {
		"name": "Lampione", "title": "S2 · MINACCIA ALTA", "color": "giallo", "hp_per_player": 1300,
		"atk": 440, "def": 44, "spd": 98,
		"desc": "Un lampione di Piazza dei Salici che accende il buio invece di spegnerlo. Abbaglia un bersaglio, marchia tutti nel buio e attira le falene sui piu' feriti.",
		"cycle": ["abbaglio", "buio", "falena", "cono_di_luce"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 5800, "nucleo": [26, 34], "lega": [22, 30], "gear_chance": 100},
	},
	"bancomat": {
		"name": "Bancomat", "title": "S2 · MINACCIA ESTREMA", "color": "verde", "hp_per_player": 1350,
		"atk": 450, "def": 46, "spd": 92,
		"desc": "Un bancomat che non restituisce niente. Preleva vita ai piu' deboli, addebita commissioni a tutti e chiude la carta sotto uno scudo.",
		"cycle": ["prelievo", "commissione", "saldo_negativo", "blocco_carta"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 6600, "nucleo": [28, 36], "lega": [24, 32], "gear_chance": 100},
	},
	"scala": {
		"name": "Scala mobile", "title": "S2 · MINACCIA ESTREMA", "color": "blu", "hp_per_player": 1400,
		"atk": 455, "def": 48, "spd": 100,
		"desc": "La scala mobile della stazione, che scende anche quando sale. Un gradino mancante colpisce uno solo, la risalita ferisce tutti.",
		"cycle": ["gradino", "risalita", "senso_inverso", "arresto"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 7500, "nucleo": [30, 38], "lega": [26, 34], "gear_chance": 100},
	},
	"radio": {
		"name": "Radio", "title": "S2 · MINACCIA ESTREMA", "color": "viola", "hp_per_player": 1450,
		"atk": 465, "def": 50, "spd": 110,
		"desc": "Una radio che trasmette voci di chi non c'e' piu'. Veloce: marchia tutti col fruscio, forza la sintonia su un bersaglio e succhia chi e' gia' a terra.",
		"cycle": ["fruscio", "sintonia", "disturbo", "onda_lunga"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 8400, "nucleo": [32, 40], "lega": [28, 36], "gear_chance": 100},
	},
	"metro": {
		"name": "Metro", "title": "S2 · MINACCIA ASSOLUTA", "color": "rosso", "hp_per_player": 1550,
		"atk": 480, "def": 52, "spd": 114,
		"desc": "Il treno fantasma dell'ultima corsa. Veloce e pesante: binario morto su un bersaglio, ultima corsa su tutti, capolinea sui piu' deboli.",
		"cycle": ["binario", "ultima_corsa", "fermata", "capolinea"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 9400, "nucleo": [34, 42], "lega": [30, 38], "gear_chance": 100},
	},
	"cassaforte": {
		"name": "Cassaforte", "title": "S2 · MINACCIA ASSOLUTA", "color": "verde", "hp_per_player": 1650,
		"atk": 470, "def": 66, "spd": 84,
		"desc": "La cassaforte del caveau LibraCorp. Lenta ma blindata: la combinazione marchia la squadra, la blindatura la protegge e il furto svuota i feriti.",
		"cycle": ["serratura", "combinazione", "blindatura", "furto"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 10500, "nucleo": [36, 44], "lega": [32, 40], "gear_chance": 100},
	},
	"faro": {
		"name": "Faro", "title": "S2 · MINACCIA ASSOLUTA", "color": "blu", "hp_per_player": 1700,
		"atk": 490, "def": 58, "spd": 102,
		"desc": "Il faro del porto vecchio, che guida le navi verso gli scogli. Il fascio colpisce un solo bersaglio, la nebbia marchia tutti, il naufragio ferisce l'intera squadra.",
		"cycle": ["fascio", "nebbia", "naufragio", "marea_nera"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 11700, "nucleo": [38, 46], "lega": [34, 42], "gear_chance": 100},
	},
	"registro": {
		"name": "Registro", "title": "S2 · OLTRE LA SCALA", "color": "giallo", "hp_per_player": 1850,
		"atk": 510, "def": 62, "spd": 106,
		"desc": "L'archivio nero di LibraCorp: dove finisce chi viene cancellato. Cancella un bersaglio, schedatura marchia tutti, l'archiviazione si nutre dei piu' deboli.",
		"cycle": ["cancellazione", "protocollo_nero", "fascicolo", "archiviazione"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 13000, "nucleo": [40, 48], "lega": [36, 44], "gear_chance": 100},
	},
	"eclissi": {
		"name": "Eclissi", "title": "S2 · IL FINALE", "color": "viola", "hp_per_player": 2100,
		"atk": 540, "def": 70, "spd": 110,
		"desc": "Il sole nero sopra i sette minuti perduti. Oscura e marchia tutti, la corona schiaccia un solo bersaglio, la penombra beve i piu' deboli e l'ora nera ferisce tutta la squadra.",
		"cycle": ["oscuramento", "corona", "penombra", "ora_nera"],
		"atk_scale": [0.62, 0.8, 1.0],
		"drops": 5,
		"reward": {"coins": 15000, "nucleo": [44, 54], "lega": [40, 50], "gear_chance": 100},
	},
}


# Il ciclo di mosse del boss cambia a ogni fase (meta' e un quarto dei PV): ordine diverso e mosse nuove.
static func cycle_for(boss_id: String, phase: int) -> Array:
	var c: Array = BOSSES[boss_id]["cycle"]
	if phase >= 3 and c.size() >= 4:
		return ["ultimo_respiro", c[1], c[3], "furia", c[0], c[2]]
	if phase == 2 and c.size() >= 4:
		return [c[2], c[0], "furia", c[3], c[1]]
	return c


static func tier_of(tier: int) -> Dictionary:
	return TIERS[clampi(tier, 0, TIERS.size() - 1)]


static func rarity_of(kind: String, id: String) -> int:
	var table: Dictionary = MOVES if kind != "passive" else PASSIVES
	if not table.has(id):
		return 0
	var entry: Dictionary = table[id]
	return int(entry.get("rarity", 0))


# Statistiche calcolate di un personaggio del roster.
# entry: {char, level, rank, skills, ult, passives, gear:[{slot, rarity, level}]}
# Kit completo: 4 mosse equipaggiate + ultimate (non nel PvP bilanciato).
static func full_kit(entry: Dictionary) -> bool:
	if bool(entry.get("flat_rarity", false)) or str(entry.get("ult", "")) == "":
		return false
	var cid: String = str(entry.get("char", ""))
	return BattleState.kit_of(entry.get("skills", []), Signatures.skills_for(cid, int(entry.get("rank", 0)))).size() >= BattleTypes.SKILL_SLOTS
```
