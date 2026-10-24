class_name ReactGame
extends Control

# MINIGIOCHI DELLE REAZIONI: prima ogni difesa era lo stesso cerchio da toccare a tempo. Ora ogni reazione si gioca a modo suo,
# cosi' si capisce cosa sta facendo il personaggio:
#   SCHIVA   (arrow) - compare una freccia: tocca quel lato dello schermo (o freccia/A/D). Ci si butta di lato.
#   COPRI    (hold)  - tieni premuto: la barra sale; lascia quando e' nella fascia. Ci si pianta davanti e si regge il colpo.
#   FERMA    (mash)  - tocca a raffica finche' la barra si riempie. Si spinge il nemico fuori tempo.
#   SOCCORRI (beat)  - tocca a tempo col battito del cuore, tre volte. Si rianima un compagno.
# Esito: "great" (riuscito) o "fail" (sbagliato). Anche sbagliata la reazione funziona, ma vale meno (BattleResolver.react_grade).
# Il tempo si ferma in pausa (Engine.time_scale = 0). Si usa cosi': var g := ReactGame.new("arrow", "SAUL", col); add_child(g); await g.done

signal done(grade: String)

const TITLES: Dictionary = {"arrow": "SCHIVA", "hold": "COPRI", "mash": "FERMA", "beat": "SOCCORRI"}
const MASH_TAPS: int = 7
const HOLD_TIME: float = 1.1          # dal vuoto al pieno
const ZONE: Vector2 = Vector2(0.62, 0.86)
const BEATS: int = 3
const BEAT_GAP: float = 0.62
const BEAT_OK: float = 0.17

var mode: String = "arrow"
var who: String = ""
var col: Color = Color.WHITE
var slow: bool = false                # prima volta: piu' tempo per leggere
var t: float = 0.0
var limit: float = 1.2
var _dir: int = 1                     # freccia: -1 sinistra, 1 destra
var _fill: float = 0.0
var _holding: bool = false
var _held_once: bool = false
var _taps: int = 0
var _beat_hits: int = 0
var _beat_done: Array = []
var _over: bool = false
var _title: Label
var _sub: Label


func _init(m: String, name_txt: String, c: Color, first_time: bool = false) -> void:
	mode = m
	who = name_txt
	col = c
	slow = first_time
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.place(self, 0, 0, 1, 1)
	_dir = -1 if randf() < 0.5 else 1
	match mode:
		"arrow":
			limit = 1.9 if slow else 1.1
		"hold":
			limit = 3.0 if slow else 2.2
		"mash":
			limit = 2.8 if slow else 2.1
		"beat":
			limit = 0.5 + BEAT_GAP * float(BEATS) + 0.3
			for i in BEATS:
				_beat_done.append(false)
	# titolo grande (56): e' la prima cosa che il giocatore legge quando la finestra si apre; entra con uno scatto (Persona 5)
	_title = Ui.label("%s · %s" % [str(TITLES.get(mode, "")), who], 56, col.lightened(0.3), Ui.display(), 12)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ui.place(_title, 0.1, 0.2, 0.9, 0.2, 0, 28, 0, 108)      # 28 px piu' giu': sopra c'e' la riga DEBOLE A del nemico
	add_child(_title)
	_sub = Ui.label(_how(), 30, Ui.CREAM, null, 10)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ui.place(_sub, 0.15, 0.68, 0.85, 0.68, 0, 0, 0, 90)
	add_child(_sub)


func _ready() -> void:
	_title.pivot_offset = Vector2(size.x * 0.4, 40)
	_title.scale = Vector2(1.5, 1.5)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(_title, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Scritta grande nel disegno (con contorno scuro): il comando da dare in questo istante, leggibile da lontano
func _cue(text: String, at: Vector2, size_px: int, c: Color) -> void:
	var f: Font = Ui.display()
	draw_string_outline(f, at, text, HORIZONTAL_ALIGNMENT_CENTER, 600.0, size_px, 14, Ui.INK)
	draw_string(f, at, text, HORIZONTAL_ALIGNMENT_CENTER, 600.0, size_px, c)


func _how() -> String:
	match mode:
		"arrow":
			return "Tocca il lato %s dello schermo" % ("SINISTRO" if _dir < 0 else "DESTRO")
		"hold":
			return "Tieni premuto e lascia quando la barra è nella fascia"
		"mash":
			return "Tocca a raffica finché la barra si riempie"
		"beat":
			return "Tocca quando il cuore batte (tre volte)"
	return ""


func _process(delta: float) -> void:
	if _over or Engine.time_scale <= 0.0:
		return
	var rd: float = delta / Engine.time_scale          # tempo vero: x2 e rallentatori non cambiano la difficolta'
	t += rd
	if mode == "hold" and _holding:
		_fill += rd / HOLD_TIME
		if _fill >= 1.0:
			_finish("fail")
			return
	if mode == "beat":
		# un battito passato senza tocco conta come perso
		for i in BEATS:
			if not bool(_beat_done[i]) and t > _beat_t(i) + BEAT_OK:
				_beat_done[i] = true
	if t >= limit:
		match mode:
			"beat":
				_finish("great" if _beat_hits >= 2 else "fail")
			"hold":
				_finish("fail")
			_:
				_finish("fail")
		return
	queue_redraw()


func _beat_t(i: int) -> float:
	return 0.5 + BEAT_GAP * float(i)


func _input(event: InputEvent) -> void:
	if _over or Engine.time_scale <= 0.0:
		return
	var down: bool = false
	var up: bool = false
	var x: float = -1.0
	if event is InputEventScreenTouch:
		down = event.pressed
		up = not event.pressed
		x = (event as InputEventScreenTouch).position.x
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		down = event.pressed
		up = not event.pressed
		x = (event as InputEventMouseButton).position.x
	elif event is InputEventKey and not event.echo:
		var k: int = (event as InputEventKey).physical_keycode
		if k in [KEY_LEFT, KEY_A]:
			x = 0.0
		elif k in [KEY_RIGHT, KEY_D]:
			x = get_viewport_rect().size.x
		elif not k in [KEY_SPACE, KEY_ENTER, KEY_R, KEY_1, KEY_4]:
			return
		down = event.pressed
		up = not event.pressed
	else:
		return
	get_viewport().set_input_as_handled()
	match mode:
		"arrow":
			if down and x >= 0.0:
				var left: bool = x < get_viewport_rect().size.x * 0.5
				_finish("great" if left == (_dir < 0) else "fail")
		"hold":
			if down:
				_holding = true
				_held_once = true
			elif up and _held_once:
				_holding = false
				_finish("great" if _fill >= ZONE.x and _fill <= ZONE.y else "fail")
		"mash":
			if down:
				_taps += 1
				Settings.buzz(8)
				if _taps >= MASH_TAPS:
					_finish("great")
		"beat":
			if down:
				var best: int = -1
				for i in BEATS:
					if not bool(_beat_done[i]) and absf(t - _beat_t(i)) <= BEAT_OK:
						best = i
				if best >= 0:
					_beat_done[best] = true
					_beat_hits += 1
					Settings.buzz(15)
	queue_redraw()


func _finish(grade: String) -> void:
	if _over:
		return
	_over = true
	Settings.buzz(40 if grade == "great" else 12)
	_title.text = "PERFETTO!" if grade == "great" else "QUASI..."
	_title.scale = Vector2(1.3, 1.3)          # esito con scatto: la conferma arriva subito
	create_tween().set_ignore_time_scale(true).tween_property(_title, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_title.add_theme_color_override("font_color", Ui.YELLOW if grade == "great" else Color("#c4c2cf"))
	_sub.text = "" if grade == "great" else "La reazione vale meno"
	queue_redraw()
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_interval(0.45)
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func() -> void:
		done.emit(grade)
		queue_free())


func _draw() -> void:
	var sz: Vector2 = size
	var c: Vector2 = sz * Vector2(0.5, 0.45)
	var left: float = clampf(1.0 - t / maxf(0.01, limit), 0.0, 1.0)
	# barra del tempo che resta, sotto il titolo
	var tw: float = sz.x * 0.4
	# barra del tempo piu' spessa; negli ultimi istanti diventa rossa (urgenza leggibile senza numeri)
	draw_rect(Rect2(c.x - tw * 0.5, sz.y * 0.2 + 118, tw, 14), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(c.x - tw * 0.5, sz.y * 0.2 + 118, tw * left, 14), col if left > 0.3 or _over else Color("#ff4a5a"))
	match mode:
		"arrow":
			# freccia grande verso il lato giusto, e il lato giusto dello schermo illuminato
			var side_x: float = 0.0 if _dir < 0 else sz.x * 0.5
			draw_rect(Rect2(side_x, 0, sz.x * 0.5, sz.y), Color(col.r, col.g, col.b, 0.12))
			var d: float = float(_dir)
			var tip := c + Vector2(d * 130, 0)
			var pts := PackedVector2Array([tip, c + Vector2(d * 40, -80), c + Vector2(d * 40, -32), c + Vector2(-d * 110, -32),
				c + Vector2(-d * 110, 32), c + Vector2(d * 40, 32), c + Vector2(d * 40, 80)])
			draw_colored_polygon(pts, Color(0, 0, 0, 0.6))
			var inner := PackedVector2Array()
			for p in pts:
				inner.append(c + (p - c) * 0.88)
			draw_colored_polygon(inner, col.lightened(0.2))
			# al centro della meta' libera: a destra le card della squadra (circa 400 px) coprivano "TOCCA QUI" a meta'
			var free_c: float = sz.x * 0.25 if _dir < 0 else sz.x * 0.5 + (sz.x * 0.5 - 400.0) * 0.5
			draw_rect(Rect2(side_x if _dir < 0 else sz.x - 12.0, 0, 12.0, sz.y), Color(col, 0.7))      # bordo acceso sul lato da toccare
			_cue("TOCCA QUI", Vector2(free_c - 300.0, sz.y * 0.66), 48, Ui.YELLOW)
		"hold":
			var w: float = 70.0
			var h: float = 220.0          # piu' bassa di prima (260): non tocca piu' il titolo e la barra del tempo
			var r := Rect2(c.x - w * 0.5, c.y - h * 0.5 + 34.0, w, h)
			draw_rect(r.grow(6), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(r.position.x, r.end.y - h * ZONE.y, w, h * (ZONE.y - ZONE.x)), Color(Ui.YELLOW.r, Ui.YELLOW.g, Ui.YELLOW.b, 0.45))
			draw_rect(Rect2(r.position.x, r.end.y - h * _fill, w, h * _fill), col.lightened(0.15))
			draw_rect(r, Ui.CREAM, false, 4.0)
			# cosa fare adesso: TIENI finche' sale, LASCIA! quando la barra e' nella fascia gialla (la fascia lampeggia)
			var in_zone: bool = _holding and _fill >= ZONE.x and _fill <= ZONE.y
			if in_zone:
				draw_rect(Rect2(r.position.x, r.end.y - h * ZONE.y, w, h * (ZONE.y - ZONE.x)), Color(1, 1, 1, 0.55))
			_cue("LASCIA!" if in_zone else ("TIENI..." if _holding else "TIENI PREMUTO"), Vector2(c.x + 60.0, c.y + 40.0), 44, Ui.YELLOW if in_zone else Ui.CREAM)
		"mash":
			var w2: float = 420.0
			var r2 := Rect2(c.x - w2 * 0.5, c.y - 30, w2, 60)
			draw_rect(r2.grow(6), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(r2.position, Vector2(w2 * float(_taps) / float(MASH_TAPS), 60)), col.lightened(0.15))
			draw_rect(r2, Ui.CREAM, false, 4.0)
			_cue("TOCCA TOCCA!   %d/%d" % [_taps, MASH_TAPS], Vector2(c.x - 300.0, r2.end.y + 70.0), 44, Ui.YELLOW)
		"beat":
			# il cuore: si gonfia su ogni battito; i tre pallini dicono quanti battiti hai preso
			var pulse: float = 0.0
			for i in BEATS:
				pulse = maxf(pulse, 1.0 - clampf(absf(t - _beat_t(i)) / 0.25, 0.0, 1.0))
			var rr: float = 46.0 + 30.0 * pulse
			draw_circle(c + Vector2(-rr * 0.45, 0), rr * 0.62, Color("#ff5a6e"))
			draw_circle(c + Vector2(rr * 0.45, 0), rr * 0.62, Color("#ff5a6e"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-rr * 1.02, rr * 0.18), c + Vector2(rr * 1.02, rr * 0.18), c + Vector2(0, rr * 1.25)]), Color("#ff5a6e"))
			draw_arc(c, 120, 0, TAU, 48, Color(1, 1, 1, 0.25 + 0.5 * pulse), 4.0)
			# ORA! mentre il battito da prendere e' nella finestra giusta
			for i in BEATS:
				if not bool(_beat_done[i]) and absf(t - _beat_t(i)) <= BEAT_OK:
					_cue("ORA!", Vector2(c.x - 460.0, c.y + 10.0), 56, Ui.YELLOW)
			for i in BEATS:
				var on: bool = bool(_beat_done[i]) and i < _beat_hits + (BEATS - _beat_hits)
				draw_circle(c + Vector2(-40 + 40 * i, 150), 12, Ui.YELLOW if (bool(_beat_done[i]) and i < _beat_hits) else Color(1, 1, 1, 0.3 if not on else 0.5))
