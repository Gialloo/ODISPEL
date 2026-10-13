class_name ComicFx
extends RefCounted

# Effetti "da fumetto/manga": esplosioni con il numero dentro, linee di velocita',
# lampo d'impatto, didascalie inclinate. Tutto si disegna da codice e si auto-elimina.


# Stella a punte irregolari (la "nuvoletta" dei colpi).
static func burst_polygon(radius: float, spikes: int = 12, jitter: float = 0.28, rng_seed: int = 1) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var pts := PackedVector2Array()
	for i in spikes * 2:
		var a: float = TAU * float(i) / float(spikes * 2)
		var r: float = radius if i % 2 == 0 else radius * 0.62
		r *= 1.0 + rng.randf_range(-jitter, jitter) * (1.0 if i % 2 == 0 else 0.4)
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


# Esplosione con testo. Ritorna il nodo (si dissolve da solo).
class Pop extends Control:
	var text: String = ""
	var fill: Color = Color.WHITE
	var ink: Color = Color.BLACK
	var radius: float = 70.0
	var font_size: int = 40
	var _poly: PackedVector2Array
	var _tilt: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_poly = ComicFx.burst_polygon(radius, 11, 0.3, text.hash())
		_tilt = randf_range(-0.22, 0.22)
		pivot_offset = Vector2.ZERO
		scale = Vector2.ZERO
		var tw: Tween = create_tween()
		tw.tween_property(self, "scale", Vector2.ONE * 1.25, 0.09)
		tw.tween_property(self, "scale", Vector2.ONE, 0.07)
		tw.tween_interval(0.5)
		tw.tween_property(self, "modulate:a", 0.0, 0.3)
		tw.tween_callback(queue_free)
		var drift: Tween = create_tween()
		drift.tween_property(self, "position:y", position.y - 26.0, 0.9)

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, _tilt, Vector2.ONE)
		# ombra netta, poi riempimento e contorno nero spesso
		var shadow := PackedVector2Array()
		for p in _poly:
			shadow.append(p + Vector2(6, 6))
		draw_colored_polygon(shadow, Color(0, 0, 0, 0.8))
		draw_colored_polygon(_poly, fill)
		var ring: PackedVector2Array = _poly.duplicate()
		ring.append(_poly[0])
		draw_polyline(ring, ink, 5.0, true)
		var f: Font = BattleTheme.display()
		var sz: Vector2 = f.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var pos := Vector2(-sz.x * 0.5, sz.y * 0.28)
		draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 8, Color.WHITE)
		draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)


static func pop(parent: Node, text: String, pos: Vector2, fill: Color = BattleTheme.POP, ink: Color = Color.BLACK, size: int = 40, radius: float = 70.0) -> Pop:
	var p := Pop.new()
	p.text = text
	p.fill = fill
	p.ink = ink
	p.font_size = size
	p.radius = radius
	p.position = pos
	parent.add_child(p)
	return p


# Linee di velocita' che partono dal centro e si dissolvono.
class SpeedLines extends Control:
	var center: Vector2 = Vector2.ZERO
	var color: Color = Color.WHITE
	var inner: float = 120.0
	var outer: float = 900.0
	var count: int = 46
	var life: float = 0.22
	var _t: float = 0.0
	var _angles: Array = []
	var _widths: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for i in count:
			_angles.append(randf() * TAU)
			_widths.append(randf_range(0.01, 0.045))

	func _process(delta: float) -> void:
		_t += delta
		if _t >= life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k: float = clampf(_t / life, 0.0, 1.0)
		var a: float = 1.0 - k
		var reach: float = lerpf(outer * 0.5, outer, k)
		for i in count:
			var ang: float = float(_angles[i])
			var w: float = float(_widths[i])
			var dir := Vector2(cos(ang), sin(ang))
			var tip: Vector2 = center + dir * reach
			var base1: Vector2 = center + Vector2(cos(ang - w), sin(ang - w)) * inner
			var base2: Vector2 = center + Vector2(cos(ang + w), sin(ang + w)) * inner
			draw_colored_polygon(PackedVector2Array([base1, tip, base2]), Color(color, a))


static func speed_lines(parent: Node, center: Vector2, color: Color = Color.WHITE, life: float = 0.22) -> SpeedLines:
	var s := SpeedLines.new()
	s.center = center
	s.color = color
	s.life = life
	parent.add_child(s)
	return s


# Lampo a tutto schermo (bianco o nero) che si spegne in fretta: il "fotogramma d'impatto".
static func flash(parent: Node, color: Color = Color.WHITE, seconds: float = 0.12) -> void:
	if Settings.flash < 0.05:
		return
	var r := ColorRect.new()
	r.color = Color(color.r, color.g, color.b, color.a * Settings.flash)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ScreenFrame.overshoot(r)
	parent.add_child(r)
	var tw: Tween = r.create_tween()
	tw.tween_property(r, "modulate:a", 0.0, seconds)
	tw.tween_callback(r.queue_free)


# Didascalia inclinata che scatta da sinistra (nome dell'abilita', "ALLARME", ecc.).
class Caption extends Control:
	var text: String = ""
	var accent: Color = BattleTheme.RD
	var width: float = 520.0
	var hold: float = 0.7

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(width, 64)
		var box := SlantBox.make(BattleTheme.BK, accent, 22.0, accent.darkened(0.5), 3.0)
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", box)
		panel.size = size
		add_child(panel)
		var label := BattleTheme.make_label(text, 30, BattleTheme.WH, true)
		panel.add_child(label)
		modulate.a = 0.0
		var start_x: float = position.x - 260.0
		var end_x: float = position.x
		position.x = start_x
		var tw: Tween = create_tween()
		tw.set_parallel(true)
		tw.tween_property(self, "position:x", end_x, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "modulate:a", 1.0, 0.08)
		tw.chain().tween_interval(hold)
		tw.chain().tween_property(self, "modulate:a", 0.0, 0.2)
		tw.chain().tween_callback(queue_free)


static func caption(parent: Node, text: String, pos: Vector2, accent: Color = BattleTheme.RD, hold: float = 0.7) -> Caption:
	var c := Caption.new()
	c.text = text
	c.accent = accent
	c.hold = hold
	c.position = pos
	parent.add_child(c)
	return c
