class_name ScreenFrame
extends RefCounted

# Adatta l'interfaccia (disegnata per 1280x720) a QUALSIASI schermo, telefoni lunghi e con
# "notch" compresi. Ogni schermata diventa un riquadro 1280x720 centrato dentro l'area sicura
# del telefono: i tasti non finiscono mai sotto la fotocamera, ai bordi arrotondati o fuori
# dallo schermo. Gli sfondi (rettangoli a tutto schermo) escono dal riquadro e riempiono
# comunque tutto lo schermo, cosi' ai lati non restano bande vuote.

const BASE: Vector2 = Vector2(1280.0, 720.0)
const MOBILE_MARGIN: float = 14.0      # aria minima dai bordi su telefono (angoli arrotondati)

# Prova su PC / test: margini "sicuri" in unita' del gioco (sinistra, alto, destra, basso).
static var test_insets: Vector4 = Vector4.ZERO


# Margini fisici dello schermo (pixel veri) lasciati liberi da notch e barre di sistema.
static func physical_insets() -> Vector4:
	if not OS.has_feature("mobile") or DisplayServer.get_name() == "headless":
		return Vector4.ZERO
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var screen: Vector2i = DisplayServer.screen_get_size()
	if safe.size.x <= 0 or safe.size.y <= 0 or screen.x <= 0:
		return Vector4(MOBILE_MARGIN, MOBILE_MARGIN, MOBILE_MARGIN, MOBILE_MARGIN)
	return Vector4(float(safe.position.x), float(safe.position.y), float(screen.x - safe.end.x), float(screen.y - safe.end.y))


# Dimensione logica da dare alla finestra: la base piu' i margini, cosi' il riquadro sta sempre.
static func content_size(window: Window) -> Vector2i:
	if test_insets != Vector4.ZERO:
		return Vector2i(ceili(BASE.x + test_insets.x + test_insets.z), ceili(BASE.y + test_insets.y + test_insets.w))
	var ins: Vector4 = physical_insets()
	if ins == Vector4.ZERO or window == null:
		return Vector2i(BASE)
	var win := Vector2(window.size)
	if win.x < 1.0 or win.y < 1.0:
		return Vector2i(BASE)
	var c: Vector2 = BASE
	for i in 4:
		var s: float = minf(win.x / c.x, win.y / c.y)
		c = Vector2(BASE.x + (ins.x + ins.z) / s + 2.0 * MOBILE_MARGIN, BASE.y + (ins.y + ins.w) / s + 2.0 * MOBILE_MARGIN)
	return Vector2i(c.ceil())


# Margini in unita' del gioco, dato lo schermo reale e la vista corrente.
static func view_insets(window: Window, view: Vector2) -> Vector4:
	if test_insets != Vector4.ZERO:
		return test_insets
	var ins: Vector4 = physical_insets()
	if ins == Vector4.ZERO or window == null or view.x < 1.0:
		return Vector4.ZERO
	var win := Vector2(window.size)
	var s: float = maxf(0.0001, minf(win.x / view.x, win.y / view.y))
	return Vector4(ins.x / s + MOBILE_MARGIN, ins.y / s + MOBILE_MARGIN, ins.z / s + MOBILE_MARGIN, ins.w / s + MOBILE_MARGIN)


# Posizione e dimensione del riquadro 1280x720 dentro una vista: centrato nell'area sicura.
static func box_for(view: Vector2, ins: Vector4) -> Rect2:
	var uw: float = view.x - ins.x - ins.z
	var uh: float = view.y - ins.y - ins.w
	var bx: float = ins.x + maxf(0.0, (uw - BASE.x) * 0.5)
	var by: float = ins.y + maxf(0.0, (uh - BASE.y) * 0.5)
	return Rect2(bx, by, BASE.x, BASE.y)


# Da chiamare nel _ready di ogni schermata a tutto schermo.
static func setup(screen: Control) -> void:
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var window: Window = screen.get_window()
	if window != null:
		window.content_scale_size = content_size(window)
	if not screen.ready.is_connected(_attach_later.bind(screen)):
		screen.ready.connect(_attach_later.bind(screen), CONNECT_ONE_SHOT)


static func _attach_later(screen: Control) -> void:
	attach(screen)


# I nodi che escono dal riquadro per coprire tutto lo schermo (sfondi, veli, velature).
static func wants_bleed(c: Node) -> bool:
	if not (c is Control):
		return false
	var ctl: Control = c
	if ctl.has_meta("no_bleed"):
		return false
	if ctl.has_meta("bleed"):
		return true
	var full: bool = ctl.anchor_left == 0.0 and ctl.anchor_top == 0.0 and ctl.anchor_right == 1.0 and ctl.anchor_bottom == 1.0
	return full and (ctl is ColorRect or ctl is TextureRect or ctl is MenuBackdrop or ctl is BattleStage)


# Fa del controllo un riquadro centrato e tiene aggiornati gli sfondi quando lo schermo cambia.
static func attach(screen: Control) -> void:
	if not is_instance_valid(screen) or not screen.is_inside_tree() or screen.has_meta("screen_frame"):
		return
	var f := Frame.new()
	f.screen = screen
	screen.set_meta("screen_frame", f)
	for c in screen.get_children():
		if wants_bleed(c):
			f.bleeds.append(c)
	var vp: Viewport = screen.get_viewport()
	if vp != null:
		vp.size_changed.connect(f.layout)
	f.layout()


# Un fondo che copre sempre tutto lo schermo, anche fuori dal riquadro (modali, velature).
static func overshoot(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = -4000.0
	c.offset_top = -4000.0
	c.offset_right = 4000.0
	c.offset_bottom = 4000.0


# Contenitore a tutto schermo che resta dentro l'area sicura (per avvisi e barre fisse che stanno ai bordi).
static func safe_holder(parent: Control) -> Control:
	var h := Control.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(h)
	var update: Callable = func() -> void:
		if not is_instance_valid(h) or not h.is_inside_tree():
			return
		var ins: Vector4 = view_insets(h.get_window(), h.get_viewport().get_visible_rect().size)
		h.offset_left = ins.x
		h.offset_top = ins.y
		h.offset_right = -ins.z
		h.offset_bottom = -ins.w
	h.ready.connect(func() -> void:
		update.call()
		h.get_viewport().size_changed.connect(update))
	return h


class Frame extends RefCounted:
	var screen: Control
	var bleeds: Array = []

	func layout() -> void:
		if not is_instance_valid(screen) or not screen.is_inside_tree():
			return
		var vp: Vector2 = screen.get_viewport().get_visible_rect().size
		var ins: Vector4 = ScreenFrame.view_insets(screen.get_window(), vp)
		var box: Rect2 = ScreenFrame.box_for(vp, ins)
		screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
		screen.position = box.position
		screen.size = box.size
		for c in bleeds:
			if not is_instance_valid(c):
				continue
			var ctl: Control = c
			ctl.set_anchors_preset(Control.PRESET_FULL_RECT)
			ctl.offset_left = -box.position.x
			ctl.offset_top = -box.position.y
			ctl.offset_right = vp.x - box.position.x - box.size.x
			ctl.offset_bottom = vp.y - box.position.y - box.size.y
			if ctl.has_method("set_frame_origin"):
				ctl.call("set_frame_origin", box.position)
