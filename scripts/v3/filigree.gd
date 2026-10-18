class_name Filigree
extends RefCounted

# Cornici gotiche in filigrana d'argento (docs/STILE_VISIVO.md: «nei ritratti, nei menu e nei momenti forti»).
# Tutto disegnato in 2D (draw_*), niente immagini: volute a spirale, spine, una gemma tonda nell'angolo.
# Ogni tratto ha sotto un contorno d'inchiostro, come il resto del gioco.

const SILVER: Color = Color("#d6dbe6")
const SILVER_DK: Color = Color("#7c8396")


# Spirale (voluta) come lista di punti: parte da p, gira di turns giri stringendosi
static func _volute(p: Vector2, dir: Vector2, r0: float, turns: float, flip: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var a0: float = dir.angle()
	var n: int = int(18.0 * turns) + 2
	for i in n:
		var t: float = float(i) / float(n - 1)
		var a: float = a0 + flip * t * TAU * turns
		var r: float = r0 * (1.0 - 0.82 * t)
		pts.append(p + Vector2(cos(a), sin(a)) * r - Vector2(cos(a0), sin(a0)) * r0)
	return pts


static func _stroke(ci: CanvasItem, pts: PackedVector2Array, w: float, col: Color) -> void:
	ci.draw_polyline(pts, Toon.INK, w + 3.0, true)
	ci.draw_polyline(pts, col, w, true)


static func _thorn(ci: CanvasItem, base: Vector2, dir: Vector2, length: float, w: float, col: Color) -> void:
	var d: Vector2 = dir.normalized()
	var n := Vector2(-d.y, d.x)
	var tri := PackedVector2Array([base + n * w, base + d * length, base - n * w])
	var big := PackedVector2Array([base + n * (w + 2.0) - d * 1.5, base + d * (length + 3.0), base - n * (w + 2.0) - d * 1.5])
	ci.draw_colored_polygon(big, Toon.INK)
	ci.draw_colored_polygon(tri, col)


# Ornamento d'angolo. sx, sy = verso l'interno (+1/-1). k = scala (1 = circa 90 px).
static func corner(ci: CanvasItem, p: Vector2, sx: float, sy: float, k: float, gem: Color, alpha: float = 1.0) -> void:
	var col := Color(SILVER.r, SILVER.g, SILVER.b, alpha)
	var dk := Color(SILVER_DK.r, SILVER_DK.g, SILVER_DK.b, alpha)
	var L: float = 84.0 * k
	# due bracci lungo i bordi, con spine
	_stroke(ci, PackedVector2Array([p, p + Vector2(sx * L, 0)]), 3.0 * k, col)
	_stroke(ci, PackedVector2Array([p, p + Vector2(0, sy * L)]), 3.0 * k, col)
	for i in 3:
		var t: float = 0.35 + 0.25 * float(i)
		_thorn(ci, p + Vector2(sx * L * t, 0), Vector2(0, -sy), 9.0 * k, 3.0 * k, dk)
		_thorn(ci, p + Vector2(0, sy * L * t), Vector2(-sx, 0), 9.0 * k, 3.0 * k, dk)
	# volute alle estremita' dei bracci e una grande verso l'interno
	_stroke(ci, _volute(p + Vector2(sx * L, 0), Vector2(0, sy), 13.0 * k, 1.3, -sx * sy), 2.5 * k, col)
	_stroke(ci, _volute(p + Vector2(0, sy * L), Vector2(sx, 0), 13.0 * k, 1.3, sx * sy), 2.5 * k, col)
	_stroke(ci, _volute(p + Vector2(sx, sy) * 22.0 * k, Vector2(sx, sy).normalized(), 18.0 * k, 1.5, 1.0), 3.0 * k, col)
	# gemma tonda incastonata
	var g: Vector2 = p + Vector2(sx, sy) * 10.0 * k
	ci.draw_circle(g, 11.0 * k + 2.0, Toon.INK)
	ci.draw_circle(g, 11.0 * k, dk)
	ci.draw_circle(g, 7.5 * k, Color(gem.r, gem.g, gem.b, alpha))
	ci.draw_circle(g + Vector2(-2.5, -2.5) * k, 2.5 * k, Color(1, 1, 1, 0.85 * alpha))


# Cornice completa attorno a un rettangolo: doppio filo d'argento + quattro angoli
static func frame(ci: CanvasItem, r: Rect2, k: float, gem: Color, alpha: float = 1.0) -> void:
	var col := Color(SILVER.r, SILVER.g, SILVER.b, alpha * 0.9)
	var inset: float = 8.0 * k
	for j in 2:
		var rr: Rect2 = r.grow(-inset * float(j))
		var pts := PackedVector2Array([rr.position, Vector2(rr.end.x, rr.position.y), rr.end, Vector2(rr.position.x, rr.end.y), rr.position])
		ci.draw_polyline(pts, Toon.INK, (3.0 if j == 0 else 2.0) * k + 3.0)
		ci.draw_polyline(pts, col, (3.0 if j == 0 else 1.5) * k)
	corner(ci, r.position, 1.0, 1.0, k, gem, alpha)
	corner(ci, Vector2(r.end.x, r.position.y), -1.0, 1.0, k, gem, alpha)
	corner(ci, r.end, -1.0, -1.0, k, gem, alpha)
	corner(ci, Vector2(r.position.x, r.end.y), 1.0, -1.0, k, gem, alpha)
