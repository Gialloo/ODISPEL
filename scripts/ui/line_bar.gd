class_name LineBar
extends Control

# Barra semplice a una linea: riempimento pieno su fondo scuro, con un tratto opzionale (scudo) dopo il riempimento.

var ratio: float = 1.0
var shield_ratio: float = 0.0
var color_on: Color = BattleTheme.HP
var color_shield: Color = BattleTheme.GOLD
var color_bg: Color = Color(0, 0, 0, 0.45)


func setup(on: Color, min_size: Vector2) -> LineBar:
	color_on = on
	custom_minimum_size = min_size
	size = min_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


# value e shield sono frazioni dello stesso totale; se insieme superano 1 si riscalano per entrare nella barra.
func set_values(value: float, shield: float = 0.0) -> void:
	var v: float = maxf(value, 0.0)
	var s: float = maxf(shield, 0.0)
	var total: float = v + s
	if total > 1.0:
		v /= total
		s /= total
	ratio = v
	shield_ratio = s
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color_bg)
	var w: float = size.x
	draw_rect(Rect2(0.0, 0.0, w * ratio, size.y), color_on)
	if shield_ratio > 0.0:
		draw_rect(Rect2(w * ratio, 0.0, w * shield_ratio, size.y), color_shield)
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.18), false, 1.0)
