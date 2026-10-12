class_name PortraitView
extends Control

# Mostra un personaggio (o un boss) con la sua grafica se esiste, altrimenti un
# segnaposto in stile "sagoma + nome". Cambiando `expression` il segnaposto mostra
# l'espressione in testo, cosi' chi scrive i dialoghi la vede anche senza disegni.
#
# kind: "bust" (ritratto con espressioni), "splash" (illustrazione grande),
#       "icon" (quadrata), "cutin" (sequenza ultimate)

var char_id: String = ""
var is_boss: bool = false
var kind: String = "bust"
var expression: String = "neutral"
var dimmed: bool = false           # chi non parla e' piu' scuro
var flip: bool = false             # specchia (personaggio a destra che guarda a sinistra)
var show_expression_text: bool = true
var _texture: Texture2D = null
var _t: float = 0.0


func setup(new_char: String, new_kind: String = "bust", boss: bool = false) -> PortraitView:
	char_id = new_char
	kind = new_kind
	is_boss = boss
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_texture()
	return self


func set_expression(new_expression: String) -> void:
	expression = new_expression
	_refresh_texture()


func has_art() -> bool:
	return _texture != null


func _refresh_texture() -> void:
	if is_boss:
		_texture = ArtLibrary.boss_image(char_id, "portrait")
	else:
		match kind:
			"splash":
				_texture = ArtLibrary.splash(char_id)
			"icon":
				_texture = ArtLibrary.icon(char_id)
			"cutin":
				_texture = ArtLibrary.cutin(char_id)
			_:
				_texture = ArtLibrary.portrait(char_id, expression)
	set_process(_texture == null)    # con la grafica vera non c'e' niente che si muova
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _color() -> Color:
	if is_boss:
		return BattleTheme.RD
	var def: Dictionary = BattleContent.CHARACTERS.get(char_id, {})
	return BattleTheme.unit_color(str(def.get("color", "")))


func _display_name() -> String:
	if is_boss:
		return str(BattleContent.BOSSES.get(char_id, {}).get("name", char_id)).to_upper()
	return str(BattleContent.CHARACTERS.get(char_id, {}).get("name", char_id)).to_upper()


func _draw() -> void:
	var tint: Color = Color(0.45, 0.45, 0.5, 1.0) if dimmed else Color.WHITE
	if _texture != null:
		_draw_texture(tint)
	else:
		_draw_placeholder(tint)


# Disegna la grafica adattata all'area: i piedi/basso dell'immagine restano in basso.
func _draw_texture(tint: Color) -> void:
	var ts: Vector2 = _texture.get_size()
	var fit: float = minf(size.x / ts.x, size.y / ts.y) if kind != "icon" else maxf(size.x / ts.x, size.y / ts.y)
	var draw_size: Vector2 = ts * fit
	var pos := Vector2((size.x - draw_size.x) * 0.5, size.y - draw_size.y)
	if kind == "icon":
		pos = (size - draw_size) * 0.5
	var rect := Rect2(pos, draw_size)
	if flip:
		draw_set_transform(Vector2(size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect(_texture, rect, false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_placeholder(tint: Color) -> void:
	var col: Color = _color()
	var body: Color = col.darkened(0.5) * tint
	var line: Color = col * tint
	var w: float = size.x
	var h: float = size.y
	if kind == "icon":
		draw_rect(Rect2(Vector2.ZERO, size), body)
		draw_rect(Rect2(Vector2.ZERO, size), line, false, 2.0)
		var f: Font = BattleTheme.display()
		var ini: String = _display_name().substr(0, 1)
		var fs: int = int(h * 0.55)
		var sz: Vector2 = f.get_string_size(ini, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(f, Vector2((w - sz.x) * 0.5, h * 0.5 + sz.y * 0.3), ini, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, line)
		return

	_draw_anime_bust(col, tint)

	var f2: Font = BattleTheme.display()
	var name: String = _display_name()
	var fs2: int = clampi(int(w * 0.11), 14, 36)
	draw_string(f2, Vector2(10.0, 26.0), name, HORIZONTAL_ALIGNMENT_LEFT, w - 20.0, fs2, line)
	if show_expression_text and kind == "bust":
		draw_string(BattleTheme.mono(), Vector2(10.0, 26.0 + fs2), "[%s]" % expression.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, w - 20.0, 14, line.darkened(0.2))


# ---------- Busto anime (segnaposto) ----------
# Pochi tratti ma scelti: capelli nel colore dell'operatore, volto semplice e OCCHI grandi, che cambiano con l'espressione.
# Senza sfondo: la figura sta da sola, come nelle scene di storia.

static func _oval(c: Vector2, rx: float, ry: float, n: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a: float = TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _hair_style() -> int:
	return absi(char_id.hash()) % 3


func _draw_anime_bust(col: Color, tint: Color) -> void:
	var w: float = size.x
	var h: float = size.y
	var cx: float = w * 0.5
	var bob: float = sin(_t * 1.6) * 2.0
	var r: float = minf(w * 0.24, h * 0.2)                     # raggio del volto
	var head := Vector2(cx, h * 0.40 + bob)
	var hair_col: Color = col.darkened(0.15) * tint
	var hair_hi: Color = col.lightened(0.35) * tint
	var skin: Color = Color("#f7dfcf") * tint
	var skin_sh: Color = Color("#e3b9a4") * tint
	var cloth: Color = col.darkened(0.55) * tint
	var line: Color = Color("#1a1020") * tint
	var style: int = _hair_style()

	# capelli dietro: massa + ciocche lunghe nello stile 2
	draw_colored_polygon(_oval(head + Vector2(0, -r * 0.1), r * 1.22, r * 1.3), hair_col)
	if style == 2:
		draw_colored_polygon(PackedVector2Array([head + Vector2(-r * 1.15, 0), head + Vector2(-r * 1.3, r * 2.0), head + Vector2(-r * 0.7, r * 1.7), head + Vector2(-r * 0.6, 0)]), hair_col)
		draw_colored_polygon(PackedVector2Array([head + Vector2(r * 1.15, 0), head + Vector2(r * 1.3, r * 2.0), head + Vector2(r * 0.7, r * 1.7), head + Vector2(r * 0.6, 0)]), hair_col)

	# spalle e giacca
	var sh := PackedVector2Array([
		Vector2(cx - w * 0.46, h), Vector2(cx - w * 0.40, h * 0.72 + bob), Vector2(cx - w * 0.16, h * 0.64 + bob),
		Vector2(cx + w * 0.16, h * 0.64 + bob), Vector2(cx + w * 0.40, h * 0.72 + bob), Vector2(cx + w * 0.46, h)])
	draw_colored_polygon(sh, cloth)
	draw_polyline(sh, col * tint, 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(cx - w * 0.14, h * 0.64 + bob), Vector2(cx, h * 0.80 + bob), Vector2(cx + w * 0.14, h * 0.64 + bob)]), skin_sh)
	draw_rect(Rect2(cx - r * 0.3, head.y + r * 0.9, r * 0.6, r * 0.8), skin_sh)       # collo

	# volto
	draw_colored_polygon(_oval(head + Vector2(0, r * 0.12), r * 0.92, r * 1.08), skin)
	draw_colored_polygon(PackedVector2Array([head + Vector2(r * 0.55, r * 0.5), head + Vector2(r * 0.88, r * 0.1), head + Vector2(r * 0.7, r * 0.95)]), skin_sh)

	# frangia: calotta sopra la fronte con il bordo basso che cambia con lo stile; ciuffi laterali ai lati del volto
	var edge: Array = [
		[[0.98, 0.15], [0.7, -0.2], [0.55, 0.05], [0.3, -0.3], [0.15, 0.0], [-0.1, -0.35], [-0.3, 0.05], [-0.55, -0.25], [-0.7, 0.1], [-0.98, 0.2]],
		[[0.98, 0.3], [0.7, -0.1], [0.3, -0.45], [0.05, -0.55], [-0.05, -0.55], [-0.3, -0.45], [-0.7, -0.1], [-0.98, 0.3]],
		[[0.98, 0.1], [0.6, -0.3], [0.1, -0.4], [-0.4, -0.1], [-0.7, 0.3], [-0.98, 0.55]],
	][style]
	var bangs := PackedVector2Array()
	for i in 13:
		var a2: float = PI + PI * float(i) / 12.0
		bangs.append(head + Vector2(cos(a2) * r * 1.02, sin(a2) * r * 1.1 - r * 0.05))
	for pt in edge:
		bangs.append(head + Vector2(float(pt[0]) * r, float(pt[1]) * r))
	draw_colored_polygon(bangs, hair_col)
	for s in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([head + Vector2(s * r * 0.86, -r * 0.3), head + Vector2(s * r * 1.04, -r * 0.2), head + Vector2(s * r * 1.0, r * 0.75), head + Vector2(s * r * 0.84, r * 0.45)]), hair_col)
	draw_polyline(PackedVector2Array([head + Vector2(-r * 0.6, -r * 0.8), head + Vector2(-r * 0.1, -r * 0.95), head + Vector2(r * 0.35, -r * 0.85)]), hair_hi, 3.0)

	# occhi: la parte che conta
	var ey: float = head.y + r * 0.3
	var ex: float = r * 0.45
	var erx: float = r * 0.32
	var ery: float = r * 0.42
	var iris: Color = col.lightened(0.1) * tint
	match expression:
		"happy":
			for s in [-1.0, 1.0]:
				draw_arc(Vector2(cx + s * ex, ey + ery * 0.2), erx * 0.9, PI * 1.08, PI * 1.92, 14, line, 4.0)
		"angry":
			for s in [-1.0, 1.0]:
				var c := Vector2(cx + s * ex, ey)
				draw_colored_polygon(_oval(c, erx, ery * 0.72), Color("#ffffff") * tint)
				draw_colored_polygon(_oval(c + Vector2(0, ery * 0.05), erx * 0.62, ery * 0.62), iris)
				draw_circle(c + Vector2(-erx * 0.2, -ery * 0.15), erx * 0.18, Color.WHITE)
				draw_line(c + Vector2(-s * erx * 1.15, -ery * 1.15 + s * ery * 0.0), c + Vector2(s * erx * 0.4, -ery * 0.55), line, 5.0)
		"sad", "hurt":
			for s in [-1.0, 1.0]:
				var c2 := Vector2(cx + s * ex, ey + ery * 0.1)
				draw_colored_polygon(_oval(c2, erx, ery), Color("#ffffff") * tint)
				draw_colored_polygon(_oval(c2 + Vector2(0, ery * 0.15), erx * 0.72, ery * 0.78), iris)
				draw_circle(c2 + Vector2(-erx * 0.25, -ery * 0.2), erx * 0.26, Color.WHITE)
				draw_circle(c2 + Vector2(erx * 0.2, ery * 0.3), erx * 0.12, Color(1, 1, 1, 0.8))
				draw_line(c2 + Vector2(-s * erx * 1.0, -ery * 1.2 + s * 0.0), c2 + Vector2(s * erx * 0.9, -ery * 1.45), line, 4.0)
			draw_circle(Vector2(cx - ex * 1.05, ey + ery * 1.5), r * 0.05, Color("#9fe6ff") * tint)
		"surprised":
			for s in [-1.0, 1.0]:
				var c3 := Vector2(cx + s * ex, ey)
				draw_colored_polygon(_oval(c3, erx * 1.05, ery * 1.15), Color("#ffffff") * tint)
				draw_colored_polygon(_oval(c3, erx * 0.5, ery * 0.6), iris)
				draw_circle(c3 + Vector2(-erx * 0.12, -ery * 0.2), erx * 0.15, Color.WHITE)
		_:
			for s in [-1.0, 1.0]:
				var c4 := Vector2(cx + s * ex, ey)
				draw_colored_polygon(_oval(c4, erx, ery), Color("#ffffff") * tint)
				draw_colored_polygon(_oval(c4 + Vector2(0, ery * 0.1), erx * 0.78, ery * 0.88), iris)
				draw_colored_polygon(_oval(c4 + Vector2(0, ery * 0.12), erx * 0.42, ery * 0.5), line)
				draw_circle(c4 + Vector2(-erx * 0.28, -ery * 0.28), erx * 0.26, Color.WHITE)
				draw_circle(c4 + Vector2(erx * 0.25, ery * 0.35), erx * 0.12, Color(1, 1, 1, 0.85))
				draw_arc(c4, erx * 1.02, PI * 1.05, PI * 1.95, 14, line, 4.0)
	# sopracciglia (tranne dove gia' disegnate) e bocca minima
	if expression != "angry" and expression != "sad" and expression != "hurt":
		for s in [-1.0, 1.0]:
			draw_line(Vector2(cx + s * ex - erx * 0.8, ey - ery * 1.5), Vector2(cx + s * ex + erx * 0.8, ey - ery * 1.6 - (r * 0.05 if expression == "surprised" else 0.0)), line, 3.0)
	var my: float = head.y + r * 0.82
	match expression:
		"happy":
			draw_arc(Vector2(cx, my - r * 0.1), r * 0.2, PI * 0.1, PI * 0.9, 10, line, 3.0)
		"surprised":
			draw_colored_polygon(_oval(Vector2(cx, my), r * 0.07, r * 0.1, 12), line)
		"sad", "hurt":
			draw_arc(Vector2(cx, my + r * 0.12), r * 0.12, PI * 1.15, PI * 1.85, 8, line, 3.0)
		"angry":
			draw_line(Vector2(cx - r * 0.12, my), Vector2(cx + r * 0.12, my + 2.0), line, 3.0)
		_:
			draw_line(Vector2(cx - r * 0.1, my), Vector2(cx + r * 0.1, my), line, 3.0)

