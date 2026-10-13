class_name AnimFx
extends RefCounted

# Libreria di animazioni disegnate da codice (nessuna immagine): colpi, cure, scudi, frammenti, pioggia,
# portale del reclutamento, bagliori sui pulsanti, striscia del round. Tutto si elimina da solo.
# Si spengono con la qualita' grafica BASSA (enabled()), tranne cio' che serve a capire cosa succede.


static func enabled() -> bool:
	return Settings.quality_name() != "BASSA"


const MAX_LIVE: int = 48
static var _live: int = 0


static func _add(parent: Node, c: Control, pos: Vector2) -> Control:
	# tetto agli effetti vivi insieme: con decine di colpi in un round il telefono non deve soffrire
	if _live >= MAX_LIVE:
		c.free()
		return null
	c.position = pos
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_live += 1
	c.tree_exited.connect(func() -> void: _live = maxi(0, _live - 1))
	parent.add_child(c)
	return c


# ---------- Base: un controllo che vive `life` secondi ----------

class Timed extends Control:
	var life: float = 0.5
	var t: float = 0.0
	var k: float = 0.0              # 0..1 avanzamento

	func _process(delta: float) -> void:
		t += delta
		k = clampf(t / life, 0.0, 1.0)
		queue_redraw()
		if t >= life:
			queue_free()


# ---------- Colpi ----------

# Tagli diagonali che si allargano e svaniscono.
class Slash extends Timed:
	var col: Color = Color.WHITE
	var ang: float = -0.6
	var power: float = 1.0

	func _init() -> void:
		life = 0.28

	func _draw() -> void:
		var a: float = 1.0 - k
		var reach: float = (60.0 + 70.0 * power) * (0.4 + 0.6 * minf(1.0, k * 3.0))
		for i in 3:
			var off: float = (float(i) - 1.0) * 16.0
			var d := Vector2(cos(ang), sin(ang))
			var n := Vector2(-d.y, d.x)
			var c: Vector2 = n * off
			var w: float = (7.0 - 2.0 * absf(float(i) - 1.0)) * power * (1.0 - k * 0.7)
			draw_line(c - d * reach * 0.2, c + d * reach, Color(col, a * 0.95), maxf(1.0, w), true)
			draw_line(c - d * reach * 0.2, c + d * reach * 0.8, Color(1, 1, 1, a), maxf(1.0, w * 0.4), true)


# Anello d'urto che si espande.
class Shockwave extends Timed:
	var col: Color = Color.WHITE
	var radius: float = 120.0

	func _init() -> void:
		life = 0.38

	func _draw() -> void:
		var e: float = 1.0 - pow(1.0 - k, 3.0)
		var r: float = radius * e
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(col, (1.0 - k) * 0.9), 8.0 * (1.0 - k) + 1.0, true)
		draw_arc(Vector2.ZERO, r * 0.7, 0.0, TAU, 32, Color(1, 1, 1, (1.0 - k) * 0.6), 3.0, true)


# Scintille con gravita'.
class Sparks extends Timed:
	var col: Color = Color.WHITE
	var count: int = 14
	var speed: float = 260.0
	var _dirs: Array = []
	var _spd: Array = []

	func _init() -> void:
		life = 0.55

	func _ready() -> void:
		for i in count:
			_dirs.append(randf() * TAU)
			_spd.append(randf_range(0.4, 1.0))

	func _draw() -> void:
		for i in _dirs.size():
			var d := Vector2(cos(_dirs[i]), sin(_dirs[i]))
			var dist: float = speed * float(_spd[i]) * (1.0 - pow(1.0 - k, 2.0))
			var p: Vector2 = d * dist + Vector2(0.0, 120.0 * k * k)
			var tail: Vector2 = p - d * (14.0 * (1.0 - k))
			draw_line(tail, p, Color(col, 1.0 - k), 3.0 * (1.0 - k) + 1.0, true)


# Proiettile con scia da un punto a un altro; poi chiama on_hit.
class Projectile extends Timed:
	var from: Vector2 = Vector2.ZERO
	var to: Vector2 = Vector2.ZERO
	var col: Color = Color.WHITE
	var on_hit: Callable = Callable()
	var _fired: bool = false

	func _init() -> void:
		life = 0.16

	func _draw() -> void:
		var head: Vector2 = from.lerp(to, k) - position
		var tail: Vector2 = from.lerp(to, maxf(0.0, k - 0.35)) - position
		draw_line(tail, head, Color(col, 0.55), 6.0, true)
		draw_line(tail.lerp(head, 0.5), head, Color(1, 1, 1, 0.95), 3.0, true)
		draw_circle(head, 5.0, Color(1, 1, 1, 0.95))

	func _process(delta: float) -> void:
		super._process(delta)
		if t >= life and not _fired:
			_fired = true
			if on_hit.is_valid():
				on_hit.call()


# ---------- Cure e scudi ----------

# Croci/particelle che salgono (cura).
class Rise extends Timed:
	var col: Color = Color("#6bffb0")
	var count: int = 9
	var _x: Array = []
	var _d: Array = []

	func _init() -> void:
		life = 1.0

	func _ready() -> void:
		for i in count:
			_x.append(randf_range(-46.0, 46.0))
			_d.append(randf_range(0.0, 0.35))

	func _draw() -> void:
		for i in _x.size():
			var kk: float = clampf((k - float(_d[i])) / (1.0 - float(_d[i])), 0.0, 1.0)
			if kk <= 0.0:
				continue
			var p := Vector2(float(_x[i]) + sin(kk * 6.0 + float(i)) * 6.0, -kk * 110.0)
			var a: float = sin(kk * PI)
			var s: float = 7.0 + float(i % 3) * 2.0
			draw_line(p + Vector2(-s, 0), p + Vector2(s, 0), Color(col, a), 3.0)
			draw_line(p + Vector2(0, -s), p + Vector2(0, s), Color(col, a), 3.0)
		draw_arc(Vector2.ZERO, 40.0 + 30.0 * k, 0.0, TAU, 32, Color(col, (1.0 - k) * 0.5), 3.0)


# Scudo a esagono: si accende; se `broken` si spezza in frammenti.
class ShieldHex extends Timed:
	var col: Color = Color("#7cf0ff")
	var broken: bool = false
	var radius: float = 70.0

	func _init() -> void:
		life = 0.55

	func _hex(r: float, rot: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 6:
			var a: float = rot + float(i) * TAU / 6.0
			pts.append(Vector2(cos(a), sin(a) * 1.15) * r)
		return pts

	func _draw() -> void:
		var a: float = 1.0 - k
		if not broken:
			var pts: PackedVector2Array = _hex(radius * (0.8 + 0.25 * sin(k * PI)), 0.0)
			draw_colored_polygon(pts, Color(col, 0.18 * a))
			pts.append(pts[0])
			draw_polyline(pts, Color(col, a), 4.0, true)
			return
		for i in 6:
			var a0: float = float(i) * TAU / 6.0
			var a1: float = a0 + TAU / 6.0
			var out: Vector2 = Vector2(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5)) * 60.0 * k
			var p0 := Vector2(cos(a0), sin(a0) * 1.15) * radius + out
			var p1 := Vector2(cos(a1), sin(a1) * 1.15) * radius + out
			draw_line(p0, p1, Color(col, a), 4.0 * a + 1.0, true)


# ---------- Morte del boss ----------

# Frammenti che schizzano via e svaniscono.
class Shards extends Timed:
	var col: Color = Color.WHITE
	var count: int = 38
	var spread: Vector2 = Vector2(260.0, 220.0)
	var _p: Array = []
	var _v: Array = []
	var _s: Array = []
	var _r: Array = []

	func _init() -> void:
		life = 1.3

	func _ready() -> void:
		for i in count:
			_p.append(Vector2(randf_range(-spread.x, spread.x) * 0.5, randf_range(-spread.y, spread.y) * 0.5))
			var dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.2, 0.6)).normalized()
			_v.append(dir * randf_range(80.0, 360.0))
			_s.append(randf_range(8.0, 26.0))
			_r.append(randf() * TAU)

	func _draw() -> void:
		var a: float = 1.0 - k * k
		for i in _p.size():
			var p: Vector2 = _p[i] + _v[i] * k + Vector2(0.0, 380.0 * k * k)
			var s: float = float(_s[i]) * (1.0 - k * 0.5)
			var r: float = float(_r[i]) + k * 5.0
			var pts := PackedVector2Array([
				p + Vector2(cos(r), sin(r)) * s,
				p + Vector2(cos(r + 2.2), sin(r + 2.2)) * s * 0.7,
				p + Vector2(cos(r + 4.0), sin(r + 4.0)) * s * 0.9])
			draw_colored_polygon(pts, Color(col.lerp(Color.WHITE, 0.4), a))


# ---------- Striscia del round ----------

class RoundBanner extends Timed:
	var text: String = "ROUND 1"
	var col: Color = Color("#ff4630")

	func _init() -> void:
		life = 1.3

	func _draw() -> void:
		var w: float = size.x if size.x > 0.0 else 1280.0
		var slide: float
		if k < 0.2:
			slide = 1.0 - pow(k / 0.2, 0.5)
		elif k > 0.8:
			slide = -((k - 0.8) / 0.2)
		else:
			slide = 0.0
		var x: float = slide * w
		var y: float = 0.0
		var h: float = 78.0
		var band := PackedVector2Array([Vector2(x - 40.0, y), Vector2(x + w, y), Vector2(x + w - 50.0, y + h), Vector2(x - 90.0, y + h)])
		draw_colored_polygon(band, Color(0.02, 0.04, 0.08, 0.86))
		draw_polyline(PackedVector2Array([band[0], band[1], band[2], band[3], band[0]]), col, 4.0, true)
		var f: Font = BattleTheme.display()
		var sz: Vector2 = f.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 54)
		draw_string_outline(f, Vector2(x + w * 0.5 - sz.x * 0.5, y + 56.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 54, 8, Color.BLACK)
		draw_string(f, Vector2(x + w * 0.5 - sz.x * 0.5, y + 56.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Color.WHITE)


# ---------- Pioggia e neon (sfondi dei menu) ----------

class Rain extends Control:
	var drops: int = 46
	var _x: PackedFloat32Array = PackedFloat32Array()
	var _y: PackedFloat32Array = PackedFloat32Array()
	var _s: PackedFloat32Array = PackedFloat32Array()
	var _t: float = 0.0
	var _flash: float = 0.0
	var tint: Color = Color("#7cf0ff")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if Settings.quality_name() == "MEDIA":
			drops = 24
		visibility_changed.connect(func() -> void: set_process(is_visible_in_tree()))
		for i in drops:
			_x.append(randf() * 1400.0)
			_y.append(randf() * 760.0)
			_s.append(randf_range(0.6, 1.4))

	func _process(delta: float) -> void:
		_t += delta
		for i in drops:
			_y[i] += 520.0 * _s[i] * delta
			_x[i] -= 90.0 * _s[i] * delta
			if _y[i] > 740.0 or _x[i] < -20.0:
				_y[i] = -20.0
				_x[i] = randf() * 1400.0
		_flash = maxf(0.0, _flash - delta * 2.0)
		if randf() < delta * 0.18:
			_flash = 1.0           # un neon che sfarfalla ogni tanto
		queue_redraw()

	func _draw() -> void:
		for i in drops:
			var p := Vector2(_x[i], _y[i])
			draw_line(p, p + Vector2(-5.0, 24.0) * _s[i], Color(tint, 0.14 * _s[i]), 1.5)
		if _flash > 0.0:
			var f: float = _flash * (0.6 + 0.4 * sin(_t * 60.0))
			draw_rect(Rect2(0, 0, size.x, size.y), Color(tint.r, tint.g, tint.b, 0.035 * f))


# ---------- Bagliore che scorre sui pulsanti ----------

class Glint extends Control:
	var period: float = 3.2
	var _t: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		clip_contents = true
		visibility_changed.connect(func() -> void: set_process(is_visible_in_tree()))
		_t = randf() * period

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var k: float = fposmod(_t, period) / period
		if k > 0.35:
			return
		var e: float = k / 0.35
		var x: float = lerpf(-size.y, size.x + size.y, e)
		var w: float = size.y * 0.55
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + w, 0), Vector2(x + w - size.y * 0.5, size.y), Vector2(x - size.y * 0.5, size.y)]),
			Color(1, 1, 1, 0.22 * sin(e * PI)))


# ---------- Portale del reclutamento ----------

class Portal extends Control:
	signal done
	var rarity: int = 0
	var _t: float = 0.0
	var _life: float = 1.2
	var _end_sent: bool = false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_life = [1.0, 1.3, 1.8, 2.3][clampi(rarity, 0, 3)]

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t >= _life and not _end_sent:
			_end_sent = true
			done.emit()
			queue_free()

	func _gui_input(event: InputEvent) -> void:
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			_t = maxf(_t, _life - 0.05)       # un tocco salta

	func _unhandled_key_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo:
			get_viewport().set_input_as_handled()
			_t = maxf(_t, _life - 0.05)

	func _draw() -> void:
		var col: Color = PullReveal.color_of(rarity)
		var k: float = clampf(_t / _life, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.05, 0.9 * minf(1.0, k * 6.0)))
		var c: Vector2 = size * 0.5
		var charge: float = pow(k, 1.6)
		var shake := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 6.0 * charge * float(rarity)
		c += shake
		for i in 5:
			var r: float = lerpf(420.0, 40.0, charge) * (0.35 + 0.65 * float(i + 1) / 5.0) + 10.0 * sin(_t * 5.0 + float(i))
			draw_arc(c, r, _t * (1.5 + float(i) * 0.4), _t * (1.5 + float(i) * 0.4) + PI * 1.4, 36, Color(col, 0.25 + 0.5 * charge), 3.0 + float(i), true)
		for i in 16:
			var a: float = float(i) / 16.0 * TAU + _t * 2.0
			var d: float = lerpf(380.0, 30.0, charge)
			draw_line(c + Vector2(cos(a), sin(a)) * d, c + Vector2(cos(a), sin(a)) * (d + 38.0 * charge), Color(col, 0.7 * charge), 3.0)
		draw_circle(c, 18.0 + 60.0 * charge, Color(col, 0.25 + 0.5 * charge))
		draw_circle(c, 8.0 + 26.0 * charge, Color(1, 1, 1, 0.9 * charge))
		if k > 0.85:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, (k - 0.85) / 0.15 * 0.9))
		var f: Font = BattleTheme.display()
		var txt: String = "..." if k < 0.5 else ["RECLUTAMENTO", "SEGNALE RARO", "SEGNALE EPICO", "SEGNALE LEGGENDARIO"][clampi(rarity, 0, 3)]
		var sz: Vector2 = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 34)
		draw_string_outline(f, Vector2(c.x - sz.x * 0.5, size.y - 90.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, 6, Color.BLACK)
		draw_string(f, Vector2(c.x - sz.x * 0.5, size.y - 90.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, col)


# ---------- Funzioni di comodo ----------

static func slash(parent: Node, pos: Vector2, col: Color, power: float = 1.0) -> void:
	var s := Slash.new()
	s.col = col
	s.power = power
	s.ang = randf_range(-0.9, -0.3) if randf() < 0.5 else randf_range(0.3, 0.9) + PI
	_add(parent, s, pos)


static func shockwave(parent: Node, pos: Vector2, col: Color, radius: float = 120.0) -> void:
	var s := Shockwave.new()
	s.col = col
	s.radius = radius
	_add(parent, s, pos)


static func sparks(parent: Node, pos: Vector2, col: Color, count: int = 14, speed: float = 260.0) -> void:
	var s := Sparks.new()
	s.col = col
	s.count = count
	s.speed = speed
	_add(parent, s, pos)


static func projectile(parent: Node, from: Vector2, to: Vector2, col: Color, on_hit: Callable = Callable()) -> void:
	var p := Projectile.new()
	p.from = from
	p.to = to
	p.col = col
	p.on_hit = on_hit
	_add(parent, p, Vector2.ZERO)


static func rise(parent: Node, pos: Vector2, col: Color = Color("#6bffb0")) -> void:
	var r := Rise.new()
	r.col = col
	_add(parent, r, pos)


static func shield(parent: Node, pos: Vector2, broken: bool = false, col: Color = Color("#7cf0ff")) -> void:
	var s := ShieldHex.new()
	s.broken = broken
	s.col = col
	_add(parent, s, pos)


static func shards(parent: Node, pos: Vector2, col: Color = Color.WHITE, spread: Vector2 = Vector2(260.0, 220.0)) -> void:
	var s := Shards.new()
	s.col = col
	s.spread = spread
	_add(parent, s, pos)


static func round_banner(parent: Control, text: String) -> void:
	var b := RoundBanner.new()
	b.text = text
	b.size = Vector2(1280.0, 80.0)
	_add(parent, b, Vector2(0.0, 250.0))


static func rain(parent: Control, tint: Color = Color("#7cf0ff")) -> void:
	if not enabled():
		return
	var r := Rain.new()
	r.tint = tint
	parent.add_child(r)


static func glint(button: Control) -> void:
	if not enabled() or button.has_node("Glint"):
		return
	var g := Glint.new()
	g.name = "Glint"
	button.add_child(g)


static func portal(host: Node, rarity: int, on_done: Callable) -> void:
	var p := Portal.new()
	p.rarity = rarity
	p.done.connect(func() -> void: on_done.call())
	host.add_child(p)


# Numeri che "salgono": sposta un'etichetta da `from` a `to` in mezzo secondo.
static func count_up(label: Label, from: int, to: int, fmt: String = "%d") -> void:
	if not enabled() or label == null or not label.is_inside_tree():
		label.text = fmt % to
		return
	var tw: Tween = label.create_tween()
	tw.tween_method(func(v: float) -> void: label.text = fmt % int(round(v)), float(from), float(to), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# Scritta che sale e svanisce (es. "LV +1").
static func float_text(parent: Node, text: String, pos: Vector2, col: Color, size: int = 30) -> void:
	var l := BattleTheme.make_label(text, size, col, true)
	l.add_theme_color_override("font_outline_color", BattleTheme.BK)
	l.add_theme_constant_override("outline_size", 8)
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	var tw: Tween = l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", pos.y - 80.0, 1.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)


# Pulsante che "chiama": piccolo battito ogni tanto (qualcosa da riscuotere, da reclutare).
static func nudge(button: Control) -> void:
	if not enabled() or not button.is_inside_tree():
		return
	button.pivot_offset = button.size * 0.5
	var tw: Tween = button.create_tween().set_loops()
	tw.tween_interval(2.4)
	tw.tween_property(button, "scale", Vector2(1.025, 1.06), 0.1)
	tw.tween_property(button, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
