class_name ComboFx
extends RefCounted

# REGIA MODULARE delle combo: pochi effetti riutilizzabili (AnimFx, LightningFx, ComicFx) combinati da un preset.
# Il preset (fx) viene dalla regola della combo; il TIER (0 base, 1 potente, 2 signature) dice quanto e' spettacolare.
# La presentazione non cambia mai il risultato della battaglia: legge solo gli eventi gia' risolti.

# Quanto dura e quanto pesa ogni tier: {shake, flash, speed_lines, slow (scala del tempo, 0 = niente), caption}
const TIERS: Array = [
	{"shake": 5.0, "flash": 0.0, "lines": false, "slow": 0.0, "caption": false},
	{"shake": 10.0, "flash": 0.25, "lines": true, "slow": 0.0, "caption": false},
	{"shake": 18.0, "flash": 0.45, "lines": true, "slow": 0.35, "caption": true},
]


static func tier_def(tier: int) -> Dictionary:
	return TIERS[clampi(tier, 0, TIERS.size() - 1)]


# Disegna l'effetto del preset tra chi ha preparato (from) e chi chiude la combo (to), con bersaglio sul boss (target).
static func play(parent: Node, fx: String, col: Color, from: Vector2, to: Vector2, target: Vector2, tier: int) -> void:
	if not AnimFx.enabled():
		return
	var k: float = 1.0 + 0.3 * float(clampi(tier, 0, 2))
	match fx:
		"aura":
			AnimFx.shield(parent, to, false, col)
			AnimFx.rise(parent, from, col)
		"chain":
			LightningFx.play(parent, from, target, col, 0.3, 0.9)
			AnimFx.sparks(parent, target, col, int(10.0 * k), 220.0)
		"burst":
			AnimFx.shockwave(parent, target, col, 150.0 * k)
			AnimFx.sparks(parent, target, col, int(16.0 * k), 320.0)
		"shatter":
			AnimFx.shards(parent, target, col)
			AnimFx.slash(parent, target, col, k)
		"lock":
			LightningFx.play(parent, from, target, col, 0.25, 0.7)
			AnimFx.shield(parent, from, false, col)
			AnimFx.slash(parent, target, col, k)
		"volley":
			AnimFx.projectile(parent, to + Vector2(60.0, 0.0), target, col, func() -> void: AnimFx.sparks(parent, target, col, int(10.0 * k), 240.0))
			AnimFx.slash(parent, target, col, k)
		_:
			AnimFx.sparks(parent, target, col, int(8.0 * k), 200.0)
