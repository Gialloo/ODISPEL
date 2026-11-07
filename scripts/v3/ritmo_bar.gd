class_name RitmoBar
extends Control

# RITMO DI SQUADRA a schermo (HUD 0.61, P0-A, mockup approvato dall'autore il 7/11/2026).
# Una barra a quattro tratti (CALMO, ACCESO, INCANDESCENTE, APICE) sopra la fila della squadra, nell'HUD col ritratto.
# Non somiglia alla barra dell'ULTIMATE (sottile, dentro le card): e' larga quanto la squadra, storta, con le tacche dei livelli.
# Ogni livello si riconosce a colpo d'occhio:
#   CALMO          grigio acciaio, niente alone (discreto)
#   ACCESO         arancio con alone leggero
#   INCANDESCENTE  rosso fuoco, frecce di calore che scorrono, alone piu' forte
#   APICE          oro con riga bianca ed emblema a stella che pulsa piano (una volta al secondo, niente lampeggi)
# Soglia raggiunta ma condizione mancante (Ritmo "ready"): il tratto dopo ha il bordo tratteggiato e sopra c'e' cosa fare,
# col testo vero della condizione (Ritmo.CONDS). Nessuna previsione: solo lo stato del motore.
# PRESTAZIONI: un solo _draw; ridisegna ogni fotogramma solo a INCANDESCENTE/APICE o durante il lampo del cambio di livello.

const INK: Color = Color("#120a1c")
const CREAM: Color = Color("#fff4dc")
const HOT: Color = Color("#ffd23f")
const W_PARTY: float = 410.0        # larghezza della fila della squadra (4 card da 92 + 3 spazi da 14)
const H: float = 13.0                # altezza del riempimento
const SK: float = 7.0                # inclinazione dei tratti
const LV: Array = [
	{"fill": Color8(125, 138, 166), "txt": Color8(190, 198, 216), "glow": Color(0, 0, 0, 0), "size": 17},
	{"fill": Color8(255, 154, 46), "txt": Color8(255, 170, 70), "glow": Color8(255, 150, 40, 70), "size": 19},
	{"fill": Color8(255, 70, 30), "txt": Color8(255, 120, 50), "glow": Color8(255, 80, 20, 110), "size": 19},
	{"fill": Color8(255, 210, 63), "txt": Color8(255, 210, 63), "glow": Color8(255, 210, 63, 150), "size": 23},
]

var level: int = 0
var ardore: int = 0
var is_ready: bool = false
var hint: String = ""              # "per INCANDESCENTE: manda il nemico in BREAK" (solo con ready)
var _t: float = 0.0
var _flash: float = 0.0            # lampo breve quando il livello cambia
var _sig: String = ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process(false)


# Legge lo stato del RITMO dal motore (nessun calcolo qui: la UI mostra, non decide).
func set_state(state: Dictionary) -> void:
	visible = BattleTypes.RITMO_ON and not bool(state.get("pvp", false))      # dove il RITMO e' spento (PvP) niente barra vuota
	if not visible:
		return
	var lv: int = Ritmo.level(state)
	var ar: int = Ritmo.ardore(state)
	var rd: bool = bool(Ritmo.st(state).get("ready", false)) and lv < Ritmo.APICE
	var h: String = ""
	if rd:
		for c in Ritmo.next_conds(state):
			if not Ritmo.cond_ok(state, c):
				var tx: String = str(c["text"])
				h = "per %s: %s" % [Ritmo.level_name(lv + 1), tx.substr(0, 1).to_lower() + tx.substr(1)]
				break
	set_values(lv, ar, rd, h)


func set_values(lv: int, ar: int, rd: bool, h: String) -> void:
	var sig: String = "%d|%d|%s|%s" % [lv, ar, rd, h]
	if sig == _sig:
		return
	if _sig != "" and lv != level:
		_flash = 0.6
	_sig = sig
	level = clampi(lv, 0, 3)
	ardore = clampi(ar, 0, BattleTypes.RITMO_CAP)
	is_ready = rd
	hint = h
	set_process(level >= Ritmo.INCANDESCENTE or _flash > 0.0)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta)
	if level < Ritmo.INCANDESCENTE and _flash <= 0.0:
		set_process(false)
	queue_redraw()


func _slant(x: float, y: float, w: float, h: float, sk: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x + sk, y), Vector2(x + w, y), Vector2(x + w - sk, y + h), Vector2(x, y + h)])


func _draw() -> void:
	if Settings.hud_foto:
		_draw_badge()
		return
	var st: Dictionary = LV[level]
	var x0: float = size.x - 22.0 - W_PARTY
	var w: float = W_PARTY
	var x1: float = x0 + w
	var yb: float = size.y - PortraitParty.top() - 42.0       # sopra la squadra (con le card grandi della foto sale)
	var fd: Font = Ui.display()
	var fb: Font = Ui.body()
	var fill: Color = st["fill"]
	if _flash > 0.0:
		fill = fill.lerp(Color.WHITE, _flash / 0.6 * 0.6)
	# alone (piu' forte a ogni livello), ombra e fondo
	var frame: PackedVector2Array = _slant(x0 - 3, yb - 3, w + 6, H + 6, SK)
	var gl: Color = st["glow"]
	if gl.a > 0.0:
		var pulse: float = 1.0
		if level == Ritmo.APICE:
			pulse = 0.75 + 0.25 * sin(_t * TAU)       # pulsa piano, una volta al secondo
		for r in [7.0, 4.0]:
			var g: Color = gl
			g.a *= 0.5 * pulse
			draw_colored_polygon(_slant(x0 - 3 - r, yb - 3 - r * 0.6, w + 6 + r * 2, H + 6 + r * 1.2, SK), g)
	var sh := PackedVector2Array()
	for q in frame:
		sh.append(q + Vector2(4, 4))
	draw_colored_polygon(sh, Color(INK, 0.9))
	draw_colored_polygon(frame, Color8(10, 6, 16, 235))
	# quattro tratti (25/50/75/100) con una tacca tra un livello e l'altro
	var k: float = clampf(float(ardore) / float(BattleTypes.RITMO_CAP), 0.0, 1.0)
	var seg: float = w / 4.0
	var sk2: float = SK * H / (H + 6.0)
	for i in 4:
		var sx: float = x0 + i * seg + (2.0 if i > 0 else 0.0)
		var sw: float = seg - (4.0 if i < 3 else 2.0)
		draw_colored_polygon(_slant(sx, yb, sw, H, sk2), Color8(40, 34, 52))
		var fw: float = minf(sw, x0 + w * k - sx)
		if fw <= 1.0:
			continue
		draw_colored_polygon(_slant(sx, yb, fw, H, minf(sk2, fw * 0.5)), fill)
		if level == Ritmo.INCANDESCENTE:
			# calore: frecce chiare che scorrono verso destra dentro il riempimento
			var off: float = fmod(_t * 28.0, 16.0)
			var j: float = off
			while j + 6.0 < fw:
				var cx: float = sx + 2.0 + j
				draw_polyline(PackedVector2Array([Vector2(cx, yb + 3), Vector2(cx + 5, yb + H * 0.5), Vector2(cx, yb + H - 3)]), Color8(255, 230, 150, 230), 2.0)
				j += 16.0
		elif level == Ritmo.APICE:
			draw_line(Vector2(sx + 3, yb + H * 0.42), Vector2(sx + fw - 2, yb + H * 0.42), Color8(255, 255, 240), 2.5)
	for i in range(1, 4):
		var tx: float = x0 + i * seg
		draw_line(Vector2(tx + 3, yb - 7), Vector2(tx + 1, yb - 1), Color(CREAM, 0.67), 2.0)
	# soglia raggiunta, manca la condizione: il tratto dopo ha il bordo tratteggiato giallo
	if is_ready:
		var nx: float = x0 + mini(3, level + 1) * seg
		var j2: float = 0.0
		while j2 < seg - 4.0:
			draw_line(Vector2(nx + j2 + SK, yb - 2), Vector2(nx + j2 + 5 + SK, yb - 2), HOT, 2.0)
			draw_line(Vector2(nx + j2, yb + H + 2), Vector2(nx + j2 + 5, yb + H + 2), HOT, 2.0)
			j2 += 10.0
	# scritte: RITMO + LIVELLO a sinistra, ARDORE a destra, cosa fare sopra
	var ly: float = yb - 9.0
	draw_string_outline(fb, Vector2(x0, ly), "RITMO", HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT, 5, INK)
	draw_string(fb, Vector2(x0, ly), "RITMO", HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT, Color(CREAM, 0.85))
	var lx: float = x0 + fb.get_string_size("RITMO", HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT).x + 8.0
	var nm: String = Ritmo.level_name(level)
	draw_string_outline(fd, Vector2(lx, ly + 1), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, int(st["size"]), 6, INK)
	draw_string(fd, Vector2(lx, ly + 1), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, int(st["size"]), st["txt"])
	var at: String = "ARDORE %d" % ardore
	var aw: float = fb.get_string_size(at, HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT).x
	draw_string_outline(fb, Vector2(x1 - aw, ly), at, HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT, 5, INK)
	draw_string(fb, Vector2(x1 - aw, ly), at, HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT, Color(CREAM, 0.85))
	if is_ready and hint != "":
		var hs: String = "> " + hint
		# allineata a destra: una condizione lunga cresce verso sinistra, sopra la scena libera, e non si taglia
		var hx: float = minf(x0, x1 - fb.get_string_size(hs, HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT).x)
		draw_string_outline(fb, Vector2(hx, ly - 21), hs, HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT, 6, INK)
		draw_string(fb, Vector2(hx, ly - 21), hs, HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT, HOT)
	if level == Ritmo.APICE:
		# emblema dell'APICE: stella a quattro punte oro in fondo alla barra
		var c := Vector2(x1 + 8, yb + H * 0.5)
		var r: float = 11.0 * (0.92 + 0.08 * sin(_t * TAU))
		var pts := PackedVector2Array()
		for i in 8:
			var a: float = -PI / 2.0 + i * PI / 4.0
			pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.38))
		draw_colored_polygon(pts, HOT)
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color.WHITE, 1.5)


# RITMO come la barra viola della foto dell'autore (7/11/2026, "SCHEGGIA 80"): lastra viola storta sul lato destro, nome del
# livello grande, sotto cosa serve per salire (la condizione vera del motore), ARDORE in numero giallo enorme con la stella.
# Sotto la lastra una striscia del colore del livello si riempie con l'ARDORE. Stessi dati, nessuna previsione in piu'.
func _draw_badge() -> void:
	var st: Dictionary = LV[level]
	var fd: Font = Ui.display()
	var fb: Font = Ui.body()
	var w: float = 440.0
	var h: float = 74.0
	var x0: float = size.x - 150.0 - w        # a sinistra della colonna ORDINE
	var y0: float = size.y * 0.34         # sotto la prossima mossa del nemico, sopra REAZIONE
	var pl := PackedVector2Array([Vector2(x0 + 22, y0), Vector2(x0 + w, y0 - 8), Vector2(x0 + w - 22, y0 + h - 6), Vector2(x0, y0 + h)])
	var sh := PackedVector2Array()
	for q in pl:
		sh.append(q + Vector2(6, 6))
	draw_colored_polygon(sh, Color(INK, 0.9))
	var base: Color = Color("#5b1fb8").lerp(Color.WHITE, _flash / 0.6 * 0.4) if _flash > 0.0 else Color("#5b1fb8")
	draw_colored_polygon(pl, base)
	# taglio chiaro in diagonale (la luce della lastra del riferimento)
	draw_colored_polygon(PackedVector2Array([Vector2(x0 + w * 0.55, y0 - 4), Vector2(x0 + w * 0.72, y0 - 6), Vector2(x0 + w * 0.6, y0 + h - 3), Vector2(x0 + w * 0.43, y0 + h - 1)]), Color(0.7, 0.4, 1.0, 0.35))
	draw_polyline(pl + PackedVector2Array([pl[0]]), Color(CREAM, 0.85), 2.0, true)
	var nm: String = "RITMO · " + Ritmo.level_name(level)
	draw_set_transform(Vector2(x0 + 26, y0 + 32), -0.05)
	draw_string_outline(fd, Vector2.ZERO, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 7, INK)
	draw_string(fd, Vector2.ZERO, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, CREAM)
	var sub: String = hint if hint != "" else "ARDORE della squadra"
	var room: float = w - 170.0          # il numero e la stella stanno a destra
	while sub.length() > 8 and fb.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT).x > room:
		sub = sub.substr(0, sub.length() - 2)
	if sub != (hint if hint != "" else "ARDORE della squadra"):
		sub = sub.strip_edges() + "…"
	draw_string_outline(fb, Vector2(2, 24), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT, 5, INK)
	draw_string(fb, Vector2(2, 24), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, HudLayers.MIN_TEXT, HOT if is_ready else CREAM)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# numero enorme dell'ARDORE con la stella
	var ns: String = str(ardore)
	var nsz: int = 64
	var nw: float = fd.get_string_size(ns, HORIZONTAL_ALIGNMENT_LEFT, -1, nsz).x
	var np := Vector2(x0 + w - 44.0 - nw, y0 + h - 4.0)
	draw_set_transform(np, -0.1)
	draw_string_outline(fd, Vector2(4, 4), ns, HORIZONTAL_ALIGNMENT_LEFT, -1, nsz, 12, Color("#2a0a5e"))
	draw_string_outline(fd, Vector2.ZERO, ns, HORIZONTAL_ALIGNMENT_LEFT, -1, nsz, 9, INK)
	draw_string(fd, Vector2.ZERO, ns, HORIZONTAL_ALIGNMENT_LEFT, -1, nsz, HOT)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var sc := Vector2(x0 + w - 22.0, y0 + 18.0)
	var pulse: float = 1.0 + (0.12 * sin(_t * TAU) if level == Ritmo.APICE else 0.0)
	for pass_i in 2:
		var pts := PackedVector2Array()
		var rr: float = (22.0 if pass_i == 0 else 18.0) * pulse
		for k in 10:
			pts.append(sc + Vector2.from_angle(-PI / 2.0 + k * PI / 5.0) * (rr if k % 2 == 0 else rr * 0.45))
		draw_colored_polygon(pts, INK if pass_i == 0 else Color("#c77dff"))
	# striscia del livello sotto la lastra, a quattro tratti (25/50/75/100)
	var k2: float = clampf(float(ardore) / float(BattleTypes.RITMO_CAP), 0.0, 1.0)
	var by: float = y0 + h + 6.0
	var seg: float = (w - 60.0) / 4.0
	for i in 4:
		var sx: float = x0 + 10.0 + i * seg
		draw_colored_polygon(_slant(sx, by, seg - 5.0, 9.0, 4.0), Color(INK, 0.85))
		var fw: float = minf(seg - 5.0, x0 + 10.0 + (w - 60.0) * k2 - sx)
		if fw > 1.0:
			draw_colored_polygon(_slant(sx, by, fw, 9.0, minf(4.0, fw * 0.5)), st["fill"])
