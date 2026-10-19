class_name ActionTheme
extends RefCounted

# Palette e caratteri di ODISPEL, ripresi dal gioco originale
# (scripts/ui/battle_theme.gd): notte urbana, dominante ciano, accenti rossi
# aggressivi, bianco e nero. Ogni colore di potere resta riconoscibile.

const CY: Color = Color("#7cf0ff")        # ciano principale
const CY_DIM: Color = Color("#2a8a9a")
const CY_DARK: Color = Color("#0f3a44")
const RD: Color = Color("#ff2d55")        # rosso aggressivo
const RD_DARK: Color = Color("#5a1022")
const WH: Color = Color("#f2fdff")
const BK: Color = Color("#04080a")
const PANEL: Color = Color("#061418")

const POWER_COLORS: Dictionary = {
	"rosso": Color("#ff4d6d"),
	"verde": Color("#6bffb0"),
	"blu": Color("#5aa8ff"),
	"giallo": Color("#ffd25f"),
	"viola": Color("#b07bff"),
}

static var _mono: Font = null
static var _display: Font = null


# Carattere a spaziatura fissa (numeri, testi tecnici).
static func mono() -> Font:
	if _mono == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Consolas", "Courier New", "DejaVu Sans Mono", "monospace"])
		f.font_weight = 700
		_mono = f
	return _mono


# Carattere "da insegna": pesante e inclinato (pulsanti, titoli).
static func display() -> Font:
	if _display == null:
		var base := SystemFont.new()
		base.font_names = PackedStringArray(["Impact", "Arial Black", "DejaVu Sans Bold", "sans-serif"])
		base.font_weight = 900
		var fv := FontVariation.new()
		fv.base_font = base
		fv.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-0.22, 1.0), Vector2.ZERO)
		_display = fv
	return _display


static func flat_material(color: Color, roughness: float = 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


static func glow_material(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m
