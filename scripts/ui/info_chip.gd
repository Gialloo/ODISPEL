class_name InfoChip
extends Control

# Piccola etichetta dell'HUD che si puo' puntare o toccare per leggere la spiegazione (vedi HintCard).
# Tipi: testo colorato, e munizioni (icone di proiettile + numero).

var kind: String = "text"
var text: String = ""
var color: Color = BattleTheme.CY
var filled: bool = true          # sfondo colorato (badge) oppure solo testo
var count: int = 0
var max_count: int = 0

const FONT_SIZE: int = 11


static func badge(label: String, tint: Color, solid: bool = true) -> InfoChip:
	var c := InfoChip.new()
	c.text = label
	c.color = tint
	c.filled = solid
	c._fit()
	return c


static func ammo(now: int, most: int, tint: Color) -> InfoChip:
	var c := InfoChip.new()
	c.kind = "ammo"
	c.count = now
	c.max_count = most
	c.color = tint
	c._fit()
	return c


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_HELP


func chip_height() -> float:
	return 24.0 if TouchUi.active() else 17.0


func _font_size() -> int:
	return 14 if TouchUi.active() else FONT_SIZE


func _fit() -> void:
	var h: float = chip_height()
	if kind == "ammo":
		var num_w: float = BattleTheme.mono().get_string_size("x%d" % count, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size()).x
		custom_minimum_size = Vector2(8.0 + float(max_count) * 9.0 + num_w + 6.0, h)
	else:
		var tw: float = BattleTheme.mono().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size()).x
		custom_minimum_size = Vector2(tw + 10.0, h)
	size = custom_minimum_size


func _draw() -> void:
	var h: float = size.y
	var fs: int = _font_size()
	var font: Font = BattleTheme.mono()
	if kind == "ammo":
		_draw_ammo(h, fs, font)
		return
	if filled:
		draw_rect(Rect2(0, 0, size.x, h), Color(color, 0.22))
		draw_rect(Rect2(0, 0, size.x, h), Color(color, 0.8), false, 1.0)
	draw_string(font, Vector2(5.0, h - 4.0 - (h - fs) * 0.25), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


func _draw_ammo(h: float, fs: int, font: Font) -> void:
	draw_rect(Rect2(0, 0, size.x, h), Color(color, 0.14))
	draw_rect(Rect2(0, 0, size.x, h), Color(color, 0.7), false, 1.0)
	var top: float = 3.0
	var bh: float = h - 6.0
	for i in max_count:
		_bullet(Vector2(6.0 + float(i) * 9.0, top), bh, i < count)
	var low: bool = count == 0
	draw_string(font, Vector2(8.0 + float(max_count) * 9.0, h - 4.0 - (h - fs) * 0.25), "x%d" % count, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, BattleTheme.RD if low else color)


# Un proiettile in piedi: punta, corpo e fondello. Pieno se carico, solo contorno se scarico.
func _bullet(at: Vector2, height: float, loaded: bool) -> void:
	var w: float = 6.0
	var tip: float = height * 0.38
	var pts := PackedVector2Array([
		at + Vector2(w * 0.5, 0.0), at + Vector2(w, tip), at + Vector2(w, height), at + Vector2(0.0, height), at + Vector2(0.0, tip),
	])
	if loaded:
		draw_colored_polygon(pts, color)
		draw_line(at + Vector2(0.0, tip + 1.0), at + Vector2(w, tip + 1.0), BattleTheme.BK, 1.0)
		draw_line(at + Vector2(0.0, height - 2.0), at + Vector2(w, height - 2.0), Color(BattleTheme.BK, 0.6), 1.0)
	else:
		var closed: PackedVector2Array = pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, Color(color, 0.4), 1.0)
