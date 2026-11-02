class_name PortraitHud
extends CmdWheel

# HUD DI BATTAGLIA COL RITRATTO 2D (riferimento dell'autore, 2/11/2026: lo stile del remake di Persona 1).
# In basso a sinistra il ritratto 2D di chi e' di turno, tagliato dal bordo dello schermo; i comandi gli stanno attorno
# come scritte storte (ULTIMATE, ABILITA', ATTACCO a sinistra, GUARDIA a destra), ognuno col suo tasto (1-4) o la sua
# icona sul telefono; il nome grande in fondo. Stessa interfaccia della ruota (CmdWheel): setup, pick, item, tapped,
# hovered, e le bande nere dell'ULTIMATE. La ruota resta nel codice: Settings.hud_ritratto = false la riporta.
#
# Ritratti: res://assets/portraits/hud/<id>_hud.png (2D fatti a mano, guida Procreate in docs/RITRATTI_HUD_PROCREATE.md).
# Finche' non ci sono si usa il mezzobusto <id>_neutro.png come segnaposto.

# Riquadro del ritratto (unita' 1280x720): 352x470, proporzione 3:4, appoggiato al bordo in basso a sinistra.
# Il disegno di Procreate (1536x2048) ci entra intero. Zone (frazioni del riquadro): volto x 0.48-0.92 y 0.12-0.55,
# colonna dei comandi x 0-0.45 y 0.30-0.70, GUARDIA x 0.52-0.95 y 0.70-0.82, nome x 0-0.65 y 0.88-1.
const PW: float = 352.0
const PH: float = 470.0
# posto di ogni comando: [x, distanza della linea di base dal fondo, grandezza, rotazione]. ATTACCO e' il piu' grande.
const SLOT: Dictionary = {
	"ult": [10.0, 300.0, 32, -0.10],
	"skill": [16.0, 236.0, 32, -0.07],
	"attack": [6.0, 168.0, 38, -0.05],
	"guard": [196.0, 104.0, 30, -0.04],
}
const KEYS: Dictionary = {"attack": "1", "skill": "2", "ult": "3", "guard": "4"}
const GREY: Color = Color("#8a8496")

var who_id: String = ""                       # id del personaggio (ferri, zecca, nox, saul...): sceglie il ritratto
var _tex: Texture2D
var _tex_real: bool = false
var _rects: Dictionary = {}                   # kind -> Rect2 in coordinate del controllo (tocco e mouse)
var _hov: String = ""


func _init() -> void:
	super()
	# la ruota disegna su quattro strati e le scintille: qui non servono (tutto in un _draw solo, una draw call in piu')
	for n in [_paint, _beam, _rays, _flow, _front]:
		(n as CanvasItem).visible = false
	_flow.emitting = false


func set_who(id: String) -> void:
	if id == who_id and _tex != null:
		return
	who_id = id
	_tex = null
	_tex_real = false
	var real: String = "res://assets/portraits/hud/%s_hud.png" % id
	if ResourceLoader.exists(real):
		_tex = load(real)
		_tex_real = true
	else:
		var fp: String = "res://assets/portraits/%s_neutro.png" % id
		if ResourceLoader.exists(fp):
			_tex = load(fp)
	queue_redraw()


func setup(p_who: String, p_col: Color, p_items: Array) -> void:
	super(p_who, p_col, p_items)
	queue_redraw()


func pick(kind: String) -> void:
	super(kind)
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	var was_a: float = appear
	var was_s: float = sel
	appear = move_toward(appear, 1.0, delta / 0.32)
	sel = move_toward(sel, 1.0 if picked != "" else 0.0, delta / (0.4 if picked == "ult" else 0.2))
	var was_f: float = flash
	flash = maxf(0.0, flash - delta * 3.2)
	# PRESTAZIONI: si ridisegna solo mentre qualcosa si muove (entrata, scelta, lampo)
	if appear != was_a or sel != was_s or flash != was_f:
		queue_redraw()


func _ease(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)


func _draw() -> void:
	super()            # bande nere dell'ULTIMATE e lampo della scelta, come la ruota
	var H: float = size.y
	var e: float = _ease(appear)
	var dx: float = -(1.0 - e) * (PW + 60.0)
	var f: Font = Ui.display()
	_rects.clear()
	# 1) lastra del colore di chi e' di turno, storta, con l'ombra d'inchiostro: il ritratto ci sta sopra
	var sh := PackedVector2Array([Vector2(dx, H - 360), Vector2(dx + 250, H - 430), Vector2(dx + PW + 30, H), Vector2(dx, H)])
	var off := PackedVector2Array()
	for q in sh:
		off.append(q + Vector2(10, 8))
	draw_colored_polygon(off, Color(INK, 0.9 * e))
	draw_colored_polygon(sh, Color(col.darkened(0.55), 0.92 * e))
	draw_colored_polygon(PackedVector2Array([Vector2(dx, H - 330), Vector2(dx + 226, H - 376), Vector2(dx + 240, H - 362), Vector2(dx, H - 314)]), Color(col.lightened(0.15), 0.9 * e))
	draw_colored_polygon(PackedVector2Array([Vector2(dx + 268, H - 408), Vector2(dx + 286, H - 412), Vector2(dx + PW + 46, H), Vector2(dx + PW + 26, H)]), Color(col, 0.85 * e))
	# 2) ritratto: in basso, tagliato dal bordo; il volto sta nella meta' destra della zona, le scritte a sinistra e in fondo
	if _tex != null:
		var r := Rect2(Vector2(dx, H - PH), Vector2(PW, PH))
		if not _tex_real:
			# segnaposto (mezzobusto 512x768, volto al centro): spostato e ingrandito per mettere il volto nella sua zona
			r = Rect2(Vector2(dx + 92.0, H - 500.0), Vector2(320.0, 480.0))
		# ombra piatta del colore (stile cel): lo stesso ritratto spostato e scurito
		draw_texture_rect(_tex, Rect2(r.position + Vector2(-8, 6), r.size), false, Color(INK, 0.55 * e))
		draw_texture_rect(_tex, r, false, Color(1, 1, 1, e))
	# 3) comandi attorno al ritratto
	for kind in ["ult", "skill", "attack", "guard"]:
		var it: Dictionary = item(kind)
		if it.is_empty():
			continue
		_draw_cmd(kind, it, dx, H, f, e)
	# 4) nome grande in fondo, sopra al ritratto (come il nome in giapponese del riferimento)
	var nm: String = who.split(" · ")[0]
	var nsz: int = 40
	while nsz > 26 and f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, nsz).x > PW - 20:
		nsz -= 2
	CmdWheel.skew_text(self, Vector2(dx + 12, H - 22), nm, nsz, col.lightened(0.45), INK, f, 12, -0.25)
	if who.contains("RAPIDO"):
		CmdWheel.skew_text(self, Vector2(dx + 16, H - 66), "RAPIDO", 18, HOT, INK, f, 7, -0.25)
	# 5) cosa fa il comando scelto: una lastra scura sopra il ritratto
	if picked != "":
		_draw_tip(item(picked), dx, H, e)


func _draw_cmd(kind: String, it: Dictionary, dx: float, H: float, f: Font, e: float) -> void:
	var sl: Array = SLOT[kind]
	var sz: int = int(sl[2])
	var name: String = str(it.get("name", kind))
	var ok: bool = bool(it.get("ok", false))
	var on: bool = picked == kind
	var maxw: float = 150.0
	while sz > 22 and f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > maxw:
		sz -= 2
	if on:
		sz += 4
	var tw: float = f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var p := Vector2(dx + float(sl[0]), H - float(sl[1]))
	var rot: float = float(sl[3])
	var fill: Color = Color(CREAM.lerp(col.lightened(0.6), 0.45)) if ok else GREY
	var edge: Color = INK
	# il comando scelto: lastra piena del colore dietro alla scritta, scritta scura
	draw_set_transform(p, rot)
	if on:
		var slab := PackedVector2Array([Vector2(-10, -sz * 0.92), Vector2(tw + 18, -sz * 1.02), Vector2(tw + 8, sz * 0.22), Vector2(-16, sz * 0.3)])
		var sdw := PackedVector2Array()
		for q in slab:
			sdw.append(q + Vector2(6, 6))
		draw_colored_polygon(sdw, Color(INK, e))
		draw_colored_polygon(slab, Color(col.lightened(0.1), e))
		fill = HOT
	elif _hov == kind and ok:
		fill = CREAM
	# ombra del colore sfalsata (lettering del riferimento) + contorno d'inchiostro spesso
	draw_set_transform(p + Vector2(4, 4).rotated(rot), rot, Vector2(1, 1))
	draw_string_outline(f, Vector2.ZERO, name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 10, Color(col.darkened(0.2), 0.95 * e))
	draw_set_transform(p, rot)
	draw_string_outline(f, Vector2.ZERO, name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 9, Color(edge, e))
	draw_string(f, Vector2.ZERO, name, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(fill, e))
	# tasto rotondo: numero della tastiera su PC, icona sul telefono
	var bc := Vector2(tw + 22, -sz * 0.62)
	if kind == "guard":
		bc = Vector2(-20, -sz * 0.5)      # GUARDIA ha il tasto a sinistra (come DEFEND nel riferimento)
	var br: float = 15.0 if not on else 18.0
	draw_circle(bc + Vector2(2, 2), br + 3, Color(INK, e))
	draw_circle(bc, br + 2, Color(CREAM if ok else GREY, e))
	draw_circle(bc, br - 1, Color(INK if not on else col.darkened(0.3), e))
	if Ui.is_touch():
		CmdWheel.glyph(self, kind, bc, br * 0.8, Color(CREAM if ok else GREY, e))
	else:
		var k: String = str(KEYS.get(kind, ""))
		var ks: Vector2 = f.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		draw_string(f, bc + Vector2(-ks.x * 0.5, 7), k, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(CREAM if ok else GREY, e))
	# ULTIMATE non pronta: la carica in piccolo sotto la scritta
	if kind == "ult" and not ok:
		draw_string(Ui.body(), Vector2(6, 18), str(it.get("cost", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(GREY, e))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# zona del tocco: scritta + tasto, almeno 56 di altezza (dito sul telefono)
	var x0: float = minf(0.0, bc.x - br) - 8.0
	var x1: float = maxf(tw, bc.x + br) + 8.0
	var hh: float = maxf(56.0, sz * 1.3)
	_rects[kind] = Rect2(p + Vector2(x0, -sz - (hh - sz * 1.3) * 0.5), Vector2(x1 - x0, hh))


func _draw_tip(it: Dictionary, dx: float, H: float, e: float) -> void:
	if it.is_empty():
		return
	var bf: Font = Ui.body()
	var lines: Array = CmdWheel.wrap(bf, str(it.get("desc", "")).replace("\n", " · "), 16, 330.0)
	if lines.size() > 3:
		lines = lines.slice(0, 3)
	var top: float = H - 400.0 - 30.0 - 20.0 * lines.size()
	var r := Rect2(Vector2(dx + 6, top), Vector2(360, 34 + 20.0 * lines.size()))
	var poly := CmdWheel.slant(r, 10.0)
	draw_colored_polygon(poly, Color(0.03, 0.02, 0.06, 0.88 * e))
	draw_polyline(PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]]), Color(col.lightened(0.3), e), 2.0)
	draw_string(Ui.display(), r.position + Vector2(16, 24), str(it.get("title", "")), HORIZONTAL_ALIGNMENT_LEFT, 330, 17, Color(HOT, e))
	for i in lines.size():
		draw_string(bf, r.position + Vector2(16, 46 + 20 * i), str(lines[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(CREAM, e))


func _has_point(p: Vector2) -> bool:
	for k in _rects:
		if (_rects[k] as Rect2).has_point(p):
			return true
	return false


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var hk: String = ""
		for k in _rects:
			if (_rects[k] as Rect2).has_point((ev as InputEventMouseMotion).position):
				hk = k
		if hk != _hov:
			_hov = hk
			hovered.emit(hk)
			queue_redraw()
		return
	var pressed: bool = (ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed) \
		or (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	if not pressed:
		return
	var p: Vector2 = (ev as InputEventScreenTouch).position if ev is InputEventScreenTouch else (ev as InputEventMouseButton).position
	for k in _rects:
		if (_rects[k] as Rect2).has_point(p):
			accept_event()
			tapped.emit(k)
			return
