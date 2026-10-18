class_name CastVisual
extends RefCounted

# Aspetto dei segnaposto 3D (PROVVISORIO: in attesa dei modelli veri).
# Colori e proporzioni stanno qui, separati dalla logica: si possono ritoccare senza toccare il codice.
# height: altezza in metri. Colori in esadecimale. fem: corporatura femminile. eyes: colore degli occhi.
# brow: sopracciglia (+ arrabbiate, - stanche). lid: palpebre calate 0..1. smirk: mezzo sorriso 0..1.

# kit = abbigliamento moderno (stile URBANO di oggi, decisione dell'autore): tattico, notturna, streamer, corriere.
# accent = dettagli (profili, lacci, fodera); il colore di battaglia resta quello del motore (rosso, blu, viola, verde).
# metal = parti metalliche (shader toon a bande, alpha 0.4) · gold = anelli e fibbie.
const CAST: Dictionary = {
	"ferri": {
		"name": "Ferri", "faction": "LibraCorp", "height": 1.80, "build": 1.08, "kit": "tattico",
		"skin": "#e9b996", "hair": "#1d1a22", "top": "#25324f", "bottom": "#1b2236", "accent": "#e8343f", "shoes": "#14121a",
		"metal": "#aab0c0", "gold": "#d9b44a", "glove": "#18161e",
		"hair_style": "crew", "extra": "cap", "eyes": "#6b3a2e", "brow": 1.0, "lid": 0.15, "smirk": 0.0,
	},
	"nox": {
		"name": "Nox", "faction": "Civette", "height": 1.70, "build": 0.95, "kit": "notturna",
		"skin": "#f0c9ac", "hair": "#2a2c56", "top": "#3a3770", "bottom": "#24224a", "accent": "#39b7ff", "shoes": "#191629",
		"metal": "#aeb4c4", "gold": "#d9b44a", "glove": "#2a2734",
		"hair_style": "owl", "extra": "coat", "fem": true, "eyes": "#3f6dff", "brow": -0.6, "lid": 0.45, "smirk": 0.0,
	},
	"zecca": {
		"name": "Zecca", "faction": "Masca", "height": 1.66, "build": 0.9, "kit": "streamer",
		"skin": "#d79f7c", "hair": "#f0e6ff", "top": "#8e3df0", "bottom": "#2a2140", "accent": "#ffd23f", "shoes": "#f2f2f2",
		"metal": "#b8bccb", "gold": "#e0b54a", "glove": "#f2f0f6",
		"hair_style": "spiky", "extra": "mask", "eyes": "#b45cff", "brow": 0.2, "lid": 0.0, "smirk": 1.0,
	},
	"saul": {
		"name": "Saul", "faction": "Magabondi", "height": 1.78, "build": 0.98, "kit": "corriere",
		"skin": "#c98f6b", "hair": "#4a2b1c", "top": "#2f8f5a", "bottom": "#3d3a33", "accent": "#ff8a2b", "shoes": "#2a1d17",
		"metal": "#b5b9c4", "gold": "#d9b44a", "glove": "#5a3b26",
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
