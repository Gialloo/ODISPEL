class_name PullReveal
extends Control

# Apertura del reclutamento: ogni operatore ottenuto entra a tutto schermo, a scatti
# come in Persona, con il colore della sua rarita'. Click / INVIO / SPAZIO = avanti,
# ESC = salta. Alla fine un riepilogo con tutti i risultati.

signal finished

const RARITY_COLORS: Array = ["#7cf0ff", "#6bffb0", "#b07bff", "#ffd25f"]

var results: Array = []
var index: int = -1
var summary: bool = false
var finished_flag: bool = false
var _t: float = 0.0
var _stage_t: float = 0.0
var _portrait: PortraitView
var _name: Label
var _sub: Label
var _badge: Label
var _hint: Label
var _grid: GridContainer


static func play(host: Node, new_results: Array) -> PullReveal:
	var v := PullReveal.new()
	v.results = new_results
	host.add_child(v)
	return v


static func color_of(rarity: int) -> Color:
	return Color(RARITY_COLORS[clampi(rarity, 0, RARITY_COLORS.size() - 1)])


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_portrait = PortraitView.new().setup("", "splash")
	_portrait.size = Vector2(520, 640)
	_portrait.show_expression_text = false
	add_child(_portrait)
	_name = BattleTheme.make_label("", 72, BattleTheme.WH, true)
	add_child(_name)
	_sub = BattleTheme.make_label("", 24, BattleTheme.WH, true)
	add_child(_sub)
	_badge = BattleTheme.make_label("", 30, BattleTheme.BK, true)
	add_child(_badge)
	_hint = BattleTheme.make_label("CLICK = AVANTI     ESC = SALTA", 15, BattleTheme.CY_DIM)
	_hint.position = Vector2(40, 684)
	add_child(_hint)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	_grid.position = Vector2(110, 150)
	_grid.visible = false
	add_child(_grid)
	advance()


func _process(delta: float) -> void:
	_t += delta
	_stage_t += delta
	queue_redraw()


func current() -> Dictionary:
	return results[index] if index >= 0 and index < results.size() else {}


func advance() -> void:
	if finished_flag:
		return
	if summary:
		_end()
		return
	index += 1
	if index >= results.size():
		if results.size() > 1:
			_show_summary()
		else:
			_end()
		return
	_show_card(results[index])


func skip_all() -> void:
	if finished_flag:
		return
	if summary or results.size() <= 1:
		_end()
	else:
		index = results.size()
		_show_summary()


func _label_of(r: Dictionary) -> String:
	match str(r["outcome"]):
		"new":
			return "NUOVO!"
		"rank":
			return "RANK UP!"
	return "COPIA MASSIMA  +%d" % int(r.get("refund", 0))


func _show_card(r: Dictionary) -> void:
	var rarity: int = int(r["rarity"])
	var col: Color = color_of(rarity)
	var def: Dictionary = BattleContent.CHARACTERS.get(str(r["char"]), {})
	Snd.play("cutin" if rarity >= 2 else "swap")
	_stage_t = 0.0
	_portrait.char_id = str(r["char"])
	_portrait._refresh_texture()
	_portrait.position = Vector2(-600, 40)
	_portrait.visible = true
	_name.text = str(def.get("name", r["char"])).to_upper()
	_name.position = Vector2(1400, 240)
	_name.add_theme_color_override("font_color", Color.WHITE)
	_sub.text = "%s  ·  %s  ·  %s" % [str(BattleTypes.RARITIES[rarity]).to_upper(), str(def.get("cls", "")).to_upper(), str(def.get("color", "")).to_upper()]
	_sub.position = Vector2(1400, 340)
	_sub.add_theme_color_override("font_color", col)
	_badge.text = " " + _label_of(r) + " "
	_badge.position = Vector2(1400, 420)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_portrait, "position:x", 90.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_name, "position:x", 640.0, 0.2).set_delay(0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_sub, "position:x", 646.0, 0.2).set_delay(0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_badge, "position:x", 646.0, 0.2).set_delay(0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ComicFx.speed_lines(self, Vector2(640, 360), Color(col, 0.9), 0.35)
	ComicFx.flash(self, col if rarity >= 2 else Color.WHITE, 0.12)


func _show_summary() -> void:
	summary = true
	_portrait.visible = false
	_name.text = "RISULTATO"
	_name.position = Vector2(110, 40)
	_sub.text = "%d RECLUTAMENTI" % results.size()
	_sub.position = Vector2(116, 120)
	_badge.text = ""
	_grid.visible = true
	for c in _grid.get_children():
		c.queue_free()
	for r in results:
		var rarity: int = int(r["rarity"])
		var col: Color = color_of(rarity)
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(200, 92)
		cell.add_theme_stylebox_override("panel", SlantBox.make(BattleTheme.BK, col, 10.0, col.darkened(0.55), 3.0))
		var v := VBoxContainer.new()
		v.add_child(BattleTheme.make_label(str(BattleContent.CHARACTERS[str(r["char"])]["name"]).to_upper(), 22, col, true))
		v.add_child(BattleTheme.make_label(_label_of(r), 13, BattleTheme.WH))
		cell.add_child(v)
		_grid.add_child(cell)
	_hint.text = "CLICK = CHIUDI"
	UiMotion.slide_in(_grid.get_children(), Vector2(0, 40), 0.04, 0.2)


func _end() -> void:
	if finished_flag:
		return
	finished_flag = true
	finished.emit()
	queue_free()


func _draw() -> void:
	var view: Vector2 = size
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.01, 0.02, 0.03, 0.94))
	var col: Color = BattleTheme.CY
	if not summary and not current().is_empty():
		col = color_of(int(current()["rarity"]))
	var k: float = clampf(_stage_t / 0.18, 0.0, 1.0)
	# grande banda diagonale dietro al personaggio
	var reach: float = maxf(view.x * k, 80.0)
	var back := PackedVector2Array([Vector2(-20, 110), Vector2(reach + 140.0, 80.0), Vector2(reach, 640.0), Vector2(-20, 670.0)])
	draw_colored_polygon(back, col.darkened(0.45) if not summary else Color(col, 0.18))
	var band := PackedVector2Array([Vector2(-20, 130), Vector2(reach + 110.0, 104.0), Vector2(reach - 30.0, 620.0), Vector2(-20, 646.0)])
	draw_colored_polygon(band, Color(0.02, 0.03, 0.04, 0.96))
	draw_line(band[1], band[2], Color.WHITE, 4.0)
	for i in 6:
		var x: float = 600.0 + float(i) * 110.0 + fmod(_t * 30.0, 110.0)
		draw_line(Vector2(x + 150.0, 140.0), Vector2(x, 620.0), Color(col, 0.2), 5.0)
	if not summary and not current().is_empty():
		var stars: int = int(current()["rarity"]) + 1
		for s in stars:
			var p := Vector2(660.0 + float(s) * 46.0, 200.0)
			var pts := PackedVector2Array()
			for j in 10:
				var a: float = -PI / 2.0 + TAU * float(j) / 10.0
				var rr: float = 20.0 if j % 2 == 0 else 8.5
				pts.append(p + Vector2(cos(a), sin(a)) * rr)
			draw_colored_polygon(pts, col)
	# targhetta del badge (dietro il testo)
	if not summary and _badge.text != "":
		var bx: float = _badge.position.x
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 14.0, 418.0), Vector2(bx + _badge.size.x + 6.0, 418.0), Vector2(bx + _badge.size.x - 8.0, 468.0), Vector2(bx - 28.0, 468.0)]), col)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()


func _input(event: InputEvent) -> void:
	if finished_flag or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			get_viewport().set_input_as_handled()
			advance()
		KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			skip_all()
