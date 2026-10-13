class_name MenuBackdrop
extends Control

# Sfondo dei menu: strisce diagonali che scorrono piano, un grande taglio colorato e
# mezzitoni. Sta dietro ai pannelli e non cattura il mouse. Se esiste l'immagine di
# sfondo del menu (art/backgrounds/hub.png) resta visibile sotto le strisce.

var accent: Color = BattleTheme.RD
var secondary: Color = BattleTheme.CY
var _t: float = 0.0


static func add_to(parent: Control, new_accent: Color = BattleTheme.RD, at_index: int = -1, with_halftone: bool = true) -> MenuBackdrop:
	var b := MenuBackdrop.new()
	b.accent = new_accent
	b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	if at_index >= 0:
		parent.move_child(b, mini(at_index, parent.get_child_count() - 1))
	if with_halftone:
		ScreenFx.halftone(b)
	return b


# Le strisce sono disegnate UNA volta sola in un nodo figlio che poi si limita a scorrere (basta cambiare la posizione,
# nessun ridisegno): lo scorrimento resta fluido a qualsiasi frequenza e costa quasi zero.
const STEP: float = 90.0
const PERIOD: float = STEP * 4.0     # i colori si ripetono ogni 4 strisce
var _stripes: Control


class Stripes extends Control:
	var hot: Color = Color("#ff3fd0")
	var cool: Color = BattleTheme.CY

	func _draw() -> void:
		var h: float = size.y
		var x: float = -h - 5.0 * MenuBackdrop.STEP
		var k: int = 0
		while x < size.x + MenuBackdrop.STEP:
			draw_line(Vector2(x, h), Vector2(x + h * 0.7, 0), Color(hot if k % 4 == 0 else cool, 0.06), 3.0)
			x += MenuBackdrop.STEP
			k += 1


func _ready() -> void:
	_stripes = Stripes.new()
	_stripes.cool = secondary
	_stripes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stripes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_stripes)


func _process(delta: float) -> void:
	_t += delta
	if _stripes != null:
		_stripes.position.x = fmod(_t * 14.0, PERIOD)


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var hot := Color("#ff3fd0")
	var sun := Color("#ffe14d")
	# bagliore magenta in alto a destra e ciano in basso a sinistra
	for i in 6:
		var f: float = float(i) / 5.0
		draw_circle(Vector2(w * 0.92, h * 0.06), 260.0 * (1.0 - f * 0.8), Color(hot, 0.035))
		draw_circle(Vector2(w * 0.05, h * 0.98), 300.0 * (1.0 - f * 0.8), Color(secondary, 0.035))
	# grande taglio diagonale in basso a sinistra
	var cut := PackedVector2Array([Vector2(0, h * 0.55), Vector2(w * 0.62, h * 0.18), Vector2(w * 0.74, h * 0.18), Vector2(w * 0.12, h), Vector2(0, h)])
	draw_colored_polygon(cut, Color(accent, 0.13))
	var cut2 := PackedVector2Array([Vector2(w * 0.55, h), Vector2(w, h * 0.38), Vector2(w, h * 0.62), Vector2(w * 0.78, h)])
	draw_colored_polygon(cut2, Color(secondary, 0.09))
	# terzo taglio giallo/magenta sottile, stile JetSet
	var cut3 := PackedVector2Array([Vector2(w * 0.80, 0), Vector2(w * 0.86, 0), Vector2(w * 0.60, h * 0.34), Vector2(w * 0.54, h * 0.34)])
	draw_colored_polygon(cut3, Color(hot, 0.10))
	draw_line(Vector2(w * 0.54, h * 0.34), Vector2(w * 0.80, 0), Color(sun, 0.22), 3.0)
	# filo bianco lungo il taglio e fila di rombi in alto
	draw_line(Vector2(0, h * 0.55), Vector2(w * 0.62, h * 0.18), Color(1, 1, 1, 0.12), 2.0)
	for i in 5:
		var cx: float = w - 60.0 - float(i) * 26.0
		var cy: float = h - 40.0
		draw_colored_polygon(PackedVector2Array([Vector2(cx, cy - 9.0), Vector2(cx + 9.0, cy), Vector2(cx, cy + 9.0), Vector2(cx - 9.0, cy)]), Color([sun, hot, secondary, sun, hot][i], 0.55))
