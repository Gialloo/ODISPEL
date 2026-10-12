class_name TouchUi
extends RefCounted

# Modalita' touch (telefono/tablet). Su schermo 1280x720 scalato su un telefono,
# 1 punto del gioco vale circa mezzo "dp": un bottone alto 44 e' largo meno di
# 23dp, troppo piccolo per un dito. In modalita' touch ogni bottone stilizzato da
# BattleTheme viene portato ad altezza comoda; sul PC non cambia nulla.

const MIN_HEIGHT: float = 64.0       # ~33dp: comodo anche nelle schermate fitte
const COMFY_HEIGHT: float = 88.0     # ~45dp: per le azioni principali (ordini in battaglia)
const MIN_FONT: int = 20

static var force: bool = false       # prova su PC / test


static func active() -> bool:
	return force or OS.has_feature("mobile")


# Adatta un bottone: altezza e testo minimi. Idempotente.
static func fit(b: Button, size: int) -> int:
	if not active():
		return size
	b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, MIN_HEIGHT)
	return maxi(size, MIN_FONT)
