class_name ProfileCard
extends Control

# Icona del profilo (ProfileIcon) e carta con banner, nome e icona (ProfileCard).
# Si usano nell'hub, nella lobby e nella chat. I dati sono {name, icon, banner}.


class ProfileIcon extends Control:
	var icon_id: String = "c_sword"
	var _glyph: Control
	var _t: float = 0.0

	func setup(id: String, px: float) -> ProfileIcon:
		icon_id = id if Profile.icon_valid(id) else "c_sword"
		custom_minimum_size = Vector2(px, px)
		size = Vector2(px, px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var inset: float = maxf(3.0, px * 0.14)
		if icon_id.begins_with("char:"):
			var face := PortraitView.new().setup(icon_id.substr(5), "icon")
			face.show_expression_text = false
			_glyph = face
		else:
			var def: Array = Profile.ICONS[icon_id]
			_glyph = GameIcon.new().setup(str(def[2]), Color(str(def[3])), px - inset * 2.0)
		_glyph.position = Vector2(inset, inset)
		_glyph.size = Vector2(px, px) - Vector2(inset, inset) * 2.0
		_glyph.custom_minimum_size = _glyph.size
		_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_glyph)
		set_process(Profile.rarity_of(icon_id) >= 1 and AnimFx.enabled())
		return self

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var r: int = Profile.rarity_of(icon_id)
		var col: Color = Profile.RARITY_COLORS[r]
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color(0.04, 0.06, 0.1, 0.92))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.5)), Color(col.r, col.g, col.b, 0.10 + 0.05 * r))
		var w: float = 2.0 if r < 2 else 3.0
		draw_rect(rect.grow(-w * 0.5), col, false, w)
		if r >= 2:
			draw_rect(rect.grow(-w - 2.0), Color(col.r, col.g, col.b, 0.45), false, 1.0)
		if r == 1:
			var kr: float = 0.5 + 0.5 * sin(_t * 2.2)
			draw_rect(rect.grow(1.0), Color(col.r, col.g, col.b, 0.10 + 0.18 * kr), false, 2.0)
		if r == 2:
			# scintille che si accendono e spengono
			for i in 4:
				var ph: float = fposmod(_t * 0.9 + float(i) * 0.25, 1.0)
				var sp := Vector2(size.x * fposmod(0.2 + 0.31 * float(i) + float(i * i) * 0.07, 1.0), size.y * fposmod(0.15 + 0.27 * float(i), 1.0))
				var a: float = sin(ph * PI)
				var rr: float = 1.5 + 3.0 * a
				draw_line(sp - Vector2(rr, 0), sp + Vector2(rr, 0), Color(1, 1, 1, 0.8 * a), 1.5)
				draw_line(sp - Vector2(0, rr), sp + Vector2(0, rr), Color(1, 1, 1, 0.8 * a), 1.5)
		if r >= 3:
			var k: float = 0.5 + 0.5 * sin(_t * 3.0)
			draw_rect(rect.grow(2.0), Color(col.r, col.g, col.b, 0.18 + 0.22 * k), false, 3.0)
			var sx: float = fposmod(_t * 0.7, 1.4) - 0.2
			draw_line(Vector2(size.x * sx, size.y), Vector2(size.x * (sx + 0.25), 0), Color(1, 1, 1, 0.22), maxf(3.0, size.x * 0.1))


var data: Dictionary = {"name": Profile.DEFAULT_NAME, "icon": "c_sword", "banner": 0}
var subtitle: String = ""
var _sheen: float = 0.0
var _icon: ProfileIcon
var _name_label: Label
var _sub_label: Label


func _process(delta: float) -> void:
	_sheen += delta
	queue_redraw()


# Carta con banner: size = dimensioni della carta, prima il banner, poi icona a sinistra e nome.
func setup(profile: Dictionary, card_size: Vector2, new_subtitle: String = "") -> ProfileCard:
	data = profile.duplicate()
	subtitle = new_subtitle
	custom_minimum_size = card_size
	size = card_size
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()
	return self


func update_data(profile: Dictionary, new_subtitle: String = "") -> void:
	data = profile.duplicate()
	subtitle = new_subtitle
	_build()


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var h: float = size.y
	var px: float = h - 14.0
	_icon = ProfileIcon.new().setup(str(data.get("icon", "c_sword")), px)
	_icon.position = Vector2(8, 7)
	add_child(_icon)
	_name_label = BattleTheme.make_label(str(data.get("name", "")).to_upper(), int(clampf(h * 0.36, 14.0, 26.0)), BattleTheme.WH)
	_name_label.position = Vector2(px + 20, 5 if subtitle != "" else (h - 26.0) * 0.5)
	_name_label.size = Vector2(size.x - px - 30, 28)
	_name_label.clip_text = true
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)
	if subtitle != "":
		_sub_label = BattleTheme.make_label(subtitle, int(clampf(h * 0.24, 11.0, 16.0)), Color(1, 1, 1, 0.72))
		_sub_label.position = Vector2(px + 20, h * 0.52)
		_sub_label.size = Vector2(size.x - px - 30, 22)
		_sub_label.clip_text = true
		_sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_sub_label)
	queue_redraw()


func _draw() -> void:
	var cols: Array = Profile.banner_colors(int(data.get("banner", 0)))
	var a: Color = cols[0]
	var b: Color = cols[1]
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y)])
	draw_polygon(pts, PackedColorArray([a, b.darkened(0.25), b.darkened(0.25), a]))
	# strisce oblique leggere
	var step: float = 22.0
	var x: float = -size.y
	while x < size.x:
		draw_line(Vector2(x, size.y), Vector2(x + size.y, 0), Color(1, 1, 1, 0.05), 6.0)
		x += step
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.45)), Color(1, 1, 1, 0.05))
	if AnimFx.enabled():
		var sx: float = fposmod(_sheen * 0.22, 1.8) - 0.4
		draw_line(Vector2(size.x * sx, size.y), Vector2(size.x * (sx + 0.15), 0), Color(1, 1, 1, 0.10), size.y * 0.5)
	draw_rect(Rect2(Vector2.ZERO, size), Color(b.r, b.g, b.b, 0.85), false, 2.0)
	draw_rect(Rect2(Vector2(0, size.y - 3), Vector2(size.x, 3)), b)
