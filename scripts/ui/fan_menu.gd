class_name FanMenu
extends Control

# Menu a ventaglio: i comandi si dispongono su un arco attorno al personaggio attivo.
# Qui si disegna solo l'arco (guida discreta); i pulsanti li posiziona chi usa il ventaglio con layout().

var origin: Vector2 = Vector2(230.0, 360.0)
var radius: float = 220.0
var tint: Color = Color("#ff3d6e")
var _a0: float = 0.0
var _a1: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


# Posizioni (centro di ogni pulsante) per n comandi alti h: disposti sull'arco, centrati leggermente in alto.
func layout(n: int, h: float, gap: float, new_radius: float) -> Array:
	radius = new_radius
	var min_step: float = (h + gap) / radius
	var step: float = maxf(min_step, deg_to_rad(16.0 if n <= 4 else (13.5 if n <= 6 else 12.0)))
	var span: float = step * float(maxi(0, n - 1))
	var mid: float = deg_to_rad(22.0)
	# se l'arco uscirebbe dallo schermo lo si sposta senza cambiare la forma
	var top_y: float = origin.y + sin(mid - span * 0.5) * radius - h * 0.5
	var bot_y: float = origin.y + sin(mid + span * 0.5) * radius + h * 0.5
	var shift: float = 0.0
	if top_y < 56.0:
		shift = 56.0 - top_y
	elif bot_y > 700.0:
		shift = 700.0 - bot_y
	var pts: Array = []
	for i in n:
		var a: float = mid - span * 0.5 + float(i) * step
		pts.append(origin + Vector2(cos(a), sin(a)) * radius + Vector2(0.0, shift))
	_a0 = mid - span * 0.5 - step * 0.5
	_a1 = mid + span * 0.5 + step * 0.5
	queue_redraw()
	return pts


func clear_arc() -> void:
	_a0 = 0.0
	_a1 = 0.0
	queue_redraw()


func _draw() -> void:
	if _a1 <= _a0:
		return
	var pts := PackedVector2Array()
	var n: int = 24
	for i in n + 1:
		var a: float = lerpf(_a0, _a1, float(i) / float(n))
		pts.append(origin + Vector2(cos(a), sin(a)) * (radius - 14.0))
	draw_polyline(pts, Color(tint, 0.35), 3.0, true)
	draw_polyline(pts, Color(1.0, 1.0, 1.0, 0.18), 1.0, true)
	draw_circle(origin, 5.0, Color(tint, 0.8))
