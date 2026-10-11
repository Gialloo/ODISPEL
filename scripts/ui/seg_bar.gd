class_name SegBar
extends Control

# Barra a segmenti (stile contatore arcade). ratio va da 0 a 1.

var segments: int = 10
var ratio: float = 1.0
var color_on: Color = BattleTheme.CY
var color_off: Color = BattleTheme.CY_DARK
var gap: float = 2.0


func setup(seg_count: int, on: Color, min_size: Vector2) -> SegBar:
	segments = seg_count
	color_on = on
	custom_minimum_size = min_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


func set_ratio(value: float) -> void:
	var r: float = clampf(value, 0.0, 1.0)
	if not is_equal_approx(r, ratio):
		ratio = r
		queue_redraw()


func filled_segments() -> int:
	if ratio <= 0.0:
		return 0
	return clampi(int(ceil(ratio * float(segments) - 0.0001)), 1, segments)


func _draw() -> void:
	if segments <= 0:
		return
	var w: float = (size.x - gap * float(segments - 1)) / float(segments)
	var filled: int = filled_segments()
	for i in segments:
		var x: float = float(i) * (w + gap)
		draw_rect(Rect2(x, 0.0, w, size.y), color_on if i < filled else color_off)
