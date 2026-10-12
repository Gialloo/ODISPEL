class_name HudPanel
extends Control

# Pannello dell'HUD: angoli tagliati, ombra sfalsata e linguetta col titolo.

var title: String = ""
var accent: Color = BattleTheme.CY
var cut: float = 14.0
var margins: Vector4 = Vector4(14.0, 30.0, 14.0, 12.0)   # sinistra, alto, destra, basso


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


func _draw() -> void:
	draw_colored_polygon(_shape(Vector2(5.0, 5.0)), Color(accent, 0.28))
	draw_colored_polygon(_shape(), Color(BattleTheme.PANEL, 0.80))
	var outline: PackedVector2Array = _shape()
	outline.append(outline[0])
	draw_polyline(outline, accent, 2.0)
	if title != "":
		var font: Font = BattleTheme.display()
		var tw: float = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		var tab: PackedVector2Array = PackedVector2Array([
			Vector2(12.0, -12.0), Vector2(12.0 + tw + 34.0, -12.0), Vector2(12.0 + tw + 20.0, 12.0), Vector2(12.0, 12.0)])
		draw_colored_polygon(tab, accent)
		draw_string(font, Vector2(24.0, 6.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, BattleTheme.BK)
