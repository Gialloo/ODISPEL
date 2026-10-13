class_name LightningFx
extends Control

# Fulmine neon: percorso spezzato che sfarfalla (si ricalcola ~20 volte al secondo), bagliore a quattro
# strati in fusione additiva, rami, scintille e lampo all'impatto. Si disegna da solo e sparisce.

var from_pt: Vector2 = Vector2.ZERO
var to_pt: Vector2 = Vector2.ZERO
var color: Color = Color("#7cf0ff")
var life: float = 0.32
var power: float = 1.0
var _t: float = 0.0
var _tick: int = -1
var _main: PackedVector2Array = PackedVector2Array()
var _branches: Array = []
var _seed: int = 0

static var _additive: CanvasItemMaterial = null


static func play(parent: Node, a: Vector2, b: Vector2, col: Color, new_life: float = 0.32, new_power: float = 1.0) -> LightningFx:
	var f := LightningFx.new()
	f.from_pt = a
	f.to_pt = b
	f.color = col
	f.life = new_life
	f.power = new_power
	f._seed = int(a.x * 13.0 + b.y * 7.0) & 0xffff
	parent.add_child(f)
	return f


static func additive() -> CanvasItemMaterial:
	if _additive == null:
		_additive = CanvasItemMaterial.new()
		_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _additive


# Percorso spezzato tra a e b: le estremita' restano ferme, il centro oscilla.
static func points(a: Vector2, b: Vector2, seed_value: int, amp: float, segs: int) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var dir: Vector2 = b - a
	var normal: Vector2 = dir.orthogonal().normalized()
	var pts := PackedVector2Array([a])
	for i in range(1, segs):
		var f: float = float(i) / float(segs)
		pts.append(a + dir * f + normal * rng.randf_range(-amp, amp) * sin(f * PI))
	pts.append(b)
	return pts


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	material = additive()


func _process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
		return
	var tick: int = int(_t * 20.0)
	if tick != _tick:
		_tick = tick
		_rebuild()
		queue_redraw()


func _rebuild() -> void:
	var length: float = from_pt.distance_to(to_pt)
	var amp: float = clampf(length * 0.07, 10.0, 34.0) * power
	_main = points(from_pt, to_pt, _seed + _tick * 7919, amp, clampi(int(length / 36.0), 6, 14))
	_branches.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed + _tick * 104729
	for k in 2 + int(power):
		var idx: int = rng.randi_range(2, maxi(2, _main.size() - 3))
		var start: Vector2 = _main[idx]
		var ang: float = (to_pt - from_pt).angle() + rng.randf_range(-1.2, 1.2)
		_branches.append(points(start, start + Vector2(cos(ang), sin(ang)) * rng.randf_range(34.0, 80.0) * power, _seed + k + _tick * 31, 8.0, 4))


func _draw() -> void:
	if _main.size() < 2:
		return
	var k: float = clampf(_t / life, 0.0, 1.0)
	var fade: float = pow(1.0 - k, 1.4)
	var w: float = 6.0 * power
	draw_polyline(_main, Color(color, 0.10 * fade), w * 5.0, true)
	draw_polyline(_main, Color(color, 0.22 * fade), w * 2.8, true)
	draw_polyline(_main, Color(color, 0.85 * fade), w, true)
	draw_polyline(_main, Color(1, 1, 1, fade), maxf(1.5, w * 0.38), true)
	for br in _branches:
		draw_polyline(br, Color(color, 0.30 * fade), w * 1.5, true)
		draw_polyline(br, Color(1, 1, 1, 0.9 * fade), 1.4, true)
	# impatto: bagliore tondo e scintille a raggiera
	var flash: float = (1.0 - k) * power
	draw_circle(to_pt, 26.0 * flash, Color(color, 0.30 * fade))
	draw_circle(to_pt, 11.0 * flash, Color(1, 1, 1, 0.8 * fade))
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed + _tick
	for i in 7:
		var a: float = rng.randf() * TAU
		var d0: float = rng.randf_range(8.0, 20.0)
		var d1: float = d0 + rng.randf_range(14.0, 34.0) * power
		draw_line(to_pt + Vector2(cos(a), sin(a)) * d0, to_pt + Vector2(cos(a), sin(a)) * d1, Color(1, 1, 1, 0.9 * fade), 2.0)
