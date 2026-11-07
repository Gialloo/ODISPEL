class_name HudIcons
extends RefCounted

# ICONE DELL'HUD DISEGNATE DALL'AUTORE (HUD 0.61, P1-C, 7/11/2026).
# L'autore disegna le icone in Procreate (guida: docs/HUD_ICONE_PROCREATE.md) e le mette in res://assets/hud_icons/<nome>.png:
# PNG 256x256, bianche su trasparente. Il gioco le colora da solo (modulate): bianco x colore = il colore dell'HUD.
# Finche' un file non c'e', resta l'icona disegnata in codice (CmdWheel.glyph, ThreatPlate.draw_icon, _notice_icon): niente si rompe.
# Area utile: il cerchio di 208 px al centro (24 px di margine per lato) corrisponde al diametro dell'icona di prima.

const DIR: String = "res://assets/hud_icons/"
const CANVAS: float = 256.0
const USEFUL: float = 208.0
# nomi riconosciuti (un file per nome); a sinistra il nome nel codice, a destra il file
const NAMES: Dictionary = {
	"attack": "attacco", "skill": "abilita", "ult": "ultimate", "guard": "guardia",
	"singolo": "minaccia_singolo", "tutti": "minaccia_tutti", "catena": "minaccia_catena", "stato": "stato", "stordito": "stordito",
	"boss": "avviso_pericolo", "fx": "avviso_tattica", "env": "avviso_ambiente", "chain": "avviso_catena", "move": "avviso_mossa",
}

static var _cache: Dictionary = {}


# La texture dell'icona `kind`, o null se l'autore non l'ha ancora disegnata.
static func tex(kind: String) -> Texture2D:
	if _cache.has(kind):
		return _cache[kind]
	var t: Texture2D = null
	var path: String = DIR + str(NAMES.get(kind, kind)) + ".png"
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	_cache[kind] = t
	return t


# Disegna l'icona dell'autore, se c'e', centrata in c: r e' il raggio dell'icona disegnata in codice che sostituisce.
# Ritorna false se il file non c'e' (allora chi chiama disegna la sua).
static func draw(ci: CanvasItem, kind: String, c: Vector2, r: float, col: Color) -> bool:
	var t: Texture2D = tex(kind)
	if t == null:
		return false
	var side: float = 2.0 * r * CANVAS / USEFUL
	ci.draw_texture_rect(t, Rect2(c - Vector2(side, side) * 0.5, Vector2(side, side)), false, col)
	return true
