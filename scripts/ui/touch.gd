extends Control

const M = preload("res://scripts/player/moves.gd")
## Comandi touch: stick mobile a sinistra, trascinamento a destra per la telecamera,
## tasti grandi per il pollice destro. Multitouch con indice per ogni dito.

signal gear_pressed

var look_scale := 1.7
var power: Node                    # per disegnare le ricariche
var _pw_id := -1
var _pw_start := Vector2.ZERO
var _pw_t := 0
var _pw_done := false
var _pw_last := ""
var _pw_last_t := 0
const SWIPE := 42.0
var _stick_id := -1
var _stick_center := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _look_id := -1
var _look_last := Vector2.ZERO
var _btn_touch := {}               # indice dito -> nome tasto
var _look_tap_t := 0               # doppio tocco sulla visuale = aggancio
var _look_tap_p := Vector2.ZERO
var _look_down_t := 0
var _look_moved := 0.0
var _font: Font

const STICK_R := 95.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = load("res://assets/fonts/ArchivoBlack-Regular.ttf")

func _buttons() -> Dictionary:
	var s := size
	return {
		"attack": {"pos": Vector2(s.x - 165, s.y - 150), "r": 82.0, "label": "ATTACCO", "col": Color(0.35, 0.95, 1.0)},
		"dodge": {"pos": Vector2(s.x - 330, s.y - 92), "r": 58.0, "label": "SCHIVA", "col": Color(1, 1, 1)},
		"jump": {"pos": Vector2(s.x - 92, s.y - 305), "r": 56.0, "label": "SALTO", "col": Color(1, 1, 1)},
		"power": {"pos": Vector2(s.x - 305, s.y - 262), "r": 62.0, "label": "POTERE", "col": Color(0.85, 0.6, 1.0)},
		"lock": {"pos": Vector2(s.x - 190, s.y - 400), "r": 52.0, "label": "LOCK", "col": Color(1, 0.85, 0.3)},
	}

func _gear_rect() -> Rect2:
	return Rect2(Vector2(size.x - 86, 14), Vector2(70, 60))

func _input(event: InputEvent) -> void:
	if not visible or get_tree().paused:
		# 0.9: con i comandi nascosti (scelta, menu) le dita alzate vanno comunque registrate,
		# altrimenti la visuale restava "occupata" da un dito che non c'è più e non scorreva
		if event is InputEventScreenTouch and not event.pressed:
			_release_all()
		return
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		if event.pressed:
			if _gear_rect().has_point(p):
				gear_pressed.emit()
				return
			for n in _buttons():
				var b: Dictionary = _buttons()[n]
				if p.distance_to(b.pos) <= b.r * 1.15:
					if n == "power":
						# POTERE: scorri su = SPINGI, giù = ATTIRA, tocco = SOVRACCARICA
						_pw_id = event.index
						_pw_start = p
						_pw_t = Time.get_ticks_msec()
						_pw_done = false
						queue_redraw()
						return
					_btn_touch[event.index] = n
					Pad.press(n)
					queue_redraw()
					return
			if event.index == _stick_id:
				_stick_id = -1
			if p.x < size.x * 0.42 and _stick_id == -1:
				_stick_id = event.index
				_stick_center = p
				_stick_pos = p
			elif p.x >= size.x * 0.42 or _look_id == -1:
				# l'ultimo dito sulla destra prende sempre la visuale
				_look_id = event.index
				_look_last = p
				var now := Time.get_ticks_msec()
				if now - _look_tap_t < 320 and p.distance_to(_look_tap_p) < 90.0:
					Pad.tap("lock")
					_look_tap_t = 0
				_look_down_t = now
				_look_moved = 0.0
			queue_redraw()
		else:
			if event.index == _pw_id:
				if not _pw_done and Time.get_ticks_msec() - _pw_t < 400:
					_fire("alter")
				_pw_id = -1
			if _btn_touch.has(event.index):
				Pad.release(_btn_touch[event.index])
				_btn_touch.erase(event.index)
			if event.index == _stick_id:
				_stick_id = -1
				Pad.move = Vector2.ZERO
			if event.index == _look_id:
				_look_id = -1
				if Time.get_ticks_msec() - _look_down_t < 220 and _look_moved < 18.0:
					_look_tap_t = Time.get_ticks_msec()
					_look_tap_p = event.position
			queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == _pw_id:
			var dy: float = event.position.y - _pw_start.y
			if not _pw_done and absf(dy) >= SWIPE:
				_pw_done = true
				_fire("push" if dy < 0 else "pull")
			return
		if event.index == _stick_id:
			_stick_pos = event.position
			var v: Vector2 = (_stick_pos - _stick_center)
			if v.length() > STICK_R:
				# lo stick segue il dito: niente pollice "fuori corsa"
				_stick_center = _stick_pos - v.normalized() * STICK_R
				v = v.normalized() * STICK_R
			var m := v / STICK_R
			Pad.move = Vector2(m.x, -m.y)
			queue_redraw()
		elif event.index == _look_id or (_look_id == -1 and event.position.x >= size.x * 0.42 and not _btn_touch.has(event.index)):
			if _look_id == -1:
				_look_id = event.index
				_look_last = event.position
			Pad.look += (event.position - _look_last) * look_scale
			_look_moved += (event.position - _look_last).length()
			_look_last = event.position

func _fire(a: String) -> void:
	Pad.tap(a)
	_pw_last = a
	_pw_last_t = Time.get_ticks_msec()

func _release_all() -> void:
	for i in _btn_touch:
		Pad.release(_btn_touch[i])
	_btn_touch.clear()
	_stick_id = -1
	_look_id = -1
	_pw_id = -1
	Pad.move = Vector2.ZERO

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_release_all()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		for i in _btn_touch:
			Pad.release(_btn_touch[i])
		_btn_touch.clear()
		_stick_id = -1
		_look_id = -1
		_pw_id = -1
		Pad.move = Vector2.ZERO

func _process(_d: float) -> void:
	queue_redraw()

func _tri(c: Vector2, dir: int, col: Color) -> void:
	var h := 12.0 * dir
	draw_colored_polygon(PackedVector2Array([c + Vector2(-13, -h * 0.5), c + Vector2(13, -h * 0.5), c + Vector2(0, h * 0.7)]), col)

func _draw() -> void:
	# stick
	if _stick_id != -1:
		draw_circle(_stick_center, STICK_R, Color(1, 1, 1, 0.08))
		draw_arc(_stick_center, STICK_R, 0, TAU, 40, Color(1, 1, 1, 0.3), 3.0)
		var knob := _stick_center + (_stick_pos - _stick_center).limit_length(STICK_R)
		draw_circle(knob, 42, Color(1, 1, 1, 0.35))
	else:
		var c := Vector2(170, size.y - 160)
		draw_arc(c, STICK_R, 0, TAU, 40, Color(1, 1, 1, 0.12), 3.0)
	# tasti
	var held := {}
	for i in _btn_touch:
		held[_btn_touch[i]] = true
	for n in _buttons():
		var b: Dictionary = _buttons()[n]
		var on: bool = held.has(n) or Pad.held(n)
		var col: Color = b.col
		if n == "attack" and power and power.player and power.player.has_method("next_form"):
			# il tasto prende il colore della forma che uscirà: viola = VECTOR pronto
			col = M.FORM_COLOR[power.player.next_form()]
		draw_circle(b.pos, b.r, Color(col, 0.32 if on else 0.14))
		draw_arc(b.pos, b.r, 0, TAU, 40, Color(col, 0.9 if on else 0.55), 4.0 if on else 3.0)
		var fs := 22 if b.r > 70 else 17
		var w := _font.get_string_size(b.label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		draw_string(_font, b.pos + Vector2(-w * 0.5, fs * 0.35), b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.9))
		if n == "attack" and power and power.player and power.player.has_method("next_form"):
			var fn: String = M.FORM_NAME[power.player.next_form()]
			var fw := _font.get_string_size(fn, HORIZONTAL_ALIGNMENT_CENTER, -1, 15).x
			draw_string(_font, b.pos + Vector2(-fw * 0.5, 34), fn, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(col, 0.95))
	# POTERE: frecce del gesto e ricariche
	var pb: Dictionary = _buttons()["power"]
	var pc: Vector2 = pb.pos
	var pr: float = pb.r
	var flash := Time.get_ticks_msec() - _pw_last_t < 180
	_tri(pc + Vector2(0, -pr - 18), -1, Color(0.7, 0.95, 1.0, 0.95 if flash and _pw_last == "push" else 0.6))
	_tri(pc + Vector2(0, pr + 18), 1, Color(0.85, 0.5, 1.0, 0.95 if flash and _pw_last == "pull" else 0.6))
	if power:
		var cols := {"push": Color(0.7, 0.95, 1.0), "pull": Color(0.85, 0.5, 1.0), "alter": Color(1, 0.85, 0.2)}
		var i := 0
		for k in ["push", "pull", "alter"]:
			var cr: float = power.cooldown_ratio(k)
			if cr > 0.0:
				var a0 := -PI * 0.5 + i * TAU / 3.0
				draw_arc(pc, pr + 6 + i * 5, a0, a0 + TAU / 3.0 * cr, 16, Color(cols[k], 0.85), 4.0)
			i += 1
	# ingranaggio del laboratorio
	var g := _gear_rect()
	draw_rect(g, Color(0, 0, 0, 0.35))
	var gw := _font.get_string_size("LAB", HORIZONTAL_ALIGNMENT_CENTER, -1, 20).x
	draw_string(_font, g.get_center() + Vector2(-gw * 0.5, 8), "LAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.8))
