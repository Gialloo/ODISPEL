class_name Profile
extends RefCounted

# Profilo del giocatore: nome, icona e banner. Si vede nell'hub e nel multiplayer (lobby e chat).
# Sta in un file a parte (user://profile.cfg): "Nuovo gioco" cancella i progressi ma NON il profilo.
#
# Icone: id come "c_sword" (catalogo qui sotto) oppure "char:kira" (il volto di un operatore posseduto).
# Rarita': 0 comune, 1 rara, 2 epica, 3 leggendaria. Le non comuni si ottengono dai boss (premi di fine
# battaglia) e dalle imprese (schermata OBIETTIVI).

const NAME_MAX: int = 16
const DEFAULT_NAME: String = "Giocatore"
const RARITY_NAMES: Array = ["COMUNE", "RARA", "EPICA", "LEGGENDARIA"]
const RARITY_COLORS: Array = [Color("#9fb4c8"), Color("#4fd8ff"), Color("#c07bff"), Color("#ffd25f")]

# {id: [nome, rarita', chiave GameIcon, colore, come ottenerla]}
const ICONS: Dictionary = {
	"c_sword": ["Lama", 0, "sword", "#dfe9f2", "Sempre disponibile"],
	"c_shield": ["Scudo", 0, "shield", "#dfe9f2", "Sempre disponibile"],
	"c_heal": ["Cura", 0, "heal", "#dfe9f2", "Sempre disponibile"],
	"c_target": ["Mirino", 0, "target", "#dfe9f2", "Sempre disponibile"],
	"c_bolt": ["Provocazione", 0, "taunt", "#dfe9f2", "Sempre disponibile"],
	"r_burst": ["Esplosione", 1, "burst", "#ff9a5f", "Premio dei boss / impresa «Primo contatto»"],
	"r_nucleo": ["Nucleo", 1, "nucleo", "#6bffb0", "Premio dei boss"],
	"r_stivali": ["Passo Rapido", 1, "stivali", "#7cf0ff", "Premio dei boss / impresa «Sul campo»"],
	"r_lega": ["Lega", 1, "lega", "#ffd25f", "Premio dei boss"],
	"e_kairos": ["Kairos", 2, "kairos", "#c07bff", "Premio dei boss (raro) / impresa «Veterani»"],
	"e_libracorp": ["Libracorp", 2, "libracorp", "#7cf0ff", "Premio dei boss (raro) / impresa «Reclutatore»"],
	"e_rondini": ["Rondini", 2, "rondini", "#ff6b8a", "Premio dei boss (raro)"],
	"e_magabondi": ["Magabondi", 2, "magabondi", "#6bffb0", "Premio dei boss (raro) / impresa «Collezione»"],
	"l_striker": ["Leggenda: Fulmine", 3, "bolt", "#ffd25f", "Premio dei boss (rarissimo) / impresa «Leggende di strada»"],
	"l_vanguard": ["Leggenda: Baluardo", 3, "vanguard", "#ffd25f", "Premio dei boss (rarissimo) / impresa «Una leggenda in squadra»"],
	"l_warden": ["Leggenda: Custode", 3, "warden", "#ffd25f", "Premio dei boss (rarissimo) / impresa «Incubo della citta'»"],
	"l_duello": ["Leggenda: Duellante", 3, "sword", "#ff9a5f", "SOLO con l'impresa «Campione del PvP» (5 vittorie PvP)"],
}

# Icone esclusive: non cadono come premio dei boss, si prendono solo con la loro impresa.
const EXCLUSIVE_ICONS: Array = ["l_duello"]

# Badge (distintivi) mostrati sulla carta del profilo: {id: [nome, descrizione, colore]}
const BADGES: Dictionary = {
	"duellante": ["Duellante", "Ha vinto 5 sfide PvP", "#ff9a5f"],
}

# Premi fissi delle imprese: id impresa -> id icona.
const FEAT_ICONS: Dictionary = {
	"wins_1": "r_burst",
	"plays_25": "r_stivali",
	"wins_15": "e_kairos",
	"pulls_10": "e_libracorp",
	"owned_7": "e_magabondi",
	"wins_40": "l_striker",
	"legend_1": "l_vanguard",
	"wins_100": "l_warden",
	"pvp_wins_5": "l_duello",
}

# Premi fissi delle imprese: id impresa -> id badge.
const FEAT_BADGES: Dictionary = {
	"pvp_wins_5": "duellante",
}

# Banner: [nome, colore A, colore B]
const BANNERS: Array = [
	["Notte", "#101a2e", "#2b4a7a"],
	["Neon", "#2a0f3a", "#ff3d8b"],
	["Cobalto", "#08203a", "#17a2ff"],
	["Brace", "#2b0d0d", "#ff7a2f"],
	["Smeraldo", "#07261c", "#2fd68a"],
	["Oro", "#2e2208", "#ffd25f"],
	["Ametista", "#1d0f33", "#a56bff"],
	["Cenere", "#15181d", "#7d8a99"],
]

static var path: String = "user://profile.cfg"
static var player_name: String = DEFAULT_NAME
static var icon: String = "c_sword"
static var banner: int = 0
static var unlocked: Array = []        # id delle icone non comuni ottenute
static var badges: Array = []          # id dei badge ottenuti
static var _loaded: bool = false


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	player_name = clean_name(str(cfg.get_value("profile", "name", DEFAULT_NAME)))
	icon = str(cfg.get_value("profile", "icon", icon))
	banner = clampi(int(cfg.get_value("profile", "banner", 0)), 0, BANNERS.size() - 1)
	unlocked = []
	for id in Array(cfg.get_value("profile", "unlocked", [])):
		if ICONS.has(str(id)) and not unlocked.has(str(id)):
			unlocked.append(str(id))
	badges = []
	for id in Array(cfg.get_value("profile", "badges", [])):
		if BADGES.has(str(id)) and not badges.has(str(id)):
			badges.append(str(id))
	if not icon_valid(icon):
		icon = "c_sword"


static func has_badge(id: String) -> bool:
	ensure_loaded()
	return badges.has(id)


static func unlock_badge(id: String) -> bool:
	ensure_loaded()
	if not BADGES.has(id) or badges.has(id):
		return false
	badges.append(id)
	save()
	return true


# Il badge messo in mostra: l'ultimo ottenuto ("" se non ne ha).
static func shown_badge() -> String:
	ensure_loaded()
	return str(badges[badges.size() - 1]) if not badges.is_empty() else ""


static func badge_name(id: String) -> String:
	return str(BADGES.get(id, ["", "", ""])[0])


static func save() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "name", player_name)
	cfg.set_value("profile", "icon", icon)
	cfg.set_value("profile", "banner", banner)
	cfg.set_value("profile", "unlocked", unlocked)
	cfg.set_value("profile", "badges", badges)
	return cfg.save(path) == OK


static func clean_name(raw: String) -> String:
	var s: String = raw.strip_edges().replace("\n", " ").substr(0, NAME_MAX).strip_edges()
	return s if s != "" else DEFAULT_NAME


static func rename_to(raw: String) -> void:
	ensure_loaded()
	player_name = clean_name(raw)


static func icon_valid(id: String) -> bool:
	if id.begins_with("char:"):
		return BattleContent.CHARACTERS.has(id.substr(5))
	return ICONS.has(id)


static func rarity_of(id: String) -> int:
	return int(ICONS[id][1]) if ICONS.has(id) else 0


static func is_unlocked(id: String) -> bool:
	ensure_loaded()
	if id.begins_with("char:"):
		return BattleContent.CHARACTERS.has(id.substr(5))
	if not ICONS.has(id):
		return false
	return rarity_of(id) == 0 or unlocked.has(id)


static func unlock(id: String) -> bool:
	ensure_loaded()
	if not ICONS.has(id) or is_unlocked(id):
		return false
	unlocked.append(id)
	save()
	return true


static func select_icon(id: String) -> bool:
	ensure_loaded()
	if not is_unlocked(id):
		return false
	icon = id
	return true


static func select_banner(index: int) -> void:
	ensure_loaded()
	banner = clampi(index, 0, BANNERS.size() - 1)


static func icon_name(id: String) -> String:
	if id.begins_with("char:"):
		return str(BattleContent.CHARACTERS.get(id.substr(5), {}).get("name", id.substr(5)))
	return str(ICONS[id][0]) if ICONS.has(id) else id


# Dati da mostrare/spedire: {name, icon, banner}
static func current() -> Dictionary:
	ensure_loaded()
	return {"name": player_name, "icon": icon, "banner": banner, "badge": shown_badge()}


# Dati ricevuti dalla rete: ripuliti, mai fidarsi.
static func clean_public(raw: Variant) -> Dictionary:
	var out: Dictionary = {"icon": "c_sword", "banner": 0}
	if raw is Dictionary:
		var id: String = str(raw.get("icon", ""))
		if icon_valid(id):
			out["icon"] = id
		out["banner"] = clampi(int(raw.get("banner", 0)), 0, BANNERS.size() - 1)
		var b: String = str(raw.get("badge", ""))
		out["badge"] = b if BADGES.has(b) else ""
	return out


static func banner_colors(index: int) -> Array:
	var b: Array = BANNERS[clampi(index, 0, BANNERS.size() - 1)]
	return [Color(str(b[1])), Color(str(b[2]))]


# Estrae un'icona nuova a fine battaglia (deterministica con il seed). Ritorna l'id oppure "".
static func roll_icon(rng: RNGState, tier: int) -> String:
	var r: int = rng.random_int(1, 1000)
	var legend: int = 12 + 8 * tier
	var epic: int = 70 + 30 * tier
	var rare: int = 220 + 40 * tier
	var want: int = -1
	if r <= legend:
		want = 3
	elif r <= legend + epic:
		want = 2
	elif r <= legend + epic + rare:
		want = 1
	if want < 0:
		return ""
	var pool: Array = []
	for id in ICONS:
		if rarity_of(str(id)) == want and not EXCLUSIVE_ICONS.has(str(id)):
			pool.append(str(id))
	pool.sort()
	return str(pool[rng.random_int(0, pool.size() - 1)])
