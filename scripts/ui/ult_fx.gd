class_name UltFx
extends Control

# Particelle e aura delle ultimate. Tre stili:
#   "strike"  (attacco)  scintille e schegge che esplodono, anelli che si allargano, colonna di luce verso il boss
#   "shield"  (difesa)   esagoni che si espandono e anello di scudo
#   "heal"    (cura)     lucciole che salgono, croci luminose
# Si disegna da solo e sparisce; non cattura il mouse.

const LIFE: float = 1.3

var center: Vector2 = Vector2(640, 400)
var target: Vector2 = Vector2.ZERO
var color: Color = BattleTheme.POP
var style: String = "strike"
var _t: float = 0.0
var _parts: Array = []


static func play(parent: Node, at: Vector2, col: Color, new_style: String, toward: Vector2 = Vector2.ZERO) -> UltFx:
	var f := UltFx.new()
	f.center = at
	f.color = col
	f.style = new_style
	f.target = toward
	parent.add_child(f)
	return f


static func style_for(move: Dictionary) -> String:
	if str(move.get("target", "")) == "enemy":
		return "strike"
	if bool(move.get("cleanse", false)) or move.has("heal"):
		return "heal"
	return "shield"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(center.x * 31.0 + center.y)
	for i in 46:
		var ang: float = rng.randf() * TAU
		var spd: float = rng.randf_range(120.0, 420.0)
		var p := {"a": ang, "s": spd, "life": rng.randf_range(0.6, LIFE), "size": rng.randf_range(3.0, 9.0), "phase": rng.randf() * TAU}
		_parts.append(p)


func _process(delta: float) -> void:
	_t += delta
	if _t > LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k: float = _t / LIFE
	var fade: float = clampf(1.0 - k, 0.0, 1.0)
	# aura a terra e colonna di luce
	var ring_r: float = 40.0 + 150.0 * k
	draw_arc(center + Vector2(0, 70), ring_r, 0.0, TAU, 48, Color(color, 0.8 * fade), 5.0)
	draw_arc(center + Vector2(0, 70), ring_r * 0.62, 0.0, TAU, 48, Color(1, 1, 1, 0.7 * fade), 3.0)
	var pillar_w: float = 70.0 * (1.0 - k * 0.6)
	draw_colored_polygon(PackedVector2Array([Vector2(center.x - pillar_w, center.y + 80), Vector2(center.x - pillar_w * 0.4, -20), Vector2(center.x + pillar_w * 0.4, -20), Vector2(center.x + pillar_w, center.y + 80)]), Color(color, 0.28 * fade))
	match style:
		"strike":
			if target != Vector2.ZERO:
				var w: float = 26.0 * sin(clampf(k * 2.4, 0.0, PI))
				draw_line(center, target, Color(color, 0.5 * fade), w + 10.0)
				draw_line(center, target, Color(1, 1, 1, 0.9 * fade), maxf(1.0, w * 0.4))
			for p in _parts:
				var d: float = float(p["s"]) * _t
				var pos: Vector2 = center + Vector2(cos(float(p["a"])), sin(float(p["a"]))) * d
				var tail: Vector2 = pos - Vector2(cos(float(p["a"])), sin(float(p["a"]))) * float(p["size"]) * 3.0
				var pf: float = clampf(1.0 - _t / float(p["life"]), 0.0, 1.0)
				draw_line(tail, pos, Color(1, 1, 1, pf), float(p["size"]) * 0.5)
				draw_line(tail, pos, Color(color, pf * 0.8), float(p["size"]))
		"shield":
			for i in 3:
				var r: float = (60.0 + float(i) * 55.0) * (0.4 + k * 1.3)
				var pts := PackedVector2Array()
				for j in 7:
					var a: float = float(j) / 6.0 * TAU + float(i)
					pts.append(center + Vector2(cos(a), sin(a)) * r)
				draw_polyline(pts, Color(color, 0.85 * fade), 4.0)
			for p in _parts:
				var pos2: Vector2 = center + Vector2(cos(float(p["a"])), sin(float(p["a"]))) * float(p["s"]) * 0.45 * _t
				var pf2: float = clampf(1.0 - _t / float(p["life"]), 0.0, 1.0)
				draw_rect(Rect2(pos2 - Vector2(4, 4), Vector2(8, 8)), Color(1, 1, 1, pf2 * 0.9))
		"heal":
			for p in _parts:
				var up: float = float(p["s"]) * 0.35 * _t
				var sway: float = sin(_t * 5.0 + float(p["phase"])) * 26.0
				var pos3: Vector2 = Vector2(center.x + cos(float(p["a"])) * 90.0 + sway, center.y + 70.0 - up)
				var pf3: float = clampf(1.0 - _t / float(p["life"]), 0.0, 1.0)
				var sz: float = float(p["size"])
				if int(float(p["phase"]) * 3.0) % 4 == 0:
					draw_rect(Rect2(pos3 - Vector2(sz * 0.4, sz * 1.4), Vector2(sz * 0.8, sz * 2.8)), Color(color, pf3))
					draw_rect(Rect2(pos3 - Vector2(sz * 1.4, sz * 0.4), Vector2(sz * 2.8, sz * 0.8)), Color(color, pf3))
				else:
					draw_circle(pos3, sz * 0.7, Color(1, 1, 1, pf3 * 0.9))
					draw_circle(pos3, sz * 1.4, Color(color, pf3 * 0.35))
