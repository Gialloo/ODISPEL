class_name Archetypes
extends RefCounted

# I cinque COLORI sono le fondamenta di ogni operatore (come in One Piece Treasure Cruise):
#   ROSSO  = STR  forza bruta, colpi che crescono
#   GIALLO = PSY  energia e supporto
#   VIOLA  = INT  analisi: marchi, sanguinamento, critici
#   VERDE  = DEX  precisione: critici potenti che caricano l'ultimate
#   BLU    = QCK  rapidita': agisce prima, ultimate sempre pronta
# Sopra il colore, la CLASSE (striker/vanguard/warden), la FAZIONE e le abilita' uniche
# del personaggio completano la sua strategia. Il vantaggio/svantaggio tra colori
# (la ruota) resta com'era: e' un'altra cosa.

const OF_COLOR: Dictionary = {"rosso": "str", "giallo": "psy", "viola": "int", "verde": "dex", "blu": "qck"}

const MOMENTUM_MAX: int = 5
const MOMENTUM_PCT: float = 0.03        # danno in piu' per ogni colpo messo a segno (STR)
const PSY_POWER: float = 1.20           # cure e scudi (PSY)
const INT_MARK_EXTRA: float = 1.12      # danno in piu' ai bersagli marchiati (INT)
const DEX_CRIT_GAUGE: int = 5           # ultimate per ogni critico (DEX)
const DEX_CRIT_DMG_PM: int = 200        # danno critico in piu' (DEX), per mille
const DEX_SUPPORT_CRIT: float = 1.5     # cure e scudi critici (DEX): moltiplicatore
const QCK_START_GAUGE: int = 25         # ultimate di partenza (QCK)
const QCK_GAUGE_MULT: float = 1.4       # carica dai colpi (QCK)

const DEFS: Dictionary = {
	"str": {"tag": "STR", "name": "FORZA", "color": "rosso",
		"line": "Colpi che crescono",
		"desc": "+10% ATK. SLANCIO: ogni colpo messo a segno da' +3% di danno, fino a 5 colpi.",
		"mods": [{"stat": "atk", "pm": 100}]},
	"psy": {"tag": "PSY", "name": "SINTONIA", "color": "giallo",
		"line": "Energia e supporto",
		"desc": "Cure e scudi +20%. A fine round recupera +1 energia. +6% DIF.",
		"mods": [{"stat": "def", "pm": 60}]},
	"int": {"tag": "INT", "name": "ANALISI", "color": "viola",
		"line": "Marchi, sanguinamento, critici",
		"desc": "+6% critico. MARCHIO e SANGUINAMENTO durano 1 round in piu'; +12% di danno ai bersagli marchiati.",
		"mods": [{"stat": "crit", "pm": 60}]},
	"dex": {"tag": "DEX", "name": "PRECISIONE", "color": "verde",
		"line": "Critici che caricano l'ultimate",
		"desc": "+12% critico e +20% danno critico. Ogni critico carica +10 di ultimate. Anche cure e scudi possono essere critici (x1,5).",
		"mods": [{"stat": "crit", "pm": 120}]},
	"qck": {"tag": "QCK", "name": "SCATTO", "color": "blu",
		"line": "Rapidita' e ultimate sempre pronta",
		"desc": "+12% VEL. Parte con 25 di ultimate e i colpi la caricano +40%.",
		"mods": [{"stat": "spd", "pm": 120}]},
}


static func of_color(color_name: String) -> String:
	return str(OF_COLOR.get(color_name, ""))


# Archetipo di un personaggio: di norma lo da' il colore, ma un personaggio puo' tenere il suo anche cambiando colore
# (campo "arch" nella scheda: Dafne e' gialla ma conserva il kit da tiratrice precisa).
static func of_def(def: Dictionary) -> String:
	var forced: String = str(def.get("arch", ""))
	return forced if DEFS.has(forced) else of_color(str(def.get("color", "")))


static func of_unit(u: Dictionary) -> String:
	return str(u.get("arch", ""))


static func tag_of_color(color_name: String) -> String:
	return str(DEFS.get(of_color(color_name), {}).get("tag", ""))


# Bonus permanenti alle statistiche (per mille), sommati nel refresh delle aure.
static func mods_for(u: Dictionary) -> Array:
	return DEFS.get(of_unit(u), {}).get("mods", [])


# Alla creazione dell'unita'.
static func setup(u: Dictionary) -> void:
	var forced: String = str(u.get("arch_override", ""))
	u["arch"] = forced if DEFS.has(forced) else of_color(str(u.get("color", "")))
	u["momentum"] = 0
	match str(u["arch"]):
		"qck":
			u["gauge"] = maxi(int(u.get("gauge", 0)), QCK_START_GAUGE)
		"dex":
			u["crit_dmg"] = int(u.get("crit_dmg", Factions.CRIT_DMG_PM)) + DEX_CRIT_DMG_PM


# Moltiplicatore di danno dovuto al colore di chi attacca.
static func damage_mult(attacker: Dictionary, defender: Dictionary) -> float:
	var m: float = 1.0
	match of_unit(attacker):
		"str":
			m *= 1.0 + MOMENTUM_PCT * float(int(attacker.get("momentum", 0)))
		"int":
			if defender.get("statuses", {}).has("mark"):
				m *= INT_MARK_EXTRA
	return m


# Dopo un colpo messo a segno da un giocatore.
static func after_hit(attacker: Dictionary, crit: bool) -> void:
	match of_unit(attacker):
		"str":
			attacker["momentum"] = mini(MOMENTUM_MAX, int(attacker.get("momentum", 0)) + 1)
		"dex":
			if crit:
				attacker["gauge"] = mini(BattleTypes.GAUGE_MAX, int(attacker["gauge"]) + DEX_CRIT_GAUGE)


# Carica dell'ultimate quando si colpisce.
static func gauge_on_hit(attacker: Dictionary) -> int:
	if of_unit(attacker) == "qck":
		return int(round(float(BattleTypes.GAUGE_ON_HIT) * QCK_GAUGE_MULT))
	return BattleTypes.GAUGE_ON_HIT


# Cure e scudi critici (DEX): stessa probabilita' del critico d'attacco, deterministica.
static func support_crit_mult(state: Dictionary, actor: Dictionary, target: Dictionary, salt: int) -> float:
	if of_unit(actor) == "dex" and Factions.rolls_crit(state, actor, target, salt + 977):
		return DEX_SUPPORT_CRIT
	return 1.0


# Potenza di cure e scudi.
static func support_mult(actor: Dictionary) -> float:
	return PSY_POWER if of_unit(actor) == "psy" else 1.0


# Giri in piu' per gli stati inflitti.
static func status_extra(actor: Dictionary, status: String) -> int:
	if of_unit(actor) == "int" and (status == "mark" or status == "bleed"):
		return 1
	return 0


# Energia in piu' a fine round.
static func round_energy(u: Dictionary) -> int:
	return 1 if of_unit(u) == "psy" else 0
