class_name ArrowScroll
extends ScrollContainer

# Elenco che scorre con FRECCE GRANDI su e giu' (oltre a rotella e dito): niente piu' scrollbar sottili da centrare.
# Le frecce stanno nella fascia a destra, spariscono se tutto entra, si spengono a inizio e fine lista, e tenendole
# premute l'elenco continua a scorrere. Si usa al posto di ScrollContainer.new().

const STEP_FRACTION: float = 0.45         # quanto scorre un tocco (frazione dell'altezza visibile)
const REPEAT_FIRST: float = 0.35
const REPEAT_EVERY: float = 0.10

var _up: Button
var _down: Button
var _timer: Timer
var _dir: int = 0
var _gutter: float = 0.0


func _init() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED


func _ready() -> void:
	_up = _arrow("▲", -1)
	_down = _arrow("▼", 1)
	add_child(_up, false, Node.INTERNAL_MODE_FRONT)
	add_child(_down, false, Node.INTERNAL_MODE_FRONT)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_repeat)
	add_child(_timer, false, Node.INTERNAL_MODE_FRONT)
	var bar: VScrollBar = get_v_scroll_bar()
	bar.changed.connect(_layout)
	bar.value_changed.connect(func(_v: float) -> void: _layout())
	resized.connect(_layout)
	_gutter = 52.0 if TouchUi.active() else 36.0
	_style_bar(bar)
	set_process(true)
	_layout.call_deferred()


func _arrow(glyph: String, dir: int) -> Button:
	var b := Button.new()
	b.text = glyph
	b.focus_mode = Control.FOCUS_NONE
	b.z_index = 2
	b.top_level = true             # il ScrollContainer non deve spostarle insieme al contenuto
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.custom_minimum_size = Vector2.ZERO
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", BattleTheme.CY)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", BattleTheme.BK)
	b.add_theme_color_override("font_disabled_color", Color(BattleTheme.CY_DIM, 0.35))
	b.add_theme_stylebox_override("normal", _box(Color(BattleTheme.BK, 0.88), BattleTheme.CY))
	b.add_theme_stylebox_override("hover", _box(Color(BattleTheme.CY, 0.25), Color.WHITE))
	b.add_theme_stylebox_override("pressed", _box(BattleTheme.CY, Color.WHITE))
	b.add_theme_stylebox_override("disabled", _box(Color(BattleTheme.BK, 0.55), Color(BattleTheme.CY_DIM, 0.3)))
	b.button_down.connect(_press.bind(dir))
	b.button_up.connect(_release)
	return b


func _box(fill: Color, edge: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 0.0
	sb.content_margin_right = 0.0
	sb.content_margin_top = 0.0
	sb.content_margin_bottom = 0.0
	return sb


func _style_bar(bar: VScrollBar) -> void:
	var track := StyleBoxFlat.new()
	# la larghezza della barra viene dai margini dello sfondo: cosi' il contenuto lascia davvero la fascia libera
	track.content_margin_left = _gutter * 0.5
	track.content_margin_right = _gutter * 0.5
	track.bg_color = Color(BattleTheme.CY_DIM, 0.10)
	track.set_corner_radius_all(4)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(BattleTheme.CY, 0.40)
	grab.set_corner_radius_all(4)
	var grab_hot := StyleBoxFlat.new()
	grab_hot.bg_color = Color(BattleTheme.CY, 0.80)
	grab_hot.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("grabber", grab)
	bar.add_theme_stylebox_override("grabber_highlight", grab_hot)
	bar.add_theme_stylebox_override("grabber_pressed", grab_hot)


# Frecce se c'e' spazio (la lista e' abbastanza alta), altrimenti resta la barra normale.
func _layout() -> void:
	if _up == null or not is_instance_valid(_up):
		return
	var bar: VScrollBar = get_v_scroll_bar()
	var need: bool = bar.max_value - bar.page > 1.0
	var w: float = 52.0 if TouchUi.active() else 36.0
	var roomy: bool = size.y >= w * 2.0 + 24.0
	var want: float = w if (need and roomy) else (16.0 if TouchUi.active() else 10.0)
	if absf(want - _gutter) > 0.5:
		_gutter = want
		_style_bar(bar)
		queue_sort()
	var shown: bool = need and roomy
	_up.visible = shown
	_down.visible = shown
	if not shown:
		return
	_up.size = Vector2(w, w)
	_down.size = Vector2(w, w)
	_place()
	_up.disabled = scroll_vertical <= 0
	_down.disabled = float(scroll_vertical) >= bar.max_value - bar.page - 1.0


# Le frecce sono "top level": si posizionano in coordinate assolute, sempre sull'angolo della lista.
func _place() -> void:
	if _up == null or not _up.visible:
		return
	var r: Rect2 = get_global_rect()
	_up.global_position = Vector2(r.end.x - _up.size.x, r.position.y)
	_down.global_position = Vector2(r.end.x - _down.size.x, r.end.y - _down.size.y)


func _process(_delta: float) -> void:
	_place()


func _press(dir: int) -> void:
	_dir = dir
	_step()
	_timer.start(REPEAT_FIRST)


func _release() -> void:
	_dir = 0
	_timer.stop()


func _repeat() -> void:
	if _dir == 0:
		return
	_step()
	_timer.start(REPEAT_EVERY)


func _step() -> void:
	var amount: int = int(maxf(60.0, size.y * STEP_FRACTION))
	var bar: VScrollBar = get_v_scroll_bar()
	var target: int = clampi(scroll_vertical + _dir * amount, 0, int(maxf(0.0, bar.max_value - bar.page)))
	var tw := create_tween()
	tw.tween_property(self, "scroll_vertical", target, 0.09)
