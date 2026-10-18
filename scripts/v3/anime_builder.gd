class_name AnimeBuilder
extends RefCounted

# Costruisce i personaggi tutto da codice (PROVVISORIO, in attesa dei modelli della pipeline TRELLIS.2 + Mixamo).
# Stile: docs/STILE_VISIVO.md — silhouette esagerate alla Kingdom Hearts, classi RPG (cavaliere, guardiana, giullare, ladro)
# sopra vestiti di oggi, metallo a bande, testa anime con viso a V, occhi grandi, capelli a ciocche.
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


# ================================================================ regole comuni (docs/STILE_VISIVO.md)
# Silhouette alla Kingdom Hearts: busto e gambe SOTTILI, mani e piedi ENORMI (stivali grandi quanto la testa),
# copricapo forte, un oggetto grande in diagonale. Base spenta + un solo accento saturo (colore di battaglia).

static func _m(c: Color) -> Color:
	return Color(c.r, c.g, c.b, Toon.METAL_A)


static func _c(sp: Dictionary, key: String, fallback: String = "#888888") -> Color:
	return Color(str(sp.get(key, fallback)))


# Spuntone (cono) dalla base verso dir
static func spike(mb: MeshBatch, base: Vector3, dir: Vector3, length: float, r: float, col: Color) -> void:
	var y: Vector3 = dir.normalized()
	var ref: Vector3 = Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x: Vector3 = y.cross(ref).normalized()
	var z: Vector3 = x.cross(y).normalized()
	mb.prism(Transform3D(Basis(x, y, z), base), r, 0.003, length, 6, col)


# Asta dritta da a a b (bastoni, scettri)
static func rod(mb: MeshBatch, a: Vector3, b: Vector3, r: float, col: Color) -> void:
	var y: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x: Vector3 = y.cross(ref).normalized()
	var z: Vector3 = x.cross(y).normalized()
	mb.prism(Transform3D(Basis(x, y, z), a), r, r, (b - a).length(), 8, col)


# Telo (mantello): sezioni piatte lungo un percorso, si allarga verso il fondo
static func _sheet(mb: MeshBatch, pts: Array, widths: Array, th: float, side: Vector3, col: Color) -> void:
	var secs: Array = []
	for i in pts.size():
		var p: Vector3 = pts[i]
		var tg: Vector3 = ((pts[mini(i + 1, pts.size() - 1)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)).normalized()
		var sx: Vector3 = side.normalized()
		var sz: Vector3 = tg.cross(sx).normalized()
		secs.append([p, sx, sz, float(widths[i]), th])
	mb.sweep(secs, 8, col, true, true, true)


# ================================================================ busto

static func torso(sp: Dictionary) -> MeshBatch:
	var mb := MeshBatch.new()
	mb.ink_w = 0.012
	var b: float = float(sp.get("build", 1.0))
	var fem: bool = bool(sp.get("fem", false))
	var kit: String = str(sp.get("kit", ""))
	var top: Color = _c(sp, "top")
	var bottom: Color = _c(sp, "bottom")
	var accent: Color = _c(sp, "accent")
	var metal: Color = _m(_c(sp, "metal"))
	var gold: Color = _m(_c(sp, "gold"))
	var skin: Color = _a(_c(sp, "skin"), 0.8)
	var puff: float = 0.012 if kit in ["giullare", "ladro"] else 0.0
	# busto sottile (KH): vita stretta, spalle contenute
	var wx: float = (0.098 if fem else 0.105) * b
	var hx: float = (0.122 if fem else 0.115) * b
	var cx: float = (0.118 if fem else 0.13) * b
	var sx: float = (0.13 if fem else 0.148) * b
	var pelvis: Color = metal if kit == "cavaliere" else bottom
	mb.sweep([_r(-0.07, hx * 0.9, 0.08), _r(0.0, hx, 0.086), _r(0.07, hx * 0.98, 0.084), _r(0.13, wx + 0.005, 0.078)], 14, pelvis, true, true, false)
	var rings: Array = [
		_r(0.11, wx + 0.008 + puff, 0.08 + puff),
		_r(0.2, wx + 0.01 + puff, 0.082 + puff),
		_r(0.31, cx + puff, 0.094 + puff, -0.008 if fem else -0.004),
		_r(0.40, sx + puff * 0.5, 0.086 + puff),
		_r(0.455, sx * 0.85, 0.075),
		_r(0.50, 0.072, 0.056),
		_r(0.53, 0.044, 0.041, 0.005),
	]
	mb.sweep(rings, 16, top, true, false, true)
	# collo (pelle)
	mb.sweep([_r(0.5, 0.039, 0.037, 0.012), _r(0.6, 0.035, 0.033, 0.012)], 10, skin, false, false, false)
	match kit:
		"cavaliere":
			# maglione blu a coste sotto il pettorale d'argento, spallacci (uno con spuntoni dorati), gorgiera, mantello rosso
			for i in 7:
				var x: float = lerpf(-wx * 0.8, wx * 0.8, float(i) / 6.0)
				mb.box(Transform3D(Basis(), Vector3(x, 0.19, -wx * 0.8 - 0.012)), Vector3(0.006, 0.12, 0.004), top.darkened(0.35), false)
			mb.sweep([_r(0.24, wx + 0.03, 0.095), _r(0.3, cx + 0.022, 0.108, -0.006), _r(0.39, sx + 0.012, 0.1), _r(0.45, sx * 0.88, 0.084)], 16, metal, true, true, true)
			mb.sweep([_r(0.1, wx + 0.022, 0.09), _r(0.135, wx + 0.022, 0.09)], 16, Color("#3a2a20"), false, false, false)
			mb.box(Transform3D(Basis(), Vector3(0, 0.118, -wx - 0.03)), Vector3(0.05, 0.04, 0.014), gold, false)
			for s in [-1.0, 1.0]:
				var sp_pos := Vector3(s * (sx + 0.02), 0.445, 0.0)
				mb.ball(Transform3D(Basis().scaled(Vector3(1.05, 0.62, 0.95)), sp_pos), 0.105, metal)
				mb.ball(Transform3D(Basis().scaled(Vector3(1.0, 0.5, 0.9)), sp_pos + Vector3(s * 0.02, -0.05, 0)), 0.092, metal)
				if s < 0.0:
					for k in 4:
						var a: float = lerpf(-0.7, 0.9, float(k) / 3.0)
						var d := Vector3(s * cos(a) * 0.8, 0.65 + 0.2 * sin(a), sin(a) * 0.4)
						spike(mb, sp_pos + d.normalized() * 0.07, d, 0.12, 0.03, gold)
			mb.sweep([_r(0.47, 0.08, 0.068), _r(0.57, 0.07, 0.062, 0.006)], 14, metal, true, false, false)
			# mantello rosso: dalle spalle, si gonfia dietro sul lato sinistro
			var cape: Color = accent.darkened(0.12)
			_sheet(mb, [Vector3(-0.02, 0.47, 0.09), Vector3(-0.08, 0.2, 0.2), Vector3(-0.2, -0.15, 0.3), Vector3(-0.32, -0.5, 0.36), Vector3(-0.4, -0.72, 0.32)],
				[0.16, 0.22, 0.28, 0.32, 0.3], 0.018, Vector3(1, 0, -0.35), cape)
		"guardiana":
			# cappotto lungo che diventa tunica fino agli stinchi, bordi blu, cintura con fibbia d'argento
			var coat: Color = top
			mb.sweep([_r(0.13, wx + 0.02, 0.088), _r(0.0, hx + 0.03, 0.1), _r(-0.25, hx + 0.08, 0.13, 0.01), _r(-0.55, hx + 0.14, 0.17, 0.02), _r(-0.72, hx + 0.16, 0.18, 0.025)], 16, coat.darkened(0.08), true, false, false)
			for s in [-1.0, 1.0]:
				mb.box(Transform3D(Basis(), Vector3(s * 0.012, -0.28, -0.155)), Vector3(0.014, 0.88, 0.01), _a(accent, 0.0), false)
			mb.sweep([_r(0.1, wx + 0.026, 0.094), _r(0.14, wx + 0.026, 0.094)], 16, Color("#1a1724"), false, false, false)
			mb.box(Transform3D(Basis(), Vector3(0, 0.12, -wx - 0.03)), Vector3(0.045, 0.04, 0.012), metal, false)
			mb.sweep([_r(0.46, 0.085, 0.07), _r(0.585, 0.078, 0.068, 0.01)], 14, coat.darkened(0.2), true, false, false)
			mb.box(Transform3D(Basis(), Vector3(-0.065, 0.36, -0.098)), Vector3(0.035, 0.035, 0.012), _a(accent, 0.0), false)
			for s in [-1.0, 1.0]:
				mb.ball(Transform3D(Basis().scaled(Vector3(1.0, 0.5, 0.9)), Vector3(s * (sx + 0.01), 0.44, 0.0)), 0.075, coat.darkened(0.15))
		"giullare":
			# felpa scura con rombi da arlecchino viola solo a sinistra (asimmetrico), gorgiera a punte, tasca
			for row in 4:
				for col in 2:
					var cxp: float = -0.035 - 0.05 * col - (0.025 if row % 2 == 1 else 0.0)
					var cyp: float = 0.17 + 0.075 * row
					var rh: Basis = Basis(Vector3.BACK, PI * 0.25)
					mb.box(Transform3D(rh, Vector3(cxp, cyp, -cx - puff - 0.004)), Vector3(0.034, 0.034, 0.004), accent, false)
			for k in 7:
				var a: float = TAU * float(k) / 7.0
				var d := Vector3(cos(a), -0.35, sin(a))
				spike(mb, Vector3(cos(a) * 0.07, 0.49, sin(a) * 0.06), d, 0.07, 0.03, accent if k % 2 == 0 else Color("#ece8f2"))
			mb.box(Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0, 0.17, -wx - 0.03)), Vector3(0.15, 0.075, 0.02), top.darkened(0.2))
		"ladro":
			# bomber oliva a strati, sciarpa, tracolla con borsa, amuleti con gemme tonde (rossa, gialla, blu)
			mb.sweep([_r(0.11, wx + 0.026, 0.094), _r(0.16, wx + 0.026, 0.094)], 16, top.darkened(0.3), false, false, false)
			mb.sweep([_r(0.46, 0.09, 0.075), _r(0.52, 0.085, 0.072, 0.006), _r(0.56, 0.07, 0.06, 0.008)], 14, Color("#6e5a44"), true, false, false)
			mb.lock(Vector3(-0.03, 0.5, -0.07), Vector3(-0.05, 0.38, -0.11), Vector3(-0.03, 0.22, -0.1), 0.04, 0.012, Vector3.FORWARD, Color("#6e5a44"), true, 5)
			mb.lock(Vector3(-sx * 0.75, 0.47, -0.06), Vector3(0.0, 0.3, -0.12), Vector3(sx * 0.95, 0.08, -0.04), 0.022, 0.006, Vector3.FORWARD, Color("#5a3b26"), false, 6)
			mb.box(Transform3D(Basis(Vector3.UP, 0.25), Vector3(sx * 0.95 + 0.04, 0.02, 0.0)), Vector3(0.08, 0.17, 0.22), Color("#8a5a32"))
			mb.box(Transform3D(Basis(Vector3.UP, 0.25), Vector3(sx * 0.95 + 0.085, 0.06, -0.01)), Vector3(0.02, 0.05, 0.12), _m(_c(sp, "gold")), false)
			var gems: Array = [Color(0.95, 0.2, 0.25, 0.0), Color(1.0, 0.8, 0.2, 0.0), Color(0.3, 0.6, 1.0, 0.0)]
			for i in 3:
				var gx: float = 0.02 + 0.03 * float(i)
				var gy: float = 0.36 - 0.035 * float(i)
				mb.box(Transform3D(Basis(), Vector3(gx, gy + 0.05, -0.1)), Vector3(0.003, 0.09, 0.003), Color("#d8cdb5"), false)
				mb.ball(Transform3D(Basis(), Vector3(gx, gy, -0.105)), 0.014, gems[i], true, 4, 6)
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
	if bool(sp.get("faceless", false)):
		pass                              # manichino: niente occhi ne' bocca
	elif extra == "mask" and not bool(sp.get("nomask", false)):
		_mask(mb, accent)
	else:
		_eyes(mb, sp)
	_hair(mb, style, hair, accent, sp)
	_hat(mb, sp)
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
		"knight":
			# capelli verdi che escono dall'elmo: frangia sugli occhi e ciocche ai lati
			_shell(mb, hair, 0.2, 0.03, 0.01)
			_bangs(mb, hair, [-0.07, -0.04, -0.01, 0.025, 0.06], 0.2, 0.145, 0.03)
			for s in [-1.0, 1.0]:
				mb.lock(_hp(s * 0.11, 0.17, -0.03), _hp(s * 0.125, 0.11, -0.05), _hp(s * 0.115, 0.05, -0.06), 0.03, 0.014, Vector3.RIGHT, hair, true, 4)
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
				if str(sp.get("kit", "")) != "guardiana":
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


# ================================================================ copricapi (forti, alla Kingdom Hearts)

static func _hat(mb: MeshBatch, sp: Dictionary) -> void:
	var kit: String = str(sp.get("kit", ""))
	var metal: Color = _m(_c(sp, "metal"))
	var gold: Color = _m(_c(sp, "gold"))
	var accent: Color = _c(sp, "accent")
	match kit:
		"cavaliere":
			# elmo d'argento a cupola con alette, cresta, e una grata che copre bocca e mento
			_shell(mb, metal, 0.175, 0.03, 0.026)
			mb.sweep([_r(0.17 + HEAD_OFF, 0.142, 0.15, 0.006), _r(0.2 + HEAD_OFF, 0.146, 0.154, 0.006)], 18, metal, true, false, false)
			mb.lock(_hp(0, 0.2, -0.15), _hp(0, 0.36, -0.06), _hp(0, 0.36, 0.12), 0.012, 0.03, Vector3.RIGHT, metal, true, 6)
			for s in [-1.0, 1.0]:
				for j in 2:
					var y0: float = 0.2 + 0.035 * j
					mb.lock(_hp(s * 0.14, y0, 0.02), _hp(s * 0.17, y0 + 0.045, 0.05), _hp(s * 0.19, y0 + 0.06 - 0.02 * j, 0.09), 0.034 - 0.008 * j, 0.007, Vector3.FORWARD, Color("#eef0f6"), true, 5)
				mb.ball(Transform3D(Basis().scaled(Vector3(0.5, 1.0, 1.0)), _hp(s * 0.135, 0.12, 0.0)), 0.04, metal, true, 5, 8)
			_grate(mb, metal)
		"guardiana":
			# cappuccio con orecchie da civetta (sopra i capelli)
			var hood: Color = _c(sp, "top").darkened(0.1)
			_shell(mb, hood, 0.235, -0.06, 0.03)
			for s in [-1.0, 1.0]:
				mb.lock(_hp(s * 0.075, 0.26, 0.0), _hp(s * 0.12, 0.34, -0.005), _hp(s * 0.14, 0.4, 0.02), 0.06, 0.03, Vector3.BACK, hood, true, 5)
				mb.lock(_hp(s * 0.13, 0.12, 0.03), _hp(s * 0.16, 0.0, 0.05), _hp(s * 0.15, -0.1, 0.06), 0.06, 0.02, Vector3.RIGHT, hood, true, 5)
		"giullare":
			# cappello da giullare: fascia e due corna morbide con sonagli dorati, una viola e una a scacchi chiari
			mb.sweep([_r(0.2 + HEAD_OFF, 0.13, 0.138, 0.01), _r(0.23 + HEAD_OFF, 0.133, 0.14, 0.01)], 18, Color("#2e2838"), true, false, false)
			_shell(mb, Color("#2e2838"), 0.215, 0.05, 0.03)
			for s in [-1.0, 1.0]:
				var col: Color = accent if s < 0.0 else Color("#ece8f2")
				var tip: Vector3 = _hp(s * 0.3, 0.36, 0.06)
				mb.lock(_hp(s * 0.05, 0.28, 0.0), _hp(s * 0.22, 0.46, 0.02), tip, 0.09, 0.07, Vector3.FORWARD, col, true, 7)
				mb.ball(Transform3D(Basis(), tip + Vector3(0, -0.035, 0)), 0.035, gold, true, 5, 8)
		"ladro":
			# berretto a punta che ricade dietro (da ladro), con una toppa
			var beanie: Color = Color("#3b4a3f")
			mb.sweep([_r(0.205 + HEAD_OFF, 0.13, 0.138, 0.012), _r(0.235 + HEAD_OFF, 0.132, 0.14, 0.012)], 18, beanie.darkened(0.2), true, false, false)
			_shell(mb, beanie, 0.215, 0.04, 0.02)
			mb.lock(_hp(0, 0.3, 0.02), _hp(0, 0.38, 0.14), _hp(0.02, 0.22, 0.26), 0.11, 0.08, Vector3.RIGHT, beanie, true, 7)
			mb.ball(Transform3D(Basis(), _hp(0.02, 0.21, 0.27)), 0.03, _a(accent, 1.0), true, 4, 6)
			mb.box(Transform3D(Basis(Vector3.UP, 0.4), _hp(0.1, 0.26, -0.08)), Vector3(0.03, 0.03, 0.006), Color("#7a6a4a"), false)


# Grata dell'elmo su bocca e mento
static func _grate(mb: MeshBatch, metal: Color) -> void:
	var cols: int = 12
	var rows: int = 4
	var grid: Array = []
	for i in rows + 1:
		var y: float = lerpf(-0.012, 0.072, float(i) / float(rows))
		var row: Array = []
		for j in cols + 1:
			var phi: float = lerpf(-1.45, 1.45, float(j) / float(cols))
			row.append(_head_pt(phi, y, 0.016))
		grid.append(row)
	for i in rows:
		for j in cols:
			var a: Array = grid[i][j]
			var b: Array = grid[i + 1][j]
			var c: Array = grid[i][j + 1]
			var d: Array = grid[i + 1][j + 1]
			mb._tri_smooth(a[0], b[0], c[0], a[1], b[1], c[1], metal, false)
			mb._tri_smooth(c[0], b[0], d[0], c[1], b[1], d[1], metal, false)
	for k in 5:
		var x: float = lerpf(-0.06, 0.06, float(k) / 4.0)
		_decal(mb, [Vector2(x - 0.004, 0.0), Vector2(x + 0.004, 0.0), Vector2(x + 0.004, 0.06), Vector2(x - 0.004, 0.06)], 0.02, Color(0.08, 0.06, 0.12, 0.6))
	_decal(mb, [Vector2(-0.085, 0.07), Vector2(0.085, 0.07), Vector2(0.085, 0.077), Vector2(-0.085, 0.077)], 0.02, Color(0.08, 0.06, 0.12, 0.6))


# ================================================================ braccia e gambe

static func arm(sp: Dictionary, side: float) -> MeshBatch:
	var mb := MeshBatch.new()
	mb.ink_w = 0.009
	var kit: String = str(sp.get("kit", ""))
	var top: Color = _c(sp, "top")
	var accent: Color = _c(sp, "accent")
	var metal: Color = _m(_c(sp, "metal"))
	var gold: Color = _m(_c(sp, "gold"))
	var glove: Color = _c(sp, "glove")
	var wrap: Color = _c(sp, "wrap")
	var fem: bool = bool(sp.get("fem", false))
	var k: float = 0.88 if fem else 1.0
	var upper: Color = top
	var fore: Color = top.darkened(0.06)
	if kit == "cavaliere":
		upper = wrap                           # braccia fasciate di bende
		fore = wrap
	elif kit == "giullare" and side < 0.0:
		upper = accent                         # una manica viola, l'altra scura: asimmetria da giullare
		fore = accent
	# braccio sottile
	mb.ball(Transform3D(Basis(), Vector3(0, -0.02, 0)), 0.044 * k, upper, true, 6, 10)
	mb.sweep([_r(-0.01, 0.045 * k, 0.044 * k), _r(-0.15, 0.04 * k, 0.04 * k), _r(-0.29, 0.034 * k, 0.034 * k)], 10, upper, true, false, false)
	mb.sweep([_r(-0.28, 0.034 * k, 0.034 * k), _r(-0.42, 0.032 * k, 0.031 * k), _r(-0.52, 0.029 * k, 0.028 * k)], 10, fore, true, false, false)
	match kit:
		"cavaliere":
			for i in 6:
				var y: float = -0.04 - 0.08 * float(i)
				mb.sweep([_r(y, 0.047 * k - 0.002 * i, 0.046 * k - 0.002 * i), _r(y - 0.008, 0.047 * k - 0.002 * i, 0.046 * k - 0.002 * i)], 10, wrap.darkened(0.25), false, false, false)
			# bracciale d'argento svasato
			mb.sweep([_r(-0.34, 0.04, 0.04), _r(-0.46, 0.055, 0.054), _r(-0.535, 0.075, 0.072)], 12, metal, true, true, true)
			mb.ball(Transform3D(Basis(), Vector3(0, -0.44, -0.05)), 0.014, gold, true, 4, 6)
		"guardiana":
			# maniche a campana
			mb.sweep([_r(-0.3, 0.04, 0.04), _r(-0.45, 0.06, 0.058), _r(-0.53, 0.078, 0.075)], 12, top.darkened(0.1), true, true, true)
			mb.sweep([_r(-0.52, 0.079, 0.076), _r(-0.535, 0.079, 0.076)], 12, _a(accent, 0.0), false, false, false)
		"giullare":
			mb.sweep([_r(-0.47, 0.055, 0.053), _r(-0.53, 0.06, 0.058)], 12, Color("#ece8f2"), true, true, true)
		"ladro":
			mb.sweep([_r(-0.47, 0.04, 0.038), _r(-0.53, 0.04, 0.038)], 10, top.darkened(0.3), true, false, false)
			for i in 3:
				var y2: float = -0.33 - 0.045 * float(i)
				mb.sweep([_r(y2, 0.036, 0.035), _r(y2 - 0.012, 0.036, 0.035)], 10, wrap.darkened(0.15), false, false, false)
	# mano: pugno grosso (guanto)
	var hand_c: Color = glove
	mb.ball(Transform3D(Basis().scaled(Vector3(0.85, 1.0, 1.0)), Vector3(0, -0.61, -0.008)), 0.08 * k, hand_c, true, 6, 10)
	mb.ball(Transform3D(Basis(Vector3.BACK, 0.5 * side).scaled(Vector3(0.5, 1.0, 0.5)), Vector3(-side * 0.04, -0.585, -0.055)), 0.04 * k, hand_c, true, 4, 6)
	if kit == "ladro":
		mb.sweep([_r(-0.635, 0.03, 0.03, -0.01), _r(-0.645, 0.03, 0.03, -0.01)], 8, gold, false, false, false)
	# oggetti in mano (l'arma grande attraversa il corpo in diagonale); nei ritratti i bastoni lunghi si tolgono
	var long_props: bool = not bool(sp.get("no_props", false))
	if side > 0.0:
		match kit:
			"cavaliere":
				# manico della mazza (la sfera e la catena le muove CharacterVisual)
				mb.prism(Transform3D(Basis(Vector3.RIGHT, 0.25), Vector3(0, -0.72, 0.02)), 0.022, 0.022, 0.28, 8, Color("#2b2638"))
				mb.ball(Transform3D(Basis(), Vector3(0, -0.72, 0.02)), 0.03, gold, true, 4, 6)
			"guardiana":
				# caffe' da asporto
				mb.sweep([_r(-0.6, 0.036, 0.036, -0.075), _r(-0.71, 0.043, 0.043, -0.075)], 10, Color("#f4efe6"), true, true, true)
				mb.sweep([_r(-0.645, 0.044, 0.044, -0.075), _r(-0.67, 0.044, 0.044, -0.075)], 10, Color("#8a5a32"), false, false, false)
			"giullare" when long_props:
				# scettro-asta da selfie: lungo, in diagonale, telefono in cima con alette
				var a0 := Vector3(0, -0.85, 0.12)
				var a1 := Vector3(0.05, 0.35, -0.42)
				rod(mb, a0, a1, 0.018, metal)
				mb.box(Transform3D(Basis(Vector3.RIGHT, -0.5), a1 + Vector3(0, 0.06, 0)), Vector3(0.09, 0.16, 0.016), Color("#1a1a22"))
				mb.box(Transform3D(Basis(Vector3.RIGHT, -0.5), a1 + Vector3(0, 0.06, -0.009)), Vector3(0.075, 0.135, 0.002), _a(accent.lightened(0.2), 0.0), false)
				for s2 in [-1.0, 1.0]:
					mb.lock(a1 + Vector3(s2 * 0.045, 0.06, 0), a1 + Vector3(s2 * 0.1, 0.11, 0.02), a1 + Vector3(s2 * 0.15, 0.1, 0.04), 0.035, 0.008, Vector3.FORWARD, Color("#f4f2f8"), true, 4)
			"ladro" when long_props:
				# bastone da prestigiatore col pomolo a gemma, in diagonale
				var c0 := Vector3(0, -0.95, 0.18)
				var c1 := Vector3(-0.02, 0.3, -0.36)
				rod(mb, c0, c1, 0.018, Color("#2a1d17"))
				mb.ball(Transform3D(Basis(), c1), 0.04, gold, true, 5, 8)
				mb.ball(Transform3D(Basis(), c1 + Vector3(0, 0.0, -0.035)), 0.018, _a(accent.lightened(0.2), 0.0), false, 4, 6)
	else:
		match kit:
			"guardiana" when long_props:
				# bastone con la lanterna (luce blu) in cima: lungo, in diagonale
				var l0 := Vector3(0, -0.95, 0.15)
				var l1 := Vector3(-0.04, 0.32, -0.38)
				rod(mb, l0, l1, 0.017, Color("#2b2638"))
				mb.box(Transform3D(Basis(), l1 + Vector3(0, -0.03, 0)), Vector3(0.12, 0.014, 0.014), metal)
				var lp: Vector3 = l1 + Vector3(-0.05, -0.12, 0)
				mb.prism(Transform3D(Basis(), lp + Vector3(0, -0.06, 0)), 0.045, 0.045, 0.11, 6, Color("#2b2638"))
				mb.prism(Transform3D(Basis(), lp + Vector3(0, -0.05, 0)), 0.038, 0.038, 0.09, 6, _a(accent.lightened(0.3), 0.0), false)
				mb.prism(Transform3D(Basis(), lp + Vector3(0, 0.05, 0)), 0.05, 0.005, 0.05, 6, metal)
				for s3 in [-1.0, 1.0]:
					mb.lock(lp + Vector3(s3 * 0.04, 0.03, 0), lp + Vector3(s3 * 0.09, 0.07, 0.01), lp + Vector3(s3 * 0.12, 0.06, 0.02), 0.03, 0.006, Vector3.FORWARD, Color("#f4f2f8"), true, 4)
			"ladro":
				# il pacco come reliquia: carta, spago e una luce verde che filtra
				mb.box(Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, -0.68, -0.05)), Vector3(0.12, 0.1, 0.14), Color("#c9a36b"))
				mb.box(Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, -0.68, -0.05)), Vector3(0.124, 0.014, 0.144), Color("#5a3b26"), false)
				mb.box(Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, -0.68, -0.05)), Vector3(0.014, 0.104, 0.144), Color("#5a3b26"), false)
				mb.box(Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, -0.62, -0.05)), Vector3(0.05, 0.004, 0.06), _a(accent.lightened(0.3), 0.0), false)
	return mb


static func leg(sp: Dictionary, side: float) -> MeshBatch:
	var mb := MeshBatch.new()
	mb.ink_w = 0.01
	var kit: String = str(sp.get("kit", ""))
	var bottom: Color = _c(sp, "bottom")
	var shoes: Color = _c(sp, "shoes")
	var accent: Color = _c(sp, "accent")
	var metal: Color = _m(_c(sp, "metal"))
	var gold: Color = _m(_c(sp, "gold"))
	var fem: bool = bool(sp.get("fem", false))
	var k: float = 0.9 if fem else 1.0
	var leg_c: Color = metal if kit == "cavaliere" else bottom
	if kit == "giullare" and side > 0.0:
		leg_c = accent                         # una gamba viola, l'altra a righe
	# gamba lunga e sottile
	mb.sweep([
		_r(0.0, 0.07 * k, 0.07 * k),
		_r(-0.2, 0.058 * k, 0.06 * k),
		_r(-0.42, 0.042 * k, 0.044 * k, -0.004),
		_r(-0.55, 0.045 * k, 0.047 * k, 0.006),
		_r(-0.72, 0.032 * k, 0.034 * k),
		_r(-0.78, 0.031 * k, 0.033 * k),
	], 12, leg_c, true, false, false)
	match kit:
		"cavaliere":
			# schiniere a punta sul ginocchio
			mb.ball(Transform3D(Basis().scaled(Vector3(1.0, 1.1, 0.8)), Vector3(0, -0.44, -0.03)), 0.06, metal)
			spike(mb, Vector3(0, -0.44, -0.07), Vector3(0, 0.25, -1.0), 0.09, 0.035, metal)
		"giullare":
			if side < 0.0:
				for i in 6:
					var y: float = -0.06 - 0.12 * float(i)
					mb.sweep([_r(y, 0.072 - 0.007 * i, 0.072 - 0.007 * i), _r(y - 0.05, 0.07 - 0.007 * i, 0.07 - 0.007 * i)], 12, Color("#ece8f2"), false, false, false)
		"ladro":
			# jeans strappati con toppa
			mb.box(Transform3D(Basis(), Vector3(side * 0.01, -0.3, -0.055)), Vector3(0.05, 0.05, 0.006), Color("#7a6a4a"), false)
			mb.box(Transform3D(Basis(Vector3.BACK, 0.3), Vector3(0, -0.5, -0.048)), Vector3(0.05, 0.008, 0.004), _a(_c(sp, "skin"), 0.8), false)
	# STIVALE ENORME con la punta tonda e gonfia (grande quanto la testa)
	var boot_r: float = 0.165 * (0.92 if fem else 1.0)     # piu' grande della testa (regola dello stile)
	var bk: float = boot_r / 0.14
	var boot_c: Color = shoes
	if kit == "cavaliere":
		boot_c = metal
	mb.sweep([_r(-0.6, 0.05, 0.052), _r(-0.7, 0.075 * bk, 0.078 * bk), _r(-0.79, 0.095 * bk, 0.1 * bk)], 12, boot_c, true, false, false)
	var toe := Vector3(side * 0.03, -0.81 + (boot_r - 0.14) * 0.3, -0.075 * bk)
	mb.ball(Transform3D(Basis(Vector3.UP, -side * 0.16).scaled(Vector3(0.95, 0.82, 1.5)), toe), boot_r, boot_c, true, 8, 14)
	mb.box(Transform3D(Basis(Vector3.UP, -side * 0.16), Vector3(side * 0.03, -0.915, -0.075 * bk)), Vector3(0.24 * bk, 0.028, 0.4 * bk), boot_c.darkened(0.45) if kit != "cavaliere" else Color("#3a3446"))
	match kit:
		"cavaliere":
			for i in 6:
				var a: float = lerpf(-2.4, 2.4, float(i) / 5.0)
				var d := Vector3(sin(a), 0.15, -cos(a))
				spike(mb, toe + Vector3(d.x * 0.125 * bk, -0.05, d.z * 0.19 * bk), d, 0.08, 0.026, gold)
		"guardiana":
			mb.box(Transform3D(Basis(), toe + Vector3(0, 0.1, -0.03)), Vector3(0.12, 0.022, 0.06), _a(accent, 0.0), false)
		"giullare":
			mb.box(Transform3D(Basis(Vector3.UP, -side * 0.12), toe + Vector3(side * 0.13, 0.0, 0.0)), Vector3(0.008, 0.05, 0.3), accent, false)
			mb.lock(toe + Vector3(0, 0.07, 0.16), toe + Vector3(0, 0.16, 0.26), toe + Vector3(0, 0.13, 0.34), 0.07, 0.01, Vector3.RIGHT, Color("#f4f2f8"), true, 4)
		"ladro":
			mb.sweep([_r(-0.69, 0.08, 0.083), _r(-0.715, 0.083, 0.086)], 12, _m(_c(sp, "gold")), false, false, false)
	return mb
