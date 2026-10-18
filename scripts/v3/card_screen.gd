extends Control

# CARTELLO: titolo grande su nero (capitoli, «fine dell'atto»). Tocca o aspetta per andare avanti.

var passo: Dictionary = {}
var _done: bool = false


func configure(args: Dictionary) -> void:
	passo = args.get("passo", {})


func crumb() -> String:
	return "menu"


func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.05)
	Ui.place(bg, 0, 0, 1, 1)
	add_child(bg)
	# momento forte: cornice gotica in filigrana
	var fr := Control.new()
	Ui.place(fr, 0, 0, 1, 1)
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fr.draw.connect(func() -> void: Filigree.frame(fr, Rect2(Vector2(36, 36), fr.size - Vector2(72, 72)), 1.1, Ui.YELLOW))
	add_child(fr)
	var t1 := Ui.label(str(passo.get("titolo", "")), 72, Ui.CREAM, Ui.display(), 10)
	Ui.place(t1, 0, 0.36, 1, 0.36, 0, 0, 0, 100)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(t1)
	var t2 := Ui.label(str(passo.get("sotto", "")), 30, Ui.YELLOW, Ui.display(), 6)
	Ui.place(t2, 0.1, 0.52, 0.9, 0.52, 0, 0, 0, 90)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(t2)
	Breadcrumb.mark("menu")
	await get_tree().create_timer(2.6).timeout
	_go()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_go()


func _go() -> void:
	if _done or not is_inside_tree():
		return
	_done = true
	Story.advance()
	get_parent().next_story()


func back() -> void:
	_go()
