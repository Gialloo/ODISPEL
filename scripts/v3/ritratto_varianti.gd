class_name RitrattoVarianti
extends RefCounted

# VARIANTI DEL RITRATTO 2D (disegni dell'autore, 3/11/2026: dieci versioni di Rio, ognuna con il suo momento).
# Un file per momento in res://assets/portraits/hud/<id>_<stato>.png; se manca si usa il ritratto normale <id>_hud.png,
# quindi gli altri personaggi funzionano gia' e prenderanno le varianti appena ci sono i disegni (nessun codice da toccare).
#   hud      ritratto normale dell'HUD (grigio con i riflessi rosso-arancio)
#   ombra    ULTIMATE e SKILL scelte: diventa un'ombra, resta acceso solo lo sguardo magenta
#   ferito   PV sotto il 50%: viola e rosso, il ritratto si scurisce
#   critico  PV sotto il 25%: ancora piu' scuro
#   break    il suo colpo rompe la guardia: fotogramma disturbato rosso e blu, come una VHS
#   ko       K.O. «SEGNALE PERSO»: la telecamera si spegne e resta la sagoma blu
#   pausa    menu di pausa: figura scura e calma sul lato dello schermo
#   ng       New Game+ (la Replica della diretta): la skin magenta
#   ricordo  schermata di caricamento: chiaro e olografico, come un ricordo sbiadito
# Le varianti sono 768x1024 (un quarto del peso: sul telefono il ritratto e' alto ~705 px), si caricano solo quando servono.

const DIR: String = "res://assets/portraits/hud/"
# Varianti SPENTE (autore, 3/11/2026, dopo la prova della 0.44.0: «utilizza solo questo Rio e solo per HUD»).
# Resta solo il ritratto normale <id>_hud.png nell'HUD di battaglia; i file delle varianti restano nel progetto per piu'
# avanti: rimettere true le riaccende tutte (ombra, vita bassa, break, K.O., pausa, NG+, caricamento, cut-in).
static var attive: bool = false
const FERITO: float = 0.5
const CRITICO: float = 0.25

static var _cache: Dictionary = {}


static func path(id: String, stato: String) -> String:
	if not attive and stato != "hud":
		return ""
	var p: String = DIR + "%s_%s.png" % [id, stato]
	return p if ResourceLoader.exists(p) else ""


static func has(id: String, stato: String) -> bool:
	return path(id, stato) != ""


# Texture della variante, o null se il disegno non c'e'.
static func tex(id: String, stato: String) -> Texture2D:
	var k: String = id + "_" + stato
	if not _cache.has(k):
		var p: String = path(id, stato)
		_cache[k] = load(p) if p != "" else null
	return _cache[k]


# Stato per la vita: "" (normale), "ferito" o "critico". A 0 PV e' "ko".
static func per_vita(hp: int, max_hp: int) -> String:
	if hp <= 0:
		return "ko"
	var r: float = float(hp) / maxf(1.0, float(max_hp))
	if r <= CRITICO:
		return "critico"
	if r <= FERITO:
		return "ferito"
	return ""


# Ritratto di base: nella Replica (NG+) la skin magenta, se c'e'.
static func base(id: String) -> String:
	if attive and Story.replica() > 0 and has(id, "ng"):
		return "ng"
	return "hud"
