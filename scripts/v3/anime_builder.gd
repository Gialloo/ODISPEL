class_name AnimeBuilder
extends RefCounted

# Costruisce i personaggi in stile anime semplificato, tutto da codice (PROVVISORIO, in attesa dei modelli glTF):
# forme morbide con normali lisce, testa grande, viso a V, occhi anime disegnati sulla faccia, capelli a ciocche.
# Coordinate: metri, personaggio alto 1,75 (poi scalato), guarda verso -Z. Ogni parte e' nello spazio del suo perno:
#   busto -> perno dei fianchi (y = 0 all'anca) · testa -> base del collo · braccio -> spalla · gamba -> anca.
# Colore dei vertici, canale alpha = tipo di superficie per lo shader toon:
#   1.0 normale (ombra fredda) · 0.8 pelle (ombra calda) · 0.6 piatta, senza ombra (viso) · 0.0 luce propria

const HIP_Y: float = 0.92            # gambe lunghe (circa meta' altezza)
const NECK_Y: float = 0.52           # base del collo sopra l'anca
const SHOULDER_Y: float = 0.445
const HEAD_OFF: float = 0.075        # mento sopra la base del collo

# Profilo della testa: [y dal mento, rx, z davanti, z dietro] (fronte = -Z). Viso a V, cranio tondo che sporge dietro sul collo.
const HEAD: Array = [
	[0.0, 0.012, -0.064, -0.04],
	[0.025, 0.047, -0.088, 0.0],
	[0.06, 0.082, -0.108, 0.05],
	[0.10, 0.103, -0.112, 0.088],
	[0.15, 0.112, -0.117, 0.114],
	[0.20, 0.109, -0.112, 0.12],
	[0.24, 0.088, -0.088, 0.104],
	[0.27, 0.047, -0.042, 0.062],
	[0.283, 0.008, -0.004, 0.02],
]


static func _a(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)


static func _r(y: float, rx: float, rz: float, z: float = 0.0, x: float = 0.0) -> Array:
	return MeshBatch.ring(x, y, z, rx, rz)


# ================================================================ busto

static func torso(sp: Dictionary) -> MeshBatch:
	var mb := MeshBatch.new()
	mb.ink_w = 0.012
	var b: float = float(sp.get("build", 1.0))
	var fem: bool = bool(sp.get("fem", false))
	var top: Color = Color(str(sp["top"]))
	var bottom: Color = Color(str(sp["bottom"]))
	var accent: Color = Color(str(sp["accent"]))
	var skin: Color = _a(Color(str(sp["skin"])), 0.8)
	var extra: String = str(sp["extra"])
	var puff: float = 0.012 if extra in ["mask", "bag"] else 0.0
	var wx: float = (0.112 if fem else 0.125) * b
	var hx: float = (0.142 if fem else 0.132) * b
	var cx: float = (0.13 if fem else 0.15) * b
	var sx: float = (0.14 if fem else 0.168) * b
	# bacino (colore dei pantaloni)
	mb.sweep([_r(-0.07, hx * 0.9, 0.085), _r(0.0, hx, 0.092), _r(0.07, hx * 0.98, 0.09), _r(0.13, wx + 0.005, 0.083)], 14, bottom, true, true, false)
	# busto (giacca)
	var rings: Array = [
		_r(0.11, wx + 0.008 + puff, 0.085 + puff),
		_r(0.2, wx + 0.012 + puff, 0.088 + puff),
		_r(0.31, cx + puff, 0.1 + puff, -0.008 if fem else -0.004),
		_r(0.40, sx + puff * 0.5, 0.092 + puff),
		_r(0.455, sx * 0.85, 0.08),
		_r(0.50, 0.075, 0.058),
		_r(0.53, 0.045, 0.042, 0.005),
	]
	mb.sweep(rings, 16, top, true, false, true)
	# cintura
	mb.sweep([_r(0.105, wx + 0.016 + puff, 0.093 + puff), _r(0.14, wx + 0.016 + puff, 0.093 + puff)], 16, bottom.darkened(0.45), false, false, false)
	match extra:
		"cap":
			# uniforme LibraCorp: spalline rosse, collo alto, placca, fibbia
			for s in [-1.0, 1.0]:
				mb.ball(Transform3D(Basis().scaled(Vector3(1.0, 0.35, 0.8)), Vector3(s * sx * 0.82, 0.45, 0.0)), 0.07, accent)
			mb.sweep([_r(0.48, 0.07, 0.06), _r(0.56, 0.062, 0.055, 0.004)], 14, top.darkened(0.15), true, false, false)
			mb.sweep([_r(0.535, 0.064, 0.057, 0.004), _r(0.55, 0.064, 0.057, 0.004)], 14, accent, false, false, false)
			mb.box(Transform3D(Basis(), Vector3(0.06, 0.34, -0.108)), Vector3(0.05, 0.035, 0.012), Color("#d9dde8"), false)
			mb.box(Transform3D(Basis(), Vector3(0, 0.125, -wx * 0.75 - 0.03)), Vector3(0.05, 0.035, 0.015), Color("#c9ccd6"), false)
			mb.box(Transform3D(Basis(), Vector3(0, 0.27, -0.1)), Vector3(0.012, 0.28, 0.01), accent, false)
		"coat":
			# cappotto delle Civette: si apre a campana fino al ginocchio, collo alto, profilo blu davanti
			mb.sweep([_r(0.13, wx + 0.02, 0.09), _r(0.0, hx + 0.03, 0.105), _r(-0.25, hx + 0.07, 0.13, 0.01), _r(-0.5, hx + 0.12, 0.16, 0.02)], 16, top.darkened(0.12), true, false, false)
			mb.sweep([_r(0.46, 0.085, 0.07), _r(0.585, 0.078, 0.068, 0.01)], 14, top.darkened(0.2), true, false, false)
			mb.box(Transform3D(Basis(), Vector3(0, 0.0, -0.13)), Vector3(0.018, 0.86, 0.012), accent, false)
			mb.box(Transform3D(Basis(), Vector3(-0.07, 0.36, -0.1)), Vector3(0.035, 0.035, 0.012), Color(accent.r, accent.g, accent.b, 0.0), false)
		"mask":
			# felpa larga: tasca davanti, cappuccio dietro il collo, lacci gialli
			mb.box(Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0, 0.17, -wx - 0.03)), Vector3(0.16, 0.08, 0.02), top.darkened(0.15))
			mb.ball(Transform3D(Basis().scaled(Vector3(1.0, 0.75, 0.75)), Vector3(0, 0.52, 0.075)), 0.105, top.darkened(0.2))
			for s in [-1.0, 1.0]:
				mb.lock(Vector3(s * 0.035, 0.48, -0.09), Vector3(s * 0.04, 0.42, -0.115), Vector3(s * 0.038, 0.36, -0.12), 0.006, 0.006, Vector3.FORWARD, Ui.YELLOW, false, 3)
			mb.box(Transform3D(Basis(), Vector3(0.06, 0.33, -0.115)), Vector3(0.05, 0.03, 0.01), Color(1.0, 0.82, 0.25, 0.0), false)
		"bag":
			# bomber: polsini a costine, colletto, tracolla e borsa
			mb.sweep([_r(0.11, wx + 0.026, 0.1), _r(0.16, wx + 0.026, 0.1)], 16, top.darkened(0.3), false, false, false)
			mb.sweep([_r(0.47, 0.08, 0.066), _r(0.54, 0.07, 0.06, 0.006)], 14, top.darkened(0.3), true, false, false)
			mb.lock(Vector3(-sx * 0.75, 0.47, -0.06), Vector3(0.0, 0.3, -0.13), Vector3(sx * 0.95, 0.08, -0.04), 0.022, 0.006, Vector3.FORWARD, Color("#5a3b26"), false, 6)
			mb.box(Transform3D(Basis(Vector3.UP, 0.25), Vector3(sx * 0.95 + 0.04, 0.02, 0.0)), Vector3(0.08, 0.17, 0.22), Color("#8a5a32"))
			mb.box(Transform3D(Basis(Vector3.UP, 0.25), Vector3(sx * 0.95 + 0.085, 0.06, -0.01)), Vector3(0.02, 0.05, 0.12), accent, false)
	# collo (pelle)
	mb.sweep([_r(0.5, 0.04, 0.038, 0.012), _r(0.6, 0.036, 0.034, 0.012)], 10, skin, false, false, false)
	return mb


# ================================================================ testa

static func _head_at(y: float) -> Array:
	# rx, rz, cz interpolati sul profilo
	for i in HEAD.size() - 1:
		var a: Array = HEAD[i]
		var c: Array = HEAD[i + 1]
		if y <= float(c[0]):
			var t: float = clampf((y - float(a[0])) / maxf(0.0001, float(c[0]) - float(a[0])), 0.0, 1.0)
			var zf: float = lerpf(a[2], c[2], t)
			var zb: float = lerpf(a[3], c[3], t)
			return [lerpf(a[1], c[1], t), (zb - zf) * 0.5, (zb + zf) * 0.5]
	var l: Array = HEAD[HEAD.size() - 1]
	return [l[1], (float(l[3]) - float(l[2])) * 0.5, (float(l[3]) + float(l[2])) * 0.5]


# Punto sulla superficie della testa: phi = 0 davanti (-Z), PI dietro. Ritorna [punto, normale].
static func _head_pt(phi: float, y: float, grow: float) -> Array:
	var h: Array = _head_at(y)
	var rx: float = float(h[0]) + grow
	var rz: float = float(h[1]) + grow
	var p := Vector3(sin(phi) * rx, y + HEAD_OFF, float(h[2]) - cos(phi) * rz)
	var n := Vector3(sin(phi) / maxf(0.01, rx), 0.0, -cos(phi) / maxf(0.01, rz)).normalized()
	return [p, n]


# Punto del viso dato x (laterale) e y (dal mento), staccato di off lungo la normale
static func _face(x: float, y: float, off: float) -> Array:
	var h: Array = _head_at(y)
	var rx: float = float(h[0])
	var rz: float = float(h[1])
	var u: float = clampf(x / maxf(0.01, rx), -0.98, 0.98)
	var phi: float = asin(u)
	var hp: Array = _head_pt(phi, y, 0.0)
	return [(hp[0] as Vector3) + (hp[1] as Vector3) * off, hp[1]]


static func _decal(mb: MeshBatch, pts: Array, off: float, col: Color) -> void:
	# poligono (x, y nel viso) proiettato sulla faccia, a ventaglio dal baricentro
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= float(pts.size())
	var cc: Array = _face(c.x, c.y, off)
	for i in pts.size():
		var a: Array = _face((pts[i] as Vector2).x, (pts[i] as Vector2).y, off)
		var b: Array = _face((pts[(i + 1) % pts.size()] as Vector2).x, (pts[(i + 1) % pts.size()] as Vector2).y, off)
		mb._tri_smooth(cc[0], a[0], b[0], cc[1], a[1], b[1], col, false)


static func _ellipse(center: Vector2, rx: float, ry: float, n: int = 14, a0: float = 0.0, a1: float = TAU) -> Array:
	var out: Array = []
	for i in n:
		var a: float = lerpf(a0, a1, float(i) / float(n))
		out.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return out


static func _band(pts_center: Array, th: float) -> Array:
	# striscia spessa th lungo una polilinea (per ciglia e sopracciglia)
	var top: Array = []
	var bot: Array = []
	for i in pts_center.size():
		var p: Vector2 = pts_center[i]
		var d: Vector2 = (pts_center[mini(i + 1, pts_center.size() - 1)] as Vector2) - (pts_center[maxi(i - 1, 0)] as Vector2)
		var n: Vector2 = Vector2(-d.y, d.x).normalized()
		var k: float = th * (0.55 + 0.45 * sin(PI * float(i) / float(maxi(1, pts_center.size() - 1))))
		top.append(p + n * k * 0.5)
		bot.append(p - n * k * 0.5)
	bot.reverse()
	return top + bot


static func head(sp: Dictionary) -> MeshBatch:
	var mb := MeshBatch.new()
	mb.ink_w = 0.008
	var skin := Color(str(sp["skin"]))
	var face_col: Color = _a(skin, 0.6)
	var hair: Color = Color(str(sp["hair"]))
	var accent: Color = Color(str(sp["accent"]))
	var style: String = str(sp["hair_style"])
	var extra: String = str(sp["extra"])
	# cranio e viso
	var secs: Array = []
	for r in HEAD:
		var hh: Array = _head_at(float(r[0]))
		secs.append(MeshBatch.ring(0.0, float(r[0]) + HEAD_OFF, float(hh[2]), float(hh[0]), float(hh[1])))
	mb.sweep(secs, 18, face_col, true, false, false)
	# orecchie
	for s in [-1.0, 1.0]:
		mb.ball(Transform3D(Basis().scaled(Vector3(0.45, 1.0, 0.7)), Vector3(s * 0.106, HEAD_OFF + 0.105, 0.012)), 0.03, _a(skin, 0.8), true, 4, 8)
	if extra == "mask" and not bool(sp.get("nomask", false)):
		_mask(mb, accent)
	else:
		_eyes(mb, sp)
	_hair(mb, style, hair, accent, sp)
	return mb


static func _eyes(mb: MeshBatch, sp: Dictionary) -> void:
	var eye: Color = Color(str(sp.get("eyes", "#5a3a2a")))
	var tilt: float = float(sp.get("brow", 0.0))        # + arrabbiato (interno basso), - stanco
	var lid: float = float(sp.get("lid", 0.0))          # palpebra calata (Nox): 0..1
	var ink: Color = _a(Toon.INK, 0.6)
	var wide: float = 1.12 if bool(sp.get("wide", false)) else 1.0    # occhi spalancati (sorpresa)
	var brow_up: float = float(sp.get("brow_up", 0.0))
	for s in [-1.0, 1.0]:
		var c := Vector2(0.043 * s, 0.098)
		# bianco dell'occhio
		_decal(mb, _ellipse(c, 0.025 * wide, 0.026 * wide * (1.0 - 0.35 * lid)), 0.0015, Color(0.98, 0.97, 1.0, 0.6))
		# iride alta, piu' chiara in basso, pupilla, riflesso
		var ir := c + Vector2(0.0, -0.002)
		_decal(mb, _ellipse(ir, 0.0165, 0.024 * (1.0 - 0.3 * lid)), 0.0025, _a(eye, 0.6))
		_decal(mb, _ellipse(ir + Vector2(0, -0.008), 0.012, 0.011), 0.0032, _a(eye.lightened(0.35), 0.6))
		_decal(mb, _ellipse(ir + Vector2(0, 0.002), 0.008 / wide / wide, 0.012 / wide / wide), 0.0038, _a(eye.darkened(0.65), 0.6))
		_decal(mb, _ellipse(ir + Vector2(0.006 * s, 0.009), 0.0048, 0.0048, 8), 0.0045, Color(1, 1, 1, 0.0))
		# palpebra calata (copre la parte alta)
		if lid > 0.01:
			var top_y: float = c.y + 0.026
			var cut: float = c.y + 0.026 - 0.04 * lid
			_decal(mb, [c + Vector2(-0.028, cut - c.y), c + Vector2(0.028, cut - c.y), c + Vector2(0.028, top_y - c.y + 0.004), c + Vector2(-0.028, top_y - c.y + 0.004)], 0.004, face_col_of(sp))
		# ciglia superiori spesse con la "coda" esterna
		var lash: Array = []
		for i in 9:
			var a: float = lerpf(PI * 0.92, PI * 0.08, float(i) / 8.0)
			var p := c + Vector2(cos(a) * 0.027 * s * -1.0 * -1.0, sin(a) * 0.024 * (1.0 - 0.6 * lid) + 0.004 - 0.016 * lid)
			p.x = c.x + cos(a) * 0.027 * (1.0 if s > 0.0 else -1.0)
			lash.append(p)
		lash.append(lash[lash.size() - 1] + Vector2(0.008 * s, -0.004))
		_decal(mb, _band(lash, 0.008), 0.005, ink)
		# sopracciglio
		var b0 := Vector2(0.018 * s, 0.137 - tilt * 0.012 + brow_up)
		var b1 := Vector2(0.044 * s, 0.142 + tilt * 0.002 + brow_up)
		var b2 := Vector2(0.068 * s, 0.136 + tilt * 0.008 + brow_up)
		_decal(mb, _band([b0, b1, b2], 0.006), 0.004, ink)
		# lacrima (tristezza)
		if bool(sp.get("tear", false)):
			_decal(mb, _ellipse(c + Vector2(0.012 * s, -0.034), 0.0045, 0.008, 8), 0.004, Color(0.6, 0.85, 1.0, 0.0))
	# naso (ombra piccola) e bocca
	_decal(mb, _ellipse(Vector2(0.0, 0.066), 0.004, 0.007, 6), 0.002, _a(face_col_of(sp).darkened(0.25), 0.6))
	var smirk: float = float(sp.get("smirk", 0.0))
	var lip: Color = _a(Toon.INK.lightened(0.15), 0.6)
	match str(sp.get("mouth", "")):
		"smile":
			_decal(mb, _band([Vector2(-0.02, 0.044), Vector2(-0.008, 0.035), Vector2(0.008, 0.035), Vector2(0.02, 0.044)], 0.004), 0.003, lip)
		"grin":
			_decal(mb, [Vector2(-0.02, 0.044), Vector2(0.02, 0.044), Vector2(0.01, 0.03), Vector2(-0.01, 0.03)], 0.003, Color(0.35, 0.08, 0.12, 0.6))
			_decal(mb, [Vector2(-0.018, 0.043), Vector2(0.018, 0.043), Vector2(0.016, 0.039), Vector2(-0.016, 0.039)], 0.0035, Color(1, 1, 1, 0.6))
		"frown":
			_decal(mb, _band([Vector2(-0.016, 0.034), Vector2(0.0, 0.039), Vector2(0.016, 0.034)], 0.0035), 0.003, lip)
		"open":
			_decal(mb, _ellipse(Vector2(0.0, 0.036), 0.009, 0.011, 12), 0.003, Color(0.35, 0.08, 0.12, 0.6))
		"teeth":
			_decal(mb, [Vector2(-0.018, 0.041), Vector2(0.018, 0.041), Vector2(0.015, 0.031), Vector2(-0.015, 0.031)], 0.003, Color(0.35, 0.08, 0.12, 0.6))
			_decal(mb, [Vector2(-0.016, 0.04), Vector2(0.016, 0.04), Vector2(0.015, 0.035), Vector2(-0.015, 0.035)], 0.0035, Color(1, 1, 1, 0.6))
		_:
			_decal(mb, _band([Vector2(-0.016, 0.038 - smirk * 0.002), Vector2(0.0, 0.036), Vector2(0.017, 0.039 + smirk * 0.006)], 0.0035), 0.003, lip)


static func face_col_of(sp: Dictionary) -> Color:
	return _a(Color(str(sp["skin"])), 0.6)


static func _mask(mb: MeshBatch, accent: Color) -> void:
	# maschera dei Masca: guscio bianco sul viso, occhi a fessura viola luminosi, bocca a fessura gialla
	var white := Color(0.96, 0.95, 0.93, 0.6)
	var cols: int = 12
	var rows: int = 8
	var grid: Array = []
	for i in rows + 1:
		var y: float = lerpf(0.0, 0.19, float(i) / float(rows))
		var row: Array = []
		for j in cols + 1:
			var phi: float = lerpf(-1.35, 1.35, float(j) / float(cols))
			row.append(_head_pt(phi, y, 0.011))
		grid.append(row)
	for i in rows:
		for j in cols:
			var a: Array = grid[i][j]
			var b: Array = grid[i + 1][j]
			var c: Array = grid[i][j + 1]
			var d: Array = grid[i + 1][j + 1]
			mb._tri_smooth(a[0], b[0], c[0], a[1], b[1], c[1], white, false)
			mb._tri_smooth(c[0], b[0], d[0], c[1], b[1], d[1], white, false)
	for s in [-1.0, 1.0]:
		var slit: Array = [Vector2(0.018 * s, 0.1), Vector2(0.07 * s, 0.118), Vector2(0.066 * s, 0.103), Vector2(0.02 * s, 0.09)]
		_decal(mb, slit, 0.016, Color(0.8, 0.35, 1.0, 0.0))
	_decal(mb, [Vector2(-0.03, 0.045), Vector2(0.03, 0.045), Vector2(0.026, 0.037), Vector2(-0.026, 0.037)], 0.016, Color(accent.r, accent.g, accent.b, 0.0))


# Calotta di capelli: dalla linea dell'attaccatura (alta davanti, bassa dietro) fino alla cima
static func _shell(mb: MeshBatch, hair: Color, front_y: float, back_y: float, grow: float) -> void:
	for pass_i in 2:
		var g: float = grow + (0.0 if pass_i == 0 else mb.ink_w)
		var col: Color = hair if pass_i == 0 else Toon.INK
		var ol: bool = pass_i == 1
		var cols: int = 20
		var rows: int = 7
		var grid: Array = []
		for i in rows + 1:
			var row: Array = []
			for j in cols:
				var phi: float = TAU * float(j) / float(cols)
				var yb: float = lerpf(front_y, back_y, (1.0 - cos(phi)) * 0.5)
				var y: float = lerpf(yb, 0.283, pow(float(i) / float(rows), 0.8))
				row.append(_head_pt(phi, y, g * (1.0 - 0.6 * float(i) / float(rows)) + 0.004))
			grid.append(row)
		for i in rows:
			for j in cols:
				var j1: int = (j + 1) % cols
				var a: Array = grid[i][j]
				var b: Array = grid[i + 1][j]
				var c: Array = grid[i][j1]
				var d: Array = grid[i + 1][j1]
				mb._tri_smooth(a[0], b[0], c[0], a[1], b[1], c[1], col, ol)
				mb._tri_smooth(c[0], b[0], d[0], c[1], b[1], d[1], col, ol)
		var top := Vector3(0, 0.283 + HEAD_OFF + g * 0.4 + 0.004, 0.01)
		for j in cols:
			mb._tri_smooth(grid[rows][j][0], grid[rows][(j + 1) % cols][0], top, Vector3.UP, Vector3.UP, Vector3.UP, col, ol)


static func _hp(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, y + HEAD_OFF, z)


static func _bangs(mb: MeshBatch, hair: Color, xs: Array, root_y: float, tip_y: float, w: float) -> void:
	for x in xs:
		var r: Array = _face(float(x) * 0.8, root_y, 0.012)
		var m: Array = _face(float(x) * 0.95, lerpf(root_y, tip_y, 0.5), 0.02)
		var t: Array = _face(float(x) * 1.05, tip_y, 0.012)
		mb.lock(r[0], m[0], t[0], w, 0.016, Vector3.FORWARD, hair, true, 5)


static func _hair(mb: MeshBatch, style: String, hair: Color, accent: Color, sp: Dictionary) -> void:
	match style:
		"crew":
			# corti sotto il berretto, basette
			_shell(mb, hair, 0.19, 0.02, 0.008)
			_bangs(mb, hair, [-0.055, -0.02, 0.02, 0.06], 0.205, 0.165, 0.022)
			for s in [-1.0, 1.0]:
				mb.lock(_hp(s * 0.105, 0.17, -0.03), _hp(s * 0.112, 0.13, -0.04), _hp(s * 0.108, 0.085, -0.045), 0.016, 0.01, Vector3.RIGHT, hair, true, 4)
			# berretto con visiera e stemma (bilancia stilizzata)
			var cap := Color("#25324f")
			mb.sweep([_r(0.205 + HEAD_OFF, 0.124, 0.13, 0.008), _r(0.25 + HEAD_OFF, 0.132, 0.14, 0.005), _r(0.3 + HEAD_OFF, 0.128, 0.138, 0.0), _r(0.325 + HEAD_OFF, 0.09, 0.1, 0.0)], 18, cap, true, false, true)
			mb.sweep([_r(0.205 + HEAD_OFF, 0.126, 0.132, 0.008), _r(0.228 + HEAD_OFF, 0.126, 0.132, 0.008)], 18, Color("#e8343f"), false, false, false)
			mb.sweep([[Vector3(0, 0.205 + HEAD_OFF, -0.15), Vector3.RIGHT, Vector3(0, 0.18, -0.98).normalized(), 0.105, 0.06]], 3, cap, false, false, false)
			mb.ball(Transform3D(Basis(Vector3.RIGHT, 0.2).scaled(Vector3(1.0, 0.12, 0.6)), Vector3(0, 0.205 + HEAD_OFF, -0.165)), 0.11, Color("#141a2b"))
			mb.box(Transform3D(Basis(Vector3.RIGHT, -0.15), Vector3(0, 0.275 + HEAD_OFF, -0.142)), Vector3(0.05, 0.004, 0.008), Color("#f2f0ea"), false)
			mb.box(Transform3D(Basis(Vector3.RIGHT, -0.15), Vector3(0, 0.263 + HEAD_OFF, -0.141)), Vector3(0.006, 0.026, 0.008), Color("#f2f0ea"), false)
		"owl":
			# lunghi scuri, frangia asimmetrica, due ciuffi a orecchie di civetta
			_shell(mb, hair, 0.2, 0.0, 0.012)
			_bangs(mb, hair, [-0.07, -0.035, 0.0, 0.03, 0.065], 0.215, 0.13, 0.026)
			mb.lock(_hp(0.04, 0.21, -0.1), _hp(0.06, 0.15, -0.125), _hp(0.05, 0.085, -0.12), 0.03, 0.016, Vector3.FORWARD, hair, true, 5)
			for s in [-1.0, 1.0]:
				mb.lock(_hp(s * 0.1, 0.17, -0.02), _hp(s * 0.125, 0.06, -0.03), _hp(s * 0.12, -0.04, -0.01), 0.032, 0.018, Vector3.RIGHT, hair, true, 5)
				mb.lock(_hp(s * 0.065, 0.25, 0.02), _hp(s * 0.1, 0.3, 0.005), _hp(s * 0.125, 0.335, 0.025), 0.032, 0.018, Vector3.BACK, hair, true, 5)
			# massa dietro fino alle scapole
			for i in 5:
				var x: float = lerpf(-0.075, 0.075, float(i) / 4.0)
				mb.lock(_hp(x, 0.2, 0.09), _hp(x * 1.3, 0.05, 0.15), _hp(x * 1.1, -0.2, 0.12), 0.05, 0.025, Vector3.BACK, hair, true, 6)
			mb.box(Transform3D(Basis(Vector3.BACK, 0.4), _hp(-0.085, 0.215, -0.07)), Vector3(0.035, 0.01, 0.012), Color(accent.r, accent.g, accent.b, 0.0), false)
		"spiky":
			# bianchi a punte in tutte le direzioni
			_shell(mb, hair, 0.215, -0.005, 0.01)
			var dirs: Array = [Vector3(0, 1, 0.1), Vector3(0.7, 0.75, 0.0), Vector3(-0.7, 0.75, 0.0), Vector3(0.4, 0.8, 0.5), Vector3(-0.4, 0.8, 0.5),
				Vector3(0.0, 0.5, 0.9), Vector3(0.6, 0.3, 0.6), Vector3(-0.6, 0.3, 0.6), Vector3(0.2, 0.9, -0.4), Vector3(-0.3, 0.85, -0.3)]
			for d in dirs:
				var dn: Vector3 = (d as Vector3).normalized()
				var root: Vector3 = _hp(0, 0.19, 0.01) + dn * 0.09
				mb.lock(root, root + dn * 0.07 + Vector3(0, 0.01, 0), root + dn * 0.15 + Vector3(0, -0.015, 0.02), 0.04, 0.03, Vector3.UP if absf(dn.y) < 0.9 else Vector3.BACK, hair, true, 4)
			_bangs(mb, hair, [-0.06, -0.015, 0.035], 0.225, 0.19, 0.03)
		_:
			# Saul: lunghi castani raccolti in coda, frangia divisa, berretto di lana
			_shell(mb, hair, 0.19, 0.0, 0.011)
			_bangs(mb, hair, [-0.07, -0.045, 0.05, 0.075], 0.205, 0.14, 0.026)
			for s in [-1.0, 1.0]:
				mb.lock(_hp(s * 0.1, 0.17, -0.04), _hp(s * 0.118, 0.1, -0.05), _hp(s * 0.112, 0.03, -0.045), 0.024, 0.014, Vector3.RIGHT, hair, true, 4)
			mb.lock(_hp(0, 0.13, 0.11), _hp(0, 0.04, 0.17), _hp(0.01, -0.13, 0.15), 0.04, 0.03, Vector3.RIGHT, hair, true, 6)
			mb.ball(Transform3D(Basis(), _hp(0, 0.135, 0.115)), 0.022, accent.darkened(0.2), true, 4, 8)
			var beanie: Color = Color("#3b4a3f")
			mb.sweep([_r(0.215 + HEAD_OFF, 0.126, 0.134, 0.012), _r(0.26 + HEAD_OFF, 0.13, 0.138, 0.01), _r(0.31 + HEAD_OFF, 0.1, 0.11, 0.015), _r(0.335 + HEAD_OFF, 0.04, 0.045, 0.02)], 18, beanie, true, false, true)
			mb.sweep([_r(0.205 + HEAD_OFF, 0.13, 0.138, 0.012), _r(0.235 + HEAD_OFF, 0.132, 0.14, 0.012)], 18, beanie.darkened(0.2), false, false, false)
			mb.box(Transform3D(Basis(Vector3.UP, 0.4), _hp(0.1, 0.23, -0.075)), Vector3(0.025, 0.02, 0.006), accent, false)


# ================================================================ braccia e gambe

static func arm(sp: Dictionary, side: float) -> MeshBatch:
	var mb := MeshBatch.new()
	mb.ink_w = 0.009
	var top: Color = Color(str(sp["top"]))
	var accent: Color = Color(str(sp["accent"]))
	var skin: Color = _a(Color(str(sp["skin"])), 0.8)
	var extra: String = str(sp["extra"])
	var fem: bool = bool(sp.get("fem", false))
	var k: float = 0.88 if fem else 1.0
	var puff: float = 0.01 if extra in ["mask", "bag"] else 0.0
	var sleeve: Color = top.darkened(0.06)
	mb.ball(Transform3D(Basis(), Vector3(0, -0.02, 0)), (0.05 + puff) * k, top, true, 6, 10)
	mb.sweep([_r(-0.01, (0.052 + puff) * k, (0.05 + puff) * k), _r(-0.15, (0.047 + puff) * k, (0.046 + puff) * k), _r(-0.29, (0.04 + puff) * k, (0.04 + puff) * k)], 10, top, true, false, false)
	var fore: Color = sleeve
	var hand: Color = skin
	if extra == "cap" and side > 0.0:
		fore = Color("#15151d")       # guanto lungo fino al gomito
		hand = Color("#15151d")
	elif extra == "cap":
		hand = Color("#15151d")
	mb.sweep([_r(-0.28, (0.04 + puff) * k, (0.04 + puff) * k), _r(-0.42, (0.038 + puff * 0.5) * k, (0.036 + puff * 0.5) * k), _r(-0.54, 0.032 * k, 0.03 * k)], 10, fore, true, false, false)
	if extra == "cap" and side > 0.0:
		mb.sweep([_r(-0.31, 0.045, 0.045), _r(-0.33, 0.045, 0.045)], 10, accent, false, false, false)
	elif extra == "bag":
		mb.sweep([_r(-0.5, 0.036, 0.034), _r(-0.55, 0.036, 0.034)], 10, top.darkened(0.3), true, false, false)
	elif extra == "coat":
		mb.sweep([_r(-0.48, 0.042, 0.04), _r(-0.55, 0.044, 0.042)], 10, top.darkened(0.12), true, false, false)
	# mano (a paletta) con il pollice
	mb.ball(Transform3D(Basis().scaled(Vector3(0.62, 1.0, 0.95)), Vector3(0, -0.6, -0.005)), 0.05 * k, hand, true, 5, 8)
	mb.ball(Transform3D(Basis(Vector3.BACK, 0.5 * side).scaled(Vector3(0.45, 1.0, 0.45)), Vector3(-side * 0.02, -0.585, -0.03)), 0.028 * k, hand, true, 4, 6)
	if side > 0.0:
		match extra:
			"coat":
				mb.sweep([_r(-0.6, 0.036, 0.036, -0.06), _r(-0.7, 0.042, 0.042, -0.06)], 10, Color("#f4efe6"), true, true, true)
				mb.sweep([_r(-0.64, 0.043, 0.043, -0.06), _r(-0.665, 0.043, 0.043, -0.06)], 10, Color("#8a5a32"), false, false, false)
			"mask":
				mb.box(Transform3D(Basis(), Vector3(0, -0.63, -0.055)), Vector3(0.055, 0.1, 0.012), Color("#1a1a22"))
				mb.box(Transform3D(Basis(), Vector3(0, -0.63, -0.062)), Vector3(0.045, 0.085, 0.002), Color(0.55, 0.4, 1.0, 0.0), false)
	elif extra == "bag":
		mb.box(Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, -0.66, -0.05)), Vector3(0.1, 0.09, 0.12), Color("#c9a36b"))
		mb.box(Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, -0.66, -0.05)), Vector3(0.104, 0.012, 0.124), Color("#5a3b26"), false)
	return mb


static func leg(sp: Dictionary, side: float) -> MeshBatch:
	var mb := MeshBatch.new()
	mb.ink_w = 0.01
	var bottom: Color = Color(str(sp["bottom"]))
	var shoes: Color = Color(str(sp["shoes"]))
	var accent: Color = Color(str(sp["accent"]))
	var extra: String = str(sp["extra"])
	var fem: bool = bool(sp.get("fem", false))
	var k: float = 0.9 if fem else 1.0
	var baggy: float = 0.012 if extra in ["bag", "cap"] else 0.0
	mb.sweep([
		_r(0.0, (0.078 + baggy) * k, (0.078 + baggy) * k),
		_r(-0.2, (0.066 + baggy) * k, (0.068 + baggy) * k),
		_r(-0.42, (0.05 + baggy) * k, (0.052 + baggy) * k, -0.004),
		_r(-0.55, (0.054 + baggy) * k, (0.056 + baggy) * k, 0.006),
		_r(-0.74, (0.038 + baggy * 0.6) * k, (0.04 + baggy * 0.6) * k),
		_r(-0.8, 0.036 * k, 0.038 * k),
	], 12, bottom, true, false, false)
	match extra:
		"mask":
			# sneakers bianche enormi
			mb.ball(Transform3D(Basis().scaled(Vector3(0.75, 0.62, 1.3)), Vector3(0, -0.835, -0.045)), 0.075, shoes, true, 6, 10)
			mb.box(Transform3D(Basis(), Vector3(0, -0.88, -0.045)), Vector3(0.11, 0.025, 0.24), Color("#d8d4e6"))
			mb.box(Transform3D(Basis(), Vector3(side * 0.052, -0.83, -0.05)), Vector3(0.006, 0.03, 0.1), Ui.YELLOW, false)
		"cap", "coat":
			# anfibi / stivali
			mb.sweep([_r(-0.66, 0.05, 0.052), _r(-0.8, 0.05, 0.054), _r(-0.84, 0.052, 0.058)], 12, shoes, true, false, false)
			mb.ball(Transform3D(Basis().scaled(Vector3(0.7, 0.55, 1.25)), Vector3(0, -0.85, -0.05)), 0.07, shoes, true, 6, 10)
			mb.box(Transform3D(Basis(), Vector3(0, -0.885, -0.04)), Vector3(0.1, 0.022, 0.22), shoes.darkened(0.4))
			if extra == "cap":
				mb.sweep([_r(-0.68, 0.052, 0.054), _r(-0.695, 0.052, 0.054)], 12, accent, false, false, false)
		_:
			mb.ball(Transform3D(Basis().scaled(Vector3(0.7, 0.55, 1.25)), Vector3(0, -0.845, -0.045)), 0.07, shoes, true, 6, 10)
			mb.box(Transform3D(Basis(), Vector3(0, -0.88, -0.04)), Vector3(0.1, 0.02, 0.21), shoes.darkened(0.4))
	return mb
