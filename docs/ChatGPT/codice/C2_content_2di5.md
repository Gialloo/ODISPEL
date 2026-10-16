FILE battle_content.gd - PARTE 2 DI 5
Percorso: scripts/battle/battle_content.gd
(Codice GDScript, rientri con tab. Non rispondere finche' non scrivo FINE FILE.)

```gdscript
# rarity: indice in BattleTypes.RARITIES (quanto e' raro da reclutare)
const CHARACTERS: Dictionary = {
	"kira": {"name": "Kira", "color": "viola", "cls": "striker", "rarity": 3, "skill": "colpo_caricato", "ult": "spezzatutto", "passive": "p_atk", "faction": "rondini",
		"role": "Mascotte e volto del gioco", "stat_mult": {"hp": 1.0, "atk": 1.0}},
	"dax": {"name": "Dax", "color": "rosso", "cls": "vanguard", "rarity": 0, "skill": "provoca", "ult": "bastione", "passive": "p_hp", "faction": "libracorp", "stat_mult": {"hp": 1.15, "atk": 1.2}},
	"elle": {"name": "Elle", "color": "verde", "cls": "warden", "rarity": 0, "skill": "cura", "ult": "rinascita", "passive": "p_swap", "faction": "magabondi", "stat_mult": {"hp": 1.15, "atk": 1.2}},
	"bruno": {"name": "Bruno", "color": "blu", "cls": "vanguard", "rarity": 0, "skill": "barriera", "ult": "bastione", "passive": "p_hp", "faction": "libracorp", "stat_mult": {"hp": 1.15, "atk": 1.2, "def": 1.05}},
	"nova": {"name": "Nova", "color": "giallo", "cls": "striker", "rarity": 1, "skill": "marchio", "ult": "spezzatutto", "passive": "p_hunter", "faction": "rondini"},
	"mira": {"name": "Mira", "color": "blu", "cls": "warden", "rarity": 1, "skill": "purifica", "ult": "rinascita", "passive": "p_swap", "faction": "libracorp", "stat_mult": {"hp": 1.35, "atk": 1.4}},
	"rex": {"name": "Rex", "color": "rosso", "cls": "striker", "rarity": 0, "skill": "colpo_caricato", "ult": "spezzatutto", "passive": "p_atk", "faction": "rondini", "stat_mult": {"atk": 0.95}},
	"ivo": {"name": "Ivo", "color": "blu", "cls": "striker", "rarity": 1, "skill": "marchio", "ult": "spezzatutto", "passive": "p_swap", "faction": "magabondi", "style": "atipico"},
	"sera": {"name": "Sera", "color": "verde", "cls": "warden", "rarity": 2, "skill": "barriera", "ult": "rinascita", "passive": "p_hunter", "faction": "rondini", "stat_mult": {"hp": 1.25, "atk": 1.35}},
	"eco": {"name": "Eco", "color": "giallo", "cls": "striker", "rarity": 2, "skill": "marchio", "ult": "spezzatutto", "passive": "p_atk", "faction": "kairos", "stat_mult": {"atk": 0.94}},
	"tana": {"name": "Tana", "color": "giallo", "cls": "vanguard", "rarity": 3, "skill": "provoca", "ult": "bastione", "passive": "p_hunter", "faction": "libracorp", "stat_mult": {"hp": 1.3, "atk": 1.35}},
	# Agent 02: tiratore scelto. Angela: mecamante, glass cannon con 12 munizioni.
	# Nico: l'amico di Kira, ricomparso nello Specchio. Solo storia: non esce dai reclutamenti.
	"nico": {"name": "Nico", "color": "rosso", "cls": "vanguard", "rarity": 2, "skill": "intimidisci", "ult": "bastione", "passive": "p_swap", "faction": "kairos",
		"role": "Custode del rifugio", "story_only": true},
	"dafne": {"name": "Dafne", "color": "giallo", "arch": "dex", "cls": "striker", "rarity": 3, "skill": "u_dafne_a", "ult": "coordinated_shot", "passive": "p_atk", "faction": "libracorp",
		"role": "Tiratore scelto", "ammo_max": 6, "stat_mult": {"hp": 0.85, "atk": 0.98}},
	"angela": {"name": "Angela", "color": "giallo", "cls": "striker", "rarity": 3, "skill": "u_angela_a", "ult": "orbital_strike", "passive": "p_atk", "faction": "libracorp",
		"role": "Mecamante", "ammo_max": 12, "stat_mult": {"hp": 0.75, "atk": 1.12, "def": 0.8}},
	# Roster 2: dieci operatori nuovi (3 Magabondi, 3 Kairos, 2 Rondini, 2 LibraCorp).
	"moro": {"name": "Moro", "color": "rosso", "cls": "vanguard", "rarity": 1, "skill": "provoca", "ult": "u_moro_ult", "passive": "p_hp", "faction": "magabondi",
		"role": "Difensore resistente", "stat_mult": {"hp": 1.15, "atk": 1.25, "def": 1.1}},
	"vesper": {"name": "Vesper", "color": "viola", "cls": "striker", "rarity": 2, "skill": "marchio", "ult": "u_vesper_ult", "passive": "p_atk", "faction": "magabondi",
		"role": "Cacciatore di marchiati", "stat_mult": {"hp": 1.0, "atk": 1.08}},
	"nami": {"name": "Nami", "color": "verde", "cls": "warden", "rarity": 0, "skill": "barriera", "ult": "u_nami_ult", "passive": "p_hp", "faction": "magabondi",
		"role": "Custode dei piccoli rituali", "stat_mult": {"hp": 1.6, "atk": 1.95}},
	"oriel": {"name": "Oriel", "color": "blu", "cls": "warden", "rarity": 3, "skill": "cura", "ult": "u_oriel_ult", "passive": "p_swap", "faction": "kairos",
		"role": "Custode della soglia", "stat_mult": {"hp": 1.35, "atk": 1.45}},
	"silex": {"name": "Silex", "color": "viola", "cls": "vanguard", "rarity": 1, "skill": "provoca", "ult": "u_silex_ult", "passive": "p_hp", "faction": "kairos",
		"role": "Il muro che avanza", "stat_mult": {"hp": 1.12, "atk": 1.15}},
	"yuna": {"name": "Yuna", "color": "blu", "cls": "striker", "rarity": 2, "skill": "colpo_caricato", "ult": "u_yuna_ult", "passive": "p_atk", "faction": "kairos",
		"role": "Attaccante rapido"},
	"rhea": {"name": "Rhea", "color": "verde", "cls": "warden", "rarity": 1, "skill": "purifica", "ult": "u_rhea_ult", "passive": "p_swap", "faction": "rondini",
		"role": "Specialista del contenimento", "stat_mult": {"hp": 1.25, "atk": 1.3}},
	"flux": {"name": "Flux", "color": "blu", "cls": "striker", "rarity": 3, "skill": "colpo_caricato", "ult": "u_flux_ult", "passive": "p_atk", "faction": "rondini",
		"role": "Picco di potenza", "stat_mult": {"hp": 0.9, "atk": 0.95}},
	"cato": {"name": "Cato", "color": "viola", "cls": "vanguard", "rarity": 0, "skill": "barriera", "ult": "u_cato_ult", "passive": "p_hp", "faction": "libracorp",
		"role": "Operatore standard", "stat_mult": {"hp": 1.2, "atk": 1.5, "def": 1.15}},
	"lyra": {"name": "Lyra", "color": "viola", "cls": "striker", "rarity": 3, "skill": "marchio", "ult": "u_lyra_ult", "passive": "p_atk", "faction": "libracorp",
		"role": "Stratega del bersaglio", "stat_mult": {"hp": 0.92, "atk": 0.95}},
}

# Fazione e stile di un operatore (campi opzionali "faction" e "style" in CHARACTERS; l'entry del roster puo' avere
# gli stessi campi e ha la precedenza). Senza fazione: "" e niente aure.
static func faction_of(char_id: String, entry: Dictionary = {}) -> String:
	var def: Dictionary = CHARACTERS.get(char_id, {})
	return str(entry.get("faction", def.get("faction", "")))


static func style_of(char_id: String, entry: Dictionary = {}) -> String:
	var def: Dictionary = CHARACTERS.get(char_id, {})
	return str(entry.get("style", def.get("style", "ortodosso")))


# Equipaggiamento: valore base per slot, moltiplicato da rarita' e livello.
const GEAR_BASE: Dictionary = {
	"arma": {"atk": 12},
	"petto": {"hp": 140, "def": 6},
	"stivali": {"spd": 8},
}
const GEAR_RARITY_MULT: Array = [1.0, 1.3, 1.7, 2.2]
const GEAR_LEVEL_BONUS: float = 0.10
# Livello massimo di un pezzo, per rarita'.
const GEAR_MAX_LEVEL: Array = [10, 15, 20, 30]

# Materiali per potenziare: Nucleo (personaggi), Lega (pezzi).
const MATERIALS: Dictionary = {"nucleo": "Nucleo", "lega": "Lega"}
```
