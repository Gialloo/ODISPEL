class_name MenuBackdrop
extends Control

# Sfondo dei menu: strisce diagonali che scorrono piano, un grande taglio colorato e
# mezzitoni. Sta dietro ai pannelli e non cattura il mouse. Se esiste l'immagine di
# sfondo del menu (art/backgrounds/hub.png) resta visibile sotto le strisce.

var accent: Color = BattleTheme.RD
var secondary: Color = BattleTheme.CY
var _t: float = 0.0


static func add_to(parent: Control, new_accent: Color = BattleTheme.RD, at_index: int = -1) -> MenuBackdrop:
	var b := MenuBackdrop.new()
	b.accent = new_accent
	b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	if at_index >= 0:
		parent.move_child(b, mini(at_index, parent.get_child_count() - 1))
	var half := ColorRect.new()
	half.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	half.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/halftone.gdshader")
	half.material = mat
	b.add_child(half)
	return b


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	# grande taglio diagonale in basso a sinistra
	var cut := PackedVector2Array([Vector2(0, h * 0.55), Vector2(w * 0.62, h * 0.18), Vector2(w * 0.74, h * 0.18), Vector2(w * 0.12, h), Vector2(0, h)])
	draw_colored_polygon(cut, Color(accent, 0.10))
	var cut2 := PackedVector2Array([Vector2(w * 0.55, h), Vector2(w, h * 0.38), Vector2(w, h * 0.62), Vector2(w * 0.78, h)])
	draw_colored_polygon(cut2, Color(secondary, 0.07))
	# strisce sottili che scorrono
	var step: float = 90.0
	var off: float = fmod(_t * 14.0, step)
	var x: float = -h - step + off
	while x < w + step:
		draw_line(Vector2(x, h), Vector2(x + h * 0.7, 0), Color(secondary, 0.05), 3.0)
		x += step
	# filo bianco lungo il taglio
	draw_line(Vector2(0, h * 0.55), Vector2(w * 0.62, h * 0.18), Color(1, 1, 1, 0.07), 2.0)
