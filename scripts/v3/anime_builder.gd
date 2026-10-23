class_name AnimeBuilder
extends RefCounted

# Costruisce i personaggi tutto da codice (PROVVISORIO, in attesa dei modelli della pipeline TRELLIS.2 + Mixamo).
# Stile: URBANO DI OGGI (decisione dell'autore, 18/10 sera: niente look medievale). Streetwear e divise moderne,
# testa anime con viso a V, occhi grandi, capelli a ciocche, sneakers e scarpe grosse ma realistiche.
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


# ================================================================ regole comuni
# Kit moderni: tattico (Lance, LibraCorp), notturna (Nox, Civette), streamer (Rio, Masca), corriere (Saul, Magabondi).
# Silhouette leggibile sul telefono: busto snello, scarpe e mani un po' grandi, un capo d'abbigliamento riconoscibile a testa.

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
	var puff: float = 0.016 if kit in ["streamer", "corriere"] else (0.006 if kit == "tattico" else 0.0)   # felpe e bomber larghi
	# busto snello: vita stretta, spalle contenute
	var wx: float = (0.098 if fem else 0.105) * b
	var hx: float = (0.122 if fem else 0.115) * b
	var cx: float = (0.118 if fem else 0.13) * b
	var sx: float = (0.13 if fem else 0.148) * b
	var pelvis: Color = bottom
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
		"tattico":
			# divisa LibraCorp: giacca blu notte a collo alto con profili rossi, gilet tattico con tasche, cintura, distintivo
			var vest: Color = bottom.darkened(0.15)
			mb.sweep([_r(0.13, wx + 0.022, 0.092), _r(0.24, wx + 0.026, 0.096), _r(0.33, cx + 0.018, 0.106, -0.006), _r(0.41, sx * 0.9, 0.094)], 16, vest, true, true, true)
			for s2 in [-1.0, 1.0]:
				mb.box(Transform3D(Basis(), Vector3(s2 * 0.055, 0.2, -wx - 0.034)), Vector3(0.055, 0.07, 0.03), vest.lightened(0.08))
				mb.box(Transform3D(Basis(), Vector3(s2 * 0.055, 0.236, -wx - 0.05)), Vector3(0.056, 0.012, 0.012), vest.darkened(0.3), false)
				mb.box(Transform3D(Basis(Vector3.BACK, s2 * 0.5), Vector3(s2 * 0.075, 0.44, -0.06)), Vector3(0.03, 0.09, 0.01), accent, false)
			mb.sweep([_r(0.1, wx + 0.026, 0.094), _r(0.135, wx + 0.026, 0.094)], 16, Color("#14121a"), false, false, false)
			mb.box(Transform3D(Basis(), Vector3(0, 0.118, -wx - 0.03)), Vector3(0.045, 0.035, 0.012), metal, false)
			# distintivo: bilancia stilizzata bianca su placca
			mb.box(Transform3D(Basis(), Vector3(-0.06, 0.34, -0.112)), Vector3(0.045, 0.04, 0.01), Color("#14121a"), false)
			mb.box(Transform3D(Basis(), Vector3(-0.06, 0.345, -0.118)), Vector3(0.03, 0.004, 0.004), Color(0.95, 0.95, 0.95, 0.0), false)
			mb.box(Transform3D(Basis(), Vector3(-0.06, 0.336, -0.118)), Vector3(0.004, 0.022, 0.004), Color(0.95, 0.95, 0.95, 0.0), false)
			# collo alto con profilo rosso
			mb.sweep([_r(0.47, 0.08, 0.068), _r(0.565, 0.072, 0.062, 0.006)], 14, top, true, false, false)
			mb.sweep([_r(0.555, 0.073, 0.063, 0.006), _r(0.567, 0.073, 0.063, 0.006)], 14, accent, false, false, false)
		"notturna":
			# cappotto lungo delle Civette fino al ginocchio, aperto davanti, profili blu, sciarpa, cintura
			var coat: Color = top
			mb.sweep([_r(0.13, wx + 0.02, 0.088), _r(0.0, hx + 0.03, 0.1), _r(-0.22, hx + 0.07, 0.12, 0.01), _r(-0.46, hx + 0.11, 0.15, 0.02)], 16, coat.darkened(0.06), true, false, false)
			for s2 in [-1.0, 1.0]:
				mb.box(Transform3D(Basis(Vector3.BACK, s2 * 0.06), Vector3(s2 * 0.03, -0.12, -0.13)), Vector3(0.012, 0.66, 0.01), _a(accent, 0.0), false)
			mb.sweep([_r(0.1, wx + 0.026, 0.094), _r(0.14, wx + 0.026, 0.094)], 16, Color("#1a1724"), false, false, false)
			mb.box(Transform3D(Basis(), Vector3(0, 0.12, -wx - 0.03)), Vector3(0.04, 0.035, 0.012), metal, false)
			# sciarpa morbida e collo del cappotto alzato
			mb.sweep([_r(0.45, 0.092, 0.078), _r(0.5, 0.088, 0.076, 0.006), _r(0.55, 0.075, 0.066, 0.008)], 14, Color("#4a4766"), true, false, false)
			mb.lock(Vector3(0.04, 0.5, -0.07), Vector3(0.06, 0.4, -0.1), Vector3(0.05, 0.28, -0.1), 0.045, 0.014, Vector3.FORWARD, Color("#4a4766"), true, 5)
			# distintivo delle Civette (luce blu)
			mb.box(Transform3D(Basis(), Vector3(-0.065, 0.36, -0.1)), Vector3(0.032, 0.032, 0.012), _a(accent, 0.0), false)
		"streamer":
			# felpa oversize con cappuccio abbassato dietro, lacci gialli, tasca a marsupio, adesivi
			mb.sweep([_r(0.43, 0.115, 0.1, 0.03), _r(0.5, 0.105, 0.095, 0.05), _r(0.56, 0.08, 0.075, 0.06)], 14, top.darkened(0.12), true, false, true)
			for s2 in [-1.0, 1.0]:
				mb.lock(Vector3(s2 * 0.03, 0.47, -0.085), Vector3(s2 * 0.035, 0.4, -0.11), Vector3(s2 * 0.03, 0.33, -0.112), 0.008, 0.006, Vector3.FORWARD, accent, false, 4)
			mb.box(Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0, 0.16, -wx - 0.035)), Vector3(0.16, 0.08, 0.02), top.darkened(0.18))
			mb.box(Transform3D(Basis(Vector3.BACK, 0.3), Vector3(0.07, 0.33, -0.112)), Vector3(0.035, 0.035, 0.004), accent, false)
			mb.box(Transform3D(Basis(Vector3.BACK, -0.2), Vector3(-0.07, 0.28, -0.11)), Vector3(0.03, 0.022, 0.004), Color("#f4f2f8"), false)
			mb.sweep([_r(0.1, wx + 0.03 + puff, 0.094 + puff), _r(0.14, wx + 0.03 + puff, 0.094 + puff)], 16, top.darkened(0.2), false, false, false)
		"corriere":
			# bomber verde sopra una felpa grigia col cappuccio fuori, polsini a coste, collo arancio, tracolla, collana di amuleti
			var hoodie := Color("#6b6f7a")
			mb.sweep([_r(0.45, 0.1, 0.09, 0.035), _r(0.52, 0.095, 0.085, 0.05), _r(0.57, 0.075, 0.07, 0.06)], 14, hoodie, true, false, true)
			mb.box(Transform3D(Basis(), Vector3(0, 0.3, -cx - puff - 0.002)), Vector3(0.05, 0.36, 0.006), hoodie, false)
			mb.sweep([_r(0.1, wx + 0.03 + puff, 0.094 + puff), _r(0.15, wx + 0.03 + puff, 0.094 + puff)], 16, top.darkened(0.3), false, false, false)
			mb.sweep([_r(0.455, 0.1, 0.085), _r(0.475, 0.1, 0.085)], 14, accent, false, false, false)
			mb.lock(Vector3(-sx * 0.75, 0.47, -0.06), Vector3(0.0, 0.3, -0.12), Vector3(sx * 0.95, 0.08, -0.04), 0.022, 0.006, Vector3.FORWARD, Color("#3a2a20"), false, 6)
			mb.box(Transform3D(Basis(Vector3.UP, 0.25), Vector3(sx * 0.95 + 0.04, 0.02, 0.0)), Vector3(0.08, 0.17, 0.22), Color("#2a2a30"))
			mb.box(Transform3D(Basis(Vector3.UP, 0.25), Vector3(sx * 0.95 + 0.085, 0.06, -0.01)), Vector3(0.02, 0.03, 0.12), accent, false)
			var gems: Array = [Color(0.95, 0.2, 0.25, 0.0), Color(1.0, 0.8, 0.2, 0.0), Color(0.3, 0.6, 1.0, 0.0)]
			for i in 3:
				var gx: float = 0.02 + 0.03 * float(i)
				var gy: float = 0.36 - 0.035 * float(i)
				mb.box(Transform3D(Basis(), Vector3(gx, gy + 0.05, -0.1)), Vector3(0.003, 0.09, 0.003), Color("#d8cdb5"), false)
				mb.ball(Transform3D(Basis(), Vector3(gx, gy, -0.105)), 0.012, gems[i], true, 4, 6)
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
		_mask(mb, accent, bool(sp.get("mask_crack", false)))
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


static func _mask(mb: MeshBatch, accent: Color, cracked: bool = false) -> void:
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
	if cracked:
		_mask_crack(mb)


# Dopo il capitolo 3 (Vetrina) la maschera di Rio si incrina invece di cadere: una crepa dalla fronte all'occhio destro
# e, dentro, un occhio vero («Da qui si vede... un occhio. Il mio.»). Toglierla resta il climax del suo arco (U18).
static func _mask_crack(mb: MeshBatch) -> void:
	var ink := Color(0.12, 0.07, 0.16, 0.6)
	var line: Array = [Vector2(0.018, 0.19), Vector2(0.036, 0.165), Vector2(0.026, 0.145), Vector2(0.05, 0.128), Vector2(0.043, 0.112)]
	for i in line.size() - 1:
		var a: Vector2 = line[i]
		var b: Vector2 = line[i + 1]
		var n: Vector2 = Vector2(-(b - a).y, (b - a).x).normalized() * 0.0028
		_decal(mb, [a + n, b + n, b - n, a - n], 0.0175, ink)
	_decal(mb, [Vector2(0.036, 0.165), Vector2(0.02, 0.158), Vector2(0.021, 0.155), Vector2(0.036, 0.161)], 0.0175, ink)
	# l'occhio che si vede dalla crepa: bianco, iride viola (il suo colore), pupilla e riflesso
	_decal(mb, _ellipse(Vector2(0.05, 0.104), 0.019, 0.011), 0.018, Color(0.98, 0.97, 1.0, 0.6))
	_decal(mb, _ellipse(Vector2(0.049, 0.104), 0.009, 0.0102), 0.0185, Color(0.62, 0.3, 0.95, 0.6))
	_decal(mb, _ellipse(Vector2(0.049, 0.104), 0.0042, 0.0054), 0.019, Color(0.1, 0.05, 0.15, 0.6))
	_decal(mb, _ellipse(Vector2(0.046, 0.108), 0.002, 0.002, 6), 0.0195, Color(1.0, 1.0, 1.0, 0.0))


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


# ================================================================ copricapi (silhouette forti, abiti di oggi)

static func _hat(mb: MeshBatch, sp: Dictionary) -> void:
	var kit: String = str(sp.get("kit", ""))
	var accent: Color = _c(sp, "accent")
	match kit:
		"corriere":
			# berretto di lana con risvolto e una toppa
			var beanie: Color = Color("#2d4a38")
			mb.sweep([_r(0.205 + HEAD_OFF, 0.13, 0.138, 0.012), _r(0.24 + HEAD_OFF, 0.133, 0.141, 0.012)], 18, beanie.darkened(0.2), true, false, false)
			_shell(mb, beanie, 0.215, 0.04, 0.02)
			mb.box(Transform3D(Basis(Vector3.UP, 0.4), _hp(0.1, 0.26, -0.085)), Vector3(0.03, 0.025, 0.006), accent, false)


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
	var puff: float = 0.01 if kit in ["streamer", "corriere"] else 0.0
	# braccio snello (maniche larghe per felpa e bomber)
	mb.ball(Transform3D(Basis(), Vector3(0, -0.02, 0)), 0.046 * k + puff, upper, true, 6, 10)
	mb.sweep([_r(-0.01, 0.047 * k + puff, 0.046 * k + puff), _r(-0.15, 0.042 * k + puff, 0.042 * k + puff), _r(-0.29, 0.037 * k + puff, 0.037 * k + puff)], 10, upper, true, false, false)
	mb.sweep([_r(-0.28, 0.037 * k + puff, 0.037 * k + puff), _r(-0.42, 0.035 * k + puff, 0.034 * k + puff), _r(-0.5, 0.033 * k + puff, 0.032 * k + puff)], 10, fore, true, false, false)
	match kit:
		"tattico":
			# fascia rossa al braccio sinistro; guanto lungo fino al gomito a destra (il braccio segreto)
			if side < 0.0:
				mb.sweep([_r(-0.1, 0.05, 0.049), _r(-0.16, 0.05, 0.049)], 10, accent, false, false, false)
			else:
				mb.sweep([_r(-0.3, 0.04, 0.04), _r(-0.5, 0.039, 0.038)], 10, glove, true, false, false)
			mb.sweep([_r(-0.48, 0.039, 0.038), _r(-0.52, 0.039, 0.038)], 10, top.darkened(0.3), false, false, false)
		"notturna":
			# polsini col profilo blu
			mb.sweep([_r(-0.46, 0.046, 0.045), _r(-0.52, 0.048, 0.047)], 12, top.darkened(0.12), true, false, true)
			mb.sweep([_r(-0.505, 0.049, 0.048), _r(-0.515, 0.049, 0.048)], 12, _a(accent, 0.0), false, false, false)
		"streamer":
			# polsino a coste e braccialetti
			mb.sweep([_r(-0.47, 0.044, 0.043), _r(-0.52, 0.04, 0.039)], 10, top.darkened(0.2), true, false, false)
			if side < 0.0:
				mb.sweep([_r(-0.535, 0.032, 0.032), _r(-0.545, 0.032, 0.032)], 8, accent, false, false, false)
		"corriere":
			mb.sweep([_r(-0.46, 0.044, 0.043), _r(-0.52, 0.04, 0.039)], 10, top.darkened(0.3), true, false, false)
	# mano (un po' grande, si legge meglio): guanto per Lance, mano nuda per gli altri
	var hand_c: Color = glove if kit == "tattico" else _a(_c(sp, "skin"), 0.8)
	mb.ball(Transform3D(Basis().scaled(Vector3(0.85, 1.0, 1.0)), Vector3(0, -0.585, -0.008)), 0.064 * k, hand_c, true, 6, 10)
	mb.ball(Transform3D(Basis(Vector3.BACK, 0.5 * side).scaled(Vector3(0.5, 1.0, 0.5)), Vector3(-side * 0.032, -0.565, -0.045)), 0.032 * k, hand_c, true, 4, 6)
	if kit == "corriere":
		mb.sweep([_r(-0.605, 0.024, 0.024, -0.01), _r(-0.613, 0.024, 0.024, -0.01)], 8, gold, false, false, false)
	var long_props: bool = not bool(sp.get("no_props", false))
	if side > 0.0:
		match kit:
			"tattico" when long_props:
				# manganello elettrico LibraCorp, impugnato verso il basso, con la striscia rossa accesa
				var b0 := Vector3(0, -0.6, -0.02)
				var b1 := Vector3(0.02, -1.02, -0.2)
				rod(mb, b0, b1, 0.02, Color("#1c1e26"))
				rod(mb, b0.lerp(b1, 0.3), b0.lerp(b1, 0.95), 0.008, Color(1.0, 0.25, 0.3, 0.0))
				mb.prism(Transform3D(Basis(), b0 + Vector3(0, 0.02, 0)), 0.026, 0.026, 0.03, 8, Color("#3a3d48"))
			"notturna":
				# caffe' da asporto
				mb.sweep([_r(-0.58, 0.034, 0.034, -0.065), _r(-0.69, 0.041, 0.041, -0.065)], 10, Color("#f4efe6"), true, true, true)
				mb.sweep([_r(-0.625, 0.042, 0.042, -0.065), _r(-0.65, 0.042, 0.042, -0.065)], 10, Color("#8a5a32"), false, false, false)
			"streamer":
				# telefono in mano, schermo acceso
				mb.box(Transform3D(Basis(Vector3.RIGHT, -0.4), Vector3(0, -0.62, -0.07)), Vector3(0.075, 0.14, 0.012), Color("#1a1a22"))
				mb.box(Transform3D(Basis(Vector3.RIGHT, -0.4), Vector3(0, -0.62, -0.078)), Vector3(0.062, 0.12, 0.002), _a(accent.lightened(0.3), 0.0), false)
	else:
		match kit:
			"corriere":
				# il pacco: carta, spago e una luce verde che filtra
				mb.box(Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, -0.66, -0.05)), Vector3(0.12, 0.1, 0.14), Color("#c9a36b"))
				mb.box(Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, -0.66, -0.05)), Vector3(0.124, 0.014, 0.144), Color("#5a3b26"), false)
				mb.box(Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, -0.66, -0.05)), Vector3(0.014, 0.104, 0.144), Color("#5a3b26"), false)
				mb.box(Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, -0.6, -0.05)), Vector3(0.05, 0.004, 0.06), Color(0.35, 0.95, 0.5, 0.0), false)
	return mb


static func leg(sp: Dictionary, side: float) -> MeshBatch:
	var mb := MeshBatch.new()
	mb.ink_w = 0.01
	var kit: String = str(sp.get("kit", ""))
	var bottom: Color = _c(sp, "bottom")
	var shoes: Color = _c(sp, "shoes")
	var accent: Color = _c(sp, "accent")
	var fem: bool = bool(sp.get("fem", false))
	var k: float = 0.9 if fem else 1.0
	var baggy: float = 0.012 if kit in ["streamer", "corriere"] else 0.0     # pantaloni larghi / cargo
	mb.sweep([
		_r(0.0, 0.072 * k + baggy, 0.072 * k + baggy),
		_r(-0.2, 0.06 * k + baggy, 0.062 * k + baggy),
		_r(-0.42, 0.046 * k + baggy, 0.048 * k + baggy, -0.004),
		_r(-0.55, 0.047 * k + baggy, 0.049 * k + baggy, 0.006),
		_r(-0.72, 0.04 * k + baggy, 0.042 * k + baggy),
		_r(-0.78, 0.042 * k + baggy, 0.044 * k + baggy),
	], 12, bottom, true, false, false)
	match kit:
		"tattico":
			# tasca laterale e ginocchiera
			mb.box(Transform3D(Basis(), Vector3(side * 0.06, -0.24, 0.0)), Vector3(0.02, 0.09, 0.07), bottom.darkened(0.2))
			mb.ball(Transform3D(Basis().scaled(Vector3(1.0, 1.1, 0.6)), Vector3(0, -0.45, -0.035)), 0.045, Color("#14121a"))
		"corriere":
			# cargo con tasconi laterali, una toppa
			mb.box(Transform3D(Basis(), Vector3(side * 0.07, -0.3, 0.0)), Vector3(0.024, 0.11, 0.085), bottom.darkened(0.15))
			mb.box(Transform3D(Basis(), Vector3(side * 0.01, -0.5, -0.06)), Vector3(0.05, 0.05, 0.006), Color("#7a6a4a"), false)
		"streamer":
			# strappo sul ginocchio sinistro
			if side < 0.0:
				mb.box(Transform3D(Basis(Vector3.BACK, 0.3), Vector3(0, -0.47, -0.062)), Vector3(0.05, 0.01, 0.004), _a(_c(sp, "skin"), 0.8), false)
	# scarpe: grosse e moderne (sneakers / anfibi), suola chiara
	var sneaker: bool = kit in ["streamer", "corriere"]
	var boot_r: float = (0.13 if sneaker else 0.118) * (0.92 if fem else 1.0)
	var bk: float = boot_r / 0.12
	if not sneaker:
		mb.sweep([_r(-0.62, 0.048, 0.05), _r(-0.72, 0.062, 0.065), _r(-0.8, 0.07, 0.074)], 12, shoes, true, false, false)
	var toe := Vector3(side * 0.01, -0.83, -0.06 * bk)
	mb.ball(Transform3D(Basis(Vector3.UP, -side * 0.08).scaled(Vector3(0.85, 0.7, 1.45)), toe), boot_r, shoes, true, 8, 14)
	var sole: Color = Color("#f2f0ea") if sneaker else Color("#2a2730")
	# suola arrotondata che segue la scarpa (niente lastra squadrata)
	mb.ball(Transform3D(Basis(Vector3.UP, -side * 0.08).scaled(Vector3(0.9, 0.2, 1.5)), Vector3(side * 0.01, -0.9, -0.06 * bk)), boot_r * 1.04, sole, true, 4, 14)
	if sneaker:
		# baffo colorato sul lato e lacci
		mb.box(Transform3D(Basis(Vector3.UP, -side * 0.08), toe + Vector3(side * 0.1 * bk, -0.01, 0.02)), Vector3(0.006, 0.035, 0.16 * bk), accent, false)
		for i in 3:
			mb.box(Transform3D(Basis(Vector3.RIGHT, -0.5), toe + Vector3(0, 0.07, -0.02 - 0.035 * i)), Vector3(0.07, 0.008, 0.012), Color("#f4f2f8"), false)
	return mb
