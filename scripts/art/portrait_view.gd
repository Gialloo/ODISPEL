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
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if _texture == null:
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

	var bob: float = sin(_t * 1.6) * 2.0
	var cx: float = w * 0.5
	# busto: spalle larghe, collo, testa
	var shoulders := PackedVector2Array([
		Vector2(cx - w * 0.42, h), Vector2(cx - w * 0.36, h * 0.66 + bob), Vector2(cx - w * 0.14, h * 0.60 + bob),
		Vector2(cx + w * 0.14, h * 0.60 + bob), Vector2(cx + w * 0.36, h * 0.66 + bob), Vector2(cx + w * 0.42, h)])
	draw_colored_polygon(shoulders, body)
	draw_polyline(PackedVector2Array([shoulders[0], shoulders[1], shoulders[2], shoulders[3], shoulders[4], shoulders[5]]), line, 3.0)
	draw_rect(Rect2(cx - w * 0.07, h * 0.5 + bob, w * 0.14, h * 0.12), body)
	var head_r: float = minf(w * 0.2, h * 0.17)
	var head := Vector2(cx, h * 0.38 + bob)
	draw_circle(head, head_r, body)
	draw_arc(head, head_r, 0.0, TAU, 32, line, 3.0)
	# visore: cambia con l'espressione, cosi' si vede
	var eye_y: float = head.y - head_r * 0.1
	match expression:
		"angry":
			draw_line(Vector2(cx - head_r * 0.7, eye_y - 6.0), Vector2(cx - head_r * 0.1, eye_y + 2.0), line, 4.0)
			draw_line(Vector2(cx + head_r * 0.7, eye_y - 6.0), Vector2(cx + head_r * 0.1, eye_y + 2.0), line, 4.0)
		"sad", "hurt":
			draw_line(Vector2(cx - head_r * 0.7, eye_y + 2.0), Vector2(cx - head_r * 0.1, eye_y - 5.0), line, 4.0)
			draw_line(Vector2(cx + head_r * 0.7, eye_y + 2.0), Vector2(cx + head_r * 0.1, eye_y - 5.0), line, 4.0)
		"happy":
			draw_arc(Vector2(cx - head_r * 0.4, eye_y), head_r * 0.25, PI, TAU, 10, line, 4.0)
			draw_arc(Vector2(cx + head_r * 0.4, eye_y), head_r * 0.25, PI, TAU, 10, line, 4.0)
		"surprised":
			draw_circle(Vector2(cx - head_r * 0.4, eye_y), head_r * 0.2, line)
			draw_circle(Vector2(cx + head_r * 0.4, eye_y), head_r * 0.2, line)
		_:
			draw_rect(Rect2(cx - head_r * 0.7, eye_y - 3.0, head_r * 1.4, 7.0), line)

	var f2: Font = BattleTheme.display()
	var name: String = _display_name()
	var fs2: int = clampi(int(w * 0.11), 14, 36)
	draw_string(f2, Vector2(10.0, 26.0), name, HORIZONTAL_ALIGNMENT_LEFT, w - 20.0, fs2, line)
	if show_expression_text and kind == "bust":
		draw_string(BattleTheme.mono(), Vector2(10.0, 26.0 + fs2), "[%s]" % expression.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, w - 20.0, 14, line.darkened(0.2))
