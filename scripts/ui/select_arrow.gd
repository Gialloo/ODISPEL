class_name SelectArrow
extends Control

# Freccia che rimbalza sopra il personaggio a cui tocca scegliere. Sta nello strato degli effetti,
# quindi si vede sempre sopra pannelli e targhette. `tip` e' la punta, nelle coordinate del genitore.

var tip: Vector2 = Vector2.ZERO
var color: Color = BattleTheme.POP
var _t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(60.0, 70.0)
	set_process(visible)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process(visible)


func point_at(p: Vector2) -> void:
	tip = p
	position = p - Vector2(size.x * 0.5, size.y)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var bob: float = absf(sin(_t * 5.0)) * 9.0
	var cx: float = size.x * 0.5
	var y: float = size.y - 32.0 - bob
	var arrow := PackedVector2Array([
		Vector2(cx, y + 32.0), Vector2(cx - 24.0, y), Vector2(cx - 9.0, y),
		Vector2(cx - 9.0, y - 22.0), Vector2(cx + 9.0, y - 22.0), Vector2(cx + 9.0, y), Vector2(cx + 24.0, y)])
	# alone, corpo e contorno scuro: si legge su qualsiasi sfondo
	var halo := PackedVector2Array()
	for p in arrow:
		halo.append(Vector2(cx, y) + (p - Vector2(cx, y)) * 1.28)
	draw_colored_polygon(halo, Color(color, 0.28))
	draw_colored_polygon(arrow, color)
	draw_polyline(arrow + PackedVector2Array([arrow[0]]), BattleTheme.BK, 3.0)
