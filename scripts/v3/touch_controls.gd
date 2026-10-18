class_name TouchControls
extends Control

# Comandi touch dell'esplorazione (stesso approccio della mappa V2):
#  - meta' sinistra: stick fluttuante (compare dove appoggi il pollice)
#  - meta' destra: trascina per ruotare la camera
#  - tasto azione rotondo in basso a destra
# Eventi touch grezzi, piu' dita insieme. Sul PC non si disegna nulla (salvo TouchUi.force).

signal action_pressed
signal action2_pressed

const R: float = 95.0
var stick: Vector2 = Vector2.ZERO          # -1..1 (y negativa = avanti)
var cam_drag: Vector2 = Vector2.ZERO       # pixel trascinati dall'ultimo fotogramma (si azzera dopo la lettura)
var act_label: String = ""
var act_live: bool = false
var act2_label: String = ""            # secondo tasto (es. ATTACCA), piu' piccolo, a sinistra del primo

var _stick_idx: int = -1
var _cam_idx: int = -1
var _base: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO
var _cam_last: Vector2 = Vector2.ZERO
var _t: float = 0.0


func _ready() -> void:
	Ui.place(self, 0, 0, 1, 1)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _home() -> Vector2:
	return Vector2(190, size.y - 175)


func act2_center() -> Vector2:
	return act_center() + Vector2(-185, 45)


func act_center() -> Vector2:
	return Vector2(size.x - 165, size.y - 165)


func _process(delta: float) -> void:
	_t += delta
	if TouchUi.active():
		queue_redraw()


func take_cam_drag() -> Vector2:
	var d: Vector2 = cam_drag
	cam_drag = Vector2.ZERO
	return d


func release_all() -> void:
	_stick_idx = -1
	_cam_idx = -1
	stick = Vector2.ZERO


# Da chiamare da _input della scena (cosi' riceve i tocchi anche sopra il 3D)
func handle(event: InputEvent) -> bool:
	if not TouchUi.active():
		return false
	if event is InputEventScreenTouch:
		var e: InputEventScreenTouch = event
		if e.pressed:
			if act_live and e.position.distance_to(act_center()) < 95.0:
				action_pressed.emit()
				return true
			if act2_label != "" and e.position.distance_to(act2_center()) < 75.0:
				action2_pressed.emit()
				return true
			if e.position.x < size.x * 0.45 and _stick_idx < 0:
				_stick_idx = e.index
				_base = e.position
				_knob = Vector2.ZERO
				stick = Vector2.ZERO
				return true
			if e.position.x >= size.x * 0.45 and _cam_idx < 0:
				_cam_idx = e.index
				_cam_last = e.position
				return true
		else:
			if e.index == _stick_idx:
				_stick_idx = -1
				stick = Vector2.ZERO
				return true
			if e.index == _cam_idx:
				_cam_idx = -1
				return true
	elif event is InputEventScreenDrag:
		var d: InputEventScreenDrag = event
		if d.index == _stick_idx:
			var off: Vector2 = d.position - _base
			if off.length() > R * 1.6:
				_base = d.position - off.normalized() * R * 1.6      # lo stick segue il pollice se esce troppo
				off = d.position - _base
			_knob = off.limit_length(R)
			stick = _knob / R
			return true
		if d.index == _cam_idx:
			cam_drag += d.position - _cam_last
			_cam_last = d.position
			return true
	return false


func _draw() -> void:
	if not TouchUi.active():
		return
	var on: bool = _stick_idx >= 0
	var c: Vector2 = _base if on else _home()
	var a: float = 0.9 if on else 0.5
	draw_circle(c + Vector2(6, 6), R, Color(0.04, 0.03, 0.08, 0.35 * a))
	draw_circle(c, R, Color(1.0, 0.95, 0.84, 0.25 * a + 0.08))
	draw_arc(c, R, 0.0, TAU, 48, Color(0.04, 0.03, 0.08, a), 6.0, true)
	var k: Vector2 = c + (_knob if on else Vector2.ZERO)
	draw_circle(k, 44.0, Color(0.04, 0.03, 0.08, a))
	draw_circle(k, 36.0, Color(1.0, 0.24, 0.55, a))
	if act_label != "":
		var ac: Vector2 = act_center()
		var al: float = 1.0 if act_live else 0.45
		var p: float = 1.0 + (0.06 * sin(_t * 6.0) if act_live else 0.0)
		draw_circle(ac + Vector2(7, 7), 72.0 * p, Color(1.0, 0.24, 0.55, al))
		draw_circle(ac, 72.0 * p, Color(0.04, 0.03, 0.08, al))
		draw_circle(ac, 65.0 * p, Color(1.0, 0.88, 0.29, al) if act_live else Color(0.8, 0.78, 0.7, al))
		var f: Font = Ui.display()
		var fs: int = 22
		var w: float = f.get_string_size(act_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, ac + Vector2(-w * 0.5, 8.0), act_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.04, 0.03, 0.08, 1.0))
	if act2_label != "":
		var bc: Vector2 = act2_center()
		var q: float = 1.0 + 0.08 * sin(_t * 8.0)
		draw_circle(bc + Vector2(6, 6), 56.0 * q, Color(0.04, 0.03, 0.08, 1.0))
		draw_circle(bc, 56.0 * q, Color(0.04, 0.03, 0.08, 1.0))
		draw_circle(bc, 50.0 * q, Color(1.0, 0.24, 0.55, 1.0))
		var f2: Font = Ui.display()
		var w2: float = f2.get_string_size(act2_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		draw_string(f2, bc + Vector2(-w2 * 0.5, 7.0), act2_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.97, 0.9, 1.0))
