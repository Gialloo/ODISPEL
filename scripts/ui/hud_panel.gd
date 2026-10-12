class_name HudPanel
extends Control

# Pannello dell'HUD: angoli tagliati, ombra sfalsata e linguetta col titolo.

var title: String = ""
var accent: Color = BattleTheme.CY
var cut: float = 14.0
var bare: bool = false       # senza cornice: solo una velatura scura, il contenuto sta sulla scena
var quiet: bool = false      # pannello secondario: solo velo e filo sottile, niente ombra ne' linguetta
var margins: Vector4 = Vector4(18.0, 30.0, 18.0, 12.0)   # sinistra, alto, destra, basso


func setup(panel_title: String, panel_accent: Color = BattleTheme.CY) -> HudPanel:
	title = panel_title
	accent = panel_accent
	return self


# Il contenuto riempie il pannello, dentro i margini.
func set_content(c: Control) -> void:
	add_child(c)
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = margins.x
	c.offset_top = margins.y
	c.offset_right = -margins.z
	c.offset_bottom = -margins.w


func _shape(offset: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var w: float = size.x
	var h: float = size.y
	return PackedVector2Array([
		Vector2(cut, 0.0) + offset, Vector2(w, 0.0) + offset, Vector2(w, h - cut) + offset,
		Vector2(w - cut, h) + offset, Vector2(0.0, h) + offset, Vector2(0.0, cut) + offset,
	])


func _draw_quiet() -> void:
	draw_colored_polygon(_shape(), Color(BattleTheme.PANEL, 0.5))
	var outline: PackedVector2Array = _shape()
	outline.append(outline[0])
	draw_polyline(outline, Color(accent, 0.55), 1.5)
	if title != "":
		draw_string(BattleTheme.hud(), Vector2(cut + 2.0, 19.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(accent, 0.9))


func _draw() -> void:
	if bare:
		draw_colored_polygon(_shape(), Color(BattleTheme.PANEL, 0.38))
		return
	if quiet:
		_draw_quiet()
		return
	draw_colored_polygon(_shape(Vector2(5.0, 5.0)), Color(accent, 0.28))
	draw_colored_polygon(_shape(), Color(BattleTheme.PANEL, 0.80))
	var outline: PackedVector2Array = _shape()
	outline.append(outline[0])
	draw_polyline(outline, accent, 2.0)
	if title != "":
		var font: Font = BattleTheme.hud()
		var tw: float = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		var tab: PackedVector2Array = PackedVector2Array([
			Vector2(12.0, -12.0), Vector2(12.0 + tw + 34.0, -12.0), Vector2(12.0 + tw + 20.0, 12.0), Vector2(12.0, 12.0)])
		draw_colored_polygon(tab, accent)
		draw_string(font, Vector2(24.0, 6.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, BattleTheme.BK)
		# tre chevron dopo la linguetta e un filo luminoso lungo il bordo alto
		for i in 3:
			var cx: float = 12.0 + tw + 44.0 + float(i) * 11.0
			draw_polyline(PackedVector2Array([Vector2(cx, -8.0), Vector2(cx + 7.0, 0.0), Vector2(cx, 8.0)]), Color(accent, 0.75 - 0.2 * float(i)), 3.0)
		draw_line(Vector2(cut + 4.0, 3.0), Vector2(size.x - 6.0, 3.0), Color(1, 1, 1, 0.10), 1.0)
