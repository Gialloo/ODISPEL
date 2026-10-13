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
func layout(n: int, h: float, gap: float, new_radius: float, mid_deg: float = 22.0, min_top: float = 56.0, max_bottom: float = 700.0) -> Array:
	radius = new_radius
	# distanza verticale FISSA fra i pulsanti; la curva decide solo quanto ognuno e' spostato in orizzontale
	var dy: float = h + gap
	var span: float = dy * float(maxi(0, n - 1))
	var mid_y: float = origin.y + sin(deg_to_rad(mid_deg)) * radius
	var top_y: float = mid_y - span * 0.5 - h * 0.5
	var bot_y: float = mid_y + span * 0.5 + h * 0.5
	var shift: float = 0.0
	if top_y < min_top:
		shift = min_top - top_y
	elif bot_y > max_bottom:
		shift = max_bottom - bot_y
	var pts: Array = []
	var lim: float = radius * 0.97
	var first: float = 0.0
	var last: float = 0.0
	for i in n:
		var y: float = mid_y - span * 0.5 + float(i) * dy
		var rel: float = clampf(y - origin.y, -lim, lim)
		var a: float = asin(rel / radius)
		if i == 0:
			first = a
		last = a
		pts.append(Vector2(origin.x + cos(a) * radius, y + shift))
	var half: float = dy * 0.5 / radius
	_a0 = first - half
	_a1 = last + half
	queue_redraw()
	return pts


func clear_arc() -> void:
	_a0 = 0.0
	_a1 = 0.0
	queue_redraw()


func _draw() -> void:
	pass      # nessuna curva disegnata: solo i pulsanti
