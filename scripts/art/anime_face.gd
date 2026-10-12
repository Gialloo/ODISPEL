class_name AnimeFace
extends RefCounted

# Volto anime dei segnaposto: capelli nel colore dell'operatore, volto semplice e OCCHI grandi che cambiano
# con l'espressione. Si disegna su qualunque CanvasItem (ritratti, sagome in battaglia, icone).

static func oval(c: Vector2, rx: float, ry: float, n: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a: float = TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


# Contorno chiuso a inchiostro: da' il tratto "manga" a ogni forma piena.
static func outline(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	var closed: PackedVector2Array = pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, col, w)


static func hair_style(char_id: String) -> int:
	return absi(char_id.hash()) % 3


# Capelli dietro la testa (da disegnare prima di spalle e volto).
static func hair_back(ci: CanvasItem, head: Vector2, r: float, char_id: String, col: Color, tint: Color) -> void:
	if r < 2.0:
		return
	var hair_col: Color = col.darkened(0.15) * tint
	var style: int = hair_style(char_id)
	# capelli dietro: massa + ciocche lunghe nello stile 2
	var ink_hair: Color = col.darkened(0.65) * tint
	var mass: PackedVector2Array = oval(head + Vector2(0, -r * 0.1), r * 1.22, r * 1.3)
	ci.draw_colored_polygon(mass, hair_col)
	# ombra a colore piatto in basso a destra (luce da sinistra)
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(r * 0.5, r * 1.12), head + Vector2(r * 0.9, r * 0.9), head + Vector2(r * 1.1, r * 0.55), head + Vector2(r * 1.2, -r * 0.1), head + Vector2(r * 0.7, r * 0.2)]), col.darkened(0.4) * tint)
	outline(ci, mass, ink_hair, maxf(2.0, r * 0.06))
	if style == 0:
		# ciuffo ribelle in cima
		ci.draw_polyline(PackedVector2Array([head + Vector2(0, -r * 1.3), head + Vector2(r * 0.12, -r * 1.7), head + Vector2(r * 0.5, -r * 1.75), head + Vector2(r * 0.6, -r * 1.5)]), ink_hair, maxf(5.0, r * 0.2))
		ci.draw_polyline(PackedVector2Array([head + Vector2(0, -r * 1.3), head + Vector2(r * 0.12, -r * 1.7), head + Vector2(r * 0.5, -r * 1.75), head + Vector2(r * 0.6, -r * 1.5)]), hair_col, maxf(3.0, r * 0.12))
	if style == 2:
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-r * 1.15, 0), head + Vector2(-r * 1.3, r * 2.0), head + Vector2(-r * 0.7, r * 1.7), head + Vector2(-r * 0.6, 0)]), hair_col)
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(r * 1.15, 0), head + Vector2(r * 1.3, r * 2.0), head + Vector2(r * 0.7, r * 1.7), head + Vector2(r * 0.6, 0)]), hair_col)


# Volto, frangia, occhi e bocca.
static func face(ci: CanvasItem, head: Vector2, r: float, char_id: String, col: Color, tint: Color, expression: String) -> void:
	if r < 2.0:
		return
	var hair_col: Color = col.darkened(0.15) * tint
	var hair_hi: Color = col.lightened(0.35) * tint
	var skin: Color = Color("#f7dfcf") * tint
	var skin_sh: Color = Color("#e3b9a4") * tint
	var line: Color = Color("#1a1020") * tint
	var style: int = hair_style(char_id)

	# volto
	var face_pts: PackedVector2Array = oval(head + Vector2(0, r * 0.12), r * 0.92, r * 1.08)
	ci.draw_colored_polygon(face_pts, skin)
	outline(ci, face_pts, Color("#a8705e") * tint, maxf(2.0, r * 0.045))
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(r * 0.55, r * 0.5), head + Vector2(r * 0.88, r * 0.1), head + Vector2(r * 0.7, r * 0.95)]), skin_sh)

	# frangia: calotta sopra la fronte con il bordo basso che cambia con lo stile; ciuffi laterali ai lati del volto
	var edge: Array = [
		[[0.98, 0.15], [0.7, -0.2], [0.55, 0.05], [0.3, -0.3], [0.15, 0.0], [-0.1, -0.35], [-0.3, 0.05], [-0.55, -0.25], [-0.7, 0.1], [-0.98, 0.2]],
		[[0.98, 0.3], [0.7, -0.1], [0.3, -0.45], [0.05, -0.55], [-0.05, -0.55], [-0.3, -0.45], [-0.7, -0.1], [-0.98, 0.3]],
		[[0.98, 0.1], [0.6, -0.3], [0.1, -0.4], [-0.4, -0.1], [-0.7, 0.3], [-0.98, 0.55]],
	][style]
	# ombra della frangia sulla fronte
	var shade := PackedVector2Array()
	for pt in edge:
		shade.append(head + Vector2(float(pt[0]) * r * 0.9, float(pt[1]) * r))
	for k in range(edge.size() - 1, -1, -1):
		shade.append(head + Vector2(float(edge[k][0]) * r * 0.9, float(edge[k][1]) * r + r * 0.16))
	ci.draw_colored_polygon(shade, Color(skin_sh, 0.85))
	var bangs := PackedVector2Array()
	for i in 13:
		var a2: float = PI + PI * float(i) / 12.0
		bangs.append(head + Vector2(cos(a2) * r * 1.02, sin(a2) * r * 1.1 - r * 0.05))
	for pt in edge:
		bangs.append(head + Vector2(float(pt[0]) * r, float(pt[1]) * r))
	ci.draw_colored_polygon(bangs, hair_col)
	outline(ci, bangs, col.darkened(0.65) * tint, maxf(2.0, r * 0.05))
	for s in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(s * r * 0.86, -r * 0.3), head + Vector2(s * r * 1.04, -r * 0.2), head + Vector2(s * r * 1.0, r * 0.75), head + Vector2(s * r * 0.84, r * 0.45)]), hair_col)
	ci.draw_polyline(PackedVector2Array([head + Vector2(-r * 0.6, -r * 0.8), head + Vector2(-r * 0.1, -r * 0.95), head + Vector2(r * 0.35, -r * 0.85)]), hair_hi, maxf(3.0, r * 0.08))
	ci.draw_polyline(PackedVector2Array([head + Vector2(-r * 0.85, -r * 0.45), head + Vector2(-r * 0.78, -r * 0.7)]), Color(hair_hi, 0.7), maxf(2.0, r * 0.06))

	# occhi: la parte che conta
	var ey: float = head.y + r * 0.3
	var ex: float = r * 0.45
	var erx: float = r * 0.32
	var ery: float = r * 0.42
	var iris: Color = col.lightened(0.1) * tint
	match expression:
		"happy":
			for s in [-1.0, 1.0]:
				ci.draw_arc(Vector2(head.x + s * ex, ey + ery * 0.2), erx * 0.9, PI * 1.08, PI * 1.92, 14, line, 4.0)
		"angry":
			for s in [-1.0, 1.0]:
				var c := Vector2(head.x + s * ex, ey)
				ci.draw_colored_polygon(oval(c, erx, ery * 0.72), Color("#ffffff") * tint)
				ci.draw_colored_polygon(oval(c + Vector2(0, ery * 0.05), erx * 0.62, ery * 0.62), iris)
				ci.draw_circle(c + Vector2(-erx * 0.2, -ery * 0.15), erx * 0.18, Color.WHITE)
				ci.draw_line(c + Vector2(-s * erx * 1.15, -ery * 1.15 + s * ery * 0.0), c + Vector2(s * erx * 0.4, -ery * 0.55), line, 5.0)
		"sad", "hurt":
			for s in [-1.0, 1.0]:
				var c2 := Vector2(head.x + s * ex, ey + ery * 0.1)
				ci.draw_colored_polygon(oval(c2, erx, ery), Color("#ffffff") * tint)
				ci.draw_colored_polygon(oval(c2 + Vector2(0, ery * 0.15), erx * 0.72, ery * 0.78), iris)
				ci.draw_circle(c2 + Vector2(-erx * 0.25, -ery * 0.2), erx * 0.26, Color.WHITE)
				ci.draw_circle(c2 + Vector2(erx * 0.2, ery * 0.3), erx * 0.12, Color(1, 1, 1, 0.8))
				ci.draw_line(c2 + Vector2(-s * erx * 1.0, -ery * 1.2 + s * 0.0), c2 + Vector2(s * erx * 0.9, -ery * 1.45), line, 4.0)
			ci.draw_circle(Vector2(head.x - ex * 1.05, ey + ery * 1.5), r * 0.05, Color("#9fe6ff") * tint)
		"surprised":
			for s in [-1.0, 1.0]:
				var c3 := Vector2(head.x + s * ex, ey)
				ci.draw_colored_polygon(oval(c3, erx * 1.05, ery * 1.15), Color("#ffffff") * tint)
				ci.draw_colored_polygon(oval(c3, erx * 0.5, ery * 0.6), iris)
				ci.draw_circle(c3 + Vector2(-erx * 0.12, -ery * 0.2), erx * 0.15, Color.WHITE)
		_:
			for s in [-1.0, 1.0]:
				var c4 := Vector2(head.x + s * ex, ey)
				ci.draw_colored_polygon(oval(c4, erx, ery), Color("#ffffff") * tint)
				ci.draw_colored_polygon(oval(c4 + Vector2(0, ery * 0.1), erx * 0.78, ery * 0.88), iris)
				ci.draw_colored_polygon(oval(c4 + Vector2(0, ery * 0.12), erx * 0.42, ery * 0.5), line)
				ci.draw_colored_polygon(oval(c4 + Vector2(0, ery * 0.5), erx * 0.5, ery * 0.2, 12), Color(col.lightened(0.5) * tint, 0.75))
				ci.draw_circle(c4 + Vector2(-erx * 0.28, -ery * 0.28), erx * 0.26, Color.WHITE)
				ci.draw_circle(c4 + Vector2(erx * 0.25, ery * 0.35), erx * 0.12, Color(1, 1, 1, 0.85))
				ci.draw_arc(c4, erx * 1.02, PI * 1.05, PI * 1.95, 14, line, 4.0)
	# guance e naso
	if expression != "angry":
		for s in [-1.0, 1.0]:
			ci.draw_colored_polygon(oval(Vector2(head.x + s * r * 0.62, head.y + r * 0.66), r * 0.2, r * 0.1, 14), Color("#ff8fa3", 0.34 * tint.a) * Color(tint.r, tint.g, tint.b, 1.0))
	ci.draw_line(Vector2(head.x + r * 0.03, head.y + r * 0.6), Vector2(head.x - r * 0.03, head.y + r * 0.7), Color("#a8705e") * tint, maxf(2.0, r * 0.05))
	# sopracciglia (tranne dove gia' disegnate) e bocca minima
	if expression != "angry" and expression != "sad" and expression != "hurt":
		for s in [-1.0, 1.0]:
			ci.draw_line(Vector2(head.x + s * ex - erx * 0.8, ey - ery * 1.5), Vector2(head.x + s * ex + erx * 0.8, ey - ery * 1.6 - (r * 0.05 if expression == "surprised" else 0.0)), line, 3.0)
	var my: float = head.y + r * 0.82
	match expression:
		"happy":
			ci.draw_arc(Vector2(head.x, my - r * 0.1), r * 0.2, PI * 0.1, PI * 0.9, 10, line, 3.0)
		"surprised":
			ci.draw_colored_polygon(oval(Vector2(head.x, my), r * 0.07, r * 0.1, 12), line)
		"sad", "hurt":
			ci.draw_arc(Vector2(head.x, my + r * 0.12), r * 0.12, PI * 1.15, PI * 1.85, 8, line, 3.0)
		"angry":
			ci.draw_line(Vector2(head.x - r * 0.12, my), Vector2(head.x + r * 0.12, my + 2.0), line, 3.0)
		_:
			ci.draw_line(Vector2(head.x - r * 0.1, my), Vector2(head.x + r * 0.1, my), line, 3.0)
