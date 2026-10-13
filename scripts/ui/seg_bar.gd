class_name SegBar
extends Control

# Barra a segmenti (stile contatore arcade). ratio va da 0 a 1.

var segments: int = 10
var ratio: float = 1.0
var color_on: Color = BattleTheme.CY
var color_off: Color = BattleTheme.CY_DARK
var gap: float = 2.0
var smooth: bool = false        # barre dei PV: la scia chiara mostra quanto si e' perso e poi si svuota
var _ghost: float = 1.0
var _ghost_wait: float = 0.0


func setup(seg_count: int, on: Color, min_size: Vector2) -> SegBar:
	segments = seg_count
	color_on = on
	custom_minimum_size = min_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


func set_ratio(value: float) -> void:
	var r: float = clampf(value, 0.0, 1.0)
	if not is_equal_approx(r, ratio):
		if smooth and r < ratio:
			_ghost = maxf(_ghost, ratio)
			_ghost_wait = 0.45
			set_process(true)
		ratio = r
		if r > _ghost:
			_ghost = r
		queue_redraw()


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if _ghost_wait > 0.0:
		_ghost_wait -= delta
		return
	_ghost = maxf(ratio, _ghost - delta * 0.9)
	queue_redraw()
	if is_equal_approx(_ghost, ratio):
		_ghost = ratio
		set_process(false)


func filled_segments() -> int:
	if ratio <= 0.0:
		return 0
	return clampi(int(ceil(ratio * float(segments) - 0.0001)), 1, segments)


func _draw() -> void:
	if segments <= 0:
		return
	var w: float = (size.x - gap * float(segments - 1)) / float(segments)
	var filled: int = filled_segments()
	var ghost_n: int = clampi(int(ceil(_ghost * float(segments) - 0.0001)), 0, segments) if _ghost > ratio else filled
	for i in segments:
		var x: float = float(i) * (w + gap)
		var c: Color = color_on if i < filled else color_off
		if i >= filled and i < ghost_n:
			c = Color(1, 1, 1, 0.85)
		draw_rect(Rect2(x, 0.0, w, size.y), c)
		if i < filled and size.y >= 6.0:
			# rilievo: luce in alto, ombra in basso; l'ultimo segmento acceso ha un alone
			draw_rect(Rect2(x, 0.0, w, size.y * 0.42), Color(1, 1, 1, 0.22))
			draw_rect(Rect2(x, size.y * 0.78, w, size.y * 0.22), Color(0, 0, 0, 0.22))
			if i == filled - 1 and size.y >= 10.0:
				draw_rect(Rect2(x - 1.0, -1.0, w + 2.0, size.y + 2.0), Color(c, 0.35), false, 1.5)
