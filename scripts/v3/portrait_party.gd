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
const FACE: Rect2 = Rect2(112, 128, 290, 270)      # volto dentro al mezzobusto 512x768 (segnaposto)
const EYES: Rect2 = Rect2(120, 270, 290, 110)      # striscia degli occhi per la colonna ORDINE

var party: Array = []           # {id, name, col, hp, max_hp, en, gauge, gmax, active, alive, marked}
var order: Array = []           # {id, name, col, boss, now}
var order_on: bool = true
var round_n: int = 1
var _tex: Dictionary = {}
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
		if stato != "" and ResourceLoader.exists(vp):
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
	var x0: float = W - 22.0 - CW * n - 14.0 * (n - 1)
	for i in n:
		var u: Dictionary = party[i]
		var on: bool = bool(u.get("active", false))
		var alive: bool = bool(u.get("alive", true))
		var col: Color = u.get("col", CREAM)
		var x: float = x0 + i * (CW + 14.0)
		var y: float = H - 128.0 - (12.0 if on else 0.0)
		var tilt: float = -4.0 if i % 2 == 0 else 3.0
		# cornice di carta storta: bianca, rossa se il nemico la punta, del colore se e' di turno
		var fr := PackedVector2Array([Vector2(x, y + 6 + tilt), Vector2(x + CW, y), Vector2(x + CW - 4, y + 84), Vector2(x + 2, y + 88 + tilt)])
		var sh := PackedVector2Array()
		for q in fr:
			sh.append(q + Vector2(6, 6))
		draw_colored_polygon(sh, INK)
		var edge: Color = RED if bool(u.get("marked", false)) else (col.lightened(0.2) if on else CREAM)
		draw_colored_polygon(fr, edge)
		var inner := Rect2(Vector2(x + 5, y + 8), Vector2(CW - 11, 74))
		draw_rect(inner, col.darkened(0.6) if alive else Color(0.15, 0.15, 0.18))
		var st: String = _stato_di(u)
		var fd: Array = _face(str(u.get("id", "")), st)
		if fd[0] != null:
			# il volto K.O. disegnato apposta (sagoma blu) si vede intero; quello di ripiego si spegne in grigio come prima
			var lit: bool = alive or (st == "ko" and bool(fd[2]) and str((fd[0] as Texture2D).resource_path).contains("_volto_ko"))
			draw_texture_rect_region(fd[0], inner, _fit(fd[1], inner.size), Color.WHITE if lit else Color(0.4, 0.4, 0.45))
		# numeri: PV grande, EN sotto, a destra in basso sopra la cornice (come HP/SP del riferimento)
		var hp_s: String = "%d" % int(u.get("hp", 0))
		var en_s: String = "EN %d" % int(u.get("en", 0))
		var hw: float = f.get_string_size(hp_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		var ew: float = f.get_string_size(en_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string_outline(f, Vector2(x + CW - hw - 2, y + 96), hp_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 6, INK)
		draw_string(f, Vector2(x + CW - hw - 2, y + 96), hp_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, CREAM if alive else Color(0.6, 0.6, 0.65))
		draw_string_outline(f, Vector2(x + CW - ew - 2, y + 113), en_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, INK)
		draw_string(f, Vector2(x + CW - ew - 2, y + 113), en_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Ui.CYAN)
		# barrette a sinistra sotto il ritratto: vita (verde) e ULTIMATE (rosa, gialla quando e' piena)
		var bw: float = maxf(18.0, CW - hw - 12.0)
		var hpk: float = clampf(float(u.get("hp", 0)) / maxf(1.0, float(u.get("max_hp", 1))), 0.0, 1.0)
		var gk: float = clampf(float(u.get("gauge", 0)) / maxf(1.0, float(u.get("gmax", 100))), 0.0, 1.0)
		draw_rect(Rect2(x + 2, y + 94, bw, 7), INK)
		draw_rect(Rect2(x + 3, y + 95, (bw - 2) * hpk, 5), Color("#62f08c") if hpk > 0.3 else Color("#ff5a6e"))
		draw_rect(Rect2(x + 2, y + 104, bw, 6), INK)
		draw_rect(Rect2(x + 3, y + 105, (bw - 2) * gk, 4), HOT if gk >= 1.0 else Ui.PINK)
		if on:
			CmdWheel.skew_text(self, Vector2(x + 2, y - 4), "▶", 18, HOT, INK, f, 6, 0.0)
		if not alive:
			CmdWheel.skew_text(self, Vector2(x + 18, y + 54), "KO", 30, RED, INK, f, 8)
	# --- ORDINE: colonna sul bordo destro, solo mentre si sceglie -------------------------------------------
	if not order_on or order.is_empty():
		return
	var ox: float = W - 128.0
	var oy: float = 76.0
	CmdWheel.skew_text(self, Vector2(ox - 8, oy + 22), "ORDINE", 24, HOT, INK, f, 8, -0.25)
	CmdWheel.skew_text(self, Vector2(ox + 2, oy + 42), "TURNO %d" % round_n, 14, CREAM, INK, f, 5, -0.25)
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
		if boss:
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
