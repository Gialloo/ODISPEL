class_name PortraitParty
extends Control

# Squadra e ordine dei turni dell'HUD col ritratto (riferimento dell'autore, 2/11/2026, remake di Persona 1):
# - in basso a destra una fila di ritratti storti con PV ed EN e due barrette (vita verde, ULTIMATE rosa/gialla);
# - sul bordo destro la colonna ORDINE: una lastrina per turno con la striscia degli occhi, chi agisce ora e' piu' grande.
# Tutto in un _draw solo, rifatto solo quando cambiano i dati (PRESTAZIONI). I dati li passa battle3d (set_party, set_order).
# Ritratto piccolo: res://assets/portraits/hud/<id>_volto.png se c'e', altrimenti il mezzobusto <id>_neutro.png ritagliato.

const INK: Color = Color("#120a1c")
const CREAM: Color = Color("#fff4dc")
const HOT: Color = Color("#ffd23f")
const RED: Color = Color("#ff2340")
const CW: float = 92.0          # larghezza di una card della squadra
const CW_FOTO: float = 118.0    # HUD come la foto dell'autore (Settings.hud_foto): card piu' grandi, cornice del colore
const FH_FOTO: float = 100.0    # altezza del volto nella card grande


static func cw() -> float:
	return CW_FOTO if Settings.hud_foto else CW


# Larghezza vera della colonna ORDINE dal bordo destro (HUD Combat 2.0): lastrina di chi agisce larga 92, 10 di margine,
# freccia a 40 dalla lastrina. Chi deve stare accanto all'ORDINE (pannello del nemico) usa questa misura, non una stima.
const ORDINE_LASTRA: float = 92.0
const ORDINE_BORDO: float = 10.0
const ORDINE_FRECCIA: float = 40.0


static func order_width() -> float:
	return ORDINE_BORDO + ORDINE_LASTRA + ORDINE_FRECCIA


# Altezza dalla base dello schermo al bordo alto della card (per chi deve stare sopra la squadra).
static func top() -> float:
	return 160.0 if Settings.hud_foto else 128.0
const FACE: Rect2 = Rect2(112, 128, 290, 270)      # volto dentro al mezzobusto 512x768 (segnaposto)
const EYES: Rect2 = Rect2(120, 270, 290, 110)      # striscia degli occhi per la colonna ORDINE

var party: Array = []           # {id, name, col, hp, max_hp, en, gauge, gmax, active, alive, marked, tgt}
var order: Array = []           # {id, name, col, boss, now}
var order_on: bool = true
var round_n: int = 1
var _tex: Dictionary = {}
var boss_face: Texture2D        # HUD Combat 2.0, decisione 3: il volto del nemico nella colonna ORDINE (battle3d._boss_face)
var _sig: String = ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func set_data(p: Array, o: Array, rnd: int, show_order: bool) -> void:
	var sig: String = "%s|%s|%d|%s" % [str(p), str(o), rnd, show_order]
	if sig == _sig:
		return
	_sig = sig
	party = p
	order = o
	round_n = rnd
	order_on = show_order
	queue_redraw()


func set_order_visible(on: bool) -> void:
	if on != order_on:
		order_on = on
		_sig = ""
		queue_redraw()


func _face(id: String, stato: String = "") -> Array:
	# [texture, regione]: il volto disegnato apposta se c'e', altrimenti il mezzobusto ritagliato.
	# stato (varianti dell'autore, 3/11/2026): "ferito", "critico", "ko" o "ng" usano <id>_volto_<stato>.png se c'e'.
	var key: String = id + "|" + stato
	if not _tex.has(key):
		var vp: String = "res://assets/portraits/hud/%s_volto_%s.png" % [id, stato]
		if stato != "" and RitrattoVarianti.attive and ResourceLoader.exists(vp):
			var tv: Texture2D = load(vp)
			_tex[key] = [tv, Rect2(Vector2.ZERO, tv.get_size()), true]
			return _tex[key]
		var real: String = "res://assets/portraits/hud/%s_volto.png" % id
		if ResourceLoader.exists(real):
			var t: Texture2D = load(real)
			_tex[key] = [t, Rect2(Vector2.ZERO, t.get_size()), true]
		else:
			var fp: String = "res://assets/portraits/%s_neutro.png" % id
			_tex[key] = [load(fp) if ResourceLoader.exists(fp) else null, FACE, false]
	return _tex[key]


# Quale volto: K.O. e vita bassa prima, poi la skin della Replica.
func _stato_di(u: Dictionary) -> String:
	if not bool(u.get("alive", true)):
		return "ko"
	var vs: String = RitrattoVarianti.per_vita(int(u.get("hp", 0)), int(u.get("max_hp", 1)))
	if vs != "":
		return vs
	var b: String = RitrattoVarianti.base(str(u.get("id", "")))
	return "" if b == "hud" else b


func _draw() -> void:
	var W: float = size.x
	var H: float = size.y
	var f: Font = Ui.display()
	# --- SQUADRA: fila in basso a destra -------------------------------------------------------------------
	var n: int = party.size()
	var cww: float = cw()
	var foto: bool = Settings.hud_foto
	var fh: float = FH_FOTO if foto else 74.0          # altezza del volto
	var x0: float = W - 22.0 - cww * n - 14.0 * (n - 1)
	var any_on: bool = false
	for uu in party:
		if bool(uu.get("active", false)):
			any_on = true
	for i in n:
		var u: Dictionary = party[i]
		var on: bool = bool(u.get("active", false))
		var alive: bool = bool(u.get("alive", true))
		var col: Color = u.get("col", CREAM)
		var x: float = x0 + i * (cww + 14.0)
		var y: float = H - top() - (12.0 if on else 0.0)
		var tilt: float = -4.0 if i % 2 == 0 else 3.0
		# cornice di carta storta: bianca, rossa se il nemico la punta, del colore se e' di turno
		var fr := PackedVector2Array([Vector2(x, y + 6 + tilt), Vector2(x + cww, y), Vector2(x + cww - 4, y + fh + 10), Vector2(x + 2, y + fh + 14 + tilt)])
		var sh := PackedVector2Array()
		for q in fr:
			sh.append(q + Vector2(6, 6))
		draw_colored_polygon(sh, INK)
		var edge: Color = RED if bool(u.get("marked", false)) else (col.lightened(0.2) if on else (col if foto else CREAM))      # foto: ogni card del colore del suo personaggio
		if on and Settings.hud_party:
			# P1-B: chi e' di turno ha una seconda cornice piena del suo colore attorno alla carta (si vede da lontano)
			var big := PackedVector2Array()
			var ctr := Vector2(x + cww * 0.5, y + fh * 0.6)
			for q in fr:
				big.append(ctr + (q - ctr) * Vector2(1.1, 1.08))
			draw_colored_polygon(big, col)
		draw_colored_polygon(fr, edge)
		var inner := Rect2(Vector2(x + 5, y + 8), Vector2(cww - 11, fh))
		draw_rect(inner, col.darkened(0.6) if alive else Color(0.15, 0.15, 0.18))
		var st: String = _stato_di(u)
		var fd: Array = _face(str(u.get("id", "")), st)
		if fd[0] != null:
			# il volto K.O. disegnato apposta (sagoma blu) si vede intero; quello di ripiego si spegne in grigio come prima
			var lit: bool = alive or (st == "ko" and bool(fd[2]) and str((fd[0] as Texture2D).resource_path).contains("_volto_ko"))
			var tint: Color = Color.WHITE if lit else Color(0.4, 0.4, 0.45)
			if lit and alive and not on and any_on and Settings.hud_party:
				tint = Color(0.78, 0.78, 0.84)      # P1-B: gli altri un filo piu' scuri, cosi' chi e' di turno risalta
			draw_texture_rect_region(fd[0], inner, _fit(fd[1], inner.size), tint)
		# numeri: PV grande, EN sotto, a destra in basso sopra la cornice (come HP/SP del riferimento)
		var dy: float = fh - 74.0          # tutto quello che sta sotto il volto scende con lui
		var hsz: int = 28 if foto else HudLayers.font_size("vite_squadra")      # L2 (HUD Combat 2.0)
		var esz: int = 20 if foto else HudLayers.font_size("en_squadra")
		var hp_s: String = "%d" % int(u.get("hp", 0))
		var en_s: String = "EN %d" % int(u.get("en", 0))
		var hw: float = f.get_string_size(hp_s, HORIZONTAL_ALIGNMENT_LEFT, -1, hsz).x
		var ew: float = f.get_string_size(en_s, HORIZONTAL_ALIGNMENT_LEFT, -1, esz).x
		draw_string_outline(f, Vector2(x + cww - hw - 2, y + 96 + dy + (6.0 if foto else 0.0)), hp_s, HORIZONTAL_ALIGNMENT_LEFT, -1, hsz, 7, INK)
		var hpk0: float = float(u.get("hp", 0)) / maxf(1.0, float(u.get("max_hp", 1)))
		var hcol: Color = HudLayers.tone("vite_squadra", CREAM, INK, hpk0 <= 0.3) if alive else Color(0.6, 0.6, 0.65)   # sotto il 30% torna piena
		draw_string(f, Vector2(x + cww - hw - 2, y + 96 + dy + (6.0 if foto else 0.0)), hp_s, HORIZONTAL_ALIGNMENT_LEFT, -1, hsz, hcol)
		draw_string_outline(f, Vector2(x + cww - ew - 2, y + 113 + dy + (12.0 if foto else 0.0)), en_s, HORIZONTAL_ALIGNMENT_LEFT, -1, esz, 5, INK)
		draw_string(f, Vector2(x + cww - ew - 2, y + 113 + dy + (12.0 if foto else 0.0)), en_s, HORIZONTAL_ALIGNMENT_LEFT, -1, esz, Ui.CYAN)
		# barrette a sinistra sotto il ritratto: vita (verde) e ULTIMATE (rosa, gialla quando e' piena)
		var bw: float = maxf(18.0, cww - hw - 12.0)
		if bool(HudLayers.v("squadra.barre_uguali")):
			# HUD Combat 2.0: barre lunghe uguali su tutte le card (prima la lunghezza dipendeva da quante cifre ha la vita)
			bw = maxf(18.0, cww - _hp_w_max(f, hsz) - 12.0)
		var bh: float = float(HudLayers.v("squadra.barra_vita"))      # 7 nella 0.63, 11 (riempimento 9) nella 2.0
		var ud: float = bh - 7.0                                      # la barretta ULTIMATE scende di quanto cresce la vita
		var hpk: float = clampf(float(u.get("hp", 0)) / maxf(1.0, float(u.get("max_hp", 1))), 0.0, 1.0)
		var gk: float = clampf(float(u.get("gauge", 0)) / maxf(1.0, float(u.get("gmax", 100))), 0.0, 1.0)
		draw_rect(Rect2(x + 2, y + 94 + dy, bw, bh), INK)
		draw_rect(Rect2(x + 3, y + 95 + dy, (bw - 2) * hpk, bh - 2.0), Color("#62f08c") if hpk > 0.3 else Color("#ff5a6e"))
		if Settings.hud_party:
			# P1-B: barretta ULTIMATE piu' spessa; piena = gialla con la stella accanto
			draw_rect(Rect2(x + 2, y + 104 + dy + ud, bw, 9), INK)
			draw_rect(Rect2(x + 3, y + 105 + dy + ud, (bw - 2) * gk, 7), HOT if gk >= 1.0 else Ui.PINK)
			if gk >= 1.0 and alive:
				var sc := Vector2(x + bw + 9, y + 108 + dy + ud)
				var pts := PackedVector2Array()
				for k in 10:
					pts.append(sc + Vector2.from_angle(-PI / 2.0 + k * PI / 5.0) * (8.0 if k % 2 == 0 else 3.4))
				draw_colored_polygon(pts, HOT)
		else:
			draw_rect(Rect2(x + 2, y + 104 + dy, bw, 6), INK)
			draw_rect(Rect2(x + 3, y + 105 + dy, (bw - 2) * gk, 4), HOT if gk >= 1.0 else Ui.PINK)
		if on:
			CmdWheel.skew_text(self, Vector2(x + 2, y - 4), "▶", 18, HOT, INK, f, 6, 0.0)
		if not alive:
			CmdWheel.skew_text(self, Vector2(x + 18, y + 54 + dy * 0.5), "KO", 30, RED, INK, f, 8)
		# HUD 0.61, P0-B: chi e' davvero nel bersaglio della prossima mossa (1 mirino; 2 colpo FORTE o KO: "!" rosso e giallo)
		var tg: int = int(u.get("tgt", 0))
		if tg > 0 and alive:
			var bc := Vector2(x + cww - 8, y + 4)
			var mr: float = float(HudLayers.v("squadra.mirino_su_tutti"))
			if tg == 1 and mr > 0.0 and _tutti_nel_mirino():
				# HUD Combat 2.0: colpo normale su tutti = L3, mirino piccolo; il colpo singolo o FORTE resta grande (L1)
				draw_circle(bc, mr, Color(INK, 0.92))
				draw_arc(bc, mr, 0, TAU, 24, ThreatPlate.RED, 2.5, true)
				ThreatPlate.draw_icon(self, "singolo", bc, ThreatPlate.RED, 5.0)
				continue
			if tg >= 2:
				draw_circle(bc, 15.0, Color("#d0122f"))
				draw_arc(bc, 15.0, 0, TAU, 28, HOT, 2.5, true)
				var xw: float = f.get_string_size("!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
				draw_string(f, bc + Vector2(-xw * 0.5, 8), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, CREAM)
			else:
				draw_circle(bc, 14.0, Color(INK, 0.92))
				draw_arc(bc, 14.0, 0, TAU, 28, ThreatPlate.RED, 3.0, true)
				ThreatPlate.draw_icon(self, "singolo", bc, ThreatPlate.RED, 7.0)
	# --- ORDINE: colonna sul bordo destro, solo mentre si sceglie -------------------------------------------
	if not order_on or order.is_empty():
		return
	var ox: float = W - 128.0
	var oy: float = 6.0 if Settings.hud_alto else 76.0      # piu' in alto, nello spazio lasciato da x1, AUTO e pausa (autore, 7/11/2026)
	# HUD Combat 2.0: etichetta L2 (18 crema, la 0.63 la faceva gialla da 24: gridava come un'informazione L1)
	var oc: Color = HOT if bool(HudLayers.v("ordine.etichetta_gialla")) else HudLayers.tone("ordine_etichetta", CREAM, INK)
	CmdWheel.skew_text(self, Vector2(ox - 8, oy + 22), "ORDINE", HudLayers.font_size("ordine_etichetta"), oc, INK, f, 8, -0.25)
	# ORDINE TURNO bloccati cosi' (autore, 8/11/2026: «e' perfetto»). Il numero a parte, alto dalla cima di ORDINE al fondo
	# di TURNO, 3 px a destra della scritta piu' lunga, nello spazio vuoto verso il riquadro della telecamera.
	var so: int = HudLayers.font_size("ordine_etichetta")
	var st: int = HudLayers.font_size("ordine_turno")
	var tc: Color = HudLayers.tone("ordine_turno", CREAM, INK)
	CmdWheel.skew_text(self, Vector2(ox + 2, oy + 42), "TURNO", st, tc, INK, f, 5, -0.25)
	var cap: float = 0.72          # altezza delle maiuscole e delle cifre rispetto alla grandezza del carattere
	var nh: float = 20.0 + float(so) * cap
	var ns: int = int(round(nh / cap))
	var nx: float = maxf(ox - 8.0 + f.get_string_size("ORDINE", HORIZONTAL_ALIGNMENT_LEFT, -1, so).x, ox + 2.0 + f.get_string_size("TURNO", HORIZONTAL_ALIGNMENT_LEFT, -1, st).x) + 3.0 + 6.0
	CmdWheel.skew_text(self, Vector2(nx, oy + 42), str(round_n), ns, HOT if bool(HudLayers.v("ordine.etichetta_gialla")) else CREAM, INK, f, 6, -0.25)
	var y2: float = oy + 54.0
	for e in order:
		var now: bool = bool(e.get("now", false))
		var boss: bool = bool(e.get("boss", false))
		var col2: Color = e.get("col", CREAM)
		var w: float = 92.0 if now else 78.0
		var h: float = 46.0 if now else 38.0
		var x: float = W - 10.0 - w
		var r := Rect2(Vector2(x, y2), Vector2(w, h))
		var poly := CmdWheel.slant(r, 8.0)
		var sh2 := PackedVector2Array()
		for q in poly:
			sh2.append(q + Vector2(4, 4))
		draw_colored_polygon(sh2, INK)
		draw_colored_polygon(poly, (HOT if now else col2.darkened(0.1)) if not boss else RED)
		var ir := Rect2(r.position + Vector2(8, 4), r.size - Vector2(14, 8))
		if boss and boss_face != null and not bool(e.get("greg", false)) and bool(HudLayers.v("ordine.volto_nemico")):
			draw_rect(ir, Color(0.06, 0.0, 0.03))
			draw_texture_rect(boss_face, ir, false)
		elif boss:
			draw_rect(ir, Color(0.06, 0.0, 0.03))
			var bn: String = str(e.get("name", "?"))
			var bs: int = 15
			while bs > 10 and f.get_string_size(bn, HORIZONTAL_ALIGNMENT_LEFT, -1, bs).x > ir.size.x - 4:
				bs -= 1
			draw_string(f, ir.position + Vector2(3, ir.size.y * 0.5 + bs * 0.38), bn, HORIZONTAL_ALIGNMENT_LEFT, -1, bs, RED.lightened(0.3))
		else:
			draw_rect(ir, col2.darkened(0.55))
			var fd2: Array = _face(str(e.get("id", "")))
			if fd2[0] != null:
				var reg: Rect2 = EYES if not bool(fd2[2]) else fd2[1]
				draw_texture_rect_region(fd2[0], ir, _fit(reg, ir.size))
		# segno a sinistra della lastrina: il colore di chi agisce (come le icone del riferimento)
		var dc := Vector2(x - 12, y2 + h * 0.5)
		draw_colored_polygon(PackedVector2Array([dc + Vector2(0, -9), dc + Vector2(8, 0), dc + Vector2(0, 9), dc + Vector2(-8, 0)]), INK)
		draw_colored_polygon(PackedVector2Array([dc + Vector2(0, -6), dc + Vector2(5, 0), dc + Vector2(0, 6), dc + Vector2(-5, 0)]), RED if boss else col2.lightened(0.2))
		if now:
			CmdWheel.skew_text(self, Vector2(x - 40, y2 + h * 0.5 + 8), "▶", 20, HOT, INK, f, 6, 0.0)
		y2 += h + 6.0


# vita piu' larga della squadra con questa misura: le barre di tutte le card finiscono allo stesso punto
func _hp_w_max(f: Font, sz: int) -> float:
	var w: float = 0.0
	for uu in party:
		w = maxf(w, f.get_string_size("%d" % int(uu.get("hp", 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x)
	return w


# la prossima mossa colpisce tutti i vivi (colpo su tutti)
func _tutti_nel_mirino() -> bool:
	for uu in party:
		if bool(uu.get("alive", true)) and int(uu.get("tgt", 0)) == 0:
			return false
	return true


# Regione della texture con le stesse proporzioni del riquadro (taglia ai lati o sopra/sotto, non schiaccia)
func _fit(reg: Rect2, box: Vector2) -> Rect2:
	var ar: float = box.x / maxf(1.0, box.y)
	var r: Rect2 = reg
	if r.size.x / r.size.y > ar:
		var nw: float = r.size.y * ar
		r.position.x += (r.size.x - nw) * 0.5
		r.size.x = nw
	else:
		var nh: float = r.size.x / ar
		r.position.y += (r.size.y - nh) * 0.3
		r.size.y = nh
	return r
