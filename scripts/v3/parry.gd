class_name Parry
extends RefCounted

# Finestre della guardia a tempo in millisecondi veri, misurate con l'orologio di sistema:
# a 30, 60, 120 o 240 fps la parata e' identica (prima il tempo avanzava a fotogrammi).
const LEAD_MS: float = 900.0       # dall'apparire del cerchio all'impatto
const GOOD_MS: float = 300.0       # quanto prima dell'impatto vale gia' come guardia
const LATE_MS: float = 120.0       # tolleranza dopo l'impatto
const PERFECT_MS: float = 80.0     # +- attorno all'impatto per la parata perfetta
const WIDE_GOOD: float = 1.5       # "Finestra di parata: AMPIA" (impostazioni): piu' margine, stessa guardia normale
const WIDE_PERFECT: float = 1.5
const LANCE_GOOD: float = 1.5      # Al secondo (Lance): finestre piu' larghe sui colpi che prende lui
const LANCE_PERFECT: float = 1.6


# Le finestre di questo colpo. wide = impostazione del giocatore, lance = il colpo finisce su Lance.
static func windows(wide: bool, lance: bool) -> Dictionary:
	var good: float = GOOD_MS
	var perfect: float = PERFECT_MS
	var late: float = LATE_MS
	if wide:
		good *= WIDE_GOOD
		perfect *= WIDE_PERFECT
		late *= WIDE_GOOD
	if lance:
		good *= LANCE_GOOD
		perfect *= LANCE_PERFECT
	return {"good": good, "perfect": perfect, "late": late}


# d_ms = tocco meno impatto (negativo = in anticipo). Ritorna perfect, good o early.
static func grade(d_ms: float, w: Dictionary) -> String:
	if absf(d_ms) <= float(w["perfect"]):
		return "perfect"
	if d_ms >= -float(w["good"]) and d_ms <= float(w["late"]):
		return "good"
	return "early"
