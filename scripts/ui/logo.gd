class_name OdispelLogo
extends Control

# Logo del gioco, disegnato dal codice: scritta inclinata con contorno, taglio rosso
# dietro e un puntino REC che lampeggia. Se esiste `art/logo.png` viene usato quello.

const TEXT: String = "ODISPEL"
var font_size: int = 78
var _t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(430, 120)
	size = custom_minimum_size


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var art: Texture2D = ArtLibrary.texture("logo.png")
	if art != null:
		var h: float = size.y
		var w: float = h * art.get_width() / maxf(1.0, float(art.get_height()))
		draw_texture_rect(art, Rect2(0, 0, w, h), false)
		return
	var font: Font = BattleTheme.display()
	var tw: float = font.get_string_size(TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	# taglio rosso e ombra
	draw_colored_polygon(PackedVector2Array([Vector2(-8, 70), Vector2(tw + 40, 18), Vector2(tw + 18, 104), Vector2(-26, 112)]), BattleTheme.RD_DARK)
	draw_colored_polygon(PackedVector2Array([Vector2(-14, 62), Vector2(tw + 34, 10), Vector2(tw + 12, 94), Vector2(-32, 102)]), BattleTheme.RD)
	var base := Vector2(2, 92)
	draw_string_outline(font, base + Vector2(4, 4), TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 14, BattleTheme.BK)
	draw_string_outline(font, base, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 14, BattleTheme.BK)
	draw_string(font, base, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BattleTheme.WH)
	# REC
	if int(_t * 1.6) % 2 == 0:
		draw_circle(Vector2(tw + 26, 10), 7.0, BattleTheme.RD)
	draw_string(BattleTheme.mono(), Vector2(tw + 38, 16), "REC", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, BattleTheme.CY)
