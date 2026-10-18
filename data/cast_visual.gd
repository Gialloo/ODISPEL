class_name CastVisual
extends RefCounted

# Aspetto dei segnaposto 3D (PROVVISORIO: in attesa dei modelli veri).
# Colori e proporzioni stanno qui, separati dalla logica: si possono ritoccare senza toccare il codice.
# height: altezza in metri. Colori in esadecimale.

const CAST: Dictionary = {
	"ferri": {
		"name": "Ferri", "faction": "LibraCorp", "height": 1.80, "build": 1.12,
		"skin": "#e9b996", "hair": "#1d1a22", "top": "#25324f", "bottom": "#1b2236", "accent": "#e8343f", "shoes": "#14121a",
		"hair_style": "crew", "extra": "cap",
	},
	"nox": {
		"name": "Nox", "faction": "Civette", "height": 1.70, "build": 0.95,
		"skin": "#f0c9ac", "hair": "#2a2c56", "top": "#3a3770", "bottom": "#24224a", "accent": "#39b7ff", "shoes": "#191629",
		"hair_style": "owl", "extra": "coat",
	},
	"zecca": {
		"name": "Zecca", "faction": "Masca", "height": 1.66, "build": 0.9,
		"skin": "#d79f7c", "hair": "#f0e6ff", "top": "#8e3df0", "bottom": "#2a2140", "accent": "#ffd23f", "shoes": "#f2f2f2",
		"hair_style": "spiky", "extra": "mask",
	},
	"saul": {
		"name": "Saul", "faction": "Magabondi", "height": 1.78, "build": 0.98,
		"skin": "#c98f6b", "hair": "#4a2b1c", "top": "#2f8f5a", "bottom": "#3d3a33", "accent": "#ff8a2b", "shoes": "#2a1d17",
		"hair_style": "long", "extra": "bag",
	},
}

const ORDER: Array = ["ferri", "nox", "zecca", "saul"]


static func spec(id: String) -> Dictionary:
	return CAST.get(id, CAST["saul"])


static func col(id: String, key: String) -> Color:
	return Color(str(spec(id)[key]))
