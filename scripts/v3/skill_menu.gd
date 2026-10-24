class_name SkillMenu
extends Control

# Menu delle ABILITA' alla Persona 5 (scegli la Persona -> Use a Skill): un menu a parte, semplice. Titolo grande inclinato,
# il nome di chi sceglie, una riga per mossa (icona, nome, costo a destra), la riga sotto il cursore e' una lama piena del
# colore del personaggio, e sotto la lista una piccola spiegazione della mossa sotto il cursore.
# Un clic (o un tocco) sulla mossa la LANCIA: niente tasto CONFERMA. Su PC il cursore segue il mouse e le frecce.
# Disegnato a mano in un solo _draw (nessun nodo per riga): costa poco sul telefono.

signal chosen(move_id: String)
signal closed

const ROW_H: float = 50.0
const LEFT: float = 56.0
const TOP: float = 150.0
const WIDTH: float = 560.0

var items: Array = []           # {id, name, cost, desc, ok, why, icon}
var who: String = ""
var col: Color = Color("#8b3dff")
var idx: int = 0
var appear: float = 0.0
var _rows: Array = []           # Rect2 di ogni riga (per il tocco)
var _back: Rect2 = Rect2()
var _opened_ms: int = 0         # sul telefono il tocco che apre il menu arriva anche come clic finto: lo si ignora
var _touch_ms: int = -1000      # ultimo tocco vero, per non contare due volte il clic emulato che lo segue


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func open(p_items: Array, p_who: String, p_col: Color, start: int) -> void:
	items = p_items
	who = p_who
	col = p_col
	idx = clampi(start, 0, maxi(0, items.size() - 1))
	appear = 0.0
	_opened_ms = Time.get_ticks_msec()
	queue_redraw()


func _process(delta: float) -> void:
	if appear < 1.0:
		appear = minf(1.0, appear + delta / 0.16)
		queue_redraw()


func move(step: int) -> void:
	if items.is_empty():
		return
	idx = (idx + step + items.size()) % items.size()
	Settings.buzz(6)
	queue_redraw()


func accept() -> void:
	if idx >= 0 and idx < items.size():
		if bool(items[idx]["ok"]):
			chosen.emit(str(items[idx]["id"]))
		else:
			Settings.buzz(10)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var k: int = _row_at((ev as InputEventMouseMotion).position)
		if k >= 0 and k != idx:
			idx = k
			queue_redraw()
		return
	var pressed: bool = (ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed) \
		or (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
		accept_event()
		closed.emit()
		return
	if not pressed:
		return
	var now: int = Time.get_ticks_msec()
	if ev is InputEventScreenTouch:
		_touch_ms = now
	elif now - _touch_ms < 400:
		accept_event()
		return             # clic emulato dallo stesso tocco: gia' gestito
	if now - _opened_ms < 250:
		accept_event()
		return             # e' ancora il tocco su ABILITA' che ha aperto il menu: prima lo chiudeva subito
	var p: Vector2 = (ev as InputEventScreenTouch).position if ev is InputEventScreenTouch else (ev as InputEventMouseButton).position
	accept_event()
	if _back.has_point(p):
		closed.emit()
		return
	var k2: int = _row_at(p)
	if k2 >= 0:
		idx = k2
		queue_redraw()
		accept()
		return
	# tocco fuori dal menu: si torna ai comandi (come INDIETRO)
	closed.emit()


func _row_at(p: Vector2) -> int:
	for k in _rows.size():
		if (_rows[k] as Rect2).has_point(p):
			return k
	return -1


static func icon_for(mv: Dictionary) -> String:
	var tgt: String = str(mv.get("target", "enemy"))
	if tgt in ["allies", "ally", "party"]:
		return "guard"
	if tgt == "self":
		return "ult"
	return "attack" if float(mv.get("mult", 0.0)) > 0.0 else "skill"


func _draw() -> void:
	var fd: Font = Ui.display()
	var fb: Font = Ui.body()
	var a: float = appear
	var slide: float = (1.0 - a) * -60.0
	_rows.clear()
	# titolo: ABILITA' grande inclinato, sotto "usa una mossa", accanto il nome di chi sceglie su una lastra
	var tp := Vector2(LEFT - 8.0 + slide, TOP - 46.0)
	CmdWheel.skew_text(self, tp, "ABILITÀ", 58, Color(CmdWheel.CREAM, a), Color(CmdWheel.INK, a), fd, 12, -0.22)
	CmdWheel.skew_text(self, tp + Vector2(18.0, 26.0), "usa una mossa", 17, Color(col.lightened(0.5), a), Color(CmdWheel.INK, a), fb, 6, -0.12)
	var tw: float = fd.get_string_size("ABILITÀ", HORIZONTAL_ALIGNMENT_LEFT, -1, 58).x
	var nr := Rect2(tp + Vector2(tw + 26.0, -38.0), Vector2(fd.get_string_size(who, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 44.0, 40.0))
	draw_colored_polygon(CmdWheel.slant(nr.grow(3.0), 12.0), Color(col.lightened(0.2), a))
	draw_colored_polygon(CmdWheel.slant(nr, 10.0), Color(0.02, 0.01, 0.04, 0.95 * a))
	draw_string(fd, nr.position + Vector2(22.0, 29.0), who, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(col.lightened(0.45), a))
	# righe
	for k in items.size():
		var it: Dictionary = items[k]
		var on: bool = k == idx
		var ok: bool = bool(it["ok"])
		var y: float = TOP + 14.0 + float(k) * ROW_H
		var x: float = LEFT + slide + float(k) * 6.0          # leggero scalino, come la lista di Persona 5
		var r := Rect2(x, y, WIDTH, ROW_H - 6.0)
		_rows.append(r)
		if on:
			# lama piena del colore del personaggio, che si allarga verso destra
			draw_colored_polygon(PackedVector2Array([r.position + Vector2(-18.0, 6.0), Vector2(r.end.x + 30.0, r.position.y - 6.0),
				Vector2(r.end.x + 10.0, r.end.y + 2.0), Vector2(r.position.x - 30.0, r.end.y + 6.0)]), Color(0, 0, 0, 0.6 * a))
			draw_colored_polygon(CmdWheel.slant(r, 14.0), Color(col, a))
		else:
			draw_colored_polygon(CmdWheel.slant(r, 14.0), Color(0.02, 0.01, 0.04, 0.72 * a))
		# icona in un riquadro nero a sinistra
		var ib := Rect2(r.position + Vector2(14.0, 7.0), Vector2(46.0, r.size.y - 14.0))
		draw_colored_polygon(CmdWheel.slant(ib, 6.0), Color(0, 0, 0, 0.85 * a))
		CmdWheel.glyph(self, str(it["icon"]), ib.get_center(), 13.0, Color((CmdWheel.HOT if on else col.lightened(0.35)), a * (1.0 if ok else 0.45)))
		var tc: Color = CmdWheel.INK if on else (CmdWheel.CREAM if ok else Color("#8f8a9c"))
		draw_string(fd, r.position + Vector2(76.0, 31.0), str(it["name"]), HORIZONTAL_ALIGNMENT_LEFT, WIDTH - 200.0, 22, Color(tc, a))
		if bool(it.get("sig", false)):
			# la FIRMA del personaggio (equipaggiata in pausa > SQUADRA): stellina e scritta accanto al nome
			var nw: float = minf(fd.get_string_size(str(it["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x, WIDTH - 200.0)
			var sp := r.position + Vector2(76.0 + nw + 14.0, 8.0)
			var tag := Rect2(sp, Vector2(74.0, 26.0))
			draw_colored_polygon(CmdWheel.slant(tag, 6.0), Color(CmdWheel.INK if on else Color("#ffd23f"), a))
			draw_string(fb, sp + Vector2(12.0, 19.0), "FIRMA", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(Color("#ffd23f") if on else CmdWheel.INK, a))
		# costo a destra: rosso se non basta l'energia
		var cost: String = str(it["cost"])
		var cw: float = fd.get_string_size(cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		var cc: Color = CmdWheel.INK if on else (Color("#3fe0ff") if ok else Color("#ff5a6e"))
		draw_string(fd, Vector2(r.end.x - cw - 26.0, r.position.y + 31.0), cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(cc, a))
	# spiegazione della mossa sotto il cursore (e perche' non si puo' usare, se e' il caso)
	if idx >= 0 and idx < items.size():
		var it2: Dictionary = items[idx]
		var txt: String = str(it2.get("desc", ""))
		if not bool(it2["ok"]) and str(it2.get("why", "")) != "":
			txt = str(it2["why"]) + (" · " + txt if txt != "" else "")
		var lines: Array = CmdWheel.wrap(fb, txt, 18, WIDTH - 60.0).slice(0, 3)
		var dy: float = TOP + 22.0 + float(items.size()) * ROW_H
		var dr := Rect2(LEFT + 20.0 + slide, dy, WIDTH - 10.0, 22.0 + 24.0 * float(maxi(1, lines.size())))
		draw_colored_polygon(CmdWheel.slant(dr, 12.0), Color(0.02, 0.01, 0.04, 0.88 * a))
		var ly: float = dr.position.y + 28.0
		for ln in lines:
			draw_string(fb, Vector2(dr.position.x + 24.0, ly), str(ln), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(CmdWheel.CREAM, a))
			ly += 24.0
		# INDIETRO sotto la spiegazione
		_back = Rect2(dr.position + Vector2(0.0, dr.size.y + 12.0), Vector2(170.0, 40.0))
		draw_colored_polygon(CmdWheel.slant(_back, 8.0), Color(0.02, 0.01, 0.04, 0.85 * a))
		draw_string(fb, _back.position + Vector2(24.0, 27.0), "< INDIETRO", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(CmdWheel.CREAM, a))
