class_name ImpactOverlay
extends Control

# Overlay 2D procedurale degli impact frames (nessun asset, nessuno shader: compatibile col renderer Compatibility).
# Si disegna in _draw, avanza col tempo REALE (non dipende da Engine.time_scale) e si elimina da solo.
# Usa i colori ODISPEL: corallo (impatto/pericolo), magenta (forza Odica), ciano (solo contrasto), bianco e nero (frame drammatico).

const CORAL: Color = Color("#FF667A")
const CYAN: Color = Color("#55D8F5")

var level: int = 1
var at: Vector2 = Vector2(640.0, 300.0)
var len_s: float = 0.3
var lite: bool = false
var seed_value: int = 1
var _t: float = 0.0
var _wedges: Array = []        # [a0, a1] in radianti
var _cracks: Array = []        # polilinee
var _gaps: Array = []


func setup(new_level: int, center: Vector2, rng_seed: int, light: bool) -> ImpactOverlay:
	level = clampi(new_level, 1, 4)
	at = center
	seed_value = rng_seed
	lite = light
	len_s = float(ImpactFrames.OVERLAY_LEN[level]) * (0.85 if light else 1.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	return self


func _build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# raggi del "manga": spicchi alternati con ampiezze irregolari
	var n: int = (10 if lite else 18) + level * (2 if lite else 4)
	var a: float = rng.randf() * TAU
	for i in n:
		var w: float = rng.randf_range(0.05, 0.16)
		_wedges.append([a, a + w])
		a += w + rng.randf_range(0.07, 0.22)
	# fratture: polilinee a zig-zag che partono dal punto d'impatto
	var count: int = 0
	match level:
		2:
			count = 3
		3:
			count = 4
		4:
			count = 6
	for i in count:
		var ang: float = rng.randf() * TAU
		var pts: Array = [Vector2.ZERO]
		var p := Vector2.ZERO
		var segs: int = 5 + level
		for s in segs:
			ang += rng.randf_range(-0.55, 0.55)
			p += Vector2(cos(ang), sin(ang)) * rng.randf_range(40.0, 78.0)
			pts.append(p)
		_cracks.append(pts)
	for i in 4:
		_gaps.append(rng.randf_range(0.0, TAU))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)   # coordinate locali = quelle del livello effetti


func _process(delta: float) -> void:
	_t += delta / maxf(0.05, len_s)
	if _t >= 1.0:
		queue_free()
		return
	queue_redraw()


func _wedge_poly(r: float, w0: float, w1: float) -> PackedVector2Array:
	return PackedVector2Array([at, at + Vector2(cos(w0), sin(w0)) * r, at + Vector2(cos(w1), sin(w1)) * r])


func _draw() -> void:
	var fl: float = clampf(Settings.flash, 0.0, 1.0)         # 0 = niente luci improvvise
	var soft: float = lerpf(0.45, 1.0, fl)                  # elementi non lampeggianti: mai del tutto spenti
	var k: float = _t
	var inv: float = 1.0 - k
	var vp: Vector2 = get_viewport_rect().size
	var big: float = maxf(vp.x, vp.y) * 1.6
	match level:
		1:
			# critico pesante: lampo secco (2 frame circa) + piccolo burst corallo, mai a schermo pieno a lungo
			var fa: float = (inv * inv) * 0.34 * fl * (1.0 if k < 0.5 else 0.5)
			draw_rect(Rect2(-4000, -4000, 8000, 8000), Color(1.0, 0.9, 0.9, fa))
			for i in 12:
				var ang: float = TAU * float(i) / 12.0 + float(seed_value % 7)
				var r0: float = 26.0 + 90.0 * k
				var r1: float = r0 + 34.0 + 40.0 * inv
				draw_line(at + Vector2(cos(ang), sin(ang)) * r0, at + Vector2(cos(ang), sin(ang)) * r1, Color(CORAL, 0.95 * inv), 5.0, true)
			draw_arc(at, 30.0 + 70.0 * k, 0.0, TAU, 28, Color(1, 1, 1, 0.8 * inv), 4.0, true)
		2:
			# danno eccezionale: contrasto alto, raggi bianchi su velo scuro, fratture corallo, flash bianco poi rosso
			var dim: float = 0.42 * (inv if k > 0.25 else 1.0)
			draw_rect(Rect2(-4000, -4000, 8000, 8000), Color(0.02, 0.0, 0.03, dim * soft))
			var wa: float = 0.38 * (inv if k > 0.2 else 1.0) * soft
			for w in _wedges:
				draw_colored_polygon(_wedge_poly(big, w[0], w[1]), Color(1, 1, 1, wa))
			var flc: Color = Color(1, 1, 1, 0.5) if k < 0.2 else Color(CORAL, 0.28)
			draw_rect(Rect2(-4000, -4000, 8000, 8000), Color(flc.r, flc.g, flc.b, flc.a * fl * inv))
			_draw_cracks(CORAL, 5.0, inv, 1.0 + 1.4 * k)
		3:
			# ultimate + critico: enfasi sul colpo decisivo, geometrie rituali (anello spezzato magenta), tagli diagonali
			var dim3: float = 0.55 * (inv if k > 0.3 else 1.0)
			draw_rect(Rect2(-4000, -4000, 8000, 8000), Color(0.02, 0.0, 0.05, dim3 * soft))
			var wa3: float = 0.32 * (inv if k > 0.25 else 1.0) * soft
			for w in _wedges:
				draw_colored_polygon(_wedge_poly(big, w[0], w[1]), Color(1, 1, 1, wa3))
			_draw_ring(MAGENTA(), 70.0 + 190.0 * k, 9.0 * inv + 2.0, 0.95 * inv)
			if not lite:
				_draw_ring(CYAN, 52.0 + 120.0 * k, 3.0, 0.7 * inv)
			for s in 2:
				var d: Vector2 = Vector2(1.0, -0.55 if s == 0 else 0.4).normalized()
				draw_line(at - d * 1400.0 * k, at + d * 1400.0 * k, Color(1, 1, 1, 0.9 * inv), 6.0 * inv + 1.0, true)
			_draw_cracks(MAGENTA(), 5.0, inv, 1.0 + k)
			draw_rect(Rect2(-4000, -4000, 8000, 8000), Color(1, 1, 1, (0.4 if k < 0.12 else 0.0) * fl))
		4:
			# ultimate + danno eccezionale: raro. Frame quasi monocromatico, frattura rituale, accento magenta/corallo, bordo ciano
			var mono: float = 0.9 if k < 0.3 else 0.9 * clampf(1.0 - (k - 0.3) / 0.45, 0.0, 1.0)
			draw_rect(Rect2(-4000, -4000, 8000, 8000), Color(0.0, 0.0, 0.0, mono * soft))
			var wa4: float = (0.75 if k < 0.3 else 0.75 * clampf(1.0 - (k - 0.3) / 0.5, 0.0, 1.0)) * soft
			for w in _wedges:
				draw_colored_polygon(_wedge_poly(big, w[0], w[1]), Color(1, 1, 1, wa4))
			_draw_ring(MAGENTA(), 60.0 + 280.0 * k, 12.0 * inv + 2.0, 1.0 * (inv if k > 0.5 else 1.0))
			_draw_ring(CORAL, 36.0 + 160.0 * k, 6.0 * inv + 1.0, 0.95 * inv)
			if not lite:
				_draw_ring(CYAN, 92.0 + 330.0 * k, 3.0, 0.8 * inv)
			_draw_cracks(CORAL, 7.0, inv if k > 0.4 else 1.0, 1.0 + 2.2 * k)
			_draw_cracks(MAGENTA(), 3.0, inv, 1.0 + 2.6 * k)
			if k < 0.1:
				draw_rect(Rect2(-4000, -4000, 8000, 8000), Color(1, 1, 1, 0.5 * fl))
			if not lite:
				var e: float = 14.0 * inv
				draw_rect(Rect2(-4000, -4000, 8000, 8000), Color(CYAN, 0.0))
				draw_rect(Rect2(0.0, 0.0, vp.x, e), Color(CYAN, 0.55 * inv))
				draw_rect(Rect2(0.0, vp.y - e, vp.x, e), Color(CYAN, 0.55 * inv))


static func MAGENTA() -> Color:
	return BattleTheme.MAGENTA


func _draw_cracks(col: Color, width: float, alpha: float, grow: float) -> void:
	for c in _cracks:
		var pts := PackedVector2Array()
		for p in c:
			pts.append(at + (p as Vector2) * grow)
		draw_polyline(pts, Color(col, clampf(alpha, 0.0, 1.0)), width * clampf(alpha, 0.3, 1.0), true)


# Anello rituale con 4 interruzioni (stesso linguaggio dell'icona "sigillo").
func _draw_ring(col: Color, radius: float, width: float, alpha: float) -> void:
	if alpha <= 0.01:
		return
	for i in 4:
		var a0: float = float(i) * TAU / 4.0 + float(_gaps[0]) * 0.2 + 0.18
		draw_arc(at, radius, a0, a0 + TAU / 4.0 - 0.42, 14, Color(col, clampf(alpha, 0.0, 1.0)), width, true)
