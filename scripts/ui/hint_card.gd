class_name HintCard
extends Control

# Scheda di spiegazione che compare vicino a un elemento dell'HUD.
#   - mouse: compare quando ci passi sopra, sparisce quando esci;
#   - telefono: compare toccando l'elemento (o tenendolo premuto, per i pulsanti d'azione) e sparisce toccando altrove.
# Una sola scheda alla volta. Il testo viene chiesto a un Callable al momento di mostrarla, cosi' e' sempre aggiornato.

const WIDTH: float = 340.0
const HOLD_SECONDS: float = 0.45

static var _current: HintCard = null

var _panel: HudPanel
var _label: Label
var _anchor: Control
var _auto_hide: float = 0.0


# Collega una scheda a un elemento. provider: Callable() -> {title, body, color}. host: nodo schermo che ospita la scheda.
# hold: per i pulsanti che fanno gia' qualcosa al tocco, la scheda compare tenendo premuto (e il tocco non vale come azione).
static func bind(node: Control, provider: Callable, host: Control, hold: bool = false) -> void:
	node.set_meta("hinted", true)       # tiene la pressione lunga per la scheda: si conferma al rilascio
	node.mouse_entered.connect(func() -> void:
		if not TouchUi.active():
			show_for(host, node, provider.call()))
	node.mouse_exited.connect(func() -> void:
		if not TouchUi.active():
			hide_current())
	if not TouchUi.active() and not hold:
		return
	var state: Dictionary = {"timer": null}
	node.gui_input.connect(func(event: InputEvent) -> void:
		var pressed: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
		var released: bool = (event is InputEventScreenTouch and not event.pressed) or (event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
		if pressed and not hold:
			show_for(host, node, provider.call())
		elif pressed and hold and TouchUi.active():
			var t: SceneTreeTimer = node.get_tree().create_timer(HOLD_SECONDS)
			state["timer"] = t
			t.timeout.connect(func() -> void:
				if state["timer"] == t and is_instance_valid(node):
					node.set_meta("hint_held", true)
					show_for(host, node, provider.call()))
		elif released:
			state["timer"] = null)


# Un pulsante premuto a lungo ha mostrato la scheda: quel rilascio non e' un comando (si legge una volta sola).
static func consume_hold(node: Control) -> bool:
	if node.has_meta("hint_held"):
		node.remove_meta("hint_held")
		return true
	return false


static func show_for(host: Control, anchor: Control, card: Dictionary) -> HintCard:
	hide_current()
	var c := HintCard.new()
	c._anchor = anchor
	host.add_child(c)
	c.build(card, host)
	_current = c
	return c


static func hide_current() -> void:
	if is_instance_valid(_current):
		_current.queue_free()
	_current = null


static func current() -> HintCard:
	return _current if is_instance_valid(_current) else null


func build(card: Dictionary, host: Control) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 200
	var accent: Color = card.get("color", BattleTheme.CY)
	_panel = HudPanel.new().setup(str(card.get("title", "")), accent)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_label = BattleTheme.make_label(str(card.get("body", "")), 16 if TouchUi.active() else 13, BattleTheme.WH)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(WIDTH - 28.0, 0.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_content(_label)
	var font_size: int = 16 if TouchUi.active() else 13
	var font: Font = BattleTheme.mono()
	var text_h: float = 0.0
	for line in str(card.get("body", "")).split("\n"):
		var w: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		text_h += (ceilf(maxf(w, 1.0) / (WIDTH - 28.0)) * (font_size + 6.0))
	_panel.size = Vector2(WIDTH, clampf(text_h + 54.0, 80.0, 420.0))
	var view: Vector2 = host.get_viewport_rect().size
	var rect: Rect2 = _anchor.get_global_rect() if is_instance_valid(_anchor) else Rect2()
	var x: float = clampf(rect.position.x, 8.0, view.x - WIDTH - 8.0)
	var y: float = rect.position.y - _panel.size.y - 8.0
	if y < 8.0:
		y = minf(rect.end.y + 8.0, view.y - _panel.size.y - 8.0)
	_panel.position = host.get_global_transform().affine_inverse() * Vector2(x, y)
	if TouchUi.active():
		_auto_hide = 5.0


func _process(delta: float) -> void:
	if not is_instance_valid(_anchor) or not _anchor.is_inside_tree():
		hide_current()      # l'elemento e' stato ricostruito: la scheda non ha piu' a cosa riferirsi
		return
	if _auto_hide > 0.0:
		_auto_hide -= delta
		if _auto_hide <= 0.0:
			hide_current()


# Toccare altrove chiude la scheda (sul telefono non c'e' "uscire col mouse").
func _input(event: InputEvent) -> void:
	if not TouchUi.active():
		return
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		var inside: bool = is_instance_valid(_anchor) and _anchor.get_global_rect().has_point(event.position)
		if not inside:
			hide_current()
