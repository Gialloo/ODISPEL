class_name CharAccent
extends RefCounted

# ACCENTI DEI PERSONAGGI (HUD 0.61, P2, approvato dall'autore il 7/11/2026). Stessa struttura dell'HUD per tutti, ma ogni
# personaggio lascia un segno suo dietro i suoi timbri e nel lampo quando sceglie un comando:
#   lance  impatto      tre tagli diagonali spessi
#   nox    precisione   anelli concentrici sottili
#   saul   imprevisto   pezzi storti, fuori asse
#   rio    hype         stelle, solo nei suoi momenti HYPE (hype=true); fuori dall'HYPE niente accento
# Un solo disegno, senza texture: chi lo usa lo chiama dentro il suo _draw (ci) con l'intensita' a (0..1).

static func draw(ci: CanvasItem, id: String, r: Rect2, col: Color, a: float, hype: bool = false) -> void:
	if a <= 0.01:
		return
	var c: Vector2 = r.get_center()
	match id:
		"lance":
			for k in 3:
				var w: float = r.size.x * (0.16 - 0.03 * k)
				var x: float = c.x - r.size.x * 0.3 + k * r.size.x * 0.26
				var sk: float = r.size.y * 0.45
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x + sk, r.position.y), Vector2(x + sk + w, r.position.y),
					Vector2(x + w - sk * 0.2, r.end.y), Vector2(x - sk * 0.2, r.end.y)]), Color(col, a * (0.55 - 0.1 * k)))
		"nox":
			var rad: float = minf(r.size.x, r.size.y) * 0.5
			for k in 4:
				ci.draw_arc(c, rad * (0.35 + 0.22 * k), 0.0, TAU, 48, Color(col, a * (0.85 - 0.15 * k)), 3.0, true)
			ci.draw_line(c - Vector2(rad * 1.2, 0), c + Vector2(rad * 1.2, 0), Color(col, a * 0.6), 2.0, true)
		"saul":
			# pezzi fuori asse: sempre gli stessi (niente caso), ruotati e spostati come carte lanciate
			var pcs: Array = [[-0.38, -0.2, 0.42, 0.16], [0.3, -0.28, -0.3, 0.12], [-0.12, 0.26, 0.25, 0.14], [0.4, 0.22, -0.5, 0.1], [0.05, -0.05, 0.9, 0.08]]
			for p in pcs:
				var pc: Vector2 = c + Vector2(r.size.x * float(p[0]), r.size.y * float(p[1]))
				var hs := Vector2(r.size.x * float(p[3]), r.size.y * 0.09)
				var pts := PackedVector2Array()
				for q in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
					pts.append(pc + (q * hs).rotated(float(p[2])))
				ci.draw_colored_polygon(pts, Color(col, a * 0.6))
		"rio":
			if not hype:
				return
			var st: Array = [[-0.36, -0.22, 1.0], [0.34, -0.3, 0.7], [-0.1, 0.28, 0.8], [0.42, 0.24, 0.55], [0.0, -0.36, 0.45]]
			for s in st:
				var sc: Vector2 = c + Vector2(r.size.x * float(s[0]), r.size.y * float(s[1]))
				var rr: float = minf(r.size.x, r.size.y) * 0.16 * float(s[2])
				var pts := PackedVector2Array()
				for k in 8:
					pts.append(sc + Vector2.from_angle(-PI / 2.0 + k * PI / 4.0) * (rr if k % 2 == 0 else rr * 0.32))
				ci.draw_colored_polygon(pts, Color(col.lightened(0.3), a * 0.8))
