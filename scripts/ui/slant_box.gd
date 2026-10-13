class_name SlantBox
extends StyleBox

# Riquadro "a parallelogramma" con ombra netta, alla Persona: tutti i pulsanti e le
# etichette importanti del gioco lo usano. Disegna un poligono inclinato invece di
# un rettangolo; il bordo e l'ombra sono opzionali.

var fill: Color = Color.BLACK
var border: Color = Color.WHITE
var border_width: float = 2.0
var skew: float = 14.0                         # di quanto e' inclinato il bordo
var shadow: Color = Color(0, 0, 0, 0.0)        # ombra netta spostata in basso a destra
var shadow_offset: Vector2 = Vector2(5, 5)
var hatch: Color = Color(1, 1, 1, 0.0)           # righe oblique chiare sopra il riempimento (serve texture_repeat sul nodo)
var gloss: float = 0.0                           # lucentezza: velo chiaro nella meta' alta


static func make(new_fill: Color, new_border: Color, new_skew: float = 14.0, new_shadow: Color = Color(0, 0, 0, 0), width: float = 2.0) -> SlantBox:
	var s := SlantBox.new()
	s.fill = new_fill
	s.border = new_border
	s.skew = new_skew
	s.shadow = new_shadow
	s.border_width = width
	s.content_margin_left = new_skew + 10.0
	s.content_margin_right = new_skew + 10.0
	s.content_margin_top = 7.0
	s.content_margin_bottom = 7.0
	return s


func _points(rect: Rect2, offset: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var p: Vector2 = rect.position + offset
	var w: float = rect.size.x - absf(shadow_offset.x if shadow.a > 0.0 else 0.0)
	var h: float = rect.size.y - absf(shadow_offset.y if shadow.a > 0.0 else 0.0)
	return PackedVector2Array([
		Vector2(p.x + skew, p.y), Vector2(p.x + w, p.y),
		Vector2(p.x + w - skew, p.y + h), Vector2(p.x, p.y + h)])


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if shadow.a > 0.0:
		RenderingServer.canvas_item_add_polygon(to_canvas_item, _points(rect, shadow_offset), PackedColorArray([shadow]))
	var pts: PackedVector2Array = _points(rect)
	RenderingServer.canvas_item_add_polygon(to_canvas_item, pts, PackedColorArray([fill]))
	if hatch.a > 0.0:
		RenderingServer.canvas_item_add_polygon(to_canvas_item, pts, PackedColorArray([hatch, hatch, hatch, hatch]), UiTex.uvs_for(pts), UiTex.hatch().get_rid())
	if gloss > 0.0:
		var mid: float = (pts[0].y + pts[3].y) * 0.5
		var top := PackedVector2Array([pts[0], pts[1], Vector2(pts[1].x - skew * 0.5, mid), Vector2(pts[0].x - skew * 0.5, mid)])
		var hi := Color(1, 1, 1, gloss)
		var lo := Color(1, 1, 1, 0.0)
		RenderingServer.canvas_item_add_polygon(to_canvas_item, top, PackedColorArray([hi, hi, lo, lo]))
	if border_width > 0.0 and border.a > 0.0:
		var ring: PackedVector2Array = pts.duplicate()
		ring.append(pts[0])
		RenderingServer.canvas_item_add_polyline(to_canvas_item, ring, PackedColorArray([border]), border_width, true)
