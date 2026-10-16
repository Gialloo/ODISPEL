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
var _odd: bool = false


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
	# solo il busto segnaposto respira; icone, sagome e grafica vera sono ferme (niente ridisegno a ogni frame)
	set_process(_texture == null and kind == "bust" and not is_boss)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	if Settings.light_fx:                 # telefoni: la respirazione del ritratto a 30 disegni al secondo basta
		_odd = not _odd
		if _odd:
			return
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
	if kind == "splash" and _cut_at_bottom(_texture):
		_draw_faded_bottom(rect, tint)
	else:
		draw_texture_rect(_texture, rect, false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Le illustrazioni tagliate a meta' (busto, cosce) sfumano in basso invece di finire con un taglio netto.
static var _cut_cache: Dictionary = {}


static func _cut_at_bottom(tex: Texture2D) -> bool:
	var key: int = tex.get_instance_id()
	if _cut_cache.has(key):
		return bool(_cut_cache[key])
	var cut: bool = false
	var img: Image = tex.get_image()
	if img != null and not img.is_empty():
		var w: int = img.get_width()
		var y: int = img.get_height() - 2
		var solid: int = 0
		for x in range(0, w, 6):
			if img.get_pixel(x, y).a > 0.6:
				solid += 1
		cut = solid >= 6          # sei punti opachi lungo il bordo basso: la figura continua oltre l'immagine
	_cut_cache[key] = cut
	return cut


func _draw_faded_bottom(rect: Rect2, tint: Color) -> void:
	var ts: Vector2 = _texture.get_size()
	const STRIPS: int = 14
	const FADE: float = 0.16
	var solid_h: float = 1.0 - FADE
	draw_texture_rect_region(_texture, Rect2(rect.position, Vector2(rect.size.x, rect.size.y * solid_h)), Rect2(0.0, 0.0, ts.x, ts.y * solid_h), tint)
	for i in STRIPS:
		var a0: float = solid_h + FADE * float(i) / float(STRIPS)
		var a1: float = solid_h + FADE * float(i + 1) / float(STRIPS)
		var c := Color(tint.r, tint.g, tint.b, tint.a * (1.0 - (float(i) + 0.5) / float(STRIPS)))
		draw_texture_rect_region(_texture, Rect2(rect.position + Vector2(0.0, rect.size.y * a0), Vector2(rect.size.x, rect.size.y * (a1 - a0) + 0.5)), Rect2(0.0, ts.y * a0, ts.x, ts.y * (a1 - a0)), c)


func _draw_placeholder(tint: Color) -> void:
	var col: Color = _color()
	var body: Color = col.darkened(0.5) * tint
	var line: Color = col * tint
	var w: float = size.x
	var h: float = size.y
	if kind == "icon":
		draw_rect(Rect2(Vector2.ZERO, size), body)
		var ir: float = minf(w, h) * 0.34
		var ihead := Vector2(w * 0.5, h * 0.5)
		if not HeadCache.draw(self, ihead, ir, char_id, col, expression, tint):
			AnimeFace.hair_back(self, ihead, ir, char_id, col, tint)
			AnimeFace.face(self, ihead, ir, char_id, col, tint, expression)
		draw_rect(Rect2(Vector2.ZERO, size), line, false, 2.0)
		return

	if is_boss:
		_draw_boss_placeholder(col, tint)
	else:
		_draw_anime_bust(col, tint)

	var f2: Font = BattleTheme.display()
	var name: String = _display_name()
	var fs2: int = clampi(int(w * 0.11), 14, 36)
	draw_string(f2, Vector2(10.0, 26.0), name, HORIZONTAL_ALIGNMENT_LEFT, w - 20.0, fs2, line)
	if show_expression_text and kind == "bust":
		draw_string(BattleTheme.mono(), Vector2(10.0, 26.0 + fs2), "[%s]" % expression.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, w - 20.0, 14, line.darkened(0.2))


# Un bersaglio non e' una persona: sagoma squadrata con due occhi accesi.
func _draw_boss_placeholder(col: Color, tint: Color) -> void:
	var w: float = size.x
	var h: float = size.y
	var body: Rect2 = Rect2(w * 0.2, h * 0.28, w * 0.6, h * 0.62)
	draw_rect(body, col.darkened(0.55) * tint)
	draw_rect(body, col * tint, false, 3.0)
	var ey: float = body.position.y + body.size.y * 0.25
	for s in [-1.0, 1.0]:
		draw_rect(Rect2(w * 0.5 + s * w * 0.14 - w * 0.06, ey, w * 0.12, h * 0.045), Color("#fff36b") * tint)


# ---------- Busto anime (segnaposto) ----------
# Pochi tratti ma scelti: capelli nel colore dell'operatore, volto semplice e OCCHI grandi, che cambiano con l'espressione.
# Senza sfondo: la figura sta da sola, come nelle scene di storia. Il volto e' in AnimeFace.

func _draw_anime_bust(col: Color, tint: Color) -> void:
	var w: float = size.x
	var h: float = size.y
	var cx: float = w * 0.5
	var bob: float = sin(_t * 1.6) * 2.0
	var r: float = minf(w * 0.24, h * 0.2)                     # raggio del volto
	var head := Vector2(cx, h * 0.40 + bob)
	var skin_sh: Color = Color("#e3b9a4") * tint
	var cloth: Color = col.darkened(0.55) * tint
	var cached_back: bool = HeadCache.draw(self, head, r, char_id, col, expression, tint, HeadCache.BACK)
	if not cached_back:
		AnimeFace.hair_back(self, head, r, char_id, col, tint)
	# spalle e giacca
	var sh := PackedVector2Array([
		Vector2(cx - w * 0.46, h), Vector2(cx - w * 0.40, h * 0.72 + bob), Vector2(cx - w * 0.16, h * 0.64 + bob),
		Vector2(cx + w * 0.16, h * 0.64 + bob), Vector2(cx + w * 0.40, h * 0.72 + bob), Vector2(cx + w * 0.46, h)])
	draw_colored_polygon(sh, cloth)
	draw_polyline(sh, col * tint, 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(cx - w * 0.14, h * 0.64 + bob), Vector2(cx, h * 0.80 + bob), Vector2(cx + w * 0.14, h * 0.64 + bob)]), skin_sh)
	draw_rect(Rect2(cx - r * 0.3, head.y + r * 0.9, r * 0.6, r * 0.8), skin_sh)       # collo
	if not HeadCache.draw(self, head, r, char_id, col, expression, tint, HeadCache.FRONT):
		AnimeFace.face(self, head, r, char_id, col, tint, expression)
