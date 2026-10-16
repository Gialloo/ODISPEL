class_name HudPanel
extends Control

# Pannello dell'HUD: angoli tagliati, ombra sfalsata e linguetta col titolo.

var title: String = ""
var accent: Color = BattleTheme.CY
var cut: float = 14.0
var bare: bool = false       # senza cornice: solo una velatura scura, il contenuto sta sulla scena
var backdrop: float = 1.0    # opacita' dello sfondo (il testo non cambia)
var quiet: bool = false      # pannello secondario: solo velo e filo sottile, niente ombra ne' linguetta
var margins: Vector4 = Vector4(18.0, 30.0, 18.0, 12.0)   # sinistra, alto, destra, basso


func setup(panel_title: String, panel_accent: Color = BattleTheme.CY) -> HudPanel:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
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


# Grana e riflesso del pannello: righe oblique chiare, velo di luce in alto, tacche negli angoli.
func _draw_surface(strength: float) -> void:
	var shape: PackedVector2Array = _shape()
	var tint := Color(1, 1, 1, 0.075 * strength).lerp(Color(accent, 0.12 * strength), 0.5)
	draw_polygon(shape, PackedColorArray([tint, tint, tint, tint, tint, tint]), UiTex.uvs_for(shape), UiTex.hatch())
	var gh: float = minf(44.0, size.y * 0.35)
	var hi := Color(accent, 0.10 * strength)         # velo di luce discreto: la luce serve alla gerarchia, non all'ornamento
	var lo := Color(accent, 0.0)
	draw_polygon(PackedVector2Array([Vector2(cut, 0.0), Vector2(size.x, 0.0), Vector2(size.x, gh), Vector2(0.0, gh)]), PackedColorArray([hi, hi, lo, lo]))


func _draw_quiet() -> void:
	draw_colored_polygon(_shape(), Color(BattleTheme.PANEL, 0.5))
	_draw_surface(0.5)
	var outline: PackedVector2Array = _shape()
	outline.append(outline[0])
	draw_polyline(outline, Color(accent, 0.55), 1.5)
	if title != "":
		draw_string(BattleTheme.display(), Vector2(cut + 2.0, 19.0), title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(accent, 0.9))


func _draw() -> void:
	if bare:
		draw_colored_polygon(_shape(), Color(BattleTheme.PANEL, minf(0.92, 0.38 * backdrop)))
		_draw_surface(0.45)
		return
	if quiet:
		_draw_quiet()
		return
	draw_colored_polygon(_shape(Vector2(5.0, 5.0)), Color(accent, 0.28 * backdrop))
	draw_colored_polygon(_shape(), Color(BattleTheme.PANEL, 0.80 * backdrop))
	_draw_surface(1.0)
	var outline: PackedVector2Array = _shape()
	outline.append(outline[0])
	draw_polyline(outline, accent, 2.0)
	if title != "":
		var font: Font = BattleTheme.display()
		var shown: String = title.to_upper()
		var tw: float = font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var tab: PackedVector2Array = PackedVector2Array([
			Vector2(12.0, -12.0), Vector2(12.0 + tw + 34.0, -12.0), Vector2(12.0 + tw + 20.0, 12.0), Vector2(12.0, 12.0)])
		draw_colored_polygon(tab, accent)
		draw_string(font, Vector2(24.0, 7.0), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, BattleTheme.BK)
		# (niente chevron ne' fili luminosi: la linguetta col titolo basta)
