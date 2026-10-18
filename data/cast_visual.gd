class_name CastVisual
extends RefCounted

# Aspetto dei segnaposto 3D (PROVVISORIO: in attesa dei modelli veri).
# Colori e proporzioni stanno qui, separati dalla logica: si possono ritoccare senza toccare il codice.
# height: altezza in metri. Colori in esadecimale. fem: corporatura femminile. eyes: colore degli occhi.
# brow: sopracciglia (+ arrabbiate, - stanche). lid: palpebre calate 0..1. smirk: mezzo sorriso 0..1.

# kit = classe RPG del personaggio (docs/STILE_VISIVO.md): cavaliere, guardiana, giullare, ladro.
# Colori: base spenta (nero, argento, grigio, viola, oliva, marrone) + un solo accento saturo = colore di battaglia.
# metal = argento a bande (shader toon, alpha 0.4) · gold = borchie e spuntoni dorati.
const CAST: Dictionary = {
	"ferri": {
		"name": "Ferri", "faction": "LibraCorp", "height": 1.80, "build": 1.0, "kit": "cavaliere",
		"skin": "#efc9a6", "hair": "#8fd06a", "top": "#2a3560", "bottom": "#c4cad6", "accent": "#e8343f", "shoes": "#c4cad6",
		"metal": "#c4cad6", "gold": "#e0b54a", "glove": "#d9b27a", "wrap": "#e9e1cd",
		"hair_style": "knight", "extra": "cap", "eyes": "#a2452f", "brow": 1.0, "lid": 0.1, "smirk": 0.0,
	},
	"nox": {
		"name": "Nox", "faction": "Civette", "height": 1.70, "build": 0.95, "kit": "guardiana",
		"skin": "#f0c9ac", "hair": "#2a2c56", "top": "#3b3850", "bottom": "#24222f", "accent": "#39b7ff", "shoes": "#1e1b28",
		"metal": "#aeb4c4", "gold": "#d9b44a", "glove": "#2a2734", "wrap": "#cfd3e0",
		"hair_style": "owl", "extra": "coat", "fem": true, "eyes": "#3f6dff", "brow": -0.6, "lid": 0.45, "smirk": 0.0,
	},
	"zecca": {
		"name": "Zecca", "faction": "Masca", "height": 1.66, "build": 0.9, "kit": "giullare",
		"skin": "#d79f7c", "hair": "#f0e6ff", "top": "#2e2838", "bottom": "#1d1a24", "accent": "#8e3df0", "shoes": "#f2f0f6",
		"metal": "#b8bccb", "gold": "#e0b54a", "glove": "#f2f0f6", "wrap": "#d9d6e0",
		"hair_style": "spiky", "extra": "mask", "eyes": "#b45cff", "brow": 0.2, "lid": 0.0, "smirk": 1.0,
	},
	"saul": {
		"name": "Saul", "faction": "Magabondi", "height": 1.78, "build": 0.98, "kit": "ladro",
		"skin": "#c98f6b", "hair": "#4a2b1c", "top": "#4b5536", "bottom": "#353b4a", "accent": "#2f8f5a", "shoes": "#4a3326",
		"metal": "#b5b9c4", "gold": "#d9b44a", "glove": "#5a3b26", "wrap": "#d8cdb5",
		"hair_style": "long", "extra": "bag", "eyes": "#c98a2a", "brow": 0.0, "lid": 0.25, "smirk": 1.0,
	},
}

const ORDER: Array = ["ferri", "nox", "zecca", "saul"]


static func spec(id: String) -> Dictionary:
	return CAST.get(id, CAST["saul"])


static func col(id: String, key: String) -> Color:
	return Color(str(spec(id)[key]))


# Espressioni dei portrait (dialoghi stile Persona). Valori che si sovrappongono alla scheda del personaggio.
# I nomi sono quelli dei file: assets/portraits/<personaggio>_<espressione>.png
const EXPRESSIONS: Dictionary = {
	"neutro": {},
	"felice": {"mouth": "smile", "brow": -0.2, "lid": 0.05, "smirk": 0.0},
	"arrabbiato": {"mouth": "teeth", "brow": 1.8, "lid": 0.25},
	"triste": {"mouth": "frown", "brow": -1.4, "lid": 0.35, "tear": true},
	"sorpreso": {"mouth": "open", "wide": true, "brow": -0.4, "brow_up": 0.008, "lid": 0.0},
	"sfotto": {"mouth": "", "smirk": 1.6, "brow": 0.4, "lid": 0.35},
	"serio": {"mouth": "", "smirk": 0.0, "brow": 1.0, "lid": 0.2},
}
const EXPR_ORDER: Array = ["neutro", "felice", "arrabbiato", "triste", "sorpreso", "sfotto", "serio"]


# Valori finali per un'espressione: Nox resta stanca (palpebre calate) tranne quando si sorprende; Zecca senza maschera.
static func expression(id: String, expr: String) -> Dictionary:
	var o: Dictionary = (EXPRESSIONS.get(expr, {}) as Dictionary).duplicate()
	var base: Dictionary = spec(id)
	if id == "nox" and expr != "sorpreso":
		o["lid"] = minf(0.7, float(o.get("lid", base["lid"])) + 0.25)
	if id == "zecca" and expr != "maschera":
		o["nomask"] = true
	return o
